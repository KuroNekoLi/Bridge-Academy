import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:bridge_core/bridge_core.dart';

import 'authoritative_game.dart';
import 'encrypted_session_store.dart';

/// An A4.3 BEN worker will implement this interface. Never return an action
/// before the real upstream validates the model response.
abstract interface class GatewayDecisionBackend {
  Future<Map<String, Object?>> decide(
    String route,
    Map<String, String> allowedFields,
  );
}

/// Production-safe default: do NOT invent AI proposals or fall back to Demo.
class UnavailableDecisionBackend implements GatewayDecisionBackend {
  const UnavailableDecisionBackend();

  @override
  Future<Map<String, Object?>> decide(
    String route,
    Map<String, String> allowedFields,
  ) async =>
      throw const GatewayFailure(503, 'upstream_unavailable');
}

/// Exceptions never carry raw cards, PBN, request bodies, tokens or upstream logs.
class GatewayFailure implements Exception {
  const GatewayFailure(this.status, this.code);
  final int status;
  final String code;
}

class GatewayConfig {
  const GatewayConfig({
    this.sessionTtl = const Duration(minutes: 15),
    this.window = const Duration(minutes: 1),
    this.bootstrapLimit = 5,
    this.decisionLimit = 30,
    this.decisionTimeout = const Duration(seconds: 30),
    this.maxSessions = 1024,
    this.allowedBrowserOrigins = const <String>{},
  });

  final Duration sessionTtl;
  final Duration window;
  final int bootstrapLimit;
  final int decisionLimit;
  final Duration decisionTimeout;
  final int maxSessions;

  /// No CORS-enabled browser origin by default. Tokens still need real
  /// server-side session authorization; CORS is not an authentication system.
  final Set<String> allowedBrowserOrigins;
}

class _Session {
  _Session(this.expiresAt, this.game);
  final DateTime expiresAt;
  final AuthoritativeGame game;
  DateTime? windowStarted;
  int used = 0;
  bool inFlight = false;
}

class _Window {
  _Window(this.start);
  final DateTime start;
  int used = 0;
}

/// Single-process, loopback-first DEV gateway. The entire session store is
/// volatile; restart invalidates all tokens. No production claim is implied.
class BridgeGatewayService {
  BridgeGatewayService({
    GatewayDecisionBackend? backend,
    GatewayConfig config = const GatewayConfig(),
    DateTime Function()? clock,
    Deal Function()? dealFactory,
    EncryptedSessionStore? checkpointStore,
  })  : _checkpointStore = checkpointStore,
        _backend = backend ?? const UnavailableDecisionBackend(),
        _dealFactory = dealFactory ?? Deal.shuffled,
        _config = config,
        _clock = clock ?? DateTime.now {
    if (config.sessionTtl <= Duration.zero ||
        config.window <= Duration.zero ||
        config.decisionTimeout <= Duration.zero ||
        config.bootstrapLimit < 1 ||
        config.decisionLimit < 1 ||
        config.maxSessions < 1) {
      throw ArgumentError('Invalid positive gateway limits');
    }
  }

  final GatewayDecisionBackend _backend;
  final GatewayConfig _config;
  final DateTime Function() _clock;
  final Deal Function() _dealFactory;
  final EncryptedSessionStore? _checkpointStore;
  final Random _random = Random.secure();
  final Map<String, _Session> _sessions = {};
  final Map<String, _Window> _bootstrapByIp = {};
  HttpServer? _server;
  StreamSubscription<HttpRequest>? _requests;

  int get port => _server?.port ?? 0;

