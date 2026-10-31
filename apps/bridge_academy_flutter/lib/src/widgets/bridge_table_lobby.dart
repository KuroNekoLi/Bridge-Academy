import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../app_copy.dart';
import '../bridge_session.dart';
import 'bridge_table_components.dart';
import 'bridge_table_toolbar.dart';
import 'bridge_bidding_box.dart';
import 'bridge_history_section.dart';
import 'bridge_completed_sections.dart';
import 'bridge_daily_practice_section.dart';
import 'bridge_practice_launcher.dart';
import 'bridge_practice_selection.dart';
import 'bridge_practice_result_panels.dart';

/// Practice and history workspace, including the narrow/legacy table fallback.
/// Receives authoritative player-visible data from BridgeSession only.
class BridgeTableLobby extends StatelessWidget {
  const BridgeTableLobby({super.key, required this.session, required this.copy,
    required this.selection, required this.historyOnly,
    required this.historyOpen, required this.onToggleHistory});
  final BridgeSession session;
  final AppCopy copy;
  final BridgePracticeSelection selection;
  final bool historyOnly;
  final bool historyOpen;
  final VoidCallback onToggleHistory;

  @override
  Widget build(BuildContext context) {
    final view = session.view;
    final trainingContract = session.isJustDeclare ? view?.contract : null;
    final declarerTricks = trainingContract == null || view == null
        ? 0
        : view.completedTricks.where(
            (trick) => trick.winner.isNS == trainingContract.declarer.isNS,
          ).length;
    return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!historyOnly && view == null)
                      BridgePracticeLauncher(session: session, copy: copy, selection: selection, historyOpen: historyOpen, onToggleHistory: onToggleHistory),
                    if (historyOpen || historyOnly) ...[
                      const SizedBox(height: 8),
                      BridgeHistorySection(session: session, copy: copy),
                    ],
                    if (!historyOnly) ...[
                      if (session.dailyPractice != null ||
                          session.dailyHistory.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        BridgeDailyPracticeSection(session: session, copy: copy, selection: selection),
                      ],
                      if (session.dailyError != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(copy.t(session.dailyError!)),
                                if (session.dailySaveFailed)
                                  TextButton(
                                    key: const Key('daily_retry_save'),
                                    onPressed: session.retryDailySave,
                                    child: Text(copy.t('dailyRetrySave')),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      if (session.fourBoardPractice != null) ...[
                        const SizedBox(height: 8),
                        BridgeFourBoardPanel(session: session, copy: copy),
                      ],
                      if (session.isBiddingPractice)
                        BridgeBiddingPracticePanel(session: session, copy: copy),
                      if (session.isJustDeclare) ...[
                        const SizedBox(height: 8),
                        Card(
                          key: const Key('just_declare_active'),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(copy.t('justDeclareActive')),
                                if (trainingContract != null) ...[
                                  Text(
                                    '${copy.t('justDeclareDeclarer')}: '
                                    '${copy.seat(trainingContract.declarer.letter)}',
                                  ),
                                  Text(
                                    '${copy.t('justDeclareDummy')}: '
                                    '${copy.seat(trainingContract.dummy.letter)}',
                                  ),
                                  Text(
                                    copy.justDeclareProgress(
                                      declarerTricks,
                                      trainingContract.targetTricks,
                                    ),
                                    key: const Key('just_declare_goal'),
                                  ),
                                  if (session.finished)
                                    Text(
                                      copy.t(
                                        declarerTricks >=
                                                trainingContract.targetTricks
                                            ? 'justDeclareMade'
                                            : 'justDeclareDown',
                                      ),
                                      key: const Key('just_declare_outcome'),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        copy.t(
                          session.mode == OpponentMode.demo
                              ? 'demoNotice'
                              : 'liveNotice',
                        ),
                      ),
                      if (kIsWeb)
                        Text(
                          copy.t('webCheckpointCaution'),
                          key: const Key('web_checkpoint_caution'),
                        ),
                      if (session.restoring) ...[
                        const LinearProgressIndicator(
                          key: Key('restore_progress'),
                        ),
                        Text(copy.t('restoringGame')),
                      ],
                      if (view == null && session.errorCode != null)
                        Text(
                          copy.t(session.errorCode!),
                          key: const Key('error_message'),
                        ),
                      if (view == null) ...[
                        const SizedBox(height: 24),
                        Text(
                          copy.t('notStarted'),
                          key: const Key('empty_state'),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        BridgeBoardHeader(
                          boardNumber: session.board.number,
                          view: view,
                          busy: session.busy,
                          copy: copy,
                        ),
                        if (session.restoredFromStorage)
                          Text(
                            copy.t('restoredGame'),
                            key: const Key('restored_game'),
                          ),
                        if (session.recoveryNeedsConfirmation)
                          Card(
                            key: const Key('recovery_warning'),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(copy.t('recoveredOlderCheckpoint')),
                                  const SizedBox(height: 8),
                                  FilledButton(
                                    key: const Key('ack_recovered_checkpoint'),
                                    onPressed:
                                        session.acknowledgeRecoveredCheckpoint,
                                    child: Text(
                                      copy.t('ackRecoveredCheckpoint'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (session.errorCode != null) ...[
                          const SizedBox(height: 8),
                          Card(
                            color: Theme.of(context).colorScheme.errorContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Wrap(
                                spacing: 12,
                                children: [
                                  Text(
                                    copy.t(session.errorCode!),
                                    key: const Key('error_message'),
                                  ),
                                  if (session.saveFailed && !session.busy)
                                    TextButton(
                                      key: const Key('retry_save'),
                                      onPressed: session.retrySave,
                                      child: Text(copy.t('retrySave')),
                                    ),
                                  if (!session.saveFailed &&
                                      !session.busy &&
                                      !view.canAct &&
                                      !session.finished)
                                    TextButton(
                                      key: const Key('retry_bot'),
                                      onPressed: session.retryBots,
                                      child: Text(copy.t('retry')),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (session.busy) ...[
                          const LinearProgressIndicator(
                            key: Key('bot_progress'),
                          ),
                          const SizedBox(height: 8),
                          Text(copy.t('waitingBot')),
                        ],
                        const SizedBox(height: 12),
                        BridgeTableSurface(
                          view: view,
                          copy: copy,
                          actionsPaused:
                              session.actionsPaused ||
                              (session.isBiddingPractice &&
                                  session.biddingPracticeComplete),
                          onPlayCard: session.submitCard,
                        ),
                        const SizedBox(height: 8),
                        BridgeTableToolbar(view: view, copy: copy),
                        const SizedBox(height: 8),
                        if (!session.finished)
                          BridgeHumanControls(view: view, session: session, copy: copy)
                        else ...[
                          if (!session.isBiddingPractice)
                            BridgeFinalResultCard(view: view, copy: copy),
                          const SizedBox(height: 8),
                          if (!session.isBiddingPractice)
                            BridgeCompletedBoardActions(session: session, copy: copy),
                          const SizedBox(height: 8),
                          if (!historyOpen && !session.isBiddingPractice)
                            BridgeCompletedReplaySection(key: ValueKey(session.completedReplay), session: session, copy: copy),
                        ],
                      ],
                      if (view != null) ...[
                        const SizedBox(height: 24),
                        BridgePracticeLauncher(session: session, copy: copy, selection: selection, historyOpen: historyOpen, onToggleHistory: onToggleHistory),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
  }
}

/// Player-visible auction and play controls for the legacy layout.
class BridgeHumanControls extends StatelessWidget {
  const BridgeHumanControls({super.key, required this.view,
    required this.session, required this.copy});
  final PlayerView view;
  final BridgeSession session;
  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    if (view.phase == Phase.auction) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BridgePlayerHand(
            view: view,
            copy: copy,
            actionsPaused: true,
            onPlayCard: session.submitCard,
          ),
          BridgeBiddingBox(
            copy: copy,
            view: view,
            canSubmit: view.canAct && !session.actionsPaused,
            onSubmitCall: session.submitCall,
          ),
        ],
      );
    }
    if (view.phase == Phase.play && !session.isBiddingPractice) {
      return BridgePlayerHand(
        view: view,
        copy: copy,
        actionsPaused: session.actionsPaused,
        onPlayCard: session.submitCard,
      );
    }
    return const SizedBox.shrink();
  }
}
