import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bridge_core/bridge_core.dart';
import 'package:crypto/crypto.dart';
import 'package:bridge_gateway/src/a6_board_fixtures.dart';
import 'package:bridge_gateway/bridge_gateway.dart';

// Same pinned, non-secret fixed board as bridge_ben_adapter/live_ben_smoke.dart.
// This fixture is injected on the SERVER ONLY; never sent through client APIs.
// A true model runs at 127.0.0.1:8085; this script contains no fake backend.
const _fixture = 'N:AJ5.KQ7.A982.K76 32.9843.J73.Q943 '
    'QT6.AJ6.KT6.JT52 K9874.T52.Q54.A8';

class _MeasuredRealBen implements GatewayDecisionBackend {
  _MeasuredRealBen(this.actual);
  final BenLoopbackBackend actual;
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


void _checkFinalScore(Map<String, dynamic> state) {
  final raw = state['contract'] as Map<String, dynamic>;
  final contract = Contract(
    level: raw['level'] as int,
    strain: Strain.values.firstWhere((s) => s.code == raw['strain']),
    declarer: Seat.fromLetter(raw['declarer'] as String),
    doubling: Doubling.values.byName(raw['doubling'] as String),
  );
  final tricks = state['completedTricks'] as List;
  final made = tricks.where((t) {
    final winner = Seat.fromLetter((t as Map)['winner'] as String);
    return winner.isNS == contract.declarer.isNS;
  }).length;
  final vul = Vulnerability.values.byName(state['vulnerability'] as String);
  if (state['nsScore'] != DuplicateScore.score(contract, made, vul)) {
    throw StateError('DuplicateScore mismatch');
  }
}

void _checkPassOut(Map<String, dynamic> state) {
  final calls = state['auction'] as List;
  if (state['phase'] != 'finished' || state['contract'] != null ||
      state['nsScore'] != 0 || calls.length != 4 ||
      calls.any((v) => (v as Map)['call'] != 'PASS') ||
      (state['completedTricks'] as List).isNotEmpty ||
      state['version'] != 4) {
    throw StateError('Invalid four-Pass terminal auction');
  }
}

int _p95(List<int> values) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  return sorted[(sorted.length * 0.95).ceil() - 1];
}

// A model may open before North acts. Outrank its highest public bid so
// this is a bounded full-card-play regression, not an expert bidding lesson.
String _opening(String wanted, List<dynamic> auction) {
  int rank(String bid) {
    final m = RegExp(r'^([1-7])(C|D|H|S|NT)$').firstMatch(bid);
    if (m == null) return 0;
    return (int.parse(m.group(1)!) - 1) * 5 +
        ['C', 'D', 'H', 'S', 'NT'].indexOf(m.group(2)!) + 1;
  }
  var highest = 0;
  for (final raw in auction) {
    final found = rank((raw as Map)['call'] as String);
    if (found > highest) highest = found;
  }
  return rank(wanted) > highest ? wanted : (rank('7NT') > highest ? '7NT' : 'PASS');
}

Future<int> _status(int port, String path, Map<String, Object?> data,
    {String? bearer}) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(Uri.parse('http://127.0.0.1:$port$path'));
    req.headers.contentType = ContentType.json;
    if (bearer != null) req.headers.set('Authorization', 'Bearer $bearer');
    req.write(jsonEncode(data));
    final res = await req.close().timeout(const Duration(seconds: 10));
    await res.drain<void>();
    return res.statusCode;
  } finally {
    client.close(force: true);
  }
}

