import 'package:bridge_ben_adapter/bridge_ben_adapter.dart';
import 'package:bridge_core/bridge_core.dart';

import 'gateway_service.dart';

/// Each anonymous bearer owns one server-generated training deal.
/// An HTTP caller cannot obtain all hands or request an arbitrary seat view.
class AuthoritativeGame {
  AuthoritativeGame({
    required Deal deal,
    required GatewayDecisionBackend backend,
  }) : _coordinator = SinglePlayerCoordinator(
          deal: deal,
          dealer: Seat.north,
          vulnerability: Vulnerability.none,
          humanSeat: Seat.north,
          bot: BenBotPolicy(_PrivateBackendTransport(backend)),
        );

  final SinglePlayerCoordinator _coordinator;
  final Map<String, (String, Map<String, Object?>)> _replies = {};
  bool _busy = false;

  Map<String, Object?> view() => {
        'version': 1,
        'view': _coordinator.humanView.toJson(),
      };

  Future<Map<String, Object?>> execute(
    Map<String, dynamic> body, {
    required bool advanceBots,
  }) async {
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
    final previous = _replies[requestId];
    if (previous != null) {
      if (previous.$1 != fingerprint) {
        throw const GatewayFailure(409, 'request_id_conflict');
      }
      return previous.$2;
    }
    if (_busy) throw const GatewayFailure(409, 'game_busy');
    if (expectedVersion != _coordinator.version) {
      throw const GatewayFailure(409, 'stale_version');
    }

    _busy = true;
    try {
      if (advanceBots) {
        // BenBotPolicy sees a privacy-filtered PlayerView constructed here,
        // NOT any client-supplied hand or seat.
        await _coordinator.runBots(maxActions: 60);
      } else {
        _coordinator.submitHuman(action!, expectedVersion: expectedVersion);
      }
      final reply = Map<String, Object?>.unmodifiable({
        ...view(),
        'request_id': requestId,
      });
      // Volatile/bounded dedup; NOT durable exactly-once across restarts.
      if (_replies.length >= 128) _replies.remove(_replies.keys.first);
      _replies[requestId] = (fingerprint, reply);
      return reply;
    } on GatewayFailure {
      rethrow;
    } on BenApiException {
      throw const GatewayFailure(503, 'upstream_unavailable');
    } on RuleViolation {
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
