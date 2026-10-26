import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_practice_hub.dart';
import 'package:bridge_core/bridge_core.dart' show Bid, Strain;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tap(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('M2-F53 replacing an unfinished deal requires explicit choice', (
    tester,
  ) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await session.newGame();
    await session.submitCall(const Bid(1, Strain.notrump));
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    final view = session.view;
    await tap(tester, 'new_game');
    expect(find.text('放棄目前牌局？'), findsOneWidget);
    await tap(tester, 'keep_current_deal');
    expect(session.view!.version, view!.version);
    expect(session.view!.ownCards, view.ownCards);
    await tap(tester, 'new_game');
    await tap(tester, 'replace_current_deal');
    expect(find.byKey(const Key('keep_current_deal')), findsNothing);
    expect(session.view!.version, 0);
  });
  testWidgets('M2-F53 functional destinations preserve an active game', (
    tester,
  ) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    expect(find.byType(BridgePracticeHub), findsOneWidget);
    expect(find.text('自由打牌'), findsOneWidget);
    expect(find.text('專心練主打'), findsOneWidget);
    await tap(tester, 'new_game');
    final version = session.view!.version;
    final cards = [...session.view!.ownCards];
    await tap(tester, 'nav_review');
    expect(find.byKey(const Key('bridge_board')), findsNothing);
    expect(find.byKey(const Key('history_search')), findsOneWidget);
    await tap(tester, 'nav_me');
    expect(find.text('開源授權'), findsOneWidget);
    await tap(tester, 'nav_play');
    expect(session.view!.version, version);
    expect(session.view!.ownCards, cards);
    expect(find.byKey(const Key('bridge_board')), findsOneWidget);
    await tap(tester, 'nav_learn');
    expect(find.byKey(const Key('academy_page')), findsOneWidget);
    Navigator.of(tester.element(find.byKey(const Key('academy_page')))).pop();
    await tester.pumpAndSettle();
    expect(session.view!.version, version);
  });

  testWidgets(
    'M2-F53 active board precedes launchers, locales preserve session',
    (tester) async {
      final session = BridgeSession();
      addTearDown(session.dispose);
      await session.newGame();
      await tester.pumpWidget(BridgeAcademyApp(session: session));
      expect(
        tester.getTopLeft(find.byKey(const Key('bridge_board'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('practice_hub'))).dy),
      );
      await tap(tester, 'toggle_locale');
      expect(
        find.text('What would you like to practice next?'),
        findsOneWidget,
      );
      expect(session.view!.version, 0);
    },
  );

  for (final width in [320.0, 768.0, 1280.0]) {
    testWidgets('M2-F53 workspace fits $width at 2x text', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final session = BridgeSession();
      addTearDown(session.dispose);
      await tester.pumpWidget(BridgeAcademyApp(session: session));
      await tap(tester, 'new_game');
      await tap(tester, 'nav_review');
      await tap(tester, 'nav_me');
      await tap(tester, 'toggle_locale');
      await tap(tester, 'nav_play');
    });
  }
}