  Future<int> start({
    InternetAddress? address,
    int port = 0,
  }) async {
    if (_server != null) throw StateError('Gateway already listening');
    // Intentionally no public bind in the development command.
    final bindAddress = address ?? InternetAddress.loopbackIPv4;
    if (!bindAddress.isLoopback) {
      throw ArgumentError('A4.2 development gateway may bind loopback only');
    }
    if (_checkpointStore != null) {
      final loaded = await _checkpointStore.open();
      final now = _clock().toUtc();
      for (final entry in loaded.entries) {
        final archive = entry.value;
        final expiry = DateTime.fromMillisecondsSinceEpoch(
          archive['expiresAtMs'] as int,
          isUtc: true,
        );
        if (!expiry.isAfter(now)) {
          await _checkpointStore.remove(entry.key);
          continue;
        }
        final game = AuthoritativeGame.restore(
          archive: Map<String, dynamic>.from(archive['game'] as Map),
          backend: _backend,
        );
        final session = _Session(expiry, game);
        session.used = archive['used'] as int? ?? 0;
        final started = archive['windowStartedMs'];
        if (started is int) {
          session.windowStarted = DateTime.fromMillisecondsSinceEpoch(
            started, isUtc: true);
        }
        game.setCheckpoint(() => _persistSession(entry.key, session));
        _sessions[entry.key] = session;
      }
    }
    try {
      _server = await HttpServer.bind(bindAddress, port);
    } catch (_) {
      await _checkpointStore?.close();
      rethrow;
    }
    _requests = _server!.listen((request) {
      unawaited(_handle(request));
    });
    return _server!.port;
  }

  Future<void> close() async {
    await _requests?.cancel();
    await _server?.close(force: true);
    _server = null;
    await _checkpointStore?.close();
    _sessions.clear();
    _bootstrapByIp.clear();
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    response.headers.set('Cache-Control', 'no-store, private');
    response.headers.set('X-Content-Type-Options', 'nosniff');

    try {
      if (request.uri.hasQuery || request.uri.hasFragment) {
        throw const GatewayFailure(400, 'invalid_request');
      }

      final origin = request.headers.value('origin');
      if (origin != null) {
        if (!_config.allowedBrowserOrigins.contains(origin)) {
          throw const GatewayFailure(403, 'origin_denied');
        }
        response.headers.set('Access-Control-Allow-Origin', origin);
        response.headers.set('Vary', 'Origin');
      }
      final isGame = const {
        '/v1/games/view',
        '/v1/games/action',
        '/v1/games/advance',
      }.contains(request.uri.path);
      // Raw client-provided hands are permitted only in the old ephemeral
      // localhost dev mode. Durable mode denies this insecure API completely.
      final rawDecision = request.uri.path == '/v1/ai/decision';
      if (rawDecision && _checkpointStore != null) {
        throw const GatewayFailure(404, 'not_found');
      }
      final isApi = request.uri.path == '/v1/sessions/anonymous' ||
          rawDecision || isGame;
      if (request.method == 'OPTIONS' && isApi && origin != null) {
        response.statusCode = HttpStatus.noContent;
        response.headers.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
        response.headers.set('Access-Control-Allow-Headers',
            'Authorization, Content-Type');
        response.headers.set('Access-Control-Max-Age', '600');
        return;
      }
      if (request.method == 'GET' && request.uri.path == '/healthz') {
        _reply(response, 200, {'version': 1, 'status': 'ready'});
        return;
      }
      if (request.method != 'POST' || !isApi) {
        throw const GatewayFailure(404, 'not_found');
      }

      if (request.headers.contentType?.mimeType != 'application/json') {
        throw const GatewayFailure(415, 'content_type_required');
      }
      final body = await _readJson(request);
      if (request.uri.path == '/v1/sessions/anonymous') {
        await _issueSession(request, body);
      } else if (isGame) {
        await _requestGame(request, body);
      } else {
        await _requestDecision(request, body);
      }
    } on GatewayFailure catch (failure) {
      _reply(response, failure.status, {
        'version': 1,
        'error': {'code': failure.code}
      });
    } catch (_) {
      // Do not leak backend exception, request body or token to the response.
      _reply(response, 500, {
        'version': 1,
        'error': {'code': 'internal_error'}
      });
    } finally {
      try {
        await response.close();
      } catch (_) {
        // Peer can disconnect. Never log its private request.
      }
    }
  }

  Future<Map<String, dynamic>> _readJson(HttpRequest request) async {
    final bytes = <int>[];
    await for (final part in request) {
      if (bytes.length + part.length > 8192) {
        throw const GatewayFailure(413, 'payload_too_large');
      }
      bytes.addAll(part);
    }
    Object? data;
    try {
      data = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw const GatewayFailure(400, 'invalid_json');
    }
    if (data is! Map<String, dynamic>) {
      throw const GatewayFailure(400, 'invalid_request');
    }
    return data;
  }

