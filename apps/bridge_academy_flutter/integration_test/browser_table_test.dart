import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> tapControl(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('REAL BROWSER: switch language, start, pass out, restart',
      (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));

    expect(find.text('Bridge Academy｜橋牌學院'), findsOneWidget);
    await tapControl(tester, 'toggle_locale');
    expect(find.text('Bridge Academy'), findsOneWidget);
    await tapControl(tester, 'new_game');
    expect(session.view?.viewer, Seat.north);
    expect(session.view?.ownCards.length, 13);
    expect(session.view?.dummyCards, isNull);

    await tapControl(tester, 'pass');
    expect(session.finished, isTrue);
    expect(session.view!.auction.length, 4);
    expect(session.view!.nsScore, 0);
    expect(find.byKey(const Key('final_result')), findsOneWidget);

    await tapControl(tester, 'new_game');
    expect(session.finished, isFalse);
    expect(session.view!.auction, isEmpty);
    expect(find.byKey(const Key('final_result')), findsNothing);
  });

  testWidgets('REAL BROWSER: bid, reveal dummy, play dummy card',
      (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tapControl(tester, 'new_game');
    await tapControl(tester, 'make_bid');

    expect(session.view!.phase, Phase.play);
    expect(session.view!.dummyExposed, isTrue);
    expect(find.byKey(const Key('dummy_revealed')), findsOneWidget);

    final legal = session.view!.legalCards.first.code;
    final version = session.view!.version;
    await tapControl(tester, 'dummy_card_$legal');
    expect(session.view!.version, greaterThan(version));
    expect(session.errorCode, isNull);
  });
}

