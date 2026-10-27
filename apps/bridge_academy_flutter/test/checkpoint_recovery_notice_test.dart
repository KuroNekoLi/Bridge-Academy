import '../test_driver/bidding_test_actions.dart';
import 'dart:convert';

import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Keys implements CheckpointKeyValueStore {
  final data = <String, String>{};
  bool failNextMarkerWrite = false;

  @override
  Future<String?> getString(String key) async => data[key];

  @override
  Future<void> setString(String key, String value) async {
    if (failNextMarkerWrite &&
        key == PreferencesSessionArchiveStore.activeKey) {
      failNextMarkerWrite = false;
      throw StateError('Injected marker write failure');
    }
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
  test('A2.5: restored prior generation stays flagged until consent',
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
    expect(store.recoveredOlderCheckpoint, true,
        reason: 'Unacknowledged rollback must persist across reads');
    // A fresh store instance represents an actual new app process.
    final reopened = PreferencesSessionArchiveStore(keyValueStore: keys);
    expect(await reopened.read(), first);
    expect(reopened.recoveredOlderCheckpoint, true);
    await reopened.acknowledgeRecoveredCheckpoint();
    expect(reopened.recoveredOlderCheckpoint, false);
    final third = PreferencesSessionArchiveStore(keyValueStore: keys);
    expect(await third.read(), first);
    expect(third.recoveredOlderCheckpoint, false);
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

    await tester.ensureVisible(find.byKey(const Key('ack_recovered_checkpoint')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ack_recovered_checkpoint')));
    await tester.pumpAndSettle();
    expect(session.recoveryNeedsConfirmation, false);
    expect(session.actionsPaused, false);
    expect(find.byKey(const Key('recovery_warning')), findsNothing);
    expect(tester.widget<OutlinedButton>(find.byKey(const Key('pass')))
        .onPressed, isNotNull);

    await tester.ensureVisible(find.byKey(const Key('pass')));
    await tester.pumpAndSettle();
    await tapBiddingAware(tester, find.byKey(const Key('pass')), 'pass');
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

  test('A2.5: killing session twice never bypasses consent', () async {
    final keys = _Keys();
    final writer = PreferencesSessionArchiveStore(keyValueStore: keys);
    await writer.write(_snapshot());
    await writer.write(_snapshot(humanPassed: true));
    keys.corruptLatest();

    final first = BridgeSession(
      archiveStore: PreferencesSessionArchiveStore(keyValueStore: keys),
    );
    expect(await first.restoreSavedGame(), isTrue);
    expect(first.recoveryNeedsConfirmation, isTrue);
    expect(first.view!.version, 0);
    first.dispose();

    final second = BridgeSession(
      archiveStore: PreferencesSessionArchiveStore(keyValueStore: keys),
    );
    addTearDown(second.dispose);
    expect(await second.restoreSavedGame(), isTrue);
    expect(second.recoveryNeedsConfirmation, isTrue);
    await second.submitCall(const Pass());
    expect(second.view!.version, 0);
    await second.acknowledgeRecoveredCheckpoint();
    expect(second.recoveryNeedsConfirmation, isFalse);
    await second.submitCall(const Pass());
    expect(second.finished, true);
  });

  test('A2.5: failed acknowledgment is not treated as consent', () async {
    final keys = _Keys();
    final store = PreferencesSessionArchiveStore(keyValueStore: keys);
    await store.write(_snapshot());
    await store.write(_snapshot(humanPassed: true));
    keys.corruptLatest();
    final session = BridgeSession(archiveStore: store);
    addTearDown(session.dispose);
    expect(await session.restoreSavedGame(), true);
    final before = keys.data[PreferencesSessionArchiveStore.activeKey];
    keys.failNextMarkerWrite = true;
    await session.acknowledgeRecoveredCheckpoint();
    expect(session.recoveryNeedsConfirmation, true);
    expect(session.actionsPaused, true);
    expect(session.errorCode, 'errorSave');
    expect(keys.data[PreferencesSessionArchiveStore.activeKey], before);
    await session.submitCall(const Pass());
    expect(session.view!.version, 0);

    final reopened = BridgeSession(
      archiveStore: PreferencesSessionArchiveStore(keyValueStore: keys),
    );
    addTearDown(reopened.dispose);
    expect(await reopened.restoreSavedGame(), true);
    expect(reopened.recoveryNeedsConfirmation, true);
    expect(reopened.view!.version, 0);
    await reopened.acknowledgeRecoveredCheckpoint();
    expect(reopened.recoveryNeedsConfirmation, false);
  });

  test('A2.5: invalid consent marker is never accepted', () async {
    final keys = _Keys();
    final store = PreferencesSessionArchiveStore(keyValueStore: keys);
    await store.write(_snapshot());
    final invalid = jsonDecode(
        keys.data[PreferencesSessionArchiveStore.activeKey]!)
        as Map<String, dynamic>;
    invalid['recoveryPending'] = 'yes';
    keys.data[PreferencesSessionArchiveStore.activeKey] = jsonEncode(invalid);
    await expectLater(store.read(), throwsFormatException);
  });

  test('A2.5: explicit new game supersedes unacknowledged backup', () async {
    final keys = _Keys();
    final store = PreferencesSessionArchiveStore(keyValueStore: keys);
    await store.write(_snapshot());
    await store.write(_snapshot(humanPassed: true));
    keys.corruptLatest();
    final session = BridgeSession(archiveStore: store);
    addTearDown(session.dispose);
    expect(await session.restoreSavedGame(), true);
    expect(session.recoveryNeedsConfirmation, true);
    await session.newGame(boardNumber: 2, humanSeat: Seat.east);
    expect(session.recoveryNeedsConfirmation, false);
    expect(session.board.number, 2);
    final newer = PreferencesSessionArchiveStore(keyValueStore: keys);
    final raw = await newer.read();
    expect(raw, isNotNull);
    expect(SavedBoardCodec.decode(raw!).board.number, 2);
    expect(newer.recoveredOlderCheckpoint, false);
  });

}

