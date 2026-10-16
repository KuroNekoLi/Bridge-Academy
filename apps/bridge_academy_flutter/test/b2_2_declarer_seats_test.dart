import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/completed_history_store.dart';
import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Archive implements SessionArchiveStore {
  String? current;
  @override
  Future<String?> read() async => current;
  @override
  Future<void> write(String archive) async { current = archive; }
  @override
  Future<void> clear() async { current = null; }
}

BridgeSession _practice(_Archive archive,
    MemoryCompletedHistoryStore history) => BridgeSession(
  freshDealFactory: Deal.suitPerSeat,
  botFactory: (_) => const DeterministicTrainingBot(),
  archiveStore: archive,
  historyStore: history,
);

void main() {
  test('B2.2 any N/E/S/W can be declarer; own+dummy only after lead', () async {
    for (final seat in Seat.values) {
      final archive = _Archive();
      final history = MemoryCompletedHistoryStore();
      final session = _practice(archive, history);
      await session.startJustDeclare(
          level: 3, strain: Strain.notrump, humanSeat: seat);
      expect(session.started, true, reason: seat.letter);
      expect(session.isJustDeclare, true);
      expect(session.mode, OpponentMode.demo);
      final view = session.view!;
      expect(view.viewer, seat);
      expect(view.contract!.declarer, seat);
      expect(view.contract!.dummy, seat.partner);
      expect(view.auction, isEmpty);
      expect(view.phase, Phase.play);
      expect(view.dummyExposed, true);
      expect(view.version, 1); // Real Core lead: no fake auction.
      expect(view.turn, seat.partner);
      expect(view.canAct, true);
      expect(view.ownCards.length, 13);
      expect(view.dummyCards!.length, 13);
      expect(view.toJson().containsKey('hands'), false);

      // One actual player action, then a new process-like session restore.
      await session.submitCard(view.legalCards.first);
      final committedVersion = session.view!.version;
      session.dispose();
      final resumed = _practice(archive, history);
      addTearDown(resumed.dispose);
      expect(await resumed.restoreSavedGame(), true);
      expect(resumed.humanSeat, seat);
      expect(resumed.isJustDeclare, true);
      expect(resumed.view!.contract!.declarer, seat);
      expect(resumed.view!.version, committedVersion);

      // A completed training attempt can replay exactly the same Deal
      // and training contract instead of manufacturing regular bids.
      for (var n = 0; n < 52 && !resumed.finished; n++) {
        final state = resumed.view!;
        expect(state.canAct, true);
        await resumed.submitCard(state.legalCards.first);
      }
      expect(resumed.finished, true);
      expect(resumed.view!.auction, isEmpty);
      expect(resumed.completedHistory, hasLength(1));
      await resumed.replaySameBoard();
      expect(resumed.isJustDeclare, true);
      expect(resumed.view!.contract!.declarer, seat);
      expect(resumed.view!.auction, isEmpty);
    }
  });

  test('B2.2 rejects level 0/8 and cannot interrupt live auction', () async {
    final session = _practice(_Archive(), MemoryCompletedHistoryStore());
    addTearDown(session.dispose);
    await expectLater(
        session.startJustDeclare(level: 0, strain: Strain.notrump),
        throwsArgumentError);
    await expectLater(
        session.startJustDeclare(level: 8, strain: Strain.notrump),
        throwsArgumentError);
    expect(session.started, false);
    await session.newGame();
    final version = session.view!.version;
    await session.startJustDeclare(
        level: 4, strain: Strain.spades, humanSeat: Seat.west);
    expect(session.isJustDeclare, false);
    expect(session.view!.version, version);
    expect(session.humanSeat, Seat.north);
  });

  testWidgets('B2.2 real UI displays training target and localized seats',
      (tester) async {
    final session = _practice(_Archive(), MemoryCompletedHistoryStore());
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    final start = find.byKey(const Key('start_just_declare'));
    await tester.ensureVisible(start);
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('just_declare_active')), findsOneWidget);
    expect(find.byKey(const Key('just_declare_goal')), findsOneWidget);
    expect(find.textContaining('莊家方已贏墩數／定約目標'), findsOneWidget);
    await tester.tap(find.byKey(const Key('toggle_locale')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Declarer tricks / contract target'),
        findsOneWidget);
    expect(find.textContaining('Rules-demo Bot only'), findsOneWidget);
  });
}
