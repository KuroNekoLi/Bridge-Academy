import 'dart:io';

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
  final gateway = BridgeGatewayService(
    backend: benBackend,
    config: GatewayConfig(
      decisionTimeout: benBackend == null
          ? const Duration(seconds: 30)
          : const Duration(seconds: 130),
    ),
  );
  await gateway.start(port: port);
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
