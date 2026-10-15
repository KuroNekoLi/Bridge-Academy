import 'game.dart';
import 'model.dart';

/// Strictly filtered, immutable seat-specific perspective of a bridge deal.
///
/// A GameState or GameTranscript contains all four hands and must NEVER be
/// sent to an untrusted player or ordinary bridge AI. Only serialize this DTO.
/// Caller authorization (who is allowed to request which Seat) must be checked
/// by the coordinator or future server, not by this low-level projector.
class PlayerView {
  PlayerView._({
    required this.viewer,
    required this.dealer,
    required this.vulnerability,
    required this.phase,
    required this.version,
    required this.turn,
    required this.actorToPlay,
    required this.contract,
    required this.nsScore,
    required this.dummyExposed,
    required List<Card> ownCards,
    required List<Card>? dummyCards,
    required Map<Seat, int> remainingCards,
    required List<AuctionEntry> auction,
    required List<PlayedCard> currentTrick,
    required List<Trick> completedTricks,
    required List<Card> legalCards,
  }) : ownCards = List.unmodifiable(ownCards),
       dummyCards = dummyCards == null ? null : List.unmodifiable(dummyCards),
       remainingCards = Map.unmodifiable(remainingCards),
       auction = List.unmodifiable(auction),
       currentTrick = List.unmodifiable(currentTrick),
       completedTricks = List.unmodifiable(completedTricks),
       legalCards = List.unmodifiable(legalCards);

  /// This factory can read privileged GameState. Do not expose it as an
  /// arbitrary-seat HTTP endpoint; use SinglePlayerCoordinator.humanView.
  factory PlayerView.forSeat(GameState state, Seat seat) {
    List<Card> ordered(Iterable<Card> cards) =>
        cards.toList()..sort((a, b) => a.code.compareTo(b.code));
    final dummy = state.dummyExposed ? state.contract!.dummy : null;
    final canAct = state.actorToPlay == seat && !state.isFinished;
    return PlayerView._(
      viewer: seat,
      dealer: state.dealer,
      vulnerability: state.vulnerability,
      phase: state.phase,
      version: state.version,
      turn: state.turn,
      actorToPlay: state.actorToPlay,
      contract: state.contract,
      nsScore: state.nsScore,
      dummyExposed: state.dummyExposed,
      ownCards: ordered(state.hands[seat]!),
      dummyCards: dummy == null ? null : ordered(state.hands[dummy]!),
      remainingCards: {
        for (final position in Seat.values) position: state.hands[position]!.length,
      },
      auction: state.auction,
      currentTrick: state.currentTrick,
      completedTricks: state.tricks,
      legalCards: canAct && state.phase == Phase.play
          ? ordered(state.legalCards(state.turn!))
          : const <Card>[],
    );
  }

  final Seat viewer;
  final Seat dealer;
  final Vulnerability vulnerability;
  final Phase phase;
  final int version;
  final Seat? turn;
  final Seat? actorToPlay;
  final Contract? contract;
  final int? nsScore;
  final bool dummyExposed;

  /// Only this seat's remaining private hand, never other private hands.
  final List<Card> ownCards;

  /// Public remaining dummy hand after the opening lead, null before.
  final List<Card>? dummyCards;

  /// Public per-seat counts, not card identities.
  final Map<Seat, int> remainingCards;
  final List<AuctionEntry> auction;
  final List<PlayedCard> currentTrick;
  final List<Trick> completedTricks;

  /// Only provided when this viewer may make the next card selection.
  /// For dummy, the declarer can act but the dummy seat cannot.
  final List<Card> legalCards;

  bool get canAct => actorToPlay == viewer && phase != Phase.finished;

  Map<String, Object?> toJson() {
    Map<String, Object?> played(PlayedCard play) => {
      'seat': play.handOwner.letter,
      'actor': play.actor.letter,
      'card': play.card.code,
    };
    return {
      'schemaVersion': 1,
      'viewer': viewer.letter,
      'dealer': dealer.letter,
      'vulnerability': vulnerability.name,
      'phase': phase.name,
      'version': version,
      'turn': turn?.letter,
      'actorToPlay': actorToPlay?.letter,
      'canAct': canAct,
      'ownCards': ownCards.map((c) => c.code).toList(),
      'dummyExposed': dummyExposed,
      'dummyCards': dummyCards?.map((c) => c.code).toList(),
      'remainingCards': {
        for (final entry in remainingCards.entries)
          entry.key.letter: entry.value,
      },
      'auction': [
        for (final entry in auction)
          {'seat': entry.seat.letter, 'call': entry.call.code},
      ],
      'currentTrick': currentTrick.map(played).toList(),
      'completedTricks': [
        for (final trick in completedTricks)
          {
            'winner': trick.winner.letter,
            'plays': trick.plays.map(played).toList(),
          },
      ],
      'contract': contract == null
          ? null
          : {
              'level': contract!.level,
              'strain': contract!.strain.code,
              'declarer': contract!.declarer.letter,
              'doubling': contract!.doubling.name,
              'dummy': contract!.dummy.letter,
            },
      'nsScore': nsScore,
      'legalCards': legalCards.map((c) => c.code).toList(),
    };
  }
}

