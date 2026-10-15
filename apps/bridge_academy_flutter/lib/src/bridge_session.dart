import 'package:bridge_ben_adapter/bridge_ben_adapter.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/foundation.dart';

enum OpponentMode { demo, ben }

/// Private in-process game controller for M2: clients only observe PlayerView.
///
/// Demo uses a fixed board/placeholder opponents. BEN uses real HTTP when
/// configured; it never silently falls back if the service is unavailable.
class BridgeSession extends ChangeNotifier {
  BridgeSession({
    Deal? fixedDeal,
    BotPolicy Function(OpponentMode mode)? botFactory,
  })  : _fixedDeal = fixedDeal ?? Deal.fromPbn(
          'N:AJ5.KQ7.A982.K76 32.9843.J73.Q943 '
          'QT6.AJ6.KT6.JT52 K9874.T52.Q54.A8',
        ),
        _botFactory = botFactory;

  final Deal _fixedDeal;
  final BotPolicy Function(OpponentMode mode)? _botFactory;
  SinglePlayerCoordinator? _coordinator;
  BenHttpTransport? _transport;

  bool _busy = false;
  String? _errorCode;
  OpponentMode _mode = OpponentMode.demo;
  Seat _humanSeat = Seat.north;

  bool get busy => _busy;
  String? get errorCode => _errorCode;
  bool get started => _coordinator != null;
  bool get finished => _coordinator?.finished ?? false;
  PlayerView? get view => _coordinator?.humanView;
  OpponentMode get mode => _mode;
  Seat get humanSeat => _humanSeat;

  BotPolicy _createBot(OpponentMode mode) {
    if (_botFactory != null) return _botFactory(mode);
    if (mode == OpponentMode.demo) {
      return const DeterministicTrainingBot();
    }
    // In a trusted development environment configure BEN_BASE_URL explicitly:
    // --dart-define=BEN_BASE_URL=http://127.0.0.1:8085
    // Android emulators require host networking such as 10.0.2.2. Never
    // expose an untrusted public BEN origin: GET carries the actor's hand.
    const origin = String.fromEnvironment(
      'BEN_BASE_URL',
      defaultValue: 'http://127.0.0.1:8085',
    );
    final transport = BenHttpTransport(baseUri: Uri.parse(origin));
    _transport = transport;
    return BenBotPolicy(transport);
  }

  Future<void> newGame({
    Seat humanSeat = Seat.north,
    OpponentMode mode = OpponentMode.demo,
  }) async {
    if (_busy) return;
    _transport?.close();
    _transport = null;
    _humanSeat = humanSeat;
    _mode = mode;
    _errorCode = null;
    _coordinator = SinglePlayerCoordinator(
      deal: _fixedDeal,
      dealer: Seat.north,
      vulnerability: Vulnerability.none,
      humanSeat: humanSeat,
      bot: _createBot(mode),
    );
    notifyListeners();
    await _advanceBots();
  }

  Future<void> submitCall(Call call) async {
    final view = this.view;
    if (_busy || view == null || view.phase != Phase.auction ||
        !view.canAct) {
      return;
    }
    await _submit(CallAction(view.viewer, call), view.version);
  }

  Future<void> submitCard(Card card) async {
    final view = this.view;
    if (_busy || view == null || view.phase != Phase.play ||
        !view.canAct || view.turn == null ||
        !view.legalCards.contains(card)) {
      return;
    }
    await _submit(CardAction(view.viewer, view.turn!, card), view.version);
  }

  Future<void> _submit(GameAction action, int expectedVersion) async {
    try {
      _coordinator!.submitHuman(action, expectedVersion: expectedVersion);
      _errorCode = null;
      notifyListeners();
    } on RuleViolation {
      _errorCode = 'errorInvalid';
      notifyListeners();
      return;
    }
    await _advanceBots();
  }

  Future<void> retryBots() => _advanceBots();

  Future<void> _advanceBots() async {
    if (_busy || _coordinator == null || _coordinator!.finished ||
        _coordinator!.humanView.canAct) {
      return;
    }
    _busy = true;
    _errorCode = null;
    notifyListeners();
    try {
      await _coordinator!.runBots(maxActions: 100);
    } catch (_) {
      // HTTP errors can contain credentials/private hands in upstream logs;
      // never show or log raw exception text on the player-facing UI.
      _errorCode = 'errorBot';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _transport?.close();
    super.dispose();
  }
}

