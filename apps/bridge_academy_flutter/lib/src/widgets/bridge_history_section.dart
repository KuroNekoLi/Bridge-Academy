import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_copy.dart';
import '../bridge_session.dart';
import 'bridge_history_panel.dart';

/// Owns only the local history selection and replay cursor.
/// All history data and mutation remain in BridgeSession.
class BridgeHistorySection extends StatefulWidget {
  const BridgeHistorySection({super.key, required this.session, required this.copy});
  final BridgeSession session;
  final AppCopy copy;

  @override
  State<BridgeHistorySection> createState() => _BridgeHistorySectionState();
}

class _BridgeHistorySectionState extends State<BridgeHistorySection> {
  String? _selectedHistoryId;
  int _historyStep = 0;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final copy = widget.copy;
    return BridgeHistoryPanel(
        history: session.completedHistory,
        copy: copy,
        selectedId: _selectedHistoryId,
        selectedReplay: _selectedHistoryId == null
            ? null
            : session.historyReplay(_selectedHistoryId!),
        replayIndex: _historyStep,
        onSelect: (id) => setState(() {
          _selectedHistoryId = id;
          _historyStep = 0;
        }),
        onReplayStep: (step) => setState(() => _historyStep = step),
        canDelete: !session.busy,
        onExportPbn: (id) async {
          // The panel requires a separate explicit private-hand
          // export confirmation BEFORE calling this callback.
          final pbn = session.exportHistoryPbn(id);
          if (pbn == null) return false;
          await Clipboard.setData(ClipboardData(text: pbn));
          return true;
        },
        onImportPbn: session.importHistoryPbn,
        onAnalyzeDds: session.analyzeHistoryDds,
        onDelete: (id) async {
          final removed = await session.deleteHistory(id);
          if (removed && mounted && _selectedHistoryId == id) {
            setState(() {
              _selectedHistoryId = null;
              _historyStep = 0;
            });
          }
        },
        errorCode: session.historyError,
        onRetrySave: session.historySaveFailed
            ? session.retryHistorySave
            : null,
      );
  }
}
