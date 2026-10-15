import 'dart:async';

import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_ben_adapter/bridge_ben_adapter.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Counts only successful BEN HTTP calls. Never logs URLs, private cards,
/// request query maps, HTTP payloads or PBN in test output.
class _RouteCounter implements BenTransport {
  _RouteCounter(this.delegate);

  final BenTransport delegate;
  final Map<String, int> calls = <String, int>{};

  @override
  Future<Map<String, dynamic>> get(
    String route,
    Map<String, String> query,
  ) async {
    // Explicitly prevent accidental omniscient request fields in live runs.
    const allowed = {'hand', 'seat', 'dealer', 'vul', 'ctx', 'dummy', 'played'};
    if (!allowed.containsAll(query.keys)) {
      throw StateError('Unexpected BEN request field');
    }
    if (route == '/bid' || route == '/lead') {
      if (query.containsKey('dummy') || query.containsKey('played')) {
        throw StateError('BEN received early dummy/history data');
      }
    }
    final result = await delegate.get(route, query);
    calls.update(route, (n) => n + 1, ifAbsent: () => 1);
    return result;
  }
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

/// A real HTTP request cannot be completed by advancing fake widget time.
/// Yield to actual network async work, then paint its result in Chrome.
Future<void> _awaitBen(WidgetTester tester, BridgeSession session) async {
  await tester.runAsync(() async {
    final elapsed = Stopwatch()..start();
    while (session.busy && elapsed.elapsed < const Duration(minutes: 3)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  });
  await tester.pumpAndSettle();
  expect(session.busy, false, reason: 'BEN request exceeded live UI timeout');
  expect(session.errorCode, isNull,
      reason: 'Real BEN failed; no deterministic fallback is allowed');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('M2-F07 real Chrome + real BEN /bid /lead /play, 52 cards',
      (tester) async {
    const origin = String.fromEnvironment(
      'BEN_BASE_URL',
      defaultValue: 'http://127.0.0.1:8085',
    );
    final realHttp = BenHttpTransport(
      baseUri: Uri.parse(origin),
      timeout: const Duration(seconds: 120),
    );
    addTearDown(realHttp.close);

    final counter = _RouteCounter(realHttp);
    final session = BridgeSession(
      botFactory: (mode) {
        if (mode != OpponentMode.ben) {
          throw StateError('M2-F07 requires BEN mode, not Demo');
        }
        return BenBotPolicy(counter);
      },
    );
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));

    // Select the real model using exactly the same menu a player sees.
    await _tap(tester, 'mode_selector');
    await tester.pumpAndSettle();
    await tester.tap(find.text('真正 BEN API').last);
    await tester.pumpAndSettle();
    await _tap(tester, 'new_game');
    await _awaitBen(tester, session);
    expect(session.mode, OpponentMode.ben);
    expect(session.view!.viewer, Seat.north);
    expect(session.view!.ownCards.length, 13);
    expect(session.view!.dummyCards, isNull);

    // The fixed human 3NT opening guarantees a played contract.
    // It is a deterministic integration fixture, not a bidding lesson.
    await _tap(tester, 'bid_level');
    await tester.pumpAndSettle();
    await tester.tap(find.text('3').last);
    await tester.pumpAndSettle();
    await _tap(tester, 'make_bid');
    await _awaitBen(tester, session);

    var dummyClicks = 0;
    var handClicks = 0;
    for (var i = 0; i < 70 && !session.finished; i++) {
      final view = session.view!;
      expect(view.canAct, true,
          reason: 'All non-human actions should have been processed');
      if (view.phase == Phase.auction) {
        await _tap(tester, 'pass');
      } else if (view.phase == Phase.play) {
        final card = view.legalCards.first.code;
        final isDummy = view.turn != view.viewer;
        if (isDummy) {
          expect(view.contract?.dummy, view.turn);
          expect(view.dummyExposed, true);
          dummyClicks++;
        } else {
          handClicks++;
        }
        await _tap(tester, '${isDummy ? 'dummy_card_' : 'hand_card_'}$card');
      } else {
        fail('Unexpected active human phase');
      }
      await _awaitBen(tester, session);
    }

    final view = session.view!;
    expect(session.finished, true);
    expect(view.completedTricks.length, 13);
    expect(view.remainingCards.values, everyElement(0));
    expect(view.nsScore, isNotNull);
    expect(view.version, view.auction.length + 52);
    expect(dummyClicks, greaterThan(0));
    expect(handClicks, greaterThan(0));
    expect(find.byKey(const Key('final_result')), findsOneWidget);
    for (final route in ['/bid', '/lead', '/play']) {
      expect(counter.calls[route], greaterThan(0),
          reason: 'Missing true BEN response on $route');
    }
    // Sanitized evidence only: per-route counts, no hands or raw BEN requests.
    // ignore: avoid_print
    print('M2_F07_REAL_BEN_CHROME_PASS: '
        'tricks=13 cards=52 dummyClicks=$dummyClicks '
        'handClicks=$handClicks routeCounts=${counter.calls}');
  });
}
