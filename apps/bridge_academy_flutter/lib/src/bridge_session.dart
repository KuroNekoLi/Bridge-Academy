import 'package:bridge_ben_adapter/bridge_ben_adapter.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/foundation.dart';

import 'session_persistence.dart';

enum OpponentMode { demo, ben }
enum BoardMode { training, fresh }

/// Private in-process game controller for M2: clients only observe PlayerView.
///
/// Demo uses a fixed board/placeholder opponents. BEN uses real HTTP when
/// configured; it never silently falls back if the service is unavailable.
class BridgeSession extends ChangeNotifier {
  BridgeSession({
    Deal? fixedDeal,
    BotPolicy Function(OpponentMode mode)? botFactory,
    Deal Function()? freshDealFactory,
    SessionArchiveStore? archiveStore,
  })  : _fixedDeal = fixedDeal ?? Deal.fromPbn(
          'N:AJ5.KQ7.A982.K76 32.9843.J73.Q943 '
          'QT6.AJ6.KT6.JT52 K9874.T52.Q54.A8',
        ),
        _botFactory = botFactory,
        _freshDealFactory = freshDealFactory,
        _archiveStore = archiveStore;

  final Deal _fixedDeal;
  final BotPolicy Function(OpponentMode mode)? _botFactory;
  final Deal Function()? _freshDealFactory;
  final SessionArchiveStore? _archiveStore;
  SinglePlayerCoordinator? _coordinator;
  Deal? _activeDeal;
  BoardDefinition _board = BoardDefinition.forNumber(1);
  BenHttpTransport? _transport;

  bool _busy = false;
  bool _saving = false;
  bool _restoring = false;
  bool _saveFailed = false;
  bool _restoredFromStorage = false;
  bool _recoveryNeedsConfirmation = false;
  String? _errorCode;
  OpponentMode _mode = OpponentMode.demo;
  BoardMode _boardMode = BoardMode.training;
  Seat _humanSeat = Seat.north;

  bool get busy => _busy || _saving || _restoring;
  bool get recoveryNeedsConfirmation => _recoveryNeedsConfirmation;
  bool get actionsPaused => busy || _recoveryNeedsConfirmation;
  bool get restoring => _restoring;
  bool get saveFailed => _saveFailed;
  bool get restoredFromStorage => _restoredFromStorage;
  String? get errorCode => _errorCode;
  bool get started => _coordinator != null;
  bool get finished => _coordinator?.finished ?? false;
  PlayerView? get view => _coordinator?.humanView;
  CompletedReplay? get completedReplay => _coordinator?.completedReplay;
  OpponentMode get mode => _mode;
  BoardMode get boardMode => _boardMode;
  Seat get humanSeat => _humanSeat;
  BoardDefinition get board => _board;

  /// Rebuilds only a committed event sequence, never an in-flight AI proposal.
  /// A restored bot turn is retried from its last committed version.
  Future<bool> restoreSavedGame() async {
    if (_archiveStore == null || busy || started) return false;
    _restoring = true;
    notifyListeners();
    var restored = false;
    var advanceBot = false;
    try {
      final raw = await _archiveStore.read();
      if (raw == null) return false;
      final snapshot = SavedBoardCodec.decode(raw);
      final recoveredBackup = _archiveStore is RecoveryAwareSessionArchiveStore &&
          (_archiveStore as RecoveryAwareSessionArchiveStore)
              .recoveredOlderCheckpoint;
      final mode = OpponentMode.values.byName(snapshot.opponentMode);
      final boardMode = BoardMode.values.byName(snapshot.boardMode);
      final bot = _createBot(mode);
      final coordinator = SinglePlayerCoordinator.restore(
        trustedStorageArchive: snapshot.transcript,
        humanSeat: snapshot.humanSeat, bot: bot,
      );
      _coordinator = coordinator;
      _activeDeal = snapshot.state.deal;
      _board = snapshot.board;
      _humanSeat = snapshot.humanSeat;
      _mode = mode;
      _boardMode = boardMode;
      _errorCode = null;
      _restoredFromStorage = true;
      _recoveryNeedsConfirmation = recoveredBackup;
      restored = true;
      advanceBot = !recoveredBackup && !coordinator.finished &&
          !coordinator.humanView.canAct;
    } on FormatException {
      _errorCode = 'errorCorruptSave';
    } on RuleViolation {
      _errorCode = 'errorCorruptSave';
    } on TypeError {
      _errorCode = 'errorCorruptSave';
    } on RangeError {
      _errorCode = 'errorCorruptSave';
    } catch (_) {
      _errorCode = 'errorStorage';
    } finally {
      _restoring = false;
      notifyListeners();
    }
    if (advanceBot) await _advanceBots();
    return restored;
  }

  /// Explicit player confirmation required after losing a committed slot.
  Future<void> acknowledgeRecoveredCheckpoint() async {
    if (!_recoveryNeedsConfirmation || busy) return;
    _recoveryNeedsConfirmation = false;
    notifyListeners();
    await _advanceBots();
  }

