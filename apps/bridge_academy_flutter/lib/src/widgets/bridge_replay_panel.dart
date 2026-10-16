import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:flutter/material.dart';

import '../app_copy.dart';
import '../review/review_timeline.dart';
import 'bridge_table_components.dart';

/// Terminal history uses filtered, immutable replay frames only.
class BridgeCompletedReplayPanel extends StatelessWidget {
  const BridgeCompletedReplayPanel({
    super.key,
    required this.replay,
    required this.index,
    required this.copy,
    required this.onSelectIndex,
    this.reviewId,
  });

  final CompletedReplay replay;
  final int index;
  final AppCopy copy;
  final ValueChanged<int> onSelectIndex;
  /// Only for ephemeral in-page bookmarks; this is not a persistent store ID.
  final String? reviewId;

  @override
  Widget build(BuildContext context) {
    final timeline = ReviewTimeline.fromReplay(replay);
    final step = timeline.steps[index];
    final frame = step.frame;
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
            if (step.targetTricks != null)
              Text('${copy.t('reviewTargetTricks')}: ${step.targetTricks}',
                  key: const Key('review_target_tricks')),
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
            const SizedBox(height: 12),
            Text(copy.t('reviewNotesTitle'),
                style: Theme.of(context).textTheme.titleSmall),
            Text(copy.t('reviewStrategyUnknown'),
                key: const Key('review_strategy_unknown')),
            for (final note in step.insights)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  '${copy.t(switch (note.evidence) {
                    ReviewEvidence.rule => 'reviewRuleTag',
                    ReviewEvidence.convention => 'reviewConventionTag',
                    ReviewEvidence.unknown => 'reviewUnknownTag',
                  })}: ${copy.t(note.key)}'
                  '${note.ruleId == null ? '' : ' (${note.ruleId})'}',
                  key: Key('review_insight_${note.key}'),
                ),
              ),
            const SizedBox(height: 8),
            _ReviewJumpAndMarks(
              timeline: timeline,
              index: index,
              copy: copy,
              reviewId: reviewId ?? replay.historyFingerprint,
              onSelectIndex: onSelectIndex,
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                key: const Key('replay_first'),
                onPressed: index == 0 ? null : () => onSelectIndex(0),
                child: Text(copy.t('replayFirst')),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                key: const Key('replay_previous'),
                onPressed: index == 0
                    ? null : () => onSelectIndex(index - 1),
                child: Text(copy.t('replayPrevious')),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                key: const Key('replay_next'),
                onPressed: index == replay.lastIndex
                    ? null : () => onSelectIndex(index + 1),
                child: Text(copy.t('replayNext')),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
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

 
/// Bookmarks deliberately live only while this review widget is mounted;
/// no additional plaintext history store is created or synchronized.
class _ReviewJumpAndMarks extends StatefulWidget {
  const _ReviewJumpAndMarks({
    required this.timeline,
    required this.index,
    required this.copy,
    required this.reviewId,
    required this.onSelectIndex,
  });

  final ReviewTimeline timeline;
  final int index;
  final AppCopy copy;
  final String reviewId;
  final ValueChanged<int> onSelectIndex;

  @override
  State<_ReviewJumpAndMarks> createState() => _ReviewJumpAndMarksState();
}

class _ReviewJumpAndMarksState extends State<_ReviewJumpAndMarks> {
  final Set<String> _bookmarks = {};

  @override
  void didUpdateWidget(covariant _ReviewJumpAndMarks oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reviewId != widget.reviewId ||
        oldWidget.timeline.historyFingerprint !=
            widget.timeline.historyFingerprint) {
      _bookmarks.clear();
    }
  }

  String _keyFor(int index) => '${widget.reviewId}:$index';

  String _stepLabel(ReviewStep step) {
    final action = step.frame.action;
    final event = switch (step.eventType) {
      ReviewEventType.start => widget.copy.t('reviewStartEvent'),
      ReviewEventType.auction => widget.copy.t('reviewAuctionEvent'),
      ReviewEventType.play => widget.copy.t('reviewPlayEvent'),
    };
    final actionCode = switch (action) {
      CallAction a => ' ${a.actor.letter} ${a.call.code}',
      CardAction a => ' ${a.handOwner.letter} ${a.card.code}',
      _ => '',
    };
    return '${step.index} · $event$actionCode';
  }

  @override
  Widget build(BuildContext context) {
    final next = widget.timeline.nextKeyAfter(widget.index);
    final previous = widget.timeline.previousKeyBefore(widget.index);
    final marked = _bookmarks.contains(_keyFor(widget.index));
    final activeMarks = widget.timeline.steps
        .where((step) => _bookmarks.contains(_keyFor(step.index)))
        .toList();

    return Column(
      key: const Key('review_timeline_controls'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.copy.t('reviewJumpTitle')),
        DropdownButton<int>(
          key: const Key('review_jump'),
          isExpanded: true,
          value: widget.index,
          items: [
            for (final step in widget.timeline.steps)
              DropdownMenuItem<int>(
                value: step.index,
                child: Text(_stepLabel(step),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (value) {
            if (value != null) widget.onSelectIndex(value);
          },
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              key: const Key('review_prev_key'),
              onPressed: previous == null
                  ? null : () => widget.onSelectIndex(previous),
              child: Text(widget.copy.t('reviewPreviousKey')),
            ),
            OutlinedButton(
              key: const Key('review_next_key'),
              onPressed: next == null
                  ? null : () => widget.onSelectIndex(next),
              child: Text(widget.copy.t('reviewNextKey')),
            ),
            OutlinedButton.icon(
              key: const Key('review_bookmark_toggle'),
              icon: Icon(marked ? Icons.bookmark : Icons.bookmark_border),
              onPressed: () => setState(() {
                if (marked) {
                  _bookmarks.remove(_keyFor(widget.index));
                } else {
                  _bookmarks.add(_keyFor(widget.index));
                }
              }),
              label: Text(widget.copy.t(
                  marked ? 'reviewUnmark' : 'reviewMark')),
            ),
          ],
        ),
        if (activeMarks.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(widget.copy.t('reviewMarkedTitle')),
          Wrap(
            key: const Key('review_bookmarks'),
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final step in activeMarks)
                ActionChip(
                  key: Key('review_bookmark_${step.index}'),
                  label: Text(_stepLabel(step)),
                  onPressed: () => widget.onSelectIndex(step.index),
                ),
            ],
          ),
        ],
        Text(widget.copy.t('reviewBookmarksTemporary'),
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
