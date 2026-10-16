import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

Future<({int status, Map<String, dynamic> body})> _post(
    int port, String route, Map<String, Object?> payload,
    {String? token}) async {
  final client = HttpClient();
  try {
    final req = await client.postUrl(Uri.parse('http://127.0.0.1:$port$route'));
    req.headers.contentType = ContentType.json;
    if (token != null) {
      req.headers.set('Authorization', 'Bearer $token');
    }
    req.write(jsonEncode(payload));
    final response = await req.close();
    return (
      status: response.statusCode,
      body: jsonDecode(await utf8.decoder.bind(response).join())
          as Map<String, dynamic>,
    );
  } finally {
    client.close(force: true);
  }
}

Future<int> _freeLocalPort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

Future<void> _waitForHealth(int port, Process process) async {
  final watch = Stopwatch()..start();
  while (watch.elapsed < const Duration(seconds: 25)) {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
          Uri.parse('http://127.0.0.1:$port/healthz'))
          .timeout(const Duration(seconds: 1));
      final response = await request.close()
          .timeout(const Duration(seconds: 1));
      await response.drain<void>();
      if (response.statusCode == 200) return;
    } catch (_) {
      // Process may still be compiling and starting.
    } finally {
      client.close(force: true);
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  process.kill(ProcessSignal.sigkill);
  throw StateError('Gateway child process did not become healthy');
}

void main() {
  test('A4.3.2b OS SIGKILL and new Dart process restore bearer+ack',
      () async {
    final temp = await Directory.systemTemp.createTemp('bridge-process-restart-');
    final port = await _freeLocalPort();
    final secret = base64.encode(List<int>.generate(32, (i) => i + 1));
    final environment = {
      ...Platform.environment,
      'GATEWAY_PORT': port.toString(),
      'GATEWAY_CHECKPOINT_DIR': temp.path,
      'GATEWAY_CHECKPOINT_KEY_B64': secret,
    };
    Process? process;

    Future<void> launch() async {
      process = await Process.start(
        Platform.resolvedExecutable,
        ['run', 'bin/serve.dart'],
        workingDirectory: Directory.current.path,
        environment: environment,
      );
      // Do not print child logs: test fixtures and potential BEN errors can
      // become sensitive as the gateway evolves.
      unawaited(process!.stdout.drain<void>());
      unawaited(process!.stderr.drain<void>());
      await _waitForHealth(port, process!);
    }

    Future<void> terminate() async {
      final running = process;
      process = null;
      if (running != null) {
        running.kill(ProcessSignal.sigkill);
        await running.exitCode.timeout(const Duration(seconds: 5));
      }
    }

    try {
      await launch();
      final issued = await _post(port, '/v1/sessions/anonymous',
          {'version': 1});
      expect(issued.status, 201);
      final token = issued.body['access_token'] as String;
      final payload = {
        'version': 1,
        'expected_version': 0,
        'request_id': 'process_crash_001',
        'action': {'kind': 'bid', 'call': '1NT'},
      };
      final first = await _post(port, '/v1/games/action', payload, token: token);
      expect(first.status, 200);
      expect((first.body['view'] as Map)['version'], 1);

      // Force-kill the entire Dart VM, not merely close BridgeGatewayService.
      await terminate();
      await launch();

      final restored = await _post(port, '/v1/games/view',
          {'version': 1}, token: token);
      expect(restored.status, 200);
      expect((restored.body['view'] as Map)['version'], 1);
      final duplicate = await _post(port, '/v1/games/action',
          payload, token: token);
      expect(duplicate.status, 200);
      expect(duplicate.body, first.body);
      final stale = await _post(port, '/v1/games/action', {
        ...payload,
        'request_id': 'process_crash_002',
      }, token: token);
      expect(stale.status, 409);
      final legacy = await _post(port, '/v1/ai/decision',
          {'version': 1, 'route': 'bid', 'input': {'hand': 'SECRET'}},
          token: token);
      expect(legacy.status, 404);
    } finally {
      await terminate();
      await temp.delete(recursive: true);
    }
  }, skip: !Platform.isLinux,
     timeout: const Timeout(Duration(minutes: 2)));
}
