import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('M2-F10: fixed training deal and injectable fresh deal are distinct',
      () async {
    final first = Deal.shuffled(seed: 300);
    final second = Deal.shuffled(seed: 301);
    final injected = [first, second];
    final session = BridgeSession(
      freshDealFactory: () => injected.removeAt(0),
    );
    addTearDown(session.dispose);

    await session.newGame();
    final training = session.view!.ownCards.toSet();
    expect(session.boardMode, BoardMode.training);
    expect(session.view!.dummyCards, isNull);

    await session.newGame(boardMode: BoardMode.fresh);
    expect(session.boardMode, BoardMode.fresh);
    expect(session.view!.ownCards.toSet(), first.hands[Seat.north]);
    expect(session.view!.toJson().containsKey('hands'), false);
    expect(session.mode, OpponentMode.demo);

    await session.newGame(boardMode: BoardMode.fresh);
    expect(session.view!.ownCards.toSet(), second.hands[Seat.north]);
    expect(session.view!.ownCards.toSet(), isNot(first.hands[Seat.north]));
    expect(injected, isEmpty);

    await session.newGame(boardMode: BoardMode.training);
    expect(session.view!.ownCards.toSet(), training);
    expect(session.boardMode, BoardMode.training);
  });

  testWidgets('M2-F10: user can switch fixed/shuffled deal source in Flutter',
      (tester) async {
    final seed = Deal.shuffled(seed: 20261015);
    final session = BridgeSession(freshDealFactory: () => seed);
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));

    await tester.tap(find.byKey(const Key('board_mode_selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新隨機牌局').last);
    await tester.pumpAndSettle();

    final start = find.byKey(const Key('new_game'));
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(session.boardMode, BoardMode.fresh);
    expect(session.view!.ownCards.toSet(), seed.hands[Seat.north]);
    expect(session.view!.dummyCards, isNull);
  });
}

