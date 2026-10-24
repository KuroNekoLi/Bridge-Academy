/// M3 Precision design evidence. Not a selectable ConventionCatalog profile.
///
/// Meckwell Lite and the upstream EPBot Meckwell card are NOT interchangeable:
/// the reference card (2026-01-05) lists 1NT 13-16 whereas the pinned upstream
/// BEN/BBA Meckwell.bbsa selects 13-15. Further artificial responses, opening
/// ranges, interference, alerts and engine behavior need expert verification.
final class PrecisionResearchCandidate {
  const PrecisionResearchCandidate({
    required this.researchId,
    required this.source,
    required this.oneNotrumpRange,
    required this.strongOneClubMeaning,
    required this.runtimeBackend,
    required this.nativeSystemType,
    required this.backendValidated,
    required this.expertApproved,
    required this.licenseApproved,
    required this.supportedByPlayableBenNeuralModel,
  });

  final String researchId;
  final String source;
  final String oneNotrumpRange;
  final String strongOneClubMeaning;
  final String runtimeBackend;
  final int nativeSystemType;
  final bool backendValidated;
  final bool expertApproved;
  final bool licenseApproved;
  final bool supportedByPlayableBenNeuralModel;

  bool get readyForCatalog =>
      expertApproved && licenseApproved && backendValidated;

  Map<String, Object> toReport() => {
    'researchId': researchId,
    'source': source,
    'oneNotrumpRange': oneNotrumpRange,
    'strongOneClubMeaning': strongOneClubMeaning,
    'runtimeBackend': runtimeBackend,
    'nativeSystemType': nativeSystemType,
    'backendValidated': backendValidated,
    'expertApproved': expertApproved,
    'licenseApproved': licenseApproved,
    'supportedByPlayableBenNeuralModel': supportedByPlayableBenNeuralModel,
    'readyForCatalog': readyForCatalog,
  };
}

abstract final class PrecisionResearchCatalog {
  static const String benPinnedRevision =
      'ad8608af6e6bfe095863023f344f3cb2cbafec3d';

  /// Documentation candidate; no claim its complete alerts/interference
  /// semantics have been expert-approved for Bridge Academy.
  static const meckwellLiteReference = PrecisionResearchCandidate(
    researchId: 'PRECISION-MECKWELL-LITE-20260105-REFERENCE',
    source: 'https://zaremba.ch/files/precision-meckwell_lite.pdf',
    oneNotrumpRange: '13-16',
    strongOneClubMeaning: '17+ balanced or 16+ unbalanced (exceptions noted)',
    runtimeBackend: 'DOCUMENTATION_ONLY',
    nativeSystemType: 3,
    backendValidated: false,
    expertApproved: false,
    licenseApproved: false,
    supportedByPlayableBenNeuralModel: false,
  );

  /// Actual card in pinned BEN checkout; only research with isolated EPBot.
  static const upstreamBbaMeckwell = PrecisionResearchCandidate(
    researchId: 'PRECISION-BEN-EPBOT-MECKWELL-RESEARCH',
    source: 'https://github.com/lorserker/ben/blob/ad8608af6e6bfe095863023f344f3cb2cbafec3d/BBA/CC/Meckwell.bbsa',
    oneNotrumpRange: '13-15',
    strongOneClubMeaning: 'EPBot Precision / card requires full semantic review',
    runtimeBackend: 'ISOLATED_BBA_ONLY',
    nativeSystemType: 3,
    expertApproved: false,
    licenseApproved: false,
    supportedByPlayableBenNeuralModel: false,
  );

  static const candidates = <PrecisionResearchCandidate>[
    meckwellLiteReference,
    upstreamBbaMeckwell,
  ];

  static bool get compatibleAsSameVersion =>
      meckwellLiteReference.oneNotrumpRange ==
      upstreamBbaMeckwell.oneNotrumpRange;

  /// Never map this research-only type to a selectable GameSystems profile.
  static bool get canOfferPrecisionToPlayers => false;
}
