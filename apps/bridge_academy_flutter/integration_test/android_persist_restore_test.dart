import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Called from a second flutter drive process AFTER adb am force-stop.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('A2.3 process B: restore mid-trick game from Android disk',
      (tester) async {
    final store = PreferencesSessionArchiveStore();
    final prefs = SharedPreferencesAsync();
    final expected = await tester.runAsync(() async {
      final version = await prefs.getInt('bridge_qa.a23.version');
      final fingerprint =
          await prefs.getString('bridge_qa.a23.fingerprint');
      return (version: version, fingerprint: fingerprint);
    });
    expect(expected, isNotNull);
    expect(expected!.version, isNotNull);
    expect(expected.fingerprint, isNotNull);

    final raw = await tester.runAsync(store.read);
    expect(raw, isNotNull,
        reason: 'Android app data must survive force-stop and relaunch');
    final snapshot = SavedBoardCodec.decode(raw!);
    expect(snapshot.state.version, expected.version);
    expect(snapshot.state.historyFingerprint, expected.fingerprint);
    expect(snapshot.board.number, 1);
    expect(snapshot.state.isFinished, false);
    expect(snapshot.state.phase, Phase.play);
    expect(snapshot.state.dummyExposed, true);

    final resumed = BridgeSession(archiveStore: store);
    addTearDown(resumed.dispose);
    expect(await tester.runAsync(resumed.restoreSavedGame), true);
    expect(resumed.restoredFromStorage, true);
    expect(resumed.board.number, 1);
    expect(resumed.view!.version, expected.version);
    expect(resumed.view!.phase, Phase.play);
    expect(resumed.view!.dummyExposed, true);
    expect(resumed.view!.ownCards, isNotEmpty);
    expect(resumed.view!.dummyCards, isNotNull);
    expect(resumed.view!.legalCards, isNotEmpty);
    expect(resumed.completedReplay, isNull);
    expect(resumed.view!.toJson().containsKey('dealPbn'), false);
    expect(resumed.view!.toJson().containsKey('hands'), false);

    await tester.pumpWidget(BridgeAcademyApp(session: resumed));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('restored_game')), findsOneWidget);
    expect(find.byKey(const Key('dummy_revealed')), findsOneWidget);
    expect(find.byKey(const Key('board_number')), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Continue with the next legal action; previous action is NOT replayed.
    final prior = resumed.view!.version;
    await tester.runAsync(
      () => resumed.submitCard(resumed.view!.legalCards.first),
    );
    await tester.pumpAndSettle();
    expect(resumed.view!.version, greaterThan(prior));
    expect(resumed.errorCode, isNull);
    final continued = await tester.runAsync(store.read);
    expect(SavedBoardCodec.decode(continued!).state.version,
        resumed.view!.version);

    await tester.runAsync(() async {
      await store.clear();
      await prefs.remove('bridge_qa.a23.version');
      await prefs.remove('bridge_qa.a23.fingerprint');
    });
    // ignore: avoid_print
    print('A2_3_ANDROID_PROCESS_B_PASS');
  });
}

