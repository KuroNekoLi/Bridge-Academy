import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:bridge_core/bridge_core.dart' as bridge show Card;
import 'package:flutter/material.dart';

import '../app_copy.dart';
import 'bridge_bidding_box.dart';
import 'bridge_card_face.dart';
import 'bridge_card_strip.dart';
import 'bridge_table_components.dart';
import 'bridge_trick_geometry.dart';

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
  BridgeCardDrag? _selected;
  bool _wideHands = false;
  late final AnimationController _collection;
  Trick? _collected;

  @override
  void initState() {
    super.initState();
    _collection = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(BridgeFocusTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.view;
    final after = widget.view;
    if (after.version != before.version || widget.actionsPaused) {
      _selected = null;
    }
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
    setState(() {
      _submittedVersion = widget.view.version;
      _selected = null;
    });
    widget.onPlayCard(drag.card);
  }

  Widget _hand(Seat owner, List<bridge.Card> cards, String label) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final sorted = sortedVisibleCards(cards);
          final confirm =
              !_wideHands &&
              constraints.maxWidth < 68 + (sorted.length - 1) * 48 &&
              MediaQuery.textScalerOf(context).scale(14) <= 19;
          final selected = _selected?.owner == owner ? _selected : null;
          final selectedIndex = selected == null
              ? null
              : sorted.indexOf(selected.card);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selected == null
                            ? widget.copy.seat(owner.letter)
                            : widget.copy.cardName(selected.card.code),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    if (selected != null)
                      FilledButton(
                        key: const Key('focus_confirm_card'),
                        onPressed: _allowed(selected)
                            ? () => _play(selected)
                            : null,
                        child: Text(widget.copy.t('confirmPlay')),
                      ),
                  ],
                ),
              ),
              BridgeCardStrip(
                useFan: !_wideHands,
                compactFan: !_wideHands,
                selectedIndex: selectedIndex,
                hintColor: Colors.white70,
                centerWhenFits: true,
                id: 'focus_${owner.letter}',
                copy: widget.copy,
                children: [
                  for (final card in sorted)
                    _draggable(
                      BridgeCardDrag(widget.view.version, owner, card),
                      confirm: confirm,
                    ),
                ],
              ),
            ],
          );
        },
      );

  Widget _draggable(BridgeCardDrag drag, {bool confirm = false}) {
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
          child: BridgeCardFace(card: drag.card, prominentIndex: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: .35,
        child: SizedBox(
          width: 64,
          height: 92,
          child: BridgeCardFace(card: drag.card, prominentIndex: true),
        ),
      ),
      child: BridgePlayingCardButton(
        dragEnabled: true,
        prominentIndex:
            !(_selected?.card == drag.card && _selected?.owner == drag.owner),
        card: drag.card,
        prefix: 'focus_card_${drag.owner.letter}_',
        copy: widget.copy,
        legal: allowed,
        busy: widget.actionsPaused,
        onTap: () {
          if (confirm &&
              (_selected?.card != drag.card ||
                  _selected?.owner != drag.owner)) {
            setState(() => _selected = drag);
          } else {
            _play(drag);
          }
        },
      ),
    );
  }

  Widget _seat(Seat seat) {
    final active = widget.view.turn == seat;
    return Semantics(
      selected: active,
      label: active ? widget.copy.t('activeSeat') : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF4D374) : const Color(0xFFE5EDE8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            '${widget.copy.seat(seat.letter)} · ${widget.view.remainingCards[seat] ?? 0}',
            key: Key('focus_seat_${seat.letter}'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF163D33),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _arena() => DragTarget<BridgeCardDrag>(
    onWillAcceptWithDetails: (details) => _allowed(details.data),
    onAcceptWithDetails: (details) => _play(details.data),
    builder: (context, candidates, rejected) => LayoutBuilder(
      builder: (context, constraints) {
        final arena = constraints.biggest;
        final side = arena.width < 560 ? 58.0 : 92.0;
        final geometry = BridgeTrickGeometry.fit(
          Size(arena.width - side * 2, arena.height - 48),
          arenaSize: arena,
        );
        return Container(
          key: const Key('focus_drop_zone'),
          decoration: BoxDecoration(
            color: candidates.isNotEmpty ? Colors.white12 : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundDecoration: BoxDecoration(
            border: Border.all(
              color: candidates.isNotEmpty
                  ? const Color(0xFFF4D374)
                  : Colors.transparent,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Align(alignment: Alignment.topCenter, child: _seat(Seat.north)),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(width: side - 4, child: _seat(Seat.west)),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(width: side - 4, child: _seat(Seat.east)),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _seat(Seat.south),
              ),
              Center(
                child: widget.view.phase == Phase.auction
                    ? SizedBox(
                        width: arena.width - side * 2,
                        height: arena.height - 92,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.copy.t('auction'),
                                style: const TextStyle(color: Colors.white),
                              ),
                              for (final entry in widget.view.auction)
                                Text(
                                  '${widget.copy.seat(entry.seat.letter)} ${entry.call.code}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                            ],
                          ),
                        ),
                      )
                    : BridgeCurrentTrick(
                        view: widget.view,
                        copy: widget.copy,
                        compact: true,
                        geometry: geometry,
                        showHeading: false,
                      ),
              ),
              _collectionLayer(geometry, arena),
            ],
          ),
        );
      },
    ),
  );

  Widget _collectionLayer(BridgeTrickGeometry geometry, Size arena) =>
      Positioned.fill(
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _collection,
              builder: (context, _) {
                if (_collection.value == 1 || _collected == null) {
                  return const SizedBox.shrink();
                }
                final t = _collection.value;
                final gather = const Interval(
                  .12,
                  .45,
                  curve: Curves.easeInOut,
                ).transform(t);
                final fly = const Interval(
                  .45,
                  1,
                  curve: Curves.easeInCubic,
                ).transform(t);
                final fade = 1 - const Interval(.65, 1).transform(t);
                final center =
                    arena.center(Offset.zero) -
                    geometry.cardSize.center(Offset.zero);
                final destination =
                    geometry.seatAnchor(_collected!.winner) -
                    geometry.cardSize.center(Offset.zero);
                return SizedBox(
                  key: const Key('focus_collection'),
                  child: Stack(
                    children: [
                      for (final play in _collected!.plays)
                        Positioned(
                          key: Key('focus_collect_${play.handOwner.letter}'),
                          left:
                              center.dx +
                              geometry.seatOffset(play.handOwner).dx *
                                  (1 - gather) +
                              (destination.dx - center.dx) * fly,
                          top:
                              center.dy +
                              geometry.seatOffset(play.handOwner).dy *
                                  (1 - gather) +
                              (destination.dy - center.dy) * fly,
                          child: Opacity(
                            opacity: fade,
                            child: Transform.scale(
                              scale: 1 - .3 * fly,
                              child: SizedBox(
                                width: geometry.cardSize.width,
                                height: geometry.cardSize.height,
                                child: BridgeCardFace(
                                  card: play.card,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

  Widget _tableSurface({double? arenaHeight}) {
    final view = widget.view;
    return DecoratedBox(
      key: const Key('focus_table_surface'),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          radius: 1.2,
          colors: [Color(0xFF246653), Color(0xFF123F35)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: arenaHeight == null
              ? MainAxisSize.max
              : MainAxisSize.min,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final copy = widget.copy;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            key: const Key('focus_hand_layout'),
            tooltip: copy.t(_wideHands ? 'fanHand' : 'wideHand'),
            icon: Icon(_wideHands ? Icons.style : Icons.view_carousel_outlined),
            onPressed: () => setState(() {
              _wideHands = !_wideHands;
              _selected = null;
            }),
          ),
        ],
        title: Text(
          '${copy.contract(view.contract?.label ?? copy.t('notYet'))} · ${copy.boardNumber(widget.boardNumber)}',
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
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Text(
                                  copy.trickCount(view.completedTricks.length),
                                ),
                                const SizedBox(width: 12),
                                Text(copy.dealer(view.dealer.letter)),
                                const SizedBox(width: 12),
                                Text(
                                  copy.vulnerability(view.vulnerability.name),
                                ),
                              ],
                            ),
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
                          SizedBox(
                            height: MediaQuery.textScalerOf(context).scale(24),
                            child: view.completedTricks.isEmpty
                                ? const SizedBox.shrink()
                                : Text(
                                    copy.replayWinner(
                                      view.completedTricks.last.winner.letter,
                                    ),
                                  ),
                          ),
                          if (view.phase == Phase.play)
                            Text(
                              copy.t(
                                _wideHands ? 'focusDragHint' : 'selectPlayHint',
                              ),
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
