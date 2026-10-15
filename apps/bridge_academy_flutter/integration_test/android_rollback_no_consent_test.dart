import 'dart:convert';

import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Process B: a fresh OS process must find the damaged current slot, recover
/// ONLY the previous legal state, record durable consent-required status.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('A2.6 process B: rollback warning blocks play after force-stop',
      (tester) async {
    final store = PreferencesSessionArchiveStore();
    final session = BridgeSession(archiveStore: store);
    addTearDown(session.dispose);
    expect(await tester.runAsync(session.restoreSavedGame), true);
    expect(session.recoveryNeedsConfirmation, true);
    expect(session.actionsPaused, true);
    expect(session.view!.version, 0);
    expect(session.view!.auction, isEmpty);
    expect(session.view!.viewer, Seat.north);
    expect(session.view!.dummyCards, isNull);
    expect(session.view!.toJson().containsKey('dealPbn'), false);
    expect(session.view!.toJson().containsKey('hands'), false);

    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recovery_warning')), findsOneWidget);
    final pass = find.byKey(const Key('pass'));
    expect(tester.widget<OutlinedButton>(pass).onPressed, isNull);
    await tester.runAsync(() => session.submitCall(const Pass()));
    expect(session.view!.version, 0);
    expect(session.finished, false);

    final prefs = SharedPreferencesAsync();
    final active = await tester.runAsync(() async => jsonDecode(
      (await prefs.getString(PreferencesSessionArchiveStore.activeKey))!,
    ) as Map<String, dynamic>);
    expect(active!['slot'], 'a');
    expect(active['generation'], 1);
    expect(active['recoveryPending'], true);
    // This process does NOT acknowledge; second force-stop must preserve it.
    // ignore: avoid_print
    print('A2_6_PROCESS_B_UNACKNOWLEDGED_WARNING_PASS');
  });
}

