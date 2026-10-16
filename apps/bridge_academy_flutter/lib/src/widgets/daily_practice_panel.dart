import 'package:flutter/material.dart';

import '../app_copy.dart';
import '../daily_practice.dart';

/// B6 public-only summary: receives no Deal, PBN, or private transcript.
class DailyPracticePanel extends StatelessWidget {
  const DailyPracticePanel({
    super.key,
    required this.copy,
    required this.today,
    required this.active,
    required this.history,
    required this.finished,
    required this.canAdvance,
    required this.canRestart,
    required this.onNext,
    required this.onRestart,
  });

  final AppCopy copy;
  final DailyPracticeManifest today;
  final DailyPracticeProgress? active;
  final List<DailyPracticeProgress> history;
  final bool finished;
  final bool canAdvance;
  final bool canRestart;
  final VoidCallback onNext;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final progress = active;
    if (progress == null && history.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      key: const Key('daily_panel'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(copy.t('dailyTitle'),
                style: Theme.of(context).textTheme.titleMedium),
            Text(copy.t('dailyScope')),
            if (progress != null) ...[
              const SizedBox(height: 8),
              Text('${copy.t('dailyDateUtc')}: ${progress.manifest.utcDay}',
                  key: const Key('daily_date')),
              Text('${copy.t('dailyCompleted')}: ${progress.completed} / 4',
                  key: const Key('daily_progress')),
              Text('${copy.t('dailyScore')}: '
                  '${progress.humanNetScore > 0 ? '+' : ''}${progress.humanNetScore}',
                  key: const Key('daily_score')),
              for (final result in progress.results)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${copy.boardNumber(result.boardNumber)} • '
                      '${result.contract}', maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  trailing: Text('${progress.humanSeat.isNS
                      ? result.nsScore : -result.nsScore}'),
                ),
              if (progress.isComplete) ...[
                Text(copy.t('dailyFinished'), key: const Key('daily_finished')),
                if (canRestart && progress.manifest.utcDay == today.utcDay)
                  OutlinedButton.icon(
                    key: const Key('daily_restart'),
                    onPressed: onRestart,
                    icon: const Icon(Icons.restart_alt),
                    label: Text(copy.t('dailyRestart'),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ] else if (finished) ...[
                FilledButton.icon(
                  key: const Key('next_daily_board'),
                  onPressed: canAdvance ? onNext : null,
                  icon: const Icon(Icons.skip_next),
                  label: Text(copy.t('dailyNext'),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ] else
                Text(copy.t('dailyCurrent')),
            ],
            if (history.isNotEmpty) ...[
              const Divider(),
              Text(copy.t('dailyHistory')),
              for (final item in history.take(7))
                Text('${item.manifest.utcDay} • '
                    '${item.completed}/4 • '
                    '${item.humanNetScore > 0 ? '+' : ''}${item.humanNetScore}',
                    key: Key('daily_history_${item.manifest.utcDay}')),
            ],
          ],
        ),
      ),
    );
  }
}
