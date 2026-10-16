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

  /// Decode ONLY the filtered v1 Gateway PlayerView. Never reconstruct a Deal
  /// or use this as a server-authoritative GameState.
  factory PlayerView.fromJson(Map<String, dynamic> data) {
    const keys = {
      'schemaVersion', 'viewer', 'dealer', 'vulnerability', 'phase',
      'version', 'turn', 'actorToPlay', 'canAct', 'ownCards',
      'dummyExposed', 'dummyCards', 'remainingCards', 'auction',
      'currentTrick', 'completedTricks', 'contract', 'nsScore', 'legalCards',
    };
    if (data.keys.toSet().difference(keys).isNotEmpty ||
        !data.keys.toSet().containsAll(keys) ||
        data['schemaVersion'] != 1 ||
        data['version'] is! int ||
        (data['version'] as int) < 0) {
      throw const FormatException('Invalid PlayerView schema');
    }
    Seat seat(Object? value) {
      if (value is! String) throw const FormatException('Seat required');
      return Seat.fromLetter(value);
    }
    Seat? nullableSeat(Object? value) => value == null ? null : seat(value);
    Card card(Object? value) {
      if (value is! String ||
          !RegExp(r'^[CDHS][2-9TJQKA]
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

).hasMatch(value)) {
        throw const FormatException('Invalid card');
      }
      return Card(
        Suit.values.firstWhere((s) => s.pbn == value[0]),
        Rank.fromSymbol(value[1]),
      );
    }
    List<T> items<T>(Object? value, T Function(Object?) decode) {
      if (value is! List) throw const FormatException('Invalid list');
      return value.map(decode).toList(growable: false);
    }
    Map<String, dynamic> obj(Object? value) {
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Invalid object');
      }
      return value;
    }
    Call call(Object? value) {
      if (value == 'PASS') return const Pass();
      if (value == 'X') return const DoubleCall();
      if (value == 'XX') return const RedoubleCall();
      if (value is! String) throw const FormatException('Invalid call');
      final match = RegExp(r'^([1-7])(C|D|H|S|NT)
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

).firstMatch(value);
      if (match == null) throw const FormatException('Invalid call');
      return Bid(int.parse(match.group(1)!),
          Strain.values.firstWhere((s) => s.code == match.group(2)));
    }
    PlayedCard played(Object? value) {
      final o = obj(value);
      if (o.length != 3) throw const FormatException('Invalid played card');
      return PlayedCard(
          seat(o['seat']), seat(o['actor']), card(o['card']));
    }
    Trick trick(Object? value) {
      final o = obj(value);
      final cards = items(o['plays'], played);
      if (cards.length != 4 ||
          cards.map((p) => p.handOwner).toSet().length != 4) {
        throw const FormatException('Invalid completed trick');
      }
      return Trick(cards, seat(o['winner']));
    }

    final own = items(data['ownCards'], card);
    final dummy = data['dummyCards'] == null
        ? null : items(data['dummyCards'], card);
    final legal = items(data['legalCards'], card);
    final exposed = data['dummyExposed'];
    if (exposed is! bool || data['canAct'] is! bool ||
        own.length > 13 || own.toSet().length != own.length ||
        (dummy != null && (dummy.length > 13 ||
            dummy.toSet().length != dummy.length)) ||
        (!exposed && dummy != null) ||
        data['remainingCards'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid hand projection');
    }
    final counts = <Seat, int>{};
    for (final entry in (data['remainingCards'] as Map<String, dynamic>).entries) {
      if (entry.value is! int ||
          (entry.value as int) < 0 || (entry.value as int) > 13) {
        throw const FormatException('Invalid card count');
      }
      counts[seat(entry.key)] = entry.value as int;
    }
    if (counts.length != 4 ||
        !Seat.values.every(counts.containsKey)) {
      throw const FormatException('Missing public card counts');
    }
    final contractJson = data['contract'] == null
        ? null : obj(data['contract']);
    final contract = contractJson == null ? null : Contract(
      level: contractJson['level'] as int,
      strain: Strain.values.firstWhere(
          (s) => s.code == contractJson['strain']),
      declarer: seat(contractJson['declarer']),
      doubling: Doubling.values.byName(contractJson['doubling'] as String),
    );
    final viewer = seat(data['viewer']);
    final phase = Phase.values.byName(data['phase'] as String);
    final actor = nullableSeat(data['actorToPlay']);
    if (data['canAct'] != (actor == viewer && phase != Phase.finished) ||
        (legal.isNotEmpty && (actor != viewer || phase != Phase.play)) ||
        (exposed && contract == null) ||
        (legal.any((c) => !(data['turn'] == viewer.letter
            ? own.contains(c) : (dummy?.contains(c) ?? false))))) {
      throw const FormatException('Inconsistent PlayerView');
    }
    return PlayerView._(
      viewer: viewer,
      dealer: seat(data['dealer']),
      vulnerability: Vulnerability.values.byName(
          data['vulnerability'] as String),
      phase: phase,
      version: data['version'] as int,
      turn: nullableSeat(data['turn']),
      actorToPlay: actor,
      contract: contract,
      nsScore: data['nsScore'] as int?,
      dummyExposed: exposed,
      ownCards: own,
      dummyCards: dummy,
      remainingCards: counts,
      auction: items(data['auction'], (a) {
        final o = obj(a);
        return AuctionEntry(seat(o['seat']), call(o['call']));
      }),
      currentTrick: items(data['currentTrick'], played),
      completedTricks: items(data['completedTricks'], trick),
      legalCards: legal,
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

