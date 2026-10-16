import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_copy.dart';
import 'bridge_session.dart';
import 'widgets/bridge_table_components.dart';
import 'widgets/bridge_bidding_box.dart';
import 'widgets/bridge_table_toolbar.dart';
import 'widgets/bridge_replay_panel.dart';
import 'widgets/bridge_history_panel.dart';
import 'session_persistence.dart';
import 'completed_history_store.dart';
import 'secure_session_persistence.dart';
import 'gateway_game_session.dart';
import 'gateway_http_api.dart';
import 'gateway_table.dart';

/// App composition: Flutter sees only PlayerView through BridgeSession.
class BridgeAcademyApp extends StatefulWidget {
  const BridgeAcademyApp({super.key, this.session, this.gatewayApi});
  final BridgeSession? session;
  /// Test-injected Gateway API; a configured origin is an explicit opt-in.
  final GatewayApi? gatewayApi;

  @override
  State<BridgeAcademyApp> createState() => _BridgeAcademyAppState();
}

class _BridgeAcademyAppState extends State<BridgeAcademyApp> {
  BridgeSession? _session;
  GatewayGameSession? _gateway;
  GatewayHttpApi? _ownedGatewayApi;
  bool _ownsSession = false;
  bool _gatewayConfigError = false;
  bool _isEnglish = false;

  @override
  void initState() {
    super.initState();
    if (widget.session != null) {
      _session = widget.session;
      return;
    }
    // Never silently fall back to Demo when a Gateway was configured.
    const gatewayOrigin = String.fromEnvironment('BRIDGE_GATEWAY_ORIGIN');
    if (widget.gatewayApi != null || gatewayOrigin.isNotEmpty) {
      try {
        final api = widget.gatewayApi ??
            (_ownedGatewayApi = GatewayHttpApi(
              origin: Uri.parse(gatewayOrigin),
            ));
        _gateway = GatewayGameSession(api);
      } catch (_) {
        _gatewayConfigError = true;
      }
      return;
    }

    _ownsSession = true;
    // Original encrypted local Demo / developer BEN behavior unchanged.
    final mobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    _session = BridgeSession(
      historyStore: mobile
          ? EncryptedCompletedHistoryStore.native()
          : kIsWeb
              ? EncryptedCompletedHistoryStore.browser()
              : MemoryCompletedHistoryStore(),
      archiveStore: mobile
          ? EncryptedTransactionalSessionArchiveStore.native()
          : kIsWeb
              ? EncryptedTransactionalSessionArchiveStore.browser()
              : PreferencesSessionArchiveStore(),
    );
    _session!.restoreSavedGame(); // Also loads the separate history archive.
  }

  @override
  void dispose() {
    if (_ownsSession) _session?.dispose();
    _gateway?.dispose();
    _ownedGatewayApi?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy(_isEnglish);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (_) => copy.t('title'),
      locale: _isEnglish ? const Locale('en') : const Locale('zh', 'TW'),
      supportedLocales: const [Locale('zh', 'TW'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0C746E),
        scaffoldBackgroundColor: const Color(0xFFF2F6F3),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(copy.t('title'), maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              key: const Key('toggle_locale'),
              tooltip: copy.t('language'),
              onPressed: () => setState(() => _isEnglish = !_isEnglish),
              icon: const Icon(Icons.language),
            ),
          ],
        ),
        body: _gatewayConfigError
            ? Center(child: Text(copy.t('gatewayInvalidConfig'),
                key: const Key('gateway_invalid_config')))
            : _gateway != null
                ? GatewayTable(session: _gateway!, copy: copy)
                : BridgeTable(session: _session!, copy: copy),
      ),
    );
  }
}

class BridgeTable extends StatefulWidget {
  const BridgeTable({super.key, required this.session, required this.copy});
  final BridgeSession session;
  final AppCopy copy;

  @override
  State<BridgeTable> createState() => _BridgeTableState();
}

