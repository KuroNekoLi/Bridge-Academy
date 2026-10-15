import 'dart:convert';

import 'package:bridge_academy_flutter/src/secure_session_persistence.dart';
import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Key implements ArchiveEncryptionKeyProvider {
  const _Key([this.fill = 42]);
  final int fill;

  @override
  Future<List<int>> loadOrCreateKey() async => List.filled(32, fill);
}

String _archive({bool passed = false}) {
  final board = BoardDefinition.forNumber(1);
  final coordinator = SinglePlayerCoordinator(
    deal: Deal.suitPerSeat(),
    dealer: board.dealer,
    vulnerability: board.vulnerability,
    humanSeat: Seat.north,
    bot: const DeterministicTrainingBot(),
  );
  if (passed) {
    coordinator.submitHuman(
      const CallAction(Seat.north, Pass()),
      expectedVersion: 0,
    );
  }
  return SavedBoardCodec.encode(
    board: board,
    humanSeat: Seat.north,
    opponentMode: 'demo',
    boardMode: 'training',
    coordinator: coordinator,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('A2.8: browser record contains AEAD boxes, no privileged plaintext',
      () async {
    final prefs = SharedPreferencesAsync();
    final first = EncryptedTransactionalSessionArchiveStore.browser(
      preferences: prefs, keys: const _Key(),
    );
    await first.write(_archive());
    final raw = await prefs.getString(BrowserSingleRecordArchiveStore.key);
    expect(raw, isNotNull);
    final record = jsonDecode(raw!) as Map<String, dynamic>;
    expect(record['generation'], 1);
    expect((record['active'] as Map)['ciphertext'], isNotEmpty);
    expect(raw, isNot(contains('dealPbn')));
    expect(raw, isNot(contains('humanSeat')));
    expect(raw, isNot(contains('N:AKQJ')));

    final reopened = EncryptedTransactionalSessionArchiveStore.browser(
      preferences: SharedPreferencesAsync(), keys: const _Key(),
    );
    final restored = await reopened.read();
    expect(restored, _archive());
    expect(SavedBoardCodec.decode(restored!).state.version, 0);
    await reopened.clear();
    expect(await prefs.getString(BrowserSingleRecordArchiveStore.key), isNull);
  });

  test('A2.8: migrates valid old plaintext only after encrypted commit',
      () async {
    final prefs = SharedPreferencesAsync();
    final legacy = PreferencesSessionArchiveStore(preferences: prefs);
    await legacy.write(_archive(passed: true));
    expect(await prefs.getString(PreferencesSessionArchiveStore.activeKey),
        isNotNull);
    final migrated = EncryptedTransactionalSessionArchiveStore.browser(
      preferences: prefs, keys: const _Key(),
    );
    expect(SavedBoardCodec.decode((await migrated.read())!).state.version, 1);
    final encrypted =
        await prefs.getString(BrowserSingleRecordArchiveStore.key);
    expect(encrypted, isNotNull);
    expect(encrypted, isNot(contains('dealPbn')));
    expect(await prefs.getString(PreferencesSessionArchiveStore.activeKey),
        isNull);
    expect(await prefs.getString(PreferencesSessionArchiveStore.slotAKey),
        isNull);
    expect(await prefs.getString(PreferencesSessionArchiveStore.slotBKey),
        isNull);
    expect(await prefs.getString(PreferencesSessionArchiveStore.key), isNull);
  });

  test('A2.8: wrong browser key rejects both generations without fallback',
      () async {
    final prefs = SharedPreferencesAsync();
    final first = EncryptedTransactionalSessionArchiveStore.browser(
      preferences: prefs, keys: const _Key(),
    );
    await first.write(_archive());
    await first.write(_archive(passed: true));
    final encrypted =
        await prefs.getString(BrowserSingleRecordArchiveStore.key);
    final mismatched = EncryptedTransactionalSessionArchiveStore.browser(
      preferences: prefs, keys: const _Key(10),
    );
    await expectLater(mismatched.read(), throwsFormatException);
    expect(await prefs.getString(BrowserSingleRecordArchiveStore.key),
        encrypted);
  });

  test('A2.8: durable rollback warning survives new browser store instance',
      () async {
    final prefs = SharedPreferencesAsync();
    final first = EncryptedTransactionalSessionArchiveStore.browser(
      preferences: prefs, keys: const _Key(),
    );
    await first.write(_archive());
    await first.write(_archive(passed: true));
    final raw = await prefs.getString(BrowserSingleRecordArchiveStore.key);
    final record = jsonDecode(raw!) as Map<String, dynamic>;
    (record['active'] as Map<String, dynamic>)['mac'] = 'invalid';
    await prefs.setString(
        BrowserSingleRecordArchiveStore.key, jsonEncode(record));
    final second = EncryptedTransactionalSessionArchiveStore.browser(
      preferences: prefs, keys: const _Key(),
    );
    expect(SavedBoardCodec.decode((await second.read())!).state.version, 0);
    expect(second.recoveredOlderCheckpoint, isTrue);
    final third = EncryptedTransactionalSessionArchiveStore.browser(
      preferences: SharedPreferencesAsync(), keys: const _Key(),
    );
    expect(SavedBoardCodec.decode((await third.read())!).state.version, 0);
    expect(third.recoveredOlderCheckpoint, isTrue);
    await third.acknowledgeRecoveredCheckpoint();
    final fourth = EncryptedTransactionalSessionArchiveStore.browser(
      preferences: prefs, keys: const _Key(),
    );
    expect(await fourth.read(), isNotNull);
    expect(fourth.recoveredOlderCheckpoint, isFalse);
  });

  test('A2.8: sessions resume without exposing all four hands to UI',
      () async {
    final prefs = SharedPreferencesAsync();
    final first = BridgeSession(
      archiveStore: EncryptedTransactionalSessionArchiveStore.browser(
        preferences: prefs, keys: const _Key(),
      ),
    );
    await first.newGame();
    await first.submitCall(const Pass());
    expect(first.finished, true);
    final version = first.view!.version;
    first.dispose();

    final second = BridgeSession(
      archiveStore: EncryptedTransactionalSessionArchiveStore.browser(
        preferences: SharedPreferencesAsync(), keys: const _Key(),
      ),
    );
    addTearDown(second.dispose);
    expect(await second.restoreSavedGame(), true);
    expect(second.view!.version, version);
    expect(second.view!.nsScore, 0);
    expect(second.view!.toJson().containsKey('hands'), false);
    expect(second.view!.toJson().containsKey('dealPbn'), false);
    expect(second.completedReplay, isNotNull);
  });
}
