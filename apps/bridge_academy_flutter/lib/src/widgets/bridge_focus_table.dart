import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:bridge_core/bridge_core.dart' as bridge show Card;
import 'package:flutter/material.dart';

import '../app_copy.dart';
import 'bridge_bidding_box.dart';
import 'bridge_card_face.dart';
import 'bridge_card_strip.dart';
import 'bridge_table_components.dart';

/// A drag carries only a visible card and the projection it came from.
class BridgeCardDrag {
  const BridgeCardDrag(this.version, this.owner, this.card);
  final int version;
  final Seat owner;
  final bridge.Card card;
}

/// Focused viewport, driven by an authorized projection. No Session or Deal.
class BridgeFocusTable extends StatefulWidget {
  const BridgeFocusTable({
    super.key,
    required this.view,
    required this.copy,
    required this.boardNumber,
    required this.modeLabel,
    required this.actionsPaused,
    required this.onPlayCard,
    required this.onSubmitCall,
    this.error,
    this.onRetry,
  });

  final PlayerView view;
  final AppCopy copy;
  final int boardNumber;
  final String modeLabel;
  final bool actionsPaused;
  final ValueChanged<bridge.Card> onPlayCard;
  final ValueChanged<Call> onSubmitCall;
  final String? error;
  final VoidCallback? onRetry;

  @override
  State<BridgeFocusTable> createState() => _BridgeFocusTableState();
}

