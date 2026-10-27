import '../test_driver/bidding_test_actions.dart';
import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/daily_practice.dart';
import 'package:bridge_academy_flutter/src/four_board_practice.dart';
import 'package:bridge_academy_flutter/src/daily_practice_store.dart';
import 'package:bridge_academy_flutter/src/completed_history_store.dart';
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
  Future<void> write(String text) async { saved = text; }
  @override
  Future<void> clear() async { saved = null; }
}

class _BrokenDailyStore implements DailyPracticeStore {
  @override
  Future<List<DailyPracticeProgress>> read() async =>
      throw const FormatException('damaged ciphertext');
  @override
  Future<void> write(List<DailyPracticeProgress> records) async =>
      throw StateError('write forbidden');
}

class _FailingWriteDailyStore implements DailyPracticeStore {
  _FailingWriteDailyStore(this.delegate);
  final DailyPracticeStore delegate;
  bool fail = false;
  @override
  Future<List<DailyPracticeProgress>> read() => delegate.read();
  @override
  Future<void> write(List<DailyPracticeProgress> records) {
    if (fail) throw StateError('no space');
    return delegate.write(records);
  }
}

final _day = DateTime.utc(2026, 10, 16);

BridgeSession _session({
  required _MemoryArchive archive,
  required DailyPracticeStore daily,
  MemoryCompletedHistoryStore? history,
}) => BridgeSession(
  archiveStore: archive,
  dailyStore: daily,
  historyStore: history,
  utcNow: () => _day,
  botFactory: (_) => _PassBot(),
);

Future<void> _passOut(BridgeSession session) async {
  expect(session.view!.phase, Phase.auction);
  await session.submitCall(const Pass());
  expect(session.finished, true);
  expect(session.view!.nsScore, 0);
  expect(session.view!.auction.length, 4);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final button = find.byKey(Key(key));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tapBiddingAware(tester, button, key);
  await tester.pumpAndSettle();
}

