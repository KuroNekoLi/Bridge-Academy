import 'package:bridge_academy_flutter/src/app_copy.dart';
import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_card_face.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_focus_table.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_public_card_entrance.dart';
import 'package:bridge_core/bridge_core.dart' as b;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

b.GameState initial() => b.GameState.justDeclareStart(
  b.Deal.shuffled(seed: 57),
  b.Seat.north,
  b.Vulnerability.none,
  const b.Contract(level: 1, strain: b.Strain.notrump, declarer: b.Seat.south),
);
b.GameState advance(b.GameState s) => b.BridgeGame.apply(
  s,
  b.CardAction(s.actorToPlay!, s.turn!, s.legalCards(s.turn!).first),
);

Future<void> showTable(
  WidgetTester tester,
  b.GameState state, {
  ValueChanged<b.Card>? onPlay,
  bool paused = false,
  bool reduced = false,
  String? error,
  VoidCallback? retry,
  double textScale = 1,
}) => tester.pumpWidget(
  MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        disableAnimations: reduced,
        textScaler: TextScaler.linear(textScale),
      ),
      child: BridgeFocusTable(
        view: b.PlayerView.forSeat(state, b.Seat.south),
        copy: const AppCopy(true),
        boardNumber: 1,
        modeLabel: 'Demo',
        actionsPaused: paused,
        onPlayCard: onPlay ?? (_) {},
        onSubmitCall: (_) {},
        error: error,
        onRetry: retry,
      ),
    ),
  ),
);

