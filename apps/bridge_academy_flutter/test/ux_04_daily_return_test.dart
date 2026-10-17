import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/daily_practice.dart';
import 'package:bridge_academy_flutter/src/daily_practice_store.dart';
import 'package:bridge_academy_flutter/src/experience/daily/daily_return_summary.dart';
import 'package:bridge_academy_flutter/src/four_board_practice.dart';
import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final today = DateTime.utc(2026, 10, 17, 8);
final yesterday = DateTime.utc(2026, 10, 16, 8);

DailyPracticeProgress record(DateTime day, int count) {
  final manifest = DailyPracticeManifest.forDate(day);
  var p = DailyPracticeProgress.newChallenge(manifest, Seat.north);
  for (var i = 0; i < count; i++) {
    p = p.withResult(FourBoardResult(
      id: 'record_${day.day}_$i',
      boardNumber: manifest.startBoard + i,
      contract: 'PASS OUT',
      nsScore: 0,
    ));
  }
  return p;
}

DailyReturnSummary summary({
  DailyPracticeProgress? active,
  List<DailyPracticeProgress> history = const [],
  DateTime? clock,
  bool started = false,
  bool finished = false,
  bool isDaily = false,
  bool fourBoard = false,
  bool busy = false,
  bool dailySaveFailed = false,
  bool recovery = false,
  bool dailyError = false,
}) => DailyReturnSummary.from(
  now: clock ?? today,
  active: active,
  history: history,
  started: started,
  finished: finished,
  isDaily: isDaily,
  hasOtherFourBoard: fourBoard,
  busy: busy,
  dailySaveFailed: dailySaveFailed,
  saveFailed: false,
  historySaveFailed: false,
  recoveryNeeded: recovery,
  dailyError: dailyError,
);

class PassBot implements BotPolicy {
  @override
  Future<GameAction> choose(PlayerView view) async =>
      CallAction(view.viewer, const Pass());
}
class Archive implements SessionArchiveStore {
  String? data;
  @override
  Future<String?> read() async => data;
  @override
  Future<void> write(String value) async { data = value; }
  @override
  Future<void> clear() async { data = null; }
}
class BrokenDailyStore implements DailyPracticeStore {
  @override
  Future<List<DailyPracticeProgress>> read() async =>
      throw const FormatException('Damaged ciphertext');
  @override
  Future<void> write(List<DailyPracticeProgress> entries) async =>
      throw StateError('Read-only store');
}

Future<void> tapVisible(WidgetTester tester, String id) async {
  final target = find.byKey(Key(id));
  // The result card can be below the lazy ListView cache.
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(target, 170,
        scrollable: find.byType(Scrollable).last, maxScrolls: 35);
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  test('empty, 1/4, 4/4 are safe public-only projections', () {
    final empty = summary();
    expect(empty.state, DailyReturnState.notStarted);
    expect(empty.canStart, true);
    expect(empty.completed, 0);
    expect(empty.recent, isEmpty);
    final one = record(today, 1);
    final between = summary(
        active: one, history: [one],
        started: true, finished: true, isDaily: true);
    expect(between.state, DailyReturnState.betweenBoards);
    expect(between.canNext, true);
    expect(between.completed, 1);
    final done = record(today, 4);
    final completed = summary(active: done, history: [one, done]);
    expect(completed.state, DailyReturnState.completed);
    expect(completed.canRestart, true);
    expect(completed.canStart, false);
    expect(completed.recent.single.completed, 4);
  });

  test('saved today resumes; old challenge stays separate across UTC midnight', () {
    final old = record(yesterday, 2);
    final partial = record(today, 1);
    expect(summary(history: [partial]).state,
        DailyReturnState.readyToResume);
    final stale = summary(active: old, history: [old],
        started: true, finished: true, isDaily: true);
    expect(stale.state, DailyReturnState.previousDay);
    expect(stale.canStart, false);
    expect(stale.canNext, true);
    expect(stale.previous!.manifest.utcDay, '2026-10-16');
    expect(summary(history: [old]).state, DailyReturnState.notStarted);
    expect(summary(clock: DateTime.parse('2026-10-17T01:30:00+03:00'))
        .today.utcDay, '2026-10-16');
  });

  test('other activity, recovery and local-store failure never overwrite', () {
    final one = record(today, 1);
    expect(summary(history: [one], started: true,
        finished: false).state, DailyReturnState.otherSession);
    expect(summary(history: [one], started: true,
        fourBoard: true).canStart, false);
    expect(summary(active: one, recovery: true).state,
        DailyReturnState.recoveryPending);
    expect(summary(active: one, dailySaveFailed: true).state,
        DailyReturnState.storageProblem);
    expect(summary(active: one, dailyError: true).canStart, false);
    expect(summary(active: one, busy: true).state,
        DailyReturnState.waiting);
  });

  testWidgets('real UX-04 action starts today, advances and switches language',
      (tester) async {
    final archive = Archive();
    final ledger = MemoryDailyPracticeStore();
    final session = BridgeSession(
      archiveStore: archive,
      dailyStore: ledger,
      utcNow: () => today,
      botFactory: (_) => PassBot(),
    );
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    expect(find.byKey(const Key('ux_daily_return_panel')), findsOneWidget);
    expect(find.byKey(const Key('ux_daily_empty_history')), findsOneWidget);
    await tapVisible(tester, 'ux_daily_start_or_resume');
    expect(session.isDailyPractice, true);
    expect(session.dailyPractice!.completed, 0);
    await tapVisible(tester, 'pass');
    expect(session.dailyPractice!.completed, 1);
    expect(find.byKey(const Key('ux_daily_next')), findsNothing);
    expect(find.byKey(const Key('next_daily_board')), findsOneWidget);
    await tapVisible(tester, 'next_daily_board');
    expect(session.board.number, session.dailyPractice!.manifest.startBoard + 1);
    expect(session.view!.phase, Phase.auction);
    await tapVisible(tester, 'toggle_locale');
    expect(find.textContaining('not a ranked event'), findsOneWidget);
    expect(find.byKey(const Key('ux_daily_continue')), findsOneWidget);
    expect((await ledger.read()).single.completed, 1);
  });

  testWidgets('failed daily ledger blocks new start instead of overwriting',
      (tester) async {
    final session = BridgeSession(
      dailyStore: BrokenDailyStore(),
      utcNow: () => today,
    );
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tapVisible(tester, 'ux_daily_start_or_resume');
    expect(session.started, false);
    expect(find.byKey(const Key('ux_daily_start_or_resume')), findsNothing);
    expect(find.byKey(const Key('ux_daily_state')), findsOneWidget);
  });
}