class _BridgeTableState extends State<BridgeTable> {
  Seat _selectedSeat = Seat.north;
  OpponentMode _selectedMode = OpponentMode.demo;
  BoardMode _selectedBoard = BoardMode.training;
  int _bidLevel = 1;
  Strain _bidStrain = Strain.notrump;
  int? _replayIndex;
  bool _historyOpen = false;
  String? _selectedHistoryId;
  int _historyStep = 0;
  bool _syncedRestore = false;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_syncRestoredSelection);
    _syncRestoredSelection();
  }

  void _syncRestoredSelection() {
    if (_syncedRestore || !widget.session.restoredFromStorage) return;
    _syncedRestore = true;
    setState(() {
      _selectedSeat = widget.session.humanSeat;
      _selectedMode = widget.session.mode;
      _selectedBoard = widget.session.boardMode;
    });
  }

  @override
  void dispose() {
    widget.session.removeListener(_syncRestoredSelection);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = widget.copy;
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final session = widget.session;
        final view = session.view;
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) => Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _modeSelector(copy, constraints.maxWidth),
                    _seatSelector(copy, constraints.maxWidth),
                    _boardSelector(copy, constraints.maxWidth),
                    FilledButton.icon(
                      key: const Key('new_game'),
                      onPressed: session.busy
                          ? null
                          : () {
                              setState(() => _replayIndex = null);
                              session.newGame(
                                humanSeat: _selectedSeat,
                                mode: _selectedMode,
                                boardMode: _selectedBoard,
                              );
                            },
                      icon: const Icon(Icons.refresh),
                      label: Text(session.started
                          ? copy.t('restart')
                          : copy.t('newGame')),
                    ),
                    OutlinedButton.icon(
                      key: const Key('history_toggle'),
                      onPressed: () => setState(() {
                        _historyOpen = !_historyOpen;
                        if (!_historyOpen) _selectedHistoryId = null;
                      }),
                      icon: const Icon(Icons.history),
                      label: Text(copy.t(_historyOpen
                          ? 'historyClose' : 'historyOpen')),
                    ),
                  ],
                  ),
                ),
              ),
            ),
            if (_historyOpen) ...[
              const SizedBox(height: 8),
              BridgeHistoryPanel(
                history: session.completedHistory,
                copy: copy,
                selectedId: _selectedHistoryId,
                selectedReplay: _selectedHistoryId == null
                    ? null : session.historyReplay(_selectedHistoryId!),
                replayIndex: _historyStep,
                onSelect: (id) => setState(() {
                  _selectedHistoryId = id;
                  _historyStep = 0;
                }),
                onReplayStep: (step) =>
                    setState(() => _historyStep = step),
                canDelete: !session.busy,
                onDelete: (id) async {
                  final removed = await session.deleteHistory(id);
                  if (removed && mounted && _selectedHistoryId == id) {
                    setState(() {
                      _selectedHistoryId = null;
                      _historyStep = 0;
                    });
                  }
                },
                errorCode: session.historyError,
                onRetrySave: session.historySaveFailed
                    ? session.retryHistorySave : null,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              copy.t(session.mode == OpponentMode.demo
                  ? 'demoNotice'
                  : 'liveNotice'),
            ),
            if (kIsWeb)
              Text(
                copy.t('webCheckpointCaution'),
                key: const Key('web_checkpoint_caution'),
              ),
            if (session.restoring) ...[
              const LinearProgressIndicator(key: Key('restore_progress')),
              Text(copy.t('restoringGame')),
            ],
            if (view == null && session.errorCode != null)
              Text(copy.t(session.errorCode!),
                  key: const Key('error_message')),
            if (view == null) ...[
              const SizedBox(height: 24),
              Text(copy.t('notStarted'), key: const Key('empty_state')),
            ] else ...[
              const SizedBox(height: 12),
              BridgeBoardHeader(
                 boardNumber: session.board.number,
                 view: view,
                 busy: session.busy,
                 copy: copy,
               ),
              if (session.restoredFromStorage)
                Text(copy.t('restoredGame'),
                    key: const Key('restored_game')),
              if (session.recoveryNeedsConfirmation)
                Card(
                  key: const Key('recovery_warning'),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(copy.t('recoveredOlderCheckpoint')),
                        const SizedBox(height: 8),
                        FilledButton(
                          key: const Key('ack_recovered_checkpoint'),
                          onPressed: session.acknowledgeRecoveredCheckpoint,
                          child: Text(copy.t('ackRecoveredCheckpoint')),
                        ),
                      ],
                    ),
                  ),
                ),
              if (session.errorCode != null) ...[
                const SizedBox(height: 8),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 12,
                      children: [
                        Text(copy.t(session.errorCode!),
                            key: const Key('error_message')),
                        if (session.saveFailed && !session.busy)
                          TextButton(
                            key: const Key('retry_save'),
                            onPressed: session.retrySave,
                            child: Text(copy.t('retrySave')),
                          ),
                        if (!session.saveFailed && !session.busy &&
                            !view.canAct && !session.finished)
                          TextButton(
                            key: const Key('retry_bot'),
                            onPressed: session.retryBots,
                            child: Text(copy.t('retry')),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (session.busy) ...[
                const LinearProgressIndicator(key: Key('bot_progress')),
                const SizedBox(height: 8),
                Text(copy.t('waitingBot')),
              ],
              const SizedBox(height: 12),
              BridgeTableSurface(
                 view: view,
                 copy: copy,
                 actionsPaused: session.actionsPaused,
                 onPlayCard: session.submitCard,
               ),
              const SizedBox(height: 8),
              BridgeTableToolbar(view: view, copy: copy),
              const SizedBox(height: 8),
              if (!session.finished)
                _humanControls(view, session, copy)
              else ...[
                _finishCard(view, copy),
                const SizedBox(height: 8),
                _completedBoardActions(session, copy),
                const SizedBox(height: 8),
                if (!_historyOpen) _replayPanel(session, copy),
              ],
            ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _modeSelector(AppCopy copy, double availableWidth) => SizedBox(
        width: availableWidth < 320 ? availableWidth : 320,
        child: DropdownButtonFormField<OpponentMode>(
          key: const Key('mode_selector'),
          isExpanded: true,
          initialValue: _selectedMode,
          decoration: InputDecoration(labelText: copy.t('mode')),
          items: [
            for (final mode in OpponentMode.values)
              DropdownMenuItem(
                value: mode,
                child: Text(copy.t(mode == OpponentMode.demo ? 'demo' : 'live'),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 13)),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _selectedMode = value);
          },
        ),
      );

  Widget _seatSelector(AppCopy copy, double availableWidth) => SizedBox(
        width: availableWidth < 185 ? availableWidth : 185,
        child: DropdownButtonFormField<Seat>(
          key: const Key('seat_selector'),
          isExpanded: true,
          initialValue: _selectedSeat,
          decoration: InputDecoration(labelText: copy.t('humanSeat')),
          items: [
            for (final seat in Seat.values)
              DropdownMenuItem(
                value: seat,
                child: Text(copy.seat(seat.letter),
                    overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _selectedSeat = value);
          },
        ),
      );

  Widget _boardSelector(AppCopy copy, double availableWidth) => SizedBox(
        width: availableWidth < 225 ? availableWidth : 225,
        child: DropdownButtonFormField<BoardMode>(
          key: const Key('board_mode_selector'),
          isExpanded: true,
          initialValue: _selectedBoard,
          decoration: InputDecoration(labelText: copy.t('boardMode')),
          items: [
            for (final board in BoardMode.values)
              DropdownMenuItem(
                value: board,
                child: Text(
                  copy.t(board == BoardMode.training
                      ? 'trainingBoard' : 'freshBoard'),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _selectedBoard = value);
          },
        ),
      );

  Widget _completedBoardActions(BridgeSession session, AppCopy copy) =>
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            key: const Key('replay_same_board'),
            onPressed: session.busy ? null : () {
              setState(() => _replayIndex = null);
              session.replaySameBoard();
            },
            icon: const Icon(Icons.replay),
            label: Text(copy.t('replaySameBoard')),
          ),
          FilledButton.icon(
            key: const Key('next_board'),
            onPressed: session.busy ? null : () {
              setState(() => _replayIndex = null);
              session.nextBoard();
            },
            icon: const Icon(Icons.skip_next),
            label: Text(copy.t('nextBoard')),
          ),
        ],
      );

  Widget _humanControls(PlayerView view, BridgeSession session, AppCopy copy) {
    if (view.phase == Phase.auction) {
      return BridgeBiddingBox(
        copy: copy,
        selectedLevel: _bidLevel,
        selectedStrain: _bidStrain,
        canSubmit: view.canAct && !session.actionsPaused,
        onLevelChanged: (level) => setState(() => _bidLevel = level),
        onStrainChanged: (strain) => setState(() => _bidStrain = strain),
        onSubmitCall: session.submitCall,
      );
    }
    if (view.phase == Phase.play) {
      return BridgePlayerHand(
        view: view,
        copy: copy,
        actionsPaused: session.actionsPaused,
        onPlayCard: session.submitCard,
      );
    }
    return const SizedBox.shrink();
  }

  /// Finished history stays immutable. Only the selected frame index is local.
  Widget _replayPanel(BridgeSession session, AppCopy copy) {
    final replay = session.completedReplay;
    if (replay == null) return const SizedBox.shrink();
    final index = (_replayIndex ?? replay.lastIndex).clamp(0, replay.lastIndex);
    return BridgeCompletedReplayPanel(
      replay: replay,
      index: index,
      copy: copy,
      onSelectIndex: (value) => setState(() => _replayIndex = value),
    );
  }

  Widget _finishCard(PlayerView view, AppCopy copy) => Card(
        key: const Key('final_result'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(copy.t('end'), style: Theme.of(context).textTheme.titleLarge),
              if (view.contract == null) Text(copy.t('passOut')),
              if (view.contract != null)
                Text(copy.contract(view.contract!.label)),
              if (view.nsScore != null) Text(copy.score(view.nsScore!)),
            ],
          ),
        ),
      );

}
