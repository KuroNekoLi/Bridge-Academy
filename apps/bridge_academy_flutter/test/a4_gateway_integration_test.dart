import 'dart:convert';

import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/gateway_game_session.dart';
import 'package:bridge_academy_flutter/src/gateway_http_api.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _AuthorityFixture {
  _AuthorityFixture()
      : coordinator = SinglePlayerCoordinator(
          deal: Deal.suitPerSeat(),
          dealer: Seat.north,
          vulnerability: Vulnerability.none,
          humanSeat: Seat.north,
          bot: const DeterministicTrainingBot(),
        );

  final SinglePlayerCoordinator coordinator;
  final seenIds = <String>[];
  final seenRoutes = <String>[];
  final cached = <String, Map<String, dynamic>>{};
  bool loseFirstActionResponse = false;
  bool denied = false;

  Future<http.Response> handle(http.Request request) async {
    expect(request.method, 'POST');
    expect(request.url.scheme, 'https');
    expect(request.url.host, 'gateway.example.test');
    expect(request.url.query, isEmpty);
    expect(request.body, isNot(contains('hand')));
    expect(request.body, isNot(contains('deal')));
    final path = request.url.path;
    seenRoutes.add(path);
    if (path == '/v1/sessions/anonymous') {
      expect(request.headers, isNot(contains('Authorization')));
      return http.Response(jsonEncode({
        'version': 1, 'access_token': 'A' * 43,
        'token_type': 'Bearer', 'expires_in': 900,
        'scope': 'ai:decision',
      }), 201);
    }
    expect(request.headers['Authorization'], 'Bearer ${'A' * 43}');
    if (denied) {
      return http.Response(jsonEncode({
        'version': 1, 'error': {'code': 'unauthorized'},
      }), 401);
    }
    Map<String, dynamic> reply([String? id]) {
      final value = <String, dynamic>{
        'version': 1,
        'view': coordinator.humanView.toJson(),
      };
      if (id != null) {
        value['request_id'] = id;
      }
      return value;
    }
    if (path == '/v1/games/view') {
      return http.Response(jsonEncode(reply()), 200);
    }
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    final id = body['request_id'] as String;
    seenIds.add(id);
    if (cached.containsKey(id)) {
      return http.Response(jsonEncode(cached[id]), 200);
    }
    expect(body['expected_version'], coordinator.version);
    if (path == '/v1/games/action') {
      final action = body['action'] as Map<String, dynamic>;
      if (action['kind'] == 'bid') {
        final value = action['call'];
        final Call call = value == 'PASS'
            ? const Pass()
            : const Bid(1, Strain.notrump);
        coordinator.submitHuman(
          CallAction(Seat.north, call),
          expectedVersion: body['expected_version'] as int,
        );
      } else {
        final card = coordinator.humanView.legalCards.first;
        coordinator.submitHuman(
          CardAction(Seat.north, coordinator.humanView.turn!, card),
          expectedVersion: body['expected_version'] as int,
        );
      }
    } else if (path == '/v1/games/advance') {
      await coordinator.runBots(maxActions: 60);
    } else {
      return http.Response('{}', 404);
    }
    final response = reply(id);
    cached[id] = response;
    if (path == '/v1/games/action' && loseFirstActionResponse) {
      loseFirstActionResponse = false;
      throw StateError('Secret HTTP error never reaches player');
    }
    return http.Response(jsonEncode(response), 200);
  }
}

