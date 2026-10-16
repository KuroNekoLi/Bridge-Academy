import 'dart:convert';
import 'dart:io';

import 'package:bridge_gateway/bridge_gateway.dart';
import 'package:test/test.dart';

const hand = 'AKQ.JT9.876.5432';
const base = <String, String>{
  'hand': hand, 'seat': 'N', 'dealer': 'E', 'vul': 'NS', 'ctx': '1N-P',
};

Future<Map<String, dynamic>> post(
    int port, String path, Map<String, Object?> body,
    {String? token, int expected = 200}) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(
        Uri.parse('http://127.0.0.1:$port$path'));
    req.headers.contentType = ContentType.json;
    if (token != null) req.headers.set('authorization', 'Bearer $token');
    req.write(jsonEncode(body));
    final res = await req.close();
    final decoded = jsonDecode(await utf8.decoder.bind(res).join())
        as Map<String, dynamic>;
    expect(res.statusCode, expected);
    return decoded;
  } finally {
    client.close(force: true);
  }
}

Future<String> token(int port) async =>
    (await post(port, '/v1/sessions/anonymous', {'version': 1},
        expected: 201))['access_token'] as String;

Future<Map<String, dynamic>> decide(
    int port, String credential, String route, Map<String, String> input,
    {int expected = 200}) =>
    post(port, '/v1/ai/decision',
        {'version': 1, 'route': route, 'input': input},
        token: credential, expected: expected);

void main() {
  group('A4.3.1 loopback worker (real HTTP, fake BEN only)', () {
    late HttpServer ben;
    late BridgeGatewayService gateway;
    late BenLoopbackBackend backend;
    late int gatewayPort;
    String? seenPath;
    Map<String, String>? seenQuery;
    Map<String, Object?> reply = {'bid': 'PASS'};
    int status = 200;

    setUp(() async {
      seenPath = null;
      seenQuery = null;
      status = 200;
      reply = {'bid': 'PASS', 'private_debug': 'SECRET_DEBUG'};
      ben = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      ben.listen((request) async {
        seenPath = request.uri.path;
        seenQuery = request.uri.queryParameters;
        request.response.statusCode = status;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(reply));
        await request.response.close();
      });
      backend = BenLoopbackBackend(
          origin: Uri.parse('http://127.0.0.1:' + ben.port.toString()));
      gateway = BridgeGatewayService(backend: backend);
      gatewayPort = await gateway.start();
    });

    tearDown(() async {
      await gateway.close();
      backend.close();
      await ben.close(force: true);
    });

    test('Gateway POST only sends filtered data to loopback BEN GET', () async {
      final result = await decide(gatewayPort, await token(gatewayPort),
          'bid', base);
      expect(result, {'version': 1, 'decision': {'bid': 'PASS'}});
      expect(seenPath, '/bid');
      expect(seenQuery, base);
      expect(result.toString(), isNot(contains('SECRET_DEBUG')));
      expect(result.toString(), isNot(contains(hand)));
    });

    test('lead and play only forward public dummy when supplied', () async {
      final t = await token(gatewayPort);
      reply = {'card': 'D2', 'internal': 'PRIVATE'};
      expect((await decide(gatewayPort, t, 'lead', base))['decision'],
          {'card': 'D2'});
      expect(seenPath, '/lead');
      expect(seenQuery, isNot(contains('dummy')));
      final play = {...base, 'dummy': '.AKQJT98765432..', 'played': 'S2'};
      expect((await decide(gatewayPort, t, 'play', play))['decision'],
          {'card': 'D2'});
      expect(seenPath, '/play');
      expect(seenQuery?['dummy'], '.AKQJT98765432..');
    });

    test('forbidden Deal rejected before reaching internal BEN', () async {
      await decide(gatewayPort, await token(gatewayPort),
          'bid', {...base, 'deal': 'PRIVATE'}, expected: 400);
      expect(seenPath, isNull);
    });

    test('reject remote, DNS, credentials, redirects and arbitrary paths', () {
      for (final uri in [
        'http://localhost:8085',
        'http://example.org:8085',
        'http://192.168.1.4:8085',
        'https://127.0.0.1:8085',
        'http://user:secret@127.0.0.1:8085',
        'http://127.0.0.1:8085/private',
        'http://127.0.0.1:8085?hand=PRIVATE',
      ]) {
        expect(() => BenLoopbackBackend(origin: Uri.parse(uri)),
            throwsArgumentError, reason: uri);
      }
    });

    test('invalid BEN action and BEN errors are sanitized', () async {
      final t = await token(gatewayPort);
      reply = {'bid': '8NT', 'internal': 'PRIVATE'};
      final invalid = await decide(gatewayPort, t, 'bid', base,
          expected: 502);
      expect(invalid.toString(), isNot(contains('PRIVATE')));
      reply = {'error': 'SECRET_HAND'};
      await decide(gatewayPort, t, 'bid', base, expected: 502);
      status = 302;
      reply = {'bid': 'PASS'};
      await decide(gatewayPort, t, 'bid', base, expected: 503);
    });

    test('unreachable BEN fails closed without Demo fallback', () async {
      await ben.close(force: true);
      final res = await decide(gatewayPort, await token(gatewayPort),
          'bid', base, expected: 503);
      expect(res, {'version': 1,
        'error': {'code': 'upstream_unavailable'}});
    });
  });
}
