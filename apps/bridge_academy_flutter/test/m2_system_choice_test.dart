import 'dart:convert';

import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/gateway_game_session.dart';
import 'package:bridge_academy_flutter/src/gateway_http_api.dart';
import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('Gateway session only transmits canonical NS/EW IDs, not model commits',
      () async {
    Map<String, dynamic>? issuedBody;
    final view = PlayerView.forSeat(
      GameState.start(Deal.suitPerSeat(), Seat.north, Vulnerability.none),
      Seat.north,
    );
    final api = GatewayHttpApi(
      origin: Uri.parse('https://gateway.example.test'),
      client: MockClient((request) async {
        expect(request.url.query, isEmpty);
        expect(request.headers, isNot(contains('X-Deal')));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (request.url.path == '/v1/sessions/anonymous') {
          issuedBody = body;
          return http.Response(jsonEncode({
            'version': 1,
            'access_token': 'A' * 43,
            'token_type': 'Bearer',
            'expires_in': 900,
            'scope': 'ai:decision',
            'game_systems': GameSystems(
              northSouth: ConventionCatalog.twoOverOne,
              eastWest: ConventionCatalog.sayc,
            ).toJson(),
          }), 201);
        }
        return http.Response(
            jsonEncode({'version': 1, 'view': view.toJson()}), 200);
      }),
    );
    final session = GatewayGameSession(api);
    addTearDown(session.dispose);
    await session.startNewGame(northSouth: 'BA-21GF', eastWest: 'BA-SAYC');
    expect(session.errorCode, isNull);
    expect(session.started, true);
    expect(session.gameSystems!.northSouth.modelId, '21GF');
    expect(session.gameSystems!.eastWest.modelId, 'SAYC');
    expect(issuedBody, {
      'version': 1,
      'game_systems': {'northSouth': 'BA-21GF', 'eastWest': 'BA-SAYC'},
    });
    expect(issuedBody.toString(), isNot(contains('ad8608af')));
    expect(issuedBody.toString(), isNot(contains('hand')));
  });

  test('Gateway session rejects mismatched server system fingerprint', () async {
    final api = GatewayHttpApi(
      origin: Uri.parse('https://gateway.example.test'),
      client: MockClient((request) async {
        return http.Response(jsonEncode({
          'version': 1,
          'access_token': 'A' * 43,
          'token_type': 'Bearer',
          'expires_in': 900,
          'scope': 'ai:decision',
          'game_systems': GameSystems(
            northSouth: ConventionCatalog.sayc,
            eastWest: ConventionCatalog.sayc,
          ).toJson(),
        }), 201);
      }),
    );
    final session = GatewayGameSession(api);
    addTearDown(session.dispose);
    await session.startNewGame(northSouth: 'BA-21GF', eastWest: 'BA-SAYC');
    expect(session.errorCode, 'gatewayInvalidResponse');
    expect(session.started, false);
  });

  testWidgets('Gateway table provides pregame NS/EW choice and locks mid-game',
      (tester) async {
    Map<String, dynamic>? issued;
    final view = PlayerView.forSeat(
        GameState.start(Deal.suitPerSeat(), Seat.north, Vulnerability.none),
        Seat.north);
    final client = MockClient((request) async {
      if (request.url.path == '/v1/sessions/anonymous') {
        issued = jsonDecode(request.body) as Map<String, dynamic>;
        final gameSystems = GameSystems(
          northSouth: ConventionCatalog.twoOverOne,
          eastWest: ConventionCatalog.sayc,
        );
        return http.Response(jsonEncode({
          'version': 1,
          'access_token': 'A' * 43,
          'token_type': 'Bearer',
          'expires_in': 900,
          'scope': 'ai:decision',
          'game_systems': gameSystems.toJson(),
        }), 201);
      }
      return http.Response(jsonEncode({
        'version': 1, 'view': view.toJson(),
      }), 200);
    });
    addTearDown(client.close);
    await tester.pumpWidget(BridgeAcademyApp(
      gatewayApi: GatewayHttpApi(
        origin: Uri.parse('https://gateway.example.test'),
        client: client,
      ),
    ));
    expect(find.byKey(const Key('gateway_system_ns')), findsOneWidget);
    expect(find.byKey(const Key('gateway_system_ew')), findsOneWidget);
    await tester.tap(find.byKey(const Key('gateway_system_ns')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NS · 2/1 進局迫叫').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('gateway_system_ew')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EW · SAYC 標準黃卡').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('gateway_start')));
    await tester.pumpAndSettle();
    expect(issued!['game_systems'], {
      'northSouth': 'BA-21GF', 'eastWest': 'BA-SAYC',
    });
    expect(find.byKey(const Key('gateway_systems_locked')), findsOneWidget);
    final nsWidget = tester.widget<DropdownButton<String>>(
        find.byKey(const Key('gateway_system_ns')));
    expect(nsWidget.onChanged, isNull);
    expect(find.byKey(const Key('bridge_board')), findsOneWidget);
  });
}
