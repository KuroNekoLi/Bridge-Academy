import 'dart:convert';
import 'dart:io';

import 'package:bridge_gateway/bridge_gateway.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:test/test.dart';

Future<({int code, Map<String, dynamic> body})> _send(
    int port, String route, Map<String, Object?> data, {String? bearer}) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(
        Uri.parse('http://127.0.0.1:$port$route'));
    req.headers.contentType = ContentType.json;
    if (bearer != null) req.headers.set('authorization', 'Bearer $bearer');
    req.write(jsonEncode(data));
    final res = await req.close();
    return (code: res.statusCode,
        body: jsonDecode(await utf8.decoder.bind(res).join())
            as Map<String, dynamic>);
  } finally {
    client.close(force: true);
  }
}

Map<String, Object?> get _profileChoice => {
  'version': 1,
  'game_systems': {'northSouth': 'BA-21GF', 'eastWest': 'BA-SAYC'},
};

void main() {
  group('M2.2/2.3 server-owned system routing, stub HTTP BEN', () {
    late HttpServer ben;
    late BridgeGatewayService gateway;
    late BenLoopbackBackend backend;
    late int port;
    List<Map<String, String>> observed = [];
    bool capabilities = true;

    setUp(() async {
      observed = [];
      capabilities = true;
      ben = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      ben.listen((request) async {
        final route = request.uri.path;
        request.response.headers.contentType = ContentType.json;
        if (route == '/') {
          request.response.write(jsonEncode({
            'playsSystems': capabilities ? ['21GF', 'SAYC'] : ['21GF'],
            'readsSystems': capabilities ? ['21GF', 'SAYC'] : ['21GF'],
            'defaults': {'ourSystem': '21GF'},
          }));
        } else {
          observed.add({...request.uri.queryParameters, 'route': route});
          request.response.write(jsonEncode(
              route == '/bid' ? {'bid': 'PASS'} : {'card': 'D2'}));
        }
        await request.response.close();
      });
      backend = BenLoopbackBackend(
        origin: Uri.parse('http://127.0.0.1:${ben.port}/'),
        pinnedBenRevision: ConventionCatalog.benCandidateRevision,
      );
      gateway = BridgeGatewayService(
        backend: backend,
        dealFactory: Deal.suitPerSeat,
      );
      port = await gateway.start();
    });

    tearDown(() async {
      await gateway.close();
      backend.close();
      await ben.close(force: true);
    });

    test('bootstrap server resolves IDs and returns pinned hash', () async {
      final issued = await _send(port, '/v1/sessions/anonymous',
          _profileChoice);
      expect(issued.code, 201);
      final systems = GameSystems.fromTrustedJson(issued.body['game_systems']);
      expect(systems.northSouth.modelId, '21GF');
      expect(systems.eastWest.modelId, 'SAYC');
      expect(systems.fingerprint, isNotEmpty);
      final token = issued.body['access_token'] as String;
      final view = await _send(port, '/v1/games/view',
          {'version': 1}, bearer: token);
      expect(view.code, 200);
      expect(view.body.containsKey('gameSystems'), false);
      expect(view.body.toString(), isNot(contains('dealPbn')));
      expect(observed, isEmpty);
    });

    test('private model fields follow east-west seat without client hand', () async {
      final issued = await _send(port, '/v1/sessions/anonymous',
          _profileChoice);
      final token = issued.body['access_token'] as String;
      final first = await _send(port, '/v1/games/action', {
        'version': 1, 'expected_version': 0,
        'request_id': 'm22_human_bid_01',
        'action': {'kind': 'bid', 'call': '1NT'},
      }, bearer: token);
      expect(first.code, 200);
      final bot = await _send(port, '/v1/games/advance', {
        'version': 1, 'expected_version': 1,
        'request_id': 'm22_bots_round_01',
      }, bearer: token);
      expect(bot.code, 200);
      expect(observed.where((e) => e['route'] == '/bid').length, 3);
      expect(observed[0]['seat'], 'E');
      expect(observed[0]['ourSystem'], 'SAYC');
      expect(observed[0]['theirSystem'], '21GF');
      expect(observed[1]['seat'], 'S');
      expect(observed[1]['ourSystem'], '21GF');
      expect(observed[2]['seat'], 'W');
      expect(observed[2]['ourSystem'], 'SAYC');
      expect(observed.any((e) => e.containsKey('deal')), false);
      expect((bot.body['view'] as Map)['version'], greaterThanOrEqualTo(4));
    });

    test('unknown model, revision injection and mixed legacy rejected', () async {
      for (final choice in [
        {'northSouth': 'BA-PRECISION', 'eastWest': 'BA-SAYC'},
        {'northSouth': 'BA-21GF', 'eastWest': 'LEGACY_UNVERIFIED'},
        {'northSouth': 'BA-21GF', 'eastWest': 'BA-SAYC', 'revision': 2},
      ]) {
        final res = await _send(port, '/v1/sessions/anonymous',
            {'version': 1, 'game_systems': choice});
        expect(res.code, 400);
      }
      expect(observed, isEmpty);
    });

    test('unsupported worker cannot create game or continue pinned game',
        () async {
      capabilities = false;
      final blocked = await _send(port, '/v1/sessions/anonymous',
          _profileChoice);
      expect(blocked.code, 503);
      expect(blocked.body['error'], {'code': 'system_router_unavailable'});
      capabilities = true;
      final accepted = await _send(port, '/v1/sessions/anonymous',
          _profileChoice);
      final token = accepted.body['access_token'] as String;
      capabilities = false;
      final after = await _send(port, '/v1/games/action', {
        'version': 1, 'expected_version': 0,
        'request_id': 'm22_backend_gone',
        'action': {'kind': 'bid', 'call': 'PASS'},
      }, bearer: token);
      expect(after.code, 503);
      final view = await _send(
          port, '/v1/games/view', {'version': 1}, bearer: token);
      expect((view.body['view'] as Map)['version'], 0);
    });
  });
}
