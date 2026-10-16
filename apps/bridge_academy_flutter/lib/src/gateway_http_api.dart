import 'dart:convert';

import 'package:http/http.dart' as http;

/// Token never appears in URLs, diagnostics or persistent Flutter storage.
/// Browser deployments MUST use a separately approved HTTPS gateway origin.
class GatewayHttpError implements Exception {
  const GatewayHttpError(this.status, this.code);
  final int status;
  final String code;
}

abstract interface class GatewayApi {
  Future<Map<String, dynamic>> post(
    String path, Map<String, Object?> data, {String? bearer});
}

class GatewayHttpApi implements GatewayApi {
  GatewayHttpApi({required Uri origin, http.Client? client})
      : _origin = _validateOrigin(origin),
        _client = client ?? http.Client(),
        _ownsClient = client == null;

  final Uri _origin;
  final http.Client _client;
  final bool _ownsClient;

  static Uri _validateOrigin(Uri origin) {
    if ((origin.scheme != 'https' &&
            !(origin.scheme == 'http' &&
              const {'127.0.0.1', '::1', 'localhost'}.contains(origin.host))) ||
        origin.host.isEmpty ||
        origin.userInfo.isNotEmpty ||
        origin.hasQuery || origin.hasFragment ||
        (origin.path.isNotEmpty && origin.path != '/')) {
      throw ArgumentError('Gateway origin must be trusted HTTPS or local dev');
    }
    return origin;
  }

  @override
  Future<Map<String, dynamic>> post(
      String path, Map<String, Object?> data, {String? bearer}) async {
    if (!const {
      '/v1/sessions/anonymous', '/v1/games/view',
      '/v1/games/action', '/v1/games/advance',
    }.contains(path)) {
      throw ArgumentError('Unsupported secure Gateway route');
    }
    // All sensitive data is JSON body or Authorization header, never a query.
    final request = http.Request('POST', _origin.replace(path: path));
    request.followRedirects = false;
    request.headers['Content-Type'] = 'application/json';
    request.headers['Accept'] = 'application/json';
    if (bearer != null) {
      request.headers['Authorization'] = 'Bearer $bearer';
    }
    request.body = jsonEncode(data);
    try {
      final wire = await _client.send(request).timeout(
          const Duration(seconds: 150));
      final response = await http.Response.fromStream(wire)
          .timeout(const Duration(seconds: 150));
      if (response.statusCode != 200 &&
          !(path == '/v1/sessions/anonymous' && response.statusCode == 201)) {
        // Never include raw server response; it might contain private data.
        throw GatewayHttpError(response.statusCode, 'request_rejected');
      }
      if (response.bodyBytes.length > 65536) {
        throw const GatewayHttpError(502, 'response_too_large');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const GatewayHttpError(502, 'invalid_response');
      }
      return decoded;
    } on GatewayHttpError {
      rethrow;
    } catch (_) {
      // Never disclose raw HTTP exception, origin, card contents or bearer.
      throw const GatewayHttpError(0, 'network_unavailable');
    }
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
