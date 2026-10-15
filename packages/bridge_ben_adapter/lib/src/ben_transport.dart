import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// No private hands or query parameters are included in thrown errors.
class BenApiException implements Exception {
  const BenApiException(this.kind, this.message);
  final String kind;
  final String message;
  @override
  String toString() => 'BenApiException($kind): $message';
}

abstract interface class BenTransport {
  Future<Map<String, dynamic>> get(String route, Map<String, String> query);
}

/// Calls BEN's documented stateless API. An injected client permits HTTP
/// contract tests without any live BEN service (those tests are NOT real AI).
class BenHttpTransport implements BenTransport {
  BenHttpTransport({
    required Uri baseUri,
    http.Client? client,
    this.timeout = const Duration(seconds: 60),
  }) : _baseUri = baseUri, _client = client ?? http.Client() {
    if ((baseUri.scheme != 'http' && baseUri.scheme != 'https') ||
        baseUri.host.isEmpty || baseUri.userInfo.isNotEmpty ||
        baseUri.hasQuery || baseUri.hasFragment ||
        (baseUri.path.isNotEmpty && baseUri.path != '/')) {
      throw ArgumentError.value(baseUri, 'baseUri', 'Expected a BEN origin');
    }
  }

  final Uri _baseUri;
  final http.Client _client;
  final Duration timeout;
  void close() => _client.close();

  @override
  Future<Map<String, dynamic>> get(String route, Map<String, String> query) async {
    if (!const {'/bid', '/lead', '/play'}.contains(route)) {
      throw const BenApiException('request', 'Unsupported BEN route');
    }
    final uri = _baseUri.replace(path: route, queryParameters: query);
    late http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const BenApiException('timeout', 'BEN request timed out');
    } on http.ClientException {
      throw const BenApiException('network', 'BEN HTTP request failed');
    } catch (_) {
      throw const BenApiException('network', 'BEN transport request failed');
    }
    if (response.statusCode != 200) {
      throw BenApiException('http', 'BEN returned HTTP ${response.statusCode}');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const BenApiException('response', 'BEN did not return valid JSON');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const BenApiException('response', 'BEN must return JSON object');
    }
    if (decoded['error'] != null) {
      throw const BenApiException('response', 'BEN reported an error');
    }
    return decoded;
  }
}

