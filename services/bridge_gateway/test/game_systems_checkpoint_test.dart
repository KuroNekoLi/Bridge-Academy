import 'dart:convert';

import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_gateway/bridge_gateway.dart';
import 'package:test/test.dart';

void main() {
  group('M2.1 server-owned immutable game system persistence', () {
    const backend = UnavailableDecisionBackend();

    GameSystems approved() => GameSystems(
      northSouth: ConventionCatalog.twoOverOne,
      eastWest: ConventionCatalog.sayc,
    );

    AuthoritativeGame game({GameSystems? systems}) => AuthoritativeGame(
      deal: Deal.suitPerSeat(),
      backend: backend,
      gameSystems: systems,
    );

    Map<String, dynamic> checkpoint(AuthoritativeGame g) =>
        jsonDecode(jsonEncode(g.trustedCheckpoint())) as Map<String, dynamic>;

    test('one game freezes different north-south and east-west profiles', () {
      final pinned = approved();
      final session = game(systems: pinned);
      expect(session.gameSystems.fingerprint, pinned.fingerprint);
      expect(session.gameSystems.northSouth.modelId, '21GF');
      expect(session.gameSystems.eastWest.modelId, 'SAYC');
      expect(checkpoint(session)['gameSystems'], pinned.toJson());

      // M2.1 metadata is trusted-only and does not change public API v1.
      final view = session.view();
      expect(view.keys, containsAll(['version', 'view']));
      expect(view, isNot(contains('gameSystems')));
      expect(view.toString(), isNot(contains('BA-21GF')));
      expect(view.toString(), isNot(contains('BA-SAYC')));
    });

    test('valid stored system survives encrypted-archive-style JSON roundtrip', () {
      final g = game(systems: approved());
      final saved = checkpoint(g);
      final restored = AuthoritativeGame.restore(
          archive: saved, backend: backend);
      expect(restored.gameSystems, approved());
      expect(restored.gameSystems.fingerprint, g.gameSystems.fingerprint);
      expect(restored.view(), g.view());

      // Changing the decoded archive after construction changes no live pin.
      final encoded = saved['gameSystems'] as Map<String, dynamic>;
      final ns = encoded['northSouth'] as Map<String, dynamic>;
      ns['modelId'] = 'ALTERED';
      expect(restored.gameSystems.northSouth.modelId, '21GF');
    });

    test('tampered or unsupported profile fails closed on restore', () {
      for (final kind in ['revision', 'model', 'fingerprint', 'missing']) {
        final saved = checkpoint(game(systems: approved()));
        final systems = saved['gameSystems'] as Map<String, dynamic>;
        final ns = systems['northSouth'] as Map<String, dynamic>;
        switch (kind) {
          case 'revision':
            ns['revision'] = 999;
          case 'model':
            ns['modelId'] = 'UNSUPPORTED';
          case 'fingerprint':
            systems['fingerprint'] = 'sha256:wrong';
          case 'missing':
            systems.remove('northSouth');
        }
        expect(
          () => AuthoritativeGame.restore(archive: saved, backend: backend),
          throwsFormatException,
          reason: kind,
        );
      }
    });

    test('old checkpoints without system pin migrate as unverified', () {
      final original = game();
      final old = checkpoint(original)..remove('gameSystems');
      final recovered =
          AuthoritativeGame.restore(archive: old, backend: backend);
      expect(recovered.gameSystems.northSouth.isLegacyUnverified, true);
      expect(recovered.gameSystems.eastWest.isLegacyUnverified, true);
      expect(recovered.gameSystems.northSouth.modelId, 'UNVERIFIED');
      expect(recovered.view(), original.view());
      final resaved = checkpoint(recovered);
      expect(resaved['gameSystems'], GameSystems.legacyUnverified().toJson());
    });

    test('new session default never falsely claims 2/1/SAYC', () {
      final defaultGame = game();
      expect(defaultGame.gameSystems, GameSystems.legacyUnverified());
      expect(defaultGame.gameSystems.northSouth.modelId, 'UNVERIFIED');
      expect(defaultGame.gameSystems.eastWest.modelId, 'UNVERIFIED');
    });
  });
}
