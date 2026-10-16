import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';

import '../app_copy.dart';
import '../completed_history_store.dart';
import 'bridge_replay_panel.dart';

/// A5 list shows summaries and a selected filtered replay, never full Deal.
class BridgeHistoryPanel extends StatelessWidget {
  const BridgeHistoryPanel({
    super.key,
    required this.history,
    required this.copy,
    required this.selectedId,
    required this.selectedReplay,
    required this.replayIndex,
    required this.onSelect,
    required this.onReplayStep,
    required this.errorCode,
    required this.onRetrySave,
  });

  final List<HistorySummary> history;
  final AppCopy copy;
  final String? selectedId;
  final CompletedReplay? selectedReplay;
  final int replayIndex;
  final ValueChanged<String> onSelect;
  final ValueChanged<int> onReplayStep;
  final String? errorCode;
  final VoidCallback? onRetrySave;

  @override
  Widget build(BuildContext context) => Card(
        key: const Key('history_panel'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(copy.t('historyTitle'),
                  style: Theme.of(context).textTheme.titleMedium),
              if (errorCode != null) ...[
                Text(copy.t(errorCode!), key: const Key('history_error')),
                if (onRetrySave != null)
                  TextButton(
                    key: const Key('history_retry_save'),
                    onPressed: onRetrySave,
                    child: Text(copy.t('historyRetry')),
                  ),
              ],
              if (history.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(copy.t('historyEmpty'),
                      key: const Key('history_empty')),
                ),
              for (final record in history)
                ListTile(
                  key: Key('history_item_${record.id}'),
                  selected: selectedId == record.id,
                  leading: const Icon(Icons.history),
                  title: Text('${copy.boardNumber(record.boardNumber)} · '
                      '${record.contract == 'PASS OUT' ? copy.t('historyPassOut') : record.contract}'),
                  subtitle: Text(
                    '${copy.score(record.score)} · '
                    '${copy.seat(record.humanSeat.letter)} · '
                    '${record.savedAt.toLocal().toString().substring(0, 16)}'
                    '${record.isPractice ? ' · ' + copy.t('historyPractice') : ''}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onSelect(record.id),
                ),
              if (selectedReplay != null) ...[
                const Divider(),
                Text(copy.t('historyReplayTitle'),
                    style: Theme.of(context).textTheme.titleSmall),
                BridgeCompletedReplayPanel(
                  replay: selectedReplay!,
                  index: replayIndex.clamp(0, selectedReplay!.lastIndex),
                  copy: copy,
                  onSelectIndex: onReplayStep,
                ),
              ],
            ],
          ),
        ),
      );
}
