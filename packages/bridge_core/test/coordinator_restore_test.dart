import 'package:bridge_core/bridge_core.dart';
import 'package:test/test.dart';

void main() {
  final deal = Deal.fromPbn(
    'N:AJ5.KQ7.A982.K76 32.9843.J73.Q943 '
    'QT6.AJ6.KT6.JT52 K9874.T52.Q54.A8',
  );

  test('P1-A2: mid-auction checkpoint resumes exact version and hand', () {
    final original = SinglePlayerCoordinator(
      deal: deal, dealer: Seat.north, vulnerability: Vulnerability.ns,
      humanSeat: Seat.north, bot: const DeterministicTrainingBot(),
    );
    original.submitHuman(
      const CallAction(Seat.north, Bid(1, Strain.notrump)),
      expectedVersion: 0,
    );
    final save = original.snapshotForTrustedStorage();
    final restored = SinglePlayerCoordinator.restore(
      trustedStorageArchive: save, humanSeat: Seat.north,
      bot: const DeterministicTrainingBot(),
    );
    expect(restored.version, 1);
    expect(restored.humanView.auction.length, 1);
    expect(restored.humanView.ownCards, original.humanView.ownCards);
    expect(restored.humanView.vulnerability, Vulnerability.ns);
    expect(restored.humanView.dummyCards, isNull);
    expect(restored.completedReplay, isNull);
    expect(restored.historyFingerprint, original.historyFingerprint);
    expect(
      () => restored.submitHuman(
        const CallAction(Seat.north, Pass()), expectedVersion: 0),
      throwsA(isA<RuleViolation>()),
    );
  });

  test('P1-A2: bot commits call checkpoint once per legal action', () async {
    final coordinator = SinglePlayerCoordinator(
      deal: deal, dealer: Seat.east, vulnerability: Vulnerability.ew,
      humanSeat: Seat.north, bot: const DeterministicTrainingBot(),
    );
    final versions = <int>[];
    final archives = <Map<String, Object?>>[];
    await coordinator.runBots(afterCommittedAction: () async {
      versions.add(coordinator.version);
      archives.add(coordinator.snapshotForTrustedStorage());
    });
    expect(versions, [1, 2, 3]);
    for (var i = 0; i < archives.length; i++) {
      final restored = SinglePlayerCoordinator.restore(
        trustedStorageArchive: archives[i],
        humanSeat: Seat.north, bot: const DeterministicTrainingBot(),
      );
      expect(restored.version, i + 1);
    }
    expect(coordinator.humanView.canAct, true);
  });

  test('P1-A2: corrupted event version cannot be restored', () {
    final original = SinglePlayerCoordinator(
      deal: deal, dealer: Seat.north, vulnerability: Vulnerability.none,
      humanSeat: Seat.north, bot: const DeterministicTrainingBot(),
    );
    original.submitHuman(
      const CallAction(Seat.north, Pass()), expectedVersion: 0);
    final archive = original.snapshotForTrustedStorage();
    final corrupted = <String, dynamic>{...archive,
      'events': [
        {'version': 7, 'type': 'call', 'actor': 'N', 'call': 'PASS'},
      ],
    };
    expect(
      () => SinglePlayerCoordinator.restore(
        trustedStorageArchive: corrupted, humanSeat: Seat.north,
        bot: const DeterministicTrainingBot(),
      ),
      throwsFormatException,
    );
  });

  test('P1-A2: partial play rehydrates dummy and legal follow-suit', () async {
    final game = SinglePlayerCoordinator(
      deal: deal, dealer: Seat.north, vulnerability: Vulnerability.both,
      humanSeat: Seat.north, bot: const DeterministicTrainingBot(),
    );
    game.submitHuman(
      const CallAction(Seat.north, Bid(1, Strain.notrump)),
      expectedVersion: 0);
    await game.runBots(); // Three passes, East opening lead, North controls dummy.
    final view = game.humanView;
    expect(view.dummyExposed, isTrue);
    expect(view.turn, Seat.south);
    game.submitHuman(
      CardAction(Seat.north, Seat.south, view.legalCards.first),
      expectedVersion: view.version);
    final snapshot = game.snapshotForTrustedStorage();
    final loaded = SinglePlayerCoordinator.restore(
      trustedStorageArchive: snapshot, humanSeat: Seat.north,
      bot: const DeterministicTrainingBot(),
    );
    expect(loaded.version, game.version);
    expect(loaded.humanView.dummyCards, game.humanView.dummyCards);
    expect(loaded.humanView.currentTrick.length,
        game.humanView.currentTrick.length);
    expect(loaded.humanView.legalCards, game.humanView.legalCards);
    expect(loaded.historyFingerprint, game.historyFingerprint);
  });
}
