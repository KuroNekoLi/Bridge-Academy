import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:bridge_dds_adapter/bridge_dds_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_copy.dart';
import 'academy/academy_page.dart';
import 'bridge_session.dart';
import 'daily_practice_store.dart';
import 'widgets/daily_practice_panel.dart';
import 'widgets/bridge_table_components.dart';
import 'widgets/bridge_focus_table.dart';
import 'widgets/bridge_bidding_box.dart';
import 'widgets/bidding_convention_panel.dart';
import 'conventions/convention_profile.dart';
import 'conventions/custom_draft_page.dart';
import 'conventions/auction_coach_page.dart';
import 'widgets/bridge_table_toolbar.dart';
import 'widgets/bridge_replay_panel.dart';
import 'widgets/bridge_history_panel.dart';
import 'widgets/bridge_practice_hub.dart';
import 'session_persistence.dart';
import 'completed_history_store.dart';
import 'secure_session_persistence.dart';
import 'gateway_game_session.dart';
import 'gateway_http_api.dart';
import 'gateway_table.dart';

/// App composition: Flutter sees only PlayerView through BridgeSession.
class BridgeAcademyApp extends StatefulWidget {
  const BridgeAcademyApp({
    super.key,
    this.session,
    this.gatewayApi,
    this.ddsAnalyzer,
  });
  final BridgeSession? session;

  /// Test-injected Gateway API; a configured origin is an explicit opt-in.
  final GatewayApi? gatewayApi;
  final DoubleDummyAnalyzer? ddsAnalyzer;

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
  bool _reduceMotion = false;
  int _destination = 0;

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
        final api =
            widget.gatewayApi ??
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
    final mobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    _session = BridgeSession(
      ddsAnalyzer: widget.ddsAnalyzer ?? _configuredDds(),
      dailyStore: mobile
          ? EncryptedDailyPracticeStore.native()
          : kIsWeb
          ? EncryptedDailyPracticeStore.browser()
          : MemoryDailyPracticeStore(),
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
    _session!.restoreSavedGame(); // Also loads daily and history archives.
  }

