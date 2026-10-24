import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'precision_bidding_provider.dart';

/// Research-only native EPBot sidecar transport. Never send private hands in
/// a URL, proxy, log or redirect. Gateway integration remains gated for M3.4.
abstract interface class BbaTableBidTransport {
  Future<bool> researchReady();
  Future<Map<String, Object?>> tableBid(Map<String, Object> payload);
}

final class BbaPrecisionLoopbackTransport
    implements PrecisionBidTransport, BbaTableBidTransport {
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
  Future<bool> researchReady() async {
    try {
      final req = await _client.getUrl(_origin.resolve('/health')).timeout(_timeout);
      req.followRedirects = false;
      final response = await req.close().timeout(_timeout);
      if (response.statusCode != 200 || response.isRedirect) return false;
      final bytes = <int>[];
      await for (final chunk in response.timeout(_timeout)) {
        if (bytes.length + chunk.length > 1024) return false;
        bytes.addAll(chunk);
      }
      final obj = jsonDecode(utf8.decode(bytes));
      return obj is Map &&
          obj['status'] == 'research_ready' &&
          obj['profileId'] == 'BA-PRECISION-MECKWELL' &&
          obj['revision'] == 1 &&
          obj['cardSha256'] ==
              '5c2a6c8d84094a0a9efd2cefe98a93983185140e6bde81b2520086b8b27d9cbc' &&
          obj['sourceCommit'] == 'ad8608af6e6bfe095863023f344f3cb2cbafec3d';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Map<String, Object?>> bid(Map<String, Object> payload) =>
      _send('/v1/precision/bid', payload, const {
        'version', 'profileId', 'revision', 'cardSha256', 'opponentModel',
        'seat', 'dealer', 'vul', 'ctx', 'hand',
      });

  @override
  Future<Map<String, Object?>> tableBid(Map<String, Object> payload) =>
      _send('/v1/precision/table-bid', payload, const {
        'version', 'profileId', 'revision', 'cardSha256',
        'northSouth', 'eastWest', 'seat', 'dealer', 'vul', 'ctx', 'hand',
      });

  Future<Map<String, Object?>> _send(
      String path, Map<String, Object> payload, Set<String> fields) async {
    // Strict route-controlled schema, never untrusted caller-selected URL.
    // No arbitrary extra headers or body fields.
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
          .postUrl(_origin.resolve(path))
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
