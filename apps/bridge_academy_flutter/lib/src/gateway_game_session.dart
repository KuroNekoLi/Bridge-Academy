import 'dart:math';

import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/foundation.dart';

import 'gateway_http_api.dart';

/// A4.4 browser/session-facing authoritative client. Its only state source
/// is Gateway PlayerView. Never uses a local Deal, Demo fallback or BEN GET.
class GatewayGameSession extends ChangeNotifier {
  GatewayGameSession(this._api, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final GatewayApi _api;
  final DateTime Function() _clock;
  final Random _ids = Random.secure();
  String? _bearer;
  DateTime? _expires;
  PlayerView? _view;
  _Pending? _pending;
  bool _busy = false;
  String? _error;
  int _counter = 0;

  bool get busy => _busy;
  PlayerView? get view => _view;
  String? get errorCode => _error;
  bool get started => _view != null;
  bool get finished => _view?.phase == Phase.finished;
  bool get hasPending => _pending != null;
  bool get actionsPaused => _busy || _error != null || _pending != null;

  String _id() {
    // Unpredictable per-process prefix plus sequential suffix. A retry must
    // keep the exact ID; a new user action gets a fresh one.
    final bytes = List<int>.generate(16, (_) => _ids.nextInt(256));
    return 'a4_${bytes.map((n) => n.toRadixString(16).padLeft(2, '0')).join()}_${_counter++}';
  }

  bool get _expired => _bearer == null || _expires == null ||
      !_expires!.isAfter(_clock().toUtc());

  void _readView(Map<String, dynamic> envelope) {
    if (envelope['version'] != 1 ||
        envelope['view'] is! Map<String, dynamic> ||
        envelope.keys.toSet().difference(
          const {'version', 'view', 'request_id'},
        ).isNotEmpty) {
      throw const FormatException('Unexpected Gateway envelope');
    }
    final candidate =
        PlayerView.fromJson(envelope['view'] as Map<String, dynamic>);
    if (candidate.viewer != Seat.north) {
      throw const FormatException('Unsupported server seat');
    }
    _view = candidate;
  }

  String _mapError(Object e) {
    if (e is GatewayHttpError) {
      if (e.status == 401) return 'gatewayExpired';
      if (e.status == 409) return 'gatewayConflict';
      if (e.status == 429) return 'gatewayRateLimited';
      if (e.status == 503 || e.status == 504 || e.status == 502) {
        return 'gatewayUnavailable';
      }
      if (e.status == 0) return 'gatewayOffline';
    }
    return 'gatewayInvalidResponse';
  }

  /// Intentionally no silent auto-bootstrap: the user must start a NEW deal.
  /// Expired credentials cannot be resurrected by retrying a stale action.
  Future<void> startNewGame() async {
    if (_busy) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final issued = await _api.post(
          '/v1/sessions/anonymous', {'version': 1});
      final token = issued['access_token'];
      final ttl = issued['expires_in'];
      if (issued['version'] != 1 ||
          issued['token_type'] != 'Bearer' ||
          issued['scope'] != 'ai:decision' ||
          token is! String ||
          !RegExp(r'^[A-Za-z0-9_-]{40,128}$').hasMatch(token) ||
          ttl is! int || ttl < 1 || ttl > 86400) {
        throw const FormatException('Invalid session capability');
      }
      final response = await _api.post(
        '/v1/games/view', {'version': 1}, bearer: token);
      // Must validate filtered server view BEFORE displaying any state.
      final old = _view;
      _readView(response);
      if (_view!.version != 0) {
        _view = old;
        throw const FormatException('New session did not start at version 0');
      }
      _bearer = token; // Memory-only, never saved to SharedPreferences.
      _expires = _clock().toUtc().add(Duration(seconds: ttl));
      _pending = null;
    } catch (e) {
      _error = _mapError(e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> submitCall(Call call) async {
    final current = _view;
    if (actionsPaused || current == null ||
        current.phase != Phase.auction || !current.canAct) return;
    await _execute('/v1/games/action', {
      'version': 1,
      'expected_version': current.version,
      'request_id': _id(),
      'action': {'kind': 'bid', 'call': call.code},
    });
    if (_error == null) await _advanceIfNeeded();
  }

  Future<void> submitCard(Card card) async {
    final current = _view;
    if (actionsPaused || current == null || current.phase != Phase.play ||
        !current.canAct || !current.legalCards.contains(card)) return;
    await _execute('/v1/games/action', {
      'version': 1,
      'expected_version': current.version,
      'request_id': _id(),
      'action': {'kind': 'play', 'card': card.code},
    });
    if (_error == null) await _advanceIfNeeded();
  }

  Future<void> _advanceIfNeeded() async {
    final current = _view;
    if (current == null || current.phase == Phase.finished ||
        current.canAct || _pending != null || _error != null) return;
    await _execute('/v1/games/advance', {
      'version': 1,
      'expected_version': current.version,
      'request_id': _id(),
    });
  }

  Future<void> _execute(String route, Map<String, Object?> payload) async {
    if (_busy || _expired) {
      _error = 'gatewayExpired';
      notifyListeners();
      return;
    }
    final pending = _Pending(route, Map.unmodifiable(payload));
    _pending = pending;
    await _sendPending(pending);
  }

  Future<void> _sendPending(_Pending current) async {
    if (_busy) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.post(
        current.route, current.body, bearer: _bearer);
      if (result['request_id'] != current.body['request_id']) {
        throw const FormatException('Request identity mismatch');
      }
      _readView(result);
      _pending = null;
    } catch (e) {
      // Preserve same request_id + expected_version for explicit replay.
      // Unknown HTTP commit outcome must never generate a new action ID.
      _error = _mapError(e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Manual recovery first reads server truth; it does NOT auto-replay.
  /// The pending ID remains available for the user-controlled retry.
  Future<void> refreshServerView() async {
    if (_busy || _bearer == null) return;
    if (_expired) {
      _error = 'gatewayExpired';
      notifyListeners();
      return;
    }
    _busy = true;
    notifyListeners();
    try {
      final response = await _api.post(
          '/v1/games/view', {'version': 1}, bearer: _bearer);
      _readView(response);
      _error = _pending == null ? null : 'gatewayRetryPending';
    } catch (e) {
      _error = _mapError(e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> retry() async {
    if (_busy || _expired) {
      _error = 'gatewayExpired';
      notifyListeners();
      return;
    }
    final pending = _pending;
    if (pending != null) {
      await _sendPending(pending);
      if (_error == null) await _advanceIfNeeded();
    } else {
      _error = null;
      await _advanceIfNeeded();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Do not print, persist or expose credentials; explicit in-memory expiry.
    _bearer = null;
    super.dispose();
  }
}

class _Pending {
  const _Pending(this.route, this.body);
  final String route;
  final Map<String, Object?> body;
}
