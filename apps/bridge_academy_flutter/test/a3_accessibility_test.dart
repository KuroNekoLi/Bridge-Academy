import '../test_driver/bidding_test_actions.dart';
import 'package:bridge_academy_flutter/src/app_copy.dart';
import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_table_components.dart';
import 'package:bridge_core/bridge_core.dart' as bridge;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tapVisible(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  await tester.ensureVisible(target);
  await tapBiddingAware(tester, target, key);
  await tester.pumpAndSettle();
}

void main() {
  test('A3.4 spoken suit/rank and seat descriptions are localized', () {
    const zh = AppCopy(false);
    const en = AppCopy(true);
    expect(zh.accessibleCard('SA', playable: true), '可出牌: 黑桃 A');
    expect(zh.accessibleCard('HJ', playable: false), '目前不能出牌: 紅心 J');
    expect(en.accessibleCard('DT', playable: true), 'Playable card: Diamonds Ten');
    expect(en.cardName('CK'), 'Clubs King');
    expect(
      zh.seatSummary('S',
          active: true, viewer: false, dummy: true, remaining: 13),
      contains('公開明手'),
    );
  });

  testWidgets('A3.4 cards expose >=48 logical pixel target and useful label',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: BridgePlayingCardButton(
              card: const bridge.Card(bridge.Suit.spades, bridge.Rank.ace),
              prefix: 'hand_card_',
              copy: const AppCopy(false),
              legal: true,
              busy: false,
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );
    final finder = find.byKey(const Key('hand_card_SA'));
    final size = tester.getSize(finder);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(
      find.byWidgetPredicate((widget) =>
          widget is Semantics &&
          widget.properties.label == '可出牌: 黑桃 A'),
      findsOneWidget,
    );
    await tester.tap(finder);
    expect(taps, 1);
  });

  testWidgets('A3.4 a disabled or busy card never submits a play',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: BridgePlayingCardButton(
              card: const bridge.Card(bridge.Suit.hearts, bridge.Rank.jack),
              prefix: 'hand_card_',
              copy: const AppCopy(false),
              legal: true,
              busy: true,
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );
    final finder = find.byKey(const Key('hand_card_HJ'));
    expect(tester.widget<OutlinedButton>(finder).onPressed, isNull);
    expect(
      find.byWidgetPredicate((widget) =>
          widget is Semantics &&
          widget.properties.label == '目前不能出牌: 紅心 J'),
      findsOneWidget,
    );
    expect(taps, 0);
  });

  for (final config in [
    (width: 320.0, scale: 2.0),
    (width: 375.0, scale: 1.6),
    (width: 768.0, scale: 2.0),
  ]) {
    testWidgets('A3.4 ${config.width}px at ${config.scale}x text scale',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(config.width, 720);
      tester.platformDispatcher.textScaleFactorTestValue = config.scale;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final session = BridgeSession();
      addTearDown(session.dispose);
      await tester.pumpWidget(BridgeAcademyApp(session: session));
      await tapVisible(tester, 'new_game');
      expect(find.byKey(const Key('active_seat_N')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tapVisible(tester, 'make_bid');
      expect(session.view!.dummyExposed, isTrue);
      expect(tester.takeException(), isNull);
      await tapVisible(tester, 'toggle_locale');
      expect(tester.takeException(), isNull);
    });
  }
}
