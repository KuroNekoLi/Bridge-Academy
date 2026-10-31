import 'package:flutter/material.dart';

import 'app_copy.dart';
import 'bridge_session.dart';
import 'widgets/bridge_active_table_content.dart';
import 'widgets/bridge_practice_selection.dart';
import 'widgets/bridge_table_lobby.dart';

/// Coordinates the active board and the practice/history workspace.
/// Only workspace visibility is owned here. Game state remains in BridgeSession;
/// launch preferences, history selection and replay cursors own their own lifetimes.
class BridgeTable extends StatefulWidget {
  const BridgeTable({
    super.key,
    required this.session,
    required this.copy,
    this.historyOnly = false,
  });
  final BridgeSession session;
  final AppCopy copy;
  final bool historyOnly;

  @override
  State<BridgeTable> createState() => _BridgeTableState();
}

class _BridgeTableState extends State<BridgeTable> {
  late BridgePracticeSelection _selection;
  bool _historyOpen = false;

  @override
  void initState() {
    super.initState();
    _selection = BridgePracticeSelection();
    widget.session.addListener(_syncRestoredSelection);
    _syncRestoredSelection();
  }

  void _syncRestoredSelection() => _selection.syncRestored(widget.session);

  @override
  void didUpdateWidget(covariant BridgeTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.session, widget.session)) {
      oldWidget.session.removeListener(_syncRestoredSelection);
      _selection.dispose();
      _selection = BridgePracticeSelection();
      widget.session.addListener(_syncRestoredSelection);
      _syncRestoredSelection();
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_syncRestoredSelection);
    _selection.dispose();
    super.dispose();
  }

  void _toggleHistory() => setState(() => _historyOpen = !_historyOpen);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.session,
    builder: (context, _) {
      if (!widget.historyOnly && widget.session.view != null) {
        return BridgeActiveTableContent(
          session: widget.session,
          copy: widget.copy,
          selection: _selection,
          historyOpen: _historyOpen,
        );
      }
      return BridgeTableLobby(
        session: widget.session,
        copy: widget.copy,
        selection: _selection,
        historyOnly: widget.historyOnly,
        historyOpen: _historyOpen,
        onToggleHistory: _toggleHistory,
      );
    },
  );
}
