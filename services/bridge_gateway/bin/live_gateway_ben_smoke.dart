import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bridge_gateway/bridge_gateway.dart';

/// Real BEN smoke: private fixture, actual Gateway POST and BEN localhost GET.
/// Log only route/status names. Never print a hand, token, URL or raw exception.
Future<Map<String, dynamic>> _post(
    int port, String route, Map<String, Object?> body,
    {String? bearer}) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(
        Uri.parse('http://127.0.0.1:$port$route'));
    req.headers.contentType = ContentType.json;
    if (bearer != null) req.headers.set('authorization', 'Bearer $bearer');
    req.write(jsonEncode(body));
    final res = await req.close().timeout(const Duration(seconds: 140));
    final content = await utf8.decoder.bind(res).join();
    if (res.statusCode != 200 &&
        !(route == '/v1/sessions/anonymous' &&
          res.statusCode == 201)) {
      throw StateError('Unexpected Gateway HTTP status');
    }
    return jsonDecode(content) as Map<String, dynamic>;
  } finally {
    client.close(force: true);
  }
}

Future<void> main() async {
  final backend = BenLoopbackBackend(
    origin: Uri.parse('http://127.0.0.1:8085'),
    timeout: const Duration(seconds: 120),
  );
  final gateway = BridgeGatewayService(
    backend: backend,
    config: const GatewayConfig(decisionTimeout: Duration(seconds: 130)),
  );
  try {
    final port = await gateway.start();
    final issued = await _post(port, '/v1/sessions/anonymous',
        {'version': 1});
    final token = issued['access_token'] as String;
    final verified = <String, bool>{};
    Future<String> choose(String route, Map<String, String> input) async {
      final result = await _post(port, '/v1/ai/decision',
          {'version': 1, 'route': route, 'input': input}, bearer: token);
      final map = result['decision'] as Map<String, dynamic>;
      final value = map[route == 'bid' ? 'bid' : 'card'];
      if (value is! String || value.isEmpty) {
        throw StateError('Missing BEN action');
      }
      verified[route] = true;
      return value;
    }

    await choose('bid', {
      'hand': 'AJ5.KQ7.A982.K76', 'seat': 'N', 'dealer': 'N',
      'vul': '', 'ctx': '',
    });
    final lead = await choose('lead', {
      'hand': '32.9843.J73.Q943', 'seat': 'E', 'dealer': 'N',
      'vul': '', 'ctx': '3N-P-P-P',
    });
    if (!RegExp(r'^[CDHS][2-9TJQKA]$').hasMatch(lead)) {
      throw StateError('Unexpected card format');
    }
    await choose('play', {
      'hand': 'AJ5.KQ7.A982.K76', 'seat': 'N', 'dealer': 'N',
      'vul': '', 'ctx': '3N-P-P-P',
      'dummy': 'QT6.AJ6.KT6.JT52', 'played': lead,
    });
    stdout.writeln(jsonEncode({
      'result': 'PASS',
      'realBen': true,
      'gateway': 'POST',
      'upstream': 'GET_LOOPBACK',
      'routes': verified,
    }));
  } catch (_) {
    // Never print exception details: BEN exceptions can contain private URLs.
    stderr.writeln('A4_3_1_REAL_BEN_GATEWAY_SMOKE_FAILED');
    exitCode = 1;
  } finally {
    await gateway.close();
    backend.close();
  }
}
