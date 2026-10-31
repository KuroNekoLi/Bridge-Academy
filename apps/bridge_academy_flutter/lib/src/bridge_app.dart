import 'package:bridge_dds_adapter/bridge_dds_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_copy.dart';
import 'academy/academy_page.dart';
import 'bridge_session.dart';
import 'daily_practice_store.dart';
import 'completed_history_store.dart';
import 'session_persistence.dart';
import 'secure_session_persistence.dart';
import 'gateway_game_session.dart';
import 'gateway_http_api.dart';
import 'gateway_table.dart';
import 'conventions/custom_draft_page.dart';
import 'conventions/auction_coach_page.dart';
import 'bridge_table.dart';

export 'bridge_table.dart' show BridgeTable;

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

