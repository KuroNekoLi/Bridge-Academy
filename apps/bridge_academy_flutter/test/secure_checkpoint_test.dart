import 'dart:convert';

import 'package:bridge_academy_flutter/src/secure_session_persistence.dart';
import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter_test/flutter_test.dart';

class _Records implements AtomicArchiveRecordStore {
  Map<String, dynamic>? value;
  bool failNextWrite = false;
  int writes = 0;

  Map<String, dynamic> clone(Map<String, dynamic> original) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(original)) as Map);

  @override
  Future<Map<String, dynamic>?> readRecord() async =>
      value == null ? null : clone(value!);

  @override
  Future<void> replaceRecord(Map<String, dynamic> record) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('Simulated SQL transaction rollback');
    }
    value = clone(record);
    writes++;
  }

  @override
  Future<void> clearRecord() async {
    value = null;
  }
}

class _Keys implements ArchiveEncryptionKeyProvider {
  _Keys([int fill = 9]) : material = List.filled(32, fill);
  final List<int> material;
  @override
  Future<List<int>> loadOrCreateKey() async => List.of(material);
}

class _Legacy implements SessionArchiveStore {
  _Legacy(this.archive);
  String? archive;
  bool failClear = false;
  int cleared = 0;

  @override
  Future<String?> read() async => archive;

  @override
  Future<void> write(String next) async => archive = next;

  @override
  Future<void> clear() async {
    if (failClear) throw StateError('Simulated preferences delete failure');
    archive = null;
    cleared++;
  }
}

