import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:bridge_core/bridge_core.dart' as bridge show Card;
import 'package:flutter/material.dart';

import '../app_copy.dart';
import 'bridge_card_face.dart';
import 'bridge_card_strip.dart';
import 'bridge_public_card_entrance.dart';

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
              Text(copy.boardNumber(boardNumber),
                  key: const Key('board_number')),
              Text(copy.dealer(view.dealer.letter),
                  key: const Key('board_dealer')),
              Text(copy.vulnerability(view.vulnerability.name),
                  key: const Key('board_vulnerability')),
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
                    BridgeCurrentTrick(view: view, copy: copy),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _seat(Seat.west)),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: BridgeCurrentTrick(view: view, copy: copy),
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
  const BridgeCurrentTrick({super.key, required this.view, required this.copy});
  final PlayerView view;
  final AppCopy copy;

  @override
  State<BridgeCurrentTrick> createState() => _BridgeCurrentTrickState();
}

class _BridgeCurrentTrickState extends State<BridgeCurrentTrick> {
  Set<String> _entering = {};
  String _identity(PlayerView view, PlayedCard play) =>
      '${view.completedTricks.length}:${play.handOwner.letter}:${play.card.code}';

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
    _entering = current.version > previous.version
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
    return Padding(
      key: const Key('current_trick'),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            copy.t('currentTrick'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (view.currentTrick.isEmpty)
            Text(copy.t('notYet'))
          else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final play in view.currentTrick)
                  BridgePublicCardEntrance(
                    key: ValueKey(_identity(view, play)),
                    animate: _entering.contains(_identity(view, play)),
                    child: Semantics(
                      excludeSemantics: true,
                      label:
                          '${copy.seat(play.handOwner.letter)}: ${copy.cardName(play.card.code)}',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(copy.seat(play.handOwner.letter)),
                          SizedBox(
                            width: 54,
                            height: 76,
                            child: BridgeCardFace(card: play.card),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class BridgeSeatPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDummy = view.contract?.dummy == seat && view.dummyExposed;
    final hasDummyCards = isDummy && view.dummyCards != null;
    final active = view.turn == seat;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: copy.seatSummary(seat.letter,
          active: active, viewer: seat == view.viewer,
          dummy: hasDummyCards, remaining: view.remainingCards[seat] ?? 0),
      child: AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero : const Duration(milliseconds: 180),
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
          Text(copy.seat(seat.letter),
              maxLines: 2, textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          if (active)
            Text(copy.t('activeSeat'),
                key: Key('active_seat_${seat.letter}'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          if (seat == view.viewer)
            Text(copy.t('yourSeat'))
          else if (!hasDummyCards)
            Text(copy.remaining(view.remainingCards[seat] ?? 0),
                textAlign: TextAlign.center),
          if (hasDummyCards && seat != view.viewer) ...[
            Text(copy.t('dummy'), key: const Key('dummy_revealed')),
            BridgeCardStrip(
              id: 'dummy_${seat.letter}',
              copy: copy,
              centerWhenFits: true,
              children: [
                for (final card in sortedVisibleCards(view.dummyCards!))
                  BridgePlayingCardButton(
                    card: card,
                    prefix: 'dummy_card_',
                    copy: copy,
                    legal: view.canAct && active &&
                        view.legalCards.contains(card),
                    busy: actionsPaused,
                    onTap: () => onPlayCard(card),
                  ),
              ],
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

class BridgePlayerHand extends StatelessWidget {
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
  Widget build(BuildContext context) => Card(
        key: const Key('hand_controls'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.t('cards')),
              const SizedBox(height: 8),
              BridgeCardStrip(
                id: 'hand',
                copy: copy,
                children: [
                  for (final card in sortedVisibleCards(view.ownCards))
                    BridgePlayingCardButton(
                      card: card,
                      prefix: 'hand_card_',
                      copy: copy,
                      legal: view.canAct && view.turn == view.viewer &&
                          view.legalCards.contains(card),
                      busy: actionsPaused,
                      onTap: () => onPlayCard(card),
                    ),
                ],
              ),
              if (view.contract != null && !view.dummyExposed)
                Text(copy.t('hidden'), key: const Key('dummy_hidden')),
            ],
          ),
        ),
      );
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
  });
  final bridge.Card card;
  final String prefix;
  final AppCopy copy;
  final bool legal;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: copy.accessibleCard(card.code, playable: legal && !busy),
    button: true,
    enabled: legal && !busy,
    excludeSemantics: true,
    onTap: legal && !busy ? onTap : null,
    child: Tooltip(
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
