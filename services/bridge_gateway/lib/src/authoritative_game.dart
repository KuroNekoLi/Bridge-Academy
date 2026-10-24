import 'package:bridge_ben_adapter/bridge_ben_adapter.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_conventions/bridge_conventions.dart';

import 'gateway_service.dart';

/// Each anonymous bearer owns one server-generated training deal.
/// An HTTP caller cannot obtain all hands or request an arbitrary seat view.
class AuthoritativeGame {
  AuthoritativeGame({
    required Deal deal,
    required GatewayDecisionBackend backend,
    BoardDefinition? trainingBoard,
    GameSystems? gameSystems,
  }) : _backend = backend,
       _gameSystems = gameSystems ?? GameSystems.legacyUnverified(),
       _coordinator = SinglePlayerCoordinator(
          deal: deal,
          dealer: trainingBoard?.dealer ?? Seat.north,
          vulnerability: trainingBoard?.vulnerability ?? Vulnerability.none,
          humanSeat: Seat.north,
          bot: BenBotPolicy(_PrivateBackendTransport(backend),
              gameSystems: gameSystems),
        );

  AuthoritativeGame._restored(this._coordinator, this._gameSystems, this._backend);

  factory AuthoritativeGame.restore({
    required Map<String, dynamic> archive,
    required GatewayDecisionBackend backend,
  }) {
    // Older encrypted checkpoints had no system metadata. Explicitly mark
    // them unverified rather than assuming a new 2/1 or SAYC contract.
    final systems = archive.containsKey('gameSystems')
        ? GameSystems.fromTrustedJson(archive['gameSystems'])
        : GameSystems.legacyUnverified();
    final game = AuthoritativeGame._restored(
      SinglePlayerCoordinator.restore(
        trustedStorageArchive: archive['transcript'] as Map<String, dynamic>,
        humanSeat: Seat.north,
        bot: BenBotPolicy(_PrivateBackendTransport(backend),
            gameSystems: systems),
      ),
      systems,
      backend,
    );
    final entries = archive['replies'] as Map<String, dynamic>? ?? {};
    for (final entry in entries.entries) {
      final value = entry.value as Map<String, dynamic>;
      game._replies[entry.key] = (
        value['fingerprint'] as String,
        Map<String, Object?>.unmodifiable(
            Map<String, Object?>.from(value['response'] as Map)),
      );
    }
    final pending = archive['pending'];
    if (pending != null) {
      game._pending = Map<String, dynamic>.from(pending as Map);
    }
    return game;
  }

  final SinglePlayerCoordinator _coordinator;
  final GatewayDecisionBackend _backend;
  final GameSystems _gameSystems;

  /// Trusted server-only metadata. Never obtained from a client action.
  GameSystems get gameSystems => _gameSystems;
  final Map<String, (String, Map<String, Object?>)> _replies = {};
  Map<String, dynamic>? _pending;
  Future<void> Function()? _checkpoint;
  bool _brokenStore = false;
  bool _busy = false;

  void setCheckpoint(Future<void> Function() checkpoint) {
    _checkpoint = checkpoint;
  }

  Map<String, Object?> trustedCheckpoint() => {
        'transcript': _coordinator.snapshotForTrustedStorage(),
        'gameSystems': _gameSystems.toJson(),
        'replies': {
          for (final entry in _replies.entries)
            entry.key: {
              'fingerprint': entry.value.$1,
              'response': entry.value.$2,
            },
        },
        'pending': _pending,
      };

  Future<void> _persist() async {
    try {
      await _checkpoint?.call();
    } catch (_) {
      _brokenStore = true;
      throw const GatewayFailure(503, 'storage_unavailable');
    }
  }

  Map<String, Object?> view() => {
        'version': 1,
        'view': _coordinator.humanView.toJson(),
      };