String _game({bool hasPass = false, int boardNumber = 1}) {
  final board = BoardDefinition.forNumber(boardNumber);
  final coordinator = SinglePlayerCoordinator(
    deal: Deal.suitPerSeat(),
    dealer: board.dealer,
    vulnerability: board.vulnerability,
    humanSeat: board.dealer,
    bot: const DeterministicTrainingBot(),
  );
  if (hasPass) {
    coordinator.submitHuman(
      CallAction(board.dealer, const Pass()),
      expectedVersion: 0,
    );
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
  group('P1-A2.7 transactional AEAD checkpoint', () {
    test('encrypts all four private hands, survives fresh session instance',
        () async {
      final records = _Records();
      final key = _Keys();
      final first = EncryptedTransactionalSessionArchiveStore(
        records: records, keys: key,
      );
      final archive = _game();
      await first.write(archive);
      expect(jsonEncode(records.value), isNot(contains('dealPbn')));
      expect(jsonEncode(records.value), isNot(contains('N:AK')));
      expect(jsonEncode(records.value), isNot(contains('humanSeat')));
      final restored = EncryptedTransactionalSessionArchiveStore(
        records: records, keys: key,
      );
      expect(await restored.read(), archive);
      expect(restored.recoveredOlderCheckpoint, isFalse);
      expect(SavedBoardCodec.decode((await restored.read())!).state.version, 0);
    });

    test('two updates retain exactly prior committed generation', () async {
      final records = _Records();
      final store = EncryptedTransactionalSessionArchiveStore(
        records: records, keys: _Keys(),
      );
      await store.write(_game());
      await store.write(_game(hasPass: true));
      expect(records.value!['generation'], 2);
      expect(records.value!['previousGeneration'], 1);
      expect(SavedBoardCodec.decode((await store.read())!).state.version, 1);
    });

    test('aborted atomic commit keeps previously verified snapshot',
        () async {
      final records = _Records();
      final store = EncryptedTransactionalSessionArchiveStore(
        records: records, keys: _Keys(),
      );
      await store.write(_game());
      final before = jsonEncode(records.value);
      records.failNextWrite = true;
      await expectLater(store.write(_game(hasPass: true)), throwsStateError);
      expect(jsonEncode(records.value), before);
      expect(SavedBoardCodec.decode((await store.read())!).state.version, 0);
    });

    test('damaged current GCM box rolls back with durable consent', () async {
      final records = _Records();
      final key = _Keys();
      final store = EncryptedTransactionalSessionArchiveStore(
        records: records, keys: key,
      );
      await store.write(_game());
      await store.write(_game(hasPass: true));
      final tampered = records.clone(records.value!);
      (tampered['active'] as Map<String, dynamic>)['ciphertext'] = '%%%';
      records.value = tampered;

      final first = EncryptedTransactionalSessionArchiveStore(
        records: records, keys: key,
      );
      expect(SavedBoardCodec.decode((await first.read())!).state.version, 0);
      expect(first.recoveredOlderCheckpoint, isTrue);
      expect(records.value!['recoveryPending'], isTrue);

      final second = EncryptedTransactionalSessionArchiveStore(
        records: records, keys: key,
      );
      expect(SavedBoardCodec.decode((await second.read())!).state.version, 0);
      expect(second.recoveredOlderCheckpoint, isTrue);
      await second.acknowledgeRecoveredCheckpoint();
      expect(records.value!['recoveryPending'], isFalse);

      final third = EncryptedTransactionalSessionArchiveStore(
        records: records, keys: key,
      );
      expect(await third.read(), isNotNull);
      expect(third.recoveredOlderCheckpoint, isFalse);
    });

    test('failure to persist acknowledgment keeps warning across restarts',
        () async {
      final records = _Records();
      final store = EncryptedTransactionalSessionArchiveStore(
        records: records, keys: _Keys(),
      );
      await store.write(_game());
      await store.write(_game(hasPass: true));
      (records.value!['active'] as Map<String, dynamic>)['mac'] = 'bad';
      await store.read();
      expect(store.recoveredOlderCheckpoint, isTrue);
      records.failNextWrite = true;
      await expectLater(store.acknowledgeRecoveredCheckpoint(),
          throwsStateError);
      final after = EncryptedTransactionalSessionArchiveStore(
        records: records, keys: _Keys(),
      );
      expect(await after.read(), isNotNull);
      expect(after.recoveredOlderCheckpoint, isTrue);
    });

    test('wrong secure-store key cannot decrypt and never uses backup',
        () async {
      final records = _Records();
      final store = EncryptedTransactionalSessionArchiveStore(
        records: records, keys: _Keys(),
      );
      await store.write(_game());
      await store.write(_game(hasPass: true));
      final wrong = EncryptedTransactionalSessionArchiveStore(
        records: records, keys: _Keys(7),
      );
      await expectLater(wrong.read(), throwsFormatException);
      expect(records.value!['generation'], 2);
    });

    test('legacy plaintext migration removes it only after encrypted commit',
        () async {
      final records = _Records();
      final legacy = _Legacy(_game(boardNumber: 2));
      final store = EncryptedTransactionalSessionArchiveStore(
        records: records, keys: _Keys(), legacy: legacy,
      );
      records.failNextWrite = true;
      await expectLater(store.read(), throwsStateError);
      expect(legacy.archive, isNotNull);
      expect(records.value, isNull);
      expect(await store.read(), isNotNull);
      expect(legacy.archive, isNull);
      expect(legacy.cleared, 1);
      expect(SavedBoardCodec.decode((await store.read())!).board.number, 2);
    });

    test('after successful migration failed plaintext deletion fails closed',
        () async {
      final records = _Records();
      final legacy = _Legacy(_game())..failClear = true;
      final store = EncryptedTransactionalSessionArchiveStore(
        records: records, keys: _Keys(), legacy: legacy,
      );
      await expectLater(store.read(), throwsStateError);
      expect(records.value, isNotNull);
      expect(legacy.archive, isNotNull);
      legacy.failClear = false;
      expect(await store.read(), isNotNull);
      expect(legacy.archive, isNull);
    });

    test('invalid event archive never enters ciphertext storage', () async {
      final records = _Records();
      final store = EncryptedTransactionalSessionArchiveStore(
        records: records, keys: _Keys(),
      );
      final wrong = Map<String, dynamic>.from(jsonDecode(_game()) as Map);
      wrong['eventVersion'] = 42;
      await expectLater(store.write(jsonEncode(wrong)), throwsFormatException);
      expect(records.value, isNull);
    });

    test('clear removes committed ciphertext and optional legacy data',
        () async {
      final records = _Records();
      final legacy = _Legacy(_game());
      final store = EncryptedTransactionalSessionArchiveStore(
        records: records, keys: _Keys(), legacy: legacy,
      );
      await store.write(_game());
      await store.clear();
      expect(records.value, isNull);
      expect(legacy.archive, isNull);
      expect(await store.read(), isNull);
    });
  });
}
