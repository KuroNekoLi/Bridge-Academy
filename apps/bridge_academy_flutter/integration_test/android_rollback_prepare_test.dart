import 'dart:convert';

import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Process A: leave a committed latest slot corrupt and a valid previous
/// generation on Android's actual app-private SharedPreferences backend.
/// The corruption is intentional fault injection, NOT a simulated recovery.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('A2.6 process A: corrupt active slot, preserve previous commit',
      (tester) async {
    final prefs = SharedPreferencesAsync();
    final store = PreferencesSessionArchiveStore();
    await tester.runAsync(store.clear);
    final board = BoardDefinition.forNumber(1);
    final game = SinglePlayerCoordinator(
      deal: Deal.suitPerSeat(),
      dealer: board.dealer,
      vulnerability: board.vulnerability,
      humanSeat: Seat.north,
      bot: const DeterministicTrainingBot(),
    );
    String snapshot() => SavedBoardCodec.encode(
      board: board,
      humanSeat: Seat.north,
      opponentMode: 'demo',
      boardMode: 'training',
      coordinator: game,
    );
    await tester.runAsync(() async {
      await store.write(snapshot()); // Slot A, generation 1, human to act.
      game.submitHuman(
        const CallAction(Seat.north, Pass()), expectedVersion: 0,
      );
      await store.write(snapshot()); // Slot B, generation 2.
    });

    final before = await tester.runAsync(() async {
      final marker = await prefs.getString(
          PreferencesSessionArchiveStore.activeKey);
      return jsonDecode(marker!) as Map<String, dynamic>;
    });
    expect(before!['slot'], 'b');
    expect(before['generation'], 2);
    await tester.runAsync(() async {
      await prefs.setString(
        PreferencesSessionArchiveStore.slotBKey, 'torn-active-checkpoint',
      );
    });
    expect(await prefs.getString(PreferencesSessionArchiveStore.slotAKey),
        isNotNull);
    expect(await prefs.getString(PreferencesSessionArchiveStore.slotBKey),
        'torn-active-checkpoint');
    // DO NOT call store.read() here: Android process B must discover it.
    // ignore: avoid_print
    print('A2_6_PROCESS_A_COMMITTED_CORRUPTION_PASS');
  });
}

