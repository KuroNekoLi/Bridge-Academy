import 'package:bridge_academy_flutter/src/app_copy.dart';
import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_card_face.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_table_components.dart';
import 'package:bridge_core/bridge_core.dart' as bridge;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playing_cards/playing_cards.dart' as cards;

void main() {
  test('M2-F54 all 52 cards map uniquely; sorting copies the projection', () {
    final deck = [
      for (final suit in bridge.Suit.values)
        for (final rank in bridge.Rank.values) bridge.Card(suit, rank),
    ];
    final faces = deck.map(displayCard).map((c) => (c.suit, c.value)).toSet();
    expect(faces.length, 52);
    for (final card in deck) {
      expect(displayCard(card).suit.name, card.suit.name);
      expect(displayCard(card).value.name, card.rank.name);
    }
    expect(displayCard(deck.last).value, cards.CardValue.ace);
    expect(displayCard(deck.last).suit, cards.Suit.spades);
    final snapshot = [...deck];
    final sorted = sortedVisibleCards(deck);
    expect(deck, snapshot);
    expect(sorted.first.code, 'SA');
    expect(sorted.last.code, 'C2');
  });

  testWidgets('M2-F54 auction shows only the authorized hand, no card input', (
    tester,
  ) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await session.newGame();
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    final rendered = tester
        .widgetList<BridgeCardFace>(find.byType(BridgeCardFace))
        .map((w) => w.card)
        .toList();
    expect(rendered, unorderedEquals(session.view!.ownCards));
    expect(rendered.length, 13);
    for (final card in rendered) {
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(Key('hand_card_${card.code}')))
            .onPressed,
        isNull,
      );
    }
    expect(find.byKey(const Key('dummy_revealed')), findsNothing);
  });

  testWidgets(
    'M2-F54 legal card supports keyboard; busy/illegal cannot submit',
    (tester) async {
      var taps = 0;
      Future<void> render(bool legal, bool busy) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Card(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Visible hand'),
                      BridgePlayingCardButton(
                        card: const bridge.Card(
                          bridge.Suit.hearts,
                          bridge.Rank.queen,
                        ),
                        prefix: 'test_',
                        copy: const AppCopy(true),
                        legal: legal,
                        busy: busy,
                        onTap: () => taps++,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      final semantics = tester.ensureSemantics();
      try {
        await render(true, false);
        expect(
          tester
              .getSemantics(find.byType(BridgePlayingCardButton))
              .getSemanticsData()
              .label,
          'Playable card: Hearts Queen',
        );
        expect(
          tester
              .getSemantics(find.byType(BridgePlayingCardButton))
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
        expect(
          tester.getSize(find.byKey(const Key('test_HQ'))).shortestSide,
          greaterThanOrEqualTo(48),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(taps, 1);
        tester.semantics.tap(
          find.semantics.byLabel('Playable card: Hearts Queen'),
        );
        expect(taps, 2);
        await render(false, false);
        expect(
          tester
              .getSemantics(find.byType(BridgePlayingCardButton))
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isFalse,
        );
        expect(
          tester
              .widget<OutlinedButton>(find.byKey(const Key('test_HQ')))
              .onPressed,
          isNull,
        );
        await render(true, true);
        expect(
          tester
              .widget<OutlinedButton>(find.byKey(const Key('test_HQ')))
              .onPressed,
          isNull,
        );
        expect(taps, 2);
        // Custom suit/court builders never load upstream raster artwork.
        expect(find.byType(Image), findsNothing);
      } finally {
        semantics.dispose();
      }
    },
  );
}
