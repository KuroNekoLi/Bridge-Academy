import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Keys implements CheckpointKeyValueStore {
  final data = <String, String>{};

  @override
  Future<String?> getString(String key) async => data[key];

  @override
  Future<void> setString(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    data.remove(key);
  }

  void corruptLatest() {
    data[PreferencesSessionArchiveStore.slotBKey] = 'torn';
  }
}

String _snapshot({bool humanPassed = false}) {
  final board = BoardDefinition.forNumber(1);
  final game = SinglePlayerCoordinator(
    deal: Deal.suitPerSeat(),
    dealer: board.dealer,
    vulnerability: board.vulnerability,
    humanSeat: Seat.north,
    bot: const DeterministicTrainingBot(),
  );
  if (humanPassed) {
    game.submitHuman(const CallAction(Seat.north, Pass()),
        expectedVersion: 0);
  }
  return SavedBoardCodec.encode(
    board: board,
    humanSeat: Seat.north,
    opponentMode: 'demo',
    boardMode: 'training',
    coordinator: game,
  );
}

void main() {
  test('A2.4: restored prior generation is explicitly reported once',
      () async {
    final keys = _Keys();
    final store = PreferencesSessionArchiveStore(keyValueStore: keys);
    final first = _snapshot();
    final second = _snapshot(humanPassed: true);
    await store.write(first);
    await store.write(second);
    expect(store.recoveredOlderCheckpoint, false);
    expect(await store.read(), second);
    expect(store.recoveredOlderCheckpoint, false);

    keys.corruptLatest();
    expect(await store.read(), first);
    expect(store.recoveredOlderCheckpoint, true);
    expect(SavedBoardCodec.decode((await store.read())!).state.version, 0);
    expect(store.recoveredOlderCheckpoint, false,
        reason: 'Warning provenance should be for the most recent read');
  });

  testWidgets('A2.4: backup restore blocks actions until player confirms',
      (tester) async {
    final keys = _Keys();
    final store = PreferencesSessionArchiveStore(keyValueStore: keys);
    await store.write(_snapshot());
    await store.write(_snapshot(humanPassed: true));
    keys.corruptLatest();

    final session = BridgeSession(archiveStore: store);
    addTearDown(session.dispose);
    expect(await session.restoreSavedGame(), true);
    expect(session.restoredFromStorage, true);
    expect(session.recoveryNeedsConfirmation, true);
    expect(session.actionsPaused, true);
    expect(session.view!.version, 0);
    expect(session.view!.canAct, true);
    expect(session.view!.toJson().containsKey('hands'), false);

    await session.submitCall(const Pass());
    expect(session.view!.version, 0,
        reason: 'Must not replay an unacknowledged human action');

    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recovery_warning')), findsOneWidget);
    expect(find.byKey(const Key('pass')), findsOneWidget);
    expect(tester.widget<OutlinedButton>(find.byKey(const Key('pass')))
        .onPressed, isNull);
    expect(find.textContaining('最新存檔已損壞'), findsOneWidget);
    expect(find.textContaining('AJ5.KQ7'), findsNothing);

    await tester.tap(find.byKey(const Key('toggle_locale')));
    await tester.pumpAndSettle();
    expect(find.textContaining('older valid backup'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ack_recovered_checkpoint')));
    await tester.pumpAndSettle();
    expect(session.recoveryNeedsConfirmation, false);
    expect(session.actionsPaused, false);
    expect(find.byKey(const Key('recovery_warning')), findsNothing);
    expect(tester.widget<OutlinedButton>(find.byKey(const Key('pass')))
        .onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('pass')));
    await tester.pumpAndSettle();
    expect(session.finished, true);
    expect(session.view!.version, 4);
    expect(session.errorCode, isNull);
    expect(SavedBoardCodec.decode((await store.read())!).state.version, 4);
    expect(store.recoveredOlderCheckpoint, false);
  });

  test('A2.4: restored bot turn never auto-advances before consent',
      () async {
    final keys = _Keys();
    final store = PreferencesSessionArchiveStore(keyValueStore: keys);
    final pendingBot = _snapshot(humanPassed: true);
    await store.write(pendingBot);
    await store.write(pendingBot);
    keys.corruptLatest();

    final session = BridgeSession(archiveStore: store);
    addTearDown(session.dispose);
    expect(await session.restoreSavedGame(), true);
    expect(session.recoveryNeedsConfirmation, true);
    expect(session.view!.version, 1);
    expect(session.view!.canAct, false);
    await session.retryBots();
    expect(session.view!.version, 1);

    await session.acknowledgeRecoveredCheckpoint();
    expect(session.recoveryNeedsConfirmation, false);
    expect(session.finished, true);
    expect(session.view!.version, 4);
    expect(SavedBoardCodec.decode((await store.read())!).state.version, 4);
  });

  test('A2.4: ordinary current checkpoint restores without warning',
      () async {
    final keys = _Keys();
    final store = PreferencesSessionArchiveStore(keyValueStore: keys);
    await store.write(_snapshot());
    final session = BridgeSession(archiveStore: store);
    addTearDown(session.dispose);
    expect(await session.restoreSavedGame(), true);
    expect(session.recoveryNeedsConfirmation, false);
    expect(session.actionsPaused, false);
    expect(session.view!.canAct, true);
  });
}

