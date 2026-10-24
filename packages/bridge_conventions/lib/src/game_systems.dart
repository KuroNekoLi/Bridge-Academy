import 'dart:convert';

import 'package:crypto/crypto.dart';

/// M2.1: a *metadata pin*, not a claim the deployed BEN Worker supports it.
/// The trusted catalog, not HTTP clients, creates selectable profiles.
final class PartnershipSystem {
  const PartnershipSystem._({
    required this.profileId,
    required this.revision,
    required this.engineId,
    required this.modelId,
    required this.modelRevision,
    required this.profileFingerprint,
  });

  final String profileId;
  final int revision;
  final String engineId;
  final String modelId;
  final String modelRevision;
  final String profileFingerprint;

  bool get isLegacyUnverified => profileId == 'LEGACY_UNVERIFIED';

  static String _fingerprint(
    String id, int revision, String engine, String model, String modelRevision,
  ) {
    final canonical = jsonEncode([
      'bridge-academy-partnership-profile-v1',
      id, revision, engine, model, modelRevision,
    ]);
    return 'sha256:${sha256.convert(utf8.encode(canonical))}';
  }

  factory PartnershipSystem._known(
    String id, int revision, String engine, String model, String modelRevision,
  ) {
    if (!RegExp(r'^[A-Z0-9_-]{2,50}$').hasMatch(id) ||
        revision < 1 ||
        !RegExp(r'^[A-Z0-9_-]{2,50}$').hasMatch(engine) ||
        model.isEmpty || modelRevision.isEmpty) {
      throw ArgumentError('Invalid trusted bidding-system profile');
    }
    return PartnershipSystem._(
      profileId: id,
      revision: revision,
      engineId: engine,
      modelId: model,
      modelRevision: modelRevision,
      profileFingerprint: _fingerprint(id, revision, engine, model, modelRevision),
    );
  }

  Map<String, Object> toJson() => {
    'profileId': profileId,
    'revision': revision,
    'engineId': engineId,
    'modelId': modelId,
    'modelRevision': modelRevision,
    'profileFingerprint': profileFingerprint,
  };

  /// Trusted checkpoint recovery still rejects unknown systems/versions;
  /// a syntactically valid hash is not authorization for an arbitrary model.
  factory PartnershipSystem.fromTrustedJson(Object? raw) {
    if (raw is! Map || raw.keys.toSet().difference(const {
      'profileId', 'revision', 'engineId', 'modelId',
      'modelRevision', 'profileFingerprint',
    }).isNotEmpty || raw.length != 6) {
      throw const FormatException('Invalid partnership system schema');
    }
    final id = raw['profileId'];
    final revision = raw['revision'];
    if (id is! String || revision is! int) {
      throw const FormatException('Invalid partnership system identity');
    }
    final registered = ConventionCatalog.resolve(id, revision);
    if (registered == null || !_sameFields(registered.toJson(), raw)) {
      throw const FormatException('Unknown or mismatched partnership profile');
    }
    return registered;
  }

  static bool _sameFields(Map<String, Object> known, Map raw) =>
      known.length == raw.length &&
      known.entries.every((entry) => raw[entry.key] == entry.value);

  @override
  bool operator ==(Object other) =>
      other is PartnershipSystem &&
      profileFingerprint == other.profileFingerprint;

  @override
  int get hashCode => profileFingerprint.hashCode;

  @override
  String toString() => '$profileId/r$revision ($modelId)';
}

/// Registry is intentionally allowlisted. Precision and custom profiles are
/// not enabled in M2.1; BEN routing and runtime matching start in M2.2/2.3.
abstract final class ConventionCatalog {
  static const String benCandidateRevision =
      'ad8608af6e6bfe095863023f344f3cb2cbafec3d';

  static final PartnershipSystem legacyUnverified =
      PartnershipSystem._known(
    'LEGACY_UNVERIFIED', 1, 'LEGACY', 'UNVERIFIED', 'UNVERIFIED',
  );

  static final PartnershipSystem twoOverOne = PartnershipSystem._known(
    'BA-21GF', 1, 'BEN', '21GF', benCandidateRevision,
  );

