import 'dart:convert';

import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Process C: a second real Android process restart must not remove consent
/// state. Only a user's actual UI tap may clear it and unblock legal actions.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('A2.6 process C: warning survives second restart until tap',
      (tester) async {
    final store = PreferencesSessionArchiveStore();
    final session = BridgeSession(archiveStore: store);
    addTearDown(session.dispose);
    expect(await tester.runAsync(session.restoreSavedGame), true);
    expect(session.recoveryNeedsConfirmation, true);
    expect(session.view!.version, 0);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recovery_warning')), findsOneWidget);
    expect(tester.widget<OutlinedButton>(find.byKey(const Key('pass')))
        .onPressed, isNull);

    final button = find.byKey(const Key('ack_recovered_checkpoint'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(session.recoveryNeedsConfirmation, false);
    expect(session.actionsPaused, false);
    expect(find.byKey(const Key('recovery_warning')), findsNothing);
    expect(session.view!.version, 0,
        reason: 'Acknowledgment must not fabricate an auction event');

    final prefs = SharedPreferencesAsync();
    final acknowledged = await tester.runAsync(() async => jsonDecode(
      (await prefs.getString(PreferencesSessionArchiveStore.activeKey))!,
    ) as Map<String, dynamic>);
    expect(acknowledged!['recoveryPending'], false);
    expect(acknowledged['generation'], 1);
    final pass = find.byKey(const Key('pass'));
    await tester.ensureVisible(pass);
    await tester.tap(pass);
    await tester.pumpAndSettle();
    expect(session.finished, true);
    expect(session.view!.version, 4); // Human pass + three actual bot passes.
    expect(session.view!.nsScore, 0);
    expect(session.errorCode, isNull);
    final raw = await tester.runAsync(store.read);
    expect(SavedBoardCodec.decode(raw!).state.version, 4);
    expect(store.recoveredOlderCheckpoint, false);
    await tester.runAsync(store.clear);
    // ignore: avoid_print
    print('A2_6_PROCESS_C_EXPLICIT_CONSENT_PASS');
  });
}

