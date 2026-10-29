import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:bridge_core/bridge_core.dart' as bridge show Card;
import 'package:flutter/material.dart';
import 'package:overmark/overmark.dart';

import '../app_copy.dart';
import 'bridge_bidding_box.dart';
import 'bridge_auction_grid.dart';
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

String _dummySuitSymbol(Suit suit) => switch (suit) {
  Suit.spades => '♠',
  Suit.hearts => '♥',
  Suit.clubs => '♣',
  Suit.diamonds => '♦',
};

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
  final _bidAnchor = GlobalKey(debugLabel: 'focus_tutorial_bid');
  final _handAnchor = GlobalKey(debugLabel: 'focus_tutorial_hand');
  final _dummySuitsAnchor = GlobalKey(debugLabel: 'focus_tutorial_suits');
  final _dummyChoicesAnchor = GlobalKey(debugLabel: 'focus_tutorial_choices');
  int? _submittedVersion;
  BridgeCardDrag? _selected;
  Suit? _selectedDummySuit;
  OvermarkController? _tutorial;
  int? _tutorialVersion;
  Call? _tutorialCall;
  bridge.Card? _tutorialCard;
  Seat? _tutorialCardOwner;
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
    if (_tutorial?.isAwaitingAction == true &&
        _tutorialVersion == before.version &&
        after.version > before.version) {
      final callAccepted =
          _tutorialCall != null &&
          after.auction.length > before.auction.length &&
          after.auction[before.auction.length].call.code == _tutorialCall!.code;
      final cardAccepted =
          _tutorialCard != null &&
          <PlayedCard>[
            ...after.currentTrick,
            for (final trick in after.completedTricks) ...trick.plays,
          ].any(
            (play) =>
                play.handOwner == _tutorialCardOwner &&
                play.card == _tutorialCard,
          );
      if (callAccepted || cardAccepted) {
        _tutorialVersion = null;
        _tutorialCall = null;
        _tutorialCard = null;
        _tutorialCardOwner = null;
        _tutorial!.completeAction();
      }
    }
    if (after.viewer != before.viewer) {
      _selected = null;
      _selectedDummySuit = null;
      _submittedVersion = null;
      _collected = null;
      _collection.value = 1;
      return;
    }
    if (after.version != before.version || widget.actionsPaused) {
      _selected = null;
      _selectedDummySuit = null;
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
    if (_tutorial?.isAwaitingAction == true) {
      _tutorialVersion = widget.view.version;
      _tutorialCard = drag.card;
      _tutorialCardOwner = drag.owner;
    }
    widget.onPlayCard(drag.card);
  }

  void _submitCall(Call call) {
    if (_tutorial?.isAwaitingAction == true) {
      _tutorialVersion = widget.view.version;
      _tutorialCall = call;
    }
    widget.onSubmitCall(call);
  }

  Future<void> _startTutorial() async {
    final view = widget.view;
    if (widget.actionsPaused || !view.canAct || Overmark.isShowing) return;
    final steps = <OvermarkStep>[];
    if (view.phase == Phase.auction) {
      steps.add(
        _actionStep(_bidAnchor, 'tutorialBidTitle', 'tutorialBidMessage'),
      );
    } else if (view.phase == Phase.play &&
        view.dummyExposed &&
        view.contract?.dummy == view.turn &&
        view.viewer != view.turn) {
      final legalSuits = {for (final card in view.legalCards) card.suit};
      if (legalSuits.isEmpty) return;
      setState(() => _selectedDummySuit = null);
      steps
        ..add(
          _actionStep(
            _dummySuitsAnchor,
            'tutorialSuitTitle',
            'tutorialSuitMessage',
          ),
        )
        ..add(
          _actionStep(
            _dummyChoicesAnchor,
            'tutorialCardTitle',
            'tutorialCardMessage',
          ),
        );
    } else if (view.phase == Phase.play && view.turn == view.viewer) {
      steps.add(
        _actionStep(_handAnchor, 'tutorialCardTitle', 'tutorialCardMessage'),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.copy.t('tutorialWait'))));
      return;
    }
    final controller = OvermarkController();
    _tutorial = controller;
    setState(() {});
    try {
      await Overmark.show(
        context,
        controller: controller,
        steps: steps,
        labels: OvermarkLabels(
          next: widget.copy.t('tutorialNext'),
          previous: widget.copy.t('tutorialBack'),
          skip: widget.copy.t('tutorialSkip'),
          done: widget.copy.t('tutorialDone'),
        ),
        config: const OvermarkConfig(
          advanceOnBarrierTap: false,
          showPrevious: false,
          dismissible: true,
        ),
        theme: const OvermarkTheme(
          spotlightBorderColor: Color(0xFFB7E85B),
          spotlightBorderWidth: 3,
          spotlightPulse: true,
          cardMotion: OvermarkCardMotion.fadeSlide,
        ),
      );
    } finally {
      if (mounted && identical(_tutorial, controller)) {
        setState(() {
          _tutorial = null;
          _tutorialVersion = null;
          _tutorialCall = null;
          _tutorialCard = null;
          _tutorialCardOwner = null;
          _selectedDummySuit = null;
        });
      }
    }
  }

  OvermarkStep _actionStep(
    GlobalKey anchor,
    String titleKey,
    String messageKey,
  ) => OvermarkStep(
    anchorKey: anchor,
    title: widget.copy.t(titleKey),
    message: widget.copy.t(messageKey),
    gate: OvermarkStepGate.action,
    shape: OvermarkShape.rrect,
    padding: const EdgeInsets.all(4),
    cardBuilder: (context, details) => Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.copy.t(titleKey),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(widget.copy.t(messageKey)),
            if (details.isAwaitingAction) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app_rounded, size: 20),
                  const SizedBox(width: 8),
                  Flexible(child: Text(widget.copy.t('tutorialTapToContinue'))),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: details.skip,
                  child: Text(widget.copy.t('tutorialSkip')),
                ),
                if (!details.isAwaitingAction)
                  FilledButton(
                    onPressed: details.completeAction,
                    child: Text(widget.copy.t('tutorialDone')),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

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
              if (owner != widget.view.viewer)
                _dummyHand(owner, sorted)
              else
                KeyedSubtree(
                  key: _handAnchor,
                  child: BridgeCardStrip(
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
                ),
            ],
          );
        },
      );

  Widget _dummyHand(Seat owner, List<bridge.Card> sorted) {
    const suits = [Suit.spades, Suit.hearts, Suit.clubs, Suit.diamonds];
    final selectedSuit = _selectedDummySuit;
    final choices = selectedSuit == null
        ? const <bridge.Card>[]
        : sorted.where((card) => card.suit == selectedSuit).toList();
    return Column(
      key: Key('focus_${owner.letter}_dummy_hand'),
      mainAxisSize: MainAxisSize.min,
      children: [
        KeyedSubtree(
          key: _dummySuitsAnchor,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columnWidth = constraints.maxWidth / suits.length;
              final cardWidth = (columnWidth - 6).clamp(36.0, 46.0).toDouble();
              final cardHeight = cardWidth * 84 / 58;
              // Keep the four suit stacks shallow enough to protect the central
              // trick area on short mobile viewports; the selected suit expands
              // into full cards below.
              const overlap = 20.0;
              return Row(
                key: Key('focus_${owner.letter}_dummy_suits'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final suit in suits)
                    Expanded(
                      child: _dummySuitColumn(
                        owner: owner,
                        suit: suit,
                        cards: sorted
                            .where((card) => card.suit == suit)
                            .toList(),
                        width: columnWidth,
                        cardWidth: cardWidth,
                        cardHeight: cardHeight,
                        overlap: overlap,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        if (selectedSuit != null && choices.isNotEmpty)
          KeyedSubtree(
            key: _dummyChoicesAnchor,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: BridgeCardStrip(
                key: Key('focus_${owner.letter}_dummy_choices'),
                centerWhenFits: true,
                id: 'focus_${owner.letter}_dummy_choice',
                copy: widget.copy,
                children: [
                  for (final card in choices)
                    _draggable(
                      BridgeCardDrag(widget.view.version, owner, card),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _dummySuitColumn({
    required Seat owner,
    required Suit suit,
    required List<bridge.Card> cards,
    required double width,
    required double cardWidth,
    required double cardHeight,
    required double overlap,
  }) {
    final selected = _selectedDummySuit == suit;
    final canSelect =
        widget.view.phase == Phase.play &&
        widget.view.canAct &&
        !widget.actionsPaused &&
        _submittedVersion != widget.view.version &&
        widget.view.turn == owner &&
        cards.any(widget.view.legalCards.contains);
    final suitLabel = widget.copy.t(switch (suit) {
      Suit.spades => 'suitS',
      Suit.hearts => 'suitH',
      Suit.diamonds => 'suitD',
      Suit.clubs => 'suitC',
    });
    return Semantics(
      label: '$suitLabel, ${widget.copy.remaining(cards.length)}',
      button: true,
      selected: selected,
      enabled: canSelect,
      child: Tooltip(
        message: '$suitLabel · ${cards.length}',
        child: InkWell(
          key: Key('focus_dummy_suit_${suit.name}'),
          borderRadius: BorderRadius.circular(8),
          onTap: canSelect
              ? () {
                  setState(() => _selectedDummySuit = selected ? null : suit);
                  if (_tutorial?.isAwaitingAction == true && !selected) {
                    _tutorial!.completeAction();
                  }
                }
              : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFB7E85B).withValues(alpha: .18)
                  : Colors.transparent,
              border: Border.all(
                color: selected ? const Color(0xFFB7E85B) : Colors.white24,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              width: width,
              height:
                  24 +
                  (cards.isEmpty
                      ? 0
                      : cardHeight + (cards.length - 1) * overlap),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 22,
                    child: Center(
                      child: Text(
                        '${_dummySuitSymbol(suit)}  ${cards.length}',
                        maxLines: 1,
                        style: TextStyle(
                          color: suit == Suit.hearts || suit == Suit.diamonds
                              ? const Color(0xFFFF8990)
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (cards.isEmpty)
                    Positioned.fill(
                      top: 22,
                      child: Center(
                        child: Text(
                          widget.copy.t('emptySuit'),
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ),
                    ),
                  for (var index = 0; index < cards.length; index++)
                    Positioned(
                      left: (width - cardWidth) / 2,
                      top: 22 + index * overlap,
                      width: cardWidth,
                      height: cardHeight,
                      child: IgnorePointer(
                        child: BridgeCardFace(
                          card: cards[index],
                          prominentIndex: true,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
        if (widget.view.phase == Phase.auction) {
          return BridgeAuctionGrid(
            view: widget.view,
            copy: widget.copy,
            height: arena.height,
          );
        }
        final side = arena.width < 560 ? 58.0 : 92.0;
        final geometry = BridgeTrickGeometry.fit(
          Size(arena.width - side * 2, arena.height - 48),
          arenaSize: arena,
          viewer: widget.view.viewer,
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
              Align(
                alignment: Alignment.topCenter,
                child: _seat(geometry.seatAt(Seat.north)),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: side - 4,
                  child: _seat(geometry.seatAt(Seat.west)),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: side - 4,
                  child: _seat(geometry.seatAt(Seat.east)),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _seat(geometry.seatAt(Seat.south)),
              ),
              Center(
                child: BridgeCurrentTrick(
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
                                child: BridgeCardFace(card: play.card),
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
          IconButton(
            key: const Key('focus_tutorial'),
            tooltip: copy.t('tutorialHelp'),
            icon: const Icon(Icons.lightbulb_outline_rounded),
            onPressed: _tutorial == null ? _startTutorial : null,
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
                            KeyedSubtree(
                              key: _bidAnchor,
                              child: BridgeBiddingBox(
                                copy: copy,
                                view: view,
                                canSubmit: view.canAct && !widget.actionsPaused,
                                onSubmitCall: _submitCall,
                              ),
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
