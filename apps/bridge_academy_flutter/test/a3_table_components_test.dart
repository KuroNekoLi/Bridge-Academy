import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_table_components.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tapComponent(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('A3.1 header, seat, trick components preserve board metadata',
      (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await session.newGame(boardNumber: 2, humanSeat: Seat.east);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    expect(find.byType(BridgeBoardHeader), findsOneWidget);
    expect(find.byType(BridgeTableSurface), findsOneWidget);
    expect(find.byType(BridgeCurrentTrick), findsOneWidget);
    expect(find.byType(BridgeSeatPanel), findsNWidgets(4));
    expect(find.text('牌號: 2'), findsOneWidget);
    expect(find.text('發牌者: 東（E）'), findsOneWidget);
    expect(find.text('局況: 南北有局'), findsOneWidget);
    expect(find.byKey(const Key('dummy_revealed')), findsNothing);
    expect(find.byType(BridgePlayerHand), findsNothing);
    // A concealed opponent seat has only its card count, not card buttons.
    expect(find.byKey(const Key('seat_W')), findsOneWidget);
    expect(find.byKey(const Key('dummy_card_SA')), findsNothing);
    await tapComponent(tester, 'toggle_locale');
    expect(find.text('Board: 2'), findsOneWidget);
    expect(find.text('Vulnerability: N/S vulnerable'), findsOneWidget);
  });

  testWidgets('A3.1 extracted cards keep Dummy action ownership and keys',
      (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tapComponent(tester, 'new_game');
    await tapComponent(tester, 'make_bid');
    expect(session.view!.dummyExposed, isTrue);
    expect(find.byType(BridgePlayerHand), findsOneWidget);
    expect(find.byType(BridgePlayingCardButton), findsWidgets);
    final card = session.view!.legalCards.first;
    final oldVersion = session.view!.version;
    await tapComponent(tester, 'dummy_card_${card.code}');
    expect(session.view!.version, greaterThan(oldVersion));
  });
}
