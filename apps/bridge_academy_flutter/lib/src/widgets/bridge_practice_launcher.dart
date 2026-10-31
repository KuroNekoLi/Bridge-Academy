import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:flutter/material.dart';

import '../app_copy.dart';
import '../bridge_session.dart';
import 'bridge_practice_hub.dart';

/// Persists launch selections even while the focus table temporarily hides the hub.
/// This controller owns UI preferences only, never GameState.
class BridgePracticeSelection extends ChangeNotifier {
  Seat seat = Seat.north;
  OpponentMode mode = OpponentMode.demo;
  BoardMode board = BoardMode.training;
  int level = 3;
  Strain strain = Strain.notrump;
  bool _restored = false;

  void syncRestored(BridgeSession session) {
    if (_restored || !session.restoredFromStorage) return;
    _restored = true;
    seat = session.humanSeat;
    mode = session.mode;
    board = session.boardMode == BoardMode.bidding || session.boardMode == BoardMode.daily
        ? BoardMode.fresh : session.boardMode;
    notifyListeners();
  }

  void setSeat(Seat value) { seat = value; notifyListeners(); }
  void setMode(OpponentMode value) { mode = value; notifyListeners(); }
  void setBoard(BoardMode value) { board = value; notifyListeners(); }
  void setLevel(int value) { level = value; notifyListeners(); }
  void setStrain(Strain value) { strain = value; notifyListeners(); }
}

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
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  _modeSelector(copy, constraints.maxWidth),
                  _seatSelector(copy, constraints.maxWidth),
                  _boardSelector(copy, constraints.maxWidth),
                ],
              ),
            ),
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
        _justDeclareLauncher(session, copy),
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

  Widget _modeSelector(AppCopy copy, double availableWidth) => SizedBox(
        width: availableWidth < 320 ? availableWidth : 320,
        child: DropdownButtonFormField<OpponentMode>(
          key: const Key('mode_selector'),
          isExpanded: true,
          initialValue: selection.mode,
          decoration: InputDecoration(labelText: copy.t('mode')),
          items: [
            for (final mode in OpponentMode.values)
              DropdownMenuItem(
                value: mode,
                child: Text(copy.t(mode == OpponentMode.demo ? 'demo' : 'live'),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 13)),
              ),
          ],
          onChanged: (value) {
            if (value != null) selection.setMode(value);
          },
        ),
      );

  Widget _seatSelector(AppCopy copy, double availableWidth) => SizedBox(
        width: availableWidth < 185 ? availableWidth : 185,
        child: DropdownButtonFormField<Seat>(
          key: const Key('seat_selector'),
          isExpanded: true,
          initialValue: selection.seat,
          decoration: InputDecoration(labelText: copy.t('humanSeat')),
          items: [
            for (final seat in Seat.values)
              DropdownMenuItem(
                value: seat,
                child: Text(copy.seat(seat.letter),
                    overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
          ],
          onChanged: (value) {
            if (value != null) selection.setSeat(value);
          },
        ),
      );

  Widget _boardSelector(AppCopy copy, double availableWidth) => SizedBox(
        width: availableWidth < 225 ? availableWidth : 225,
        child: DropdownButtonFormField<BoardMode>(
          key: const Key('board_mode_selector'),
          isExpanded: true,
          initialValue: (selection.board == BoardMode.bidding ||
                  selection.board == BoardMode.daily)
              ? BoardMode.fresh : selection.board,
          decoration: InputDecoration(labelText: copy.t('boardMode')),
          items: [
            for (final board in [BoardMode.training, BoardMode.fresh])
              DropdownMenuItem(
                value: board,
                child: Text(
                  copy.t(board == BoardMode.training
                      ? 'trainingBoard' : 'freshBoard'),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) selection.setBoard(value);
          },
        ),
      );

  Widget _justDeclareLauncher(BridgeSession session, AppCopy copy) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(copy.t('justDeclareSeatHint')),
          Text(copy.t('justDeclareLevel')),
          DropdownButton<int>(
            key: const Key('just_declare_level'),
            value: selection.level,
            // DropdownButton has no tooltip parameter (Flutter 3.47).
            items: [for (var i = 1; i <= 7; i++)
              DropdownMenuItem(value: i, child: Text('$i'))],
            onChanged: (v) {
              if (v != null) selection.setLevel(v);
            },
          ),
          Text(copy.t('justDeclareStrain')),
          SizedBox(
            width: 178,
            child: DropdownButton<Strain>(
            isExpanded: true,
            key: const Key('just_declare_strain'),
            value: selection.strain,
            // Keep the selector accessible with a visible label.
            items: [for (final v in Strain.values)
              DropdownMenuItem(value: v, child: Text(
                copy.t('strain${v == Strain.notrump ? 'NT' : v.code}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ))],
            onChanged: (v) {
              if (v != null) selection.setStrain(v);
            },
          ),
          ),
          SizedBox(width: 230, child: FilledButton.tonalIcon(
            key: const Key('start_just_declare'),
            onPressed: session.busy || session.saveFailed ||
                (session.started && !session.finished && !session.biddingPracticeComplete) ||
                (session.dailyPractice != null &&
                                   !session.dailyPractice!.isComplete) ||
                              (session.fourBoardPractice != null &&
                    !session.fourBoardPractice!.isComplete)
                ? null : () {
              
              session.startJustDeclare(
                level: selection.level,
                strain: selection.strain,
                humanSeat: selection.seat,
              );
            },
            icon: const Icon(Icons.school),
            label: Text(copy.t('justDeclareStart'),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
        ],
      );

}
