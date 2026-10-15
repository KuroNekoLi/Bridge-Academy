import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/secure_session_persistence.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> tapBrowser(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
  final error = tester.takeException();
  if (error != null) fail('Browser control $key: $error');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('REAL BROWSER A2.8: default WebCrypto checkpoint survives reload',
      (tester) async {
    final secure = EncryptedTransactionalSessionArchiveStore.browser();
    await tester.runAsync(secure.clear);
    addTearDown(() async { await secure.clear(); });

    // Do not inject a fake session: exercise the real browser composition.
    expect(find.byKey(const Key('restored_game')), findsNothing);
    await tester.pumpWidget(const BridgeAcademyApp(
      key: ValueKey('a28_web_fresh_application'),
    ));
    await tester.pumpAndSettle();
    await tapBrowser(tester, 'new_game');
    await tapBrowser(tester, 'pass');
    expect(find.byKey(const Key('final_result')), findsOneWidget);

    final encrypted = await tester.runAsync(() =>
        SharedPreferencesAsync().getString(BrowserSingleRecordArchiveStore.key));
    expect(encrypted, isNotNull);
    expect(encrypted, isNot(contains('dealPbn')));
    expect(encrypted, isNot(contains('humanSeat')));

    // A second BridgeAcademyApp recreates its session and storage provider.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(const BridgeAcademyApp(
      key: ValueKey('a28_web_restored_application'),
    ));
    await tester.runAsync(() =>
        Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('restored_game')), findsOneWidget);
    expect(find.byKey(const Key('final_result')), findsOneWidget);
    expect(find.byKey(const Key('board_number')), findsOneWidget);
    expect(tester.takeException(), isNull);
    // ignore: avoid_print
    print('A2_8_REAL_WEB_CRYPTO_RELOAD_PASS');
  });
}
