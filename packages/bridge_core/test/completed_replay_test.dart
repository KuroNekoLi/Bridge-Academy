import 'package:bridge_core/bridge_core.dart';
import 'package:test/test.dart';

void main() {
  final deal = Deal.fromPbn(
    'N:AJ5.KQ7.A982.K76 32.9843.J73.Q943 '
    'QT6.AJ6.KT6.JT52 K9874.T52.Q54.A8',
  );

  test('M2-F11 completed replay is forbidden until terminal Pass Out', () async {
    final table = SinglePlayerCoordinator(
      deal: deal,
      dealer: Seat.north,
      vulnerability: Vulnerability.none,
      humanSeat: Seat.north,
      bot: const DeterministicTrainingBot(),
    );
    expect(table.completedReplay, isNull);
    table.submitHuman(
      const CallAction(Seat.north, Pass()),
      expectedVersion: 0,
    );
    expect(table.completedReplay, isNull);
    expect(await table.runBots(), 3);
    expect(table.finished, true);
    final replay = table.completedReplay!;
    expect(replay.frames.length, 5);
    expect(replay.lastIndex, 4);
    expect(replay.frames.first.action, isNull);
    expect(replay.frames.first.view.dummyCards, isNull);
    expect(replay.frames.first.view.ownCards.length, 13);
    for (var i = 1; i <= 4; i++) {
      expect(replay.frames[i].view.version, i);
      final action = replay.frames[i].action as CallAction;
      expect(action.actor, Seat.values[i - 1]);
      expect(action.call, isA<Pass>());
    }
    expect(replay.frames.last.view.nsScore, 0);
    expect(replay.frames.last.view.completedTricks, isEmpty);
    expect(replay.frames.last.view.phase, Phase.finished);

    final reconstructed = BridgeGame.replay(
      deal,
      Seat.north,
      Vulnerability.none,
      replay.frames.skip(1).map((f) => f.action!),
    );
    expect(reconstructed.isPassOut, true);
    expect(reconstructed.historyFingerprint, replay.historyFingerprint);
    expect(reconstructed.version, replay.lastIndex);
  });

  test('M2-F11 each of 52 plays is reconstructed through actual rules', () async {
    final table = SinglePlayerCoordinator(
      deal: deal,
      dealer: Seat.north,
      vulnerability: Vulnerability.none,
      humanSeat: Seat.north,
      bot: const DeterministicTrainingBot(),
    );
    table.submitHuman(
      const CallAction(Seat.north, Bid(1, Strain.notrump)),
      expectedVersion: 0,
    );
    expect(table.completedReplay, isNull);
    await table.runBots();
    expect(table.completedReplay, isNull);
    while (!table.finished) {
      final view = table.humanView;
      expect(view.canAct, true);
      table.submitHuman(
        CardAction(view.viewer, view.turn!, view.legalCards.first),
        expectedVersion: view.version,
      );
      await table.runBots();
    }
    final replay = table.completedReplay!;
    expect(replay.lastIndex, table.version);
    expect(replay.frames.length, table.version + 1);
    expect(replay.frames.where((f) => f.action is CallAction).length, 4);
    expect(replay.frames.where((f) => f.action is CardAction).length, 52);
    expect(replay.frames.first.view.dummyCards, isNull);
    expect(replay.frames.first.view.ownCards.length, 13);
    expect(replay.frames.first.view.toJson().containsKey('hands'), false);
    final startCards = replay.frames.first.view.toJson()['ownCards'] as List;
    expect(startCards.length, 13);

    for (var i = 0; i < replay.frames.length; i++) {
      final frame = replay.frames[i];
      expect(frame.view.viewer, Seat.north);
      expect(frame.view.version, i);
      expect(frame.view.completedTricks.length, lessThanOrEqualTo(13));
      if (frame.view.phase == Phase.auction ||
          (frame.view.phase == Phase.play &&
              frame.view.completedTricks.isEmpty &&
              frame.view.currentTrick.isEmpty)) {
        expect(frame.view.dummyCards, isNull,
            reason: 'Dummy not exposed before opening lead at frame $i');
      }
    }
    final dummyTurn = replay.frames.firstWhere(
      (f) => f.action is CardAction &&
          (f.action as CardAction).handOwner == Seat.south,
    );
    final dummyAction = dummyTurn.action as CardAction;
    expect(dummyAction.actor, Seat.north);
    expect(dummyTurn.view.dummyExposed, true);
    expect(replay.frames.last.view.completedTricks.length, 13);
    expect(replay.frames.last.view.remainingCards.values,
        everyElement(0));
    expect(replay.frames.last.view.nsScore, table.humanView.nsScore);
    expect(replay.frames.last.view.phase, Phase.finished);

    final rebuilt = BridgeGame.replay(
      deal,
      Seat.north,
      Vulnerability.none,
      replay.frames.skip(1).map((f) => f.action!),
    );
    expect(rebuilt.historyFingerprint, replay.historyFingerprint);
    expect(rebuilt.nsScore, table.humanView.nsScore);
    expect(rebuilt.tricks.length, 13);
  });
}

