import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:bridge_core/bridge_core.dart' as bridge show Card;
import 'package:flutter/material.dart';

import '../app_copy.dart';
import 'bridge_card_face.dart';
import 'bridge_card_strip.dart';
import 'bridge_public_card_entrance.dart';
import 'bridge_trick_geometry.dart';
import 'bridge_auction_grid.dart';

/// The table widgets are deliberately presentation-only:
/// they receive a seat-filtered PlayerView, never Deal or BridgeSession.
class BridgeBoardHeader extends StatelessWidget {
  const BridgeBoardHeader({
    super.key,
    required this.boardNumber,
    required this.view,
    required this.busy,
    required this.copy,
  });

  final int boardNumber;
  final PlayerView view;
  final bool busy;
  final AppCopy copy;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('game_status'),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 24,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(copy.boardNumber(boardNumber), key: const Key('board_number')),
          Text(copy.dealer(view.dealer.letter), key: const Key('board_dealer')),
          Text(
            copy.vulnerability(view.vulnerability.name),
            key: const Key('board_vulnerability'),
          ),
          Text(copy.formatTurn(view.turn?.letter)),
          Text(copy.contract(view.contract?.label ?? copy.t('notYet'))),
          Text(copy.trickCount(view.completedTricks.length)),
          if (view.nsScore != null) Text(copy.score(view.nsScore!)),
          if (busy) const CircularProgressIndicator(strokeWidth: 2),
        ],
      ),
    ),
  );
}

/// Four seats and the public trick. A seat must never reconstruct hidden cards.
class BridgeTableSurface extends StatelessWidget {
  const BridgeTableSurface({
    super.key,
    required this.view,
    required this.copy,
    required this.actionsPaused,
    required this.onPlayCard,
  });

  final PlayerView view;
  final AppCopy copy;
  final bool actionsPaused;
  final ValueChanged<bridge.Card> onPlayCard;

  BridgeSeatPanel _seat(Seat seat) => BridgeSeatPanel(
    seat: seat,
    view: view,
    copy: copy,
    actionsPaused: actionsPaused,
    onPlayCard: onPlayCard,
  );

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('bridge_board'),
    color: const Color(0xFFD8E9DE),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // A side-seat half-column cannot hold exposed dummy cards on a
          // phone. Put current trick on its own row at narrow widths.
          final compact = constraints.maxWidth < 560;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _seat(Seat.north),
              if (compact) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _seat(Seat.west)),
                    const SizedBox(width: 8),
                    Expanded(child: _seat(Seat.east)),
                  ],
                ),
                view.phase == Phase.auction
                    ? BridgeAuctionGrid(view: view, copy: copy)
                    : BridgeCurrentTrick(view: view, copy: copy),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _seat(Seat.west)),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: view.phase == Phase.auction
                          ? BridgeAuctionGrid(view: view, copy: copy)
                          : BridgeCurrentTrick(view: view, copy: copy),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _seat(Seat.east)),
                  ],
                ),
              _seat(Seat.south),
            ],
          );
        },
      ),
    ),
  );
}

class BridgeCurrentTrick extends StatefulWidget {
  const BridgeCurrentTrick({
    super.key,
    required this.view,
    required this.copy,
    this.compact = false,
    this.geometry,
    this.showHeading = true,
  });
  final PlayerView view;
  final AppCopy copy;
  final bool compact;
  final BridgeTrickGeometry? geometry;
  final bool showHeading;

  @override
  State<BridgeCurrentTrick> createState() => _BridgeCurrentTrickState();
}

class _BridgeCurrentTrickState extends State<BridgeCurrentTrick> {
  Set<String> _entering = {};
  String _identity(PlayerView view, PlayedCard play) =>
      '${view.viewer.letter}:${view.completedTricks.length}:${play.handOwner.letter}:${play.card.code}';

