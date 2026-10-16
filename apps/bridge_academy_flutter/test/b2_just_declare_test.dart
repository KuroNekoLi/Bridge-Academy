import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/completed_history_store.dart';
import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryArchive implements SessionArchiveStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String archive) async { value = archive; }

  @override
  Future<void> clear() async { value = null; }
}

BridgeSession _session({
  _MemoryArchive? archive,
  CompletedHistoryStore? history,
}) => BridgeSession(
  freshDealFactory: Deal.suitPerSeat,
  botFactory: (_) => const DeterministicTrainingBot(),
  archiveStore: archive,
  historyStore: history,
);

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test('B2 session begins declarer practice and resumes without fake bids',
      () async {
    final archive = _MemoryArchive();
    final history = MemoryCompletedHistoryStore();
    final first = _session(archive: archive, history: history);
    await first.startJustDeclare(level: 4, strain: Strain.hearts);
    expect(first.isJustDeclare, true);
    expect(first.mode, OpponentMode.demo);
    expect(first.view!.contract!.label, '4H');
    expect(first.view!.contract!.declarer, Seat.north);
    expect(first.view!.phase, Phase.play);
    expect(first.view!.auction, isEmpty);
    expect(first.view!.dummyExposed, true);
    expect(first.view!.turn, Seat.south);
    final originalVersion = first.view!.version;
    await first.submitCall(const Pass());
    expect(first.view!.version, originalVersion);
    first.dispose();

    final resumed = _session(archive: archive, history: history);
    addTearDown(resumed.dispose);
    expect(await resumed.restoreSavedGame(), true);
    expect(resumed.isJustDeclare, true);
    expect(resumed.view!.contract!.label, '4H');
    expect(resumed.view!.auction, isEmpty);
    expect(resumed.view!.dummyExposed, true);

    for (var n = 0; n < 52 && !resumed.finished; n++) {
      final view = resumed.view!;
      expect(view.canAct, true);
      await resumed.submitCard(view.legalCards.first);
    }
    expect(resumed.finished, true);
    expect(resumed.view!.version, 52);
    expect(resumed.view!.completedTricks.length, 13);
    expect(resumed.completedHistory, hasLength(1));
    expect(resumed.completedHistory.single.isPractice, true);
    final replay = resumed.historyReplay(resumed.completedHistory.single.id)!;
    expect(replay.frames.first.view.auction, isEmpty);
    expect(replay.frames.first.view.phase, Phase.play);
    // Never serialize a made-up auction to a supposedly regular PBN export.
    expect(resumed.exportHistoryPbn(resumed.completedHistory.single.id), isNull);
    await resumed.replaySameBoard();
    expect(resumed.isJustDeclare, true);
    expect(resumed.view!.contract!.label, '4H');
    expect(resumed.view!.version, 1);
  });

  testWidgets('B2 visible zh-TW/en launch controls and exposed dummy', (
    tester,
  ) async {
    final session = _session(history: MemoryCompletedHistoryStore());
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    expect(find.byKey(const Key('start_just_declare')), findsOneWidget);
    await _tap(tester, 'start_just_declare');
    expect(find.byKey(const Key('just_declare_active')), findsOneWidget);
    expect(find.byKey(const Key('replay_panel')), findsNothing);
    expect(session.isJustDeclare, true);
    expect(session.view!.contract!.label, '3NT');
    expect(session.view!.auction, isEmpty);
    expect(session.view!.dummyExposed, true);
    expect(find.byKey(const Key('dummy_card_' + 'HA')), findsOneWidget);
    await _tap(tester, 'toggle_locale');
    expect(find.textContaining('Declarer practice:'), findsOneWidget);
    expect(find.text('Just Declare practice'), findsOneWidget);
  });
}
