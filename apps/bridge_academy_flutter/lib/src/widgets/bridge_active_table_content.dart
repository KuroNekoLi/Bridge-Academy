import 'package:flutter/material.dart';
import '../app_copy.dart';
import '../bridge_session.dart';
import 'bridge_focus_table.dart';
import 'bridge_daily_practice_section.dart';
import 'bridge_completed_sections.dart';
import 'bridge_practice_launcher.dart';
import 'bridge_practice_result_panels.dart';

/// Active board presentation. No local mutable UI state or Bridge Core mutation.
class BridgeActiveTableContent extends StatelessWidget {
  const BridgeActiveTableContent({super.key, required this.session,
    required this.copy, required this.selection, required this.historyOpen});
  final BridgeSession session;
  final AppCopy copy;
  final BridgePracticeSelection selection;
  final bool historyOpen;

  @override
  Widget build(BuildContext context) {
    final view = session.view!;
    return BridgeFocusTable(
            view: view,
            copy: copy,
            boardNumber: session.board.number,
            modeLabel: copy.t(session.mode == OpponentMode.demo
                ? 'demoNotice' : 'liveNotice'),
            actionsPaused: session.actionsPaused ||
                session.saveFailed || session.recoveryNeedsConfirmation ||
                (session.isBiddingPractice && session.biddingPracticeComplete),
            error: session.errorCode == null
                ? (session.recoveryNeedsConfirmation
                    ? copy.t('recoveredOlderCheckpoint') : null)
                : copy.t(session.errorCode!),
            onRetry: session.recoveryNeedsConfirmation ? null
                : session.saveFailed ? session.retrySave
                : session.errorCode != null ? session.retryBots : null,
            onPlayCard: session.submitCard,
            onSubmitCall: session.submitCall,
            sessionActions: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (session.recoveryNeedsConfirmation)
                  FilledButton(
                    key: const Key('ack_recovered_checkpoint'),
                    onPressed: session.acknowledgeRecoveredCheckpoint,
                    child: Text(copy.t('ackRecoveredCheckpoint')),
                  ),
                if (session.dailyPractice != null ||
                    session.dailyHistory.isNotEmpty)
                  BridgeDailyPracticeSection(session: session, copy: copy, selection: selection),
                if (session.fourBoardPractice != null)
                  BridgeFourBoardPanel(session: session, copy: copy),
                if (session.isBiddingPractice)
                  BridgeBiddingPracticePanel(session: session, copy: copy),
                if (session.finished && !session.isBiddingPractice) ...[
                  BridgeFinalResultCard(view: view, copy: copy),
                  BridgeCompletedBoardActions(session: session, copy: copy),
                  if (!historyOpen) BridgeCompletedReplaySection(key: ValueKey(session.completedReplay), session: session, copy: copy),
                ],
              ],
            ),
          );
  }
}
