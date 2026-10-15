import 'package:bridge_core/bridge_core.dart';
import 'package:test/test.dart';

/// All actual choices remain subject to BridgeGame.apply. The scripted bot
/// exercises X/XX, but it never computes or forges a winner or score.
class _RedoubleBot implements BotPolicy {
  const _RedoubleBot();

  @override
  Future<GameAction> choose(PlayerView view) async {
    if (view.phase == Phase.auction) {
      final Call call = switch (view.auction.length) {
        1 => const DoubleCall(),
        2 => const RedoubleCall(),
        _ => const Pass(),
      };
      return CallAction(view.viewer, call);
    }
    if (view.phase != Phase.play || view.legalCards.isEmpty) {
      throw StateError('Bot called outside legal play');
    }
    return CardAction(view.viewer, view.turn!, view.legalCards.first);
  }
}

void main() {
  final deal = Deal.fromPbn(
    'N:AJ5.KQ7.A982.K76 32.9843.J73.Q943 '
    'QT6.AJ6.KT6.JT52 K9874.T52.Q54.A8',
  );

  test('M2-F11.1: four dealers and vulnerabilities preserve Pass Out history',
      () async {
    for (final dealer in Seat.values) {
      final table = SinglePlayerCoordinator(
        deal: deal,
        dealer: dealer,
        vulnerability: Vulnerability.values[dealer.index],
        humanSeat: dealer,
        bot: const DeterministicTrainingBot(),
      );
      expect(table.completedReplay, isNull);
      table.submitHuman(
        CallAction(dealer, const Pass()),
        expectedVersion: 0,
      );
      expect(table.completedReplay, isNull);
      expect(await table.runBots(), 3);
      final replay = table.completedReplay!;
      expect(replay.frames.length, 5);
      expect(replay.lastIndex, 4);
      expect(replay.frames.first.view.version, 0);
      expect(replay.frames.first.view.viewer, dealer);
      expect(replay.frames.first.view.vulnerability,
          Vulnerability.values[dealer.index]);
      expect(replay.frames.every((frame) => frame.view.dummyCards == null),
          isTrue);
      for (var i = 1; i <= 4; i++) {
        expect(replay.frames[i].view.version, i);
        expect(replay.frames[i].action, isA<CallAction>());
        expect((replay.frames[i].action as CallAction).actor,
            Seat.values[(dealer.index + i - 1) % 4]);
      }
      expect(replay.frames.last.view.phase, Phase.finished);
      expect(replay.frames.last.view.nsScore, 0);
      expect(replay.frames.last.view.completedTricks, isEmpty);
    }
  });

  test('M2-F11.1: X/XX full replay is immutable and rejects altered archive',
      () async {
    final table = SinglePlayerCoordinator(
      deal: deal,
      dealer: Seat.north,
      vulnerability: Vulnerability.both,
      humanSeat: Seat.north,
      bot: const _RedoubleBot(),
    );
    table.submitHuman(
      const CallAction(Seat.north, Bid(1, Strain.spades)),
      expectedVersion: 0,
    );
    expect(table.completedReplay, isNull);
    expect(await table.runBots(), 3); // E doubles; S redoubles; W passes.
    expect(table.completedReplay, isNull);
    table.submitHuman(const CallAction(Seat.north, Pass()),
        expectedVersion: table.version);
    await table.runBots(); // E's final pass and opening lead.
    expect(table.completedReplay, isNull);

    while (!table.finished) {
      final view = table.humanView;
      expect(view.canAct, isTrue);
      table.submitHuman(
        CardAction(view.viewer, view.turn!, view.legalCards.first),
        expectedVersion: view.version,
      );
      await table.runBots();
    }

    final replay = table.completedReplay!;
    expect(replay.frames.length, 59); // Initial + 6 calls + 52 cards.
    expect(replay.frames.first.view.dummyCards, isNull);
    expect(replay.frames.first.view.ownCards.length, 13);
    expect(replay.frames.last.view.contract!.doubling, Doubling.redoubled);
    expect(replay.frames.last.view.completedTricks.length, 13);
    expect(replay.frames.last.view.remainingCards.values, everyElement(0));
    expect(replay.frames.last.view.nsScore, table.humanView.nsScore);
    expect(replay.frames.where((f) => f.action is CardAction).length, 52);
    expect(
      replay.frames.where((f) {
        final action = f.action;
        return action is CardAction && action.handOwner == Seat.south &&
            action.actor == Seat.north;
      }).length,
      13,
    );

    // Neither the frame collection nor the projected historical state can
    // be mutated by Flutter; the archive containing four hands stays private.
    expect(() => replay.frames.clear(), throwsUnsupportedError);
    expect(() => replay.frames.first.view.ownCards.clear(),
        throwsUnsupportedError);
    expect(() => replay.frames.last.view.auction.clear(),
        throwsUnsupportedError);
    expect(() => replay.frames.last.view.remainingCards.clear(),
        throwsUnsupportedError);
    for (final frame in replay.frames) {
      expect(frame.view.viewer, Seat.north);
      final json = frame.view.toJson();
      expect(json.containsKey('dealPbn'), isFalse);
      expect(json.containsKey('hands'), isFalse);
      expect(json.containsKey('events'), isFalse);
    }

    final original = BridgeGame.replay(
      deal, Seat.north, Vulnerability.both,
      replay.frames.skip(1).map((f) => f.action!),
    );
    expect(original.isFinished, isTrue);
    expect(original.historyFingerprint, replay.historyFingerprint);

    // GameTranscript is intentionally a privileged, complete-hand archive.
    // It is decoded here only in the domain test, never sent to a player.
    final archive = GameTranscript.encode(original);
    final decoded = GameTranscript.decode(archive);
    expect(decoded.historyFingerprint, replay.historyFingerprint);
    expect(decoded.nsScore, original.nsScore);

    List<Map<String, dynamic>> cloneEvents() =>
        (archive['events']! as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
    final wrongVersion = cloneEvents();
    wrongVersion[1]['version'] = 99;
    expect(
      () => GameTranscript.decode({...archive, 'events': wrongVersion}),
      throwsA(isA<FormatException>()),
    );

    final wrongActor = cloneEvents();
    wrongActor[1]['actor'] = 'W'; // Only East may double North here.
    expect(
      () => GameTranscript.decode({...archive, 'events': wrongActor}),
      throwsA(isA<RuleViolation>()),
    );

    final badOwner = cloneEvents();
    final firstPlay = badOwner.indexWhere((event) => event['type'] == 'play');
    expect(firstPlay, greaterThanOrEqualTo(0));
    badOwner[firstPlay]['handOwner'] = 'N'; // Opening leader is East.
    expect(
      () => GameTranscript.decode({...archive, 'events': badOwner}),
      throwsA(isA<RuleViolation>()),
    );
  });

  test('M2-F11.1: three visible passes are not a completed Pass Out', () {
    final initial = GameState.start(
      deal, Seat.north, Vulnerability.none,
    );
    var state = initial;
    for (final seat in [Seat.north, Seat.east, Seat.south]) {
      state = BridgeGame.apply(state, CallAction(seat, const Pass()));
    }
    final decoded = GameTranscript.decode(GameTranscript.encode(state));
    expect(decoded.isFinished, isFalse);
    expect(decoded.isPassOut, isFalse);
    expect(decoded.version, 3);
    expect(decoded.nsScore, isNull);
  });
}

