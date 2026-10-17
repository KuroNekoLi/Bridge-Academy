import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('UX-01: Home -> Demo -> legal call -> return and resume',
      (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(
        BridgeAcademyApp(session: session, showHomeOnLaunch: true));
    final start = find.byKey(const Key('ux_home_quick_start'));
    await tester.ensureVisible(start);
    await tester.tap(start);
    // A real browser uses wall-clock Future scheduling; don't spin
    // pumpAndSettle while a bot or transition may keep animating.
    await tester.runAsync(() async {
      for (var i = 0; i < 40 && !session.started; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    });
    await tester.pump(const Duration(milliseconds: 120));
    expect(session.started, true);
    final initial = session.view!.version;
    final pass = find.byKey(const Key('pass'));
    await tester.ensureVisible(pass);
    await tester.tap(pass);
    await tester.runAsync(() async {
      for (var i = 0; i < 50 && session.view!.version == initial; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    });
    await tester.pump(const Duration(milliseconds: 120));
    expect(session.view!.version, greaterThan(initial));
    await tester.tap(find.byKey(const Key('ux_app_home')));
    await tester.pump(const Duration(milliseconds: 120));
    if (!session.finished) {
      final resume = find.byKey(const Key('ux_home_resume'));
      await tester.ensureVisible(resume);
      await tester.tap(resume);
      await tester.pump(const Duration(milliseconds: 120));
      expect(session.view!.version, greaterThan(initial));
    }
  });
}
