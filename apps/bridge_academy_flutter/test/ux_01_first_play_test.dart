import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/gateway_http_api.dart';
import 'package:bridge_academy_flutter/src/academy/academy_page.dart';
import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Archive implements SessionArchiveStore {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String content) async { value = content; }
  @override
  Future<void> clear() async { value = null; }
}

class _Gateway implements GatewayApi {
  int count = 0;
  @override
  Future<Map<String, dynamic>> post(
      String path, Map<String, Object?> body, {String? bearer}) async {
    count++;
    throw const GatewayHttpError(503, 'offline');
  }
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  if (f.evaluate().isEmpty) {
    await tester.scrollUntilVisible(f, 170,
        scrollable: find.byType(Scrollable).last, maxScrolls: 30);
  }
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('UX-01 guest Home -> Demo auction -> Home -> resume',
      (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(
      BridgeAcademyApp(session: session, showHomeOnLaunch: true));
    expect(find.byKey(const Key('ux_home_screen')), findsOneWidget);
    expect(find.byKey(const Key('bridge_board')), findsNothing);
    expect(find.textContaining('不是 BEN'), findsWidgets);
    await tapKey(tester, 'ux_home_quick_start');
    expect(session.started, true);
    expect(session.mode, OpponentMode.demo);
    expect(session.view!.ownCards.length, 13);
    expect(session.view!.dummyCards, isNull);
    final version = session.view!.version;
    await tapKey(tester, 'ux_app_home');
    expect(find.byKey(const Key('ux_home_resume')), findsOneWidget);
    await tapKey(tester, 'ux_home_resume');
    expect(session.view!.version, version);
    await tapKey(tester, 'pass');
    expect(session.view!.version, greaterThan(version));
  });

  testWidgets('UX-01 new game requires confirmation for unfinished progress',
      (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(
        BridgeAcademyApp(session: session, showHomeOnLaunch: true));
    await tapKey(tester, 'ux_home_quick_start');
    expect(session.view!.version, 0);
    await tapKey(tester, 'new_game');
    expect(find.byKey(const Key('ux_replace_confirm')), findsOneWidget);
    await tapKey(tester, 'ux_replace_cancel');
    expect(session.view!.version, 0);
  });

  testWidgets('UX-01 Academy and navigation keep language selection',
      (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(
        BridgeAcademyApp(session: session, showHomeOnLaunch: true));
    await tapKey(tester, 'toggle_locale');
    expect(find.text('How would you like to practice?'), findsOneWidget);
    await tapKey(tester, 'ux_home_learn');
    expect(find.byType(AcademyPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapKey(tester, 'ux_home_custom');
    expect(find.byKey(const Key('new_game')), findsOneWidget);
    await tapKey(tester, 'ux_app_home');
    expect(find.text('How would you like to practice?'), findsOneWidget);
  });

  testWidgets('UX-01 checkpoint is resumed without new board', (tester) async {
    final archive = _Archive();
    final original = BridgeSession(archiveStore: archive);
    await original.newGame();
    expect(archive.value, isNotNull);
    original.dispose();
    final restored = BridgeSession(archiveStore: archive);
    addTearDown(restored.dispose);
    expect(await restored.restoreSavedGame(), true);
    final savedVersion = restored.view!.version;
    await tester.pumpWidget(
        BridgeAcademyApp(session: restored, showHomeOnLaunch: true));
    expect(find.byKey(const Key('ux_home_resume')), findsOneWidget);
    await tapKey(tester, 'ux_home_resume');
    expect(restored.view!.version, savedVersion);
  });

  testWidgets('UX-01 configured Gateway never silently offers Demo',
      (tester) async {
    final api = _Gateway();
    await tester.pumpWidget(
        BridgeAcademyApp(gatewayApi: api, showHomeOnLaunch: true));
    expect(find.byKey(const Key('ux_home_quick_start')), findsNothing);
    expect(find.byKey(const Key('ux_home_gateway')), findsOneWidget);
    expect(api.count, 0);
    await tapKey(tester, 'ux_home_gateway');
    expect(find.byKey(const Key('gateway_start')), findsOneWidget);
    expect(api.count, 0); // Explicit session start only.
  });

  for (final width in [320.0, 375.0]) {
    testWidgets('UX-01 responsive $width and English locale',
        (tester) async {
      tester.view.physicalSize = Size(width, 860);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final session = BridgeSession();
      addTearDown(session.dispose);
      await tester.pumpWidget(
          BridgeAcademyApp(session: session, showHomeOnLaunch: true));
      expect(tester.takeException(), isNull);
      await tapKey(tester, 'toggle_locale');
      expect(tester.takeException(), isNull);
      await tapKey(tester, 'ux_home_custom');
      expect(tester.takeException(), isNull);
    });
  }
}
