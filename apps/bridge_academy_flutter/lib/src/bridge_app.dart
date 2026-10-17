import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:bridge_dds_adapter/bridge_dds_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_copy.dart';
import 'academy/academy_page.dart';
import 'experience/review_learning/review_learning_map.dart';
import 'bridge_session.dart';
import 'daily_practice_store.dart';
import 'widgets/daily_practice_panel.dart';
import 'widgets/ux_postgame_result_panel.dart';
import 'widgets/bridge_table_components.dart';
import 'widgets/bridge_bidding_box.dart';
import 'widgets/bidding_convention_panel.dart';
import 'conventions/convention_profile.dart';
import 'widgets/bridge_table_toolbar.dart';
import 'widgets/bridge_replay_panel.dart';
import 'widgets/bridge_history_panel.dart';
import 'session_persistence.dart';
import 'completed_history_store.dart';
import 'secure_session_persistence.dart';
import 'gateway_game_session.dart';
import 'gateway_http_api.dart';
import 'gateway_table.dart';
import 'experience/first_play_home.dart';

enum _UxPage { home, play, review, me }

/// App composition: Flutter sees only PlayerView through BridgeSession.
class BridgeAcademyApp extends StatefulWidget {
  const BridgeAcademyApp({
    super.key, this.session, this.gatewayApi, this.ddsAnalyzer,
    this.showHomeOnLaunch,
  });
  final BridgeSession? session;
  /// Test-injected Gateway API; a configured origin is an explicit opt-in.
  final GatewayApi? gatewayApi;
  final DoubleDummyAnalyzer? ddsAnalyzer;
  /// Injected session/API defaults to legacy table for existing fixtures.
  /// Regular app launches show Home. Tests can explicitly opt into Home.
  final bool? showHomeOnLaunch;

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
  late final bool _uxHomeEnabled;
  late _UxPage _uxPage;

  void _go(_UxPage page) {
    if (page == _UxPage.review && _session == null) return;
    setState(() => _uxPage = page);
  }

  void _openAcademy(BuildContext navigatorContext) {
    Navigator.of(navigatorContext).push(MaterialPageRoute<void>(
      builder: (_) => AcademyPage(isEnglish: _isEnglish),
    ));
  }

  Future<void> _quickStart() async {
    final session = _session;
    if (session == null || session.busy || session.saveFailed ||
        session.dailySaveFailed || session.recoveryNeedsConfirmation) {
      return;
    }
    final seriesPending =
        (session.dailyPractice != null &&
            !session.dailyPractice!.isComplete) ||
        (session.fourBoardPractice != null &&
            !session.fourBoardPractice!.isComplete);
    if (session.started && (!session.finished || seriesPending)) {
      _go(_UxPage.play); // Resume, never replace committed actions.
      return;
    }
    await session.newGame(
      humanSeat: Seat.north, mode: OpponentMode.demo,
      boardMode: BoardMode.training,
    );
    if (mounted && session.started) _go(_UxPage.play);
  }

  Future<void> _dailyStart() async {
    final session = _session;
    if (session == null || session.busy || session.saveFailed ||
        session.dailySaveFailed || session.recoveryNeedsConfirmation) {
      return;
    }
    if (session.started && !session.finished ||
        (session.fourBoardPractice != null &&
            !session.fourBoardPractice!.isComplete)) {
      _go(_UxPage.play);
      return;
    }
    await session.startDailyPractice();
    if (mounted) _go(_UxPage.play);
  }

