import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bridge_gateway/bridge_gateway.dart';
import 'package:test/test.dart';

const _hand = 'AKQ.JT9.876.5432';
const _input = <String, String>{
  'hand': _hand,
  'seat': 'N',
  'dealer': 'E',
  'vul': 'NS',
  'ctx': '1N-P',
};

class _FakeBackend implements GatewayDecisionBackend {
  _FakeBackend({this.output, this.error});
  Map<String, Object?>? output;
  Object? error;
  int calls = 0;
  Map<String, String>? lastInput;

  @override
  Future<Map<String, Object?>> decide(
      String route, Map<String, String> allowedFields) async {
    calls++;
    lastInput = allowedFields;
    if (error != null) throw error!;
    return output ?? {'bid': 'PASS'};
  }
}

typedef _ApiResponse = ({int status, Map<String, dynamic> body, HttpHeaders headers});

Future<_ApiResponse> _request(
  int port,
  String method,
  String path, {
  Object? json,
  String? token,
  Map<String, String> headers = const {},
}) async {
  final client = HttpClient();
  try {
    final req = await client.openUrl(
      method,
      Uri.parse('http://127.0.0.1:$port$path'),
    );
    req.followRedirects = false;
    if (json != null) {
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(json));
    }
    if (token != null) {
      req.headers.set('authorization', 'Bearer $token');
    }
    for (final entry in headers.entries) {
      req.headers.set(entry.key, entry.value);
    }
    final res = await req.close();
    final raw = await utf8.decoder.bind(res).join();
    final body = raw.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    return (status: res.statusCode, body: body, headers: res.headers);
  } finally {
    client.close(force: true);
  }
}

Future<String> _token(int port, {Map<String, String> headers = const {}}) async {
  final res = await _request(port, 'POST', '/v1/sessions/anonymous',
      json: {'version': 1}, headers: headers);
  expect(res.status, 201);
  return res.body['access_token'] as String;
}

Future<_ApiResponse> _decision(
  int port,
  String token, {
  String route = 'bid',
  Map<String, Object?> input = _input,
  Map<String, String> headers = const {},
}) =>
    _request(port, 'POST', '/v1/ai/decision',
        token: token,
        json: {'version': 1, 'route': route, 'input': input},
        headers: headers);

