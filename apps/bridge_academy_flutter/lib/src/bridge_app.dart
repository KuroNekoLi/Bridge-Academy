import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_copy.dart';
import 'bridge_session.dart';
import 'widgets/bridge_table_components.dart';
import 'widgets/bridge_bidding_box.dart';
import 'session_persistence.dart';
import 'secure_session_persistence.dart';

/// App composition: Flutter sees only PlayerView through BridgeSession.
class BridgeAcademyApp extends StatefulWidget {
  const BridgeAcademyApp({super.key, this.session});
  final BridgeSession? session;

  @override
  State<BridgeAcademyApp> createState() => _BridgeAcademyAppState();
}

class _BridgeAcademyAppState extends State<BridgeAcademyApp> {
  late final BridgeSession _session;
  late final bool _ownsSession;
  bool _isEnglish = false;

  @override
  void initState() {
    super.initState();
    _ownsSession = widget.session == null;
    // Native mobile uses AES-GCM + transactional SQLite with a secure key.
    // Web checkpoints are AES-GCM encrypted with a browser WebCrypto key.
    // Browser single-key storage remains best effort (not SQLite or XSS-safe).
    // Missing secure context/key must fail closed, never downgrade to plaintext.
    final mobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    _session = widget.session ?? BridgeSession(
      archiveStore: mobile
          ? EncryptedTransactionalSessionArchiveStore.native()
          : kIsWeb
              ? EncryptedTransactionalSessionArchiveStore.browser()
              : PreferencesSessionArchiveStore(),
    );
    if (_ownsSession) {
      // The session notifies BridgeTable when the saved game is loaded.
      _session.restoreSavedGame();
    }
  }

  @override
  void dispose() {
    if (_ownsSession) _session.dispose();
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
        body: BridgeTable(session: _session, copy: copy),
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
                  ],
                  ),
                ),
              ),
            ),
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
              _auctionHistory(view, copy),
              const SizedBox(height: 8),
              if (!session.finished)
                _humanControls(view, session, copy)
              else ...[
                _finishCard(view, copy),
                const SizedBox(height: 8),
                _completedBoardActions(session, copy),
                const SizedBox(height: 8),
                _replayPanel(session, copy),
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

  Widget _auctionHistory(PlayerView view, AppCopy copy) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(copy.t('auction')),
              Wrap(
                spacing: 6,
                children: [
                  for (final entry in view.auction)
                    Chip(label: Text('${entry.seat.letter}: ${entry.call.code}')),
                ],
              ),
            ],
          ),
        ),
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

  /// Replay uses read-only PlayerView snapshots, never the live action UI.
  Widget _replayPanel(BridgeSession session, AppCopy copy) {
    final replay = session.completedReplay;
    if (replay == null) return const SizedBox.shrink();
    final index = (_replayIndex ?? replay.lastIndex)
        .clamp(0, replay.lastIndex);
    final frame = replay.frames[index];
    final view = frame.view;
    final action = frame.action;
    String eventLabel;
    if (action is CallAction) {
      eventLabel = '${copy.seat(action.actor.letter)}: ${action.call.code}';
    } else if (action is CardAction) {
      eventLabel = '${copy.seat(action.handOwner.letter)}: '
          '${bridgeCardText(action.card)}';
      if (action.actor != action.handOwner) {
        eventLabel = '$eventLabel (${copy.t('replayBy')}: '
            '${copy.seat(action.actor.letter)})';
      }
    } else {
      eventLabel = copy.t('replayStart');
    }

    return Card(
      key: const Key('replay_panel'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(copy.t('replayTitle'),
                style: Theme.of(context).textTheme.titleMedium),
            Text(copy.replayProgress(index, replay.lastIndex),
                key: const Key('replay_progress')),
            const SizedBox(height: 6),
            Text(eventLabel, key: const Key('replay_event')),
            Text(copy.trickCount(view.completedTricks.length)),
            Text(copy.contract(view.contract?.label ?? copy.t('notYet'))),
            if (view.nsScore != null)
              Text(copy.score(view.nsScore!)),
            if (view.currentTrick.isNotEmpty) ...[
              Text(copy.t('currentTrick')),
              Wrap(
                spacing: 8,
                children: [
                  for (final play in view.currentTrick)
                    Text('${play.handOwner.letter}: '
                        '${bridgeCardText(play.card)}'),
                ],
              ),
            ],
            if (view.completedTricks.isNotEmpty)
              Text(copy.replayWinner(
                  view.completedTricks.last.winner.letter)),
            const SizedBox(height: 8),
            for (final seat in Seat.values)
              Text('${copy.seat(seat.letter)}: '
                  '${copy.remaining(view.remainingCards[seat] ?? 0)}'),
            if (view.ownCards.isNotEmpty) ...[
              Text(copy.t('cards')),
              Wrap(spacing: 6, children: [
                for (final card in view.ownCards)
                  Text(bridgeCardText(card)),
              ]),
            ],
            if (view.dummyCards != null && view.dummyCards!.isNotEmpty) ...[
              Text(copy.t('dummy')),
              Wrap(spacing: 6, children: [
                for (final card in view.dummyCards!)
                  Text(bridgeCardText(card)),
              ]),
            ],
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton(
                key: const Key('replay_first'),
                onPressed: index == 0 ? null
                    : () => setState(() => _replayIndex = 0),
                child: Text(copy.t('replayFirst')),
              ),
              OutlinedButton(
                key: const Key('replay_previous'),
                onPressed: index == 0 ? null
                    : () => setState(() => _replayIndex = index - 1),
                child: Text(copy.t('replayPrevious')),
              ),
              OutlinedButton(
                key: const Key('replay_next'),
                onPressed: index == replay.lastIndex ? null
                    : () => setState(() => _replayIndex = index + 1),
                child: Text(copy.t('replayNext')),
              ),
              OutlinedButton(
                key: const Key('replay_last'),
                onPressed: index == replay.lastIndex ? null
                    : () => setState(() => _replayIndex = replay.lastIndex),
                child: Text(copy.t('replayLast')),
              ),
            ]),
          ],
        ),
      ),
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
