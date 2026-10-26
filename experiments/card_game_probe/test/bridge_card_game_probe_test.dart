import 'package:bridge_card_game_probe/bridge_card_game_probe.dart';
import 'package:bridge_core/bridge_core.dart' as b;
import 'package:card_game/card_game.dart' as c;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

b.GameState board() {
  var state = b.GameState.justDeclareStart(
      b.Deal.shuffled(seed: 60),
      b.Seat.north,
      b.Vulnerability.none,
      const b.Contract(
          level: 1, strain: b.Strain.notrump, declarer: b.Seat.south));
  return b.BridgeGame.apply(
      state,
      b.CardAction(state.actorToPlay!, state.turn!,
          state.legalCards(state.turn!).first));
}

void main() {
  test('upstream stack limit cannot drag a non-final bridge card; adapter can',
      () {
    final cards = b.PlayerView.forSeat(board(), b.Seat.south).dummyCards!;
    final upstream = c.CardRow<b.Card, String>(
        value: 'hand',
        values: cards,
        maxGrabStackSize: 1,
        canCardBeGrabbed: (_, __) => true);
    expect(upstream.getDraggableCardValues(0, cards.first), isNull);
    expect(upstream.getDraggableCardValues(cards.length - 1, cards.last),
        [cards.last]);
    final adapter =
        BridgeProbeRow(value: 'hand', values: cards, allowed: (_) => true);
    expect(adapter.getDraggableCardValues(0, cards.first), [cards.first]);
  });

  testWidgets(
      'probe isolates authorized cards and reproduces upstream drag-end gate',
      (tester) async {
    final state = board();
    final view = b.PlayerView.forSeat(state, b.Seat.south);
    final proposals = <b.Card>[];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: BridgeCardGameProbe(
                view: view,
                onPropose: (card, version) {
                  expect(version, state.version);
                  proposals.add(card);
                }))));
    await tester.pumpAndSettle();
    final buttons = tester.widgetList<TextButton>(find.byType(TextButton));
    final codes = buttons.map((w) => (w.child as Text).data).toSet();
    expect(
        codes,
        unorderedEquals({
          ...view.ownCards.map((x) => x.code),
          ...view.dummyCards!.map((x) => x.code),
          ...view.currentTrick.map((x) => x.card.code)
        }));
    final card = view.legalCards.first;
    final source = find.byKey(ValueKey('probe_${card.code}'));
    final target = find.byKey(const ValueKey('probe_target_public'));
    await tester.drag(
        source, tester.getCenter(target) - tester.getCenter(source));
    expect(tester.takeException(), isA<TypeError>(),
        reason: 'Known upstream card_game.dart:200 recalculates a now-disabled '
            'grab stack with ! after the synchronous proposal lock. '
            'Reproduced incompatibility, not production acceptance.');
    await tester.pumpAndSettle();
    expect(proposals, [card]);
    expect(state.version, 1); // Upstream cannot apply a bridge move.
    expect(view.legalCards, contains(card));
    await tester.tap(source);
    expect(proposals, [card]); // One proposal while awaiting authority.
  });

  testWidgets('compatibility gate: upstream ignores reduced-motion duration',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Scaffold(
          body: BridgeCardGameProbe(
              view: b.PlayerView.forSeat(board(), b.Seat.south),
              onPropose: (_, __) {})),
    )));
    await tester.pumpAndSettle();
    expect(
        tester
            .widgetList<AnimatedPositioned>(find.byType(AnimatedPositioned))
            .any((w) => w.duration > Duration.zero),
        isTrue,
        reason:
            'Known production gate, not a claim that reduced motion passes.');
  });
}