  Widget _home(AppCopy copy, BuildContext context) {
    Widget makeHome() {
      final session = _session;
      final gateway = _gateway;
      final seriesPending = session != null && (
          (session.dailyPractice != null &&
              !session.dailyPractice!.isComplete) ||
          (session.fourBoardPractice != null &&
              !session.fourBoardPractice!.isComplete));
      final canContinue = (session != null && session.started &&
          !session.finished) || seriesPending ||
          (gateway != null && gateway.started && !gateway.finished);
      final isBusy = session?.busy ?? gateway?.busy ?? false;
      return FirstPlayHome(
        copy: copy,
        gatewayConfigured: gateway != null || _gatewayConfigError,
        gatewayInvalid: _gatewayConfigError,
        canQuickStart: session != null && !isBusy &&
            !session.saveFailed && !session.dailySaveFailed &&
            !session.recoveryNeedsConfirmation && !canContinue,
        canContinue: canContinue,
        busy: isBusy,
        warningKey: session?.recoveryNeedsConfirmation == true
            ? 'uxRecoveryWarning' :
            session?.saveFailed == true ? 'uxSaveWarning' : null,
        onQuick: _quickStart,
        onContinue: () => _go(_UxPage.play),
        onCustom: () => _go(_UxPage.play),
        onLearn: () => _openAcademy(context),
        onShort: () => _go(_UxPage.play),
        onDaily: _dailyStart,
        onReview: () => _go(_UxPage.review),
      );
    }
    if (_session != null) {
      return AnimatedBuilder(animation: _session!,
          builder: (context, _) => makeHome());
    }
    if (_gateway != null) {
      return AnimatedBuilder(animation: _gateway!,
          builder: (context, _) => makeHome());
    }
    return makeHome();
  }

  Widget _uxBody(AppCopy copy, BuildContext context) {
    if (_uxPage == _UxPage.home) return _home(copy, context);
    if (_uxPage == _UxPage.me) {
      return ListView(key: const Key('ux_me_screen'),
        padding: const EdgeInsets.all(16), children: [
          Text(copy.t('uxMe'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(copy.t('uxNoAccount')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('ux_settings_locale'),
            onPressed: () => setState(() => _isEnglish = !_isEnglish),
            icon: const Icon(Icons.language),
            label: Text(copy.t('language')),
          ),
        ]);
    }
    if (_gatewayConfigError) {
      return Center(child: Text(copy.t('gatewayInvalidConfig'),
          key: const Key('gateway_invalid_config')));
    }
    if (_gateway != null) {
      return GatewayTable(session: _gateway!, copy: copy);
    }
    return BridgeTable(
      session: _session!, copy: copy,
      initialHistoryOpen: _uxPage == _UxPage.review,
      confirmReplacement: true,
      allowBenSelection:
          const String.fromEnvironment('BEN_BASE_URL').isNotEmpty,
    );
  }

  @override
  void initState() {
    super.initState();
    _uxHomeEnabled = widget.showHomeOnLaunch ??
        (widget.session == null && widget.gatewayApi == null);
    _uxPage = _uxHomeEnabled ? _UxPage.home : _UxPage.play;
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
            if (_uxHomeEnabled)
              IconButton(
                key: const Key('ux_app_home'),
                tooltip: copy.t('uxHome'),
                onPressed: () => _go(_UxPage.home),
                icon: const Icon(Icons.home_outlined),
              ),
            Builder(
              builder: (navigatorContext) => IconButton(
                key: const Key('academy_open'),
                tooltip: copy.t('academyOpen'),
                onPressed: () => _openAcademy(navigatorContext),
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
        body: _uxHomeEnabled
            ? Builder(builder: (inner) => _uxBody(copy, inner))
            : _gatewayConfigError
                ? Center(child: Text(copy.t('gatewayInvalidConfig'),
                    key: const Key('gateway_invalid_config')))
                : _gateway != null
                    ? GatewayTable(session: _gateway!, copy: copy)
                    : BridgeTable(session: _session!, copy: copy),
        bottomNavigationBar: _uxHomeEnabled ? NavigationBar(
          key: const Key('ux_navigation'),
          selectedIndex: switch (_uxPage) {
            _UxPage.home => 0,
            _UxPage.play => 1,
            _UxPage.review => _gateway == null ? 2 : 1,
            _UxPage.me => _gateway == null ? 3 : 2,
          },
          onDestinationSelected: (index) => _go(switch (index) {
            0 => _UxPage.home,
            1 => _UxPage.play,
            2 => _gateway == null ? _UxPage.review : _UxPage.me,
            _ => _UxPage.me,
          }),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined), label: copy.t('uxHome')),
            NavigationDestination(
              icon: const Icon(Icons.style_outlined), label: copy.t('uxPlay')),
            if (_gateway == null)
              NavigationDestination(
                icon: const Icon(Icons.history), label: copy.t('uxReview')),
            NavigationDestination(
              icon: const Icon(Icons.person_outline), label: copy.t('uxMe')),
          ],
        ) : null,
      ),
    );
  }
}

