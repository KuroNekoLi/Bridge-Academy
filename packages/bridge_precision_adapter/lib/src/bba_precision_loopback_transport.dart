import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'precision_bidding_provider.dart';

/// Research-only native EPBot sidecar transport. Never send private hands in
/// a URL, proxy, log or redirect. Gateway integration remains gated for M3.4.
final class BbaPrecisionLoopbackTransport implements PrecisionBidTransport {
  BbaPrecisionLoopbackTransport({
    required Uri origin,
    Duration timeout = const Duration(seconds: 20),
    HttpClient? client,
  }) : _origin = origin,
       _timeout = timeout,
       _client = client ?? HttpClient() {
    if (origin.scheme != 'http' ||
        !const {'127.0.0.1', '::1'}.contains(origin.host) ||
        origin.userInfo.isNotEmpty ||
        origin.hasQuery ||
        origin.hasFragment ||
        origin.path != '/' ||
        origin.port < 1 ||
        origin.port > 65535 ||
        timeout <= Duration.zero ||
        timeout > const Duration(seconds: 60)) {
      _client.close(force: true);
      throw ArgumentError('EPBot sidecar requires strict loopback HTTP origin');
    }
    _client.findProxy = (_) => 'DIRECT';
    _client.connectionTimeout = timeout;
    _client.autoUncompress = false;
    _client.maxConnectionsPerHost = 1; // native EPBot single-process isolation
  }

  final Uri _origin;
  final Duration _timeout;
  final HttpClient _client;
  void close() => _client.close(force: true);

  @override
  Future<Map<String, Object?>> bid(Map<String, Object> payload) async {
    // Include only values built from PlayerView by the provider.
    const fields = {
      'version', 'profileId', 'revision', 'cardSha256', 'opponentModel',
      'seat', 'dealer', 'vul', 'ctx', 'hand',
    };
    if (payload.keys.toSet().difference(fields).isNotEmpty ||
        payload.length != fields.length) {
      throw const PrecisionProviderException('unexpected_request_schema');
    }
    final bytes = utf8.encode(jsonEncode(payload));
    if (bytes.length > 2048) {
      throw const PrecisionProviderException('request_too_large');
    }
    try {
      final request = await _client
          .postUrl(_origin.resolve('/v1/precision/bid'))
          .timeout(_timeout);
      request.followRedirects = false;
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      request.contentLength = bytes.length;
      request.add(bytes);
      final response = await request.close().timeout(_timeout);
      if (response.isRedirect || response.statusCode != 200) {
        throw const PrecisionProviderException('native_unavailable');
      }
      final buffer = <int>[];
      await for (final chunk in response.timeout(_timeout)) {
        if (buffer.length + chunk.length > 4096) {
          throw const PrecisionProviderException('response_too_large');
        }
        buffer.addAll(chunk);
      }
      final result = jsonDecode(utf8.decode(buffer));
      if (result is! Map<String, dynamic>) {
        throw const PrecisionProviderException('invalid_native_response');
      }
      return Map<String, Object?>.unmodifiable(result);
    } on PrecisionProviderException {
      rethrow;
    } on TimeoutException {
      throw const PrecisionProviderException('native_timeout');
    } catch (_) {
      // SocketException can include private request URLs; never propagate.
      throw const PrecisionProviderException('native_unavailable');
    }
  }
}