  Future<void> _persist() async {
    if (_archiveStore == null || _coordinator == null) return;
    try {
      await _archiveStore.write(SavedBoardCodec.encode(
        board: _board, humanSeat: _humanSeat,
        opponentMode: _mode.name, boardMode: _boardMode.name,
        coordinator: _coordinator!,
      ));
      _saveFailed = false;
    } catch (_) {
      _saveFailed = true;
      rethrow;
    }
  }

  /// Retry a failed local write before allowing any more cards or bot calls.
  Future<void> retrySave() async {
    if (!_saveFailed || busy) return;
    _saving = true;
    notifyListeners();
    var successful = false;
    try {
      await _persist();
      _errorCode = null;
      successful = true;
    } catch (_) {
      _errorCode = 'errorSave';
    } finally {
      _saving = false;
      notifyListeners();
    }
    if (successful) await _advanceBots();
  }

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

  /// Create/redeal the specified board. Defaults to the current board number
  /// (Board 1 before the first game). A fresh deal gets newly shuffled cards.
  Future<void> newGame({
    Seat humanSeat = Seat.north,
    OpponentMode mode = OpponentMode.demo,
    BoardMode boardMode = BoardMode.training,
    int? boardNumber,
  }) async {
    if (busy) return;
    final board = BoardDefinition.forNumber(boardNumber ?? _board.number);
    final deal = boardMode == BoardMode.training
        ? _fixedDeal
        : (_freshDealFactory?.call() ?? Deal.shuffled());
    await _beginBoard(
      board: board, deal: deal, humanSeat: humanSeat,
      mode: mode, boardMode: boardMode,
    );
  }

  /// Practice the identical 52 cards and board conditions, without creating
  /// a new result. The current finished replay is replaced on restart.
  Future<void> replaySameBoard() async {
    final deal = _activeDeal;
    if (busy || deal == null || !finished) return;
    await _beginBoard(
      board: _board, deal: deal, humanSeat: _humanSeat,
      mode: _mode, boardMode: _boardMode,
    );
  }

  /// Only a finished board advances the sequential Duplicate board number.
  /// The player can still restart an unfinished board with newGame().
  Future<void> nextBoard() async {
    if (busy || !finished) return;
    await newGame(
      humanSeat: _humanSeat,
      mode: _mode,
      boardMode: _boardMode,
      boardNumber: _board.number + 1,
    );
  }

  Future<void> _beginBoard({
    required BoardDefinition board,
    required Deal deal,
    required Seat humanSeat,
    required OpponentMode mode,
    required BoardMode boardMode,
  }) async {
    _transport?.close();
    _transport = null;
    _humanSeat = humanSeat;
    _mode = mode;
    _boardMode = boardMode;
    _board = board;
    _activeDeal = deal;
    _errorCode = null;
    _saveFailed = false;
    _restoredFromStorage = false;
    _recoveryNeedsConfirmation = false;
    _coordinator = SinglePlayerCoordinator(
      deal: deal,
      dealer: board.dealer,
      vulnerability: board.vulnerability,
      humanSeat: humanSeat,
      bot: _createBot(mode),
    );
    _saving = true;
    notifyListeners();
    var persisted = false;
    try {
      await _persist(); // Commit board before any first automated call.
      persisted = true;
    } catch (_) {
      _errorCode = 'errorSave';
    } finally {
      _saving = false;
      notifyListeners();
    }
    if (persisted) await _advanceBots();
  }

  Future<void> submitCall(Call call) async {
    final view = this.view;
    if (actionsPaused || _saveFailed || view == null || view.phase != Phase.auction ||
        !view.canAct) {
      return;
    }
    await _submit(CallAction(view.viewer, call), view.version);
  }

  Future<void> submitCard(Card card) async {
    final view = this.view;
    if (actionsPaused || _saveFailed || view == null || view.phase != Phase.play ||
        !view.canAct || view.turn == null ||
        !view.legalCards.contains(card)) {
      return;
    }
    await _submit(CardAction(view.viewer, view.turn!, card), view.version);
  }

  Future<void> _submit(GameAction action, int expectedVersion) async {
    if (actionsPaused || _saveFailed) return;
    _saving = true;
    notifyListeners();
    var persisted = false;
    try {
      _coordinator!.submitHuman(action, expectedVersion: expectedVersion);
      await _persist(); // Durable-intent checkpoint precedes any bot turn.
      _errorCode = null;
      persisted = true;
    } on RuleViolation {
      _errorCode = 'errorInvalid';
    } catch (_) {
      _errorCode = 'errorSave';
    } finally {
      _saving = false;
      notifyListeners();
    }
    if (persisted) await _advanceBots();
  }

  Future<void> retryBots() => _advanceBots();

  Future<void> _advanceBots() async {
    if (actionsPaused || _saveFailed || _coordinator == null ||
        _coordinator!.finished ||
        _coordinator!.humanView.canAct) {
      return;
    }
    _busy = true;
    _errorCode = null;
    notifyListeners();
    try {
      await _coordinator!.runBots(
        maxActions: 100,
        afterCommittedAction: _archiveStore == null ? null : _persist,
      );
    } catch (_) {
      // HTTP errors can contain credentials/private hands in upstream logs;
      // never show or log raw exception text on the player-facing UI.
      _errorCode = _saveFailed ? 'errorSave' : 'errorBot';
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

