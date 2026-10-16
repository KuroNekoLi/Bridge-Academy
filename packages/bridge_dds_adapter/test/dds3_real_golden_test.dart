import 'dart:io';
import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_dds_adapter/bridge_dds_adapter.dart';
import 'package:test/test.dart';

Deal _rotatedFixture(int rotation) {
  final initial = Deal.suitPerSeat();
  return Deal({
    for (final seat in Seat.values)
      seat: initial.hands[Seat.values[(seat.index + rotation) % 4]]!,
  });
}

void main() {
  final integration = Platform.environment['C1_DDS_REAL'] == '1';
  test('Three REAL DDS3 deal tables: 20 cells each, suit-vs-NT',
      () async {
    final service = DdsPythonProcessAnalyzer(
      workerScript:
          Platform.environment['C1_DDS_WORKER'] ??
          'tool/dds3_worker.py',
      timeout: const Duration(seconds: 90),
    );
    for (final rotation in [0, 1, 2]) {
      final deal = _rotatedFixture(rotation);
      final board = TrustedCompletedBoard.explicitTeachingFixture(
        originalDeal: deal,
        dealer: Seat.values[rotation],
        vulnerability: Vulnerability.values[rotation],
      );
      final first = await service.analyze(board);
      final second = await service.analyze(board);
      expect(first.byStrain, second.byStrain,
          reason: 'Same fixed deal + pinned DDS3 must be reproducible');
      for (final strain in Strain.values) {
        for (final seat in Seat.values) {
          final tricks = first.tricks(strain: strain, declarer: seat);
          expect(tricks, inInclusiveRange(0, 13));
          if (strain == Strain.notrump) {
            expect(tricks, 0,
              reason: 'Under NT the opening defender can run all 13 of one suit');
          } else {
            final trumpOwner = Seat.values.firstWhere(
              (owner) => deal.hands[owner]!.every(
                (card) => card.suit == strain.trump),
            );
            expect(tricks, seat.isNS == trumpOwner.isNS ? 13 : 0,
              reason: 'Only one partnership owns all 13 trumps');
          }
        }
      }
      expect(first.solverCommit, DoubleDummyTable.upstreamCommit);
    }
  }, skip: !integration
      ? 'Requires pinned upstream genuine DDS3 Python extension'
      : false);
}
