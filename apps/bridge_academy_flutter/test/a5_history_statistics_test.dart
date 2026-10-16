import 'package:bridge_academy_flutter/src/app_copy.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/completed_history_store.dart';
import 'package:bridge_academy_flutter/src/history_statistics.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_history_panel.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

HistorySummary _entry(
    String id, Seat seat, String contract, int score, bool? made,
    {bool practice = false}) =>
    HistorySummary(
      id: id,
      savedAt: DateTime.utc(2026, 10, 16),
      boardNumber: int.parse(id.split('_').last),
      humanSeat: seat,
      contract: contract,
      score: score,
      tricks: contract == 'PASS OUT' ? 0 : 13,
      isPractice: practice,
      contractMade: made,
    );

final _history = [
  _entry('board_1', Seat.north, '3NT', 400, true),
  _entry('board_2', Seat.east, '4S', 100, false),
  _entry('board_3', Seat.south, '2H', -50, false),
  _entry('board_4', Seat.west, '2S', -110, true),
  _entry('board_5', Seat.north, 'PASS OUT', 0, null, practice: true),
];

void main() {
  test('statistics correctly separate contracts, Pass Out and human score',
      () {
    final result = HistoryStatistics.from(_history);
    expect(result.boards, 5);
    expect(result.contracts, 4);
    expect(result.knownContractOutcomes, 4);
    expect(result.made, 2);
    expect(result.madePercent, 50);
    expect(result.passOut, 1);
    expect(result.practice, 1);
    // West scores +110 from -110 NS; East scores -100 from +100 NS.
    expect(result.netHumanScore, 360);
    final noGames = HistoryStatistics.from(const <HistorySummary>[]);
    expect(noGames.madePercent, isNull);
    expect(noGames.netHumanScore, 0);
  });

  test('unknown old fixture outcome never counts as a failed contract', () {
    final stats = HistoryStatistics.from([
      _entry('board_6', Seat.north, '3NT', 400, null),
    ]);
    expect(stats.contracts, 1);
    expect(stats.knownContractOutcomes, 0);
    expect(stats.madePercent, isNull);
  });

  test('verified terminal Core result populates declarer made flag', () async {
    final session = BridgeSession(historyStore: MemoryCompletedHistoryStore());
    addTearDown(session.dispose);
    await session.newGame(humanSeat: Seat.north);
    await session.submitCall(const Bid(1, Strain.notrump));
    for (var i = 0; i < 60 && !session.finished; i++) {
      final view = session.view!;
      expect(view.canAct, true);
      await session.submitCard(view.legalCards.first);
    }
    expect(session.finished, true);
    final summary = session.completedHistory.single;
    final view = session.view!;
    expect(view.completedTricks, hasLength(13));
    final declarer = view.contract!.declarer;
    final declarerTricks = view.completedTricks.where(
      (t) => t.winner.isNS == declarer.isNS,
    ).length;
    expect(summary.contractMade,
        declarerTricks >= view.contract!.targetTricks);
    expect(summary.score, view.nsScore);
    expect(summary.contract, view.contract!.label);
  });

  testWidgets('history stats are visible, localized and follow search/filter',
      (tester) async {
    Future<void> pumpPanel(AppCopy copy) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BridgeHistoryPanel(
              history: _history,
              copy: copy,
              selectedId: null,
              selectedReplay: null,
              replayIndex: 0,
              onSelect: (_) {},
              onReplayStep: (_) {},
              onDelete: (_) async {},
              errorCode: null,
              onRetrySave: null,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    await pumpPanel(const AppCopy(false));
    expect(find.byKey(const Key('history_statistics')), findsOneWidget);
    expect(find.text('完成副數: 5'), findsOneWidget);
    expect(find.text('定約成功率: 2/4 (50%)'), findsOneWidget);
    expect(find.text('玩家視角累積分: +360'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('history_search')), '3NT');
    await tester.pumpAndSettle();
    expect(find.text('完成副數: 1'), findsOneWidget);
    expect(find.text('定約成功率: 1/1 (100%)'), findsOneWidget);
    expect(find.text('玩家視角累積分: +400'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('history_search')), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history_filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('四家不叫').last);
    await tester.pumpAndSettle();
    expect(find.text('完成副數: 1'), findsOneWidget);
    expect(find.text('定約成功率: 尚無資料'), findsOneWidget);
    expect(find.text('玩家視角累積分: 0'), findsOneWidget);

    await pumpPanel(const AppCopy(true));
    expect(find.text('Recent deal statistics'), findsOneWidget);
  });
}
