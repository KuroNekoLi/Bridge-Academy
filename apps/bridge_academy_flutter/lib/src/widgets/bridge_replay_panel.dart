import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';

import '../app_copy.dart';
import 'bridge_table_components.dart';

/// Terminal history uses filtered, immutable replay frames only.
class BridgeCompletedReplayPanel extends StatelessWidget {
  const BridgeCompletedReplayPanel({
    super.key,
    required this.replay,
    required this.index,
    required this.copy,
    required this.onSelectIndex,
  });

  final CompletedReplay replay;
  final int index;
  final AppCopy copy;
  final ValueChanged<int> onSelectIndex;

  @override
  Widget build(BuildContext context) {
    final frame = replay.frames[index];
    final view = frame.view;
    final action = frame.action;
    String eventLabel;
    if (action is CallAction) {
      eventLabel = '${copy.seat(action.actor.letter)}: ${action.call.code}';
    } else if (action is CardAction) {
      eventLabel = '${copy.seat(action.handOwner.letter)}: '
          '${bridgeCardText(action.card)}';
      if (action.actor != action.handOwner) {
        eventLabel = '$eventLabel (${copy.t('replayBy')}: '
            '${copy.seat(action.actor.letter)})';
      }
    } else {
      eventLabel = copy.t('replayStart');
    }

    return Card(
      key: const Key('replay_panel'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(copy.t('replayTitle'),
                style: Theme.of(context).textTheme.titleMedium),
            Text(copy.replayProgress(index, replay.lastIndex),
                key: const Key('replay_progress')),
            const SizedBox(height: 6),
            Text(eventLabel, key: const Key('replay_event')),
            Text(copy.trickCount(view.completedTricks.length)),
            Text(copy.contract(view.contract?.label ?? copy.t('notYet'))),
            if (view.nsScore != null) Text(copy.score(view.nsScore!)),
            if (view.currentTrick.isNotEmpty) ...[
              Text(copy.t('currentTrick')),
              Wrap(
                spacing: 8,
                children: [
                  for (final play in view.currentTrick)
                    Text('${play.handOwner.letter}: '
                        '${bridgeCardText(play.card)}'),
                ],
              ),
            ],
            if (view.completedTricks.isNotEmpty)
              Text(copy.replayWinner(
                  view.completedTricks.last.winner.letter)),
            const SizedBox(height: 8),
            for (final seat in Seat.values)
              Text('${copy.seat(seat.letter)}: '
                  '${copy.remaining(view.remainingCards[seat] ?? 0)}'),
            if (view.ownCards.isNotEmpty) ...[
              Text(copy.t('cards')),
              Wrap(spacing: 6, children: [
                for (final card in view.ownCards)
                  Text(bridgeCardText(card)),
              ]),
            ],
            if (view.dummyCards != null && view.dummyCards!.isNotEmpty) ...[
              Text(copy.t('dummy')),
              Wrap(spacing: 6, children: [
                for (final card in view.dummyCards!)
                  Text(bridgeCardText(card)),
              ]),
            ],
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton(
                key: const Key('replay_first'),
                onPressed: index == 0 ? null : () => onSelectIndex(0),
                child: Text(copy.t('replayFirst')),
              ),
              OutlinedButton(
                key: const Key('replay_previous'),
                onPressed: index == 0
                    ? null : () => onSelectIndex(index - 1),
                child: Text(copy.t('replayPrevious')),
              ),
              OutlinedButton(
                key: const Key('replay_next'),
                onPressed: index == replay.lastIndex
                    ? null : () => onSelectIndex(index + 1),
                child: Text(copy.t('replayNext')),
              ),
              OutlinedButton(
                key: const Key('replay_last'),
                onPressed: index == replay.lastIndex
                    ? null : () => onSelectIndex(replay.lastIndex),
                child: Text(copy.t('replayLast')),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
