import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_gateway/bridge_gateway.dart';

// Same pinned, non-secret fixed board as bridge_ben_adapter/live_ben_smoke.dart.
// This fixture is injected on the SERVER ONLY; never sent through client APIs.
// A true model runs at 127.0.0.1:8085; this script contains no fake backend.
const _fixture = 'N:AJ5.KQ7.A982.K76 32.9843.J73.Q943 '
    'QT6.AJ6.KT6.JT52 K9874.T52.Q54.A8';

class _MeasuredRealBen implements SystemAwareDecisionBackend {
  _MeasuredRealBen(this.actual);
  final BenLoopbackBackend actual;

  @override
  Future<bool> supportsGameSystems(GameSystems systems) =>
      actual.supportsGameSystems(systems);
  final counts = <String, int>{};
  final durations = <int>[];

  @override
  Future<Map<String, Object?>> decide(
      String route, Map<String, String> fields) async {
    final timer = Stopwatch()..start();
    try {
      final result = await actual.decide(route, fields);
      counts.update(route, (old) => old + 1, ifAbsent: () => 1);
      return result;
    } finally {
      timer.stop();
      durations.add(timer.elapsedMilliseconds);
      // Do not log fields, BEN URLs, private hands, or raw exceptions.
    }
  }
}

class _SafeHttpFailure implements Exception {
  _SafeHttpFailure(this.status);
  final int status;
}

Future<Map<String, dynamic>> _post(
    int port, String path, Map<String, Object?> body,
    {String? token}) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(
        Uri.parse('http://127.0.0.1:$port$path'));
    req.headers.contentType = ContentType.json;
    if (token != null) {
      req.headers.set('Authorization', 'Bearer $token');
    }
    req.write(jsonEncode(body));
    final res = await req.close().timeout(const Duration(minutes: 12));
    final data = await utf8.decoder.bind(res).join();
    if (res.statusCode != (path == '/v1/sessions/anonymous' ? 201 : 200)) {
      // Never forward the server body or request in a test failure.
      throw _SafeHttpFailure(res.statusCode);
    }
    return jsonDecode(data) as Map<String, dynamic>;
  } finally {
    client.close(force: true);
  }
}

Map<String, dynamic> _safeView(Map<String, dynamic> response) {
  if (response.keys.toSet().difference(
      const {'version', 'view', 'request_id'}).isNotEmpty ||
      response['version'] != 1 ||
      response['view'] is! Map<String, dynamic>) {
    throw StateError('Unexpected top-level view projection');
  }
  final view = response['view'] as Map<String, dynamic>;
  if (view.keys.any(const {'deal', 'dealPbn', 'hands', 'transcript', 'token'}
      .contains) ||
      view['viewer'] != 'N' ||
      view['ownCards'] is! List ||
      (view['dummyExposed'] != true && view['dummyCards'] != null)) {
    throw StateError('Unfiltered or invalid server player view');
  }
  return view;
}

Map<String, Object?> _request(
        int version, String requestId, [Map<String, Object?>? action]) =>
    {
      'version': 1,
      'expected_version': version,
      'request_id': requestId,
      if (action != null) 'action': action,
    };

void _verifyFinal(Map<String, dynamic> view,
    Map<String, int> realBenCounts) {
  if (view['phase'] != 'finished' ||
      view['nsScore'] is! int ||
      view['contract'] == null ||
      view['dummyExposed'] != true) {
    throw StateError('Not a completed contracted bridge game');
  }
  final auction = view['auction'] as List<dynamic>;
  final tricks = view['completedTricks'] as List<dynamic>;
  final remaining = view['remainingCards'] as Map<String, dynamic>;
  final playedCards = <String>{};
  if (tricks.length != 13 ||
      remaining.length != 4 ||
      remaining.values.any((n) => n != 0) ||
      view['currentTrick'] is! List ||
      (view['currentTrick'] as List).isNotEmpty ||
      view['version'] != auction.length + 52) {
    throw StateError('Trick-count, version, or score invariant failed');
  }
  for (final record in tricks) {
    final trick = record as Map<String, dynamic>;
    final plays = trick['plays'] as List<dynamic>;
    if (plays.length != 4 ||
        !const {'N', 'E', 'S', 'W'}.contains(trick['winner'])) {
      throw StateError('Invalid completed trick');
    }
    final handOwners = <String>{};
    for (final raw in plays) {
      final card = raw as Map<String, dynamic>;
      if (card['card'] is! String ||
          !RegExp(r'^[CDHS][2-9TJQKA]$').hasMatch(card['card'] as String) ||
          !playedCards.add(card['card'] as String) ||
          !handOwners.add(card['seat'] as String)) {
        throw StateError('Duplicate card, seat, or illegal card format');
      }
    }
    if (handOwners.length != 4) {
      throw StateError('A trick must contain four distinct hands');
    }
  }
  if (playedCards.length != 52 ||
      realBenCounts['bid'] == null ||
      realBenCounts['lead'] == null ||
      realBenCounts['play'] == null) {
    throw StateError('Not 52 unique cards or missing genuine BEN route');
  }
}

