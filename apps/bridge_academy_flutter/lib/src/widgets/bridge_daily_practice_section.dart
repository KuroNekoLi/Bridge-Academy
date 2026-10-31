import 'package:flutter/material.dart';

import '../app_copy.dart';
import '../bridge_session.dart';
import 'bridge_practice_launcher.dart';
import 'daily_practice_panel.dart';

/// Presents a daily practice summary and owns its restart confirmation flow.
class BridgeDailyPracticeSection extends StatelessWidget {
  const BridgeDailyPracticeSection({super.key, required this.session,
    required this.copy, required this.selection});
  final BridgeSession session;
  final AppCopy copy;
  final BridgePracticeSelection selection;

  @override
  Widget build(BuildContext context) => DailyPracticePanel(
    copy: copy,
    today: session.todaysDaily,
    active: session.dailyPractice,
    history: session.dailyHistory,
    finished: session.finished,
    canAdvance: !session.busy && !session.saveFailed &&
        !session.dailySaveFailed && !session.historySaveFailed,
    canRestart: !session.busy && !session.saveFailed &&
        !session.dailySaveFailed,
    onNext: () { session.nextDailyBoard(); },
    onRestart: () => _confirmRestart(context),
  );

  Future<void> _confirmRestart(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(copy.t('dailyRestartTitle')),
        content: Text(copy.t('dailyRestartWarning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(copy.t('dailyRestartCancel')),
          ),
          FilledButton(
            key: const Key('daily_restart_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(copy.t('dailyRestartConfirm')),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await session.startDailyPractice(
        humanSeat: session.dailyPractice?.humanSeat ?? selection.seat,
        restart: true,
      );
    }
  }
}