class BridgeTable extends StatefulWidget {
  const BridgeTable({
    super.key, required this.session, required this.copy,
    this.initialHistoryOpen = false,
    this.confirmReplacement = false,
    this.allowBenSelection = true,
  });
  final BridgeSession session;
  final AppCopy copy;
  final bool initialHistoryOpen;
  final bool confirmReplacement;
  final bool allowBenSelection;

  @override
  State<BridgeTable> createState() => _BridgeTableState();
}

class _BridgeTableState extends State<BridgeTable> {
  Seat _selectedSeat = Seat.north;
  OpponentMode _selectedMode = OpponentMode.demo;
  BoardMode _selectedBoard = BoardMode.training;
  int _bidLevel = 1;
  Strain _bidStrain = Strain.notrump;
  int _justDeclareLevel = 3;
  Strain _justDeclareStrain = Strain.notrump;
  int? _replayIndex;
  bool _reviewFocused = false;
  final _resultAnchor = GlobalKey();
  final _replayAnchor = GlobalKey();
  final _historyAnchor = GlobalKey();
  bool _historyOpen = false;
  String? _selectedHistoryId;
  int _historyStep = 0;
  bool _syncedRestore = false;

  /// Navigator preserves this BridgeTable state: opening a learning route
  /// never changes the original review frame or starts a fresh game.
  Future<void> _practiceFromReview(ReviewLearningTarget target,
      {String? historyId}) async {
    if (historyId != null &&
        !widget.session.completedHistory.any((h) => h.id == historyId)) {
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => AcademyPage(
        isEnglish: widget.copy.isEnglish,
        initialLessonId: target.lessonId,
        initialQuestionId: target.questionId,
      ),
    ));
    if (!mounted) return;
    if (historyId != null &&
        !widget.session.completedHistory.any((h) => h.id == historyId)) {
      setState(() {
        _selectedHistoryId = null;
        _historyStep = 0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _historyOpen = widget.initialHistoryOpen;
    if (widget.session.started) {
      _selectedSeat = widget.session.humanSeat;
      _selectedMode = widget.session.mode;
    }
    widget.session.addListener(_syncRestoredSelection);
    _syncRestoredSelection();
  }

  void _syncRestoredSelection() {
    if (_syncedRestore || !widget.session.restoredFromStorage) return;
    _syncedRestore = true;
    setState(() {
      _selectedSeat = widget.session.humanSeat;
      _selectedMode = widget.session.mode;
      _selectedBoard = (widget.session.boardMode == BoardMode.bidding ||
              widget.session.boardMode == BoardMode.daily)
          ? BoardMode.fresh : widget.session.boardMode;
    });
  }

  @override
  void didUpdateWidget(covariant BridgeTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHistoryOpen != widget.initialHistoryOpen) {
      _historyOpen = widget.initialHistoryOpen;
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_syncRestoredSelection);
    super.dispose();
  }

  void _scrollTo(GlobalKey anchor) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = anchor.currentContext;
      if (!mounted || target == null) return;
      Scrollable.ensureVisible(target,
          duration: const Duration(milliseconds: 160), alignment: 0.08);
    });
  }

  void _openPostgameReplay() {
    setState(() {
      _historyOpen = false;
      _reviewFocused = true;
    });
    _scrollTo(_replayAnchor);
  }

  void _showPostgameResult() {
    setState(() => _reviewFocused = false);
    _scrollTo(_resultAnchor);
  }

  void _openPostgameHistory() {
    setState(() {
      _historyOpen = true;
      _reviewFocused = false;
      _selectedHistoryId = null;
    });
    _scrollTo(_historyAnchor);
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
                .where((trick) => trick.winner.isNS ==
                    trainingContract.declarer.isNS)
                .length;
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
                      onPressed: session.busy || session.saveFailed ||
                              session.recoveryNeedsConfirmation ||
                              session.dailySaveFailed ||
                              (session.dailyPractice != null &&
                                   !session.dailyPractice!.isComplete) ||
                              (session.fourBoardPractice != null &&
                               !session.fourBoardPractice!.isComplete)
                          ? null
                          : () async {
                              if (widget.confirmReplacement &&
                                  session.started && !session.finished) {
                                final accept = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: Text(copy.t('uxReplaceTitle')),
                                    content: Text(copy.t('uxReplaceWarning')),
                                    actions: [
                                      TextButton(
                                        key: const Key('ux_replace_cancel'),
                                        onPressed: () => Navigator.pop(dialogContext, false),
                                        child: Text(copy.t('uxCancel')),
                                      ),
                                      FilledButton(
                                        key: const Key('ux_replace_confirm'),
                                        onPressed: () => Navigator.pop(dialogContext, true),
                                        child: Text(copy.t('uxReplace')),
                                      ),
                                    ],
                                  ),
                                );
                                if (!mounted || accept != true) return;
                              }
                              setState(() => _replayIndex = null);
                              await session.newGame(
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
                    FilledButton.tonalIcon(
                      key: const Key('start_four_board'),
                      onPressed: session.busy || session.saveFailed ||
                          (session.started && !session.finished && !session.biddingPracticeComplete) ||
                          (session.dailyPractice != null &&
                                   !session.dailyPractice!.isComplete) ||
                              (session.fourBoardPractice != null &&
                           !session.fourBoardPractice!.isComplete)
                          ? null : () {
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
                    _justDeclareLauncher(session, copy),
                    FilledButton.tonalIcon(
                      key: const Key('start_daily_practice'),
                      onPressed: session.busy || session.saveFailed ||
                          session.dailySaveFailed ||
                          (session.started && !session.finished &&
                              !session.biddingPracticeComplete) ||
                          (session.dailyPractice != null &&
                                   !session.dailyPractice!.isComplete) ||
                              (session.fourBoardPractice != null &&
                              !session.fourBoardPractice!.isComplete)
                          ? null : () {
                        setState(() {
                          _replayIndex = null;
                          _selectedMode = OpponentMode.demo;
                          _selectedBoard = BoardMode.fresh;
                        });
                        session.startDailyPractice(humanSeat: _selectedSeat);
                      },
                      icon: const Icon(Icons.today),
                      label: Text(copy.t('dailyStart'),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                     FilledButton.tonalIcon(
                       key: const Key('start_bidding_practice'),
                       onPressed: session.busy || session.saveFailed ||
                           (session.started && !session.finished &&
                               !session.biddingPracticeComplete) ||
                           (session.dailyPractice != null &&
                                   !session.dailyPractice!.isComplete) ||
                              (session.fourBoardPractice != null &&
                               !session.fourBoardPractice!.isComplete)
                           ? null : () {
                         setState(() {
                           _replayIndex = null;
                           _selectedBoard = BoardMode.fresh;
                           _selectedMode = OpponentMode.demo;
                         });
                         session.startBiddingPractice(humanSeat: _selectedSeat);
                       },
                       icon: const Icon(Icons.record_voice_over),
                       label: Text(copy.t('biddingStart'),
                           maxLines: 1, overflow: TextOverflow.ellipsis),
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
              SizedBox(height: 8, key: _historyAnchor),
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
                onPracticeConcept: (id, target) =>
                    _practiceFromReview(target, historyId: id),
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
                    ? session.retryHistorySave : null,
              ),
            ],
            if (session.dailyPractice != null ||
                session.dailyHistory.isNotEmpty) ...[
              const SizedBox(height: 8),
              DailyPracticePanel(
                copy: copy,
                today: session.todaysDaily,
                active: session.dailyPractice,
                history: session.dailyHistory,
                finished: session.finished,
                showNextAction: !session.finished,
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
                        Text('${copy.t('justDeclareDeclarer')}: '
                            '${copy.seat(trainingContract.declarer.letter)}'),
                        Text('${copy.t('justDeclareDummy')}: '
                            '${copy.seat(trainingContract.dummy.letter)}'),
                        Text(
                          copy.justDeclareProgress(
                              declarerTricks, trainingContract.targetTricks),
                          key: const Key('just_declare_goal'),
                        ),
                        if (session.finished)
                          Text(
                            copy.t(declarerTricks >= trainingContract.targetTricks
                                ? 'justDeclareMade' : 'justDeclareDown'),
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
                 actionsPaused: session.actionsPaused ||
                     (session.isBiddingPractice && session.biddingPracticeComplete),
                 onPlayCard: session.submitCard,
               ),
              const SizedBox(height: 8),
              BridgeTableToolbar(view: view, copy: copy),
              const SizedBox(height: 8),
              if (!session.finished)
                _humanControls(view, session, copy)
              else if (!session.isBiddingPractice) ...[
                KeyedSubtree(
                  key: _resultAnchor,
                  child: _postgameResultPanel(session, view, copy),
                ),
                if (!_historyOpen) ...[
                  SizedBox(height: 8, key: _replayAnchor),
                  _replayPanel(session, copy),
                ],
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
                enabled: mode == OpponentMode.demo || widget.allowBenSelection,
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

  /// Core owns the score and next deal; this panel holds navigation only.
  Widget _postgameResultPanel(
      BridgeSession session, PlayerView view, AppCopy copy) {
    final four = session.fourBoardPractice;
    final daily = session.dailyPractice;
    final advance = four != null
        ? (four.isComplete
            ? PostgameAdvance.none : PostgameAdvance.fourBoard)
        : daily != null
            ? (daily.isComplete
                ? PostgameAdvance.none : PostgameAdvance.dailyBoard)
            : session.isJustDeclare
                ? PostgameAdvance.none : PostgameAdvance.nextBoard;
    final blocked = session.actionsPaused || session.saveFailed ||
        session.historySaveFailed || session.dailySaveFailed;
    return UxPostgameResultPanel(
      copy: copy,
      result: PostgameResult.fromFinishedView(
        view: view, boardNumber: session.board.number,
        isJustDeclare: session.isJustDeclare,
      ),
      advance: advance,
      canChangeBoard: !blocked,
      canReview: session.completedReplay != null,
      canHistory: session.completedHistory.isNotEmpty,
      canRetry: four == null && daily == null,
      blocked: blocked,
      reviewFocused: _reviewFocused,
      onReview: _openPostgameReplay,
      onBackToResult: _showPostgameResult,
      onHistory: _openPostgameHistory,
      onNext: () {
        setState(() {
          _replayIndex = null;
          _reviewFocused = false;
          _historyOpen = false;
        });
        if (four != null) {
          session.nextFourBoardPractice();
        } else if (daily != null) {
          session.nextDailyBoard();
        } else {
          session.nextBoard();
        }
      },
      onRetry: () {
        setState(() {
          _replayIndex = null;
          _reviewFocused = false;
          _historyOpen = false;
        });
        session.replaySameBoard();
      },
    );
  }

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
      onPracticeConcept: (target) => _practiceFromReview(target),
      onAnalyzeDds: session.analyzeCompletedDds,
    );
  }

}
