import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_gateway/bridge_gateway.dart';
import 'package:test/test.dart';

class _ServerBot implements GatewayDecisionBackend {
  int calls = 0;
  final seen = <Map<String, String>>[];
  Completer<void>? gate;

  @override
  Future<Map<String, Object?>> decide(
      String route, Map<String, String> fields) async {
    calls++;
    seen.add(Map.of(fields));
    if (gate != null) await gate!.future;
    if (route == 'bid') return {'bid': 'PASS'};
    if (route == 'lead') return {'card': 'D2'};
    return {'card': 'D3'};
  }
}

Future<({int code, Map<String, dynamic> data})> _post(
    int port, String endpoint, Map<String, Object?> body,
    {String? token}) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(
        Uri.parse('http://127.0.0.1:' + port.toString() + endpoint));
    req.headers.contentType = ContentType.json;
    if (token != null) req.headers.set('Authorization', 'Bearer ' + token);
    req.write(jsonEncode(body));
    final res = await req.close();
    final text = await utf8.decoder.bind(res).join();
    return (code: res.statusCode, data: jsonDecode(text) as Map<String, dynamic>);
  } finally {
    client.close(force: true);
  }
}

Map<String, Object?> _action(int version, String id, String kind,
        String key, String value) =>
    {'version': 1, 'expected_version': version, 'request_id': id,
     'action': {'kind': kind, key: value}};

Map<String, Object?> _advance(int version, String id) =>
    {'version': 1, 'expected_version': version, 'request_id': id};

