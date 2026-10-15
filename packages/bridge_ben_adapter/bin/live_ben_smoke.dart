import 'dart:convert';
import 'dart:io';

import 'package:bridge_ben_adapter/bridge_ben_adapter.dart';
import 'package:bridge_core/bridge_core.dart';

/// A real network-only acceptance test. No MockClient or fallback BotPolicy.
/// Intended to run with a separately started, pinned BEN gameapi.py service.
///
/// The fixed board is intentionally non-secret. Do not print HTTP URLs or
/// individual BEN queries because GET /bid carries the robot's private hand.
const fixedPbn = 'N:AJ5.KQ7.A982.K76 32.9843.J73.Q943 '
    'QT6.AJ6.KT6.JT52 K9874.T52.Q54.A8';

class MeasuredBenTransport implements BenTransport {
  MeasuredBenTransport(this.delegate);

  final BenTransport delegate;
  final counts = <String, int>{};
  final durationsMs = <int>[];

  @override
  Future<Map<String, dynamic>> get(
    String route,
    Map<String, String> query,
  ) async {
    final timer = Stopwatch()..start();
    try {
      final result = await delegate.get(route, query);
      counts.update(route, (count) => count + 1, ifAbsent: () => 1);
      return result;
    } finally {
      timer.stop();
      durationsMs.add(timer.elapsedMilliseconds);
    }
  }
}

Future<void> main(List<String> args) async {
  // A missing BEN service must fail, never silently switch to a fake bot.
  final url = Uri.parse(
    Platform.environment['BEN_BASE_URL'] ?? 'http://127.0.0.1:8085',
  );
  final timeout = int.parse(
    Platform.environment['BEN_TIMEOUT_SECONDS'] ?? '120',
  );
  final real = BenHttpTransport(
    baseUri: url,
    timeout: Duration(seconds: timeout),
  );
  final measured = MeasuredBenTransport(real);
  final start = Stopwatch()..start();

  try {
    final coordinator = SinglePlayerCoordinator(
      deal: Deal.fromPbn(fixedPbn),
      dealer: Seat.north,
      vulnerability: Vulnerability.none,
      humanSeat: Seat.north,
      bot: BenBotPolicy(measured),
    );

    // Fixed 3NT opening guarantees a contract and an AI opening leader;
    // robots still decide all three other seats and every card they control.
    // This is an integration fixture, not a convention-quality benchmark.
    coordinator.submitHuman(
      const CallAction(Seat.north, Bid(3, Strain.notrump)),
      expectedVersion: coordinator.version,
    );

    for (var step = 0; step < 120 && !coordinator.finished; step++) {
      await coordinator.runBots(maxActions: 100);
      if (coordinator.finished) break;
      final view = coordinator.humanView;
      if (!view.canAct) {
        throw StateError('Coordinator failed to yield to the human');
      }
      final GameAction action;
      if (view.phase == Phase.auction) {
        action = const CallAction(Seat.north, Pass());
      } else if (view.phase == Phase.play && view.turn != null) {
        if (view.legalCards.isEmpty) {
          throw StateError('Human has no legal card');
        }
        action = CardAction(Seat.north, view.turn!, view.legalCards.first);
      } else {
        throw StateError('Unknown phase during live acceptance');
      }
      coordinator.submitHuman(action, expectedVersion: view.version);
    }

    if (!coordinator.finished) {
      throw StateError('Live BEN smoke exceeded action budget');
    }
    final result = coordinator.humanView;
    if (result.completedTricks.length != 13 ||
        result.remainingCards.values.any((value) => value != 0) ||
        result.nsScore == null ||
        result.version != result.auction.length + 52) {
      throw StateError('Invalid terminal 52-card / 13-trick outcome');
    }
    for (final route in ['/bid', '/lead', '/play']) {
      if ((measured.counts[route] ?? 0) < 1) {
        throw StateError('No actual BEN call for $route');
      }
    }
    start.stop();
    // No cards/hands or raw query strings are written to GitHub logs.
    stdout.writeln(jsonEncode({
      'status': 'PASS',
      'type': 'LIVE_BEN_HTTP_NO_MOCK',
      'dealFixture': 'N-BRIDGEACADEMY-20261015',
      'contract': result.contract?.label,
      'declarer': result.contract?.declarer.letter,
      'auctionCount': result.auction.length,
      'auction': [for (final entry in result.auction) entry.call.code],
      'tricks': result.completedTricks.length,
      'cards': 52,
      'nsScore': result.nsScore,
      'terminalVersion': result.version,
      'benSuccessfulRequests': measured.counts,
      'elapsedMs': start.elapsedMilliseconds,
      'individualBenRequestMs': measured.durationsMs,
      'realBen': true,
    }));
  } catch (error) {
    stderr.writeln('LIVE_BEN_FAIL: $error');
    exitCode = 1;
  } finally {
    real.close();
  }
}

