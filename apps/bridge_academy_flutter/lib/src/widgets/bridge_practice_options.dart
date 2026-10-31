import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:flutter/material.dart';
import '../app_copy.dart';
import '../bridge_session.dart';
import 'bridge_practice_selection.dart';

/// Pure practice settings UI; changes are sent to the selection controller.
class BridgePracticeSettings extends StatelessWidget {
  const BridgePracticeSettings({super.key, required this.copy, required this.selection});
  final AppCopy copy;
  final BridgePracticeSelection selection;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _modeSelector(copy, constraints.maxWidth),
        _seatSelector(copy, constraints.maxWidth),
        _boardSelector(copy, constraints.maxWidth),
      ],
    ),
  );

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

}

/// Isolated contract/strain entry point for just-declare training.
class BridgeJustDeclareLauncher extends StatelessWidget {
  const BridgeJustDeclareLauncher({super.key, required this.session,
    required this.copy, required this.selection});
  final BridgeSession session;
  final AppCopy copy;
  final BridgePracticeSelection selection;

  @override
  Widget build(BuildContext context) => Wrap(
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
