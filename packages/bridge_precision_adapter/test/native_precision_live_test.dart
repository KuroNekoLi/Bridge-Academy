import 'dart:io';

import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_precision_adapter/bridge_precision_adapter.dart';
import 'package:test/test.dart';

void main() {
  test('M3.3 real EPBot sidecar -> Dart filtered PlayerView -> legal proposal',
      () async {
    final uri = Platform.environment['PRECISION_NATIVE_ORIGIN'];
    if (uri == null) return; // not real-EPBot evidence outside CI
    final transport = BbaPrecisionLoopbackTransport(origin: Uri.parse(uri));
    try {
      final view = PlayerView.forSeat(
        GameState.start(Deal.suitPerSeat(), Seat.north, Vulnerability.none),
        Seat.north,
      );
      final policy = BbaPrecisionBiddingProvider(
          transport: transport, precisionSideIsNS: true,
          opponentModel: 'SAYC');
      final proposed = await policy.choose(view);
      expect(proposed, isA<CallAction>());
      // Core is the final legal-actor validator, never the EPBot sidecar.
      final after = BridgeGame.apply(
          GameState.start(Deal.suitPerSeat(), Seat.north, Vulnerability.none),
          proposed);
      expect(after.version, 1);
      expect(after.auction, hasLength(1));
    } finally {
      transport.close();
    }
  });
}