  Future<void> _issueSession(HttpRequest request, Map<String, dynamic> body) async {
    if (body.length != 1 || body['version'] != 1) {
      throw const GatewayFailure(400, 'invalid_request');
    }
    final now = _clock().toUtc();
    await _expireOld(now);
    final ip = request.connectionInfo?.remoteAddress.address ?? 'unknown';
    // Never honor X-Forwarded-For without a trusted reverse-proxy contract.
    final window = _bootstrapByIp.putIfAbsent(ip, () => _Window(now));
    if (now.difference(window.start) >= _config.window) {
      _bootstrapByIp[ip] = _Window(now);
    }
    final current = _bootstrapByIp[ip]!;
    if (++current.used > _config.bootstrapLimit ||
        _sessions.length >= _config.maxSessions) {
      throw const GatewayFailure(429, 'rate_limited');
    }

    final token = _randomToken();
    // Keep only the SHA-256 token hash in process memory.
    final digest = _digest(token);
    final game = AuthoritativeGame(deal: _dealFactory(), backend: _backend);
    final session = _Session(now.add(_config.sessionTtl), game);
    game.setCheckpoint(() => _persistSession(digest, session));
    _sessions[digest] = session;
    try {
      // Token is not returned to the caller until its encrypted checkpoint
      // has been durably written.
      await _persistSession(digest, session);
    } catch (_) {
      _sessions.remove(digest);
      throw const GatewayFailure(503, 'storage_unavailable');
    }
    _reply(request.response, 201, {
      'version': 1,
      'access_token': token,
      'token_type': 'Bearer',
      'expires_in': _config.sessionTtl.inSeconds,
      'scope': 'ai:decision'
    });
  }

  /// Server-owned game routes: clients send NO hand, seat, Deal or PBN.
  /// The 15-minute anonymous capability grants only access to its own game.
  Future<void> _requestGame(
    HttpRequest request,
    Map<String, dynamic> body,
  ) async {
    final auth = request.headers.value('authorization');
    if (auth == null ||
        !auth.startsWith('Bearer ') ||
        auth.substring(7).isEmpty ||
        auth.contains(RegExp(r'[\r\n,]'))) {
      throw const GatewayFailure(401, 'unauthorized');
    }
    final now = _clock().toUtc();
    final session = _sessions[_digest(auth.substring(7))];
    if (session == null || !session.expiresAt.isAfter(now)) {
      throw const GatewayFailure(401, 'unauthorized');
    }
    if (session.windowStarted == null ||
        now.difference(session.windowStarted!) >= _config.window) {
      session.windowStarted = now;
      session.used = 0;
    }
    if (++session.used > _config.decisionLimit || session.inFlight) {
      throw const GatewayFailure(429, 'rate_limited');
    }
    if (request.uri.path == '/v1/games/view') {
      if (body.length != 1 || body['version'] != 1) {
        throw const GatewayFailure(400, 'invalid_request');
      }
      _reply(request.response, 200, session.game.view());
      return;
    }
    session.inFlight = true;
    try {
      final reply = await session.game.execute(body,
          advanceBots: request.uri.path == '/v1/games/advance')
          .timeout(_config.decisionTimeout);
      _reply(request.response, 200, reply);
    } on TimeoutException {
      throw const GatewayFailure(504, 'upstream_timeout');
    } finally {
      session.inFlight = false;
    }
  }

  Future<void> _requestDecision(
    HttpRequest request,
    Map<String, dynamic> body,
  ) async {
    final auth = request.headers.value('authorization');
    if (auth == null ||
        !auth.startsWith('Bearer ') ||
        auth.substring(7).isEmpty ||
        auth.contains(RegExp(r'[\r\n,]'))) {
      throw const GatewayFailure(401, 'unauthorized');
    }
    final now = _clock().toUtc();
    final session = _sessions[_digest(auth.substring(7))];
    if (session == null || !session.expiresAt.isAfter(now)) {
      throw const GatewayFailure(401, 'unauthorized');
    }
    if (body.length != 3 ||
        body['version'] != 1 ||
        body['route'] is! String ||
        body['input'] is! Map<String, dynamic>) {
      throw const GatewayFailure(400, 'invalid_request');
    }
    final route = body['route'] as String;
    final input = _validatedInput(route, body['input'] as Map<String, dynamic>);
    if (session.windowStarted == null ||
        now.difference(session.windowStarted!) >= _config.window) {
      session.windowStarted = now;
      session.used = 0;
    }
    if (++session.used > _config.decisionLimit || session.inFlight) {
      throw const GatewayFailure(429, 'rate_limited');
    }
    session.inFlight = true;
    try {
      final result = await _backend
          .decide(route, Map<String, String>.unmodifiable(input))
          .timeout(_config.decisionTimeout);
      if (result.length != 1) {
        throw const GatewayFailure(502, 'bad_upstream');
      }
      final key = route == 'bid' ? 'bid' : 'card';
      final value = result[key];
      if (value is! String || !_validProposal(route, value)) {
        throw const GatewayFailure(502, 'bad_upstream');
      }
      _reply(request.response, 200, {
        'version': 1,
        'decision': {key: value}
      });
    } on TimeoutException {
      throw const GatewayFailure(504, 'upstream_timeout');
    } on GatewayFailure {
      rethrow;
    } catch (_) {
      throw const GatewayFailure(503, 'upstream_unavailable');
    } finally {
      session.inFlight = false;
    }
  }

