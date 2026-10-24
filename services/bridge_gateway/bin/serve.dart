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
      benBackend = BenLoopbackBackend(
        origin: Uri.parse(upstream),
        pinnedBenRevision: Platform.environment['BEN_PINNED_COMMIT'],
      );
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
  // A4.4 Flutter Web: explicitly allow a trusted browser development
  // Origin. No '*' wildcard or implicit CORS permission. The Gateway still
  // binds 127.0.0.1 and accepts only authorized POST game actions.
  final allowedOrigins = <String>{};
  final rawOrigins = Platform.environment['GATEWAY_BROWSER_ORIGINS'];
  if (rawOrigins != null && rawOrigins.isNotEmpty) {
    try {
      for (final text in rawOrigins.split(',')) {
        final uri = Uri.parse(text.trim());
        if (uri.hasQuery || uri.hasFragment ||
            uri.userInfo.isNotEmpty ||
            (uri.path.isNotEmpty && uri.path != '/') ||
            (uri.scheme != 'https' &&
                !(uri.scheme == 'http' &&
                  const {'localhost', '127.0.0.1', '::1'}
                      .contains(uri.host)))) {
          throw const FormatException('Invalid browser Origin');
        }
        allowedOrigins.add(uri.origin);
      }
    } catch (_) {
      stderr.writeln('Invalid GATEWAY_BROWSER_ORIGINS');
      exitCode = 64;
      return;
    }
  }
  // Explicit development-only quota override for a complete 52-card board.
  // The default 30/minute still applies unless an operator opts in.
  // This executable binds loopback only; never expose this override as a
  // remotely configurable public API.
  final quotaText = Platform.environment['GATEWAY_DEV_DECISION_LIMIT'];
  final devQuota = quotaText == null ? 30 : int.tryParse(quotaText);
  if (devQuota == null || devQuota < 1 || devQuota > 240) {
    stderr.writeln('GATEWAY_DEV_DECISION_LIMIT must be between 1 and 240');
    exitCode = 64;
    return;
  }
  final gateway = BridgeGatewayService(
    checkpointStore: store,
    backend: benBackend,
    config: GatewayConfig(
      allowedBrowserOrigins: allowedOrigins,
      decisionLimit: devQuota,
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
