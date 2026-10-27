import 'package:bridge_core/bridge_core.dart' as bridge;
import 'package:flutter/material.dart';
import 'package:playing_cards/playing_cards.dart' as cards;

/// One-way presentation adapter. The renderer never deals or validates cards.
cards.PlayingCard displayCard(bridge.Card card) => cards.PlayingCard(
  switch (card.suit) {
    bridge.Suit.spades => cards.Suit.spades,
    bridge.Suit.hearts => cards.Suit.hearts,
    bridge.Suit.diamonds => cards.Suit.diamonds,
    bridge.Suit.clubs => cards.Suit.clubs,
  },
  switch (card.rank) {
    bridge.Rank.two => cards.CardValue.two,
    bridge.Rank.three => cards.CardValue.three,
    bridge.Rank.four => cards.CardValue.four,
    bridge.Rank.five => cards.CardValue.five,
    bridge.Rank.six => cards.CardValue.six,
    bridge.Rank.seven => cards.CardValue.seven,
    bridge.Rank.eight => cards.CardValue.eight,
    bridge.Rank.nine => cards.CardValue.nine,
    bridge.Rank.ten => cards.CardValue.ten,
    bridge.Rank.jack => cards.CardValue.jack,
    bridge.Rank.queen => cards.CardValue.queen,
    bridge.Rank.king => cards.CardValue.king,
    bridge.Rank.ace => cards.CardValue.ace,
  },
);

/// Use glyphs for ALL ranks/suits, including court cards, rather than upstream
/// Wikimedia imagery whose individual provenance still needs release review.
final _cardStyle = _makeCardStyle(false);
final _indexCardStyle = _makeCardStyle(true);

cards.PlayingCardViewStyle _makeCardStyle(bool indexOnly) =>
    cards.PlayingCardViewStyle(
      cardBackgroundColor: const Color(0xFFFFFDF8),
      surfaceTintColor: Colors.transparent,
      suitStyles: {
        for (final entry in [
          (cards.Suit.spades, '♠', false),
          (cards.Suit.hearts, '♥', true),
          (cards.Suit.diamonds, '♦', true),
          (cards.Suit.clubs, '♣', false),
        ])
          entry.$1: cards.SuitStyle(
            style: TextStyle(
              color: entry.$3
                  ? const Color(0xFFA52837)
                  : const Color(0xFF192D30),
            ),
            builder: (_) => FittedBox(
              child: Text(
                entry.$2,
                style: TextStyle(
                  color: entry.$3
                      ? const Color(0xFFA52837)
                      : const Color(0xFF192D30),
                ),
              ),
            ),
            cardContentBuilders: {
              for (final value in cards.CardValue.values)
                value: (_) => indexOnly
                    ? const SizedBox.shrink()
                    : Center(
                        child: FittedBox(
                          child: DefaultTextStyle(
                            style: TextStyle(
                              fontSize: 26,
                              height: 1,
                              color: entry.$3
                                  ? const Color(0xFFA52837)
                                  : const Color(0xFF192D30),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _rankLabel(value),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(entry.$2),
                              ],
                            ),
                          ),
                        ),
                      ),
            },
          ),
      },
    );

String _rankLabel(cards.CardValue value) => switch (value) {
  cards.CardValue.ace => 'A',
  cards.CardValue.king => 'K',
  cards.CardValue.queen => 'Q',
  cards.CardValue.jack => 'J',
  cards.CardValue.joker_1 || cards.CardValue.joker_2 => '',
  _ => '${value.index + 2}',
};

class BridgeCardFace extends StatelessWidget {
  const BridgeCardFace({
    super.key,
    required this.card,
    this.prominentIndex = false,
  });
  final bridge.Card card;
  final bool prominentIndex;

  @override
  Widget build(BuildContext context) {
    final face = cards.PlayingCardView(
      card: displayCard(card),
      style: prominentIndex ? _indexCardStyle : _cardStyle,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
    if (!prominentIndex) return ExcludeSemantics(child: face);
    final symbol = switch (card.suit) {
      bridge.Suit.spades => '♠',
      bridge.Suit.hearts => '♥',
      bridge.Suit.diamonds => '♦',
      bridge.Suit.clubs => '♣',
    };
    final red =
        card.suit == bridge.Suit.hearts || card.suit == bridge.Suit.diamonds;
    return ExcludeSemantics(
      child: Stack(
        children: [
          Positioned.fill(child: face),
          Positioned(
            left: 2,
            top: 2,
            width: 16,
            height: 42,
            child: ColoredBox(
              color: const Color(0xFFFFFDF8),
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: red
                      ? const Color(0xFFA52837)
                      : const Color(0xFF192D30),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: FittedBox(
                        child: Text(
                          card.rank == bridge.Rank.ten
                              ? '10'
                              : card.rank.symbol,
                        ),
                      ),
                    ),
                    Expanded(child: FittedBox(child: Text(symbol))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
