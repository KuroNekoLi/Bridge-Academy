import 'dart:math';

import 'package:bridge_ben_adapter/bridge_ben_adapter.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/foundation.dart';

import 'session_persistence.dart';
import 'completed_history_store.dart';
import 'completed_pbn_export.dart';
import 'completed_pbn_import.dart';

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
    CompletedHistoryStore? historyStore,
  })  : _fixedDeal = fixedDeal ?? Deal.fromPbn(
          'N:AJ5.KQ7.A982.K76 32.9843.J73.Q943 '
          'QT6.AJ6.KT6.JT52 K9874.T52.Q54.A8',
        ),
        _botFactory = botFactory,
        _freshDealFactory = freshDealFactory,
        _archiveStore = archiveStore,
        _historyStore = historyStore;

  final Deal _fixedDeal;
  final BotPolicy Function(OpponentMode mode)? _botFactory;
  final Deal Function()? _freshDealFactory;
  final SessionArchiveStore? _archiveStore;
  final CompletedHistoryStore? _historyStore;
  String? _historyId;
  List<StoredHistoryBoard> _historyBoards = [];
  List<HistorySummary> _historySummaries = [];
  Future<void>? _historyLoadFuture;
  bool _historyLoaded = false;
  bool _historySaveFailed = false;
  bool _historyDeleting = false;
  String? _historyError;
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
  List<HistorySummary> get completedHistory => List.unmodifiable(_historySummaries);
  String? get historyError => _historyError;
  bool get historySaveFailed => _historySaveFailed;

  static String _newHistoryId() {
    final random = Random.secure().nextInt(0x7fffffff).toRadixString(16);
    return 'h_${DateTime.now().microsecondsSinceEpoch}_$random';
  }

  HistorySummary _summarize(StoredHistoryBoard record) {
    final saved = SavedBoardCodec.decode(record.archive);
    final game = saved.state;
    if (!game.isFinished) throw const FormatException('Unfinished history');
    return HistorySummary(
      id: record.id, savedAt: record.savedAt,
      boardNumber: saved.board.number, humanSeat: saved.humanSeat,
      contract: game.contract?.label ?? 'PASS OUT',
      score: game.nsScore!, tricks: game.tricks.length,
      isPractice: saved.boardMode == BoardMode.training.name,
    );
  }

  Future<void> loadHistory() {
    if (_historyLoaded || _historyStore == null) return Future.value();
    return _historyLoadFuture ??=
        _readHistory().whenComplete(() => _historyLoadFuture = null);
  }

  Future<void> _readHistory() async {
    try {
      final records = await _historyStore!.read();
      final summaries = records.map(_summarize).toList();
      _historyBoards = List.of(records);
      _historySummaries = summaries;
      _historyLoaded = true;
      _historyError = null;
    } catch (_) {
      // The private archive, corrupted ciphertext and original hands are
      // never echoed to a player. Existing in-memory history is preserved.
      _historyError = 'errorHistoryLoad';
    }
    notifyListeners();
  }

  CompletedReplay? historyReplay(String id) {
    final matches = _historyBoards.where((entry) => entry.id == id);
    if (matches.isEmpty) return null;
    final saved = SavedBoardCodec.decode(matches.first.archive);
    if (!saved.state.isFinished) return null;
    // Only filtered ReplayFrames leave the trusted storage boundary.
    return SinglePlayerCoordinator.restore(
      trustedStorageArchive: saved.transcript,
      humanSeat: saved.humanSeat,
      bot: const DeterministicTrainingBot(),
    ).completedReplay;
  }

  /// PBN is privileged: it contains the original 52-card Deal. Call ONLY
  /// after a user-confirmed export of a FINISHED stored game. Never expose
  /// this data in summaries, active PlayerView, analytics or AI requests.
  String? exportHistoryPbn(String id) {
    final matching = _historyBoards.where((entry) => entry.id == id);
    if (matching.isEmpty) return null;
    final saved = SavedBoardCodec.decode(matching.first.archive);
    if (!saved.state.isFinished) return null;
    return CompletedPbnExport.encode(saved);
  }

  /// Import an externally pasted *completed* first-party PBN into the
  /// encrypted local history. This never starts a new live game, never calls
  /// BEN, and never replaces the active checkpoint or exposes the Deal to UI.
  Future<bool> importHistoryPbn(String pbn) async {
    if (_historyStore == null || busy || _historyDeleting) return false;
    await loadHistory();
    if (!_historyLoaded) {
      _historyError = 'errorHistoryLoad';
      notifyListeners();
      return false;
    }
    _historyDeleting = true; // Serialize local history writes and deletes.
    try {
      final id = _newHistoryId();
      final archive = CompletedPbnImport.toLocalArchive(
        pbn, historyId: id,
      );
      final imported = SavedBoardCodec.decode(archive);
      // One logical completed transcript must not be counted twice because
      // it was pasted again (even after an app restart).
      if (_historyBoards.any((item) {
        final existing = SavedBoardCodec.decode(item.archive);
        return existing.board.number == imported.board.number &&
            existing.state.historyFingerprint ==
                imported.state.historyFingerprint;
      })) {
        _historyError = 'errorHistoryDuplicate';
        notifyListeners();
        return false;
      }
      final record = StoredHistoryBoard(
        id: id, savedAt: DateTime.now().toUtc(), archive: archive,
      );
      final proposed = [record, ..._historyBoards]
          .take(EncryptedCompletedHistoryStore.maxItems)
          .toList();
      await _historyStore.write(proposed);
      _historyBoards = proposed;
      _historySummaries = proposed.map(_summarize).toList();
      _historyError = null;
      notifyListeners();
      return true;
    } catch (_) {
      // Syntax, legality, score, crypto and persistence errors never echo
      // the untrusted PBN or the four secret hands.
      _historyError = 'errorHistoryImport';
      notifyListeners();
      return false;
    } finally {
      _historyDeleting = false;
    }
  }

  /// Deletes exactly one finished attempt, without clearing the active game.
  /// The encrypted store persists a deletion marker before the UI changes.
  Future<bool> deleteHistory(String id) async {
    if (_historyStore == null || busy || _historyDeleting) return false;
    await loadHistory();
    if (!_historyLoaded || !_historyBoards.any((item) => item.id == id)) {
      return false;
    }
    _historyDeleting = true;
    try {
      await _historyStore.delete(id);
      _historyBoards = _historyBoards.where((item) => item.id != id).toList();
      _historySummaries =
          _historySummaries.where((item) => item.id != id).toList();
      _historyError = null;
      notifyListeners();
      return true;
    } catch (_) {
      _historyError = 'errorHistoryDelete';
      notifyListeners();
      return false;
    } finally {
      _historyDeleting = false;
    }
  }

  Future<void> _archiveCompleted() async {
    if (_historyStore == null || _coordinator?.finished != true) {
      return;
    }
    await loadHistory();
    if (!_historyLoaded) {
      _historyError = 'errorHistoryLoad';
      notifyListeners();
      return;
    }
    final id = _historyId ??= _newHistoryId();
    if (_historyBoards.any((item) => item.id == id)) return;
    // A restored terminal checkpoint must not recreate a user-deleted board.
    try {
      if (await _historyStore.isDeleted(id)) return;
    } catch (_) {
      _historyError = 'errorHistoryLoad';
      notifyListeners();
      return;
    }
    final item = StoredHistoryBoard(
      id: id,
      savedAt: DateTime.now().toUtc(),
      archive: SavedBoardCodec.encode(
        board: _board, humanSeat: _humanSeat,
        opponentMode: _mode.name, boardMode: _boardMode.name,
        coordinator: _coordinator!, historyId: id,
      ),
    );
    final proposed = [item, ..._historyBoards].take(
      EncryptedCompletedHistoryStore.maxItems,
    ).toList();
    try {
      await _historyStore.write(proposed);
      _historyBoards = proposed;
      _historySummaries = proposed.map(_summarize).toList();
      _historyError = null;
      _historySaveFailed = false;
    } catch (_) {
      // Active-session checkpoint remains safe and playable even when the
      // secondary history archive fails; offer a separate explicit retry.
      _historySaveFailed = true;
      _historyError = 'errorHistorySave';
    }
    notifyListeners();
  }

  Future<void> retryHistorySave() => _archiveCompleted();

  /// Rebuilds only a committed event sequence, never an in-flight AI proposal.
  /// A restored bot turn is retried from its last committed version.
  Future<bool> restoreSavedGame() async {
    if (_archiveStore == null || busy || started) return false;
    await loadHistory();
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
      _historyId = snapshot.historyId ??
          'legacy_${snapshot.state.historyFingerprint}';
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
    if (restored && finished) await _archiveCompleted();
    return restored;
  }

  /// Explicit player confirmation required after losing a committed slot.
  Future<void> acknowledgeRecoveredCheckpoint() async {
    if (!_recoveryNeedsConfirmation || busy) return;
    _saving = true;
    notifyListeners();
    var accepted = false;
    try {
      if (_archiveStore case RecoveryAwareSessionArchiveStore recoveryStore) {
        await recoveryStore.acknowledgeRecoveredCheckpoint();
      }
      _recoveryNeedsConfirmation = false;
      _errorCode = null;
      accepted = true;
    } catch (_) {
      // Keep the warning and do not wake the Bot if saving consent fails.
      _errorCode = 'errorSave';
    } finally {
      _saving = false;
      notifyListeners();
    }
    if (accepted) await _advanceBots();
  }

  Future<void> _persist() async {
    if (_archiveStore == null || _coordinator == null) return;
    try {
      await _archiveStore.write(SavedBoardCodec.encode(
        board: _board, humanSeat: _humanSeat,
        opponentMode: _mode.name, boardMode: _boardMode.name,
        coordinator: _coordinator!, historyId: _historyId,
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
    _historyId = _newHistoryId();
    _historySaveFailed = false;
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
    if (persisted && finished) await _archiveCompleted();
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
      if (finished) await _archiveCompleted();
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

