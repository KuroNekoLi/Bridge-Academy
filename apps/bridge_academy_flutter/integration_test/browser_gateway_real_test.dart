import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/gateway_table.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// A4.4 live browser acceptance. Real Chrome uses the actual localhost
/// Gateway HTTP server which calls pinned Python BEN (NEVER MockClient).
///
/// The server, not this test or Flutter, constructs the complete 52-card Deal.
/// Never print bearer credentials, cards, PBN or HTTP request bodies.
Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _waitForServer(WidgetTester tester) async {
  final session = tester.widget<GatewayTable>(
    find.byType(GatewayTable),
  ).session;
  await tester.runAsync(() async {
    final elapsed = Stopwatch()..start();
    while (session.busy && elapsed.elapsed < const Duration(minutes: 4)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  });
  await tester.pumpAndSettle();
  expect(session.busy, false, reason: 'Gateway request exceeded live timeout');
  expect(session.errorCode, isNull,
      reason: 'Real server failure must never fall back to a Demo Bot');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('A4.4 real Chrome -> Gateway -> pinned BEN complete board',
      (tester) async {
    const origin = String.fromEnvironment('BRIDGE_GATEWAY_ORIGIN');
    expect(origin, 'http://127.0.0.1:8086',
        reason: 'This E2E requires an explicitly configured local Gateway');

    await tester.pumpWidget(const BridgeAcademyApp());
    expect(find.byKey(const Key('gateway_mode_notice')), findsOneWidget);
    expect(find.byKey(const Key('mode_selector')), findsNothing);
    await _tap(tester, 'gateway_start');
    await _waitForServer(tester);

    final session = tester.widget<GatewayTable>(
      find.byType(GatewayTable),
    ).session;
    expect(session.started, true);
    expect(session.view!.viewer, Seat.north);
    expect(session.view!.version, 0);
    expect(session.view!.dummyCards, isNull);

    // Opening 3NT drives the robot seats through the actual Python model,
    // including bidding and (if contracted) opening lead and card play.
    await _tap(tester, 'bid_level');
    await tester.pumpAndSettle();
    await tester.tap(find.text('3').last);
    await tester.pumpAndSettle();
    await _tap(tester, 'make_bid');
    await _waitForServer(tester);

    var dummyClicks = 0;
    var handClicks = 0;
    for (var step = 0; step < 70 && !session.finished; step++) {
      final view = session.view!;
      expect(view.canAct, true,
          reason: 'Gateway must process robot turns before returning');
      if (view.phase == Phase.auction) {
        await _tap(tester, 'pass');
      } else if (view.phase == Phase.play) {
        final card = view.legalCards.first.code;
        final isDummy = view.turn != view.viewer;
        if (isDummy) {
          expect(view.dummyExposed, true);
          dummyClicks++;
        } else {
          handClicks++;
        }
        await _tap(
            tester, (isDummy ? 'dummy_card_' : 'hand_card_') + card);
      } else {
        fail('Unexpected active phase before completion');
      }
      await _waitForServer(tester);
    }

    final finished = session.view!;
    expect(session.finished, true);
    expect(finished.completedTricks.length, 13);
    expect(finished.remainingCards.values, everyElement(0));
    expect(finished.version, finished.auction.length + 52);
    expect(finished.nsScore, isNotNull);
    expect(dummyClicks + handClicks, greaterThan(0));
    expect(find.byKey(const Key('gateway_final_result')), findsOneWidget);

    // Safe observability, no private hand/Deal, access token or BEN URL.
    // ignore: avoid_print
    print('A4_4_REAL_BROWSER_GATEWAY_BEN_PASS: '
        'tricks=13 cards=52 dummyClicks=$dummyClicks '
        'handClicks=$handClicks');
  });
}
