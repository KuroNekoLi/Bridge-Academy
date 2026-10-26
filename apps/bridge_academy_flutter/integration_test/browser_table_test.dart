import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> tapControl(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  final pendingError = tester.takeException();
  if (pendingError != null) {
    fail('Browser action $key: $pendingError');
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('REAL BROWSER: focused table drag and taps complete 13 tricks',
      (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tapControl(tester, 'new_game');
    await tapControl(tester, 'focus_table_open');
    await tapControl(tester, 'make_bid');
    var choices = 0;
    while (!session.finished && choices < 52) {
      final view = session.view!;
      final owner = view.turn!.letter;
      final card = view.legalCards.first;
      if (choices == 0) {
        final source = find.byKey(Key('focus_drag_${owner}_${card.code}'));
        await tester.ensureVisible(source);
        await tester.pumpAndSettle();
        final drag = await tester.startGesture(tester.getCenter(source));
        await tester.pump(const Duration(milliseconds: 600));
        await drag.moveTo(tester.getCenter(
            find.byKey(const Key('focus_drop_zone'))));
        await tester.pump();
        await drag.up();
        await tester.pumpAndSettle();
        expect(session.view!.version, greaterThan(view.version));
      } else {
        await tapControl(tester, 'focus_card_${owner}_${card.code}');
      }
      choices++;
    }
    expect(choices, 26);
    expect(session.view!.completedTricks.length, 13);
    expect(session.view!.completedTricks.expand((t) => t.plays)
        .map((p) => p.card).toSet().length, 52);
    expect(find.byKey(const Key('focus_result')), findsOneWidget);
    expect(tester.takeException(), isNull);
    // pageBack() searches the English "Back" tooltip; this app is zh-TW.
    Navigator.of(tester.element(find.byKey(const Key('focus_result')))).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('final_result')), findsOneWidget);
  });

  testWidgets('REAL BROWSER: card renderer completes a full Demo board', (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tapControl(tester, 'new_game');
    await tapControl(tester, 'make_bid');
    var selections = 0;
    while (!session.finished && selections < 52) {
      final view = session.view!;
      expect(view.canAct, isTrue);
      final prefix = view.turn == view.viewer ? 'hand_card_' : 'dummy_card_';
      await tapControl(tester, '$prefix${view.legalCards.first.code}');
      selections++;
      if (selections == 2) {
        final version = session.view!.version;
        final hand = session.view!.ownCards;
        await tapControl(tester, 'nav_me');
        await tapControl(tester, 'reduce_motion');
        expect(tester.widget<SwitchListTile>(
          find.byKey(const Key('reduce_motion'))).value, isTrue);
        await tapControl(tester, 'nav_play');
        expect(session.view!.version, version);
        expect(session.view!.ownCards, hand);
      }
    }
    final terminal = session.view!;
    expect(session.finished, isTrue);
    expect(selections, 26); // North + its exposed South dummy.
    expect(terminal.completedTricks.length, 13);
    expect(terminal.completedTricks.expand((trick) => trick.plays)
      .map((play) => play.card).toSet().length, 52);
    expect(terminal.version, terminal.auction.length + 52);
    expect(terminal.remainingCards.values, everyElement(0));
    expect(terminal.nsScore, isNotNull);
    expect(find.byKey(const Key('final_result')), findsOneWidget);
    await tapControl(tester, 'nav_review');
    expect(find.byKey(const Key('history_panel')), findsOneWidget);
    await tapControl(tester, 'nav_play');
    expect(session.view!.version, terminal.version);
  });

  testWidgets('REAL BROWSER: language, pass out, restart, dummy play',
      (tester) async {
    final frameworkErrors = <String>[];
    final initialErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      frameworkErrors.add(details.exceptionAsString());
      initialErrorHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = initialErrorHandler);
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));

    expect(find.text('Bridge Academy｜橋牌學院'), findsOneWidget);
    await tapControl(tester, 'toggle_locale');
    expect(find.text('Bridge Academy'), findsOneWidget);
    await tapControl(tester, 'new_game');
    expect(session.view?.viewer, Seat.north);
    expect(session.view?.ownCards.length, 13);
    expect(session.view?.dummyCards, isNull);

    await tapControl(tester, 'pass');
    expect(session.finished, isTrue);
    expect(session.view!.auction.length, 4);
    expect(session.view!.nsScore, 0);
    expect(find.byKey(const Key('final_result')), findsOneWidget);
    expect(find.byKey(const Key('replay_panel')), findsOneWidget);
    expect(find.text('Event step: 4 / 4'), findsOneWidget);
    await tapControl(tester, 'replay_first');
    expect(find.text('Event step: 0 / 4'), findsOneWidget);
    await tapControl(tester, 'replay_next');
    expect(find.text('Event step: 1 / 4'), findsOneWidget);
    await tapControl(tester, 'replay_last');
    expect(find.text('Event step: 4 / 4'), findsOneWidget);

    await tapControl(tester, 'new_game');
    expect(find.byKey(const Key('replay_panel')), findsNothing);
    expect(session.finished, isFalse);
    expect(session.view!.auction, isEmpty);
    expect(find.byKey(const Key('final_result')), findsNothing);

    // Continue in the SAME Chrome test/browser lifecycle after restart.
    await tapControl(tester, 'make_bid');
    expect(session.view!.phase, Phase.play);
    expect(session.view!.dummyExposed, isTrue);
    expect(find.byKey(const Key('dummy_revealed')), findsOneWidget);
    final legal = session.view!.legalCards.first.code;
    final version = session.view!.version;
    try {
      await tapControl(tester, 'dummy_card_$legal');
    } catch (error) {
      fail('Dummy Chrome action: $error; underlying framework errors: '
          '${frameworkErrors.join(' / ')}');
    }
    expect(session.view!.version, greaterThan(version));
    expect(session.errorCode, isNull);
  });


  testWidgets('REAL BROWSER P1-A2: platform checkpoint survives new Session',
      (tester) async {
    final store = PreferencesSessionArchiveStore();
    await tester.runAsync(store.clear);
    addTearDown(() async { await store.clear(); });
    final original = BridgeSession(archiveStore: store);
    await tester.runAsync(() async {
      await original.newGame(boardNumber: 2, humanSeat: Seat.east);
      await original.submitCall(const Pass());
    });
    expect(original.finished, isTrue);
    final version = original.view!.version;
    original.dispose();

    final resumed = BridgeSession(archiveStore: store);
    addTearDown(resumed.dispose);
    final loaded = await tester.runAsync(resumed.restoreSavedGame);
    expect(loaded, isTrue);
    expect(resumed.board.number, 2);
    expect(resumed.view!.version, version);
    expect(resumed.completedReplay, isNotNull);
    await tester.pumpWidget(BridgeAcademyApp(session: resumed));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('restored_game')), findsOneWidget);
    expect(find.byKey(const Key('final_result')), findsOneWidget);
    expect(resumed.view!.dummyCards, isNull);
  });


}
