import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/app_copy.dart';
import 'package:bridge_academy_flutter/src/widgets/dds_review_section.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_dds_adapter/bridge_dds_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FixedDds implements DoubleDummyAnalyzer {
  int calls = 0;
  @override
  Future<DoubleDummyTable> analyze(TrustedCompletedBoard board) async {
    calls++;
    return DoubleDummyTable.fromWorkerResponse({
      'schemaVersion': 1,
      'solverCommit': DoubleDummyTable.upstreamCommit,
      'engine': 'dds3-python-calc_dd_table',
      'resTable': [
        [7, 6, 7, 6], [8, 5, 8, 5], [9, 4, 9, 4],
        [10, 3, 10, 3], [11, 2, 11, 2],
      ],
    }, board);
  }
}

void main() {
  test('C1.5 never gives DDS an unfinished or Pass Out board', () async {
    final solver = _FixedDds();
    final session = BridgeSession(ddsAnalyzer: solver);
    addTearDown(session.dispose);
    await expectLater(session.analyzeCompletedDds(),
        throwsA(isA<DoubleDummyAnalysisException>()
            .having((e) => e.code, 'code', DoubleDummyFailureCode.notFinished)));
    expect(solver.calls, 0);
    await session.newGame();
    await session.submitCall(const Pass());
    await expectLater(session.analyzeCompletedDds(),
        throwsA(isA<DoubleDummyAnalysisException>()
            .having((e) => e.code, 'code', DoubleDummyFailureCode.notFinished)));
    expect(solver.calls, 0);
  });

  testWidgets('C1.5 DDS table renders 20 typed values with bilingual caveat',
      (tester) async {
    final board = TrustedCompletedBoard.explicitTeachingFixture(
        originalDeal: Deal.suitPerSeat(), dealer: Seat.north,
        vulnerability: Vulnerability.none);
    final solver = _FixedDds();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body:
      DdsReviewSection(copy: const AppCopy(false),
          onAnalyze: () => solver.analyze(board)))));
    await tester.tap(find.byKey(const Key('dds_analyze')));
    await tester.pumpAndSettle();
    expect(solver.calls, 1);
    expect(find.byKey(const Key('dds_table')), findsOneWidget);
    expect(find.byKey(const Key('dds_result')), findsOneWidget);
    expect(find.byKey(const Key('dds_caveat')), findsOneWidget);
  });

  testWidgets('C1.5 unsupported worker fails closed without table',
      (tester) async {
    final board = TrustedCompletedBoard.explicitTeachingFixture(
        originalDeal: Deal.suitPerSeat(), dealer: Seat.north,
        vulnerability: Vulnerability.none);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body:
      DdsReviewSection(copy: const AppCopy(true),
          onAnalyze: () =>
              const UnsupportedDoubleDummyAnalyzer().analyze(board)))));
    await tester.tap(find.byKey(const Key('dds_analyze')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dds_error')), findsOneWidget);
    expect(find.byKey(const Key('dds_table')), findsNothing);
    expect(find.textContaining('DDS unavailable'), findsOneWidget);
  });
}
