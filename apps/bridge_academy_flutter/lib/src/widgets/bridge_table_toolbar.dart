import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:flutter/material.dart';

import '../app_copy.dart';
import 'bridge_table_components.dart';
import 'bridge_auction_grid.dart';

/// Compact entry points to *public* auction and completed-trick history.
/// The live session and private Deal never reach these dialogs.
class BridgeTableToolbar extends StatelessWidget {
  const BridgeTableToolbar({
    super.key,
    required this.view,
    required this.copy,
  });

  final PlayerView view;
  final AppCopy copy;

  void _showAuction(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('auction_history_dialog'),
        title: Text(copy.t('auction')),
        content: SizedBox(width: 440, child: BridgeAuctionGrid(view: view, copy: copy)),
        actions: [
          TextButton(
            key: const Key('close_history'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(copy.t('close')),
          ),
        ],
      ),
    );
  }

  void _showLastTrick(BuildContext context) {
    if (view.completedTricks.isEmpty) return;
    final trick = view.completedTricks.last;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('last_trick_dialog'),
        title: Text(copy.t('lastTrick')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final play in trick.plays)
                Text(
                  '${copy.seat(play.handOwner.letter)}: '
                  '${bridgeCardText(play.card)}',
                ),
              const SizedBox(height: 8),
              Text(copy.replayWinner(trick.winner.letter)),
            ],
          ),
        ),
        actions: [
          TextButton(
            key: const Key('close_last_trick'),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(copy.t('close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Card(
        key: const Key('table_toolbar'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                key: const Key('auction_history_action'),
                onPressed: () => _showAuction(context),
                icon: const Icon(Icons.format_list_numbered),
                label: Text(copy.t('auction')),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                key: const Key('last_trick_action'),
                onPressed: view.completedTricks.isNotEmpty
                    ? () => _showLastTrick(context)
                    : null,
                icon: const Icon(Icons.history),
                label: Text(copy.t('lastTrick')),
              ),
            ],
          ),
        ),
      );
}
