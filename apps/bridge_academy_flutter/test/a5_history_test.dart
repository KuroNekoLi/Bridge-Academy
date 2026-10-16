import 'dart:convert';

import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/completed_history_store.dart';
import 'package:bridge_academy_flutter/src/secure_session_persistence.dart';
import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ActiveStore implements SessionArchiveStore {
  String? latest;
  @override
  Future<String?> read() async => latest;
  @override
  Future<void> write(String archive) async { latest = archive; }
  @override
  Future<void> clear() async { latest = null; }
}

class _Records implements AtomicArchiveRecordStore {
  Map<String, dynamic>? record;
  @override
  Future<Map<String, dynamic>?> readRecord() async =>
      record == null ? null : Map<String, dynamic>.from(record!);
  @override
  Future<void> replaceRecord(Map<String, dynamic> value) async {
    record = Map<String, dynamic>.from(value);
  }
  @override
  Future<void> clearRecord() async { record = null; }
}

class _Keys implements ArchiveEncryptionKeyProvider {
  @override
  Future<List<int>> loadOrCreateKey() async => List<int>.filled(32, 7);
}

Future<void> _passOut(BridgeSession session) async {
  await session.newGame();
  await session.submitCall(const Pass());
  expect(session.finished, true);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  group('A5 player history', () {
    test('completed board is saved, can be replayed after next board',
        () async {
      final store = MemoryCompletedHistoryStore();
      final session = BridgeSession(historyStore: store);
      addTearDown(session.dispose);
      await _passOut(session);
      expect(session.completedHistory, hasLength(1));
      final summary = session.completedHistory.single;
      expect(summary.boardNumber, 1);
      expect(summary.score, 0);
      expect(summary.tricks, 0);
      expect(summary.contract, 'PASS OUT');
      final replay = session.historyReplay(summary.id)!;
      expect(replay.frames.length, 5);
      expect(replay.frames.first.view.dummyCards, isNull);
      expect(replay.frames.last.view.nsScore, 0);
      await session.nextBoard();
      expect(session.board.number, 2);
      expect(session.completedReplay, isNull);
      expect(session.completedHistory, hasLength(1));
      expect(session.historyReplay(summary.id)!.historyFingerprint,
          replay.historyFingerprint);
    });

    test('two completed repetitions of the same deal are separate sessions',
        () async {
      final session = BridgeSession(
          historyStore: MemoryCompletedHistoryStore());
      addTearDown(session.dispose);
      await _passOut(session);
      final first = session.completedHistory.single.id;
      await session.replaySameBoard();
      await session.submitCall(const Pass());
      expect(session.completedHistory, hasLength(2));
      expect(session.completedHistory[0].id, isNot(first));
      expect(session.completedHistory[1].id, first);
      expect(session.completedHistory.every((s) => s.isPractice), isTrue);
    });

    test('completed history survives fresh session and does not double count',
        () async {
      final active = _ActiveStore();
      final history = MemoryCompletedHistoryStore();
      final original = BridgeSession(
        archiveStore: active, historyStore: history);
      await _passOut(original);
      final id = original.completedHistory.single.id;
      original.dispose();
      final restored = BridgeSession(
        archiveStore: active, historyStore: history);
      addTearDown(restored.dispose);
      expect(await restored.restoreSavedGame(), isTrue);
      expect(restored.finished, isTrue);
      expect(restored.completedHistory, hasLength(1));
      expect(restored.completedHistory.single.id, id);
      expect(restored.historyReplay(id)!.frames.last.view.nsScore, 0);
    });

    test('encrypted history persists, ciphertext does not reveal PBN;'
        ' corrupted record fails closed', () async {
      final records = _Records();
      final store = EncryptedCompletedHistoryStore(
          records: records, keys: _Keys());
      final session = BridgeSession(historyStore: store);
      addTearDown(session.dispose);
      await _passOut(session);
      expect(records.record, isNotNull);
      final onDisk = jsonEncode(records.record);
      expect(onDisk, isNot(contains('N:AJ5')));
      expect(onDisk, isNot(contains('transcript')));
      expect((await store.read()), hasLength(1));

      final wrongKey = EncryptedCompletedHistoryStore(
        records: records, keys: _WrongKeys());
      await expectLater(wrongKey.read(), throwsA(isA<Exception>()));
      records.record!['ciphertext'] = base64Encode(List<int>.filled(48, 0));
      await expectLater(store.read(), throwsA(isA<Exception>()));
    });

    testWidgets('visible history list and old replay work after new board',
        (tester) async {
      final session = BridgeSession(
          historyStore: MemoryCompletedHistoryStore());
      addTearDown(session.dispose);
      await tester.pumpWidget(BridgeAcademyApp(session: session));
      await _tap(tester, 'new_game');
      await _tap(tester, 'pass');
      await _tap(tester, 'next_board');
      await _tap(tester, 'history_toggle');
      expect(find.byKey(const Key('history_panel')), findsOneWidget);
      expect(find.text('已完成的牌局'), findsOneWidget);
      final id = session.completedHistory.single.id;
      await _tap(tester, 'history_item_$id');
      expect(find.byKey(const Key('replay_panel')), findsOneWidget);
      expect(find.text('事件步驟: 0 / 4'), findsOneWidget);
      await _tap(tester, 'replay_last');
      expect(find.text('事件步驟: 4 / 4'), findsOneWidget);
      await _tap(tester, 'toggle_locale');
      expect(find.text('Completed deals'), findsOneWidget);
      await _tap(tester, 'history_toggle');
      expect(find.byKey(const Key('history_panel')), findsNothing);
      expect(session.board.number, 2);
    });
  });
}

class _WrongKeys implements ArchiveEncryptionKeyProvider {
  @override
  Future<List<int>> loadOrCreateKey() async => List<int>.filled(32, 9);
}
