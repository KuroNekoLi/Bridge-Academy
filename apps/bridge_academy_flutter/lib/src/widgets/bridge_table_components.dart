import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:bridge_core/bridge_core.dart' as bridge show Card;
import 'package:flutter/material.dart';

import '../app_copy.dart';

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
        color: const Color(0xFFE6F1E8),
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

class BridgeCurrentTrick extends StatelessWidget {
  const BridgeCurrentTrick({
    super.key, required this.view, required this.copy,
  });
  final PlayerView view;
  final AppCopy copy;

  @override
  Widget build(BuildContext context) => Padding(
        key: const Key('current_trick'),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(copy.t('currentTrick'),
                style: Theme.of(context).textTheme.titleSmall),
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
                    Chip(
                      label: Text(
                        '${play.handOwner.letter}: ${bridgeCardText(play.card)}',
                      ),
                    ),
                ],
              ),
          ],
        ),
      );
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
    return Container(
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
          if (seat == view.viewer)
            Text(copy.t('yourSeat'))
          else if (!hasDummyCards)
            Text(copy.remaining(view.remainingCards[seat] ?? 0),
                textAlign: TextAlign.center),
          if (hasDummyCards && seat != view.viewer) ...[
            Text(copy.t('dummy'), key: const Key('dummy_revealed')),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              children: [
                for (final card in view.dummyCards!)
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
              Wrap(
                spacing: 6,
                runSpacing: 5,
                children: [
                  for (final card in view.ownCards)
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
  Widget build(BuildContext context) => Tooltip(
        message: copy.formatCard(card.code, legal: legal && !busy),
        child: OutlinedButton(
          key: Key(prefix + card.code),
          onPressed: legal && !busy ? onTap : null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: const Size(42, 40),
          ),
          // Preserve text geometry when legality changes mid-bot turn.
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(bridgeCardText(card)),
              const SizedBox(width: 3),
              ExcludeSemantics(
                child: Icon(
                  Icons.check,
                  size: 13,
                  color: legal
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      );
}

String bridgeCardText(bridge.Card card) =>
    (switch (card.suit) {
      Suit.clubs => '♣',
      Suit.diamonds => '♦',
      Suit.hearts => '♥',
      Suit.spades => '♠',
    }) + card.rank.symbol;
