import 'dart:math' as math;

import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:flutter/material.dart';

import '../app_copy.dart';
import '../completed_history_store.dart';
import 'bridge_replay_panel.dart';

enum HistoryFilter { all, contracts, passOut, practice }

/// Player-facing history contains only authorized summaries and replay frames.
class BridgeHistoryPanel extends StatefulWidget {
  const BridgeHistoryPanel({
    super.key,
    required this.history,
    required this.copy,
    required this.selectedId,
    required this.selectedReplay,
    required this.replayIndex,
    required this.onSelect,
    required this.onReplayStep,
    required this.onDelete,
    this.onExportPbn,
    required this.errorCode,
    required this.onRetrySave,
    this.canDelete = true,
  });

  final List<HistorySummary> history;
  final AppCopy copy;
  final String? selectedId;
  final CompletedReplay? selectedReplay;
  final int replayIndex;
  final ValueChanged<String> onSelect;
  final ValueChanged<int> onReplayStep;
  final Future<void> Function(String) onDelete;
  /// Called only after the player approves sharing ALL four hands.
  final Future<bool> Function(String)? onExportPbn;
  final String? errorCode;
  final VoidCallback? onRetrySave;
  final bool canDelete;

  @override
  State<BridgeHistoryPanel> createState() => _BridgeHistoryPanelState();
}

class _BridgeHistoryPanelState extends State<BridgeHistoryPanel> {
  static const _pageSize = 5;
  String _query = '';
  HistoryFilter _filter = HistoryFilter.all;
  int _page = 0;

  List<HistorySummary> get _matching {
    final query = _query.trim().toLowerCase();
    return widget.history.where((item) {
      final allowed = switch (_filter) {
        HistoryFilter.all => true,
        HistoryFilter.contracts => item.contract != 'PASS OUT',
        HistoryFilter.passOut => item.contract == 'PASS OUT',
        HistoryFilter.practice => item.isPractice,
      };
      if (!allowed) return false;
      if (query.isEmpty) return true;
      final search = [
        item.boardNumber.toString(),
        item.contract,
        item.score.toString(),
        item.humanSeat.letter,
      ].join(' ').toLowerCase();
      return search.contains(query);
    }).toList();
  }

  Future<void> _confirmDelete(HistorySummary record) async {
    final copy = widget.copy;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(copy.t('historyDeleteTitle')),
        content: Text(copy.t('historyDeleteWarning')),
        actions: [
          TextButton(
            key: const Key('history_delete_cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(copy.t('historyDeleteCancel')),
          ),
          FilledButton(
            key: const Key('history_delete_confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(copy.t('historyDeleteConfirm')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await widget.onDelete(record.id);
    }
  }

  Future<void> _confirmExport(HistorySummary record) async {
    final copy = widget.copy;
    final export = widget.onExportPbn;
    if (export == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(copy.t('historyExportTitle')),
        content: Text(copy.t('historyExportWarning')),
        actions: [
          TextButton(
            key: const Key('history_export_cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(copy.t('historyExportCancel')),
          ),
          FilledButton(
            key: const Key('history_export_confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(copy.t('historyExportConfirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    var successful = false;
    try {
      successful = await export(record.id);
    } catch (_) {
      // Clipboard failures and private deal data must not be logged.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(copy.t(successful
          ? 'historyExportSuccess' : 'historyExportFailure'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = widget.copy;
    final matching = _matching;
    final pages = math.max(1, (matching.length + _pageSize - 1) ~/ _pageSize);
    final page = _page.clamp(0, pages - 1);
    final visible = matching.skip(page * _pageSize).take(_pageSize);

    return Card(
      key: const Key('history_panel'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(copy.t('historyTitle'),
                style: Theme.of(context).textTheme.titleMedium),
            if (widget.errorCode != null) ...[
              Text(copy.t(widget.errorCode!),
                  key: const Key('history_error')),
              if (widget.onRetrySave != null)
                TextButton(
                  key: const Key('history_retry_save'),
                  onPressed: widget.onRetrySave,
                  child: Text(copy.t('historyRetry')),
                ),
            ],
            const SizedBox(height: 8),
            TextField(
              key: const Key('history_search'),
              decoration: InputDecoration(
                labelText: copy.t('historySearch'),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() {
                _query = value;
                _page = 0;
              }),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<HistoryFilter>(
              key: const Key('history_filter'),
              initialValue: _filter,
              decoration: InputDecoration(
                labelText: copy.t('historyFilter'),
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final filter in HistoryFilter.values)
                  DropdownMenuItem(
                    value: filter,
                    child: Text(copy.t(switch (filter) {
                      HistoryFilter.all => 'historyFilterAll',
                      HistoryFilter.contracts => 'historyFilterContracts',
                      HistoryFilter.passOut => 'historyFilterPassOut',
                      HistoryFilter.practice => 'historyFilterPractice',
                    })),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _filter = value;
                    _page = 0;
                  });
                }
              },
            ),
            if (widget.history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(copy.t('historyEmpty'),
                    key: const Key('history_empty')),
              )
            else if (matching.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(copy.t('historyNoResults'),
                    key: const Key('history_no_results')),
              ),
            for (final record in visible)
              ListTile(
                key: Key('history_item_${record.id}'),
                selected: widget.selectedId == record.id,
                leading: const Icon(Icons.history),
                title: Text('${copy.boardNumber(record.boardNumber)} · '
                    '${record.contract == 'PASS OUT' ? copy.t('historyPassOut') : record.contract}'),
                subtitle: Text(
                  '${copy.score(record.score)} · '
                  '${copy.seat(record.humanSeat.letter)} · '
                  '${record.savedAt.toLocal().toString().substring(0, 16)}'
                  '${record.isPractice ? ' · ${copy.t('historyPractice')}' : ''}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onExportPbn != null)
                      IconButton(
                        key: Key('history_export_${record.id}'),
                        tooltip: copy.t('historyExportTitle'),
                        icon: const Icon(Icons.ios_share),
                        onPressed: () => _confirmExport(record),
                      ),
                    IconButton(
                  key: Key('history_delete_${record.id}'),
                  tooltip: copy.t('historyDeleteTitle'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: widget.canDelete
                      ? () => _confirmDelete(record) : null,
                    ),
                  ],
                ),
                onTap: () => widget.onSelect(record.id),
              ),
            if (matching.length > _pageSize)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    key: const Key('history_page_previous'),
                    tooltip: copy.t('historyPagePrevious'),
                    onPressed: page == 0
                        ? null : () => setState(() => _page = page - 1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(copy.historyPage(page + 1, pages),
                      key: const Key('history_page_progress')),
                  IconButton(
                    key: const Key('history_page_next'),
                    tooltip: copy.t('historyPageNext'),
                    onPressed: page == pages - 1
                        ? null : () => setState(() => _page = page + 1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            if (widget.selectedReplay != null) ...[
              const Divider(),
              Text(copy.t('historyReplayTitle'),
                  style: Theme.of(context).textTheme.titleSmall),
              BridgeCompletedReplayPanel(
                replay: widget.selectedReplay!,
                index: widget.replayIndex.clamp(
                    0, widget.selectedReplay!.lastIndex),
                copy: copy,
                onSelectIndex: widget.onReplayStep,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
