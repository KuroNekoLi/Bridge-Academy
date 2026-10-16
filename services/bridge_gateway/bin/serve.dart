import 'dart:io';

import 'package:bridge_gateway/bridge_gateway.dart';

Future<void> main() async {
  final port = int.tryParse(Platform.environment['GATEWAY_PORT'] ?? '8086');
  if (port == null || port < 1024 || port > 65535) {
    stderr.writeln('GATEWAY_PORT must be between 1024 and 65535');
    exitCode = 64;
    return;
  }

  // This local-only process intentionally does not wire in BEN yet.
  // Genuine AI decisions remain unavailable (HTTP 503) until A4.3.
  final gateway = BridgeGatewayService();
  await gateway.start(port: port);
  stdout.writeln(
      'Bridge Academy DEV gateway on 127.0.0.1:$port (BEN upstream disabled)');
  await Future.any([
    ProcessSignal.sigint.watch().first,
    ProcessSignal.sigterm.watch().first,
  ]);
  await gateway.close();
}
