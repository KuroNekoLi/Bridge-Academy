import 'package:flutter/material.dart';
import '../app_copy.dart';
import '../experience/daily/daily_return_summary.dart';

/// Public B6 status only: no deals, PBN or learner attempt details.
class UxDailyReturnPanel extends StatelessWidget {
  const UxDailyReturnPanel({
    super.key,
    required this.copy,
    required this.summary,
    required this.onStart,
    required this.onContinue,
    required this.onNext,
    this.showNextAction = true,
    required this.onRestart,
    required this.onPracticeBidding,
  });

  final AppCopy copy;
  final DailyReturnSummary summary;
  /// UX-02 owns terminal Next; hide this button to prevent duplicate actions.
  final bool showNextAction;
  final VoidCallback onStart, onContinue, onNext, onRestart, onPracticeBidding;

  @override
  Widget build(BuildContext context) {
    final progress = summary.completed;
    return Card(
      key: const Key('ux_daily_return_panel'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(copy.t('uxDailyTitle'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${copy.t('dailyDateUtc')}: ${summary.today.utcDay}',
                key: const Key('ux_daily_utc_day')),
            Text(copy.t('uxDailyNotRanked')),
            const SizedBox(height: 8),
            Semantics(
              label: '${copy.t('dailyCompleted')}: $progress / 4',
              child: LinearProgressIndicator(
                key: const Key('ux_daily_progress_bar'),
                value: progress / 4,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text('${copy.t('uxDailyProgressLabel')}: $progress / 4',
                key: const Key('ux_daily_completed')),
            Text(copy.t(summary.stateCopyKey),
                key: const Key('ux_daily_state')),
            if (summary.previous != null)
              Text('${copy.t('uxDailyPreviousDay')}: '
                  '${summary.previous!.manifest.utcDay}',
                  key: const Key('ux_daily_previous_day')),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (summary.canStart)
                  FilledButton.icon(
                    key: const Key('ux_daily_start_or_resume'),
                    onPressed: onStart,
                    icon: Icon(summary.state == DailyReturnState.notStarted
                        ? Icons.play_arrow : Icons.restore),
                    label: Text(copy.t(summary.state == DailyReturnState.notStarted
                        ? 'uxDailyBegin' : 'uxDailyRestore')),
                  ),
                if (summary.canContinue)
                  FilledButton.icon(
                    key: const Key('ux_daily_continue'),
                    onPressed: onContinue,
                    icon: const Icon(Icons.play_circle),
                    label: Text(copy.t('uxDailyContinue')),
                  ),
                if (summary.canNext && showNextAction)
                  FilledButton.icon(
                    key: const Key('ux_daily_next'),
                    onPressed: onNext,
                    icon: const Icon(Icons.skip_next),
                    label: Text(copy.t('dailyNext')),
                  ),
                if (summary.canRestart)
                  OutlinedButton.icon(
                    key: const Key('ux_daily_restart'),
                    onPressed: onRestart,
                    icon: const Icon(Icons.restart_alt),
                    label: Text(copy.t('dailyRestart')),
                  ),
                if (summary.canPracticeBidding)
                  OutlinedButton.icon(
                    key: const Key('ux_daily_bidding'),
                    onPressed: onPracticeBidding,
                    icon: const Icon(Icons.school),
                    label: Text(copy.t('uxDailyBidding')),
                  ),
              ],
            ),
            if (summary.recent.isNotEmpty) ...[
              const Divider(),
              Text(copy.t('uxDailyRecent'),
                  style: Theme.of(context).textTheme.labelLarge),
              for (final entry in summary.recent)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${entry.manifest.utcDay} (UTC) · ${entry.completed}/4',
                    key: Key('ux_daily_recent_${entry.manifest.utcDay}'),
                  ),
                ),
            ] else
              Text(copy.t('uxDailyNoHistory'),
                  key: const Key('ux_daily_empty_history')),
          ],
        ),
      ),
    );
  }
}
