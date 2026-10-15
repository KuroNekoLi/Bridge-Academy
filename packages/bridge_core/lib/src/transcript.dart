import 'game.dart';
import 'model.dart';

/// Versioned full-information archive. NEVER send directly to a player.
abstract final class GameTranscript {
  static Map<String, Object?> encode(GameState state) => {
    'schemaVersion': 1,
    'dealPbn': state.deal.toPbn(),
    'dealer': state.dealer.letter,
    'vulnerability': state.vulnerability.name,
    'events': [for (final event in state.events) _encodeEvent(event)],
  };

  static Map<String, Object?> _encodeEvent(GameEvent event) {
    final action = event.action;
    if (action is CallAction) {
      return {'version': event.version, 'type': 'call',
        'actor': action.actor.letter, 'call': action.call.code};
    }
    final play = action as CardAction;
    return {'version': event.version, 'type': 'play',
      'actor': play.actor.letter, 'handOwner': play.handOwner.letter,
      'card': play.card.code};
  }

  static GameState decode(Map<String, dynamic> archive) {
    if (archive['schemaVersion'] != 1) {
      throw const FormatException('Unsupported transcript version');
    }
    final deal = Deal.fromPbn(archive['dealPbn'] as String);
    final dealer = Seat.fromLetter(archive['dealer'] as String);
    final vulName = archive['vulnerability'] as String;
    final vulnerability = Vulnerability.values.firstWhere(
      (e) => e.name == vulName,
      orElse: () => throw const FormatException('Unknown vulnerability'),
    );
    var state = GameState.start(deal, dealer, vulnerability);
    final entries = archive['events'] as List<dynamic>;
    for (final raw in entries) {
      final entry = Map<String, dynamic>.from(raw as Map);
      if (entry['version'] != state.version + 1) {
        throw const FormatException('Non-sequential event version');
      }
      final actor = Seat.fromLetter(entry['actor'] as String);
      final GameAction action;
      switch (entry['type']) {
        case 'call':
          action = CallAction(actor, _parseCall(entry['call'] as String));
        case 'play':
          final code = entry['card'] as String;
          if (!RegExp(r'^[CDHS][2-9TJQKA]$').hasMatch(code)) {
            throw FormatException('Invalid card code: $code');
          }
          final suit = Suit.values.firstWhere((s) => s.pbn == code[0]);
          action = CardAction(actor,
            Seat.fromLetter(entry['handOwner'] as String),
            Card(suit, Rank.fromSymbol(code[1])));
        default:
          throw const FormatException('Unknown event type');
      }
      state = BridgeGame.apply(state, action);
    }
    return state;
  }

  static Call _parseCall(String value) {
    if (value == 'PASS') return const Pass();
    if (value == 'X') return const DoubleCall();
    if (value == 'XX') return const RedoubleCall();
    final match = RegExp(r'^([1-7])(C|D|H|S|NT)$').firstMatch(value);
    if (match == null) throw FormatException('Invalid call code: $value');
    final strain = Strain.values.firstWhere((s) => s.code == match.group(2));
    return Bid(int.parse(match.group(1)!), strain);
  }
}