  Map<String, String> _validatedInput(
    String route,
    Map<String, dynamic> raw,
  ) {
    if (!const {'bid', 'lead', 'play'}.contains(route)) {
      throw const GatewayFailure(400, 'invalid_request');
    }
    const base = {'hand', 'seat', 'dealer', 'vul', 'ctx'};
    const extra = {'dummy', 'played'};
    if (!raw.keys.toSet().containsAll(base) ||
        !(route == 'play'
            ? base.union(extra)
            : base).containsAll(raw.keys) ||
        (route == 'play' && !raw.keys.toSet().containsAll(extra)) ||
        raw.values.any((value) => value is! String)) {
      throw const GatewayFailure(400, 'invalid_request');
    }
    final data = raw.cast<String, String>();
    if (!_validHand(data['hand']!) ||
        (route == 'play' && !_validHand(data['dummy']!)) ||
        !const {'N', 'E', 'S', 'W'}.contains(data['seat']) ||
        !const {'N', 'E', 'S', 'W'}.contains(data['dealer']) ||
        !const {'', 'NS', 'EW', 'Both'}.contains(data['vul']) ||
        data['ctx']!.length > 200 ||
        !RegExp(r'^[1-7CDHSNTPX-]*$').hasMatch(data['ctx']!) ||
        (route == 'play' &&
            (data['played']!.length > 104 ||
                !RegExp(r'^(?:[CDHS][2-9TJQKA])*$').hasMatch(data['played']!)))) {
      throw const GatewayFailure(400, 'invalid_request');
    }
    return data;
  }

  bool _validHand(String hand) {
    final suits = hand.split('.');
    if (suits.length != 4 || suits.join().length != 13) return false;
    for (final ranks in suits) {
      if (!RegExp(r'^[AKQJT98765432]*$').hasMatch(ranks) ||
          ranks.split('').toSet().length != ranks.length) return false;
    }
    return true;
  }

  bool _validProposal(String route, String value) => route == 'bid'
      ? RegExp(r'^(?:PASS|P|--|PA|X|XX|DB|RD|DOUBLE|REDOUBLE|[1-7](?:C|D|H|S|N|NT))$')
          .hasMatch(value)
      : RegExp(r'^[CDHS][2-9TJQKA]$').hasMatch(value);

  Future<void> _expireOld(DateTime now) async {
    final expired = _sessions.entries
        .where((entry) => !entry.value.expiresAt.isAfter(now))
        .map((entry) => entry.key).toList();
    for (final digest in expired) {
      _sessions.remove(digest);
      try {
        await _checkpointStore?.remove(digest);
      } catch (_) {
        throw const GatewayFailure(503, 'storage_unavailable');
      }
    }
    _bootstrapByIp.removeWhere(
        (_, window) => now.difference(window.start) >= _config.window);
  }

  Future<void> _persistSession(String digest, _Session session) async {
    final store = _checkpointStore;
    if (store == null) return;
    await store.save(digest, {
      'expiresAtMs': session.expiresAt.millisecondsSinceEpoch,
      'windowStartedMs': session.windowStarted?.millisecondsSinceEpoch,
      'used': session.used,
      'game': session.game.trustedCheckpoint(),
    });
  }

  String _randomToken() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _digest(String token) => sha256.convert(utf8.encode(token)).toString();

  void _reply(HttpResponse response, int status, Map<String, Object?> data) {
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(data));
  }
}
