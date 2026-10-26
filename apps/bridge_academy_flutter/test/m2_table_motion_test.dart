import 'package:bridge_academy_flutter/src/app_copy.dart';
import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_card_face.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_public_card_entrance.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_table_components.dart';
import 'package:bridge_core/bridge_core.dart' as bridge;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

bridge.GameState start() => bridge.GameState.justDeclareStart(
  bridge.Deal.shuffled(seed: 56),
  bridge.Seat.north,
  bridge.Vulnerability.none,
  const bridge.Contract(
    level: 1,
    strain: bridge.Strain.notrump,
    declarer: bridge.Seat.south,
  ),
);

bridge.GameState play(bridge.GameState state) => bridge.BridgeGame.apply(
  state,
  bridge.CardAction(
    state.actorToPlay!,
    state.turn!,
    state.legalCards(state.turn!).first,
  ),
);

Future<void> render(
  WidgetTester tester,
  bridge.GameState state, {
  bool reduced = false,
}) => tester.pumpWidget(
  MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Scaffold(
        body: BridgeCurrentTrick(
          view: bridge.PlayerView.forSeat(state, bridge.Seat.south),
          copy: const AppCopy(true),
        ),
      ),
    ),
  ),
);

double opacity(WidgetTester tester, Finder entrance) => tester
    .widget<Opacity>(
      find.descendant(of: entrance, matching: find.byType(Opacity)),
    )
    .opacity;

void main() {
  testWidgets(
    'M2-F56 accepted public card animates once; rebuild cannot restart',
    (tester) async {
      var state = start();
      await render(tester, state);
      state = play(state);
      await render(tester, state);
      final entrance = find.byType(BridgePublicCardEntrance);
      expect(opacity(tester, entrance), 0);
      await tester.pump(const Duration(milliseconds: 90));
      final halfway = opacity(tester, entrance);
      expect(halfway, inExclusiveRange(0, 1));
      await render(tester, state);
      expect(opacity(tester, entrance), halfway);
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacity(tester, entrance), 1);
      expect(state.version, 1);
      expect(
        tester.widget<BridgeCardFace>(find.byType(BridgeCardFace)).card,
        state.currentTrick.single.card,
      );
    },
  );

  testWidgets(
    'M2-F56 restore is static; preference cancels in-flight animation',
    (tester) async {
      var state = play(start());
      await render(tester, state);
      expect(opacity(tester, find.byType(BridgePublicCardEntrance)), 1);
      state = play(state);
      await render(tester, state);
      final last = find.byType(BridgePublicCardEntrance).last;
      expect(opacity(tester, last), 0);
      await render(tester, state, reduced: true);
      expect(opacity(tester, last), 1);
      await render(tester, state);
      expect(opacity(tester, last), 1);
      expect(state.version, 2);
    },
  );

  testWidgets('M2-F56 rapid full deal removes old cards and disposes tickers', (
    tester,
  ) async {
    var state = start();
    await render(tester, state);
    final seen = <bridge.Card>{};
    while (!state.isFinished) {
      final card = state.legalCards(state.turn!).first;
      expect(seen.add(card), isTrue);
      state = play(state);
      await render(tester, state);
      expect(
        tester
            .widgetList<BridgeCardFace>(find.byType(BridgeCardFace))
            .map((face) => face.card),
        orderedEquals(state.currentTrick.map((play) => play.card)),
      );
    }
    expect(seen.length, 52);
    expect(state.tricks.length, 13);
    expect(state.version, 52);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('M2-F56 public card semantics exist before fade completes', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var state = start();
      await render(tester, state);
      state = play(state);
      await render(tester, state);
      final publicPlay = state.currentTrick.single;
      final label =
          '${const AppCopy(true).seat(publicPlay.handOwner.letter)}: '
          '${const AppCopy(true).cardName(publicPlay.card.code)}';
      expect(find.semantics.byLabel(label), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('M2-F56 motion cannot delay another legal card command', (
    tester,
  ) async {
    var state = play(play(start())); // East is next.
    var commands = 0;
    Future<void> table() {
      final view = bridge.PlayerView.forSeat(state, bridge.Seat.south);
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                BridgeCurrentTrick(view: view, copy: const AppCopy(true)),
                BridgePlayerHand(
                  view: view,
                  copy: const AppCopy(true),
                  actionsPaused: false,
                  onPlayCard: (card) {
                    commands++;
                    state = bridge.BridgeGame.apply(
                      state,
                      bridge.CardAction(state.actorToPlay!, state.turn!, card),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    await table();
    state = play(state); // East's newly accepted public card animates.
    await table();
    expect(opacity(tester, find.byType(BridgePublicCardEntrance).last), 0);
    final legal = bridge.PlayerView.forSeat(
      state,
      bridge.Seat.south,
    ).legalCards.first;
    final target = find.byKey(Key('hand_card_${legal.code}'));
    await tester.ensureVisible(target);
    await tester.tap(target);
    expect(commands, 1);
    expect(state.version, 4);
    await table();
    expect(find.byType(BridgePublicCardEntrance), findsNothing);
    await tester.pumpAndSettle();
    expect(commands, 1);
  });

  testWidgets('M2-F56 bilingual visit setting preserves game; OS wins', (
    tester,
  ) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await session.newGame();
    final view = session.view!;
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tester.tap(find.byKey(const Key('nav_me')));
    await tester.pumpAndSettle();
    final toggle = find.byKey(const Key('reduce_motion'));
    expect(find.text('減少動態效果'), findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    expect(MediaQuery.disableAnimationsOf(tester.element(toggle)), isTrue);
    await tester.tap(find.byKey(const Key('toggle_locale')));
    await tester.pumpAndSettle();
    expect(find.text('Reduce motion'), findsOneWidget);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(MediaQuery.disableAnimationsOf(tester.element(toggle)), isTrue);
    await tester.tap(find.byKey(const Key('nav_play')));
    await tester.pumpAndSettle();
    expect(session.view!.version, view.version);
    expect(session.view!.ownCards, view.ownCards);
  });
}