Future<Map<String, Object?>> _runBoard(
    A6BoardFixture fixture, BenLoopbackBackend ben) async {
  final counted = _MeasuredRealBen(ben);
  final gateway = BridgeGatewayService(
    backend: counted,
    dealFactory: () => fixture.deal,
    trainingBoard: fixture.metadata,
    config: const GatewayConfig(
      sessionTtl: Duration(hours: 2),
      decisionTimeout: Duration(minutes: 11),
      decisionLimit: 500,
    ),
  );
  final timer = Stopwatch()..start();
  var phase = 'start';
  try {
    final port = await gateway.start();
    phase = 'auth';
    if (await _status(port, '/v1/games/view', {'version': 1}) != 401) {
      throw StateError('Unauthenticated access accepted');
    }
    final boot = await _post(port, '/v1/sessions/anonymous', {'version': 1});
    final bearer = boot['access_token'] as String;
    var state = _safeView(await _post(
        port, '/v1/games/view', {'version': 1}, token: bearer));
    if (state['version'] != 0 || state['phase'] != 'auction' ||
        (state['ownCards'] as List).length != 13 ||
        state['dealer'] != fixture.metadata.dealer.letter ||
        state['vulnerability'] != fixture.metadata.vulnerability.name) {
      throw StateError('Wrong server-owned initial board');
    }
    phase = 'forgery';
    if (await _status(port, '/v1/games/action', {
          ..._request(0, 'a6_fake_action', {'kind': 'bid', 'call': 'PASS'}),
          'deal': 'INVALID_CLIENT_DEAL',
        }, bearer: bearer) != 400) {
      throw StateError('Client deal injection was not blocked');
    }
    state = _safeView(await _post(
        port, '/v1/games/view', {'version': 1}, token: bearer));
    if (state['version'] != 0) throw StateError('Forgery changed version');

    var acted = false;
    var human = 0;
    var batches = 0;
    Map<String, Object?>? firstPayload;
    Map<String, dynamic>? firstResponse;
    String? firstEndpoint;
    var seq = 0;
    phase = 'genuine-bid-lead-play';
    for (var loop = 0; loop < 160 && state['phase'] != 'finished'; loop++) {
      final before = state['version'] as int;
      final requestId = 'a6_${fixture.number}_${(seq++).toString().padLeft(5, '0')}';
      final String endpoint;
      final Map<String, Object?> payload;
      if (state['canAct'] == true) {
        endpoint = '/v1/games/action';
        final Map<String, Object?> action;
        if (state['phase'] == 'auction') {
          action = {'kind': 'bid',
            'call': !acted
                ? _opening(fixture.openingCall, state['auction'] as List)
                : 'PASS'};
          acted = true;
        } else {
          final cards = state['legalCards'] as List;
          if (cards.isEmpty) throw StateError('Empty legal card list');
          action = {'kind': 'play', 'card': cards.first as String};
        }
        payload = _request(before, requestId, action);
        human++;
      } else {
        endpoint = '/v1/games/advance';
        payload = _request(before, requestId);
        batches++;
      }
      final full = await _post(port, endpoint, payload, token: bearer);
      final next = _safeView(full);
      if ((next['version'] as int) <= before ||
          (next['version'] as int) > before + 60) {
        throw StateError('Core event version did not advance');
      }
      if (firstPayload == null) {
        firstPayload = payload;
        firstEndpoint = endpoint;
        firstResponse = full;
      }
      state = next;
    }
    phase = 'terminal-verification';
    final passOut = state['contract'] == null;
    if (passOut) {
      _checkPassOut(state);
    } else {
      _verifyFinal(state, counted.counts);
      _checkFinalScore(state);
    }
    phase = 'replay';
    final replay = await _post(
        port, firstEndpoint!, firstPayload!, token: bearer);
    if (jsonEncode(replay) != jsonEncode(firstResponse) ||
        _safeView(await _post(
            port, '/v1/games/view', {'version': 1},
            token: bearer))['version'] != state['version']) {
      throw StateError('Idempotent replay changed final event version');
    }
    phase = 'stale-rejection';
    if (await _status(port, firstEndpoint,
        {...firstPayload, 'request_id': 'a6_stale_${fixture.number}'},
        bearer: bearer) != 409) {
      throw StateError('Stale version was not rejected');
    }
    timer.stop();
    return <String, Object?>{
      'type': 'A6_BOARD',
      'status': 'PASS',
      'fixture': fixture.id,
      'board': fixture.number,
      'sha256': sha256.convert(utf8.encode(fixture.deal.toPbn())).toString(),
      'dealer': fixture.metadata.dealer.letter,
      'vulnerability': fixture.metadata.vulnerability.name,
      'terminal': passOut ? 'PASS_OUT' : 'CONTRACTED',
      'contract': (state['contract'] as Map?)?['strain'],
      'tricks': (state['completedTricks'] as List).length,
      'uniqueCards': passOut ? 0 : 52,
      'nsScore': state['nsScore'],
      'eventVersion': state['version'],
      'humanActions': human,
      'benBatches': batches,
      'modelSuccessByRoute': counted.counts,
      'modelTransportCalls': counted.durations.length,
      'modelTransportP95Ms': _p95(counted.durations),
      'modelTransportMaxMs': counted.durations.isEmpty
          ? 0 : counted.durations.reduce((a, b) => a > b ? a : b),
      'gameElapsedMs': timer.elapsedMilliseconds,
      'runnerRssBytes': ProcessInfo.currentRss,
    };
  } on _SafeHttpFailure catch (e) {
    throw StateError('A6_HTTP_FAIL fixture=${fixture.id} step=$phase status=${e.status}');
  } catch (_) {
    // Never print the original exception (may include private BEN URLs/PBN).
    throw StateError('A6_GAME_FAIL fixture=${fixture.id} step=$phase');
  } finally {
    await gateway.close();
  }
}

Future<void> main() async {
  final ben = BenLoopbackBackend(
    origin: Uri.parse('http://127.0.0.1:8085'),
    timeout: const Duration(seconds: 120),
  );
  final elapsed = Stopwatch()..start();
  final successes = <Map<String, Object?>>[];
  try {
    for (final fixture in a6Fixtures) {
      final result = await _runBoard(fixture, ben);
      successes.add(result);
      stdout.writeln(jsonEncode(result)); // sanitized metadata, not hands
    }
    final contracted =
        successes.where((v) => v['terminal'] == 'CONTRACTED').length;
    if (successes.length != 4 || contracted != 4) {
      throw StateError('A6 needs four complete true-BEN contracted games');
    }
    stdout.writeln(jsonEncode({
      'type': 'A6_BEN_MULTIBOARD',
      'status': 'PASS',
      'completed': successes.length,
      'required': 4,
      'contracted': contracted,
      'modelSha': '72653ec1b5c17116faea229e9b975ea5622aa1f7',
      'wallElapsedMs': elapsed.elapsedMilliseconds,
      'rssBytes': ProcessInfo.currentRss,
      'upstream': 'GENUINE_BEN_LOOPBACK_GET',
    }));
  } catch (_) {
    stderr.writeln('A6_MULTIBOARD_FAIL completed=${successes.length} required=4');
    exitCode = 1;
  } finally {
    ben.close();
  }
}
