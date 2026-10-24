import 'dart:convert';
import 'dart:io';

import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_gateway/bridge_gateway.dart';
import 'package:bridge_precision_adapter/bridge_precision_adapter.dart';

/// Genuine BBA native auction / deterministic legal-card technical E2E.
/// A completed game here is NOT proof of a full-strength Precision bot.
const fixture = 'N:AJ5.KQ7.A982.K76 32.9843.J73.Q943 '
    'QT6.AJ6.KT6.JT52 K9874.T52.Q54.A8';

Future<Map<String, dynamic>> post(
    int port, String route, Map<String, Object?> body,
    {String? bearer, int success = 200}) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(
        Uri.parse('http://127.0.0.1:$port$route'));
    req.headers.contentType = ContentType.json;
    if (bearer != null) {
      req.headers.set('Authorization', 'Bearer $bearer');
    }
    req.write(jsonEncode(body));
    final response = await req.close()
        .timeout(const Duration(minutes: 4));
    final bytes = await utf8.decoder.bind(response).join();
    if (response.statusCode != success) {
      // Never disclose response body: may reveal server-only diagnostics.
      throw StateError('Unexpected Gateway status ${response.statusCode}');
    }
    return jsonDecode(bytes) as Map<String, dynamic>;
  } finally {
    client.close(force: true);
  }
}

Map<String, Object?> request(int v, String id,
    [Map<String, Object?>? action]) => {
  'version': 1, 'expected_version': v, 'request_id': id,
  if (action != null) 'action': action,
};

void verifyFinal(Map<String, dynamic> view) {
  if (view['phase'] != 'finished') {
    throw StateError('Game has not finished');
  }
  final auction = (view['auction'] as List).length;
  final played = <String>{};
  final tricks = view['completedTricks'] as List;
  if (tricks.length != 13 || view['nsScore'] is! int ||
      view['version'] != auction + 52) {
    throw StateError('Version, score or 13 trick invariant');
  }
  for (final trick in tricks) {
    final plays = (trick as Map)['plays'] as List;
    if (plays.length != 4) throw StateError('Incomplete trick');
    for (final raw in plays) {
      final code = (raw as Map)['card'];
      if (code is! String || !played.add(code)) {
        throw StateError('Duplicate or invalid card');
      }
    }
  }
  if (played.length != 52) throw StateError('Not 52 distinct cards');
  if ((view['remainingCards'] as Map).values.any((v) => v != 0)) {
    throw StateError('Unplayed remaining cards');
  }
}

Future<void> playOne(bool swap) async {
  final native = BbaPrecisionLoopbackTransport(
      origin: Uri.parse('http://127.0.0.1:18088/'));
  final systems = GameSystems(
      northSouth: swap ? ConventionCatalog.sayc :
          ConventionCatalog.precisionMeckwell,
      eastWest: swap ? ConventionCatalog.precisionMeckwell :
          ConventionCatalog.sayc,
  );
  final gateway = BridgeGatewayService(
      backend: const UnavailableDecisionBackend(),
      precisionResearch: native,
      enablePrecisionResearch: true,
      gameSystems: systems,
      dealFactory: () => Deal.fromPbn(fixture),
      config: const GatewayConfig(
        sessionTtl: Duration(hours: 1),
        decisionTimeout: Duration(minutes: 3),
        decisionLimit: 250,
      ),
  );
  try {
    final port = await gateway.start();
    final issued = await post(port, '/v1/sessions/anonymous', {
      'version': 1,
      'game_systems': {
        'northSouth': systems.northSouth.profileId,
        'eastWest': systems.eastWest.profileId,
      },
    }, success: 201);
    if (GameSystems.fromTrustedJson(issued['game_systems']) != systems) {
      throw StateError('Profile was not pinned by server');
    }
    final bearer = issued['access_token'] as String;
    Map<String, dynamic> view = (await post(
        port, '/v1/games/view', {'version': 1}, bearer: bearer
    ))['view'] as Map<String, dynamic>;
    final watch = Stopwatch()..start();
    var botTurns = 0;
    var humanTurns = 0;
    Map<String, Object?>? firstPayload;
    Map<String, dynamic>? firstReply;
    var counter = 0;
    for (var step = 0; step < 130 && view['phase'] != 'finished'; step++) {
      final oldVersion = view['version'] as int;
      final id = 'm34_native_${(counter++).toString().padLeft(6, '0')}';
      Map<String, Object?> payload;
      String route;
      if (view['canAct'] == true) {
        final action = view['phase'] == 'auction'
          ? <String, Object?>{
              'kind': 'bid',
              'call': oldVersion == 0 ? '3NT' : 'PASS',
            }
          : <String, Object?>{
              'kind': 'play',
              'card': (view['legalCards'] as List).first as String,
            };
        payload = request(oldVersion, id, action);
        route = '/v1/games/action';
        humanTurns++;
      } else {
        payload = request(oldVersion, id);
        route = '/v1/games/advance';
        botTurns++;
      }
      final result = await post(port, route, payload, bearer: bearer);
      if (firstPayload == null) {
        firstPayload = payload;
        firstReply = result;
      }
      view = result['view'] as Map<String, dynamic>;
      if ((view['version'] as int) <= oldVersion) {
        throw StateError('Non-monotonic private game state');
      }
      if (view.keys.any(const {'dealPbn', 'hands', 'deal', 'token'}.contains)) {
        throw StateError('Server leaked privileged state');
      }
    }
    verifyFinal(view);
    final version = view['version'];
    final repeated = await post(
        port, '/v1/games/action', firstPayload!, bearer: bearer);
    if (jsonEncode(repeated) != jsonEncode(firstReply) ||
        (await post(port, '/v1/games/view', {'version': 1},
            bearer: bearer))['view']['version'] != version) {
      throw StateError('Idempotent replay changed completed game');
    }
    watch.stop();
    stdout.writeln(jsonEncode({
      'status': 'SCOPED_PASS',
      'type': 'M34_NATIVE_BBA_AUCTION_DETERMINISTIC_CARDPLAY',
      'ns': systems.northSouth.profileId,
      'ew': systems.eastWest.profileId,
      'profileFingerprint': systems.fingerprint,
      'nativeBbaAuction': true,
      'realBenCardplay': false,
      'competitiveStrengthValidated': false,
      'expertSemanticsValidated': false,
      'tricks': 13, 'uniqueCards': 52,
      'auctionCount': (view['auction'] as List).length,
      'nsScore': view['nsScore'],
      'botBatches': botTurns, 'humanActions': humanTurns,
      'elapsedMs': watch.elapsedMilliseconds,
    }));
  } finally {
    await gateway.close();
    native.close();
  }
}

Future<void> main() async {
  try {
    await playOne(false);
    await playOne(true);
  } catch (_) {
    // Never print a raw exception, private hand, token or native traceback.
    stderr.writeln('M34_NATIVE_RESEARCH_GAME_FAILED');
    exitCode = 1;
  }
}
