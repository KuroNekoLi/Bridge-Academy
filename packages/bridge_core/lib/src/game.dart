import 'model.dart';
import 'scoring.dart';

enum Phase { auction, play, finished }

class RuleViolation implements Exception {
  const RuleViolation(this.message);
  final String message;
  @override
  String toString() => 'RuleViolation: $message';
}

/// A fully immutable game snapshot. Full hands must not be sent to clients.
/// Player-visible projections belong to a separate, privacy-checked adapter.
class GameState {
  GameState._({
    required this.deal,
    required this.dealer,
    required this.vulnerability,
    required this.phase,
    required this.turn,
    required this.contract,
    required this.initialTrainingContract,
    required this.hands,
    required List<AuctionEntry> auction,
    required List<PlayedCard> currentTrick,
    required List<Trick> tricks,
    required List<GameEvent> events,
    required this.nsScore,
  }) : auction = List.unmodifiable(auction),
       currentTrick = List.unmodifiable(currentTrick),
       tricks = List.unmodifiable(tricks),
       events = List.unmodifiable(events);

  factory GameState.start(Deal deal, Seat dealer, Vulnerability vulnerability) {
    return GameState._(
      deal: deal, dealer: dealer, vulnerability: vulnerability,
      phase: Phase.auction, turn: dealer, contract: null,
      initialTrainingContract: null,
      hands: frozenHands(deal.hands), auction: const [], currentTrick: const [],
      tricks: const [], events: const [], nsScore: null,
    );
  }

  /// Starts directly at play for a named, explicit training contract.
  /// No auction events are invented; this mode is never a ranked result.
  factory GameState.justDeclareStart(
    Deal deal, Seat dealer, Vulnerability vulnerability, Contract contract,
  ) {
    if (contract.level < 1 || contract.level > 7 ||
        contract.doubling != Doubling.none) {
      throw const RuleViolation('Invalid training contract');
    }
    return GameState._(
      deal: deal, dealer: dealer, vulnerability: vulnerability,
      phase: Phase.play, turn: contract.openingLeader,
      contract: contract, initialTrainingContract: contract,
      hands: frozenHands(deal.hands), auction: const [],
      currentTrick: const [], tricks: const [], events: const [],
      nsScore: null,
    );
  }

  final Deal deal;
  final Seat dealer;
  final Vulnerability vulnerability;
  final Phase phase;
  final Seat? turn;
  final Contract? contract;
  /// Non-null only for a preconfigured declarer-training deal.
  final Contract? initialTrainingContract;
  bool get isJustDeclare => initialTrainingContract != null;
  final Map<Seat, Set<Card>> hands;
  final List<AuctionEntry> auction;
  final List<PlayedCard> currentTrick;
  final List<Trick> tricks;
  final List<GameEvent> events;
  final int? nsScore;
  int get version => events.length;
  bool get isPassOut => phase == Phase.finished && contract == null;
  bool get isFinished => phase == Phase.finished;
  bool get dummyExposed =>
      contract != null && (currentTrick.isNotEmpty || tricks.isNotEmpty);
  Seat? get actorToPlay => phase != Phase.play ? turn :
      turn == contract!.dummy ? contract!.declarer : turn;

  /// Only valid legal moves for the current hand owner, never another seat.
  Set<Card> legalCards(Seat owner) {
    if (phase != Phase.play || owner != turn) return const <Card>{};
    final held = hands[owner]!;
    if (currentTrick.isEmpty) return Set.unmodifiable(held);
    final led = currentTrick.first.card.suit;
    final follows = held.where((c) => c.suit == led).toSet();
    return Set.unmodifiable(follows.isEmpty ? held : follows);
  }

