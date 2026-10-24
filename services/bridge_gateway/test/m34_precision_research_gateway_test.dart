import 'dart:convert';
import 'dart:io';

import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_gateway/bridge_gateway.dart';
import 'package:bridge_precision_adapter/bridge_precision_adapter.dart';
import 'package:test/test.dart';

final class _NativeResearchStub implements BbaTableBidTransport {
  bool ready = true;
  final List<Map<String, Object>> requests = [];

  @override
  Future<bool> researchReady() async => ready;

  @override
  Future<Map<String, Object?>> tableBid(Map<String, Object> fields) async {
    requests.add(fields);
    return {
      'provider': 'BBA_NATIVE_EPBOT',
      'profileId': PrecisionResearchCatalog.selectedProductProfileId,
      'revision': 1,
      'cardSha256': PrecisionResearchCatalog.selectedCardSha256,
      'bid': 'PASS',
    };
  }
}

Future<({int status, Map<String, dynamic> body})> _send(
    int port, String route, Map<String, Object?> data,
    {String? token}) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(
        Uri.parse('http://127.0.0.1:$port$route'));
    req.headers.contentType = ContentType.json;
    if (token != null) req.headers.set('Authorization', 'Bearer $token');
    req.write(jsonEncode(data));
    final response = await req.close();
    return (
      status: response.statusCode,
      body: jsonDecode(await utf8.decoder.bind(response).join())
          as Map<String, dynamic>,
    );
  } finally {
    client.close(force: true);
  }
}

Map<String, Object?> _choice(String ns, String ew) => {
  'version': 1,
  'game_systems': {'northSouth': ns, 'eastWest': ew},
};

void main() {
  for (final swap in [false, true]) {
    test('M3.4 BBA all-seat auction routing with Precision '
        '${swap ? 'EW' : 'NS'} and immutable Gateway game', () async {
      final bba = _NativeResearchStub();
      final gateway = BridgeGatewayService(
        backend: const UnavailableDecisionBackend(),
        precisionResearch: bba,
        enablePrecisionResearch: true,
        dealFactory: Deal.suitPerSeat,
      );
      final port = await gateway.start();
      try {
        final ns = swap ? 'BA-SAYC' : 'BA-PRECISION-MECKWELL';
        final ew = swap ? 'BA-PRECISION-MECKWELL' : 'BA-SAYC';
        final session = await _send(
            port, '/v1/sessions/anonymous', _choice(ns, ew));
        expect(session.status, 201);
        final systems =
            GameSystems.fromTrustedJson(session.body['game_systems']);
        expect(systems.northSouth.profileId, ns);
        expect(systems.eastWest.profileId, ew);
        final bearer = session.body['access_token'] as String;
        final human = await _send(port, '/v1/games/action', {
          'version': 1, 'request_id': 'm34_human_test_01',
          'expected_version': 0,
          'action': {'kind': 'bid', 'call': '3NT'},
        }, token: bearer);
        expect(human.status, 200);
        final bots = await _send(port, '/v1/games/advance', {
          'version': 1, 'request_id': 'm34_bba_bots_01',
          'expected_version': 1,
        }, token: bearer);
        expect(bots.status, 200);
        expect(bba.requests.length, 3);
        expect(bba.requests.map((q) => q['seat']), ['E', 'S', 'W']);
        expect(bba.requests.every((q) =>
            q['northSouth'] == ns && q['eastWest'] == ew), true);
        expect(bba.requests.every((q) =>
            !q.containsKey('deal') && !q.containsKey('dummy') &&
            !q.containsKey('pbn') && !q.containsKey('hands')), true);
        expect((bots.body['view'] as Map)['phase'], 'play');
        expect((bots.body['view'] as Map).containsKey('gameSystems'), false);
        expect((bots.body['view'] as Map).containsKey('dealPbn'), false);
      } finally {
        await gateway.close();
      }
    });
  }

  test('M3.4 research remains disabled unless opted in, and fails closed',
      () async {
    final bba = _NativeResearchStub();
    final no = BridgeGatewayService(
      backend: const UnavailableDecisionBackend(),
      precisionResearch: bba,
    );
    final port1 = await no.start();
    try {
      final denied = await _send(port1, '/v1/sessions/anonymous',
          _choice('BA-PRECISION-MECKWELL', 'BA-SAYC'));
      expect(denied.status, 503);
      expect(denied.body['error'], {'code': 'research_precision_disabled'});
    } finally {
      await no.close();
    }

    bba.ready = false;
    final offline = BridgeGatewayService(
      backend: const UnavailableDecisionBackend(),
      precisionResearch: bba, enablePrecisionResearch: true,
    );
    final port2 = await offline.start();
    try {
      final denied = await _send(port2, '/v1/sessions/anonymous',
          _choice('BA-PRECISION-MECKWELL', 'BA-SAYC'));
      expect(denied.status, 503);
      expect(denied.body['error'], {'code': 'research_precision_unavailable'});
      expect(bba.requests, isEmpty);
      final invalid = await _send(port2, '/v1/sessions/anonymous',
          _choice('BA-PRECISION-MECKWELL', 'BA-PRECISION-MECKWELL'));
      expect(invalid.status, 400);
      expect(invalid.body['error'], {'code': 'unsupported_system'});
    } finally {
      await offline.close();
    }
  });
}
