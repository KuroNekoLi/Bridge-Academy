import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:flutter/material.dart';

import '../app_copy.dart';
import '../bridge_session.dart';
import 'bridge_practice_hub.dart';
import 'bridge_practice_selection.dart';
import 'bridge_practice_options.dart';

/// Builds practice launch controls without owning the session or current board.
class BridgePracticeLauncher extends StatelessWidget {
  const BridgePracticeLauncher({super.key, required this.session, required this.copy,
    required this.selection, required this.historyOpen, required this.onToggleHistory});
  final BridgeSession session;
  final AppCopy copy;
  final BridgePracticeSelection selection;
  final bool historyOpen;
  final VoidCallback onToggleHistory;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: selection,
    builder: (context, _) => _practiceHub(context, session, copy),
  );

  Widget _practiceHub(BuildContext context, BridgeSession session, AppCopy copy) => BridgePracticeHub(
    copy: copy,
    started: session.started,
    settings: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.t('hubSettings'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            BridgePracticeSettings(copy: copy, selection: selection),
          ],
        ),
      ),
    ),
    actions: [
      BridgePracticeAction(
        copy.t('hubFreeTitle'),
        copy.t('hubFreeDescription'),
        Icons.style_outlined,
        FilledButton.icon(
          key: const Key('new_game'),
          onPressed:
              session.busy ||
                  (session.dailyPractice != null &&
                      !session.dailyPractice!.isComplete) ||
                  (session.fourBoardPractice != null &&
                      !session.fourBoardPractice!.isComplete)
              ? null
              : () => _startFreePlay(context, session, copy),
          icon: const Icon(Icons.refresh),
          label: Text(session.started ? copy.t('restart') : copy.t('newGame')),
        ),
      ),
      BridgePracticeAction(
        copy.t('hubFourTitle'),
        copy.t('hubFourDescription'),
        Icons.view_module_outlined,
        FilledButton.tonalIcon(
          key: const Key('start_four_board'),
          onPressed:
              session.busy ||
                  session.saveFailed ||
                  (session.started &&
                      !session.finished &&
                      !session.biddingPracticeComplete) ||
                  (session.dailyPractice != null &&
                      !session.dailyPractice!.isComplete) ||
                  (session.fourBoardPractice != null &&
                      !session.fourBoardPractice!.isComplete)
              ? null
              : () {
                  selection.setBoard(BoardMode.fresh);
                  session.startFourBoardPractice(
                    humanSeat: selection.seat,
                    mode: selection.mode,
                  );
                },
          icon: const Icon(Icons.view_module),
          label: Text(copy.t('practiceFourStart')),
        ),
      ),
      BridgePracticeAction(
        copy.t('hubDeclareTitle'),
        copy.t('hubDeclareDescription'),
        Icons.school_outlined,
        BridgeJustDeclareLauncher(session: session, copy: copy, selection: selection),
      ),
      BridgePracticeAction(
        copy.t('hubDailyTitle'),
        copy.t('hubDailyDescription'),
        Icons.today,
        FilledButton.tonalIcon(
          key: const Key('start_daily_practice'),
          onPressed:
              session.busy ||
                  session.saveFailed ||
                  session.dailySaveFailed ||
                  (session.started &&
                      !session.finished &&
                      !session.biddingPracticeComplete) ||
                  (session.dailyPractice != null &&
                      !session.dailyPractice!.isComplete) ||
                  (session.fourBoardPractice != null &&
                      !session.fourBoardPractice!.isComplete)
              ? null
              : () {
                  selection.setMode(OpponentMode.demo);
                   selection.setBoard(BoardMode.fresh);
                  session.startDailyPractice(humanSeat: selection.seat);
                },
          icon: const Icon(Icons.today),
          label: Text(
            copy.t('dailyStart'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      BridgePracticeAction(
        copy.t('hubBidTitle'),
        copy.t('hubBidDescription'),
        Icons.record_voice_over,
        FilledButton.tonalIcon(
          key: const Key('start_bidding_practice'),
          onPressed:
              session.busy ||
                  session.saveFailed ||
                  (session.started &&
                      !session.finished &&
                      !session.biddingPracticeComplete) ||
                  (session.dailyPractice != null &&
                      !session.dailyPractice!.isComplete) ||
                  (session.fourBoardPractice != null &&
                      !session.fourBoardPractice!.isComplete)
              ? null
              : () {
                  selection.setBoard(BoardMode.fresh);
                   selection.setMode(OpponentMode.demo);
                  session.startBiddingPractice(humanSeat: selection.seat);
                },
          icon: const Icon(Icons.record_voice_over),
          label: Text(
            copy.t('biddingStart'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      BridgePracticeAction(
        copy.t('hubReviewTitle'),
        copy.t('hubReviewDescription'),
        Icons.history,
        OutlinedButton.icon(
          key: const Key('history_toggle'),
          onPressed: onToggleHistory,
          icon: const Icon(Icons.history),
          label: Text(copy.t(historyOpen ? 'historyClose' : 'historyOpen')),
        ),
      ),
    ],
  );

  Future<void> _startFreePlay(BuildContext context, BridgeSession session, AppCopy copy) async {
    if (session.started &&
        !session.finished &&
        !session.biddingPracticeComplete) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(copy.t('replaceDealTitle')),
          content: Text(copy.t('replaceDealBody')),
          actions: [
            TextButton(
              key: const Key('keep_current_deal'),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(copy.t('keepDeal')),
            ),
            FilledButton(
              key: const Key('replace_current_deal'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(copy.t('replaceDeal')),
            ),
          ],
        ),
      );
      if (!context.mounted || confirmed != true) return;
    }
    if (!context.mounted || session.busy) return;
    
    await session.newGame(
      humanSeat: selection.seat,
      mode: selection.mode,
      boardMode: selection.board,
    );
  }


}
