import 'package:bridge_core/bridge_core.dart';
import 'package:test/test.dart';

GameState applyCalls(GameState game, List<Call> calls) {
  for (final call in calls) {
    game = BridgeGame.apply(game, CallAction(game.turn!, call));
  }
  return game;
}

void main() {
  group('Auction legality and termination', () {
    for (final dealer in Seat.values) {
      test('four passes terminate from dealer $dealer', () {
        var game = GameState.start(Deal.suitPerSeat(), dealer, Vulnerability.none);
        game = applyCalls(game, const [Pass(), Pass(), Pass()]);
        expect(game.isFinished, false);
        expect(game.auction.length, 3);
        game = applyCalls(game, const [Pass()]);
        expect(game.isPassOut, true);
        expect(game.nsScore, 0);
        expect(game.events.length, 4);
        expect(() => BridgeGame.apply(game, CallAction(dealer, const Pass())),
            throwsA(isA<RuleViolation>()));
      });
    }

    test('bid and three passes determine contract and opening lead', () {
      var game = GameState.start(Deal.suitPerSeat(), Seat.north, Vulnerability.none);
      game = applyCalls(game,
          const [Bid(1, Strain.notrump), Pass(), Pass(), Pass()]);
      expect(game.phase, Phase.play);
      expect(game.contract!.declarer, Seat.north);
      expect(game.contract!.dummy, Seat.south);
      expect(game.turn, Seat.east);
    });

    test('declarer is first member of partnership bidding final strain', () {
      var game = GameState.start(Deal.suitPerSeat(), Seat.north, Vulnerability.none);
      game = applyCalls(game, const [
        Bid(1, Strain.hearts), Pass(), Bid(2, Strain.hearts),
        Pass(), Pass(), Pass()
      ]);
      expect(game.contract!.level, 2);
      expect(game.contract!.declarer, Seat.north);
    });

    test('double and redouble are legal from opposing partnerships', () {
      var game = GameState.start(Deal.suitPerSeat(), Seat.north, Vulnerability.ns);
      game = applyCalls(game, const [
        Bid(1, Strain.clubs), DoubleCall(), RedoubleCall(),
        Pass(), Pass(), Pass()
      ]);
      expect(game.phase, Phase.play);
      expect(game.contract!.doubling, Doubling.redoubled);
      expect(game.contract!.declarer, Seat.north);
    });

    test('double from bidding side is illegal and leaves state intact', () {
      var game = GameState.start(Deal.suitPerSeat(), Seat.north, Vulnerability.none);
      game = applyCalls(game, const [Bid(1, Strain.clubs), Pass()]);
      final before = game.historyFingerprint;
      expect(() => BridgeGame.apply(game,
          const CallAction(Seat.south, DoubleCall())),
          throwsA(isA<RuleViolation>()));
      expect(game.version, 2);
      expect(game.historyFingerprint, before);
    });

    test('rejects no-contract double, invalid redouble and underbid', () {
      var game = GameState.start(Deal.suitPerSeat(), Seat.north, Vulnerability.none);
      expect(() => BridgeGame.apply(game,
          const CallAction(Seat.north, DoubleCall())),
          throwsA(isA<RuleViolation>()));
      game = applyCalls(game, const [Bid(2, Strain.spades)]);
      expect(() => BridgeGame.apply(game,
          const CallAction(Seat.east, RedoubleCall())),
          throwsA(isA<RuleViolation>()));
      expect(() => BridgeGame.apply(game,
          const CallAction(Seat.east, Bid(2, Strain.hearts))),
          throwsA(isA<RuleViolation>()));
    });

    test('new bid outranks previous bid and cancels double', () {
      var game = GameState.start(Deal.suitPerSeat(), Seat.north, Vulnerability.none);
      game = applyCalls(game, const [
        Bid(1, Strain.clubs), DoubleCall(), Bid(1, Strain.hearts),
        Pass(), Pass(), Pass(),
      ]);
      expect(game.contract!.doubling, Doubling.none);
      expect(game.contract!.strain, Strain.hearts);
    });

    test('wrong actor or card during auction rejected', () {
      final game = GameState.start(Deal.suitPerSeat(), Seat.north, Vulnerability.none);
      expect(() => BridgeGame.apply(game,
          const CallAction(Seat.east, Pass())), throwsA(isA<RuleViolation>()));
      expect(() => BridgeGame.apply(game,
          const CardAction(Seat.north, Seat.north, Card(Suit.clubs, Rank.ace))),
          throwsA(isA<RuleViolation>()));
      expect(game.events, isEmpty);
    });
  });
}

