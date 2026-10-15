import 'dart:math';

enum Seat {
  north, east, south, west;
  Seat get next => Seat.values[(index + 1) % 4];
  Seat get partner => Seat.values[(index + 2) % 4];
  bool get isNS => this == north || this == south;
  bool get isEW => !isNS;
  static Seat fromLetter(String letter) {
    switch (letter.toUpperCase()) {
      case 'N': return north;
      case 'E': return east;
      case 'S': return south;
      case 'W': return west;
      default: throw FormatException('Invalid seat: $letter');
    }
  }
  String get letter => ['N', 'E', 'S', 'W'][index];
}

enum Suit {
  clubs, diamonds, hearts, spades;
  String get pbn => ['C', 'D', 'H', 'S'][index];
}

enum Strain {
  clubs, diamonds, hearts, spades, notrump;
  Suit? get trump => index == 4 ? null : Suit.values[index];
  String get code => ['C', 'D', 'H', 'S', 'NT'][index];
}

enum Rank {
  two('2'), three('3'), four('4'), five('5'), six('6'),
  seven('7'), eight('8'), nine('9'), ten('T'),
  jack('J'), queen('Q'), king('K'), ace('A');
  const Rank(this.symbol);
  final String symbol;
  static Rank fromSymbol(String symbol) {
    for (final rank in values) {
      if (rank.symbol == symbol.toUpperCase()) return rank;
    }
    throw FormatException('Invalid rank: $symbol');
  }
}

class Card {
  const Card(this.suit, this.rank);
  final Suit suit;
  final Rank rank;
  String get code => '${suit.pbn}${rank.symbol}';
  @override
  bool operator ==(Object other) =>
      other is Card && other.suit == suit && other.rank == rank;
  @override
  int get hashCode => Object.hash(suit, rank);
  @override
  String toString() => code;
}

enum Vulnerability {
  none, ns, ew, both;
  bool isVulnerable(Seat seat) =>
      this == both || (this == ns && seat.isNS) ||
      (this == ew && seat.isEW);
}
enum Doubling { none, doubled, redoubled }

class Contract {
  const Contract({required this.level, required this.strain,
      required this.declarer, this.doubling = Doubling.none})
      : assert(level >= 1 && level <= 7);
  final int level;
  final Strain strain;
  final Seat declarer;
  final Doubling doubling;
  Seat get dummy => declarer.partner;
  Seat get openingLeader => declarer.next;
  int get targetTricks => level + 6;
  String get label {
    final suffix = doubling == Doubling.doubled ? 'X' :
        doubling == Doubling.redoubled ? 'XX' : '';
    return '$level${strain.code}$suffix';
  }
}

sealed class Call {
  const Call();
  String get code;
}
final class Pass extends Call {
  const Pass();
  @override
  String get code => 'PASS';
}
final class Bid extends Call {
  const Bid(this.level, this.strain) : assert(level >= 1 && level <= 7);
  final int level;
  final Strain strain;
  @override
  String get code => '$level${strain.code}';
}
final class DoubleCall extends Call {
  const DoubleCall();
  @override
  String get code => 'X';
}
final class RedoubleCall extends Call {
  const RedoubleCall();
  @override
  String get code => 'XX';
}

class AuctionEntry {
  const AuctionEntry(this.seat, this.call);
  final Seat seat;
  final Call call;
}
class PlayedCard {
  const PlayedCard(this.handOwner, this.actor, this.card);
  final Seat handOwner;
  final Seat actor;
  final Card card;
}
class Trick {
  const Trick(this.plays, this.winner);
  final List<PlayedCard> plays;
  final Seat winner;
}

sealed class GameAction {
  const GameAction();
  Seat get actor;
  String get code;
}
final class CallAction extends GameAction {
  const CallAction(this.actor, this.call);
  @override
  final Seat actor;
  final Call call;
  @override
  String get code => 'B:${actor.letter}:${call.code}';
}
final class CardAction extends GameAction {
  const CardAction(this.actor, this.handOwner, this.card);
  @override
  final Seat actor;
  final Seat handOwner;
  final Card card;
  @override
  String get code => 'P:${actor.letter}:${handOwner.letter}:${card.code}';
}
class GameEvent {
  const GameEvent(this.version, this.action);
  final int version;
  final GameAction action;
  String get canonical => '$version:${action.code}';
}

