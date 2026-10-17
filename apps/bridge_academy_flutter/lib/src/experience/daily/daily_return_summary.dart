import '../../daily_practice.dart';

/// UI-only projection of existing encrypted B6 public progress; no full Deal.
enum DailyReturnState {
  notStarted, readyToResume, playing, betweenBoards, completed,
  previousDay, otherSession, recoveryPending, storageProblem, waiting,
}

final class DailyReturnSummary {
  const DailyReturnSummary({
    required this.today,
    required this.todayProgress,
    required this.previous,
    required this.recent,
    required this.state,
    required this.canStart,
    required this.canContinue,
    required this.canNext,
    required this.canRestart,
    required this.canPracticeBidding,
  });

  factory DailyReturnSummary.from({
    required DateTime now,
    required DailyPracticeProgress? active,
    required List<DailyPracticeProgress> history,
    required bool started,
    required bool finished,
    required bool isDaily,
    required bool hasOtherFourBoard,
    required bool busy,
    required bool saveFailed,
    required bool dailySaveFailed,
    required bool historySaveFailed,
    required bool recoveryNeeded,
    required bool dailyError,
  }) {
    final today = DailyPracticeManifest.forDate(now);
    DailyPracticeProgress? stored;
    for (final entry in history) {
      if (entry.challengeId == today.challengeId) {
        stored = entry;
        break;
      }
    }
    final progress = active?.challengeId == today.challengeId
        ? active : stored;
    final previous = active != null && active.challengeId != today.challengeId
        && !active.isComplete ? active : null;
    final byDate = <String, DailyPracticeProgress>{
      for (final entry in history) entry.manifest.utcDay: entry,
    };
    if (active != null) {
      byDate[active.manifest.utcDay] = active;
    }
    final dates = byDate.keys.toList()..sort((a,b) => b.compareTo(a));
    final recent = List<DailyPracticeProgress>.unmodifiable(
      dates.take(3).map((day) => byDate[day]!),
    );
    final errors = saveFailed || dailySaveFailed ||
        historySaveFailed || dailyError;
    late final DailyReturnState state;
    if (recoveryNeeded) {
      state = DailyReturnState.recoveryPending;
    } else if (errors) {
      state = DailyReturnState.storageProblem;
    } else if (busy) {
      state = DailyReturnState.waiting;
    } else if (previous != null) {
      state = DailyReturnState.previousDay;
    } else if ((started && !finished && !isDaily) || hasOtherFourBoard) {
      state = DailyReturnState.otherSession;
    } else if (progress?.isComplete ?? false) {
      state = DailyReturnState.completed;
    } else if (started && isDaily && !finished) {
      state = DailyReturnState.playing;
    } else if (started && isDaily && finished &&
        progress != null && progress.completed > 0) {
      state = DailyReturnState.betweenBoards;
    } else if (progress != null) {
      state = DailyReturnState.readyToResume;
    } else {
      state = DailyReturnState.notStarted;
    }
    final safe = !busy && !errors && !recoveryNeeded;
    return DailyReturnSummary(
      today: today,
      todayProgress: progress,
      previous: previous,
      recent: recent,
      state: state,
      canStart: safe && (state == DailyReturnState.notStarted ||
          state == DailyReturnState.readyToResume),
      canContinue: safe && (state == DailyReturnState.playing ||
          (state == DailyReturnState.previousDay &&
              started && isDaily && !finished)),
      canNext: safe && (state == DailyReturnState.betweenBoards ||
          (state == DailyReturnState.previousDay && started && isDaily &&
              finished && previous != null && previous.completed > 0)),
      canRestart: safe && state == DailyReturnState.completed &&
          !(started && !finished),
      canPracticeBidding: safe && state == DailyReturnState.completed &&
          !(started && !finished) && !hasOtherFourBoard,
    );
  }

  final DailyPracticeManifest today;
  final DailyPracticeProgress? todayProgress;
  final DailyPracticeProgress? previous;
  final List<DailyPracticeProgress> recent;
  final DailyReturnState state;
  final bool canStart, canContinue, canNext, canRestart, canPracticeBidding;
  int get completed => todayProgress?.completed ?? 0;
  String get stateCopyKey => switch (state) {
    DailyReturnState.notStarted => 'uxDailyEmpty',
    DailyReturnState.readyToResume => 'uxDailyReady',
    DailyReturnState.playing => 'uxDailyPlaying',
    DailyReturnState.betweenBoards => 'uxDailyBetween',
    DailyReturnState.completed => 'uxDailyDone',
    DailyReturnState.previousDay => 'uxDailyPrevious',
    DailyReturnState.otherSession => 'uxDailyBlocked',
    DailyReturnState.recoveryPending => 'uxDailyRecovery',
    DailyReturnState.storageProblem => 'uxDailyStorage',
    DailyReturnState.waiting => 'uxDailyWaiting',
  };
}
