import 'dart:convert';

import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/session_persistence.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryArchive implements SessionArchiveStore {
  String? archive;
  int writes = 0;
  bool failNextWrite = false;

  @override
  Future<String?> read() async => archive;

  @override
  Future<void> write(String raw) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('Disk unavailable'); // Never surfaced to UI.
    }
    writes++;
    archive = raw;
  }

  @override
  Future<void> clear() async {
    archive = null;
  }
}

void main() {
  test('P1-A2: pass-out persists and reopens with exact board and replay',
      () async {
    final store = _MemoryArchive();
    final before = BridgeSession(archiveStore: store);
    await before.newGame(boardNumber: 2, humanSeat: Seat.east,
        boardMode: BoardMode.fresh);
    expect(store.writes, 1); // Board checkpoint before bot actions.
    expect(before.view!.version, 0);
    await before.submitCall(const Pass());
    expect(before.finished, isTrue);
    final eventVersion = before.view!.version;
    final lastFingerprint = before.completedReplay!.historyFingerprint;
    final own = before.view!.ownCards.toSet();
    before.dispose(); // Simulated process/component disposal.

    final after = BridgeSession(archiveStore: store);
    addTearDown(after.dispose);
    expect(await after.restoreSavedGame(), isTrue);
    expect(after.restoredFromStorage, isTrue);
    expect(after.board.number, 2);
    expect(after.humanSeat, Seat.east);
    expect(after.mode, OpponentMode.demo);
    expect(after.boardMode, BoardMode.fresh);
    expect(after.view!.dealer, Seat.east);
    expect(after.view!.vulnerability, Vulnerability.ns);
    expect(after.view!.version, eventVersion);
    expect(after.view!.ownCards.toSet(), own);
    expect(after.view!.nsScore, 0);
    expect(after.completedReplay!.historyFingerprint, lastFingerprint);
    expect(after.view!.toJson().containsKey('dealPbn'), isFalse);
    expect(after.view!.toJson().containsKey('hands'), isFalse);
    expect(after.view!.dummyCards, isNull);

    await after.nextBoard();
    expect(after.board.number, 3);
    expect(after.view!.vulnerability, Vulnerability.ew);
    expect(after.view!.dealer, Seat.south);
    expect(after.view!.phase, Phase.auction);
    expect(after.view!.canAct, isTrue);
  });

  test('P1-A2: midtrick restore preserves dummy and legal playable cards',
      () async {
    final store = _MemoryArchive();
    final before = BridgeSession(archiveStore: store);
    await before.newGame(humanSeat: Seat.north);
    await before.submitCall(const Bid(1, Strain.notrump));
    expect(before.view!.dummyExposed, isTrue);
    expect(before.view!.turn, Seat.south);
    final dummyCard = before.view!.legalCards.first;
    await before.submitCard(dummyCard);
    expect(before.view!.phase, Phase.play);
    final savedVersion = before.view!.version;
    final savedAuction = before.view!.auction.length;
    final savedCurrent = before.view!.currentTrick.length;
    final fingerprint = SavedBoardCodec.decode(store.archive!).state
        .historyFingerprint;
    before.dispose();

    final after = BridgeSession(archiveStore: store);
    addTearDown(after.dispose);
    expect(await after.restoreSavedGame(), isTrue);
    expect(after.view!.version, savedVersion);
    expect(after.view!.auction.length, savedAuction);
    expect(after.view!.currentTrick.length, savedCurrent);
    expect(after.view!.dummyExposed, isTrue);
    expect(after.view!.dummyCards, isNotNull);
    expect(after.view!.ownCards.length, 13);
    expect(SavedBoardCodec.decode(store.archive!).state.historyFingerprint,
        fingerprint);
    expect(after.completedReplay, isNull);
    expect(after.view!.toJson().containsKey('dealPbn'), isFalse);
  });

  test('P1-A2: failed write blocks AI advancement until retry succeeds',
      () async {
    final store = _MemoryArchive();
    final session = BridgeSession(archiveStore: store);
    addTearDown(session.dispose);
    await session.newGame();
    store.failNextWrite = true;
    await session.submitCall(const Bid(1, Strain.notrump));
    expect(session.saveFailed, isTrue);
    expect(session.errorCode, 'errorSave');
    expect(session.view!.version, 1);
    expect(SavedBoardCodec.decode(store.archive!).state.version, 0,
        reason: 'Durable version remains previous committed checkpoint');

    // Same current board version may not be applied twice.
    await session.submitCall(const Pass());
    expect(session.view!.version, 1);
    await session.retrySave();
    expect(session.saveFailed, isFalse);
    expect(session.errorCode, isNull);
    expect(session.view!.phase, Phase.play);
    expect(session.view!.dummyExposed, isTrue);
    expect(SavedBoardCodec.decode(store.archive!).state.version,
        session.view!.version);
  });

  test('P1-A2: corrupted version / board metadata / event is rejected',
      () async {
    final store = _MemoryArchive();
    final initial = BridgeSession(archiveStore: store);
    await initial.newGame(boardNumber: 2, humanSeat: Seat.east);
    await initial.submitCall(const Pass());
    initial.dispose();
    final original = jsonDecode(store.archive!) as Map<String, dynamic>;

    for (final mutated in <Map<String, dynamic>>[
      {...original, 'schemaVersion': 99},
      {...original, 'boardNumber': 1},
      {...original, 'eventVersion': 99},
      {...original, 'historyFingerprint': 'garbage'},
      {...original, 'humanSeat': 'Z'},
      {...original, 'opponentMode': 'silent-fallback'},
      {...original, 'transcript': <String, dynamic>{
        ...(original['transcript'] as Map<String, dynamic>),
        'events': [
          {'version': 999, 'type': 'call',
           'actor': 'E', 'call': 'PASS'}
        ],
      }},
    ]) {
      store.archive = jsonEncode(mutated);
      final rejected = BridgeSession(archiveStore: store);
      expect(await rejected.restoreSavedGame(), isFalse);
      expect(rejected.view, isNull);
      expect(rejected.errorCode, 'errorCorruptSave');
      rejected.dispose();
    }
    store.archive = 'not json';
    final corrupt = BridgeSession(archiveStore: store);
    expect(await corrupt.restoreSavedGame(), isFalse);
    expect(corrupt.errorCode, 'errorCorruptSave');
    await corrupt.newGame();
    expect(corrupt.started, isTrue);
    expect(corrupt.errorCode, isNull);
    corrupt.dispose();
  });

  testWidgets('P1-A2: restored terminal game renders only filtered hands',
      (tester) async {
    final store = _MemoryArchive();
    final original = BridgeSession(archiveStore: store);
    await original.newGame();
    await original.submitCall(const Pass());
    original.dispose();

    final restored = BridgeSession(archiveStore: store);
    addTearDown(restored.dispose);
    expect(await restored.restoreSavedGame(), isTrue);
    await tester.pumpWidget(BridgeAcademyApp(session: restored));
    expect(find.byKey(const Key('restored_game')), findsOneWidget);
    expect(find.byKey(const Key('board_number')), findsOneWidget);
    expect(find.byKey(const Key('final_result')), findsOneWidget);
    expect(find.byKey(const Key('replay_panel')), findsOneWidget);
    expect(find.byKey(const Key('dummy_revealed')), findsNothing);
    expect(find.text('♠3'), findsNothing); // Hidden East card.
    expect(tester.takeException(), isNull);
  });
}