  @override
  void didUpdateWidget(BridgeCurrentTrick oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.view;
    final current = widget.view;
    // Mounting/restoring a snapshot is static. Only newly accepted public
    // cards animate; removal disposes the animation, with no outgoing ghost.
    final existing = previous.currentTrick
        .map((play) => _identity(previous, play))
        .toSet();
    _entering =
        current.viewer == previous.viewer && current.version > previous.version
        ? current.currentTrick
              .map((play) => _identity(current, play))
              .where((id) => !existing.contains(id))
              .toSet()
        : {};
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final copy = widget.copy;
    final geometry = widget.geometry ?? const BridgeTrickGeometry();
    Widget played(PlayedCard play) => BridgePublicCardEntrance(
      key: ValueKey(_identity(view, play)),
      animate: _entering.contains(_identity(view, play)),
      from: widget.compact
          ? geometry.entranceFrom(play.handOwner)
          : const Offset(0, 12),
      child: Semantics(
        excludeSemantics: true,
        label:
            '${copy.seat(play.handOwner.letter)}: ${copy.cardName(play.card.code)}',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.compact) Text(copy.seat(play.handOwner.letter)),
            SizedBox(
              width: widget.compact ? geometry.cardSize.width : 54,
              height: widget.compact ? geometry.cardSize.height : 76,
              child: BridgeCardFace(card: play.card),
            ),
          ],
        ),
      ),
    );
    return Padding(
      key: const Key('current_trick'),
      padding: EdgeInsets.all(widget.compact ? 0 : 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showHeading)
            Text(
              copy.t('currentTrick'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          if (widget.showHeading) const SizedBox(height: 8),
          if (!widget.compact && view.currentTrick.isEmpty)
            Text(copy.t('notYet'))
          else if (widget.compact)
            SizedBox(
              key: const Key('focus_trick_compass'),
              width: geometry.size.width,
              height: geometry.size.height,
              child: Stack(
                children: [
                  for (final play in view.currentTrick)
                    Positioned(
                      left: geometry.position(play.handOwner).dx,
                      top: geometry.position(play.handOwner).dy,
                      child: played(play),
                    ),
                ],
              ),
            )
          else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [for (final play in view.currentTrick) played(play)],
            ),
        ],
      ),
    );
  }
}

class BridgeDummySuitPicker extends StatelessWidget {
  const BridgeDummySuitPicker({
    super.key,
    required this.id,
    required this.owner,
    required this.cards,
    required this.legalCards,
    required this.canAct,
    required this.copy,
    required this.selectedSuit,
    required this.onSuitSelected,
    required this.cardBuilder,
    this.suitsAnchor,
    this.expandedAnchor,
  });

  final String id;
  final Seat owner;
  final List<bridge.Card> cards;
  final List<bridge.Card> legalCards;
  final bool canAct;
  final AppCopy copy;
  final Suit? selectedSuit;
  final ValueChanged<Suit?> onSuitSelected;
  final Widget Function(bridge.Card card) cardBuilder;
  final GlobalKey? suitsAnchor;
  final GlobalKey? expandedAnchor;

  static const _suits = [Suit.spades, Suit.hearts, Suit.clubs, Suit.diamonds];

  String _symbol(Suit suit) => switch (suit) {
    Suit.spades => '♠',
    Suit.hearts => '♥',
    Suit.clubs => '♣',
    Suit.diamonds => '♦',
  };

  String _label(Suit suit) => copy.t(switch (suit) {
    Suit.spades => 'suitS',
    Suit.hearts => 'suitH',
    Suit.diamonds => 'suitD',
    Suit.clubs => 'suitC',
  });

