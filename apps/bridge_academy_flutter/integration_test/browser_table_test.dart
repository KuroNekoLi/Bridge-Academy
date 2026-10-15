import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:bridge_academy_flutter/src/secure_session_persistence.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final pendingError = tester.takeException();
  if (pendingError != null) {
    fail('Browser action $key: $pendingError');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('REAL BROWSER: language, pass out, restart, dummy play',
      (tester) async {
    final frameworkErrors = <String>[];
    final initialErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      frameworkErrors.add(details.exceptionAsString());
      initialErrorHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = initialErrorHandler);
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
    expect(find.byKey(const Key('replay_panel')), findsOneWidget);
    expect(find.text('Event step: 4 / 4'), findsOneWidget);
    await tapControl(tester, 'replay_first');
    expect(find.text('Event step: 0 / 4'), findsOneWidget);
    await tapControl(tester, 'replay_next');
    expect(find.text('Event step: 1 / 4'), findsOneWidget);
    await tapControl(tester, 'replay_last');
    expect(find.text('Event step: 4 / 4'), findsOneWidget);

    await tapControl(tester, 'new_game');
    expect(find.byKey(const Key('replay_panel')), findsNothing);
    expect(session.finished, isFalse);
    expect(session.view!.auction, isEmpty);
    expect(find.byKey(const Key('final_result')), findsNothing);

    // Continue in the SAME Chrome test/browser lifecycle after restart.
    await tapControl(tester, 'make_bid');
    expect(session.view!.phase, Phase.play);
    expect(session.view!.dummyExposed, isTrue);
    expect(find.byKey(const Key('dummy_revealed')), findsOneWidget);
    final legal = session.view!.legalCards.first.code;
    final version = session.view!.version;
    try {
      await tapControl(tester, 'dummy_card_$legal');
    } catch (error) {
      fail('Dummy Chrome action: $error; underlying framework errors: '
          '${frameworkErrors.join(' / ')}');
    }
    expect(session.view!.version, greaterThan(version));
    expect(session.errorCode, isNull);
  });


  testWidgets('REAL BROWSER P1-A2: platform checkpoint survives new Session',
      (tester) async {
    final store = PreferencesSessionArchiveStore();
    await tester.runAsync(store.clear);
    addTearDown(() async { await store.clear(); });
    final original = BridgeSession(archiveStore: store);
    await tester.runAsync(() async {
      await original.newGame(boardNumber: 2, humanSeat: Seat.east);
      await original.submitCall(const Pass());
    });
    expect(original.finished, isTrue);
    final version = original.view!.version;
    original.dispose();

    final resumed = BridgeSession(archiveStore: store);
    addTearDown(resumed.dispose);
    final loaded = await tester.runAsync(resumed.restoreSavedGame);
    expect(loaded, isTrue);
    expect(resumed.board.number, 2);
    expect(resumed.view!.version, version);
    expect(resumed.completedReplay, isNotNull);
    await tester.pumpWidget(BridgeAcademyApp(session: resumed));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('restored_game')), findsOneWidget);
    expect(find.byKey(const Key('final_result')), findsOneWidget);
    expect(resumed.view!.dummyCards, isNull);
  });

  testWidgets('REAL BROWSER A2.8: default WebCrypto checkpoint survives reload',
      (tester) async {
    final secure = EncryptedTransactionalSessionArchiveStore.browser();
    await tester.runAsync(secure.clear);
    addTearDown(() async { await secure.clear(); });

    // Do not inject a fake session: exercise the real browser composition.
    await tester.pumpWidget(const BridgeAcademyApp());
    await tester.pumpAndSettle();
    await tapControl(tester, 'new_game');
    await tapControl(tester, 'pass');
    expect(find.byKey(const Key('final_result')), findsOneWidget);

    final encrypted = await tester.runAsync(() =>
        SharedPreferencesAsync().getString(BrowserSingleRecordArchiveStore.key));
    expect(encrypted, isNotNull);
    expect(encrypted, isNot(contains('dealPbn')));
    expect(encrypted, isNot(contains('humanSeat')));

    // A second BridgeAcademyApp recreates its session and storage provider.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const BridgeAcademyApp());
    await tester.runAsync(() =>
        Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('restored_game')), findsOneWidget);
    expect(find.byKey(const Key('final_result')), findsOneWidget);
    expect(find.byKey(const Key('board_number')), findsOneWidget);
    expect(tester.takeException(), isNull);
    // ignore: avoid_print
    print('A2_8_REAL_WEB_CRYPTO_RELOAD_PASS');
  });

}
