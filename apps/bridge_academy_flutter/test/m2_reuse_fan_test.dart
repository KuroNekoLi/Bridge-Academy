import 'package:bridge_academy_flutter/src/app_copy.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_card_strip.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_table_components.dart';
import 'package:bridge_core/bridge_core.dart' as b;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playing_cards/playing_cards.dart' show FlatCardFan;

void main() {
  for (final width in [644.0, 768.0, 1280.0]) {
    testWidgets('M2-F60 upstream fan exposes every target at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 600);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final played = <b.Card>[];
      final hand = [for (final r in b.Rank.values) b.Card(b.Suit.spades, r)];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BridgeCardStrip(
              useFan: true,
              id: 'reuse',
              copy: const AppCopy(true),
              children: [
                for (final card in hand)
                  BridgePlayingCardButton(
                    card: card,
                    prefix: 'reuse_',
                    copy: const AppCopy(true),
                    legal: true,
                    busy: false,
                    onTap: () => played.add(card),
                  ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(FlatCardFan), findsOneWidget);
      final fan = tester.widget<FlatCardFan>(find.byType(FlatCardFan));
      final left = fan.children.first as Transform;
      final center = fan.children[6] as Transform;
      final right = fan.children.last as Transform;
      expect(left.transform.getTranslation().y, greaterThan(center.transform.getTranslation().y));
      expect(right.transform.getTranslation().y, greaterThan(center.transform.getTranslation().y));
      final leftTilt = left.child as Transform;
      final rightTilt = right.child as Transform;
      expect(leftTilt.transform.entry(1, 0), lessThan(0));
      expect(rightTilt.transform.entry(1, 0), greaterThan(0));
      for (var i = 0; i < hand.length; i++) {
        final card = find.byKey(Key('reuse_${hand[i].code}'));
        final left = tester.getTopLeft(card);
        final exposed = i == hand.length - 1
            ? tester.getSize(card).width
            : tester
                      .getTopLeft(find.byKey(Key('reuse_${hand[i + 1].code}')))
                      .dx -
                  left.dx;
        expect(exposed, greaterThanOrEqualTo(48 - .01));
        await tester.tapAt(Offset(left.dx + 24, tester.getCenter(card).dy));
      }
      expect(played, orderedEquals(hand));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(played.length, 14);
      expect(played.last, hand.first);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'M2-F60 narrow and large text retain full-width scrolling targets',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 600);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<void> render(double scale, int count) => tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: BridgeCardStrip(
                useFan: true,
                id: 'fallback',
                copy: const AppCopy(false),
                children: [
                  for (var i = 0; i < count; i++)
                    SizedBox(width: 68, height: 96, child: Text('$i')),
                ],
              ),
            ),
          ),
        ),
      );
      await render(1, 13);
      expect(find.byType(FlatCardFan), findsNothing);
      expect(find.byKey(const Key('fallback_scroll')), findsOneWidget);
      await render(2, 5);
      expect(find.byType(FlatCardFan), findsNothing);
      await render(1, 1);
      await render(1, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
