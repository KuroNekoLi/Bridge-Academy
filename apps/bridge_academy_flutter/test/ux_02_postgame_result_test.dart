import 'package:bridge_academy_flutter/src/app_copy.dart';
import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/completed_history_store.dart';
import 'package:bridge_academy_flutter/src/widgets/ux_postgame_result_panel.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _PassBot implements BotPolicy {
  @override
  Future<GameAction> choose(PlayerView view) async =>
      view.phase == Phase.auction
          ? CallAction(view.viewer, const Pass())
          : CardAction(view.viewer, view.turn!, view.legalCards.first);
}

BridgeSession _passSession() => BridgeSession(
      botFactory: (_) => _PassBot(),
      freshDealFactory: Deal.suitPerSeat,
      historyStore: MemoryCompletedHistoryStore(),
    );

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test('only Bridge Core finished views can become UX-02 results', () async {
    final session = _passSession();
    addTearDown(session.dispose);
    await session.newGame();
    expect(
      () => PostgameResult.fromFinishedView(
          view: session.view!, boardNumber: session.board.number,
          isJustDeclare: false),
      throwsStateError,
    );
    await session.submitCall(const Pass());
    expect(session.finished, true);
    final result = PostgameResult.fromFinishedView(
      view: session.view!, boardNumber: session.board.number,
      isJustDeclare: false,
    );
    expect(result.isPassOut, true);
    expect(result.declarerTricks, isNull);
    expect(result.target, isNull);
    expect(result.humanScore, 0);
    expect(session.view!.auction, hasLength(4));
    expect(session.view!.completedTricks, isEmpty);
  });

  test('real 13-trick Just Declare summary respects North and East score sign',
      () async {
    for (final human in [Seat.north, Seat.east]) {
      final session = BridgeSession(
        botFactory: (_) => const DeterministicTrainingBot(),
        freshDealFactory: Deal.suitPerSeat,
        historyStore: MemoryCompletedHistoryStore(),
      );
      try {
        await session.startJustDeclare(
          level: 3, strain: Strain.notrump, humanSeat: human,
        );
        expect(session.view!.auction, isEmpty);
        for (var i = 0; i < 52 && !session.finished; i++) {
          expect(session.view!.canAct, true);
          await session.submitCard(session.view!.legalCards.first);
        }
        expect(session.finished, true);
        final view = session.view!;
        final result = PostgameResult.fromFinishedView(
            view: view, boardNumber: session.board.number,
            isJustDeclare: session.isJustDeclare);
        expect(result.isJustDeclare, true);
        expect(result.target, 9);
        expect(view.completedTricks, hasLength(13));
        expect(result.declarerTricks,
            view.completedTricks.where((t) =>
                t.winner.isNS == view.contract!.declarer.isNS).length);
        expect(result.trickDifference, result.declarerTricks! - 9);
        expect(result.humanScore,
            human.isNS ? view.nsScore! : -view.nsScore!);
      } finally {
        session.dispose();
      }
    }
  });

  testWidgets('pass out -> result -> review -> back -> next is a real flow',
      (tester) async {
    final session = _passSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    expect(find.byKey(const Key('final_result')), findsNothing);
    await _tap(tester, 'new_game');
    expect(find.byKey(const Key('final_result')), findsNothing);
    await _tap(tester, 'pass');
    expect(find.byKey(const Key('final_result')), findsOneWidget);
    expect(find.byKey(const Key('ux02_pass_out')), findsOneWidget);
    expect(find.byKey(const Key('ux02_tricks')), findsNothing);
    expect(find.text('四家 Pass Out，0 分'), findsOneWidget);
    final v = session.view!.version;
    await _tap(tester, 'ux02_open_review');
    expect(find.byKey(const Key('replay_panel')), findsOneWidget);
    expect(session.view!.version, v);
    await _tap(tester, 'ux02_back_to_result');
    expect(find.byKey(const Key('final_result')), findsOneWidget);
    expect(session.view!.version, v);
    await _tap(tester, 'ux02_open_history');
    expect(find.byKey(const Key('final_result')), findsOneWidget);
    expect(session.view!.version, v);
    await _tap(tester, 'next_board');
    expect(session.finished, false);
    expect(session.board.number, 2);
    expect(find.byKey(const Key('final_result')), findsNothing);
  });

  testWidgets('Just Declare finished result uses practice label, not bid history',
      (tester) async {
    final session = BridgeSession(
      botFactory: (_) => const DeterministicTrainingBot(),
      freshDealFactory: Deal.suitPerSeat,
    );
    addTearDown(session.dispose);
    await session.startJustDeclare(level: 3, strain: Strain.notrump);
    for (var i = 0; i < 52 && !session.finished; i++) {
      await session.submitCard(session.view!.legalCards.first);
    }
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    expect(find.byKey(const Key('ux02_declarer_practice')), findsOneWidget);
    expect(find.byKey(const Key('ux02_tricks')), findsOneWidget);
    expect(find.byKey(const Key('next_board')), findsNothing);
    expect(find.byKey(const Key('replay_same_board')), findsOneWidget);
    await _tap(tester, 'toggle_locale');
    expect(find.text('Declarer-only practice (no auction)'), findsOneWidget);
    await _tap(tester, 'replay_same_board');
    expect(session.isJustDeclare, true);
    expect(session.finished, false);
    expect(session.view!.auction, isEmpty);
  });

  testWidgets('a blocked next-board action never calls mutation callback',
      (tester) async {
    final session = _passSession();
    addTearDown(session.dispose);
    await session.newGame();
    await session.submitCall(const Pass());
    var calls = 0;
    final result = PostgameResult.fromFinishedView(
        view: session.view!, boardNumber: session.board.number,
        isJustDeclare: false);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: UxPostgameResultPanel(
          copy: const AppCopy(true),
          result: result,
          advance: PostgameAdvance.nextBoard,
          canChangeBoard: false,
          canReview: false,
          canHistory: false,
          canRetry: false,
          reviewFocused: false,
          blocked: true,
          onNext: () => calls++,
          onRetry: () => calls++,
          onReview: () => calls++,
          onHistory: () => calls++,
          onBackToResult: () => calls++,
        ),
      ),
    ));
    final button = tester.widget<FilledButton>(
        find.byKey(const Key('next_board')));
    expect(button.onPressed, isNull);
    expect(find.byKey(const Key('ux02_guard')), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('result actions wrap on 320px with 2x text scale',
      (tester) async {
    final session = _passSession();
    addTearDown(session.dispose);
    await session.newGame();
    await session.submitCall(const Pass());
    final result = PostgameResult.fromFinishedView(
        view: session.view!, boardNumber: session.board.number,
        isJustDeclare: false);
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
            size: Size(320, 760), textScaler: TextScaler.linear(2)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: UxPostgameResultPanel(
              copy: const AppCopy(false),
              result: result,
              advance: PostgameAdvance.fourBoard,
              canChangeBoard: true,
              canReview: true,
              canHistory: false,
              canRetry: false,
              reviewFocused: false,
              blocked: false,
              onNext: () {},
              onRetry: () {},
              onReview: () {},
              onHistory: () {},
              onBackToResult: () {},
            ),
          ),
        ),
      ),
    ));
    expect(find.byKey(const Key('next_practice_board')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
