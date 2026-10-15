import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_replay_panel.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_table_toolbar.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> a3Tap(WidgetTester tester, String key) async {
  final target = find.byKey(Key(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 375.0, 768.0]) {
    testWidgets('A3.3 $width: oriented seats, toolbar and dummy fit',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 720);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final session = BridgeSession();
      addTearDown(session.dispose);
      await tester.pumpWidget(BridgeAcademyApp(session: session));
      await a3Tap(tester, 'new_game');

      for (final position in ['N', 'E', 'S', 'W']) {
        expect(find.byKey(Key('seat_$position')), findsOneWidget);
      }
      expect(find.byKey(const Key('current_trick')), findsOneWidget);
      expect(find.byType(BridgeTableToolbar), findsOneWidget);
      final last = tester.widget<OutlinedButton>(
        find.byKey(const Key('last_trick_action')),
      );
      expect(last.onPressed, isNull);
      expect(tester.takeException(), isNull);

      await a3Tap(tester, 'make_bid');
      expect(session.view!.dummyExposed, isTrue);
      expect(find.byKey(const Key('dummy_revealed')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('A3.3 public auction dialog does not change game state',
      (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await a3Tap(tester, 'new_game');
    await a3Tap(tester, 'pass');
    final version = session.view!.version;
    await a3Tap(tester, 'auction_history_action');
    expect(find.byKey(const Key('auction_history_dialog')), findsOneWidget);
    expect(find.textContaining('PASS'), findsWidgets);
    await a3Tap(tester, 'close_history');
    expect(session.view!.version, version);
    expect(find.byType(BridgeCompletedReplayPanel), findsOneWidget);
    await a3Tap(tester, 'replay_previous');
    expect(session.view!.version, version);
  });

  testWidgets('A3.3 last trick opens only after four public played cards',
      (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await a3Tap(tester, 'new_game');
    await a3Tap(tester, 'make_bid');

    // Real Bridge Core + demo bot, never a fabricated completed trick.
    for (var n = 0; n < 8 && session.view!.completedTricks.isEmpty; n++) {
      final view = session.view!;
      expect(view.canAct, isTrue);
      final card = view.legalCards.first;
      final prefix = view.turn == view.viewer ? 'hand_card_' : 'dummy_card_';
      await a3Tap(tester, '$prefix${card.code}');
    }
    expect(session.view!.completedTricks, isNotEmpty);
    final trick = session.view!.completedTricks.last;
    expect(trick.plays.length, 4);
    final before = session.view!.version;
    await a3Tap(tester, 'last_trick_action');
    expect(find.byKey(const Key('last_trick_dialog')), findsOneWidget);
    expect(find.textContaining('上一墩贏家'), findsOneWidget);
    await a3Tap(tester, 'close_last_trick');
    expect(session.view!.version, before);
  });
}