class Deal {
  factory Deal(Map<Seat, Iterable<Card>> supplied) {
    if (supplied.length != 4 || !Seat.values.every(supplied.containsKey)) {
      throw ArgumentError('Deal must contain exactly four seats');
    }
    final seen = <Card>{};
    final result = <Seat, Set<Card>>{};
    for (final seat in Seat.values) {
      final cards = supplied[seat]!.toList();
      if (cards.length != 13 || cards.toSet().length != 13) {
        throw ArgumentError('Each seat must own 13 unique cards');
      }
      if (cards.any((card) => !seen.add(card))) {
        throw ArgumentError('Card appears in multiple hands');
      }
      result[seat] = Set.unmodifiable(cards);
    }
    if (seen.length != 52) throw ArgumentError('52 unique cards required');
    return Deal._(Map.unmodifiable(result));
  }
  const Deal._(this.hands);
  final Map<Seat, Set<Card>> hands;

  /// PBN four hands clockwise; each hand follows S.H.D.C suit order.
  factory Deal.fromPbn(String pbn) {
    final parts = pbn.trim().split(RegExp(r'\s+'));
    if (parts.length != 4 || parts.first.length < 2 ||
        parts.first[1] != ':') {
      throw FormatException('Expected PBN: N:<hand> <hand> <hand> <hand>');
    }
    final start = Seat.fromLetter(parts.first[0]);
    final result = <Seat, List<Card>>{};
    for (var i = 0; i < 4; i++) {
      final encoded = i == 0 ? parts[i].substring(2) : parts[i];
      final suits = encoded.split('.');
      if (suits.length != 4) throw FormatException('PBN requires S.H.D.C');
      final cards = <Card>[];
      for (var s = 0; s < 4; s++) {
        final suit = [Suit.spades, Suit.hearts, Suit.diamonds, Suit.clubs][s];
        for (final char in suits[s].toUpperCase().split('')) {
          if (char.isEmpty) continue;
          cards.add(Card(suit, Rank.fromSymbol(char)));
        }
      }
      result[Seat.values[(start.index + i) % 4]] = cards;
    }
    return Deal(result);
  }

  String toPbn() {
    final parts = <String>[];
    for (final seat in Seat.values) {
      final cards = hands[seat]!;
      final groups = <String>[];
      for (final suit in [Suit.spades, Suit.hearts, Suit.diamonds, Suit.clubs]) {
        final ranks = cards.where((c) => c.suit == suit)
            .map((c) => c.rank).toList()
          ..sort((a, b) => b.index.compareTo(a.index));
        groups.add(ranks.map((r) => r.symbol).join());
      }
      parts.add(groups.join('.'));
    }
    return 'N:${parts.join(' ')}';
  }

  /// Fresh local training deal. A supplied seed is intended for tests;
  /// retain toPbn() for exact replay across SDK/runtime revisions.
  /// An unseeded deal uses platform secure randomness; the local client's
  /// privileged deal must never be confused with a server fair-play model.
  factory Deal.shuffled({int? seed}) {
    final cards = [
      for (final suit in Suit.values)
        for (final rank in Rank.values) Card(suit, rank),
    ]..shuffle(seed == null ? Random.secure() : Random(seed));
    return Deal({
      for (var i = 0; i < Seat.values.length; i++)
        Seat.values[i]: cards.sublist(i * 13, (i + 1) * 13),
    });
  }

  /// Deterministic fixture, not an RNG-generated competitive deal.
  factory Deal.suitPerSeat() => Deal({
    Seat.north: Rank.values.map((r) => Card(Suit.clubs, r)),
    Seat.east: Rank.values.map((r) => Card(Suit.diamonds, r)),
    Seat.south: Rank.values.map((r) => Card(Suit.hearts, r)),
    Seat.west: Rank.values.map((r) => Card(Suit.spades, r)),
  });
}

Map<Seat, Set<Card>> frozenHands(Map<Seat, Set<Card>> hands) =>
    Map.unmodifiable({
      for (final entry in hands.entries)
        entry.key: Set<Card>.unmodifiable(entry.value)
    });

