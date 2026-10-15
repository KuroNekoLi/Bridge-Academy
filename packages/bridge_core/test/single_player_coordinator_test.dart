import 'package:bridge_core/bridge_core.dart';
import 'package:test/test.dart';

class AlwaysPassBot implements BotPolicy {
  const AlwaysPassBot();
  @override
  Future<GameAction> choose(PlayerView view) async =>
      CallAction(view.viewer, const Pass());
}
class IllegalBot implements BotPolicy {
  const IllegalBot();
  @override
  Future<GameAction> choose(PlayerView view) async =>
      CallAction(view.viewer, const DoubleCall());
}
class SpyBot implements BotPolicy {
  SpyBot(this.fullDeal);
  final Deal fullDeal;
  int observed = 0;
  @override
  Future<GameAction> choose(PlayerView view) async {
    observed++;
    for (final seat in Seat.values.where((s) => s != view.viewer)) {
      if (seat == view.contract?.dummy && view.dummyExposed) continue;
      for (final card in fullDeal.hands[seat]!) {
        expect(view.ownCards.contains(card), false);
        expect(view.dummyCards?.contains(card) ?? false, false);
      }
    }
    return CallAction(view.viewer, const Pass());
  }
}

void main() {
  group('M2 local coordinator', () {
    test('bot turn pauses for human; version checked; dummy becomes public',
        () async {
      final c = SinglePlayerCoordinator(
        deal: Deal.suitPerSeat(), dealer: Seat.east,
        vulnerability: Vulnerability.none, humanSeat: Seat.north,
        bot: const DeterministicTrainingBot(),
      );
      expect(await c.runBots(), 3);
      final human = c.humanView;
      expect(human.canAct, true);
      expect(human.phase, Phase.auction);
      expect(human.auction.map((x) => x.call.code), ['1NT','PASS','PASS']);
      expect(human.ownCards.length, 13);
      expect(human.dummyCards, isNull);
      c.submitHuman(const CallAction(Seat.north, Pass()),
          expectedVersion: human.version);
      expect(c.version, 4);
      expect(() => c.submitHuman(const CallAction(Seat.north, Pass()),
          expectedVersion: human.version), throwsA(isA<RuleViolation>()));
      expect(await c.runBots(), 2);
      expect(c.humanView.turn, Seat.north);
      expect(c.humanView.phase, Phase.play);
      expect(c.humanView.dummyExposed, true);
    });

    test('whole hand alternates between human and training bots', () async {
      final c = SinglePlayerCoordinator(
        deal: Deal.suitPerSeat(), dealer: Seat.east,
        vulnerability: Vulnerability.none, humanSeat: Seat.north,
        bot: const DeterministicTrainingBot(),
      );
      for (var tick = 0; tick < 100 && !c.finished; tick++) {
        await c.runBots();
        if (c.finished) break;
        final view = c.humanView;
        expect(view.canAct, true);
        final GameAction action = view.phase == Phase.auction
            ? const CallAction(Seat.north, Pass())
            : CardAction(Seat.north, view.turn!, view.legalCards.first);
        c.submitHuman(action, expectedVersion: view.version);
      }
      expect(c.finished, true);
      expect(c.humanView.phase, Phase.finished);
      expect(c.humanView.version, 56);
      expect(c.humanView.nsScore, isNotNull);
      expect(c.humanView.completedTricks.length, 13);
      expect(c.humanView.remainingCards.values, everyElement(0));
    });

    test('four PASS ends with score 0 without any play', () async {
      final c = SinglePlayerCoordinator(
        deal: Deal.suitPerSeat(), dealer: Seat.east,
        vulnerability: Vulnerability.none, humanSeat: Seat.north,
        bot: const AlwaysPassBot(),
      );
      expect(await c.runBots(), 3);
      expect(c.finished, false);
      c.submitHuman(const CallAction(Seat.north, Pass()),
          expectedVersion: c.version);
      expect(c.finished, true);
      expect(c.humanView.nsScore, 0);
      expect(c.humanView.auction.length, 4);
      expect(c.humanView.completedTricks, isEmpty);
    });

    test('illegal bot action cannot mutate authority', () async {
      final c = SinglePlayerCoordinator(
        deal: Deal.suitPerSeat(), dealer: Seat.east,
        vulnerability: Vulnerability.none, humanSeat: Seat.north,
        bot: const IllegalBot(),
      );
      await expectLater(c.runBots(), throwsA(isA<RuleViolation>()));
      expect(c.version, 0);
      expect(c.humanView.auction, isEmpty);
    });

    test('bots are offered filtered views only', () async {
      final deal = Deal.suitPerSeat();
      final spy = SpyBot(deal);
      final c = SinglePlayerCoordinator(
        deal: deal, dealer: Seat.east,
        vulnerability: Vulnerability.none, humanSeat: Seat.north, bot: spy,
      );
      expect(await c.runBots(), 3);
      expect(spy.observed, 3);
      expect(c.humanView.ownCards.toSet(), deal.hands[Seat.north]);
    });

    test('human cannot act for another seat', () {
      final c = SinglePlayerCoordinator(
        deal: Deal.suitPerSeat(), dealer: Seat.north,
        vulnerability: Vulnerability.none, humanSeat: Seat.north,
        bot: const DeterministicTrainingBot(),
      );
      expect(() => c.submitHuman(const CallAction(Seat.east, Pass()),
          expectedVersion: 0), throwsA(isA<RuleViolation>()));
      expect(c.version, 0);
    });
  });
}

