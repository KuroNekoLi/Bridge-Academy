import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/completed_history_store.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _tap(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<String> _validFullGame() async {
  final session = BridgeSession(historyStore: MemoryCompletedHistoryStore());
  try {
    await session.newGame();
    await session.submitCall(const Bid(1, Strain.notrump));
    var steps = 0;
    while (!session.finished && steps++ < 60) {
      final view = session.view!;
      if (!view.canAct || view.legalCards.isEmpty) {
        throw StateError('Demo fixture could not complete');
      }
      await session.submitCard(view.legalCards.first);
    }
    if (!session.finished) throw StateError('Demo fixture incomplete');
    return session.exportHistoryPbn(session.completedHistory.single.id)!;
  } finally {
    session.dispose();
  }
}

Future<String> _validPassOut() async {
  final session = BridgeSession(historyStore: MemoryCompletedHistoryStore());
  try {
    await session.newGame();
    await session.submitCall(const Pass());
    return session.exportHistoryPbn(session.completedHistory.single.id)!;
  } finally {
    session.dispose();
  }
}

void main() {
  test('A5.3.3 imports a finished 13-trick exported PBN, retains local game',
      () async {
    final pbn = await _validFullGame();
    final store = MemoryCompletedHistoryStore();
    final session = BridgeSession(historyStore: store);
    addTearDown(session.dispose);
    await session.newGame();
    final version = session.view!.version;
    expect(await session.importHistoryPbn(pbn), isTrue);
    expect(session.view!.version, version);
    expect(session.completedHistory, hasLength(1));
    final item = session.completedHistory.single;
    expect(item.tricks, 13);
    final replay = session.historyReplay(item.id)!;
    expect(replay.frames.last.view.completedTricks, hasLength(13));
    expect(replay.frames.last.view.nsScore, item.score);
    expect(replay.frames.first.view.dummyCards, isNull);
    expect(replay.frames.first.view.ownCards, hasLength(13));
    expect(replay.frames.first.view.toJson().containsKey('deal'), false);
    expect(await session.importHistoryPbn(pbn), isFalse);
    expect(session.historyError, 'errorHistoryDuplicate');
    expect(session.completedHistory, hasLength(1));

    final reopened = BridgeSession(historyStore: store);
    addTearDown(reopened.dispose);
    await reopened.loadHistory();
    expect(reopened.completedHistory, hasLength(1));
    expect(reopened.historyReplay(item.id)!.frames.last.view.nsScore,
        item.score);
  });

  test('A5.3.3 pass out imports only four real Pass calls', () async {
    final pbn = await _validPassOut();
    final session = BridgeSession(
        historyStore: MemoryCompletedHistoryStore());
    addTearDown(session.dispose);
    expect(await session.importHistoryPbn(pbn), isTrue);
    final record = session.completedHistory.single;
    expect(record.contract, 'PASS OUT');
    expect(record.score, 0);
    final replay = session.historyReplay(record.id)!;
    expect(replay.frames, hasLength(5));
    expect(replay.frames.last.view.completedTricks, isEmpty);
  });

  test('A5.3.3 rejects tampered score, card, partial auction and metadata',
      () async {
    final pbn = await _validFullGame();
    final session = BridgeSession(
        historyStore: MemoryCompletedHistoryStore());
    addTearDown(session.dispose);
    final changed = <String>[
      pbn.replaceFirst(RegExp(r'\[Score "NS [^"]+"\]'),
          '[Score "NS +9999"]'),
      pbn.replaceFirst(RegExp(r'\[Board "[^"]+"\]'),
          '[Board "2"]'),
      pbn.replaceFirst(RegExp(r'\[Play "[^"]+"\]\n'),
          '[Play "N"]\n'),
      pbn.replaceFirst(RegExp(r'\[Deal "[^"]+"\]'),
          '[Deal "N:AAAAAAAAAAAAA... ... ... ..."]'),
      pbn.replaceFirst(
          '1NT Pass Pass Pass', '1NT Pass Pass'),
      pbn.replaceFirst(RegExp(r'\[Result "[^"]+"\]'),
          '[Result "99"]'),
      '[Board "1"]',
    ];
    for (final invalid in changed) {
      expect(await session.importHistoryPbn(invalid), isFalse);
      expect(session.completedHistory, isEmpty);
      expect(session.historyError, 'errorHistoryImport');
    }
    expect(session.started, false);
  });

  testWidgets('A5.3.3 history import is a visible zh-TW player action',
      (tester) async {
    final source = await _validPassOut();
    final session = BridgeSession(
        historyStore: MemoryCompletedHistoryStore());
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await _tap(tester, 'history_toggle');
    expect(find.byKey(const Key('history_empty')), findsOneWidget);
    await _tap(tester, 'history_import_open');
    expect(find.byKey(const Key('history_import_input')), findsOneWidget);
    await _tap(tester, 'history_import_cancel');
    expect(session.completedHistory, isEmpty);
    await _tap(tester, 'history_import_open');
    await tester.enterText(
        find.byKey(const Key('history_import_input')), source);
    await _tap(tester, 'history_import_confirm');
    expect(session.completedHistory, hasLength(1));
    expect(find.text('牌局已匯入，可從歷史列表開啟複盤。'),
        findsOneWidget);
    final id = session.completedHistory.single.id;
    await _tap(tester, 'history_item_$id');
    expect(find.byKey(const Key('replay_panel')), findsOneWidget);
    await _tap(tester, 'toggle_locale');
    expect(find.text('Completed deals'), findsOneWidget);
  });
}
