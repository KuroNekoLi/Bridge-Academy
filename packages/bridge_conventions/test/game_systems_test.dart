import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:test/test.dart';

void main() {
  group('M2.1 immutable model and allowlisted conventions', () {
    test('two verified candidate identities have pinned engine revision', () {
      final profiles = ConventionCatalog.candidateProfiles;
      expect(profiles.map((p) => p.modelId), ['21GF', 'SAYC']);
      expect(profiles.every((p) =>
          p.engineId == 'BEN' &&
          p.modelRevision == ConventionCatalog.benCandidateRevision), isTrue);
      expect(ConventionCatalog.resolve('BA-PRECISION', 1), isNull);
      expect(ConventionCatalog.resolve('BA-21GF', 2), isNull);
      expect(ConventionCatalog.resolve('BA-SAYC', 1),
          same(ConventionCatalog.sayc));
      expect(() => profiles.clear(), throwsUnsupportedError);
    });

    test('NS and EW are independent frozen values, not one mutable choice', () {
      final pair = GameSystems(
        northSouth: ConventionCatalog.twoOverOne,
        eastWest: ConventionCatalog.sayc,
      );
      expect(pair.forPartnership(northSouthSeat: true).modelId, '21GF');
      expect(pair.forPartnership(northSouthSeat: false).modelId, 'SAYC');
      expect(pair.northSouth, isNot(pair.eastWest));
      expect(pair, GameSystems.fromTrustedJson(pair.toJson()));
      expect(pair.hashCode, GameSystems.fromTrustedJson(pair.toJson()).hashCode);
      expect(pair.fingerprint, startsWith('sha256:'));
      expect(pair.fingerprint.length, 71);

      final reversed = GameSystems(
        northSouth: ConventionCatalog.sayc,
        eastWest: ConventionCatalog.twoOverOne,
      );
      expect(reversed.fingerprint, isNot(pair.fingerprint));
    });

    test('serialized map mutation cannot change the game or catalog', () {
      final frozen = GameSystems(
        northSouth: ConventionCatalog.twoOverOne,
        eastWest: ConventionCatalog.sayc,
      );
      final before = frozen.fingerprint;
      final mutable = frozen.toJson();
      (mutable['northSouth'] as Map<String, Object>)['modelId'] = 'HACKED';
      mutable['fingerprint'] = 'sha256:attacker';
      expect(frozen.fingerprint, before);
      expect(frozen.northSouth.modelId, '21GF');
      expect(ConventionCatalog.twoOverOne.modelId, '21GF');
    });

    test('profile identity, revision and stored digest are always validated', () {
      final valid = GameSystems(
        northSouth: ConventionCatalog.twoOverOne,
        eastWest: ConventionCatalog.sayc,
      ).toJson();

      Map<String, Object> modified() => {
        ...valid,
        'northSouth': Map<String, Object>.from(
            valid['northSouth'] as Map<String, Object>),
      };
      var changed = modified();
      (changed['northSouth'] as Map<String, Object>)['modelId'] = 'SAYC';
      expect(() => GameSystems.fromTrustedJson(changed),
          throwsFormatException);

      changed = modified();
      (changed['northSouth'] as Map<String, Object>)['revision'] = 2;
      expect(() => GameSystems.fromTrustedJson(changed),
          throwsFormatException);

      changed = modified();
      (changed['northSouth'] as Map<String, Object>)['profileId'] =
          'BA-PRECISION';
      expect(() => GameSystems.fromTrustedJson(changed),
          throwsFormatException);

      changed = {...valid, 'fingerprint': 'sha256:wrong'};
      expect(() => GameSystems.fromTrustedJson(changed),
          throwsFormatException);

      changed = {...valid, 'unexpected': true};
      expect(() => GameSystems.fromTrustedJson(changed),
          throwsFormatException);

      changed = {...valid, 'schemaVersion': 2};
      expect(() => GameSystems.fromTrustedJson(changed),
          throwsFormatException);

      expect(() => GameSystems.fromTrustedJson(null), throwsFormatException);
      expect(() => GameSystems.fromTrustedJson({'schemaVersion': 1}),
          throwsFormatException);
    });

    test('legacy profiles are explicitly unverified, not falsely SAYC', () {
      final old = GameSystems.legacyUnverified();
      expect(old.northSouth.isLegacyUnverified, isTrue);
      expect(old.eastWest.isLegacyUnverified, isTrue);
      expect(old.northSouth.modelId, 'UNVERIFIED');
      expect(GameSystems.fromTrustedJson(old.toJson()), old);
      expect(old, GameSystems.legacyUnverified());
    });
  });
}
