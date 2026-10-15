import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('M2-F05 session (pure coordinator through Flutter ChangeNotifier)', () {
    test('demo mode starts without BEN and does not expose omniscient state', () async {
      final session = BridgeSession();
      addTearDown(session.dispose);
      await session.newGame();
      final view = session.view!;
      expect(view.viewer, Seat.north);
      expect(view.phase, Phase.auction);
      expect(view.ownCards.length, 13);
      expect(view.dummyCards, isNull);
      expect(view.canAct, true);
      expect(view.toJson().containsKey('hands'), false);
      expect(session.mode, OpponentMode.demo);
    });

    test('4 chronological Pass calls finish Pass Out with NS zero', () async {
      final session = BridgeSession();
      addTearDown(session.dispose);
      await session.newGame();
      await session.submitCall(const Pass());
      expect(session.finished, true);
      expect(session.view!.auction.map((e) => e.call.code),
          ['PASS', 'PASS', 'PASS', 'PASS']);
      expect(session.view!.nsScore, 0);
      expect(session.view!.completedTricks, isEmpty);
    });

    test('opening bid and first robot lead expose Dummy, allow declarer action',
        () async {
      final session = BridgeSession();
      addTearDown(session.dispose);
      await session.newGame();
      await session.submitCall(const Bid(1, Strain.notrump));
      final view = session.view!;
      expect(view.phase, Phase.play);
      expect(view.dummyExposed, true);
      expect(view.contract!.declarer, Seat.north);
      expect(view.contract!.dummy, Seat.south);
      expect(view.turn, Seat.south);
      expect(view.viewer, Seat.north);
      expect(view.actorToPlay, Seat.north);
      expect(view.legalCards, isNotEmpty);
      final version = view.version;
      await session.submitCard(view.legalCards.first);
      expect(session.view!.version, greaterThan(version));
      expect(session.errorCode, isNull);
    });

    test('human cannot submit a card not allowed by the projection', () async {
      final session = BridgeSession();
      addTearDown(session.dispose);
      await session.newGame();
      await session.submitCall(const Bid(1, Strain.notrump));
      final before = session.view!.version;
      final legal = session.view!.legalCards.toSet();
      final invalid = session.view!.ownCards.firstWhere(
        (card) => !legal.contains(card),
      );
      await session.submitCard(invalid);
      expect(session.view!.version, before);
    });

    test('real BEN errors never silently fall back to demo decisions', () async {
      final session = BridgeSession(
        botFactory: (_) => const RejectingBot(),
      );
      addTearDown(session.dispose);
      await session.newGame(humanSeat: Seat.east, mode: OpponentMode.ben);
      expect(session.errorCode, 'errorBot');
      expect(session.view!.auction, isEmpty);
      expect(session.mode, OpponentMode.ben);
      await session.retryBots();
      expect(session.view!.auction, isEmpty);
    });
  });
}

class RejectingBot implements BotPolicy {
  const RejectingBot();

  @override
  Future<GameAction> choose(PlayerView view) async =>
      throw const RuleViolation('BEN service is unavailable');
}

