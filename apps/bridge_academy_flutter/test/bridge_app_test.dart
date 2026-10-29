import '../test_driver/bidding_test_actions.dart';
import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tapVisible(WidgetTester tester, String key) async {
  final item = find.byKey(Key(key));
  await tester.ensureVisible(item);
  await tester.pump();
  await tapBiddingAware(tester, item, key);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Traditional Chinese default and English language switch', (
    tester,
  ) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    expect(find.text('Bridge Academy｜橋牌學院'), findsOneWidget);
    expect(find.text('開始新牌局'), findsOneWidget);
    await tapVisible(tester, 'toggle_locale');
    expect(find.text('Bridge Academy'), findsOneWidget);
    expect(find.text('Start new deal'), findsOneWidget);
    await tapVisible(tester, 'toggle_locale');
    expect(find.text('開始新牌局'), findsOneWidget);
  });

  testWidgets('demo is visibly not BEN; hidden hands never rendered', (
    tester,
  ) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    expect(find.textContaining('示範模式使用測試 Bot（不是 BEN）'), findsOneWidget);
    await tapVisible(tester, 'new_game');
    expect(find.byKey(const Key('bridge_board')), findsOneWidget);
    expect(find.byKey(const Key('dummy_revealed')), findsNothing);
    expect(find.text('♠3'), findsNothing); // East secret card.
    expect(session.view!.ownCards.length, 13);
  });

  testWidgets('four passes show final result without cards', (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tapVisible(tester, 'new_game');
    await tapVisible(tester, 'pass');
    expect(find.byKey(const Key('final_result')), findsOneWidget);
    expect(find.text('四家 Pass Out，0 分'), findsOneWidget);
    expect(session.view!.completedTricks, isEmpty);
  });

  testWidgets('make bid -> demo lead -> exposed dummy card is playable', (
    tester,
  ) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tapVisible(tester, 'new_game');
    await tapVisible(tester, 'make_bid');
    expect(session.view!.dummyExposed, true);
    final dummyId = session.view!.contract!.dummy.letter;
    expect(find.byKey(Key('focus_${dummyId}_dummy_hand')), findsOneWidget);
    final chosenCard = session.view!.legalCards.first;
    final before = session.view!.version;
    await tapVisible(tester, 'focus_dummy_suit_${chosenCard.suit.name}');
    expect(find.byKey(Key('focus_${dummyId}_dummy_suits')), findsNothing);
    expect(find.byKey(Key('focus_${dummyId}_dummy_choices')), findsOneWidget);
    await tapVisible(tester, 'focus_card_${dummyId}_${chosenCard.code}');
    expect(session.view!.version, greaterThan(before));
  });

  testWidgets('illegal X is disabled, game stays on same version', (
    tester,
  ) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tapVisible(tester, 'new_game');
    await tapVisible(tester, 'double');
    expect(session.view!.version, 0);
    expect(find.byKey(const Key('error_message')), findsNothing);
    expect(
      tester.widget<OutlinedButton>(find.byKey(const Key('double'))).onPressed,
      isNull,
    );
  });
}
