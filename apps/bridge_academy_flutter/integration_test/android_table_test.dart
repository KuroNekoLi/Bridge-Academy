import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> tapOnDevice(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pumpAndSettle();
  final error = tester.takeException();
  if (error != null) fail('Android interaction $key failed: $error');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('M2-F08 Android device: localization, Pass Out, dummy play',
      (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));

    expect(find.text('Bridge Academy｜橋牌學院'), findsOneWidget);
    await tapOnDevice(tester, 'toggle_locale');
    expect(find.text('Bridge Academy'), findsOneWidget);
    await tapOnDevice(tester, 'new_game');
    expect(session.mode, OpponentMode.demo);
    expect(session.view!.ownCards.length, 13);
    expect(session.view!.dummyCards, isNull);

    await tapOnDevice(tester, 'pass');
    expect(session.finished, true);
    expect(session.view!.auction.length, 4);
    expect(session.view!.nsScore, 0);
    expect(find.byKey(const Key('final_result')), findsOneWidget);
    expect(find.byKey(const Key('replay_panel')), findsOneWidget);
    expect(find.text('Event step: 4 / 4'), findsOneWidget);
    await tapOnDevice(tester, 'replay_first');
    expect(find.text('Event step: 0 / 4'), findsOneWidget);
    await tapOnDevice(tester, 'replay_next');
    expect(find.text('Event step: 1 / 4'), findsOneWidget);
    await tapOnDevice(tester, 'replay_last');

    await tapOnDevice(tester, 'new_game');
    expect(find.byKey(const Key('replay_panel')), findsNothing);
    expect(session.view!.auction, isEmpty);
    await tapOnDevice(tester, 'make_bid');
    expect(session.view!.phase, Phase.play);
    expect(session.view!.dummyExposed, true);
    expect(find.byKey(const Key('dummy_revealed')), findsOneWidget);
    final before = session.view!.version;
    final legalDummy = session.view!.legalCards.first.code;
    await tapOnDevice(tester, 'dummy_card_$legalDummy');
    expect(session.view!.version, greaterThan(before));
    expect(session.errorCode, isNull);
    expect(tester.takeException(), isNull);
  });
}

