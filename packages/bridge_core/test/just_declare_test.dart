import 'package:bridge_core/bridge_core.dart';
import 'package:test/test.dart';

void main() {
  test('B2 Just Declare begins play with no fabricated auction', () async {
    final deal = Deal.suitPerSeat();
    final contract = Contract(
      level: 3, strain: Strain.notrump, declarer: Seat.north,
    );
    final normal = GameState.start(deal, Seat.north, Vulnerability.none);
    expect(normal.phase, Phase.auction);
    expect(normal.isJustDeclare, false);

    final session = SinglePlayerCoordinator(
      deal: deal, dealer: Seat.north, vulnerability: Vulnerability.none,
      humanSeat: Seat.north, bot: const DeterministicTrainingBot(),
      justDeclareContract: contract,
    );
    expect(session.version, 0);
    expect(session.isJustDeclare, true);
    expect(session.humanView.phase, Phase.play);
    expect(session.humanView.auction, isEmpty);
    expect(session.humanView.contract!.label, '3NT');
    expect(session.humanView.turn, Seat.east);
    expect(session.humanView.dummyCards, isNull);
    expect(() => session.submitHuman(
      const CallAction(Seat.north, Pass()), expectedVersion: 0,
    ), throwsA(isA<RuleViolation>()));

    await session.runBots();
    expect(session.humanView.dummyExposed, true);
    expect(session.humanView.dummyCards, hasLength(13));
    expect(session.humanView.canAct, true);
    expect(session.humanView.turn, Seat.south);

    while (!session.finished) {
      final view = session.humanView;
      if (view.canAct) {
        session.submitHuman(CardAction(
          view.viewer, view.turn!, view.legalCards.first,
        ), expectedVersion: view.version);
      } else {
        await session.runBots();
      }
    }
    final view = session.humanView;
    expect(view.auction, isEmpty);
    expect(view.completedTricks, hasLength(13));
    expect(view.version, 52);
    expect(view.nsScore, isNotNull);
    final encoded = session.snapshotForTrustedStorage();
    expect(encoded['schemaVersion'], 2);
    final restored = GameTranscript.decode(
      Map<String, dynamic>.from(encoded),
    );
    expect(restored.isJustDeclare, true);
    expect(restored.events, hasLength(52));
    expect(restored.historyFingerprint, session.historyFingerprint);
    expect(restored.auction, isEmpty);
    expect(session.completedReplay!.frames.length, 53);
    expect(session.completedReplay!.frames.first.view.auction, isEmpty);
    expect(session.completedReplay!.frames.first.view.phase, Phase.play);
    expect(session.completedReplay!.frames.first.view.dummyCards, isNull);
    expect(session.completedReplay!.frames.last.view.completedTricks, hasLength(13));
  });

  test('B2 archive validation rejects malformed training metadata', () {
    final session = SinglePlayerCoordinator(
      deal: Deal.suitPerSeat(), dealer: Seat.north,
      vulnerability: Vulnerability.none, humanSeat: Seat.north,
      bot: const DeterministicTrainingBot(),
      justDeclareContract: const Contract(
        level: 4, strain: Strain.spades, declarer: Seat.north,
      ),
    );
    final raw = Map<String, dynamic>.from(
      session.snapshotForTrustedStorage(),
    );
    expect(raw['schemaVersion'], 2);
    final original = Map<String, dynamic>.from(
      raw['trainingContract'] as Map,
    );
    expect(() => GameTranscript.decode({
      ...raw, 'trainingContract': {...original, 'level': 8},
    }), throwsFormatException);
    expect(() => GameTranscript.decode({
      ...raw, 'trainingContract': {...original, 'doubling': 'redoubled'},
    }), throwsFormatException);
    expect(() => GameTranscript.decode({
      ...raw, 'trainingContract': {...original, 'declarer': 'Q'},
    }), throwsFormatException);
    expect(() => GameTranscript.decode({
      ...raw, 'schemaVersion': 1,
    }), throwsFormatException);

    final normal = SinglePlayerCoordinator(
      deal: Deal.suitPerSeat(), dealer: Seat.north,
      vulnerability: Vulnerability.none, humanSeat: Seat.north,
      bot: const DeterministicTrainingBot(),
    );
    expect(normal.snapshotForTrustedStorage()['schemaVersion'], 1);
  });
}
