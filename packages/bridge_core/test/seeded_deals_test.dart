import 'dart:convert';
import 'dart:math';
import 'package:bridge_core/bridge_core.dart';
import 'package:test/test.dart';

Deal generatedDeal(int seed) {
  final cards = [
    for (final suit in Suit.values)
      for (final rank in Rank.values) Card(suit, rank),
  ]..shuffle(Random(seed));
  return Deal({
    for (var i = 0; i < 4; i++)
      Seat.values[i]: cards.sublist(i * 13, (i + 1) * 13),
  });
}

Seat independentTrickWinner(Trick trick, Suit? trump) {
  final led = trick.plays.first.card.suit;
  PlayedCard best = trick.plays.first;
  int weight(PlayedCard p) {
    if (trump != null && p.card.suit == trump) {
      return 100 + p.card.rank.index;
    }
    return p.card.suit == led ? p.card.rank.index : -1;
  }
  for (final play in trick.plays.skip(1)) {
    if (weight(play) > weight(best)) best = play;
  }
  return best.handOwner;
}

void main() {
  test('100 seeded complete non-AI deals preserve play and replay invariants', () {
    for (var board = 0; board < 100; board++) {
      final seed = 2026101500 + board;
      final deal = generatedDeal(seed);
      final dealer = Seat.values[board % 4];
      final vul = Vulnerability.values[(board ~/ 4) % 4];
      final strain = Strain.values[board % 5];
      final level = board % 7 + 1;

      var state = GameState.start(deal, dealer, vul);
      state = BridgeGame.apply(state,
          CallAction(dealer, Bid(level, strain)));
      for (var i = 0; i < 3; i++) {
        state = BridgeGame.apply(
            state, CallAction(state.turn!, const Pass()));
      }
      expect(state.phase, Phase.play, reason: 'board $board');
      expect(state.contract!.declarer, dealer, reason: 'board $board');
      expect(state.contract!.strain, strain, reason: 'board $board');

      while (state.phase == Phase.play) {
        final owner = state.turn!;
        final legal = state.legalCards(owner).toList()
          ..sort((a, b) => a.code.compareTo(b.code));
        expect(legal, isNotEmpty, reason: 'board $board');
        final action = CardAction(state.actorToPlay!, owner, legal.first);
        state = BridgeGame.apply(state, action);
      }
      expect(state.phase, Phase.finished, reason: 'board $board');
      expect(state.tricks.length, 13, reason: 'board $board');
      expect(state.events.length, 56, reason: 'board $board');
      expect(state.currentTrick, isEmpty, reason: 'board $board');
      expect(state.hands.values.every((cards) => cards.isEmpty), isTrue,
          reason: 'board $board');
      final allPlayed = state.tricks.expand((t) => t.plays).map((p) => p.card);
      expect(allPlayed.toSet().length, 52, reason: 'board $board');
      for (final trick in state.tricks) {
        expect(trick.plays.length, 4, reason: 'board $board');
        expect(trick.winner,
            independentTrickWinner(trick, strain.trump),
            reason: 'board $board');
      }

      final decoded = GameTranscript.decode(
          jsonDecode(jsonEncode(GameTranscript.encode(state)))
              as Map<String, dynamic>);
      expect(decoded.historyFingerprint, state.historyFingerprint,
          reason: 'board $board');
      expect(decoded.nsScore, state.nsScore, reason: 'board $board');
      expect(decoded.tricks.length, 13, reason: 'board $board');
    }
  });
}

