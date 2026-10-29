import 'package:bridge_core/bridge_core.dart' as bridge;
import 'package:flutter/material.dart';
import 'package:playing_cards/playing_cards.dart' as cards;

/// One-way adapter to the pinned playing_cards renderer. This widget only
/// translates an already-authorized Core card; it never deals or validates.
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

/// Uses the package's complete rank, pip and court-card view. The package is
/// Apache-2.0; its bundled Wikimedia card imagery has a separate release audit
/// gate recorded in RESEARCH_REPORTS.md.
class BridgeCardFace extends StatelessWidget {
  const BridgeCardFace({super.key, required this.card});
  final bridge.Card card;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: cards.PlayingCardView(
      card: displayCard(card),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  );
}
