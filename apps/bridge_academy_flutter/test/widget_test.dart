import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Replaces Flutter-create's MyApp starter test, preserving this project's
/// actual entry widget when regenerating native/web platform scaffolds.
void main() {
  testWidgets('BridgeAcademyApp boots in Traditional Chinese', (tester) async {
    // Pure Widget test: inject a platform-independent Session. The actual
    // SharedPreferences plugin is exercised by device/browser integration.
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    expect(find.text('Bridge Academy｜橋牌學院'), findsOneWidget);
    expect(find.byIcon(Icons.language), findsOneWidget);
  });
}
