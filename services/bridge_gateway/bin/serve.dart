import 'dart:io';
import 'dart:convert';

import 'package:bridge_gateway/bridge_gateway.dart';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['GATEWAY_PORT'] ?? '8086');
  if (port == null || port < 1024 || port > 65535) {
    stderr.writeln('GATEWAY_PORT must be between 1024 and 65535');
    exitCode = 64;
    return;
  }

  // Explicit opt-in to a literal loopback BEN worker only. By default the
  // Gateway returns 503 instead of silently using Demo or public network.
  final upstream = Platform.environment['BEN_INTERNAL_ORIGIN'];
  BenLoopbackBackend? benBackend;
  if (upstream != null && upstream.isNotEmpty) {
    try {
      benBackend = BenLoopbackBackend(origin: Uri.parse(upstream));
    } catch (_) {
      stderr.writeln('BEN_INTERNAL_ORIGIN must be a loopback HTTP origin');
      exitCode = 64;
      return;
    }
  }
  // Pinned BEN may take longer than local HTTP mocks; the outbound backend
  // still has a stricter 120s timeout, and the gateway returns no fake action.
  final checkpointDir = Platform.environment['GATEWAY_CHECKPOINT_DIR'];
  final keyText = Platform.environment['GATEWAY_CHECKPOINT_KEY_B64'];
  EncryptedSessionStore? store;
  if (checkpointDir != null || keyText != null) {
    if (checkpointDir == null || checkpointDir.isEmpty ||
        keyText == null || keyText.isEmpty) {
      stderr.writeln('Encrypted store requires both checkpoint directory and key');
      exitCode = 64;
      return;
    }
    try {
      store = EncryptedSessionStore(
        directory: Directory(checkpointDir),
        key: base64.decode(keyText),
      );
    } catch (_) {
      stderr.writeln('Invalid encrypted store configuration');
      exitCode = 64;
      return;
    }
  }
  final gateway = BridgeGatewayService(
    checkpointStore: store,
    backend: benBackend,
    config: GatewayConfig(
      decisionTimeout: benBackend == null
          ? const Duration(seconds: 30)
          : const Duration(seconds: 130),
    ),
  );
  try {
    await gateway.start(port: port);
  } catch (_) {
    stderr.writeln('Gateway failed to open checkpoint store or bind localhost');
    exitCode = 78;
    return;
  }
  stdout.writeln(
      'Bridge Academy DEV gateway on 127.0.0.1:$port '
      '(BEN upstream: ${benBackend == null ? 'disabled' : 'loopback only'})');
  await Future.any([
    ProcessSignal.sigint.watch().first,
    ProcessSignal.sigterm.watch().first,
  ]);
  await gateway.close();
  benBackend?.close();
}
