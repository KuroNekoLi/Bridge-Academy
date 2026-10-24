import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'gateway_service.dart';
import 'package:bridge_conventions/bridge_conventions.dart';

/// Trusted development-only upstream adapter to the pinned BEN gameapi.
///
/// BEN uses GET query parameters containing a robot's own private hand.
/// Therefore the origin MUST be an IP-literal loopback endpoint. Never print,
/// cache, redirect, forward, or expose the constructed URI to the caller.
class BenLoopbackBackend implements SystemAwareDecisionBackend {
  BenLoopbackBackend({
    required Uri origin,
    Duration timeout = const Duration(seconds: 25),
    int maxResponseBytes = 32768,
    HttpClient? client,
    this.pinnedBenRevision,
  })  : _origin = origin,
        _timeout = timeout,
        _maxResponseBytes = maxResponseBytes,
        _client = client ?? HttpClient() {
    if (origin.scheme != 'http' ||
        !const {'127.0.0.1', '::1'}.contains(origin.host) ||
        origin.userInfo.isNotEmpty ||
        origin.hasQuery ||
        origin.hasFragment ||
        (origin.path.isNotEmpty && origin.path != '/') ||
        origin.port < 1 ||
        origin.port > 65535 ||
        timeout <= Duration.zero ||
        maxResponseBytes < 1 ||
        maxResponseBytes > 32768) {
      _client.close(force: true);
      throw ArgumentError('BEN upstream must be a literal loopback HTTP origin');
    }
    // Explicitly avoid HTTP proxies, including ones configured in environment.
    _client.findProxy = (_) => 'DIRECT';
    _client.connectionTimeout = timeout;
    _client.autoUncompress = false;
    _client.maxConnectionsPerHost = 1;
  }

  /// Operator-verified deployed BEN source revision; GET / does not attest weights.
  final String? pinnedBenRevision;
  final Uri _origin;
  final Duration _timeout;
  final int _maxResponseBytes;
  final HttpClient _client;


  void close() => _client.close(force: true);

  @override
  Future<bool> supportsGameSystems(GameSystems systems) async {
    if (systems.northSouth.isLegacyUnverified &&
        systems.eastWest.isLegacyUnverified) return true;
    if (pinnedBenRevision == null ||
        pinnedBenRevision != systems.northSouth.modelRevision ||
        pinnedBenRevision != systems.eastWest.modelRevision ||
        systems.northSouth.engineId != 'BEN' ||
        systems.eastWest.engineId != 'BEN') return false;
    try {
      final request = await _client.getUrl(_origin).timeout(_timeout);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != 200 || response.isRedirect) return false;
      final chunks = <int>[];
      await for (final chunk in response.timeout(_timeout)) {
        if (chunks.length + chunk.length > _maxResponseBytes) return false;
        chunks.addAll(chunk);
      }
      final data = jsonDecode(utf8.decode(chunks));
      if (data is! Map<String, dynamic>) return false;
      final plays = data['playsSystems'];
      final reads = data['readsSystems'];
      if (plays is! List || reads is! List ||
          plays.any((e) => e is! String) ||
          reads.any((e) => e is! String)) return false;
      return <String>{...plays.cast<String>()}.containsAll({
        systems.northSouth.modelId, systems.eastWest.modelId,
      }) && <String>{...reads.cast<String>()}.containsAll({
        systems.northSouth.modelId, systems.eastWest.modelId,
      });
    } catch (_) {
      return false;
    }
  }


  @override
  Future<Map<String, Object?>> decide(
      String route, Map<String, String> allowedFields) async {
    if (!const {'bid', 'lead', 'play'}.contains(route)) {
      throw const GatewayFailure(400, 'invalid_request');
    }

    // No hidden Deal, headers, identity or arbitrary query keys.
    const base = {'hand', 'seat', 'dealer', 'vul', 'ctx'};
    const system = {'ourSystem', 'theirSystem'};
    const play = {'dummy', 'played'};
    if (!allowedFields.keys.toSet().containsAll(base) ||
        !(route == 'play' ? base.union(play).union(system) :
            base.union(system)).containsAll(allowedFields.keys) ||
        (route == 'play' && !allowedFields.keys.toSet().containsAll(play))) {
      throw const GatewayFailure(400, 'invalid_request');
    }
    if (allowedFields.keys.toSet().intersection(system).isNotEmpty &&
        (!allowedFields.keys.toSet().containsAll(system) ||
         !const {'21GF', 'SAYC'}.contains(allowedFields['ourSystem']) ||
         !const {'21GF', 'SAYC'}.contains(allowedFields['theirSystem']))) {
      throw const GatewayFailure(400, 'invalid_request');
    }
    final target = _origin.replace(
      path: '/$route',
      queryParameters: allowedFields,
    );

    try {
      return await _fetch(target, route).timeout(_timeout);
    } on GatewayFailure {
      rethrow;
    } on TimeoutException {
      throw const GatewayFailure(504, 'upstream_timeout');
    } catch (_) {
      // HttpException and SocketException often contain URL, including hand.
      // Deliberately never interpolate the original error.
      throw const GatewayFailure(503, 'upstream_unavailable');
    }
  }

  Future<Map<String, Object?>> _fetch(Uri target, String route) async {
    final request = await _client.getUrl(target).timeout(_timeout);
    request.followRedirects = false;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    final response = await request.close().timeout(_timeout);
    if (response.statusCode != 200) {
      throw const GatewayFailure(503, 'upstream_unavailable');
    }
    final bytes = <int>[];
    await for (final chunk in response.timeout(_timeout)) {
      if (bytes.length + chunk.length > _maxResponseBytes) {
        throw const GatewayFailure(502, 'bad_upstream');
      }
      bytes.addAll(chunk);
    }
    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw const GatewayFailure(502, 'bad_upstream');
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['error'] != null ||
        !decoded.containsKey(route == 'bid' ? 'bid' : 'card')) {
      throw const GatewayFailure(502, 'bad_upstream');
    }
    // Only one safe action field; the A4.2 gateway validates its syntax and
    // Bridge Core still decides whether it is a legal auction/play action.
    final key = route == 'bid' ? 'bid' : 'card';
    final value = decoded[key];
    if (value is! String) {
      throw const GatewayFailure(502, 'bad_upstream');
    }
    return {key: value};
  }
}
