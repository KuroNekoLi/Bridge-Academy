import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Separate flutter drive invocation from restore test. Leaves checkpoint
/// intact for a real Android force-stop and fresh app process.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('A2.3 process A: commit mid-trick checkpoint', (tester) async {
    final store = PreferencesSessionArchiveStore();
    final preferences = SharedPreferencesAsync();
    await tester.runAsync(() async {
      await store.clear();
      await preferences.remove('bridge_qa.a23.version');
      await preferences.remove('bridge_qa.a23.fingerprint');
    });
    final session = BridgeSession(archiveStore: store);
    addTearDown(session.dispose);

    await tester.runAsync(() async {
      await session.newGame(
        boardNumber: 1,
        humanSeat: Seat.north,
        mode: OpponentMode.demo,
        boardMode: BoardMode.training,
      );
      await session.submitCall(const Bid(1, Strain.notrump));
      final view = session.view!;
      expect(view.phase, Phase.play);
      expect(view.dummyExposed, true);
      expect(view.turn, Seat.south);
      expect(view.legalCards, isNotEmpty);
      await session.submitCard(view.legalCards.first);
    });

    final current = session.view!;
    expect(session.finished, false);
    expect(current.version, greaterThan(5));
    expect(current.dummyExposed, true);
    expect(current.auction.length, 4);
    expect(current.completedTricks.length, lessThan(13));
    expect(session.saveFailed, false);
    final raw = await tester.runAsync(store.read);
    expect(raw, isNotNull);
    final saved = SavedBoardCodec.decode(raw!);
    expect(saved.board.number, 1);
    expect(saved.state.version, current.version);

    await tester.runAsync(() async {
      await preferences.setInt('bridge_qa.a23.version', current.version);
      await preferences.setString(
        'bridge_qa.a23.fingerprint', saved.state.historyFingerprint,
      );
    });

    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('board_number')), findsOneWidget);
    expect(find.byKey(const Key('dummy_revealed')), findsOneWidget);
    expect(tester.takeException(), isNull);
    // ignore: avoid_print
    print('A2_3_ANDROID_PROCESS_A_PASS');
    // Never clear here: the runner must restart a NEW app process.
  });
}

