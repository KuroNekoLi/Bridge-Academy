import '../test_driver/bidding_test_actions.dart';
import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/completed_history_store.dart';
import 'package:bridge_academy_flutter/src/four_board_practice.dart';
import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _PassBot implements BotPolicy {
  @override
  Future<GameAction> choose(PlayerView view) async =>
      CallAction(view.viewer, const Pass());
}

class _MemoryArchive implements SessionArchiveStore {
  String? saved;
  @override
  Future<String?> read() async => saved;
  @override
  Future<void> write(String archive) async { saved = archive; }
  @override
  Future<void> clear() async { saved = null; }
}

BridgeSession _session({
  _MemoryArchive? archive,
  CompletedHistoryStore? history,
}) => BridgeSession(
  botFactory: (_) => _PassBot(),
  freshDealFactory: Deal.suitPerSeat,
  archiveStore: archive,
  historyStore: history,
);

Future<void> _finishPassOut(BridgeSession session) async {
  expect(session.view!.phase, Phase.auction);
  expect(session.view!.canAct, true);
  await session.submitCall(const Pass());
  expect(session.finished, true);
  expect(session.view!.nsScore, 0);
  expect(session.view!.auction.length, 4);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final item = find.byKey(Key(key));
  await tester.ensureVisible(item);
  await tester.pump();
  await tapBiddingAware(tester, item, key);
  await tester.pumpAndSettle();
}

void main() {
  test('B1 validated four sequential duplicate boards, no fake MP/IMP', () {
    final a = FourBoardPractice(
      startBoard: 17, humanSeat: Seat.east, results: const [],
    );
    expect(a.nextBoardNumber, 17);
    final b = a.withResult(const FourBoardResult(
      id: 'original_0001', boardNumber: 17,
      contract: '3NT', nsScore: 420,
    ));
    expect(b.completed, 1);
    expect(b.humanNetScore, -420);
    final restored = FourBoardPractice.fromJson(b.toJson());
    expect(restored.humanNetScore, -420);
    expect(restored.nextBoardNumber, 18);
    expect(() => restored.withResult(const FourBoardResult(
      id: 'bad_duplicate', boardNumber: 17,
      contract: 'PASS OUT', nsScore: 0,
    )), throwsFormatException);
    expect(() => FourBoardPractice.fromJson({
      'v': 1, 'startBoard': 1, 'humanSeat': 'N',
      'results': [
        {'id': 'same_item_01', 'board': 1, 'contract': 'PASS OUT', 'nsScore': 0},
        {'id': 'same_item_01', 'board': 2, 'contract': 'PASS OUT', 'nsScore': 0},
      ]
    }), throwsFormatException);
  });

  test('B1 local practice completes exactly four boards and saves history', () async {
    final archive = _MemoryArchive();
    final history = MemoryCompletedHistoryStore();
    final session = _session(archive: archive, history: history);
    addTearDown(session.dispose);
    await session.startFourBoardPractice();
    expect(session.board.number, 1);
    expect(session.boardMode, BoardMode.fresh);
    expect(session.fourBoardPractice!.completed, 0);

    for (var i = 1; i <= 4; i++) {
      expect(session.board.number, i);
      await _finishPassOut(session);
      expect(session.fourBoardPractice!.completed, i);
      expect(session.fourBoardPractice!.humanNetScore, 0);
      expect(session.completedHistory.length, i);
      final saved = SavedBoardCodec.decode(archive.saved!);
      expect(saved.fourBoardPractice!.completed, i);
      // Ordinary restart/redeal must not skip an unfinished series.
      if (i < 4) {
        await session.newGame();
        expect(session.board.number, i);
        await session.nextFourBoardPractice();
        expect(session.board.number, i + 1);
      }
    }
    expect(session.fourBoardPractice!.isComplete, true);
    expect(session.fourBoardPractice!.results.map((e) => e.boardNumber),
        [1, 2, 3, 4]);
    await session.nextFourBoardPractice();
    expect(session.board.number, 4);
    // A new ordinary board leaves the completed practice results in history.
    await session.newGame(boardNumber: 5);
    expect(session.fourBoardPractice, isNull);
    expect(session.completedHistory.length, 4);
  });

  test('B1 resumes in-progress series without double-scoring terminal deal', () async {
    final archive = _MemoryArchive();
    final history = MemoryCompletedHistoryStore();
    final s1 = _session(archive: archive, history: history);
    await s1.startFourBoardPractice(humanSeat: Seat.north);
    await _finishPassOut(s1);
    final id = s1.fourBoardPractice!.results.single.id;
    s1.dispose();

    final s2 = _session(archive: archive, history: history);
    expect(await s2.restoreSavedGame(), true);
    expect(s2.fourBoardPractice!.completed, 1);
    expect(s2.fourBoardPractice!.results.single.id, id);
    expect(s2.completedHistory.length, 1);
    await s2.nextFourBoardPractice();
    expect(s2.board.number, 2);
    expect(s2.fourBoardPractice!.completed, 1);
    s2.dispose();

    final s3 = _session(archive: archive, history: history);
    addTearDown(s3.dispose);
    expect(await s3.restoreSavedGame(), true);
    expect(s3.board.number, 2);
    expect(s3.fourBoardPractice!.completed, 1);
    await _finishPassOut(s3);
    expect(s3.fourBoardPractice!.completed, 2);
    expect(s3.completedHistory.length, 2);
  });

  testWidgets('B1 visible zh-TW controls and result summary', (tester) async {
    final session = _session(history: MemoryCompletedHistoryStore());
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    expect(find.byKey(const Key('start_four_board')), findsOneWidget);
    await _tap(tester, 'start_four_board');
    expect(find.byKey(const Key('four_board_panel')), findsOneWidget);
    expect(find.text('已完成副數: 0 / 4'), findsOneWidget);
    await _tap(tester, 'pass');
    expect(find.byKey(const Key('next_practice_board')), findsOneWidget);
    expect(find.text('已完成副數: 1 / 4'), findsOneWidget);
    await _tap(tester, 'next_practice_board');
    expect(session.board.number, 2);
    for (var i = 2; i <= 4; i++) {
      await _tap(tester, 'pass');
      if (i < 4) await _tap(tester, 'next_practice_board');
    }
    expect(find.byKey(const Key('four_board_finished')), findsOneWidget);
    expect(find.text('已完成副數: 4 / 4'), findsOneWidget);
    expect(find.byKey(const Key('next_practice_board')), findsNothing);
    await _tap(tester, 'toggle_locale');
    expect(find.text('Four boards finished! Review each deal in History.'),
        findsOneWidget);
  });
}