void main() {
  test('Gateway HTTPS boundary rejects insecure external hosts and URL tricks',
      () {
    for (final bad in [
      'http://remote.example.test',
      'https://u:p@gateway.example.test',
      'https://gateway.example.test/other',
      'https://gateway.example.test?hand=SECRET',
    ]) {
      expect(() => GatewayHttpApi(origin: Uri.parse(bad)), throwsArgumentError);
    }
    final dev = GatewayHttpApi(origin: Uri.parse('http://127.0.0.1:8086'));
    dev.close();
  });

  test('GatewaySession authenticates then plays from filtered server PlayerView',
      () async {
    final authority = _AuthorityFixture();
    final client = MockClient(authority.handle);
    final api = GatewayHttpApi(
        origin: Uri.parse('https://gateway.example.test'), client: client);
    final session = GatewayGameSession(api);
    addTearDown(session.dispose);
    addTearDown(client.close);
    await session.startNewGame();
    expect(session.view!.viewer, Seat.north);
    expect(session.view!.version, 0);
    expect(session.view!.dummyCards, isNull);
    expect(session.errorCode, isNull);

    await session.submitCall(const Bid(1, Strain.notrump));
    expect(session.view!.version, 5);
    expect(session.view!.dummyExposed, isTrue);
    expect(session.view!.dummyCards, hasLength(13));
    expect(authority.seenRoutes, contains('/v1/games/advance'));
    expect(authority.seenIds.toSet().length, authority.seenIds.length);
    expect(session.errorCode, isNull);
  });

  test('HTTP lost response: refresh then replay SAME request ID, no double bid',
      () async {
    final authority = _AuthorityFixture()..loseFirstActionResponse = true;
    final client = MockClient(authority.handle);
    final session = GatewayGameSession(GatewayHttpApi(
        origin: Uri.parse('https://gateway.example.test'), client: client));
    addTearDown(session.dispose);
    addTearDown(client.close);
    await session.startNewGame();
    await session.submitCall(const Bid(1, Strain.notrump));
    expect(session.errorCode, 'gatewayOffline');
    expect(session.hasPending, isTrue);
    expect(authority.coordinator.version, 1);
    final originalId = authority.seenIds.single;
    await session.refreshServerView();
    expect(session.view!.version, 1);
    expect(session.errorCode, 'gatewayRetryPending');
    await session.retry();
    expect(authority.seenIds.first, originalId);
    expect(authority.seenIds[1], originalId);
    expect(authority.coordinator.humanView.auction.first.call.code, '1NT');
    expect(session.view!.version, 5);
    expect(session.hasPending, isFalse);
  });

  test('expired/invalid token is visible and does not create Demo fallbacks',
      () async {
    final fixture = _AuthorityFixture();
    final client = MockClient(fixture.handle);
    final session = GatewayGameSession(GatewayHttpApi(
        origin: Uri.parse('https://gateway.example.test'), client: client));
    addTearDown(session.dispose);
    addTearDown(client.close);
    await session.startNewGame();
    fixture.denied = true;
    await session.refreshServerView();
    expect(session.errorCode, 'gatewayExpired');
    expect(session.view!.version, 0);
    expect(fixture.seenRoutes.where((r) =>
        r == '/v1/sessions/anonymous').length, 1);
  });

  test('rejects server DTO containing forbidden full-Deal fields', () async {
    final fixture = _AuthorityFixture();
    final client = MockClient((request) async {
      if (request.url.path == '/v1/sessions/anonymous') {
        return fixture.handle(request);
      }
      final filtered = fixture.coordinator.humanView.toJson();
      return http.Response(jsonEncode({
        'version': 1,
        'view': {...filtered, 'hands': 'FORBIDDEN_OPPONENT_HANDS'},
      }), 200);
    });
    final session = GatewayGameSession(GatewayHttpApi(
      origin: Uri.parse('https://gateway.example.test'), client: client));
    addTearDown(session.dispose);
    addTearDown(client.close);
    await session.startNewGame();
    expect(session.started, isFalse);
    expect(session.errorCode, 'gatewayInvalidResponse');
  });

  testWidgets('opt-in Gateway table localized and never shows Demo mode',
      (tester) async {
    final fixture = _AuthorityFixture();
    final client = MockClient(fixture.handle);
    addTearDown(client.close);
    final api = GatewayHttpApi(
      origin: Uri.parse('https://gateway.example.test'), client: client);
    await tester.pumpWidget(BridgeAcademyApp(gatewayApi: api));
    expect(find.byKey(const Key('gateway_mode_notice')), findsOneWidget);
    expect(find.byKey(const Key('mode_selector')), findsNothing);
    expect(find.byKey(const Key('gateway_empty')), findsOneWidget);

    await tester.tap(find.byKey(const Key('gateway_start')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bridge_board')), findsOneWidget);
    expect(find.byKey(const Key('gateway_error_message')), findsNothing);
    expect(find.byKey(const Key('dummy_revealed')), findsNothing);
    await tester.tap(find.byKey(const Key('toggle_locale')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Server-owned Gateway table'), findsOneWidget);
    expect(find.byKey(const Key('mode_selector')), findsNothing);
  });
}
