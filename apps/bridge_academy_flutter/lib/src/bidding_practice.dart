import 'package:bridge_core/bridge_core.dart';

/// Small, unreviewed natural-NT teaching profile; not BEN or full SAYC.
abstract final class BiddingPracticeProfile {
  static const id = 'BA-NATURAL-NT';
  static const revision = 1;

  static int hcp(Iterable<Card> cards) => cards.fold(0, (points, card) =>
      points + (switch (card.rank) {
        Rank.ace => 4, Rank.king => 3, Rank.queen => 2,
        Rank.jack => 1, _ => 0,
      }));

  static bool balanced(Iterable<Card> cards) {
    final lengths = [for (final suit in Suit.values)
      cards.where((card) => card.suit == suit).length]..sort();
    return const ['3-3-3-4', '2-3-4-4', '2-3-3-5']
        .contains(lengths.join('-'));
  }

  /// Reads only the actor's PlayerView, never the privileged Deal.
  static Call suggest(PlayerView view) {
    if (view.phase != Phase.auction || !view.canAct) return const Pass();
    final points = hcp(view.ownCards);
    final auction = view.auction;
    if (auction.every((entry) => entry.call is Pass)) {
      return points >= 15 && points <= 17 && balanced(view.ownCards)
          ? const Bid(1, Strain.notrump) : const Pass();
    }
    final bids = auction.where((e) => e.call is! Pass).toList();
    if (bids.length == 1 && bids.single.seat == view.viewer.partner &&
        bids.single.call.code == '1NT') {
      if (points >= 10) return const Bid(3, Strain.notrump);
      if (points >= 8) return const Bid(2, Strain.notrump);
    }
    if (bids.length == 2 && bids.first.seat == view.viewer &&
        bids.first.call.code == '1NT' &&
        bids.last.seat == view.viewer.partner &&
        bids.last.call.code == '2NT' && points == 17) {
      return const Bid(3, Strain.notrump);
    }
    return const Pass();
  }

  /// Only interpret agreements with exact uncontested public auction context.
  static String explain(List<AuctionEntry> auction) {
    if (auction.isEmpty) return 'biddingUnknown';
    var index = auction.length - 1;
    while (index >= 0 && auction[index].call is Pass) {
      index--;
    }
    if (index < 0) return 'biddingUnknown';
    final last = auction[index];
    final before = auction.take(index).toList();
    if (last.call.code == '1NT' &&
        before.every((entry) => entry.call is Pass)) {
      return 'biddingOpening1NT';
    }
    final bids = before.where((entry) => entry.call is! Pass).toList();
    if (bids.length == 1 && bids.first.call.code == '1NT' &&
        bids.first.seat.partner == last.seat) {
      if (last.call.code == '2NT') return 'biddingInvite2NT';
      if (last.call.code == '3NT') return 'biddingGame3NT';
    }
    if (bids.length == 2 && bids.first.call.code == '1NT' &&
        bids.last.call.code == '2NT' &&
        bids.first.seat == last.seat &&
        bids.first.seat.partner == bids.last.seat &&
        last.call.code == '3NT') {
      return 'biddingAccept3NT';
    }
    return 'biddingUnknown';
  }
}

/// The bot proposes; Bridge Core validates. There is no play-stage fallback.
final class BiddingPracticeBot implements BotPolicy {
  const BiddingPracticeBot();

  @override
  Future<GameAction> choose(PlayerView view) async {
    if (!view.canAct || view.phase != Phase.auction) {
      throw const RuleViolation('Bidding practice is auction-only');
    }
    return CallAction(view.viewer, BiddingPracticeProfile.suggest(view));
  }
}