void main() {
  test('B6 manifest golden, version/UTC identity and legal deck distribution', () {
    final manifest = DailyPracticeManifest.forDate(_day);
    expect(manifest.challengeId, 'daily_2026-10-16_v1');
    expect(DailyPracticeManifest.forDate(
      DateTime.parse('2026-10-16T23:30:00-02:00')).utcDay, '2026-10-17');
    expect(DailyPracticeManifest.forDate(
        _day.add(const Duration(days: 1))).challengeId,
        isNot(manifest.challengeId));
    expect(DailyPracticeManifest.forDate(_day).dealAt(0).toPbn(),
        'N:Q98532.Q.2.KJ865 4.J93.9765.QT974 AT7.K8654.QJ83.A KJ6.AT72.AKT4.32');
    expect(manifest.dealAt(1).toPbn(),
        'N:876.A75.J.KT9654 A3.QJ32.QT432.83 QJ52.9.K876.AQJ7 KT94.KT864.A95.2');
    for (var i = 0; i < 4; i++) {
      final deal = manifest.dealAt(i);
      expect(deal.hands.values.expand((hand) => hand).toSet().length, 52);
      for (final seat in Seat.values) {
        expect(deal.hands[seat]!.length, 13);
      }
      expect(manifest.boardAt(i).number, manifest.startBoard + i);
      expect(manifest.boardAt(i).dealer,
          BoardDefinition.forNumber(manifest.startBoard + i).dealer);
      expect(manifest.boardAt(i).vulnerability,
          BoardDefinition.forNumber(manifest.startBoard + i).vulnerability);
      expect(deal.toPbn(),
          DailyPracticeManifest.forDate(_day).dealAt(i).toPbn());
    }
    expect(() => manifest.dealAt(4), throwsRangeError);
    expect(() => DailyPracticeManifest.fromUtcDay('2026-02-30'),
        throwsFormatException);
    expect(() => DailyPracticeManifest.forDate(_day, revision: 2),
        throwsFormatException);
  });

  test('B6 strict progress schema and EW score orientation', () {
    final manifest = DailyPracticeManifest.forDate(_day);
    final p = DailyPracticeProgress.newChallenge(manifest, Seat.east);
    final done = p.withResult(FourBoardResult(
        id: 'daily_history_01', boardNumber: manifest.startBoard,
        contract: '3NT', nsScore: 420));
    expect(done.completed, 1);
    expect(done.humanNetScore, -420);
    expect(DailyPracticeProgress.fromJson(done.toJson()).humanNetScore, -420);
    final forged = Map<String, dynamic>.from(done.toJson());
    forged['challengeId'] = 'fake_day';
    expect(() => DailyPracticeProgress.fromJson(forged), throwsFormatException);
    expect(() => done.withResult(FourBoardResult(
      id: 'daily_history_01', boardNumber: manifest.startBoard,
      contract: 'PASS OUT', nsScore: 0,
    )), throwsFormatException);
  });

  test('B6 completes four boards, persists and keeps older UTC progress', () async {
    final archive = _MemoryArchive();
    final ledger = MemoryDailyPracticeStore();
    final history = MemoryCompletedHistoryStore();
    final first = _session(archive: archive, daily: ledger, history: history);
    await first.startDailyPractice(humanSeat: Seat.north);
    expect(first.dailyPractice!.completed, 0);
    expect(first.boardMode, BoardMode.daily);
    final start = first.dailyPractice!.manifest.startBoard;
    final snapshot = SavedBoardCodec.decode(archive.saved!);
    expect(snapshot.dailyPractice!.challengeId, 'daily_2026-10-16_v1');
    expect(snapshot.state.deal.toPbn(),
        first.dailyPractice!.manifest.dealAt(0).toPbn());
    await _passOut(first);
    expect(first.dailyPractice!.completed, 1);
    final firstId = first.dailyPractice!.results.single.id;
    first.dispose();

    final second = _session(archive: archive, daily: ledger, history: history);
    expect(await second.restoreSavedGame(), true);
    expect(second.dailyPractice!.completed, 1);
    expect(second.dailyPractice!.results.single.id, firstId);
    await second.nextDailyBoard();
    expect(second.board.number, start + 1);
    expect(second.view!.ownCards, isNotEmpty);
    await _passOut(second);
    for (var i = 2; i < 4; i++) {
      await second.nextDailyBoard();
      await _passOut(second);
    }
    expect(second.dailyPractice!.completed, 4);
    expect(second.dailyPractice!.humanNetScore, 0);
    expect((await ledger.read()).single.isComplete, true);
    expect((await history.read()).length, 4);
    final before = second.dailyPractice!.results.map((e) => e.id).toList();
    await second.startDailyPractice(); // same date does NOT overwrite progress
    expect(second.dailyPractice!.results.map((e) => e.id).toList(), before);
    await second.startDailyPractice(utcDate: _day.add(const Duration(days: 1)));
    expect(second.dailyPractice!.completed, 0);
    expect(second.dailyHistory.length, 2);
    expect(second.dailyHistory[1].challengeId, 'daily_2026-10-16_v1');
    second.dispose();
  });

  test('B6 damaged ledger blocks overwrite, failed writes can retry', () async {
    final broken = _session(archive: _MemoryArchive(), daily: _BrokenDailyStore());
    addTearDown(broken.dispose);
    await broken.startDailyPractice();
    expect(broken.started, false);
    expect(broken.dailyError, 'dailyLoadError');

    final safe = MemoryDailyPracticeStore();
    final failing = _FailingWriteDailyStore(safe);
    final session = _session(archive: _MemoryArchive(), daily: failing);
    addTearDown(session.dispose);
    await session.startDailyPractice();
    failing.fail = true;
    await _passOut(session);
    expect(session.dailySaveFailed, true);
    await session.nextDailyBoard();
    expect(session.board.number, session.dailyPractice!.manifest.startBoard);
    failing.fail = false;
    await session.retryDailySave();
    expect(session.dailySaveFailed, false);
    await session.nextDailyBoard();
    expect(session.dailyPractice!.completed, 1);
    expect(session.board.number, session.dailyPractice!.manifest.startBoard + 1);
  });

  test('B6 corrupt restored daily journal blocks advancing after finish', () async {
    final archive = _MemoryArchive();
    final first = _session(
        archive: archive, daily: MemoryDailyPracticeStore());
    await first.startDailyPractice();
    first.dispose();

    final recovered = _session(
        archive: archive, daily: _BrokenDailyStore());
    addTearDown(recovered.dispose);
    expect(await recovered.restoreSavedGame(), true);
    await _passOut(recovered);
    expect(recovered.dailySaveFailed, true);
    expect(recovered.dailyError, 'dailySaveError');
    final number = recovered.board.number;
    await recovered.nextDailyBoard();
    expect(recovered.board.number, number);
  });

  testWidgets('B6 bilingual player controls, next board and summary',
      (tester) async {
    final session = _session(
      archive: _MemoryArchive(),
      daily: MemoryDailyPracticeStore(),
      history: MemoryCompletedHistoryStore(),
    );
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await _tap(tester, 'start_daily_practice');
    expect(find.byKey(const Key('daily_panel')), findsOneWidget);
    expect(find.text('已完成副數: 0 / 4'), findsOneWidget);
    await _tap(tester, 'pass');
    expect(find.byKey(const Key('next_daily_board')), findsOneWidget);
    await _tap(tester, 'next_daily_board');
    for (var i = 2; i <= 4; i++) {
      await _tap(tester, 'pass');
      if (i < 4) await _tap(tester, 'next_daily_board');
    }
    expect(find.byKey(const Key('daily_finished')), findsOneWidget);
    expect(find.byKey(const Key('next_daily_board')), findsNothing);
    await _tap(tester, 'toggle_locale');
    expect(find.textContaining('All four daily boards complete'),
        findsOneWidget);
    await _tap(tester, 'daily_restart');
    expect(find.byKey(const Key('daily_restart_confirm')), findsOneWidget);
    await _tap(tester, 'daily_restart_confirm');
    expect(session.dailyPractice!.completed, 0);
  });
}
