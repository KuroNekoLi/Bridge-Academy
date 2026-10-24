import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:test/test.dart';


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

    test('single selected V1 is pinned to the native Meckwell card', () {
      expect(PrecisionResearchCatalog.selectedProductProfileId,
          'BA-PRECISION-MECKWELL');
      expect(PrecisionResearchCatalog.selectedProductRevision, 1);
      expect(PrecisionResearchCatalog.selectedProductName,
          'BBA Meckwell Precision V1');
      expect(PrecisionResearchCatalog.selectedV1,
          same(PrecisionResearchCatalog.upstreamBbaMeckwell));
      expect(PrecisionResearchCatalog.selectedCardSha256,
          '5c2a6c8d84094a0a9efd2cefe98a93983185140e6bde81b2520086b8b27d9cbc');
      expect(PrecisionResearchCatalog.bbaPermissionReportedByOwner, isTrue);
      expect(PrecisionResearchCatalog.commercialHostingPermissionReported, isTrue);
      expect(PrecisionResearchCatalog.modificationPermissionReported, isTrue);
      expect(PrecisionResearchCatalog.redistributionPermissionReported, isTrue);
      expect(PrecisionResearchCatalog.bbaPermissionScopeVerified, isFalse);
      expect(PrecisionResearchCatalog.selectedV1.readyForCatalog, isFalse);
      expect(ConventionCatalog.resolve('BA-PRECISION-MECKWELL', 1), isNull);
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
