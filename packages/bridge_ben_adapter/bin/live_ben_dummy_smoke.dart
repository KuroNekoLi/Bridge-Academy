import 'dart:convert';
import 'dart:io';

import 'package:bridge_ben_adapter/bridge_ben_adapter.dart';
import 'package:bridge_core/bridge_core.dart';

import 'live_ben_smoke.dart' show fixedPbn, MeasuredBenTransport;

/// A second true-BEN test: the robot must act as declarer and play cards
/// belonging to its publicly exposed dummy. No mock or fallback is permitted.
class AuditRobotDeclarer implements BotPolicy {
  AuditRobotDeclarer(this.delegate);

  final BenBotPolicy delegate;
  int dummyTurns = 0;

  @override
  Future<GameAction> choose(PlayerView view) async {
    final isDummyTurn = view.phase == Phase.play &&
        view.contract != null &&
        view.viewer == view.contract!.declarer &&
        view.turn == view.contract!.dummy;

    final proposal = await delegate.choose(view);
    if (isDummyTurn) {
      if (proposal is! CardAction ||
          proposal.actor != view.contract!.declarer ||
          proposal.handOwner != view.contract!.dummy) {
        throw StateError('BEN dummy decision did not target the dummy');
      }
      dummyTurns++;
    }
    return proposal;
  }
}

Future<void> main() async {
  final client = BenHttpTransport(
    baseUri: Uri.parse(
      Platform.environment['BEN_BASE_URL'] ?? 'http://127.0.0.1:8085',
    ),
    timeout: Duration(
      seconds: int.parse(
        Platform.environment['BEN_TIMEOUT_SECONDS'] ?? '120',
      ),
    ),
  );
  final transport = MeasuredBenTransport(client);
  final audited = AuditRobotDeclarer(BenBotPolicy(transport));
  final stopwatch = Stopwatch()..start();

  try {
    final coordinator = SinglePlayerCoordinator(
      deal: Deal.fromPbn(fixedPbn),
      dealer: Seat.north,
      vulnerability: Vulnerability.none,
      humanSeat: Seat.east,
      bot: audited,
    );

    // A human East defends and always Passes during bidding. This leaves the
    // strong North hand and North/South partnership to BEN for natural bids.
    for (var step = 0; step < 120 && !coordinator.finished; step++) {
      await coordinator.runBots(maxActions: 100);
      if (coordinator.finished) break;
      final view = coordinator.humanView;
      if (!view.canAct) {
        throw StateError('Expected human East turn');
      }
      final GameAction action;
      if (view.phase == Phase.auction) {
        action = const CallAction(Seat.east, Pass());
      } else if (view.phase == Phase.play && view.turn != null) {
        if (view.legalCards.isEmpty) {
          throw StateError('Human East must have legal play');
        }
        action = CardAction(
          Seat.east,
          view.turn!,
          view.legalCards.first,
        );
      } else {
        throw StateError('Unknown game phase');
      }
      coordinator.submitHuman(action, expectedVersion: view.version);
    }

    if (!coordinator.finished) {
      throw StateError('Live robot-declarer test exceeded action budget');
    }
    final view = coordinator.humanView;
    if (view.completedTricks.length != 13 ||
        view.remainingCards.values.any((n) => n != 0) ||
        view.nsScore == null ||
        view.version != view.auction.length + 52 ||
        audited.dummyTurns < 1 ||
        (transport.counts['/bid'] ?? 0) < 1 ||
        (transport.counts['/play'] ?? 0) < 1) {
      throw StateError('Live robot dummy play acceptance not met');
    }

    stopwatch.stop();
    stdout.writeln(jsonEncode({
      'status': 'PASS',
      'type': 'LIVE_BEN_DECLARER_DUMMY_NO_MOCK',
      'fixture': 'N-BRIDGEACADEMY-20261015',
      'contract': view.contract?.label,
      'declarer': view.contract?.declarer.letter,
      'auction': [for (final entry in view.auction) entry.call.code],
      'tricks': view.completedTricks.length,
      'cards': 52,
      'nsScore': view.nsScore,
      'botControlledDummyTurns': audited.dummyTurns,
      'benSuccessfulRequests': transport.counts,
      'elapsedMs': stopwatch.elapsedMilliseconds,
      'realBen': true,
    }));
  } catch (error) {
    stderr.writeln('LIVE_BEN_DUMMY_FAIL: $error');
    exitCode = 1;
  } finally {
    client.close();
  }
}