  /// Native worker opt-in; browser and unconfigured builds never guess.
  DoubleDummyAnalyzer _configuredDds() {
    const worker = String.fromEnvironment('BRIDGE_DDS_WORKER_SCRIPT');
    return worker.isEmpty || kIsWeb
        ? const UnsupportedDoubleDummyAnalyzer()
        : DdsPythonProcessAnalyzer(workerScript: worker);
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations:
              MediaQuery.disableAnimationsOf(context) || _reduceMotion,
        ),
        child: child!,
      ),
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
        scaffoldBackgroundColor: const Color(0xFFF3F4EE),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFDDE3DA)),
          ),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            copy.t('title'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            Builder(
              builder: (navigatorContext) => IconButton(
                key: const Key('academy_open'),
                tooltip: copy.t('academyOpen'),
                onPressed: () => Navigator.of(navigatorContext).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AcademyPage(isEnglish: _isEnglish),
                  ),
                ),
                icon: const Icon(Icons.school_outlined),
              ),
            ),
            IconButton(
              key: const Key('toggle_locale'),
              tooltip: copy.t('language'),
              onPressed: () => setState(() => _isEnglish = !_isEnglish),
              icon: const Icon(Icons.language),
            ),
          ],
        ),
        bottomNavigationBar: Builder(
          builder: (context) => NavigationBar(
            key: const Key('workspace_navigation'),
            selectedIndex: _destination,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            onDestinationSelected: (index) {
              if (index == 1) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AcademyPage(isEnglish: _isEnglish),
                  ),
                );
              } else {
                setState(() => _destination = index);
              }
            },
            destinations: [
              NavigationDestination(
                key: const Key('nav_play'),
                icon: const Icon(Icons.style_outlined),
                label: copy.t('navPlay'),
              ),
              NavigationDestination(
                key: const Key('nav_learn'),
                icon: const Icon(Icons.school_outlined),
                label: copy.t('navLearn'),
              ),
              if (_session != null)
                NavigationDestination(
                  key: const Key('nav_review'),
                  icon: const Icon(Icons.history),
                  label: copy.t('navReview'),
                ),
              NavigationDestination(
                key: const Key('nav_me'),
                icon: const Icon(Icons.tune),
                label: copy.t('navMe'),
              ),
            ],
          ),
        ),
        body: IndexedStack(
          index: _destination == (_session != null ? 3 : 2) ? 1 : 0,
          children: [
            _gatewayConfigError
                ? Center(
                    child: Text(
                      copy.t('gatewayInvalidConfig'),
                      key: const Key('gateway_invalid_config'),
                    ),
                  )
                : _gateway != null
                ? GatewayTable(session: _gateway!, copy: copy)
                : BridgeTable(
                    session: _session!,
                    copy: copy,
                    historyOnly: _destination == 2,
                  ),
            Builder(
              builder: (context) => ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    copy.t('navMe'),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(copy.t('meDescription')),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(copy.t('language')),
                    onTap: () => setState(() => _isEnglish = !_isEnglish),
                  ),
                  SwitchListTile(
                    key: const Key('reduce_motion'),
                    secondary: const Icon(Icons.animation),
                    title: Text(copy.t('reduceMotion')),
                    subtitle: Text(copy.t('reduceMotionDescription')),
                    value: _reduceMotion,
                    onChanged: (value) => setState(() => _reduceMotion = value),
                  ),
                  ListTile(
                    key: const Key('m4_open_custom_conventions'),
                    leading: const Icon(Icons.edit_note_outlined),
                    title: Text(copy.t('m4Open')),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            CustomConventionDraftPage(isEnglish: _isEnglish),
                      ),
                    ),
                  ),
                  ListTile(
                    key: const Key('m5_open_coach'),
                    leading: const Icon(Icons.psychology_alt_outlined),
                    title: Text(copy.t('m5CoachOpen')),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AuctionCoachPage(isEnglish: _isEnglish),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(copy.t('licenses')),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: copy.t('title'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BridgeTable extends StatefulWidget {
  const BridgeTable({
    super.key,
    required this.session,
    required this.copy,
    this.historyOnly = false,
  });
  final BridgeSession session;
  final AppCopy copy;
  final bool historyOnly;

  @override
  State<BridgeTable> createState() => _BridgeTableState();
}

class _BridgeTableState extends State<BridgeTable> {
  Seat _selectedSeat = Seat.north;
  OpponentMode _selectedMode = OpponentMode.demo;
  BoardMode _selectedBoard = BoardMode.training;
  int _justDeclareLevel = 3;
  Strain _justDeclareStrain = Strain.notrump;
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
      _selectedBoard =
          (widget.session.boardMode == BoardMode.bidding ||
              widget.session.boardMode == BoardMode.daily)
          ? BoardMode.fresh
          : widget.session.boardMode;
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
        final trainingContract = session.isJustDeclare ? view?.contract : null;
        final declarerTricks = trainingContract == null || view == null
            ? 0
            : view.completedTricks
                  .where(
                    (trick) =>
                        trick.winner.isNS == trainingContract.declarer.isNS,
                  )
                  .length;
        if (!widget.historyOnly && view != null) {
          return BridgeFocusTable(
            view: view,
            copy: copy,
            boardNumber: session.board.number,
            modeLabel: copy.t(session.mode == OpponentMode.demo
                ? 'demoNotice' : 'liveNotice'),
            actionsPaused: session.actionsPaused ||
                session.saveFailed || session.recoveryNeedsConfirmation ||
                (session.isBiddingPractice && session.biddingPracticeComplete),
            error: session.errorCode == null
                ? (session.recoveryNeedsConfirmation
                    ? copy.t('recoveredOlderCheckpoint') : null)
                : copy.t(session.errorCode!),
            onRetry: session.recoveryNeedsConfirmation ? null
                : session.saveFailed ? session.retrySave
                : session.errorCode != null ? session.retryBots : null,
            onPlayCard: session.submitCard,
            onSubmitCall: session.submitCall,
            sessionActions: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (session.recoveryNeedsConfirmation)
                  FilledButton(
                    key: const Key('ack_recovered_checkpoint'),
                    onPressed: session.acknowledgeRecoveredCheckpoint,
                    child: Text(copy.t('ackRecoveredCheckpoint')),
                  ),
                if (session.dailyPractice != null ||
                    session.dailyHistory.isNotEmpty)
                  DailyPracticePanel(
                    copy: copy,
                    today: session.todaysDaily,
                    active: session.dailyPractice,
                    history: session.dailyHistory,
                    finished: session.finished,
                    canAdvance: !session.busy && !session.saveFailed &&
                        !session.dailySaveFailed && !session.historySaveFailed,
                    canRestart: !session.busy && !session.saveFailed &&
                        !session.dailySaveFailed,
                    onNext: () {
                      setState(() => _replayIndex = null);
                      session.nextDailyBoard();
                    },
                    onRestart: () => _confirmDailyRestart(session, copy),
                  ),
                if (session.fourBoardPractice != null)
                  _fourBoardPanel(session, copy),
                if (session.isBiddingPractice)
                  _biddingPracticePanel(session, copy),
                if (session.finished && !session.isBiddingPractice) ...[
                  _finishCard(view, copy),
                  _completedBoardActions(session, copy),
                  if (!_historyOpen) _replayPanel(session, copy),
                ],
                _practiceHub(session, copy),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!widget.historyOnly && view == null)
                      _practiceHub(session, copy),
                    if (_historyOpen || widget.historyOnly) ...[
                      const SizedBox(height: 8),
                      _historyPanel(session, copy),
                    ],
                    if (!widget.historyOnly) ...[
                      if (session.dailyPractice != null ||
                          session.dailyHistory.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        DailyPracticePanel(
                          copy: copy,
                          today: session.todaysDaily,
                          active: session.dailyPractice,
                          history: session.dailyHistory,
                          finished: session.finished,
                          canAdvance:
                              !session.busy &&
                              !session.saveFailed &&
                              !session.dailySaveFailed &&
                              !session.historySaveFailed,
                          canRestart:
                              !session.busy &&
                              !session.saveFailed &&
                              !session.dailySaveFailed,
                          onNext: () {
                            setState(() => _replayIndex = null);
                            session.nextDailyBoard();
                          },
                          onRestart: () => _confirmDailyRestart(session, copy),
                        ),
                      ],
                      if (session.dailyError != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(copy.t(session.dailyError!)),
                                if (session.dailySaveFailed)
                                  TextButton(
                                    key: const Key('daily_retry_save'),
                                    onPressed: session.retryDailySave,
                                    child: Text(copy.t('dailyRetrySave')),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      if (session.fourBoardPractice != null) ...[
                        const SizedBox(height: 8),
                        _fourBoardPanel(session, copy),
                      ],
                      if (session.isBiddingPractice)
                        _biddingPracticePanel(session, copy),
                      if (session.isJustDeclare) ...[
                        const SizedBox(height: 8),
                        Card(
                          key: const Key('just_declare_active'),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(copy.t('justDeclareActive')),
                                if (trainingContract != null) ...[
                                  Text(
                                    '${copy.t('justDeclareDeclarer')}: '
                                    '${copy.seat(trainingContract.declarer.letter)}',
                                  ),
                                  Text(
                                    '${copy.t('justDeclareDummy')}: '
                                    '${copy.seat(trainingContract.dummy.letter)}',
                                  ),
                                  Text(
                                    copy.justDeclareProgress(
                                      declarerTricks,
                                      trainingContract.targetTricks,
                                    ),
                                    key: const Key('just_declare_goal'),
                                  ),
                                  if (session.finished)
                                    Text(
                                      copy.t(
                                        declarerTricks >=
                                                trainingContract.targetTricks
                                            ? 'justDeclareMade'
                                            : 'justDeclareDown',
                                      ),
                                      key: const Key('just_declare_outcome'),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        copy.t(
                          session.mode == OpponentMode.demo
                              ? 'demoNotice'
                              : 'liveNotice',
                        ),
                      ),
                      if (kIsWeb)
                        Text(
                          copy.t('webCheckpointCaution'),
                          key: const Key('web_checkpoint_caution'),
                        ),
                      if (session.restoring) ...[
                        const LinearProgressIndicator(
                          key: Key('restore_progress'),
                        ),
                        Text(copy.t('restoringGame')),
                      ],
                      if (view == null && session.errorCode != null)
                        Text(
                          copy.t(session.errorCode!),
                          key: const Key('error_message'),
                        ),
                      if (view == null) ...[
                        const SizedBox(height: 24),
                        Text(
                          copy.t('notStarted'),
                          key: const Key('empty_state'),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        BridgeBoardHeader(
                          boardNumber: session.board.number,
                          view: view,
                          busy: session.busy,
                          copy: copy,
                        ),
                        if (session.restoredFromStorage)
                          Text(
                            copy.t('restoredGame'),
                            key: const Key('restored_game'),
                          ),
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
                                    onPressed:
                                        session.acknowledgeRecoveredCheckpoint,
                                    child: Text(
                                      copy.t('ackRecoveredCheckpoint'),
                                    ),
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
                                  Text(
                                    copy.t(session.errorCode!),
                                    key: const Key('error_message'),
                                  ),
                                  if (session.saveFailed && !session.busy)
                                    TextButton(
                                      key: const Key('retry_save'),
                                      onPressed: session.retrySave,
                                      child: Text(copy.t('retrySave')),
                                    ),
                                  if (!session.saveFailed &&
                                      !session.busy &&
                                      !view.canAct &&
                                      !session.finished)
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
                          const LinearProgressIndicator(
                            key: Key('bot_progress'),
                          ),
                          const SizedBox(height: 8),
                          Text(copy.t('waitingBot')),
                        ],
                        const SizedBox(height: 12),
                        BridgeTableSurface(
                          view: view,
                          copy: copy,
                          actionsPaused:
                              session.actionsPaused ||
                              (session.isBiddingPractice &&
                                  session.biddingPracticeComplete),
                          onPlayCard: session.submitCard,
                        ),
                        const SizedBox(height: 8),
                        BridgeTableToolbar(view: view, copy: copy),
                        const SizedBox(height: 8),
                        if (!session.finished)
                          _humanControls(view, session, copy)
                        else ...[
                          if (!session.isBiddingPractice)
                            _finishCard(view, copy),
                          const SizedBox(height: 8),
                          if (!session.isBiddingPractice)
                            _completedBoardActions(session, copy),
                          const SizedBox(height: 8),
                          if (!_historyOpen && !session.isBiddingPractice)
                            _replayPanel(session, copy),
                        ],
                      ],
                      if (view != null) ...[
                        const SizedBox(height: 24),
                        _practiceHub(session, copy),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _historyPanel(BridgeSession session, AppCopy copy) =>
      BridgeHistoryPanel(
        history: session.completedHistory,
        copy: copy,
        selectedId: _selectedHistoryId,
        selectedReplay: _selectedHistoryId == null
            ? null
            : session.historyReplay(_selectedHistoryId!),
        replayIndex: _historyStep,
        onSelect: (id) => setState(() {
          _selectedHistoryId = id;
          _historyStep = 0;
        }),
        onReplayStep: (step) => setState(() => _historyStep = step),
        canDelete: !session.busy,
        onExportPbn: (id) async {
          // The panel requires a separate explicit private-hand
          // export confirmation BEFORE calling this callback.
          final pbn = session.exportHistoryPbn(id);
          if (pbn == null) return false;
          await Clipboard.setData(ClipboardData(text: pbn));
          return true;
        },
        onImportPbn: session.importHistoryPbn,
        onAnalyzeDds: session.analyzeHistoryDds,
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
            ? session.retryHistorySave
            : null,
      );

  Widget _practiceHub(BridgeSession session, AppCopy copy) => BridgePracticeHub(
    copy: copy,
    started: session.started,
    settings: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              copy.t('hubSettings'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  _modeSelector(copy, constraints.maxWidth),
                  _seatSelector(copy, constraints.maxWidth),
                  _boardSelector(copy, constraints.maxWidth),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      BridgePracticeAction(
        copy.t('hubFreeTitle'),
        copy.t('hubFreeDescription'),
        Icons.style_outlined,
        FilledButton.icon(
          key: const Key('new_game'),
          onPressed:
              session.busy ||
                  (session.dailyPractice != null &&
                      !session.dailyPractice!.isComplete) ||
                  (session.fourBoardPractice != null &&
                      !session.fourBoardPractice!.isComplete)
              ? null
              : () => _startFreePlay(session, copy),
          icon: const Icon(Icons.refresh),
          label: Text(session.started ? copy.t('restart') : copy.t('newGame')),
        ),
      ),
      BridgePracticeAction(
        copy.t('hubFourTitle'),
        copy.t('hubFourDescription'),
        Icons.view_module_outlined,
        FilledButton.tonalIcon(
          key: const Key('start_four_board'),
          onPressed:
              session.busy ||
                  session.saveFailed ||
                  (session.started &&
                      !session.finished &&
                      !session.biddingPracticeComplete) ||
                  (session.dailyPractice != null &&
                      !session.dailyPractice!.isComplete) ||
                  (session.fourBoardPractice != null &&
                      !session.fourBoardPractice!.isComplete)
              ? null
              : () {
                  setState(() {
                    _replayIndex = null;
                    _selectedBoard = BoardMode.fresh;
                  });
                  session.startFourBoardPractice(
                    humanSeat: _selectedSeat,
                    mode: _selectedMode,
                  );
                },
          icon: const Icon(Icons.view_module),
          label: Text(copy.t('practiceFourStart')),
        ),
      ),
      BridgePracticeAction(
        copy.t('hubDeclareTitle'),
        copy.t('hubDeclareDescription'),
        Icons.school_outlined,
        _justDeclareLauncher(session, copy),
      ),
      BridgePracticeAction(
        copy.t('hubDailyTitle'),
        copy.t('hubDailyDescription'),
        Icons.today,
        FilledButton.tonalIcon(
          key: const Key('start_daily_practice'),
          onPressed:
              session.busy ||
                  session.saveFailed ||
                  session.dailySaveFailed ||
                  (session.started &&
                      !session.finished &&
                      !session.biddingPracticeComplete) ||
                  (session.dailyPractice != null &&
                      !session.dailyPractice!.isComplete) ||
                  (session.fourBoardPractice != null &&
                      !session.fourBoardPractice!.isComplete)
              ? null
              : () {
                  setState(() {
                    _replayIndex = null;
                    _selectedMode = OpponentMode.demo;
                    _selectedBoard = BoardMode.fresh;
                  });
                  session.startDailyPractice(humanSeat: _selectedSeat);
                },
          icon: const Icon(Icons.today),
          label: Text(
            copy.t('dailyStart'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      BridgePracticeAction(
        copy.t('hubBidTitle'),
        copy.t('hubBidDescription'),
        Icons.record_voice_over,
        FilledButton.tonalIcon(
          key: const Key('start_bidding_practice'),
          onPressed:
              session.busy ||
                  session.saveFailed ||
                  (session.started &&
                      !session.finished &&
                      !session.biddingPracticeComplete) ||
                  (session.dailyPractice != null &&
                      !session.dailyPractice!.isComplete) ||
                  (session.fourBoardPractice != null &&
                      !session.fourBoardPractice!.isComplete)
              ? null
              : () {
                  setState(() {
                    _replayIndex = null;
                    _selectedBoard = BoardMode.fresh;
                    _selectedMode = OpponentMode.demo;
                  });
                  session.startBiddingPractice(humanSeat: _selectedSeat);
                },
          icon: const Icon(Icons.record_voice_over),
          label: Text(
            copy.t('biddingStart'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      BridgePracticeAction(
        copy.t('hubReviewTitle'),
        copy.t('hubReviewDescription'),
        Icons.history,
        OutlinedButton.icon(
          key: const Key('history_toggle'),
          onPressed: () => setState(() {
            _historyOpen = !_historyOpen;
            if (!_historyOpen) _selectedHistoryId = null;
          }),
          icon: const Icon(Icons.history),
          label: Text(copy.t(_historyOpen ? 'historyClose' : 'historyOpen')),
        ),
      ),
    ],
  );

  Future<void> _startFreePlay(BridgeSession session, AppCopy copy) async {
    if (session.started &&
        !session.finished &&
        !session.biddingPracticeComplete) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(copy.t('replaceDealTitle')),
          content: Text(copy.t('replaceDealBody')),
          actions: [
            TextButton(
              key: const Key('keep_current_deal'),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(copy.t('keepDeal')),
            ),
            FilledButton(
              key: const Key('replace_current_deal'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(copy.t('replaceDeal')),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
    }
    if (!mounted || session.busy) return;
    setState(() => _replayIndex = null);
    await session.newGame(
      humanSeat: _selectedSeat,
      mode: _selectedMode,
      boardMode: _selectedBoard,
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
          initialValue: (_selectedBoard == BoardMode.bidding ||
                  _selectedBoard == BoardMode.daily)
              ? BoardMode.fresh : _selectedBoard,
          decoration: InputDecoration(labelText: copy.t('boardMode')),
          items: [
            for (final board in [BoardMode.training, BoardMode.fresh])
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

  Widget _justDeclareLauncher(BridgeSession session, AppCopy copy) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(copy.t('justDeclareSeatHint')),
          Text(copy.t('justDeclareLevel')),
          DropdownButton<int>(
            key: const Key('just_declare_level'),
            value: _justDeclareLevel,
            // DropdownButton has no tooltip parameter (Flutter 3.47).
            items: [for (var i = 1; i <= 7; i++)
              DropdownMenuItem(value: i, child: Text('$i'))],
            onChanged: (v) {
              if (v != null) setState(() => _justDeclareLevel = v);
            },
          ),
          Text(copy.t('justDeclareStrain')),
          SizedBox(
            width: 178,
            child: DropdownButton<Strain>(
            isExpanded: true,
            key: const Key('just_declare_strain'),
            value: _justDeclareStrain,
            // Keep the selector accessible with a visible label.
            items: [for (final v in Strain.values)
              DropdownMenuItem(value: v, child: Text(
                copy.t('strain${v == Strain.notrump ? 'NT' : v.code}'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ))],
            onChanged: (v) {
              if (v != null) setState(() => _justDeclareStrain = v);
            },
          ),
          ),
          SizedBox(width: 230, child: FilledButton.tonalIcon(
            key: const Key('start_just_declare'),
            onPressed: session.busy || session.saveFailed ||
                (session.started && !session.finished && !session.biddingPracticeComplete) ||
                (session.dailyPractice != null &&
                                   !session.dailyPractice!.isComplete) ||
                              (session.fourBoardPractice != null &&
                    !session.fourBoardPractice!.isComplete)
                ? null : () {
              setState(() => _replayIndex = null);
              session.startJustDeclare(
                level: _justDeclareLevel,
                strain: _justDeclareStrain,
                humanSeat: _selectedSeat,
              );
            },
            icon: const Icon(Icons.school),
            label: Text(copy.t('justDeclareStart'),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
        ],
      );

  Future<void> _confirmDailyRestart(
      BridgeSession session, AppCopy copy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(copy.t('dailyRestartTitle')),
        content: Text(copy.t('dailyRestartWarning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(copy.t('dailyRestartCancel')),
          ),
          FilledButton(
            key: const Key('daily_restart_confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(copy.t('dailyRestartConfirm')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _replayIndex = null);
      await session.startDailyPractice(
        humanSeat: session.dailyPractice?.humanSeat ?? _selectedSeat,
        restart: true,
      );
    }
  }

  Widget _biddingPracticePanel(BridgeSession session, AppCopy copy) {
    final view = session.view!;
    final complete = session.biddingPracticeComplete;
    return Card(
      key: const Key('bidding_practice_panel'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(copy.t('biddingTitle'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(copy.t('biddingScope')),
            BiddingConventionPanel(
              contextData: BidContext.fromView(view),
              copy: copy,
            ),
            if (!complete && session.biddingSuggestion != null)
              Text("${copy.t('biddingHint')}: ${session.biddingSuggestion!.code}",
                  key: const Key('bidding_suggestion')),
            if (complete) ...[
              Text(copy.t('biddingFinished'),
                  key: const Key('bidding_finished')),
              Text(copy.contract(view.contract?.label ?? 'PASS OUT')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _fourBoardPanel(BridgeSession session, AppCopy copy) {
    final practice = session.fourBoardPractice!;
    return Card(
      key: const Key('four_board_panel'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(copy.t('practiceFourTitle'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${copy.t('practiceFourCompleted')}: '
                '${practice.completed} / 4',
                key: const Key('four_board_progress')),
            Text('${copy.t('practiceFourHumanScore')}: '
                '${practice.humanNetScore > 0 ? '+' : ''}'
                '${practice.humanNetScore}',
                key: const Key('four_board_score')),
            Text(copy.t('practiceFourScope')),
            for (final result in practice.results)
              ListTile(
                dense: true,
                title: Text('${copy.boardNumber(result.boardNumber)} · '
                    '${result.contract}'),
                trailing: Text('${practice.humanSeat.isNS
                    ? result.nsScore : -result.nsScore}'),
              ),
            if (practice.isComplete)
              Text(copy.t('practiceFourFinished'),
                  key: const Key('four_board_finished'))
            else if (!session.finished)
              Text(copy.t('practiceFourCurrent')),
          ],
        ),
      ),
    );
  }

  Widget _completedBoardActions(BridgeSession session, AppCopy copy) =>
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          if (session.fourBoardPractice != null &&
              !session.fourBoardPractice!.isComplete)
            FilledButton.icon(
              key: const Key('next_practice_board'),
              onPressed: session.busy || session.saveFailed ||
                  session.historySaveFailed ? null : () {
                setState(() => _replayIndex = null);
                session.nextFourBoardPractice();
              },
              icon: const Icon(Icons.skip_next),
              label: Text(copy.t('practiceFourNext')),
            ),
          if (session.fourBoardPractice == null && session.dailyPractice == null)
          OutlinedButton.icon(
            key: const Key('replay_same_board'),
            onPressed: session.busy ? null : () {
              setState(() => _replayIndex = null);
              session.replaySameBoard();
            },
            icon: const Icon(Icons.replay),
            label: Text(copy.t('replaySameBoard')),
          ),
          if (session.fourBoardPractice == null && session.dailyPractice == null)
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BridgePlayerHand(
            view: view,
            copy: copy,
            actionsPaused: true,
            onPlayCard: session.submitCard,
          ),
          BridgeBiddingBox(
            copy: copy,
            view: view,
            canSubmit: view.canAct && !session.actionsPaused,
            onSubmitCall: session.submitCall,
          ),
        ],
      );
    }
    if (view.phase == Phase.play && !session.isBiddingPractice) {
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
      onAnalyzeDds: session.analyzeCompletedDds,
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