void main() {
  testWidgets('M2-F61 public plays fly from their compass seat only once', (
    tester,
  ) async {
    var state = initial();
    await showTable(tester, state);
    final expected = <b.Seat, Offset>{
      b.Seat.north: const Offset(0, -30),
      b.Seat.east: const Offset(48, 0),
      b.Seat.south: const Offset(0, 30),
      b.Seat.west: const Offset(-48, 0),
    };
    for (var index = 0; index < 4; index++) {
      state = advance(state);
      await showTable(tester, state);
      if (state.currentTrick.isEmpty) break;
      final compass = find.byKey(const Key('focus_trick_compass'));
      expect(compass, findsOneWidget);
      final entrances = find.descendant(
        of: compass,
        matching: find.byType(BridgePublicCardEntrance),
      );
      expect(entrances, findsNWidgets(state.currentTrick.length));
      for (var playIndex = 0; playIndex < state.currentTrick.length; playIndex++) {
        final play = state.currentTrick[playIndex];
        final entrance = entrances.at(playIndex);
        expect(tester.widget<BridgePublicCardEntrance>(entrance).from,
            expected[play.handOwner]);
      }
      final newest = entrances.last;
      final opacity = find.descendant(of: newest, matching: find.byType(Opacity));
      expect(tester.widget<Opacity>(opacity).opacity, 0);
      await showTable(tester, state);
      expect(tester.widget<Opacity>(opacity).opacity, 0);
      await tester.pump(const Duration(milliseconds: 190));
      expect(tester.widget<Opacity>(opacity).opacity, 1);
    }
    expect(state.tricks.length, 1);
  });

  for (final width in [320.0, 375.0, 768.0, 1280.0]) {
    testWidgets('M2-F57 focused play fits $width without vertical scrolling', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 812);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = advance(initial());
      await showTable(tester, state);
      await tester.pumpAndSettle();
      final scroll = tester.widget<SingleChildScrollView>(
        find.byKey(const Key('focus_viewport')),
      );
      final position = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byWidget(scroll),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      expect(position.maxScrollExtent, 0);
      final hand = find.byKey(
        Key(
          'focus_card_S_${b.PlayerView.forSeat(state, b.Seat.south).ownCards.first.code}',
        ),
      );
      expect(tester.getBottomRight(hand).dy, lessThanOrEqualTo(812));
      final rendered = tester
          .widgetList<BridgeCardFace>(find.byType(BridgeCardFace))
          .map((w) => w.card)
          .toSet();
      final view = b.PlayerView.forSeat(state, b.Seat.south);
      expect(
        rendered,
        unorderedEquals({
          ...view.ownCards,
          ...view.dummyCards!,
          ...view.currentTrick.map((p) => p.card),
        }),
      );
      expect(tester.takeException(), isNull);
      // Every public trick size and the collection overlay fit this width.
      var progressing = state;
      while (!progressing.isFinished) {
        progressing = advance(progressing);
        await showTable(tester, progressing);
        expect(tester.takeException(), isNull, reason: 'version ${progressing.version}');
      }
    });
  }

  testWidgets('M2-F57 large text uses reachable scroll fallback', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await showTable(tester, advance(advance(advance(initial()))), textScale: 2);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final hand = find.byType(LongPressDraggable<BridgeCardDrag>).last;
    await tester.ensureVisible(hand);
    expect(tester.getCenter(hand).dy, lessThan(600));
  });

  testWidgets('M2-F58 drag cancel, stale and duplicate drops cannot submit', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 812);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = advance(initial()); // Dummy North, selected by South.
    var calls = 0;
    b.Card? chosen;
    await showTable(
      tester,
      state,
      onPlay: (card) {
        calls++;
        chosen = card;
      },
    );
    final view = b.PlayerView.forSeat(state, b.Seat.south);
    final card = view.legalCards.first;
    final source = find.byKey(Key('focus_drag_N_${card.code}'));
    await tester.ensureVisible(source);
    final outside = await tester.startGesture(tester.getCenter(source));
    await tester.pump(const Duration(milliseconds: 600));
    await outside.moveTo(const Offset(1, 1));
    await outside.up();
    await tester.pumpAndSettle();
    expect(calls, 0);
    final gesture = await tester.startGesture(tester.getCenter(source));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('focus_drag_feedback')), findsOneWidget);
    await gesture.moveTo(
      tester.getCenter(find.byKey(const Key('focus_drop_zone'))),
    );
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(calls, 1);
    expect(chosen, card);
    final target = tester.widget<DragTarget<BridgeCardDrag>>(
      find.byType(DragTarget<BridgeCardDrag>),
    );
    target.onAcceptWithDetails!(
      DragTargetDetails(
        data: BridgeCardDrag(view.version, b.Seat.north, card),
        offset: Offset.zero,
      ),
    );
    expect(calls, 1);
    await showTable(tester, advance(state), onPlay: (_) => calls++);
    final updated = tester.widget<DragTarget<BridgeCardDrag>>(
      find.byType(DragTarget<BridgeCardDrag>),
    );
    expect(
      updated.onWillAcceptWithDetails!(
        DragTargetDetails(
          data: BridgeCardDrag(view.version, b.Seat.north, card),
          offset: Offset.zero,
        ),
      ),
      isFalse,
    );
    expect(calls, 1);
  });

  testWidgets('M2-F58 busy and wrong-owner inputs fail closed; retry visible', (
    tester,
  ) async {
    final state = advance(initial());
    var calls = 0;
    var retries = 0;
    await showTable(
      tester,
      state,
      paused: true,
      error: 'Request failed',
      retry: () => retries++,
      onPlay: (_) => calls++,
    );
    final target = tester.widget<DragTarget<BridgeCardDrag>>(
      find.byType(DragTarget<BridgeCardDrag>),
    );
    final card = b.PlayerView.forSeat(state, b.Seat.south).legalCards.first;
    for (final owner in [b.Seat.north, b.Seat.south]) {
      final details = DragTargetDetails(
        data: BridgeCardDrag(state.version, owner, card),
        offset: Offset.zero,
      );
      expect(target.onWillAcceptWithDetails!(details), isFalse);
      target.onAcceptWithDetails!(details);
    }
    expect(calls, 0);
    await tester.tap(find.byKey(const Key('focus_retry')));
    expect(retries, 1);
  });

  testWidgets(
    'M2-F59 collect only public trick; cancel and next input unaffected',
    (tester) async {
      var state = advance(advance(advance(initial())));
      await showTable(tester, state);
      state = advance(state);
      await showTable(tester, state);
      expect(find.byKey(const Key('focus_collection')), findsOneWidget);
      expect(
        tester
            .widgetList<BridgeCardFace>(
              find.descendant(
                of: find.byKey(const Key('focus_collection')),
                matching: find.byType(BridgeCardFace),
              ),
            )
            .map((w) => w.card),
        orderedEquals(state.tricks.last.plays.map((p) => p.card)),
      );
      final collecting = find.descendant(
        of: find.byKey(const Key('focus_collection')),
        matching: find.byType(BridgeCardFace),
      );
      final winnerIndex = state.tricks.last.plays.indexWhere(
        (play) => play.handOwner == state.tricks.last.winner,
      );
      final target = tester.getCenter(collecting.at(winnerIndex));
      final startDistances = [
        for (var i = 0; i < 4; i++)
          (tester.getCenter(collecting.at(i)) - target).distance,
      ];
      await tester.pump(const Duration(milliseconds: 110));
      for (var i = 0; i < 4; i++) {
        if (i == winnerIndex) continue;
        expect(
          (tester.getCenter(collecting.at(i)) - target).distance,
          lessThan(startDistances[i]),
        );
      }
      await showTable(tester, state, reduced: true);
      expect(find.byKey(const Key('focus_collection')), findsNothing);
      await showTable(tester, state);
      expect(find.byKey(const Key('focus_collection')), findsNothing);
      while (!state.isFinished) {
        state = advance(state);
        await showTable(tester, state);
      }
      expect(state.tricks.length, 13);
      expect(state.version, 52);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('M2-F57 open/close focus preserves active session and auction', (
    tester,
  ) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await session.newGame();
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    final version = session.view!.version;
    final open = find.byKey(const Key('focus_table_open'));
    await tester.ensureVisible(open);
    await tester.tap(open);
    await tester.pumpAndSettle();
    expect(find.byType(BridgeFocusTable), findsOneWidget);
    expect(session.view!.version, version);
    await tester.ensureVisible(find.byKey(const Key('make_bid')).last);
    await tester.tap(find.byKey(const Key('make_bid')).last);
    await tester.pumpAndSettle();
    expect(session.view!.phase, b.Phase.play);
    final progressed = session.view!.version;
    Navigator.of(tester.element(find.byType(BridgeFocusTable))).pop();
    await tester.pumpAndSettle();
    expect(session.view!.version, progressed);
  });
}
