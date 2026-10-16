import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ben_transport.dart';

/// Obtains a short-lived credential from a trusted session/bootstrap flow.
///
/// The credential MUST NOT be a secret embedded in Flutter's compiled assets.
typedef GatewayAccessTokenProvider = Future<String?> Function();

/// Versioned, HTTPS-only client boundary for a future Bridge Academy gateway.
///
/// The legacy BenTransport method is named "get" for adapter compatibility.
/// THIS transport performs ONLY POST; private hands never enter request URLs.
/// No implicit retry: a remote result is always validated by Bridge Core.
class BenGatewayTransport implements BenTransport {
  BenGatewayTransport({
    required Uri baseUri,
    required GatewayAccessTokenProvider accessTokenProvider,
    http.Client? client,
    this.timeout = const Duration(seconds: 60),
  })  : _baseUri = baseUri,
        _accessTokenProvider = accessTokenProvider,
        _client = client ?? http.Client() {
    if (baseUri.scheme != 'https' ||
        baseUri.host.isEmpty ||
        baseUri.userInfo.isNotEmpty ||
        baseUri.hasQuery ||
        baseUri.hasFragment ||
        (baseUri.path.isNotEmpty && baseUri.path != '/') ||
        timeout <= Duration.zero) {
      throw ArgumentError('Gateway must be an HTTPS origin without embedded credentials or paths');
    }
  }

  static const _routes = {'/bid', '/lead', '/play'};
  static const _baseFields = {'hand', 'seat', 'dealer', 'vul', 'ctx'};
  static const _allFields = {..._baseFields, 'dummy', 'played'};
  static const _maxResponseBytes = 32768;
  static const _gatewayPath = '/v1/ai/decision';

  final Uri _baseUri;
  final GatewayAccessTokenProvider _accessTokenProvider;
  final http.Client _client;
  final Duration timeout;

  void close() => _client.close();

  @override
  Future<Map<String, dynamic>> get(
    String route,
    Map<String, String> query,
  ) async {
    // Validate before resolving credentials and before touching any network.
    if (!_routes.contains(route) ||
        !query.keys.toSet().containsAll(_baseFields) ||
        !_allFields.containsAll(query.keys) ||
        query['hand']!.isEmpty ||
        !const {'N', 'E', 'S', 'W'}.contains(query['seat']) ||
        !const {'N', 'E', 'S', 'W'}.contains(query['dealer']) ||
        !const {'', 'NS', 'EW', 'Both'}.contains(query['vul']) ||
        (route == '/play' &&
            (!query.containsKey('dummy') || !query.containsKey('played'))) ||
        (route != '/play' &&
            (query.containsKey('dummy') || query.containsKey('played')))) {
      throw const BenApiException('request', 'Invalid gateway request contract');
    }
    return _send(route, query).timeout(
      timeout,
      onTimeout: () =>
          throw const BenApiException('timeout', 'Gateway request timed out'),
    );
  }

  Future<Map<String, dynamic>> _send(
    String route,
    Map<String, String> input,
  ) async {
    String? token;
    try {
      token = await _accessTokenProvider();
    } catch (_) {
      throw const BenApiException('auth', 'Gateway credential unavailable');
    }
    if (token == null ||
        token.isEmpty ||
        token.trim() != token ||
        token.contains(RegExp(r'[\r\n]'))) {
      throw const BenApiException('auth', 'Gateway credential unavailable');
    }

    final request = http.Request(
      'POST',
      _baseUri.replace(path: _gatewayPath),
    );
    request.followRedirects = false;
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Cache-Control': 'no-store',
    });
    request.body = jsonEncode({
      'version': 1,
      'route': route.substring(1),
      'input': input,
    });

    http.StreamedResponse response;
    try {
      response = await _client.send(request);
    } on http.ClientException {
      throw const BenApiException('network', 'Gateway network error');
    } catch (_) {
      throw const BenApiException('network', 'Gateway transport error');
    }

    // No follow-redirects: never forward bearer credentials or hands.
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const BenApiException('auth', 'Gateway authorization rejected');
    }
    if (response.statusCode == 429) {
      throw const BenApiException('rate_limit', 'Gateway rate limit reached');
    }
    if (response.statusCode != 200) {
      throw const BenApiException('http', 'Gateway decision unavailable');
    }

    final body = <int>[];
    try {
      await for (final chunk in response.stream) {
        if (body.length + chunk.length > _maxResponseBytes) {
          throw const BenApiException('response', 'Gateway response too large');
        }
        body.addAll(chunk);
      }
    } on BenApiException {
      rethrow;
    } catch (_) {
      throw const BenApiException('network', 'Gateway response interrupted');
    }

    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(body));
    } catch (_) {
      throw const BenApiException('response', 'Gateway response is not JSON');
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['version'] != 1 ||
        decoded['decision'] is! Map<String, dynamic>) {
      throw const BenApiException('response', 'Gateway schema not supported');
    }
    final decision = decoded['decision'] as Map<String, dynamic>;
    if (decision.containsKey('error') ||
        !decision.keys.toSet().containsAll(route == '/bid'
            ? const {'bid'}
            : const {'card'})) {
      throw const BenApiException('response', 'Gateway decision is invalid');
    }
    return decision;
  }
}
