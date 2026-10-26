import 'package:bridge_academy_flutter/src/app_copy.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_card_strip.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_table_components.dart';
import 'package:bridge_core/bridge_core.dart' as bridge;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'M2-F55 narrow hand scrolls to the exact card without shrinking targets',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 600);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final deck = [
        for (final rank in bridge.Rank.values)
          bridge.Card(bridge.Suit.clubs, rank),
      ];
      bridge.Card? selected;
      Future<void> render(List<bridge.Card> cards, {bool english = false}) =>
          tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: BridgeCardStrip(
                    id: 'test',
                    copy: AppCopy(english),
                    children: [
                      for (final card in cards)
                        BridgePlayingCardButton(
                          card: card,
                          prefix: 'strip_',
                          copy: AppCopy(english),
                          legal: true,
                          busy: false,
                          onTap: () => selected = card,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
      await render(deck);
      expect(find.text('左右滑動查看所有手牌'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('test_card_strip'))).height,
        lessThan(180),
      );
      final last = find.byKey(const Key('strip_CA'));
      expect(tester.getTopLeft(last).dx, greaterThan(320));
      await tester.ensureVisible(last);
      await tester.pumpAndSettle();
      expect(tester.getSize(last).shortestSide, greaterThanOrEqualTo(48));
      await tester.tap(last);
      expect(selected, deck.last);
      await render(deck, english: true);
      expect(find.text('Scroll sideways to see all cards'), findsOneWidget);
      // Removing most of the cards while scrolled must detach/clamp safely.
      await render(deck.take(2).toList());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('test_scroll')), findsNothing);
      expect(tester.takeException(), isNull);
      await render([]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'M2-F55 wide hand needs no scroll hint and keeps all cards on one row',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 600);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BridgeCardStrip(
              id: 'wide',
              copy: const AppCopy(true),
              children: [
                for (final rank in bridge.Rank.values)
                  BridgePlayingCardButton(
                    card: bridge.Card(bridge.Suit.spades, rank),
                    prefix: 'wide_',
                    copy: const AppCopy(true),
                    legal: false,
                    busy: false,
                    onTap: () {},
                  ),
              ],
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('wide_scroll_hint')), findsNothing);
      expect(
        tester.getTopLeft(find.byKey(const Key('wide_S2'))).dy,
        tester.getTopLeft(find.byKey(const Key('wide_SA'))).dy,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