void main() {
  group('A4.2 localhost Gateway HTTP tests (fake backend, NOT real BEN)', () {
    late BridgeGatewayService gateway;
    late int port;
    late _FakeBackend backend;

    setUp(() async {
      backend = _FakeBackend();
      gateway = BridgeGatewayService(backend: backend);
      port = await gateway.start();
    });
    tearDown(() async => gateway.close());

    test('anonymous token is random and short lived; response is no-store',
        () async {
      final first = await _request(port, 'POST', '/v1/sessions/anonymous',
          json: {'version': 1});
      final second = await _request(port, 'POST', '/v1/sessions/anonymous',
          json: {'version': 1});
      expect(first.status, 201);
      expect(first.headers.value('cache-control'), contains('no-store'));
      expect(first.body['token_type'], 'Bearer');
      expect(first.body['scope'], 'ai:decision');
      expect(first.body['expires_in'], 900);
      expect((first.body['access_token'] as String).length, greaterThan(40));
      expect(first.body['access_token'], isNot(second.body['access_token']));
    });

    test('valid scoped bearer allows only a filtered bid proposal', () async {
      final token = await _token(port);
      final response = await _decision(port, token);
      expect(response.status, 200);
      expect(response.body, {
        'version': 1,
        'decision': {'bid': 'PASS'},
      });
      expect(backend.calls, 1);
      expect(backend.lastInput, _input);
      expect(backend.lastInput, isNot(contains('deal')));
    });

    test('unauthorized, unknown token and wrong method are rejected', () async {
      final unauth = await _request(port, 'POST', '/v1/ai/decision',
          json: {'version': 1, 'route': 'bid', 'input': _input});
      expect(unauth.status, 401);
      final invalid = await _decision(port, 'not-a-real-token');
      expect(invalid.status, 401);
      final get = await _request(port, 'GET', '/v1/ai/decision');
      expect(get.status, 404);
      expect(backend.calls, 0);
    });

    test('rejects hidden deal, early dummy and invalid/missing fields', () async {
      final token = await _token(port);
      for (final input in [
        {..._input, 'deal': 'SECRET_OPPONENT_HANDS'},
        {..._input, 'dummy': 'SENSITIVE'},
        {..._input}..remove('hand'),
        {..._input, 'hand': '...A'},
        {..._input, 'seat': 'X'},
      ]) {
        final response = await _decision(port, token, input: input);
        expect(response.status, 400);
        expect(response.body.toString(), isNot(contains('SECRET')));
      }
      expect((await _decision(port, token, route: 'autoplay')).status, 400);
      expect(backend.calls, 0);
    });

    test('play requires a valid exposed-dummy-shaped hand and play history',
        () async {
      backend.output = {'card': 'D2'};
      final token = await _token(port);
      final allowed = await _decision(port, token, route: 'play',
          input: {..._input, 'dummy': '.AKQJT98765432..', 'played': 'S2'});
      expect(allowed.status, 200);
      expect(allowed.body['decision'], {'card': 'D2'});
      expect((await _decision(port, token, route: 'play')).status, 400);
    });

    test('bad JSON, oversize body and query strings fail closed', () async {
      final token = await _token(port);
      final invalid = await _request(port, 'POST', '/v1/ai/decision',
          token: token, json: ['not an object']);
      expect(invalid.status, 400);
      final oversized = await _request(port, 'POST', '/v1/ai/decision',
          token: token, json: {'x': List.filled(9000, 'Q').join()});
      expect(oversized.status, 413);
      final query = await _request(port, 'POST', '/v1/ai/decision?hand=SECRET',
          token: token, json: {'version': 1, 'route': 'bid', 'input': _input});
      expect(query.status, 400);
      expect(query.body.toString(), isNot(contains('SECRET')));
      expect(backend.calls, 0);
    });

    test('unauthorized browser Origin rejected, trusted Origin preflight',
        () async {
      await gateway.close();
      gateway = BridgeGatewayService(
        backend: backend,
        config: const GatewayConfig(
          allowedBrowserOrigins: {'https://localhost.example'},
        ),
      );
      port = await gateway.start();
      final denied = await _request(port, 'POST', '/v1/sessions/anonymous',
          json: {'version': 1},
          headers: {'origin': 'https://evil.example'});
      expect(denied.status, 403);
      final options = await _request(port, 'OPTIONS', '/v1/ai/decision',
          headers: {'origin': 'https://localhost.example'});
      expect(options.status, 204);
      expect(options.headers.value('access-control-allow-origin'),
          'https://localhost.example');
    });

    test('bootstrap requests are limited by real peer IP, never XFF', () async {
      await gateway.close();
      gateway = BridgeGatewayService(
        backend: backend,
        config: const GatewayConfig(bootstrapLimit: 1),
      );
      port = await gateway.start();
      await _token(port, headers: {'x-forwarded-for': '192.0.2.42'});
      final denied = await _request(port, 'POST', '/v1/sessions/anonymous',
          json: {'version': 1},
          headers: {'x-forwarded-for': '203.0.113.123'});
      expect(denied.status, 429);
      expect(denied.body['error'], {'code': 'rate_limited'});
    });

    test('decision requests enforce per-token usage limit', () async {
      await gateway.close();
      gateway = BridgeGatewayService(
        backend: backend,
        config: const GatewayConfig(decisionLimit: 1),
      );
      port = await gateway.start();
      final token = await _token(port);
      expect((await _decision(port, token)).status, 200);
      expect((await _decision(port, token)).status, 429);
      expect(backend.calls, 1);
    });

    test('expired token is denied without reaching backend', () async {
      await gateway.close();
      var clock = DateTime.utc(2026, 10, 16);
      gateway = BridgeGatewayService(
          backend: backend,
          clock: () => clock,
          config: const GatewayConfig(sessionTtl: Duration(seconds: 10)));
      port = await gateway.start();
      final token = await _token(port);
      clock = clock.add(const Duration(seconds: 11));
      expect((await _decision(port, token)).status, 401);
      expect(backend.calls, 0);
    });

    test('default gateway NEVER fabricates a Demo or real BEN answer',
        () async {
      await gateway.close();
      gateway = BridgeGatewayService();
      port = await gateway.start();
      final token = await _token(port);
      final res = await _decision(port, token);
      expect(res.status, 503);
      expect(res.body['error'], {'code': 'upstream_unavailable'});
      expect(res.body.toString(), isNot(contains(_hand)));
    });

    test('malformed or failing backend is sanitized and never echoed',
        () async {
      final token = await _token(port);
      backend.output = {'bid': 'PASS', 'internal': 'SECRET_PRIVATE_HAND'};
      final malformed = await _decision(port, token);
      expect(malformed.status, 502);
      backend.output = null;
      backend.error = StateError('SECRET_PRIVATE_HAND');
      final failed = await _decision(port, token);
      expect(failed.status, 503);
      expect(failed.body.toString(), isNot(contains('SECRET_PRIVATE_HAND')));
      expect(failed.body.toString(), isNot(contains(_hand)));
    });

    test('rejects concurrent decisions for the same token', () async {
      await gateway.close();
      final started = Completer<void>();
      final release = Completer<void>();
      gateway = BridgeGatewayService(
        backend: _DeferredBackend(started, release),
      );
      port = await gateway.start();
      final token = await _token(port);
      final first = _decision(port, token);
      await started.future;
      final duplicate = await _decision(port, token);
      expect(duplicate.status, 429);
      release.complete();
      expect((await first).status, 200);
    });

    test('health endpoint has no session or private details', () async {
      final res = await _request(port, 'GET', '/healthz');
      expect(res.status, 200);
      expect(res.body, {'version': 1, 'status': 'ready'});
      expect(res.body.toString(), isNot(contains(_hand)));
    });
  });
}

class _DeferredBackend implements GatewayDecisionBackend {
  _DeferredBackend(this.started, this.release);
  final Completer<void> started;
  final Completer<void> release;

  @override
  Future<Map<String, Object?>> decide(
      String route, Map<String, String> allowedFields) async {
    if (!started.isCompleted) started.complete();
    await release.future;
    return {'bid': 'PASS'};
  }
}
