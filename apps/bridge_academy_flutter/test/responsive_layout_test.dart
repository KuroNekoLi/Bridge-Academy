import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> renderAtWidth(WidgetTester tester, double width) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 720);
  await tester.pump();
}

void main() {
  for (final width in [320.0, 375.0, 768.0]) {
    testWidgets('M2-F06 mobile width $width: startup, locale and controls fit',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await renderAtWidth(tester, width);
      final session = BridgeSession();
      addTearDown(session.dispose);
      await tester.pumpWidget(BridgeAcademyApp(session: session));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('new_game')), findsOneWidget);
      await tester.tap(find.byKey(const Key('toggle_locale')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final game = find.byKey(const Key('new_game'));
      await tester.ensureVisible(game);
      await tester.tap(game);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('bridge_board')), findsOneWidget);

      // Check the substantially denser board after the opening lead:
      // 13 public Dummy cards in addition to the human hand.
      final bidButton = find.byKey(const Key('make_bid'));
      await tester.ensureVisible(bidButton);
      await tester.tap(bidButton);
      await tester.pumpAndSettle();
      expect(session.view!.dummyExposed, true);
      expect(tester.takeException(), isNull);
    });
  }
}

