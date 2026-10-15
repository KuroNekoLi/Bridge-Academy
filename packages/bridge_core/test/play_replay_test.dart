import 'dart:convert';
import 'package:bridge_core/bridge_core.dart';
import 'package:test/test.dart';

GameState contractGame(Deal deal) {
  var game = GameState.start(deal, Seat.north, Vulnerability.none);
  for (final call in const [Bid(1, Strain.notrump), Pass(), Pass(), Pass()]) {
    game = BridgeGame.apply(game, CallAction(game.turn!, call));
  }
  return game;
}

Deal mixedDeal() {
  final hands = {for (final seat in Seat.values) seat: <Card>[]};
  var i = 0;
  for (final suit in Suit.values) {
    for (final rank in Rank.values) {
      hands[Seat.values[i % 4]]!.add(Card(suit, rank));
      i++;
    }
  }
  return Deal(hands);
}

void main() {
  group('Card play and event replay', () {
    test('follow suit required when current player has led suit', () {
      var game = contractGame(mixedDeal());
      final eastClub = game.hands[Seat.east]!.firstWhere(
          (c) => c.suit == Suit.clubs);
      game = BridgeGame.apply(game, CardAction(Seat.east, Seat.east, eastClub));
      final southOffSuit = game.hands[Seat.south]!.firstWhere(
          (c) => c.suit != Suit.clubs);
      expect(() => BridgeGame.apply(game,
          CardAction(Seat.north, Seat.south, southOffSuit)),
          throwsA(isA<RuleViolation>()));
      expect(game.currentTrick.length, 1);
      expect(game.version, 5);
      expect(game.legalCards(Seat.south).every((c) => c.suit == Suit.clubs), true);
    });

    test('dummy is controlled by declarer after opening lead', () {
      var game = contractGame(Deal.suitPerSeat());
      expect(game.dummyExposed, false);
      game = BridgeGame.apply(game, CardAction(
          Seat.east, Seat.east, game.legalCards(Seat.east).first));
      expect(game.dummyExposed, true);
      final southCard = game.legalCards(Seat.south).first;
      expect(() => BridgeGame.apply(game,
          CardAction(Seat.south, Seat.south, southCard)),
          throwsA(isA<RuleViolation>()));
      game = BridgeGame.apply(game, CardAction(Seat.north, Seat.south, southCard));
      expect(game.currentTrick.length, 2);
    });

    test('13 tricks / 52 cards / score / replay / JSON archive', () {
      final deal = Deal.suitPerSeat();
      var game = contractGame(deal);
      while (!game.isFinished) {
        final owner = game.turn!;
        final actor = game.actorToPlay!;
        final card = (game.legalCards(owner).toList()
            ..sort((a, b) => a.code.compareTo(b.code))).first;
        final before = game;
        game = BridgeGame.apply(game, CardAction(actor, owner, card));
        expect(before.version + 1, game.version);
        expect(before.hands[owner]!.contains(card), true);
      }
      expect(game.tricks.length, 13);
      expect(game.events.length, 56);
      expect(game.tricks.expand((t) => t.plays).length, 52);
      expect(game.hands.values.every((h) => h.isEmpty), true);
      expect(game.currentTrick, isEmpty);
      expect(game.phase, Phase.finished);
      expect(game.nsScore, -350);
      final rebuilt = BridgeGame.replay(
          deal, Seat.north, Vulnerability.none,
          game.events.map((e) => e.action));
      expect(rebuilt.historyFingerprint, game.historyFingerprint);
      expect(rebuilt.nsScore, game.nsScore);
      final encoded = jsonDecode(jsonEncode(GameTranscript.encode(game)))
          as Map<String, dynamic>;
      final decoded = GameTranscript.decode(encoded);
      expect(decoded.historyFingerprint, game.historyFingerprint);
      expect(decoded.nsScore, game.nsScore);
      expect(decoded.tricks.length, 13);
    });

    test('PBN round-trip and invalid deals', () {
      final deal = mixedDeal();
      expect(Deal.fromPbn(deal.toPbn()).toPbn(), deal.toPbn());
      expect(() => Deal.fromPbn('N:AK.Q T.X X X'), throwsFormatException);
      expect(() => Deal({
        for (final seat in Seat.values)
          seat: Rank.values.map((r) => Card(Suit.clubs, r))
      }), throwsArgumentError);
    });

    test('corrupted transcript version is rejected, not repaired', () {
      var game = GameState.start(Deal.suitPerSeat(), Seat.north, Vulnerability.none);
      game = BridgeGame.apply(game, const CallAction(Seat.north, Pass()));
      final archive = jsonDecode(jsonEncode(GameTranscript.encode(game)))
          as Map<String, dynamic>;
      (archive['events'] as List).first['version'] = 99;
      expect(() => GameTranscript.decode(archive), throwsFormatException);
    });
  });
}