void main() {
  group('A4.3.2 server-owned game, identity and in-memory dedup', () {
    late BridgeGatewayService gateway;
    late _ServerBot backend;
    late int port;
    late String token;

    setUp(() async {
      backend = _ServerBot();
      gateway = BridgeGatewayService(
        backend: backend,
        dealFactory: Deal.suitPerSeat,
      );
      port = await gateway.start();
      final issued = await _post(port, '/v1/sessions/anonymous',
          {'version': 1});
      expect(issued.code, 201);
      token = issued.data['access_token'] as String;
    });
    tearDown(() async => gateway.close());

    test('requires capability and returns only owner projection', () async {
      final unauth = await _post(
          port, '/v1/games/view', {'version': 1});
      expect(unauth.code, 401);
      final v = await _post(
          port, '/v1/games/view', {'version': 1}, token: token);
      expect(v.code, 200);
      final view = v.data['view'] as Map<String, dynamic>;
      expect(view['viewer'], 'N');
      expect(view['version'], 0);
      expect(view['dummyCards'], isNull);
      expect(view['ownCards'], hasLength(13));
      expect((view['ownCards'] as List).every((e) =>
          (e as String).startsWith('C')), isTrue);
      expect(v.data.keys, isNot(contains('deal')));
      expect(view.keys, isNot(contains('hands')));
      expect(view.keys, isNot(contains('deal')));
      expect(backend.calls, 0);
    });

    test('client cannot select a seat or inject its own Deal', () async {
      final baseline = await _post(port, '/v1/games/view',
          {'version': 1}, token: token);
      final forged = await _post(port, '/v1/games/action',
          {..._action(0, 'forged_a1', 'bid', 'call', '1NT'),
           'seat': 'E', 'deal': 'SECRET_FULL_DEAL'},
          token: token);
      expect(forged.code, 400);
      final forgedAction = await _post(port, '/v1/games/action',
          {..._action(0, 'forged_a2', 'bid', 'call', '1NT'),
           'action': {'kind': 'bid', 'call': '1NT', 'seat': 'E'}},
          token: token);
      expect(forgedAction.code, 400);
      final after = await _post(port, '/v1/games/view',
          {'version': 1}, token: token);
      expect(after.data, baseline.data);
      expect(backend.calls, 0);
    });

    test('bid advances exactly once and duplicate id returns cached view',
        () async {
      final body = _action(0, 'action_unique_01', 'bid', 'call', '1NT');
      final first = await _post(port, '/v1/games/action', body, token: token);
      expect(first.code, 200);
      expect((first.data['view'] as Map)['version'], 1);
      final replay = await _post(port, '/v1/games/action', body, token: token);
      expect(replay.code, 200);
      expect(replay.data, first.data);
      final current = await _post(port, '/v1/games/view',
          {'version': 1}, token: token);
      expect((current.data['view'] as Map)['version'], 1);
      expect(backend.calls, 0);
    });

    test('stale version and same id with changed payload fail closed',
        () async {
      final id = 'request_abcd_1234';
      expect((await _post(port, '/v1/games/action',
          _action(0, id, 'bid', 'call', '1NT'), token: token)).code, 200);
      expect((await _post(port, '/v1/games/action',
          _action(1, id, 'bid', 'call', 'PASS'), token: token)).code, 409);
      expect((await _post(port, '/v1/games/action',
          _action(0, 'request_next_12', 'bid', 'call', 'PASS'),
          token: token)).code, 409);
      final v = await _post(port, '/v1/games/view',
          {'version': 1}, token: token);
      expect((v.data['view'] as Map)['version'], 1);
    });

    test('BEN sees only server-derived seat view and public dummy after lead',
        () async {
      expect((await _post(port, '/v1/games/action',
          _action(0, 'bid_north_0001', 'bid', 'call', '1NT'),
          token: token)).code, 200);
      final first = await _post(port, '/v1/games/advance',
          _advance(1, 'bot_step_00001'), token: token);
      expect(first.code, 200);
      final view = first.data['view'] as Map<String, dynamic>;
      expect(view['version'], 5); // 3 passes + East opening lead
      expect(view['viewer'], 'N');
      expect(view['dummyExposed'], isTrue);
      expect(view['dummyCards'], hasLength(13));
      expect((view['dummyCards'] as List).every((e) =>
          (e as String).startsWith('H')), isTrue);
      expect(backend.calls, 4);
      expect(backend.seen[0]['seat'], 'E');
      expect(backend.seen[0]['hand'], '..AKQJT98765432.');
      expect(backend.seen[0].containsKey('dummy'), isFalse);
      expect(backend.seen.last['seat'], 'E');
      expect(backend.seen.last.containsKey('dummy'), isFalse);
      for (final fields in backend.seen) {
        expect(fields, isNot(contains('deal')));
      }
      final replay = await _post(port, '/v1/games/advance',
          _advance(1, 'bot_step_00001'), token: token);
      expect(replay.code, 200);
      expect(replay.data, first.data);
      expect(backend.calls, 4);
    });

    test('different credential cannot read the first token game', () async {
      final newToken = (await _post(port, '/v1/sessions/anonymous',
          {'version': 1})).data['access_token'] as String;
      await _post(port, '/v1/games/action',
          _action(0, 'first_bid_0001', 'bid', 'call', '1NT'), token: token);
      final second = await _post(port, '/v1/games/view',
          {'version': 1}, token: newToken);
      expect((second.data['view'] as Map)['version'], 0);
      // First session's access token never travels in the request body.
      final forged = await _post(port, '/v1/games/view',
          {'version': 1, 'access_token': token}, token: newToken);
      expect(forged.code, 400);
    });

    test('backend unavailable causes 503 and no fabricated bot commit',
        () async {
      await gateway.close();
      gateway = BridgeGatewayService(dealFactory: Deal.suitPerSeat);
      port = await gateway.start();
      token = (await _post(port, '/v1/sessions/anonymous',
          {'version': 1})).data['access_token'] as String;
      expect((await _post(port, '/v1/games/action',
          _action(0, 'before_bot_001', 'bid', 'call', '1NT'),
          token: token)).code, 200);
      final failed = await _post(port, '/v1/games/advance',
          _advance(1, 'no_model_000001'), token: token);
      expect(failed.code, 503);
      final fresh = await _post(port, '/v1/games/view',
          {'version': 1}, token: token);
      expect((fresh.data['view'] as Map)['version'], 1);
    });
  });
}