  @override
  Widget build(BuildContext context) {
    final bySuit = {
      for (final suit in _suits)
        suit: cards.where((card) => card.suit == suit).toList(),
    };
    if (selectedSuit case final suit?) {
      final selectedCards = bySuit[suit]!;
      return KeyedSubtree(
        key: Key('${id}_dummy_choices'),
        child: KeyedSubtree(
          key: expandedAnchor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: Key('${id}_show_all_suits'),
                  onPressed: () => onSuitSelected(null),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(copy.t('showAllSuits')),
                ),
              ),
              BridgeCardStrip(
                centerWhenFits: true,
                id: '${id}_dummy_choice',
                copy: copy,
                children: [for (final card in selectedCards) cardBuilder(card)],
              ),
            ],
          ),
        ),
      );
    }

    return KeyedSubtree(
      key: suitsAnchor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columnWidth = constraints.maxWidth / _suits.length;
          final cardWidth = (columnWidth - 6).clamp(36.0, 46.0).toDouble();
          final cardHeight = cardWidth * 84 / 58;
          return Row(
            key: Key('${id}_dummy_suits'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final suit in _suits)
                Expanded(
                  child: _suitColumn(
                    context: context,
                    suit: suit,
                    cards: bySuit[suit]!,
                    width: columnWidth,
                    cardWidth: cardWidth,
                    cardHeight: cardHeight,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _suitColumn({
    required BuildContext context,
    required Suit suit,
    required List<bridge.Card> cards,
    required double width,
    required double cardWidth,
    required double cardHeight,
  }) {
    final enabled = canAct && cards.any(legalCards.contains);
    final dimmed =
        canAct && cards.isNotEmpty && !cards.any(legalCards.contains);
    final suitLabel = _label(suit);
    return Semantics(
      key: Key('focus_dummy_suit_semantics_${suit.name}'),
      label:
          '$suitLabel, ${copy.remaining(cards.length)}'
          '${enabled ? ', ${copy.t('legalDummySuit')}' : ''}',
      button: true,
      selected: false,
      enabled: enabled,
      child: Tooltip(
        message: '$suitLabel · ${cards.length}',
        child: InkWell(
          key: Key('focus_dummy_suit_${suit.name}'),
          borderRadius: BorderRadius.circular(8),
          onTap: enabled
              ? () {
                  onSuitSelected(suit);
                }
              : null,
          child: Opacity(
            opacity: dimmed ? .42 : 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: enabled
                    ? const Color(0xFF70D9CA).withValues(alpha: .1)
                    : Colors.transparent,
                border: Border.all(
                  color: enabled ? const Color(0xFF70D9CA) : Colors.white24,
                  width: enabled ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                key: Key('${id}_dummy_suit_cards_${suit.name}'),
                width: width,
                height:
                    24 +
                    (cards.isEmpty ? 0 : cardHeight + (cards.length - 1) * 20),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 22,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_symbol(suit)}  ${cards.length}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    suit == Suit.hearts || suit == Suit.diamonds
                                    ? const Color(0xFFFF8990)
                                    : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (enabled &&
                              MediaQuery.textScalerOf(context).scale(14) <= 19)
                            Icon(
                              Icons.check_circle,
                              key: Key('focus_dummy_legal_suit_${suit.name}'),
                              color: const Color(0xFF70D9CA),
                              size: 12,
                            ),
                        ],
                      ),
                    ),
                    if (cards.isEmpty)
                      Positioned.fill(
                        top: 22,
                        child: Center(
                          child: Text(
                            copy.t('emptySuit'),
                            style: const TextStyle(color: Colors.white60),
                          ),
                        ),
                      ),
                    for (var index = 0; index < cards.length; index++)
                      Positioned(
                        left: (width - cardWidth) / 2,
                        top: 22 + index * 20,
                        width: cardWidth,
                        height: cardHeight,
                        child: IgnorePointer(
                          child: BridgeCardFace(card: cards[index]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BridgeSeatPanel extends StatefulWidget {
  const BridgeSeatPanel({
    super.key,
    required this.seat,
    required this.view,
    required this.copy,
    required this.actionsPaused,
    required this.onPlayCard,
  });
  final Seat seat;
  final PlayerView view;
  final AppCopy copy;
  final bool actionsPaused;
  final ValueChanged<bridge.Card> onPlayCard;

  @override
  State<BridgeSeatPanel> createState() => _BridgeSeatPanelState();
}

class _BridgeSeatPanelState extends State<BridgeSeatPanel> {
  Suit? _selectedDummySuit;

  @override
  void didUpdateWidget(BridgeSeatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.view.version != widget.view.version ||
        oldWidget.actionsPaused != widget.actionsPaused ||
        oldWidget.view.viewer != widget.view.viewer) {
      _selectedDummySuit = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final seat = widget.seat;
    final view = widget.view;
    final copy = widget.copy;
    final actionsPaused = widget.actionsPaused;
    final onPlayCard = widget.onPlayCard;
    final isDummy = view.contract?.dummy == seat && view.dummyExposed;
    final hasDummyCards = isDummy && view.dummyCards != null;
    final active = view.turn == seat;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: copy.seatSummary(
        seat.letter,
        active: active,
        viewer: seat == view.viewer,
        dummy: hasDummyCards,
        remaining: view.remainingCards[seat] ?? 0,
      ),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        key: Key('seat_${seat.letter}'),
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: active ? Theme.of(context).colorScheme.primary : Colors.grey,
            width: active ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              copy.seat(seat.letter),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (active)
              Text(
                copy.t('activeSeat'),
                key: Key('active_seat_${seat.letter}'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            if (seat == view.viewer)
              Text(copy.t('yourSeat'))
            else if (!hasDummyCards)
              Text(
                copy.remaining(view.remainingCards[seat] ?? 0),
                textAlign: TextAlign.center,
              ),
            if (hasDummyCards && seat != view.viewer) ...[
              Text(copy.t('dummy'), key: const Key('dummy_revealed')),
              BridgeDummySuitPicker(
                id: 'focus_${seat.letter}',
                owner: seat,
                cards: sortedVisibleCards(view.dummyCards!),
                legalCards: view.legalCards,
                canAct: view.canAct && active && !actionsPaused,
                copy: copy,
                selectedSuit: _selectedDummySuit,
                onSuitSelected: (suit) =>
                    setState(() => _selectedDummySuit = suit),
                cardBuilder: (card) => BridgePlayingCardButton(
                  card: card,
                  prefix: 'dummy_card_',
                  copy: copy,
                  legal:
                      view.canAct && active && view.legalCards.contains(card),
                  busy: actionsPaused,
                  onTap: () => onPlayCard(card),
                ),
              ),
            ],
            if (seat != view.viewer && !hasDummyCards)
              const Icon(Icons.style_outlined),
          ],
        ),
      ),
    );
  }
}

class BridgePlayerHand extends StatefulWidget {
  const BridgePlayerHand({
    super.key,
    required this.view,
    required this.copy,
    required this.actionsPaused,
    required this.onPlayCard,
  });
  final PlayerView view;
  final AppCopy copy;
  final bool actionsPaused;
  final ValueChanged<bridge.Card> onPlayCard;

  @override
  State<BridgePlayerHand> createState() => _BridgePlayerHandState();
}

class _BridgePlayerHandState extends State<BridgePlayerHand> {
  bridge.Card? _selected;

  @override
  void didUpdateWidget(BridgePlayerHand oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.view.version != widget.view.version ||
        oldWidget.actionsPaused != widget.actionsPaused ||
        oldWidget.view.viewer != widget.view.viewer) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = sortedVisibleCards(widget.view.ownCards);
    return Card(
      key: const Key('hand_controls'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(widget.copy.t('cards'))),
                if (_selected != null)
                  FilledButton(
                    key: const Key('hand_confirm_card'),
                    onPressed:
                        widget.view.canAct &&
                            widget.view.legalCards.contains(_selected) &&
                            !widget.actionsPaused
                        ? () => widget.onPlayCard(_selected!)
                        : null,
                    child: Text(widget.copy.t('confirmPlay')),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            BridgeCardStrip(
              useFan: true,
              compactFan: true,
              selectedIndex: _selected == null
                  ? null
                  : cards.indexOf(_selected!),
              id: 'hand',
              copy: widget.copy,
              children: [
                for (final card in cards)
                  BridgePlayingCardButton(
                    card: card,
                    prefix: 'hand_card_',
                    copy: widget.copy,
                    legal:
                        widget.view.canAct &&
                        widget.view.turn == widget.view.viewer &&
                        widget.view.legalCards.contains(card),
                    busy: widget.actionsPaused,
                    onTap: () {
                      final dense =
                          MediaQuery.sizeOf(context).width < 700 &&
                          MediaQuery.textScalerOf(context).scale(14) <= 19;
                      if (dense && _selected != card) {
                        setState(() => _selected = card);
                      } else {
                        widget.onPlayCard(card);
                      }
                    },
                  ),
              ],
            ),
            if (widget.view.contract != null && !widget.view.dummyExposed)
              Text(widget.copy.t('hidden'), key: const Key('dummy_hidden')),
          ],
        ),
      ),
    );
  }
}

class BridgePlayingCardButton extends StatelessWidget {
  const BridgePlayingCardButton({
    super.key,
    required this.card,
    required this.prefix,
    required this.copy,
    required this.legal,
    required this.busy,
    required this.onTap,
    this.dragEnabled = false,
  });
  final bridge.Card card;
  final String prefix;
  final AppCopy copy;
  final bool legal;
  final bool busy;
  final VoidCallback onTap;
  final bool dragEnabled;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: copy.accessibleCard(card.code, playable: legal && !busy),
    button: true,
    enabled: legal && !busy,
    excludeSemantics: true,
    onTap: legal && !busy ? onTap : null,
    child: Tooltip(
      // A long-press tooltip would win the gesture arena over the parent drag.
      triggerMode: dragEnabled ? TooltipTriggerMode.manual : null,
      message: copy.formatCard(card.code, legal: legal && !busy),
      excludeFromSemantics: true,
      child: OutlinedButton(
        key: Key(prefix + card.code),
        onPressed: legal && !busy ? onTap : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(2),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          side: BorderSide(
            color: legal && !busy
                ? Theme.of(context).colorScheme.primary
                : const Color(0xFF9BAAA2),
            width: legal && !busy ? 2 : 1,
          ),
        ),
        // Preserve text geometry when legality changes mid-bot turn.
        child: SizedBox(
          width: 58,
          height: 84,
          child: Stack(
            children: [
              Positioned.fill(child: BridgeCardFace(card: card)),
              Positioned(
                right: 2,
                bottom: 2,
                child: ExcludeSemantics(
                  child: Icon(
                    legal && !busy ? Icons.check_circle : Icons.lock_outline,
                    size: 16,
                    color: legal && !busy
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFF62746A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Sort a copy of the permitted projection; never touch Core's card order.
List<bridge.Card> sortedVisibleCards(List<bridge.Card> visible) =>
    [...visible]..sort((a, b) {
      const order = [Suit.spades, Suit.hearts, Suit.diamonds, Suit.clubs];
      final suit = order.indexOf(a.suit).compareTo(order.indexOf(b.suit));
      return suit != 0 ? suit : b.rank.index.compareTo(a.rank.index);
    });

String bridgeCardText(bridge.Card card) =>
    (switch (card.suit) {
      Suit.clubs => '♣',
      Suit.diamonds => '♦',
      Suit.hearts => '♥',
      Suit.spades => '♠',
    }) +
    card.rank.symbol;
