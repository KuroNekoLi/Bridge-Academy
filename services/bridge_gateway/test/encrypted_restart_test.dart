import 'dart:convert';
import 'dart:io';

import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_gateway/bridge_gateway.dart';
import 'package:test/test.dart';

class _Ben implements GatewayDecisionBackend {
  _Ben({this.failAt = -1});
  final int failAt;
  int calls = 0;
  @override
  Future<Map<String, Object?>> decide(String route, Map<String, String> fields) async {
    calls++;
    if (calls == failAt) throw StateError('PRIVATE_BEN_URL_SECRET');
    if (route == 'bid') return {'bid': 'PASS'};
    return {'card': 'D2'};
  }
}

Future<({int status, Map<String, dynamic> body})> _post(
    int port, String route, Map<String, Object?> body,
    {String? token}) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(
        Uri.parse('http://127.0.0.1:$port$route'));
    request.headers.contentType = ContentType.json;
    if (token != null) request.headers.set('Authorization', 'Bearer $token');
    request.write(jsonEncode(body));
    final response = await request.close();
    final text = await utf8.decoder.bind(response).join();
    return (status: response.statusCode,
        body: jsonDecode(text) as Map<String, dynamic>);
  } finally {
    client.close(force: true);
  }
}

Future<String> _token(int port) async {
  final result = await _post(port, '/v1/sessions/anonymous', {'version': 1});
  expect(result.status, 201);
  return result.body['access_token'] as String;
}

Map<String, Object?> _action(int version, String id, String call) => {
  'version': 1, 'expected_version': version, 'request_id': id,
  'action': {'kind': 'bid', 'call': call}
};
Map<String, Object?> _advance(int version, String id) => {
  'version': 1, 'expected_version': version, 'request_id': id
};

void main() {
  group('A4.3.2b encrypted restart and replay (localhost, stub BEN)', () {
    late Directory tmp;
    late BridgeGatewayService gateway;
    late int port;
    final key = List<int>.generate(32, (i) => i + 1);

    Future<void> restart({GatewayDecisionBackend? backend,
        DateTime Function()? clock, List<int>? secret}) async {
      await gateway.close();
      gateway = BridgeGatewayService(
        checkpointStore: EncryptedSessionStore(
          directory: tmp,
          key: secret ?? key,
        ),
        backend: backend ?? _Ben(),
        dealFactory: Deal.suitPerSeat,
        clock: clock,
      );
      port = await gateway.start();
    }

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('bridge-gateway-a432b-');
      gateway = BridgeGatewayService(
        checkpointStore: EncryptedSessionStore(directory: tmp, key: key),
        backend: _Ben(),
        dealFactory: Deal.suitPerSeat,
      );
      port = await gateway.start();
    });
    tearDown(() async {
      await gateway.close();
      await tmp.delete(recursive: true);
    });

    test('save encrypted PBN and hashed token, resume unchanged game', () async {
      final token = await _token(port);
      final first = await _post(port, '/v1/games/action',
        _action(0, 'persist_bid_0001', '1NT'), token: token);
      expect(first.status, 200);
      final snapshot = ((await tmp.list()
          .where((f) => f.path.endsWith('.session')).first) as File).readAsString();
      final cipher = await snapshot;
      expect(cipher, isNot(contains('N:')));
      expect(cipher, isNot(contains('dealPbn')));
      expect(cipher, isNot(contains(token)));
      expect(cipher, isNot(contains('persist_bid_0001')));
      await restart();
      final resumed = await _post(port, '/v1/games/view',
          {'version': 1}, token: token);
      expect(resumed.status, 200);
      expect((resumed.body['view'] as Map)['version'], 1);
      final duplicate = await _post(port, '/v1/games/action',
          _action(0, 'persist_bid_0001', '1NT'), token: token);
      expect(duplicate.status, 200);
      expect(duplicate.body, first.body);
      final conflict = await _post(port, '/v1/games/action',
          _action(0, 'persist_bid_0001', 'PASS'), token: token);
      expect(conflict.status, 409);
      final stale = await _post(port, '/v1/games/action',
          _action(0, 'other_bid_00001', 'PASS'), token: token);
      expect(stale.status, 409);
    });

    test('partial bot round is checkpointed and same ID resumes after restart',
        () async {
      await restart(backend: _Ben(failAt: 2));
      final token = await _token(port);
      expect((await _post(port, '/v1/games/action',
          _action(0, 'initial_bid_0001', '1NT'), token: token)).status, 200);
      final inFlight = await _post(port, '/v1/games/advance',
          _advance(1, 'bot_batch_00001'), token: token);
      expect(inFlight.status, 503);
      expect(inFlight.body.toString(), isNot(contains('PRIVATE_BEN_URL_SECRET')));
      final partiallyDone = await _post(port, '/v1/games/view',
          {'version': 1}, token: token);
      expect((partiallyDone.body['view'] as Map)['version'], 2);
      final restoredBot = _Ben();
      await restart(backend: restoredBot);
      final afterRestart = await _post(port, '/v1/games/view',
          {'version': 1}, token: token);
      expect((afterRestart.body['view'] as Map)['version'], 2);
      final resume = await _post(port, '/v1/games/advance',
          _advance(1, 'bot_batch_00001'), token: token);
      expect(resume.status, 200);
      expect((resume.body['view'] as Map)['version'], 5);
      expect(restoredBot.calls, 3); // East PASS was already committed.
      await restart(backend: _Ben());
      final repeated = await _post(port, '/v1/games/advance',
          _advance(1, 'bot_batch_00001'), token: token);
      expect(repeated.status, 200);
      expect(repeated.body, resume.body);
    });

    test('wrong key fails closed, no fresh empty session substitution', () async {
      final token = await _token(port);
      await _post(port, '/v1/games/action',
          _action(0, 'preserve_game_01', '1NT'), token: token);
      await gateway.close();
      final broken = BridgeGatewayService(
        checkpointStore: EncryptedSessionStore(
          directory: tmp, key: List<int>.filled(32, 0),
        ),
        dealFactory: Deal.suitPerSeat,
      );
      await expectLater(broken.start(), throwsA(isA<Exception>()));
      gateway = BridgeGatewayService(
        checkpointStore: EncryptedSessionStore(directory: tmp, key: key),
        dealFactory: Deal.suitPerSeat,
      );
      port = await gateway.start();
      final view = await _post(port, '/v1/games/view',
          {'version': 1}, token: token);
      expect((view.body['view'] as Map)['version'], 1);
    });

    test('durable mode disables legacy caller-supplied-hand decision API',
        () async {
      final token = await _token(port);
      final denied = await _post(port, '/v1/ai/decision', {
        'version': 1,
        'route': 'bid',
        'input': {'hand': 'SECRET_PRIVATE_PBN', 'seat': 'E'},
      }, token: token);
      expect(denied.status, 404);
      expect(denied.body.toString(), isNot(contains('SECRET_PRIVATE_PBN')));
    });
  });
}
