import 'dart:convert';

import 'package:bridge_academy_flutter/src/app_copy.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/completed_history_store.dart';
import 'package:bridge_academy_flutter/src/secure_session_persistence.dart';
import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_history_panel.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Records implements AtomicArchiveRecordStore {
  Map<String, dynamic>? latest;
  @override
  Future<Map<String, dynamic>?> readRecord() async =>
      latest == null ? null : Map<String, dynamic>.from(latest!);
  @override
  Future<void> replaceRecord(Map<String, dynamic> record) async {
    latest = Map<String, dynamic>.from(record);
  }
  @override
  Future<void> clearRecord() async { latest = null; }
}

class _Keys implements ArchiveEncryptionKeyProvider {
  @override
  Future<List<int>> loadOrCreateKey() async => List<int>.filled(32, 12);
}

class _Active implements SessionArchiveStore {
  String? data;
  @override
  Future<String?> read() async => data;
  @override
  Future<void> write(String archive) async { data = archive; }
  @override
  Future<void> clear() async { data = null; }
}

Future<void> _passOut(BridgeSession session) async {
  await session.newGame();
  await session.submitCall(const Pass());
  expect(session.finished, true);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final element = find.byKey(Key(key));
  await tester.ensureVisible(element);
  await tester.tap(element);
  await tester.pumpAndSettle();
}

void main() {
  test('encrypted delete survives restart; old checkpoint never recreates it',
      () async {
    final db = _Records();
    final checkpoint = _Active();
    final store = EncryptedCompletedHistoryStore(
        records: db, keys: _Keys());
    final session = BridgeSession(
        historyStore: store, archiveStore: checkpoint);
    await _passOut(session);
    final id = session.completedHistory.single.id;
    expect(await session.deleteHistory(id), true);
    expect(session.completedHistory, isEmpty);
    expect(await store.isDeleted(id), true);
    final ciphertext = jsonEncode(db.latest);
    expect(ciphertext, isNot(contains('N:AJ5')));
    expect(ciphertext, isNot(contains('transcript')));
    session.dispose();

    final newStore = EncryptedCompletedHistoryStore(
        records: db, keys: _Keys());
    final restored = BridgeSession(
        historyStore: newStore, archiveStore: checkpoint);
    addTearDown(restored.dispose);
    expect(await restored.restoreSavedGame(), true);
    expect(restored.finished, true);
    expect(restored.completedHistory, isEmpty);
    expect(await newStore.isDeleted(id), true);
    expect(await newStore.read(), isEmpty);
  });

  test('delete only selected id; deleting an absent id cannot alter history',
      () async {
    final store = MemoryCompletedHistoryStore();
    final session = BridgeSession(historyStore: store);
    addTearDown(session.dispose);
    await _passOut(session);
    final id = session.completedHistory.single.id;
    expect(await session.deleteHistory('no_matching_record'), false);
    expect(session.completedHistory, hasLength(1));
    expect(await session.deleteHistory(id), true);
    expect(session.completedHistory, isEmpty);
    expect(await store.isDeleted(id), true);
  });

  testWidgets('visible search, filters, pagination, delete confirmation',
      (tester) async {
    var records = List<HistorySummary>.generate(7, (i) =>
        HistorySummary(
          id: 'history_test_$i',
          savedAt: DateTime.utc(2026, 10, 16),
          boardNumber: i + 1,
          humanSeat: Seat.north,
          contract: i.isEven ? 'PASS OUT' : '3NT',
          score: i.isEven ? 0 : 400,
          tricks: i.isEven ? 0 : 13,
          isPractice: i.isEven,
        ));
    String? deleted;
    Future<void> render() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, update) => SingleChildScrollView(
                child: BridgeHistoryPanel(
                  history: records,
                  copy: const AppCopy(false),
                  selectedId: null,
                  selectedReplay: null,
                  replayIndex: 0,
                  onSelect: (_) {},
                  onReplayStep: (_) {},
                  onDelete: (id) async {
                    deleted = id;
                    update(() => records =
                        records.where((item) => item.id != id).toList());
                  },
                  errorCode: null,
                  onRetrySave: null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    await render();
    expect(find.byKey(const Key('history_item_history_test_0')),
        findsOneWidget);
    expect(find.byKey(const Key('history_item_history_test_6')),
        findsNothing);
    expect(find.text('頁數: 1 / 2'), findsOneWidget);
    await _tap(tester, 'history_page_next');
    expect(find.byKey(const Key('history_item_history_test_6')),
        findsOneWidget);

    await tester.enterText(find.byKey(const Key('history_search')), '7');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history_item_history_test_6')),
        findsOneWidget);
    expect(find.byKey(const Key('history_item_history_test_5')),
        findsNothing);
    await tester.enterText(find.byKey(const Key('history_search')),
        'not-present');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history_no_results')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('history_search')), '');
    await tester.pumpAndSettle();

    await _tap(tester, 'history_filter');
    await tester.tap(find.text('有定約').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history_item_history_test_1')),
        findsOneWidget);
    expect(find.byKey(const Key('history_item_history_test_0')),
        findsNothing);

    await _tap(tester, 'history_delete_history_test_1');
    expect(find.text('刪除這副牌局？'), findsOneWidget);
    await _tap(tester, 'history_delete_cancel');
    expect(deleted, isNull);
    await _tap(tester, 'history_delete_history_test_1');
    await _tap(tester, 'history_delete_confirm');
    expect(deleted, 'history_test_1');
    expect(find.byKey(const Key('history_item_history_test_1')),
        findsNothing);
  });
}