  static final PartnershipSystem sayc = PartnershipSystem._known(
    'BA-SAYC', 1, 'BEN', 'SAYC', benCandidateRevision,
  );

  /// M3.4 experimental identity. Registry pin does NOT mean a playable
  /// neural model; Gateway checks explicit research-only runtime permission.
  static final PartnershipSystem precisionMeckwell = PartnershipSystem._known(
    'BA-PRECISION-MECKWELL',
    1,
    'BBA',
    'MECKWELL',
    '5c2a6c8d84094a0a9efd2cefe98a93983185140e6bde81b2520086b8b27d9cbc',
  );

  static final Map<String, PartnershipSystem> _known = Map.unmodifiable({
    for (final profile in [legacyUnverified, twoOverOne, sayc, precisionMeckwell])
      '${profile.profileId}/${profile.revision}': profile,
  });

  static PartnershipSystem? resolve(String profileId, int revision) =>
      _known['$profileId/$revision'];

  /// Identifies profiles available to M2.2 for integration; this does NOT
  /// claim a production BEN Worker has matching model weights loaded.
  static List<PartnershipSystem> get candidateProfiles =>
      List.unmodifiable([twoOverOne, sayc]);

  /// Experimental only: not part of production advertised candidates.
  static List<PartnershipSystem> get researchProfiles =>
      List.unmodifiable([twoOverOne, sayc, precisionMeckwell]);
}

/// One game has TWO fixed partnerships, not one mutable user preference.
/// It stays out of Bridge Core: game rules are system-agnostic.
final class GameSystems {
  factory GameSystems({
    required PartnershipSystem northSouth,
    required PartnershipSystem eastWest,
  }) => GameSystems._(northSouth: northSouth, eastWest: eastWest);

  GameSystems._({
    required this.northSouth,
    required this.eastWest,
  }) : fingerprint = _fingerprint(northSouth, eastWest);

  static const schemaVersion = 1;
  final PartnershipSystem northSouth;
  final PartnershipSystem eastWest;
  final String fingerprint;

  /// Existing anonymous games have no verifiable system selection. Preserve
  /// that fact, rather than incorrectly saying they played SAYC/21GF.
  factory GameSystems.legacyUnverified() => GameSystems(
    northSouth: ConventionCatalog.legacyUnverified,
    eastWest: ConventionCatalog.legacyUnverified,
  );

  PartnershipSystem forPartnership({required bool northSouthSeat}) =>
      northSouthSeat ? northSouth : eastWest;

  static String _fingerprint(
    PartnershipSystem northSouth, PartnershipSystem eastWest,
  ) {
    final canonical = jsonEncode([
      'bridge-academy-game-systems-v1',
      schemaVersion,
      northSouth.profileFingerprint,
      eastWest.profileFingerprint,
    ]);
    return 'sha256:${sha256.convert(utf8.encode(canonical))}';
  }

  Map<String, Object> toJson() => {
    'schemaVersion': schemaVersion,
    'northSouth': northSouth.toJson(),
    'eastWest': eastWest.toJson(),
    'fingerprint': fingerprint,
  };

  factory GameSystems.fromTrustedJson(Object? raw) {
    if (raw is! Map || raw.length != 4 ||
        !raw.keys.toSet().containsAll(const {
          'schemaVersion', 'northSouth', 'eastWest', 'fingerprint',
        }) ||
        raw['schemaVersion'] != schemaVersion) {
      throw const FormatException('Invalid GameSystems schema');
    }
    final restored = GameSystems(
      northSouth: PartnershipSystem.fromTrustedJson(raw['northSouth']),
      eastWest: PartnershipSystem.fromTrustedJson(raw['eastWest']),
    );
    if (raw['fingerprint'] != restored.fingerprint) {
      throw const FormatException('GameSystems fingerprint mismatch');
    }
    return restored;
  }

  @override
  bool operator ==(Object other) =>
      other is GameSystems && fingerprint == other.fingerprint;

  @override
  int get hashCode => fingerprint.hashCode;
}
