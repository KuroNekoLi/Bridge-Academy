import '../test_driver/bidding_test_actions.dart';
import 'package:bridge_academy_flutter/src/app_copy.dart';
import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_card_face.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_focus_table.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_public_card_entrance.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_table_components.dart';
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
  ValueChanged<b.Call>? onCall,
  bool paused = false,
  bool reduced = false,
  String? error,
  VoidCallback? retry,
  double textScale = 1,
  bool english = true,
  b.Seat viewer = b.Seat.south,
}) => tester.pumpWidget(
  MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        disableAnimations: reduced,
        textScaler: TextScaler.linear(textScale),
      ),
      child: BridgeFocusTable(
        view: b.PlayerView.forSeat(state, viewer),
        copy: AppCopy(english),
        boardNumber: 1,
        modeLabel: 'Demo',
        actionsPaused: paused,
        onPlayCard: onPlay ?? (_) {},
        onSubmitCall: onCall ?? (_) {},
        error: error,
        onRetry: retry,
      ),
    ),
  ),
);

void main() {
  testWidgets('dummy tutorial advances only after suit and card actions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var state = advance(initial());
    b.Card? submitted;
    Future<void> show() =>
        showTable(tester, state, onPlay: (card) => submitted = card);
    await show();
    await tester.tap(find.byKey(const Key('focus_tutorial')));
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.text('Choose a suit first'), findsOneWidget);
    final view = b.PlayerView.forSeat(state, b.Seat.south);
    final legal = view.legalCards.first;
    await tester.tap(find.byKey(Key('focus_dummy_suit_${legal.suit.name}')));
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.text('Choose a card'), findsOneWidget);
    final cardButton = find.byKey(Key('focus_card_N_${legal.code}'));
    await tester.tap(cardButton);
    await tester.pump();
    expect(submitted, legal);
    expect(state.version, 1);
    expect(find.text('Choose a card'), findsOneWidget);
    state = b.BridgeGame.apply(
      state,
      b.CardAction(state.actorToPlay!, state.turn!, submitted!),
    );
    await show();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Choose a card'), findsNothing);
    expect(state.version, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tutorial waits for Bridge Core to acknowledge a real bid', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var state = b.GameState.start(
      b.Deal.shuffled(seed: 82),
      b.Seat.north,
      b.Vulnerability.none,
    );
    b.Call? submitted;
    Future<void> show() => showTable(
      tester,
      state,
      viewer: b.Seat.north,
      onCall: (call) => submitted = call,
    );
    await show();
    await tester.tap(find.byKey(const Key('focus_tutorial')));
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.tap(find.text('Skip tutorial'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(state.version, 0);
    expect(state.auction, isEmpty);
    expect(submitted, isNull);
    await tester.tap(find.byKey(const Key('focus_tutorial')));
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.text('Choose a call'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('bid_1C')));
    await tester.tap(find.byKey(const Key('bid_1C')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('make_bid')));
    await tester.tap(find.byKey(const Key('make_bid')));
    await tester.pump();
    expect(submitted, isA<b.Bid>());
    expect(state.version, 0);
    expect(find.text('Choose a call'), findsOneWidget);
    state = b.BridgeGame.apply(state, b.CallAction(b.Seat.north, submitted!));
    await show();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Choose a call'), findsNothing);
    expect(state.auction, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'M2-F65 all player seats share hand, trick and winner perspective',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final viewer in b.Seat.values) {
        await tester.pumpWidget(const SizedBox.shrink());
        var state = b.GameState.justDeclareStart(
          b.Deal.shuffled(seed: 65),
          b.Seat.north,
          b.Vulnerability.none,
          b.Contract(level: 1, strain: b.Strain.notrump, declarer: viewer),
        );
        state = advance(advance(advance(state)));
        await showTable(tester, state, viewer: viewer);
        await tester.pumpAndSettle();
        final arena = tester.getRect(find.byKey(const Key('focus_drop_zone')));
        Offset seat(b.Seat seat) =>
            tester.getCenter(find.byKey(Key('focus_seat_${seat.letter}')));
        expect(seat(viewer).dy, greaterThan(arena.center.dy));
        expect(seat(viewer.partner).dy, lessThan(arena.center.dy));
        expect(seat(viewer.next).dx, lessThan(arena.center.dx));
        expect(seat(viewer.partner.next).dx, greaterThan(arena.center.dx));
        final view = b.PlayerView.forSeat(state, viewer);
        final rendered = tester
            .widgetList<BridgeCardFace>(find.byType(BridgeCardFace))
            .map((w) => w.card)
            .toSet();
        expect(
          rendered,
          unorderedEquals({
            ...view.ownCards,
            ...view.dummyCards!,
            ...view.currentTrick.map((p) => p.card),
          }),
        );
        final stage = find.byKey(const Key('focus_trick_compass'));
        final publicCards = find.descendant(
          of: stage,
          matching: find.byType(BridgeCardFace),
        );
        final before = [
          for (var i = 0; i < 3; i++) tester.getCenter(publicCards.at(i)),
        ];
        // Opening leader is to our left, followed by dummy above, then right.
        expect(before[0].dx, lessThan(arena.center.dx));
        expect(before[1].dy, lessThan(arena.center.dy));
        expect(before[2].dx, greaterThan(arena.center.dx));
        state = advance(state);
        await showTable(tester, state, viewer: viewer);
        final collected = find.descendant(
          of: find.byKey(const Key('focus_collection')),
          matching: find.byType(BridgeCardFace),
        );
        for (var i = 0; i < 3; i++) {
          expect(
            (tester.getCenter(collected.at(i)) - before[i]).distance,
            lessThan(1),
          );
        }
        await tester.pump(const Duration(milliseconds: 480));
        final destination = tester.getCenter(collected.first) - arena.center;
        final winner = state.tricks.last.winner;
        if (winner == viewer) {
          expect(destination.dy, greaterThan(10));
        } else if (winner == viewer.partner) {
          expect(destination.dy, lessThan(-10));
        } else if (winner == viewer.next) {
          expect(destination.dx, lessThan(-10));
        } else {
          expect(destination.dx, greaterThan(10));
        }
        // Changing perspective on the same public version cancels the old flight.
        await showTable(tester, state, viewer: viewer.next);
        expect(find.byKey(const Key('focus_collection')), findsNothing);
        expect(seat(viewer.next).dy, greaterThan(arena.center.dy));
        final changedView = b.PlayerView.forSeat(state, viewer.next);
        expect(
          tester
              .widgetList<BridgeCardFace>(find.byType(BridgeCardFace))
              .map((w) => w.card)
              .toSet(),
          unorderedEquals({
            ...changedView.ownCards,
            ...changedView.dummyCards!,
            ...changedView.currentTrick.map((p) => p.card),
          }),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'M2-F64 public version and pause invalidate an unsubmitted selection',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = advance(initial());
      var calls = 0;
      await showTable(tester, state, onPlay: (_) => calls++);
      final card = b.PlayerView.forSeat(state, b.Seat.south).legalCards.first;
      final suit = find.byKey(Key('focus_dummy_suit_${card.suit.name}'));
      await tester.tap(suit);
      await tester.pump();
      expect(find.byKey(const Key('focus_N_dummy_choices')), findsOneWidget);
      await showTable(tester, advance(state), onPlay: (_) => calls++);
      expect(find.byKey(const Key('focus_N_dummy_choices')), findsNothing);
      await showTable(tester, state, onPlay: (_) => calls++);
      await tester.tap(suit);
      await tester.pump();
      expect(find.byKey(const Key('focus_N_dummy_choices')), findsOneWidget);
      await showTable(tester, state, paused: true, onPlay: (_) => calls++);
      expect(find.byKey(const Key('focus_N_dummy_choices')), findsNothing);
      await showTable(tester, state, onPlay: (_) => calls++);
      await tester.tap(suit);
      await tester.pump();
      expect(find.byKey(const Key('focus_N_dummy_choices')), findsOneWidget);
      await showTable(
        tester,
        state,
        viewer: b.Seat.north,
        onPlay: (_) => calls++,
      );
      expect(find.byKey(const Key('focus_N_dummy_choices')), findsNothing);
      expect(calls, 0);
    },
  );

  for (final width in [320.0, 375.0]) {
    testWidgets(
      'M2-F64 all 13 fan indexes visible; select then confirm once at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 812);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var state = advance(initial());
        var calls = 0;
        final english = width == 375;
        await showTable(
          tester,
          state,
          english: english,
          onPlay: (_) => calls++,
        );
        expect(find.byKey(const Key('focus_N_scroll')), findsNothing);
        final view = b.PlayerView.forSeat(state, b.Seat.south);
        for (final card in view.ownCards) {
          final index = tester.getTopLeft(
            find.byKey(Key('focus_card_S_${card.code}')),
          );
          expect(index.dx, inInclusiveRange(-3, width - 16));
        }
        final card = view.legalCards.first;
        await tester.tap(find.byKey(Key('focus_dummy_suit_${card.suit.name}')));
        await tester.pump();
        final source = find.byKey(Key('focus_card_N_${card.code}'));
        await tester.tap(source);
        await tester.pump();
        expect(calls, 1);
        expect(find.byKey(const Key('focus_confirm_card')), findsNothing);
        // A new public version clears any selection; wider targets remain available.
        state = advance(state);
        await showTable(
          tester,
          state,
          english: english,
          onPlay: (_) => calls++,
        );
        expect(find.byKey(const Key('focus_confirm_card')), findsNothing);
        await tester.tap(find.byKey(const Key('focus_hand_layout')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('focus_S_scroll')), findsOneWidget);
        expect(calls, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final width in [320.0, 1280.0]) {
    testWidgets('M2-F62 dummy is above table and own hand below at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 812);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await showTable(tester, initial());
      expect(find.byKey(const Key('focus_N_card_strip')), findsNothing);
      await showTable(tester, advance(initial()));
      final surface = find.byKey(const Key('focus_table_surface'));
      final dummy = find.byKey(const Key('focus_N_dummy_hand'));
      final arena = find.byKey(const Key('focus_drop_zone'));
      final own = find.byKey(const Key('focus_S_card_strip'));
      expect(find.ancestor(of: dummy, matching: surface), findsOneWidget);
      expect(find.ancestor(of: own, matching: surface), findsOneWidget);
      for (final suit in [
        b.Suit.spades,
        b.Suit.hearts,
        b.Suit.clubs,
        b.Suit.diamonds,
      ]) {
        expect(
          find.byKey(Key('focus_dummy_suit_${suit.name}')),
          findsOneWidget,
        );
      }
      expect(
        tester.getBottomLeft(dummy).dy,
        lessThanOrEqualTo(tester.getTopLeft(arena).dy),
      );
      expect(
        tester.getTopLeft(own).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(arena).dy),
      );
      if (width >= 768) {
        final tableCenter = tester.getCenter(surface).dx;
        expect((tester.getCenter(dummy).dx - tableCenter).abs(), lessThan(1));
        expect((tester.getCenter(own).dx - tableCenter).abs(), lessThan(1));
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [320.0, 1280.0]) {
    testWidgets(
      'M2-F63 readable public cards and continuous collection at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 812);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var state = advance(advance(advance(initial())));
        await showTable(tester, state);
        await tester.pumpAndSettle();
        final stage = find.byKey(const Key('focus_trick_compass'));
        final cards = find.descendant(
          of: stage,
          matching: find.byType(BridgeCardFace),
        );
        final before = [
          for (var i = 0; i < 3; i++) tester.getCenter(cards.at(i)),
        ];
        expect(tester.getSize(cards.first).width, inInclusiveRange(52, 84));
        final arena = tester.getRect(find.byKey(const Key('focus_drop_zone')));
        for (final point in before) {
          expect(arena.contains(point), isTrue);
        }
        state = advance(state);
        await showTable(tester, state);
        final collected = find.descendant(
          of: find.byKey(const Key('focus_collection')),
          matching: find.byType(BridgeCardFace),
        );
        expect(collected, findsNWidgets(4));
        for (var i = 0; i < 3; i++) {
          expect(
            (tester.getCenter(collected.at(i)) - before[i]).distance,
            lessThan(1),
          );
        }
        final start = tester.getCenter(collected.first);
        await tester.pump(const Duration(milliseconds: 480));
        final moved = tester.getCenter(collected.first) - arena.center;
        switch (state.tricks.last.winner) {
          case b.Seat.north:
            expect(moved.dy, lessThan(-10));
          case b.Seat.east:
            expect(moved.dx, greaterThan(10));
          case b.Seat.south:
            expect(moved.dy, greaterThan(10));
          case b.Seat.west:
            expect(moved.dx, lessThan(-10));
        }
        expect(
          (tester.getCenter(collected.first) - start).distance,
          greaterThan(10),
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(find.byKey(const Key('focus_collection')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('M2-F61 public plays fly from their compass seat only once', (
    tester,
  ) async {
    var state = initial();
    await showTable(tester, state);
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
      for (
        var playIndex = 0;
        playIndex < state.currentTrick.length;
        playIndex++
      ) {
        final play = state.currentTrick[playIndex];
        final entrance = entrances.at(playIndex);
        expect(
          tester.widget<BridgePublicCardEntrance>(entrance).from,
          tester
              .widget<BridgeCurrentTrick>(find.byType(BridgeCurrentTrick))
              .geometry!
              .entranceFrom(play.handOwner),
        );
      }
      final newest = entrances.last;
      final opacity = find.descendant(
        of: newest,
        matching: find.byType(Opacity),
      );
      expect(tester.widget<Opacity>(opacity).opacity, 0);
      await showTable(tester, state);
      expect(tester.widget<Opacity>(opacity).opacity, 0);
      await tester.pump(const Duration(milliseconds: 190));
      expect(tester.widget<Opacity>(opacity).opacity, 1);
    }
    expect(state.tricks.length, 1);
  });

  for (final width in [320.0, 1280.0]) {
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
      // Exercise every trick only at the narrow boundary; the desktop case
      // checks the same layout contract without replaying the full board.
      if (width == 320) {
        var progressing = state;
        while (!progressing.isFinished) {
          progressing = advance(progressing);
          await showTable(tester, progressing);
          expect(
            tester.takeException(),
            isNull,
            reason: 'version ${progressing.version}',
          );
        }
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
    await tester.tap(find.byKey(Key('focus_dummy_suit_${card.suit.name}')));
    await tester.pumpAndSettle();
    final source = find.byKey(Key('focus_drag_N_${card.code}'));
    await tester.ensureVisible(source);
    final outside = await tester.startGesture(
      tester.getTopLeft(source) + const Offset(8, 40),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await outside.moveTo(const Offset(1, 1));
    await outside.up();
    await tester.pumpAndSettle();
    expect(calls, 0);
    final gesture = await tester.startGesture(
      tester.getTopLeft(source) + const Offset(8, 40),
    );
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
    await tapBiddingAware(
      tester,
      find.byKey(const Key('make_bid')).last,
      'make_bid',
    );
    await tester.pumpAndSettle();
    expect(session.view!.phase, b.Phase.play);
    final progressed = session.view!.version;
    Navigator.of(tester.element(find.byType(BridgeFocusTable))).pop();
    await tester.pumpAndSettle();
    expect(session.view!.version, progressed);
  });
}
