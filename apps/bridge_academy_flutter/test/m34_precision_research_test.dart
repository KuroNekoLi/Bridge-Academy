import 'dart:convert';

import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/gateway_http_api.dart';
import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('M3.4 explicitly opted-in bilingual Precision research option '
      'pins the NS/EW profile and locks both during game', (tester) async {
    const enabled = bool.fromEnvironment(
      'BA_M34_RESEARCH_PRECISION', defaultValue: false);
    if (!enabled) return; // general-release widgets do not advertise Precision

    Map<String, dynamic>? sessionRequest;
    final view = PlayerView.forSeat(
      GameState.start(Deal.suitPerSeat(), Seat.north, Vulnerability.none),
      Seat.north,
    );
    final client = MockClient((request) async {
      if (request.url.path == '/v1/sessions/anonymous') {
        sessionRequest = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({
          'version': 1,
          'access_token': 'A' * 43,
          'token_type': 'Bearer',
          'expires_in': 900,
          'scope': 'ai:decision',
          'game_systems': GameSystems(
            northSouth: ConventionCatalog.precisionMeckwell,
            eastWest: ConventionCatalog.sayc,
          ).toJson(),
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
    expect(find.textContaining('研究環境'), findsOneWidget);
    await tester.tap(find.byKey(const Key('gateway_system_ns')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(
        'NS · BBA Meckwell Precision V1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('gateway_system_ew')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EW · SAYC 標準黃卡').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('gateway_start')));
    await tester.pumpAndSettle();

    expect(sessionRequest!['game_systems'], {
      'northSouth': 'BA-PRECISION-MECKWELL',
      'eastWest': 'BA-SAYC',
    });
    expect(find.byKey(const Key('gateway_systems_locked')), findsOneWidget);
    expect(tester.widget<DropdownButton<String>>(
      find.byKey(const Key('gateway_system_ns')),
    ).onChanged, isNull);
    expect(find.byKey(const Key('bridge_board')), findsOneWidget);
  });
}
