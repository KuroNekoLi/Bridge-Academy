import 'dart:convert';

import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

class _FaultyKeys implements CheckpointKeyValueStore {
  final Map<String, String> data = {};
  String? failNextKey;
  String? corruptNextKey;

  @override
  Future<String?> getString(String key) async => data[key];

  @override
  Future<void> setString(String key, String value) async {
    if (failNextKey == key) {
      failNextKey = null;
      throw StateError('Injected write failure');
    }
    if (corruptNextKey == key) {
      corruptNextKey = null;
      data[key] = 'torn-json';
      return;
    }
    data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    data.remove(key);
  }
}

String _checkpoint({int number = 1, bool humanPassed = false}) {
  final board = BoardDefinition.forNumber(number);
  final coordinator = SinglePlayerCoordinator(
    deal: Deal.suitPerSeat(),
    dealer: board.dealer,
    vulnerability: board.vulnerability,
    humanSeat: board.dealer,
    bot: const DeterministicTrainingBot(),
  );
  if (humanPassed) {
    coordinator.submitHuman(CallAction(board.dealer, const Pass()),
        expectedVersion: 0);
  }
  return SavedBoardCodec.encode(
    board: board,
    humanSeat: board.dealer,
    opponentMode: 'demo',
    boardMode: 'training',
    coordinator: coordinator,
  );
}

