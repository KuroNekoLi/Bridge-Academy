import '../test_driver/bidding_test_actions.dart';
import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tapBoardButton(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tapBiddingAware(tester, finder, key);
  await tester.pumpAndSettle();
}

void main() {
  test('P1-A1: board metadata goes to coordinator and PlayerView', () async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await session.newGame(
      boardNumber: 2, humanSeat: Seat.east,
    );
    expect(session.board, BoardDefinition.forNumber(2));
    expect(session.view!.viewer, Seat.east);
    expect(session.view!.dealer, Seat.east);
    expect(session.view!.vulnerability, Vulnerability.ns);
    expect(session.view!.canAct, true);
    expect(session.view!.auction, isEmpty);
    expect(session.view!.dummyCards, isNull);
    expect(session.view!.toJson().containsKey('hands'), false);
    await session.submitCall(const Pass());
    expect(session.finished, true);
    expect(session.view!.nsScore, 0);

    await session.nextBoard();
    expect(session.board.number, 3);
    expect(session.view!.dealer, Seat.south);
    expect(session.view!.vulnerability, Vulnerability.ew);
    expect(session.view!.viewer, Seat.east);
    expect(session.view!.auction.length, 3);
    expect(session.view!.canAct, true);
    expect(session.view!.dummyCards, isNull);
    expect(session.completedReplay, isNull);
    await session.submitCall(const Pass());
    // South opens the auction on Board 3. Demo Bot bids 1NT;
    // East's last Pass ends the auction, not the full board.
    expect(session.finished, false);
    expect(session.view!.phase, Phase.play);
    expect(session.view!.contract!.declarer, Seat.south);
    expect(session.view!.contract!.label, '1NT');
    expect(session.view!.dummyExposed, true);
    expect(session.view!.nsScore, isNull);
  });

  test('P1-A1: no next-board without finishing and reject invalid number',
      () async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await session.newGame();
    await session.nextBoard();
    expect(session.board.number, 1);
    expect(session.view!.auction, isEmpty);

    await expectLater(
      session.newGame(boardNumber: 0),
      throwsRangeError,
    );
    expect(session.board.number, 1);
    expect(session.view!.auction, isEmpty);
  });

  test('P1-A1: replay exact physical deal versus next board new deal',
      () async {
    final first = Deal.shuffled(seed: 2026);
    final second = Deal.shuffled(seed: 2027);
    final deals = [first, second];
    final session = BridgeSession(freshDealFactory: () => deals.removeAt(0));
    addTearDown(session.dispose);
    await session.newGame(boardMode: BoardMode.fresh);
    final originalHand = session.view!.ownCards.toSet();
    expect(originalHand, first.hands[Seat.north]);
    await session.submitCall(const Pass());
    expect(session.finished, true);
    final originalReplay = session.completedReplay!;

    await session.replaySameBoard();
    expect(session.board.number, 1);
    expect(session.view!.ownCards.toSet(), originalHand);
    expect(session.view!.dealer, Seat.north);
    expect(session.view!.vulnerability, Vulnerability.none);
    expect(session.completedReplay, isNull);
    expect(deals.length, 1);
    await session.submitCall(const Pass());
    expect(session.finished, true);
    expect(session.completedReplay!.historyFingerprint,
        originalReplay.historyFingerprint);

    await session.nextBoard();
    expect(session.board.number, 2);
    expect(session.view!.dealer, Seat.east);
    expect(session.view!.vulnerability, Vulnerability.ns);
    expect(session.view!.ownCards.toSet(), second.hands[Seat.north]);
    expect(session.view!.ownCards.toSet(), isNot(originalHand));
    expect(deals, isEmpty);
    expect(session.view!.dummyCards, isNull);
  });

  testWidgets('P1-A1: localized Board 1/2 and replay/next controls',
      (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tapBoardButton(tester, 'new_game');
    expect(find.text('牌號: 1'), findsOneWidget);
    expect(find.text('發牌者: 北（N）'), findsOneWidget);
    expect(find.text('局況: 雙方無局'), findsOneWidget);
    expect(find.byKey(const Key('next_board')), findsNothing);

    await tapBoardButton(tester, 'pass');
    expect(session.finished, true);
    expect(find.byKey(const Key('next_board')), findsOneWidget);
    expect(find.byKey(const Key('replay_same_board')), findsOneWidget);

    await tapBoardButton(tester, 'replay_same_board');
    expect(session.finished, false);
    expect(session.board.number, 1);
    expect(find.byKey(const Key('replay_panel')), findsNothing);
    await tapBoardButton(tester, 'pass');
    await tapBoardButton(tester, 'next_board');

    expect(session.board.number, 2);
    expect(session.view!.dealer, Seat.east);
    expect(session.view!.vulnerability, Vulnerability.ns);
    expect(find.text('牌號: 2'), findsOneWidget);
    expect(find.text('發牌者: 東（E）'), findsOneWidget);
    expect(find.text('局況: 南北有局'), findsOneWidget);
    expect(session.view!.dummyCards, isNull);
    expect(find.byKey(const Key('replay_panel')), findsNothing);

    await tapBoardButton(tester, 'toggle_locale');
    expect(find.text('Board: 2'), findsOneWidget);
    expect(find.text('Dealer: East (E)'), findsOneWidget);
    expect(find.text('Vulnerability: N/S vulnerable'), findsOneWidget);
  });
}
