import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tapVisible(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test('M2-F11 session never offers playback before game finish', () async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    expect(session.completedReplay, isNull);
    await session.newGame();
    expect(session.completedReplay, isNull);
    await session.submitCall(const Pass());
    expect(session.finished, true);
    expect(session.completedReplay!.frames.length, 5);
    expect(session.completedReplay!.frames.first.view.dummyCards, isNull);
    expect(session.completedReplay!.frames.last.view.nsScore, 0);
    await session.newGame();
    expect(session.completedReplay, isNull);
  });

  testWidgets('M2-F11 Pass Out replay allows stepping and resets on restart',
      (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    expect(find.byKey(const Key('replay_panel')), findsNothing);
    await tapVisible(tester, 'new_game');
    expect(find.byKey(const Key('replay_panel')), findsNothing);
    await tapVisible(tester, 'pass');
    expect(find.byKey(const Key('final_result')), findsOneWidget);
    expect(find.byKey(const Key('replay_panel')), findsOneWidget);
    expect(find.text('事件步驟: 4 / 4'), findsOneWidget);
    await tapVisible(tester, 'replay_previous');
    expect(find.text('事件步驟: 3 / 4'), findsOneWidget);
    expect(find.text('北（N）: PASS'), findsNothing);
    await tapVisible(tester, 'replay_first');
    expect(find.text('事件步驟: 0 / 4'), findsOneWidget);
    expect(find.text('牌局開始（尚未叫牌）'), findsOneWidget);
    await tapVisible(tester, 'replay_next');
    expect(find.text('事件步驟: 1 / 4'), findsOneWidget);
    await tapVisible(tester, 'replay_last');
    expect(find.text('事件步驟: 4 / 4'), findsOneWidget);
    await tapVisible(tester, 'new_game');
    expect(find.byKey(const Key('replay_panel')), findsNothing);
    expect(session.completedReplay, isNull);
  });

  testWidgets('M2-F11 replay controls use English localized labels',
      (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tapVisible(tester, 'toggle_locale');
    await tapVisible(tester, 'new_game');
    await tapVisible(tester, 'pass');
    expect(find.text('Deal replay'), findsOneWidget);
    expect(find.text('Event step: 4 / 4'), findsOneWidget);
    await tapVisible(tester, 'replay_first');
    expect(find.text('Deal started (before auction)'), findsOneWidget);
    expect(find.text('Event step: 0 / 4'), findsOneWidget);
  });
}