  Future<Map<String, Object?>> execute(
    Map<String, dynamic> body, {
    required bool advanceBots,
  }) async {
    // Validate the CURRENT worker before each request, also after restart.
    // No fallback to a default BEN model after pinned-session restoration.
    if (!_gameSystems.northSouth.isLegacyUnverified ||
        !_gameSystems.eastWest.isLegacyUnverified) {
      final supported = _backend is SystemAwareDecisionBackend &&
          await _backend
              .supportsGameSystems(_gameSystems);
      if (!supported) {
        throw const GatewayFailure(503, 'system_router_unavailable');
      }
    }
    const requiredBase = {'version', 'request_id', 'expected_version'};
    final expectedFields = advanceBots
        ? requiredBase
        : {...requiredBase, 'action'};
    if (body.keys.toSet().length != expectedFields.length ||
        !body.keys.toSet().containsAll(expectedFields) ||
        body['version'] != 1 ||
        body['expected_version'] is! int ||
        (body['expected_version'] as int) < 0 ||
        body['request_id'] is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{8,64}$')
            .hasMatch(body['request_id'] as String)) {
      throw const GatewayFailure(400, 'invalid_request');
    }
    final requestId = body['request_id'] as String;
    final expectedVersion = body['expected_version'] as int;
    GameAction? action;
    if (!advanceBots) {
      final rawAction = body['action'];
      if (rawAction is! Map<String, dynamic>) {
        throw const GatewayFailure(400, 'invalid_action');
      }
      final view = _coordinator.humanView;
      // Derive actor and controlled hand server-side; never trust a submitted
      // seat, private hand, dummy flag or the four-hand Deal.
      if (rawAction['kind'] == 'bid' &&
          rawAction.keys.toSet().containsAll({'kind', 'call'}) &&
          rawAction.length == 2 &&
          rawAction['call'] is String) {
        try {
          action = CallAction(view.viewer,
              BenProtocol.parseCall(rawAction['call'] as String));
        } catch (_) {
          throw const GatewayFailure(400, 'invalid_action');
        }
      } else if (rawAction['kind'] == 'play' &&
          rawAction.keys.toSet().containsAll({'kind', 'card'}) &&
          rawAction.length == 2 &&
          rawAction['card'] is String) {
        try {
          action = CardAction(
              view.viewer, view.turn ?? view.viewer,
              BenProtocol.parseCard(rawAction['card'] as String));
        } catch (_) {
          throw const GatewayFailure(400, 'invalid_action');
        }
      } else {
        throw const GatewayFailure(400, 'invalid_action');
      }
    }

    // Fingerprint must depend on client payload, not the new game turn.
    // Otherwise a successful duplicate dummy-play could be misidentified
    // after _coordinator.turn has advanced.
    final rawAction = body['action'] as Map<String, dynamic>?;
    final fingerprint = advanceBots
        ? 'advance:' + expectedVersion.toString()
        : 'action:' + expectedVersion.toString() + ':' +
            rawAction!['kind'].toString() + ':' +
            (rawAction['call'] ?? rawAction['card']).toString();
    if (_brokenStore) {
      throw const GatewayFailure(503, 'storage_unavailable');
    }
    final previous = _replies[requestId];
    if (previous != null) {
      if (previous.$1 != fingerprint) {
        throw const GatewayFailure(409, 'request_id_conflict');
      }
      return previous.$2;
    }
    if (_busy) throw const GatewayFailure(409, 'game_busy');
    final pending = _pending;
    if (pending != null &&
        (pending['request_id'] != requestId ||
         pending['fingerprint'] != fingerprint)) {
      throw const GatewayFailure(409, 'pending_request');
    }
    if (pending == null && expectedVersion != _coordinator.version) {
      throw const GatewayFailure(409, 'stale_version');
    }

    _busy = true;
    try {
      if (pending == null) {
        _pending = {
          'request_id': requestId,
          'fingerprint': fingerprint,
        };
        // Write pending intent BEFORE any Bridge Core action.
        await _persist();
      }
      if (advanceBots) {
        // Checkpoint each committed bot action; restarting after a partial
        // batch continues from that version instead of replaying the move.
        await _coordinator.runBots(
          maxActions: 60,
          afterCommittedAction: _persist,
        );
      } else {
        _coordinator.submitHuman(action!, expectedVersion: expectedVersion);
      }
      final reply = Map<String, Object?>.unmodifiable({
        ...view(),
        'request_id': requestId,
      });
      if (_replies.length >= 128) _replies.remove(_replies.keys.first);
      _replies[requestId] = (fingerprint, reply);
      _pending = null;
      // Save event + resulting reply in ONE encrypted atomic checkpoint.
      await _persist();
      return reply;
    } on GatewayFailure {
      rethrow;
    } on BenApiException {
      throw const GatewayFailure(503, 'upstream_unavailable');
    } on RuleViolation {
      // Invalid human action must not permanently wedge the session.
      if (!advanceBots && _coordinator.version == expectedVersion &&
          !_brokenStore) {
        _pending = null;
        await _persist();
      }
      throw const GatewayFailure(409, 'illegal_or_stale_action');
    } catch (_) {
      throw const GatewayFailure(503, 'upstream_unavailable');
    } finally {
      _busy = false;
    }
  }
}

class _PrivateBackendTransport implements BenTransport {
  const _PrivateBackendTransport(this.backend);
  final GatewayDecisionBackend backend;

  @override
  Future<Map<String, dynamic>> get(
      String route, Map<String, String> fields) async {
    final result = await backend.decide(route.substring(1), fields);
    return Map<String, dynamic>.from(result);
  }
}