void main() {
  group('P1-A2.2 two-slot committed checkpoint', () {
    test('alternating slots preserve latest version and previous backup',
        () async {
      final keys = _FaultyKeys();
      final store = PreferencesSessionArchiveStore(keyValueStore: keys);
      final first = _checkpoint();
      final second = _checkpoint(humanPassed: true);
      await store.write(first);
      expect((jsonDecode(keys.data[PreferencesSessionArchiveStore.activeKey]!) as Map<String, dynamic>)['slot'], 'a');
      expect(await store.read(), first);
      await store.write(second);
      expect((jsonDecode(keys.data[PreferencesSessionArchiveStore.activeKey]!) as Map<String, dynamic>)['slot'], 'b');
      expect(await store.read(), second);
      expect(keys.data[PreferencesSessionArchiveStore.slotAKey],
          contains('"storeVersion":2'));
    });

    test('interruption while writing pending slot preserves commit',
        () async {
      final keys = _FaultyKeys();
      final store = PreferencesSessionArchiveStore(keyValueStore: keys);
      final previous = _checkpoint();
      await store.write(previous);
      keys.failNextKey = PreferencesSessionArchiveStore.slotBKey;
      await expectLater(store.write(_checkpoint(humanPassed: true)),
          throwsStateError);
      expect(await store.read(), previous);
      expect((jsonDecode(keys.data[PreferencesSessionArchiveStore.activeKey]!) as Map<String, dynamic>)['slot'], 'a');
    });

    test('interruption during marker commit preserves previously marked slot',
        () async {
      final keys = _FaultyKeys();
      final store = PreferencesSessionArchiveStore(keyValueStore: keys);
      final previous = _checkpoint();
      await store.write(previous);
      keys.failNextKey = PreferencesSessionArchiveStore.activeKey;
      await expectLater(store.write(_checkpoint(humanPassed: true)),
          throwsStateError);
      expect(keys.data[PreferencesSessionArchiveStore.slotBKey], isNotNull);
      expect(await store.read(), previous);
      expect((jsonDecode(keys.data[PreferencesSessionArchiveStore.activeKey]!) as Map<String, dynamic>)['slot'], 'a');
    });

    test('read-back detects torn write before committing marker',
        () async {
      final keys = _FaultyKeys();
      final store = PreferencesSessionArchiveStore(keyValueStore: keys);
      final previous = _checkpoint();
      await store.write(previous);
      keys.corruptNextKey = PreferencesSessionArchiveStore.slotBKey;
      await expectLater(store.write(_checkpoint(humanPassed: true)),
          throwsStateError);
      expect(await store.read(), previous);
    });

    test('corrupt active slot rolls back to prior legal checkpoint',
        () async {
      final keys = _FaultyKeys();
      final store = PreferencesSessionArchiveStore(keyValueStore: keys);
      final previous = _checkpoint();
      await store.write(previous);
      await store.write(_checkpoint(humanPassed: true));
      keys.data[PreferencesSessionArchiveStore.slotBKey] = 'corrupted';
      expect(await store.read(), previous);
      expect((jsonDecode(keys.data[PreferencesSessionArchiveStore.activeKey]!) as Map<String, dynamic>)['slot'], 'a');
      expect(SavedBoardCodec.decode((await store.read())!).state.version, 0);
    });

    test('valid checksum cannot legitimize an illegal game event',
        () async {
      final keys = _FaultyKeys();
      final store = PreferencesSessionArchiveStore(keyValueStore: keys);
      final previous = _checkpoint();
      await store.write(previous);
      await store.write(_checkpoint(humanPassed: true));
      final envelope = jsonDecode(
          keys.data[PreferencesSessionArchiveStore.slotBKey]!)
          as Map<String, dynamic>;
      final archive = jsonDecode(envelope['archive'] as String)
          as Map<String, dynamic>;
      archive['eventVersion'] = 99;
      final tampered = jsonEncode(archive);
      envelope['archive'] = tampered;
      envelope['sha256'] = sha256.convert(utf8.encode(tampered)).toString();
      keys.data[PreferencesSessionArchiveStore.slotBKey] =
          jsonEncode(envelope);
      expect(await store.read(), previous);
      expect((jsonDecode(keys.data[PreferencesSessionArchiveStore.activeKey]!) as Map<String, dynamic>)['slot'], 'a');
    });

    test('uncommitted next generation cannot become recovery fallback',
        () async {
      final keys = _FaultyKeys();
      final store = PreferencesSessionArchiveStore(keyValueStore: keys);
      await store.write(_checkpoint()); // committed A generation 1
      keys.failNextKey = PreferencesSessionArchiveStore.activeKey;
      await expectLater(store.write(_checkpoint(humanPassed: true)),
          throwsStateError); // B gen 2 written but never committed.
      keys.data[PreferencesSessionArchiveStore.slotAKey] = 'corrupted';
      // Returning B here would apply a never-committed human action.
      await expectLater(store.read(), throwsFormatException);
    });

    test('two corrupt slots reject rather than fabricate a new game',
        () async {
      final keys = _FaultyKeys();
      final store = PreferencesSessionArchiveStore(keyValueStore: keys);
      await store.write(_checkpoint());
      await store.write(_checkpoint(humanPassed: true));
      keys.data[PreferencesSessionArchiveStore.slotAKey] = 'broken';
      keys.data[PreferencesSessionArchiveStore.slotBKey] = 'broken';
      await expectLater(store.read(), throwsFormatException);
    });

    test('no marker ignores orphan slot from interrupted initial write',
        () async {
      final keys = _FaultyKeys();
      final store = PreferencesSessionArchiveStore(keyValueStore: keys);
      keys.failNextKey = PreferencesSessionArchiveStore.activeKey;
      await expectLater(store.write(_checkpoint()), throwsStateError);
      expect(keys.data[PreferencesSessionArchiveStore.slotAKey], isNotNull);
      expect(await store.read(), isNull);
    });

    test('v1 legacy data migrates only after a verified v2 commit',
        () async {
      final keys = _FaultyKeys();
      final store = PreferencesSessionArchiveStore(keyValueStore: keys);
      final old = _checkpoint(number: 2);
      keys.data[PreferencesSessionArchiveStore.key] = old;
      expect(await store.read(), old);
      expect(keys.data.containsKey(PreferencesSessionArchiveStore.key), false);
      expect((jsonDecode(keys.data[PreferencesSessionArchiveStore.activeKey]!) as Map<String, dynamic>)['slot'], 'a');
      expect(SavedBoardCodec.decode((await store.read())!).board.number, 2);
    });

    test('migration failure never deletes the original v1 checkpoint',
        () async {
      final keys = _FaultyKeys();
      final store = PreferencesSessionArchiveStore(keyValueStore: keys);
      final old = _checkpoint(number: 2);
      keys.data[PreferencesSessionArchiveStore.key] = old;
      keys.failNextKey = PreferencesSessionArchiveStore.activeKey;
      await expectLater(store.read(), throwsStateError);
      expect(keys.data[PreferencesSessionArchiveStore.key], old);
      expect(keys.data.containsKey(PreferencesSessionArchiveStore.activeKey),
          false);
      expect(await store.read(), old);
    });

    test('invalid v1 migration refuses poisoned records', () async {
      final keys = _FaultyKeys();
      final store = PreferencesSessionArchiveStore(keyValueStore: keys);
      keys.data[PreferencesSessionArchiveStore.key] = 'not-json';
      await expectLater(store.read(), throwsFormatException);
      expect(keys.data[PreferencesSessionArchiveStore.key], 'not-json');
      expect(keys.data.containsKey(PreferencesSessionArchiveStore.activeKey),
          false);
    });

    test('clear removes both committed and legacy versions', () async {
      final keys = _FaultyKeys();
      final store = PreferencesSessionArchiveStore(keyValueStore: keys);
      await store.write(_checkpoint());
      await store.write(_checkpoint(humanPassed: true));
      keys.data[PreferencesSessionArchiveStore.key] = _checkpoint();
      await store.clear();
      expect(keys.data, isEmpty);
      expect(await store.read(), isNull);
    });

    test('BridgeSession restore retains player secrecy and legal events',
        () async {
      final keys = _FaultyKeys();
      final store = PreferencesSessionArchiveStore(keyValueStore: keys);
      final first = BridgeSession(archiveStore: store);
      await first.newGame(boardNumber: 2, humanSeat: Seat.east);
      await first.submitCall(const Pass());
      expect(first.finished, isTrue);
      final finalVersion = first.view!.version;
      final fingerprint = first.completedReplay!.historyFingerprint;
      first.dispose();

      final resumed = BridgeSession(archiveStore: store);
      addTearDown(resumed.dispose);
      expect(await resumed.restoreSavedGame(), isTrue);
      expect(resumed.board.number, 2);
      expect(resumed.humanSeat, Seat.east);
      expect(resumed.view!.version, finalVersion);
      expect(resumed.completedReplay!.historyFingerprint, fingerprint);
      expect(resumed.view!.toJson().containsKey('dealPbn'), isFalse);
      expect(resumed.view!.toJson().containsKey('hands'), isFalse);
      expect(resumed.view!.dummyCards, isNull);
    });
  });
}