Future<void> main() async {
  final upstream = BenLoopbackBackend(
    origin: Uri.parse('http://127.0.0.1:8085'),
    timeout: const Duration(seconds: 120),
    pinnedBenRevision: ConventionCatalog.benCandidateRevision,
  );
  final backend = _MeasuredRealBen(upstream);
  final swap = Platform.environment['M2_SWAP_SYSTEMS'] == 'true';
  final pinned = GameSystems(
    northSouth: swap ? ConventionCatalog.sayc : ConventionCatalog.twoOverOne,
    eastWest: swap ? ConventionCatalog.twoOverOne : ConventionCatalog.sayc,
  );
  // Longer TTL/large quota are test-only, to cover a complete CPU-heavy game.
  final gateway = BridgeGatewayService(
    backend: backend,
    dealFactory: () => Deal.fromPbn(_fixture),
    gameSystems: pinned,
    config: const GatewayConfig(
      sessionTtl: Duration(hours: 1),
      decisionTimeout: Duration(minutes: 11),
      decisionLimit: 300,
    ),
  );

  String stepName = 'startup';
  final elapsed = Stopwatch()..start();
  try {
    final port = await gateway.start();
    stepName = 'bootstrap';
    final issued = await _post(
        port, '/v1/sessions/anonymous', {
          'version': 1,
          'game_systems': {
            'northSouth': pinned.northSouth.profileId,
            'eastWest': pinned.eastWest.profileId,
          },
        });
    if (GameSystems.fromTrustedJson(issued['game_systems']) != pinned) {
      throw StateError('Failed pinned NS/EW system identity');
    }
    final bearer = issued['access_token'] as String;

    stepName = 'initial-view';
    final initial = _safeView(await _post(
        port, '/v1/games/view', {'version': 1}, token: bearer));
    if (initial['version'] != 0 ||
        initial['phase'] != 'auction' ||
        (initial['ownCards'] as List).length != 13) {
      throw StateError('Initial version/hand invalid');
    }

    var actionCount = 0;
    var advanceCount = 0;
    var state = initial;
    var nextId = 0;
    Map<String, dynamic>? firstResponse;
    Map<String, Object?>? firstPayload;

    for (var loop = 0; loop < 125 && state['phase'] != 'finished'; loop++) {
      final version = state['version'] as int;
      final before = version;
      final id = 'fullgame_${(nextId++).toString().padLeft(5, '0')}';
      final Map<String, dynamic> result;
      if (state['canAct'] == true) {
        stepName = 'human-action';
        final Map<String, Object?> action;
        if (state['phase'] == 'auction') {
          action = {
            'kind': 'bid',
            'call': version == 0 ? '3NT' : 'PASS',
          };
        } else if (state['phase'] == 'play') {
          final legal = state['legalCards'] as List<dynamic>;
          if (legal.isEmpty || state['turn'] == null) {
            throw StateError('Human has no legal action');
          }
          action = {'kind': 'play', 'card': legal.first as String};
        } else {
          throw StateError('Unexpected human phase');
        }
        final payload = _request(version, id, action);
        result = await _post(port, '/v1/games/action', payload, token: bearer);
        actionCount++;
        if (firstPayload == null) {
          firstPayload = payload;
          firstResponse = result;
        }
      } else {
        stepName = 'real-BEN-batch';
        result = await _post(
            port, '/v1/games/advance', _request(version, id),
            token: bearer);
        advanceCount++;
      }
      state = _safeView(result);
      if ((state['version'] as int) <= before ||
          (state['version'] as int) > before + 60) {
        throw StateError('Gateway action did not advance monotonically');
      }
    }

    stepName = 'end-state-validation';
    _verifyFinal(state, backend.counts);

    stepName = 'idempotency-replay';
    final old = await _post(
        port, '/v1/games/action', firstPayload!, token: bearer);
    if (jsonEncode(old) != jsonEncode(firstResponse) ||
        _safeView(await _post(
          port, '/v1/games/view', {'version': 1}, token: bearer,
        ))['version'] != state['version']) {
      throw StateError('Completed request replay mutated game');
    }

    elapsed.stop();
    final durations = [...backend.durations]..sort();
    stdout.writeln(jsonEncode({
      'status': 'PASS',
      'type': 'M2_5_REAL_BEN_MULTISYSTEM_FULL_GAME',
      'northSouth': pinned.northSouth.modelId,
      'eastWest': pinned.eastWest.modelId,
      'gameFingerprint': pinned.fingerprint,
      'realBen': true,
      'gateway': 'POST_AUTHORIZED_SERVER_GAME',
      'upstream': 'PINNED_BEN_GET_LOOPBACK',
      'fixture': 'N-BRIDGEACADEMY-20261015',
      'contract': state['contract'],
      'auctionCount': (state['auction'] as List).length,
      'tricks': (state['completedTricks'] as List).length,
      'uniqueCards': 52,
      'terminalVersion': state['version'],
      'nsScore': state['nsScore'],
      'humanActions': actionCount,
      'botBatches': advanceCount,
      'benSuccessfulRequests': backend.counts,
      'benCallCount': backend.durations.length,
      'benP95Ms': durations[(durations.length * 0.95).ceil() - 1],
      'benMaxMs': durations.last,
      'elapsedMs': elapsed.elapsedMilliseconds,
    }));
  } on _SafeHttpFailure catch (e) {
    stderr.writeln('M2_5_MULTISYSTEM_FULL_GAME_FAIL step=$stepName http=${e.status}');
    exitCode = 1;
  } catch (_) {
    // Errors may contain a BEN URL, full PBN or access token. NEVER echo them.
    stderr.writeln('M2_5_MULTISYSTEM_FULL_GAME_FAIL step=$stepName');
    exitCode = 1;
  } finally {
    await gateway.close();
    upstream.close();
  }
}