class _BridgeFocusTableState extends State<BridgeFocusTable>
    with SingleTickerProviderStateMixin {
  int _level = 1;
  Strain _strain = Strain.notrump;
  int? _submittedVersion;
  late final AnimationController _collection;
  Trick? _collected;

  @override
  void initState() {
    super.initState();
    _collection = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(BridgeFocusTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.view;
    final after = widget.view;
    if (after.version != before.version ||
        (oldWidget.actionsPaused && !widget.actionsPaused) ||
        (oldWidget.error != null && widget.error == null)) {
      _submittedVersion = null;
    }
    if (after.version <= before.version && after.version != before.version) {
      _collected = null;
      _collection.value = 1;
    } else if (after.completedTricks.length > before.completedTricks.length) {
      _collected = after.completedTricks.last;
      if (MediaQuery.disableAnimationsOf(context)) {
        _collection.value = 1;
      } else {
        _collection.forward(from: 0);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _collection.value = 1;
  }

  @override
  void dispose() {
    _collection.dispose();
    super.dispose();
  }

  bool _allowed(BridgeCardDrag drag) =>
      !widget.actionsPaused &&
      _submittedVersion != widget.view.version &&
      drag.version == widget.view.version &&
      widget.view.canAct &&
      widget.view.phase == Phase.play &&
      drag.owner == widget.view.turn &&
      widget.view.legalCards.contains(drag.card);

  void _play(BridgeCardDrag drag) {
    if (!_allowed(drag)) return;
    setState(() => _submittedVersion = widget.view.version);
    widget.onPlayCard(drag.card);
  }

  Widget _hand(Seat owner, List<bridge.Card> cards, String label) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      BridgeCardStrip(
        useFan: true,
        centerWhenFits: true,
        id: 'focus_${owner.letter}',
        copy: widget.copy,
        children: [
          for (final card in sortedVisibleCards(cards))
            _draggable(BridgeCardDrag(widget.view.version, owner, card)),
        ],
      ),
    ],
  );

  Widget _draggable(BridgeCardDrag drag) {
    final allowed = _allowed(drag);
    return LongPressDraggable<BridgeCardDrag>(
      key: Key('focus_drag_${drag.owner.letter}_${drag.card.code}'),
      data: drag,
      maxSimultaneousDrags: allowed ? 1 : 0,
      feedback: Material(
        key: const Key('focus_drag_feedback'),
        color: Colors.transparent,
        child: SizedBox(
          width: 58,
          height: 84,
          child: BridgeCardFace(card: drag.card),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: .35,
        child: SizedBox(
          width: 64,
          height: 92,
          child: BridgeCardFace(card: drag.card),
        ),
      ),
      child: BridgePlayingCardButton(
        dragEnabled: true,
        card: drag.card,
        prefix: 'focus_card_${drag.owner.letter}_',
        copy: widget.copy,
        legal: allowed,
        busy: widget.actionsPaused,
        onTap: () => _play(drag),
      ),
    );
  }

  Widget _seat(Seat seat) => DecoratedBox(
    decoration: BoxDecoration(
      color: widget.view.turn == seat
          ? Theme.of(context).colorScheme.primaryContainer
          : Colors.white70,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        '${widget.copy.seat(seat.letter)} · '
        '${widget.view.remainingCards[seat] ?? 0}'
        '${widget.view.turn == seat ? ' · ${widget.copy.t('activeSeat')}' : ''}',
        key: Key('focus_seat_${seat.letter}'),
        textAlign: TextAlign.center,
      ),
    ),
  );

  Widget _arena() => DragTarget<BridgeCardDrag>(
    onWillAcceptWithDetails: (details) => _allowed(details.data),
    onAcceptWithDetails: (details) => _play(details.data),
    builder: (context, candidates, rejected) => Container(
      key: const Key('focus_drop_zone'),
      decoration: BoxDecoration(
        color: candidates.isNotEmpty
            ? const Color(0xFFB3DCCA)
            : const Color(0xFFD8E9DE),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: candidates.isNotEmpty ? 3 : 1,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          Align(alignment: Alignment.topCenter, child: _seat(Seat.north)),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(width: 76, child: _seat(Seat.west)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(width: 76, child: _seat(Seat.east)),
          ),
          Align(alignment: Alignment.bottomCenter, child: _seat(Seat.south)),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 78),
              child: widget.view.phase == Phase.auction
                  ? SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.copy.t('auction')),
                          for (final entry in widget.view.auction)
                            Text(
                              '${widget.copy.seat(entry.seat.letter)} ${entry.call.code}',
                            ),
                        ],
                      ),
                    )
                  : BridgeCurrentTrick(
                      view: widget.view,
                      copy: widget.copy,
                      compact: true,
                    ),
            ),
          ),
          // Public completed cards are decorative only, never another command.
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _collection,
                  builder: (context, _) {
                    if (_collection.value == 1 || _collected == null) {
                      return const SizedBox.shrink();
                    }
                    final t = Curves.easeIn.transform(_collection.value);
                    Offset slot(Seat seat) => switch (seat) {
                      Seat.north => const Offset(0, -30),
                      Seat.east => const Offset(54, 0),
                      Seat.south => const Offset(0, 30),
                      Seat.west => const Offset(-54, 0),
                    };
                    final winner = slot(_collected!.winner);
                    return Center(
                      child: SizedBox(
                        key: const Key('focus_collection'),
                        width: 148,
                        height: 116,
                        child: Stack(
                          children: [
                            for (final play in _collected!.plays)
                              Positioned(
                                left: 54 + slot(play.handOwner).dx,
                                top: 30 + slot(play.handOwner).dy,
                                child: Opacity(
                                  opacity: 1 - t,
                                  child: Transform.translate(
                                    offset: (winner - slot(play.handOwner)) * t,
                                    child: SizedBox(
                                      width: 40,
                                      height: 56,
                                      child: BridgeCardFace(card: play.card),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _tableSurface({double? arenaHeight}) {
    final view = widget.view;
    return ColoredBox(
      key: const Key('focus_table_surface'),
      color: const Color(0xFFD8E9DE),
      child: Column(
        mainAxisSize: arenaHeight == null ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (view.dummyExposed &&
              view.dummyCards != null &&
              view.contract!.dummy != view.viewer)
            _hand(
              view.contract!.dummy,
              view.dummyCards!,
              widget.copy.t('dummy'),
            ),
          if (arenaHeight != null)
            SizedBox(height: arenaHeight, child: _arena())
          else
            Expanded(child: _arena()),
          _hand(view.viewer, view.ownCards, widget.copy.t('cards')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final copy = widget.copy;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          copy.t('focusTable'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final large = MediaQuery.textScalerOf(context).scale(14) > 19;
            final minimum = view.phase == Phase.auction ? 730.0 : 620.0;
            final fallback = large || constraints.maxHeight < minimum;
            return SingleChildScrollView(
              key: const Key('focus_viewport'),
              child: SizedBox(
                height: fallback ? null : constraints.maxHeight,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 2,
                            children: [
                              Text(copy.boardNumber(widget.boardNumber)),
                              Text(copy.dealer(view.dealer.letter)),
                              Text(
                                copy.contract(
                                  view.contract?.label ?? copy.t('notYet'),
                                ),
                              ),
                              Text(
                                copy.trickCount(view.completedTricks.length),
                              ),
                              Text(copy.vulnerability(view.vulnerability.name)),
                            ],
                          ),
                          Text(
                            widget.modeLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          if (widget.error != null)
                            Wrap(
                              children: [
                                Text(
                                  widget.error!,
                                  key: const Key('focus_error'),
                                ),
                                if (widget.onRetry != null)
                                  TextButton(
                                    key: const Key('focus_retry'),
                                    onPressed: widget.onRetry,
                                    child: Text(copy.t('focusRetry')),
                                  ),
                              ],
                            ),
                          if (widget.actionsPaused)
                            const LinearProgressIndicator(),
                          const SizedBox(height: 6),
                          if (fallback)
                            _tableSurface(arenaHeight: large ? 500 : 260)
                          else
                            Expanded(child: _tableSurface()),
                          if (view.completedTricks.isNotEmpty)
                            Text(
                              copy.replayWinner(
                                view.completedTricks.last.winner.letter,
                              ),
                            ),
                          if (view.phase == Phase.play)
                            Text(
                              copy.t('focusDragHint'),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          if (view.phase == Phase.auction)
                            BridgeBiddingBox(
                              copy: copy,
                              selectedLevel: _level,
                              selectedStrain: _strain,
                              canSubmit: view.canAct && !widget.actionsPaused,
                              onLevelChanged: (value) =>
                                  setState(() => _level = value),
                              onStrainChanged: (value) =>
                                  setState(() => _strain = value),
                              onSubmitCall: widget.onSubmitCall,
                            ),
                          if (view.phase == Phase.finished)
                            Text(
                              view.nsScore == null
                                  ? copy.t('passOut')
                                  : copy.score(view.nsScore!),
                              key: const Key('focus_result'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
