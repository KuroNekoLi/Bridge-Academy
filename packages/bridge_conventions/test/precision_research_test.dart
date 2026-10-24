import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:test/test.dart';

import '../lib/src/precision_research.dart';

void main() {
  group('M3 Precision research is NOT a playable bidding system', () {
    test('documented 1NT mismatch blocks equivalence and registration', () {
      expect(PrecisionResearchCatalog.meckwellLiteReference.oneNotrumpRange,
          '13-16');
      expect(PrecisionResearchCatalog.upstreamBbaMeckwell.oneNotrumpRange,
          '13-15');
      expect(PrecisionResearchCatalog.compatibleAsSameVersion, false);
      expect(PrecisionResearchCatalog.canOfferPrecisionToPlayers, false);
      expect(PrecisionResearchCatalog.candidates.every(
          (candidate) => candidate.readyForCatalog == false), true);
    });

    test('Meckwell BBA type 3 is not a BEN neural bidder', () {
      final candidate = PrecisionResearchCatalog.upstreamBbaMeckwell;
      expect(candidate.nativeSystemType, 3);
      expect(candidate.runtimeBackend, 'ISOLATED_BBA_ONLY');
      expect(candidate.supportedByPlayableBenNeuralModel, false);
      expect(candidate.licenseApproved, false);
      expect(candidate.expertApproved, false);
    });

    test('existing production allowlist explicitly rejects Precision', () {
      expect(ConventionCatalog.resolve('BA-PRECISION', 1), isNull);
      expect(ConventionCatalog.resolve('BA-MECKWELL', 1), isNull);
      expect(ConventionCatalog.candidateProfiles
          .map((profile) => profile.modelId), ['21GF', 'SAYC']);
    });

    test('report contains explicit unapproved source conditions', () {
      final report =
          PrecisionResearchCatalog.upstreamBbaMeckwell.toReport();
      expect(report['readyForCatalog'], false);
      expect(report['licenseApproved'], false);
      expect(report['expertApproved'], false);
      expect(report['source'], contains('ad8608af'));
    });
  });
}
