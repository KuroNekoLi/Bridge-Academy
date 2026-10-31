import 'package:flutter/material.dart';

import '../app_copy.dart';
import '../bridge_session.dart';
import 'bridge_replay_panel.dart';

/// Mutations are requested through BridgeSession; this widget owns no game state.
class BridgeCompletedBoardActions extends StatelessWidget {
  const BridgeCompletedBoardActions({super.key, required this.session, required this.copy});
  final BridgeSession session;
  final AppCopy copy;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          if (session.fourBoardPractice != null &&
              !session.fourBoardPractice!.isComplete)
            FilledButton.icon(
              key: const Key('next_practice_board'),
              onPressed: session.busy || session.saveFailed ||
                  session.historySaveFailed ? null : () {
                
                session.nextFourBoardPractice();
              },
              icon: const Icon(Icons.skip_next),
              label: Text(copy.t('practiceFourNext')),
            ),
          if (session.fourBoardPractice == null && session.dailyPractice == null)
          OutlinedButton.icon(
            key: const Key('replay_same_board'),
            onPressed: session.busy ? null : () {
              
              session.replaySameBoard();
            },
            icon: const Icon(Icons.replay),
            label: Text(copy.t('replaySameBoard')),
          ),
          if (session.fourBoardPractice == null && session.dailyPractice == null)
          FilledButton.icon(
            key: const Key('next_board'),
            onPressed: session.busy ? null : () {
              
              session.nextBoard();
            },
            icon: const Icon(Icons.skip_next),
            label: Text(copy.t('nextBoard')),
          ),
        ],
      );
}

/// The replay cursor belongs to the replay UI, not to the table controller.
/// The caller keys this widget by the immutable completed replay snapshot.
class BridgeCompletedReplaySection extends StatefulWidget {
  const BridgeCompletedReplaySection({super.key, required this.session, required this.copy});
  final BridgeSession session;
  final AppCopy copy;

  @override
  State<BridgeCompletedReplaySection> createState() => _BridgeCompletedReplaySectionState();
}

class _BridgeCompletedReplaySectionState extends State<BridgeCompletedReplaySection> {
  int? _replayIndex;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final copy = widget.copy;
    final replay = session.completedReplay;
    if (replay == null) return const SizedBox.shrink();
    final index = (_replayIndex ?? replay.lastIndex).clamp(0, replay.lastIndex);
    return BridgeCompletedReplayPanel(
      replay: replay,
      index: index,
      copy: copy,
      onSelectIndex: (value) => setState(() => _replayIndex = value),
      onAnalyzeDds: session.analyzeCompletedDds,
    );
  }
}
