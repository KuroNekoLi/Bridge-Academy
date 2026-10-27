import '../test_driver/bidding_test_actions.dart';
import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_ben_adapter/bridge_ben_adapter.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class AuditedBot implements BotPolicy {
  AuditedBot(this.delegate);
  final BotPolicy delegate;
  int dummyTurns = 0;

  @override
  Future<GameAction> choose(PlayerView view) async {
    final isDummy = view.phase == Phase.play &&
        view.contract != null &&
        view.viewer == view.contract!.declarer &&
        view.turn == view.contract!.dummy;
    final action = await delegate.choose(view);
    if (isDummy) {
      if (action is! CardAction ||
          action.actor != view.contract!.declarer ||
          action.handOwner != view.contract!.dummy ||
          !view.legalCards.contains(action.card)) {
        throw StateError('Robot failed declarer/dummy authorization');
      }
      dummyTurns++;
    }
    return action;
  }
}

class RouteCounter implements BenTransport {
  RouteCounter(this.delegate);
  final BenTransport delegate;
  final Map<String, int> counts = {};
  @override
  Future<Map<String, dynamic>> get(String route, Map<String, String> query) async {
    const keys = {'hand', 'seat', 'dealer', 'vul', 'ctx', 'dummy', 'played'};
    if (!keys.containsAll(query.keys)) throw StateError('Unexpected BEN field');
    final response = await delegate.get(route, query);
    counts.update(route, (n) => n + 1, ifAbsent: () => 1);
    return response;
  }
}

Future<void> tap(WidgetTester tester, String key) async {
  final item = find.byKey(Key(key));
  await tester.ensureVisible(item);
  await tester.pump();
  await tapBiddingAware(tester, item, key);
  await tester.pump();
}

Future<void> waitBen(WidgetTester tester, BridgeSession session) async {
  await tester.runAsync(() async {
    final elapsed = Stopwatch()..start();
    while (session.busy && elapsed.elapsed < const Duration(minutes: 3)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  });
  await tester.pumpAndSettle();
  expect(session.busy, false, reason: 'Live BEN stalled');
  expect(session.errorCode, isNull, reason: 'No BEN-to-Demo fallback');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('M2-F09 real BEN North declarer controls South Dummy in Chrome',
      (tester) async {
    const origin = String.fromEnvironment('BEN_BASE_URL',
        defaultValue: 'http://127.0.0.1:8085');
    final http = BenHttpTransport(
        baseUri: Uri.parse(origin), timeout: const Duration(seconds: 120));
    addTearDown(http.close);
    final requests = RouteCounter(http);
    final bot = AuditedBot(BenBotPolicy(requests));
    final session = BridgeSession(botFactory: (mode) {
      if (mode != OpponentMode.ben) {
        throw StateError('Requires real BEN');
      }
      return bot;
    });
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tap(tester, 'seat_selector');
    await tester.pumpAndSettle();
    await tester.tap(find.text('東（E）').last);
    await tester.pumpAndSettle();
    await tap(tester, 'mode_selector');
    await tester.pumpAndSettle();
    await tester.tap(find.text('真正 BEN API').last);
    await tester.pumpAndSettle();
    await tap(tester, 'new_game');
    await waitBen(tester, session);
    expect(session.mode, OpponentMode.ben);
    expect(session.view!.viewer, Seat.east);

    var defenderTurns = 0;
    for (var n = 0; n < 90 && !session.finished; n++) {
      final view = session.view!;
      expect(view.canAct, true);
      if (view.phase == Phase.auction) {
        await tap(tester, 'pass');
      } else if (view.phase == Phase.play) {
        expect(view.turn, Seat.east);
        defenderTurns++;
        await tap(tester, 'hand_card_${view.legalCards.first.code}');
      } else {
        fail('Unexpected live game phase');
      }
      await waitBen(tester, session);
    }

    final result = session.view!;
    expect(session.finished, true);
    expect(result.contract?.declarer, Seat.north);
    expect(result.contract?.dummy, Seat.south);
    expect(result.dummyExposed, true);
    expect(result.completedTricks.length, 13);
    expect(result.remainingCards.values, everyElement(0));
    expect(result.version, result.auction.length + 52);
    expect(result.nsScore, isNotNull);
    expect(defenderTurns, 13);
    expect(bot.dummyTurns, 13);
    expect(requests.counts['/bid'], greaterThan(0));
    expect(requests.counts['/play'], greaterThan(0));
    expect(find.byKey(const Key('final_result')), findsOneWidget);
    // /lead was performed by human East, so no robot /lead is required.
    // ignore: avoid_print
    print('M2_F09_REAL_BEN_DECLARER_PASS dummyTurns=13 '
        'defenderTurns=13 cards=52 tricks=13 routes=${requests.counts}');
  });
}

