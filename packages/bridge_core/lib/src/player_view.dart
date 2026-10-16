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

  /// Validate and reconstruct only a seat-filtered HTTP PlayerView.
  /// This does NOT deserialize authoritative GameState, Deal or PBN.
  factory PlayerView.fromJson(Map<String, dynamic> data) {
    const fields = {
      'schemaVersion', 'viewer', 'dealer', 'vulnerability', 'phase',
      'version', 'turn', 'actorToPlay', 'canAct', 'ownCards',
      'dummyExposed', 'dummyCards', 'remainingCards', 'auction',
      'currentTrick', 'completedTricks', 'contract', 'nsScore', 'legalCards',
    };
    if (data.keys.toSet().difference(fields).isNotEmpty ||
        !data.keys.toSet().containsAll(fields) ||
        data['schemaVersion'] != 1 || data['version'] is! int ||
        (data['version'] as int) < 0) {
      throw const FormatException('Unexpected PlayerView schema');
    }
    Map<String, dynamic> object(Object? v) {
      if (v is! Map<String, dynamic>) {
        throw const FormatException('Invalid object');
      }
      return v;
    }
    List<T> list<T>(Object? v, T Function(Object?) parse) {
      if (v is! List) throw const FormatException('Invalid list');
      return v.map(parse).toList(growable: false);
    }
    Seat parseSeat(Object? v) {
      if (v is! String) throw const FormatException('Invalid seat');
      return Seat.fromLetter(v);
    }
    Seat? parseNullableSeat(Object? v) =>
        v == null ? null : parseSeat(v);
    Card parseCard(Object? v) {
      if (v is! String ||
          !RegExp(r'^[CDHS][2-9TJQKA]$').hasMatch(v)) {
        throw const FormatException('Invalid card');
      }
      return Card(Suit.values.firstWhere((s) => s.pbn == v[0]),
          Rank.fromSymbol(v[1]));
    }
    Call parseCall(Object? v) {
      if (v == 'PASS') return const Pass();
      if (v == 'X') return const DoubleCall();
      if (v == 'XX') return const RedoubleCall();
      if (v is! String) throw const FormatException('Invalid call');
      final match = RegExp(r'^([1-7])(C|D|H|S|NT)$').firstMatch(v);
      if (match == null) throw const FormatException('Invalid call');
      return Bid(int.parse(match.group(1)!),
          Strain.values.firstWhere((s) => s.code == match.group(2)));
    }
    PlayedCard parsePlayed(Object? v) {
      final p = object(v);
      if (p.length != 3) throw const FormatException('Invalid played card');
      return PlayedCard(
          parseSeat(p['seat']), parseSeat(p['actor']), parseCard(p['card']));
    }
    Trick parseTrick(Object? v) {
      final t = object(v);
      final plays = list(t['plays'], parsePlayed);
      if (plays.length != 4 ||
          plays.map((p) => p.handOwner).toSet().length != 4) {
        throw const FormatException('Invalid trick');
      }
      return Trick(plays, parseSeat(t['winner']));
    }
    final viewer = parseSeat(data['viewer']);
    final phase = Phase.values.byName(data['phase'] as String);
    final actor = parseNullableSeat(data['actorToPlay']);
    final turn = parseNullableSeat(data['turn']);
    final exposed = data['dummyExposed'];
    final own = list(data['ownCards'], parseCard);
    final dummy = data['dummyCards'] == null
        ? null : list(data['dummyCards'], parseCard);
    final legal = list(data['legalCards'], parseCard);
    final counts = <Seat, int>{};
    for (final e in object(data['remainingCards']).entries) {
      if (e.value is! int ||
          (e.value as int) < 0 || (e.value as int) > 13) {
        throw const FormatException('Invalid remaining cards');
      }
      counts[parseSeat(e.key)] = e.value as int;
    }
    if (counts.length != 4 || !Seat.values.every(counts.containsKey) ||
        exposed is! bool || data['canAct'] is! bool ||
        data['canAct'] != (actor == viewer && phase != Phase.finished) ||
        own.length > 13 || own.toSet().length != own.length ||
        (dummy != null &&
            (dummy.length > 13 || dummy.toSet().length != dummy.length)) ||
        (!exposed && dummy != null)) {
      throw const FormatException('Invalid public hand projection');
    }
    final c = data['contract'];
    Contract? contract;
    if (c != null) {
      final obj = object(c);
      contract = Contract(
        level: obj['level'] as int,
        strain: Strain.values.firstWhere(
            (s) => s.code == obj['strain']),
        declarer: parseSeat(obj['declarer']),
        doubling: Doubling.values.byName(obj['doubling'] as String),
      );
      if (obj['dummy'] != contract.dummy.letter) {
        throw const FormatException('Invalid dummy');
      }
    }
    if ((exposed && contract == null) ||
        (legal.isNotEmpty &&
            (actor != viewer || phase != Phase.play ||
             legal.any((card) =>
               !(turn == viewer ? own : (dummy ?? const <Card>[]))
                  .contains(card))))) {
      throw const FormatException('Illegal card projection');
    }
    return PlayerView._(
      viewer: viewer,
      dealer: parseSeat(data['dealer']),
      vulnerability: Vulnerability.values.byName(
          data['vulnerability'] as String),
      phase: phase,
      version: data['version'] as int,
      turn: turn,
      actorToPlay: actor,
      contract: contract,
      nsScore: data['nsScore'] as int?,
      dummyExposed: exposed,
      ownCards: own,
      dummyCards: dummy,
      remainingCards: counts,
      auction: list(data['auction'], (Object? v) {
        final p = object(v);
        return AuctionEntry(parseSeat(p['seat']), parseCall(p['call']));
      }),
      currentTrick: list(data['currentTrick'], parsePlayed),
      completedTricks: list(data['completedTricks'], parseTrick),
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