  /// Non-cryptographic deterministic fingerprint of initial PBN + event log.
  /// This is for regression/replay, NOT security, authentication or consensus.
  String get historyFingerprint {
    final prefix = initialTrainingContract == null ? '' :
        'JUST_DECLARE:${initialTrainingContract!.label}:'
        '${initialTrainingContract!.declarer.letter}|';
    final seed = '${deal.toPbn()}|${dealer.letter}|${vulnerability.name}|'
        '$prefix${events.map((e) => e.canonical).join('|')}';
    var hash = 0x811c9dc5;
    for (final unit in seed.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}

abstract final class BridgeGame {
  static GameState apply(GameState state, GameAction action) {
    if (state.isFinished) throw const RuleViolation('Game already finished');
    if (state.phase == Phase.auction) {
      if (action is! CallAction) {
        throw const RuleViolation('Expected auction call');
      }
      return _applyCall(state, action);
    }
    if (action is! CardAction) {
      throw const RuleViolation('Expected card play');
    }
    return _applyCard(state, action);
  }

  static GameState _applyCall(GameState state, CallAction action) {
    if (action.actor != state.turn) {
      throw const RuleViolation('Not your turn to bid');
    }
    if (action.call is Bid) {
      final bid = action.call as Bid;
      if (bid.level < 1 || bid.level > 7) {
        throw const RuleViolation('Contract level must be 1–7');
      }
    }
    final previousBids =
        state.auction.where((e) => e.call is Bid).toList();
    final lastBid = previousBids.isEmpty ? null : previousBids.last;
    final lastBidValue = lastBid?.call as Bid?;
    Doubling doubling = Doubling.none;
    if (lastBid != null) {
      final lastBidIndex = state.auction.lastIndexOf(lastBid);
      for (final entry in state.auction.skip(lastBidIndex + 1)) {
        if (entry.call is DoubleCall) doubling = Doubling.doubled;
        if (entry.call is RedoubleCall) doubling = Doubling.redoubled;
      }
    }

    switch (action.call) {
      case Pass():
        break;
      case Bid(:final level, :final strain):
        if (lastBidValue != null &&
            (level < lastBidValue.level ||
                (level == lastBidValue.level &&
                    strain.index <= lastBidValue.strain.index))) {
          throw const RuleViolation('Bid must outrank current contract');
        }
      case DoubleCall():
        if (lastBid == null || doubling != Doubling.none ||
            lastBid.seat.isNS == action.actor.isNS) {
          throw const RuleViolation('Invalid double');
        }
      case RedoubleCall():
        if (lastBid == null || doubling != Doubling.doubled ||
            lastBid.seat.isNS != action.actor.isNS) {
          throw const RuleViolation('Invalid redouble');
        }
    }

    final auction = [...state.auction, AuctionEntry(action.actor, action.call)];
    final lastThreePass = auction.length >= 3 &&
        auction.skip(auction.length - 3).every((e) => e.call is Pass);
    final isPassOut = lastBid == null && action.call is Pass &&
        auction.length == 4;
    final isContractComplete = (lastBid != null || action.call is Bid) &&
        lastThreePass;
    final complete = isPassOut || isContractComplete;
    Contract? contract;
    if (isContractComplete) {
      final bids = auction.where((e) => e.call is Bid).toList();
      final winningBid = bids.last;
      final value = winningBid.call as Bid;
      final declarer = bids.firstWhere((e) =>
          e.seat.isNS == winningBid.seat.isNS &&
          (e.call as Bid).strain == value.strain).seat;
      var finalDoubling = Doubling.none;
      for (final entry in auction.skip(auction.indexOf(winningBid) + 1)) {
        if (entry.call is DoubleCall) finalDoubling = Doubling.doubled;
        if (entry.call is RedoubleCall) finalDoubling = Doubling.redoubled;
      }
      contract = Contract(level: value.level, strain: value.strain,
          declarer: declarer, doubling: finalDoubling);
    }

    return GameState._(
      deal: state.deal, dealer: state.dealer,
      vulnerability: state.vulnerability,
      phase: isPassOut ? Phase.finished :
          complete ? Phase.play : Phase.auction,
      turn: isPassOut ? null :
          complete ? contract!.openingLeader : action.actor.next,
      contract: contract, initialTrainingContract: state.initialTrainingContract,
      hands: state.hands, auction: auction,
      currentTrick: state.currentTrick, tricks: state.tricks,
      events: [...state.events, GameEvent(state.version + 1, action)],
      nsScore: isPassOut ? 0 : null,
    );
  }

  static GameState _applyCard(GameState state, CardAction action) {
    final contract = state.contract!;
    if (action.handOwner != state.turn) {
      throw const RuleViolation('Incorrect hand owner for current turn');
    }
    final expectedActor = action.handOwner == contract.dummy
        ? contract.declarer : action.handOwner;
    if (action.actor != expectedActor) {
      throw const RuleViolation('Incorrect controlling actor');
    }
    if (!state.legalCards(action.handOwner).contains(action.card)) {
      throw const RuleViolation('Card not held or must follow suit');
    }
    final hands = <Seat, Set<Card>>{
      for (final entry in state.hands.entries)
        entry.key: {...entry.value}
    };
    hands[action.handOwner]!.remove(action.card);
    final trick = [...state.currentTrick,
        PlayedCard(action.handOwner, action.actor, action.card)];
    var turn = action.handOwner.next;
    final tricks = [...state.tricks];
    List<PlayedCard> inProgress = trick;
    if (trick.length == 4) {
      final winner = _trickWinner(trick, contract.strain.trump);
      tricks.add(Trick(List.unmodifiable(trick), winner));
      inProgress = [];
      turn = winner;
    }
    final complete = tricks.length == 13;
    final declarerTricks = tricks.where((t) =>
        t.winner.isNS == contract.declarer.isNS).length;
    return GameState._(
      deal: state.deal, dealer: state.dealer,
      vulnerability: state.vulnerability,
      phase: complete ? Phase.finished : Phase.play,
      turn: complete ? null : turn,
      contract: contract,
      initialTrainingContract: state.initialTrainingContract,
      hands: frozenHands(hands),
      auction: state.auction, currentTrick: inProgress,
      tricks: tricks,
      events: [...state.events, GameEvent(state.version + 1, action)],
      nsScore: complete
          ? DuplicateScore.score(contract, declarerTricks, state.vulnerability)
          : null,
    );
  }

  static Seat _trickWinner(List<PlayedCard> trick, Suit? trump) {
    final led = trick.first.card.suit;
    int strength(Card card) {
      if (trump != null && card.suit == trump) return 100 + card.rank.index;
      if (card.suit == led) return card.rank.index;
      return -1;
    }
    var best = trick.first;
    for (final play in trick.skip(1)) {
      if (strength(play.card) > strength(best.card)) best = play;
    }
    return best.handOwner;
  }

  /// Event replay reconstructs history through the SAME validation boundary.
  static GameState replay(Deal deal, Seat dealer, Vulnerability vulnerability,
      Iterable<GameAction> actions, {Contract? justDeclareContract}) {
    var state = justDeclareContract == null
        ? GameState.start(deal, dealer, vulnerability)
        : GameState.justDeclareStart(deal, dealer, vulnerability,
            justDeclareContract);
    for (final action in actions) {
      state = apply(state, action);
    }
    return state;
  }
}

