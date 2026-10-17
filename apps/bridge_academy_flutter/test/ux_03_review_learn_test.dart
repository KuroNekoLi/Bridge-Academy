import 'package:bridge_academy_flutter/src/academy/academy_page.dart';
import 'package:bridge_academy_flutter/src/academy/academy_catalog.dart';
import 'package:bridge_academy_flutter/src/academy/academy_models.dart';
import 'package:bridge_academy_flutter/src/bridge_app.dart';
import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/completed_history_store.dart';
import 'package:bridge_academy_flutter/src/experience/review_learning/review_learning_map.dart';
import 'package:bridge_academy_flutter/src/learning_progress/learner_store.dart';
import 'package:bridge_academy_flutter/src/review/review_timeline.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CompletedReplay makeReplay(List<Call> calls, {Deal? deal}) {
  var game = GameState.start(
      deal ?? Deal.suitPerSeat(), Seat.north, Vulnerability.none);
  final frames = <ReplayFrame>[
    ReplayFrame(PlayerView.forSeat(game, Seat.north), null),
  ];
  for (final call in calls) {
    game = BridgeGame.apply(game, CallAction(game.turn!, call));
    frames.add(ReplayFrame(PlayerView.forSeat(game, Seat.north),
        game.events.last.action));
  }
  while (!game.isFinished) {
    final owner = game.turn!;
    final action = CardAction(
        game.actorToPlay!, owner, game.legalCards(owner).first);
    game = BridgeGame.apply(game, action);
    frames.add(ReplayFrame(PlayerView.forSeat(game, Seat.north), action));
  }
  return CompletedReplay(frames, game.historyFingerprint);
}

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 160,
        scrollable: find.byType(Scrollable).last, maxScrolls: 40);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  const passes = [Pass(), Pass(), Pass(), Pass()];

  test('UX-03 only supports explicit Core rules and compatible catalog IDs', () {
    final timeline = ReviewTimeline.fromReplay(makeReplay(passes));
    expect(ReviewLearningMap.forStep(timeline.steps.first), isNull);
    final dest = ReviewLearningMap.forStep(timeline.steps.last)!;
    expect(dest.lessonId, 'b4.play-and-contract');
    expect(dest.questionId, 'b4.play.pass-out');
    expect(dest.schemaVersion, AcademyValidator.schemaVersion);
    expect(ReviewLearningMap.forStep(timeline.steps.last, catalog: []), isNull);
    final incompatible = AcademyCatalog.validated()
        .where((lesson) => lesson.lessonId != dest.lessonId).toList();
    expect(ReviewLearningMap.forStep(
        timeline.steps.last, catalog: incompatible), isNull);

    final fake = ReviewStep(
      index: timeline.lastIndex,
      frame: timeline.steps.last.frame,
      eventType: ReviewEventType.auction,
      trickNumber: 0,
      insights: const [
        ReviewInsight('reviewPassOutRule', ReviewEvidence.convention),
        ReviewInsight('reviewPassOutRule', ReviewEvidence.unknown),
      ],
      isKeyEvent: true,
    );
    expect(ReviewLearningMap.forStep(fake), isNull);
  });

  test('UX-03 validated follow suit maps only to original authored lesson', () {
    final timeline = ReviewTimeline.fromReplay(makeReplay(const [
      Bid(1, Strain.notrump), Pass(), Pass(), Pass(),
    ], deal: Deal.fromPbn('N:AJ5.KQ7.A982.K76 32.9843.J73.Q943 '
        'QT6.AJ6.KT6.JT52 K9874.T52.Q54.A8')));
    final step = timeline.steps.firstWhere((s) =>
        s.insights.any((i) => i.key == 'reviewFollowSuit'));
    expect(ReviewLearningMap.forStep(step)!.questionId,
        'b4.play.follow-suit');
    expect(step.frame.view.toJson().containsKey('hands'), false);
  });

  testWidgets('UX-03 terminal replay → target question → original step',
      (tester) async {
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tapKey(tester, 'new_game');
    expect(find.byKey(const Key('ux03_practice_concept')), findsNothing);
    await tapKey(tester, 'pass');
    expect(find.text('事件步驟: 4 / 4'), findsOneWidget);
    await tapKey(tester, 'ux03_practice_concept');
    expect(find.byKey(const Key('academy_question_b4.play.pass-out')),
        findsOneWidget);
    await tapKey(tester, 'academy_option_a');
    await tapKey(tester, 'academy_submit');
    expect(find.byKey(const Key('academy_correct')), findsOneWidget);
    await tapKey(tester, 'ux03_return_review');
    expect(find.text('事件步驟: 4 / 4'), findsOneWidget);
    await tapKey(tester, 'replay_first');
    expect(find.byKey(const Key('ux03_no_matching_lesson')), findsOneWidget);
    expect(find.byKey(const Key('ux03_practice_concept')), findsNothing);
  });

  testWidgets('UX-03 historical replay route keeps board ID and step',
      (tester) async {
    final session = BridgeSession(historyStore: MemoryCompletedHistoryStore());
    addTearDown(session.dispose);
    await tester.pumpWidget(BridgeAcademyApp(session: session));
    await tapKey(tester, 'new_game');
    await tapKey(tester, 'pass');
    await tapKey(tester, 'next_board');
    await tapKey(tester, 'history_toggle');
    final id = session.completedHistory.single.id;
    await tapKey(tester, 'history_item_$id');
    await tapKey(tester, 'review_next_key');
    expect(find.text('事件步驟: 4 / 4'), findsOneWidget);
    await tapKey(tester, 'ux03_practice_concept');
    expect(find.byKey(const Key('academy_question_b4.play.pass-out')),
        findsOneWidget);
    await tapKey(tester, 'ux03_return_review');
    expect(find.byKey(Key('history_item_$id')), findsOneWidget);
    expect(find.text('事件步驟: 4 / 4'), findsOneWidget);
  });

  testWidgets('UX-03 direct question respects opt-out and stale ID',
      (tester) async {
    final store = MemoryLearnerStore();
    await tester.pumpWidget(MaterialApp(home: AcademyPage(
      isEnglish: true,
      learnerStore: store,
      initialLessonId: 'b4.play-and-contract',
      initialQuestionId: 'b4.play.pass-out',
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('academy_question_b4.play.pass-out')),
        findsOneWidget);
    await tapKey(tester, 'academy_option_a');
    await tapKey(tester, 'academy_submit');
    expect(find.byKey(const Key('academy_correct')), findsOneWidget);
    expect(await store.read(), isNull);
    await tester.pumpWidget(const MaterialApp(home: AcademyPage(
      isEnglish: true,
      initialLessonId: 'b4.play-and-contract',
      initialQuestionId: 'outdated-question',
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ux03_invalid_lesson')), findsOneWidget);
    expect(find.byKey(const Key('academy_lesson_list')), findsOneWidget);
  });

  testWidgets('UX-03 narrow 320px with 2x text remains operable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = BridgeSession();
    addTearDown(session.dispose);
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: BridgeAcademyApp(session: session),
    ));
    await tapKey(tester, 'new_game');
    await tapKey(tester, 'pass');
    await tapKey(tester, 'ux03_practice_concept');
    expect(find.byKey(const Key('academy_question_b4.play.pass-out')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
