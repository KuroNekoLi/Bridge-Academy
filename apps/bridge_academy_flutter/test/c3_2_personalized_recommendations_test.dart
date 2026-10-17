import 'package:bridge_academy_flutter/src/academy/academy_catalog.dart';
import 'package:bridge_academy_flutter/src/academy/academy_models.dart';
import 'package:bridge_academy_flutter/src/academy/academy_page.dart';
import 'package:bridge_academy_flutter/src/learning_progress/learner_progress.dart';
import 'package:bridge_academy_flutter/src/learning_progress/learner_store.dart';
import 'package:bridge_academy_flutter/src/learning_progress/learning_recommendations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final lessons = AcademyCatalog.validated();
final now = DateTime.utc(2026, 10, 17);

LearnerAttempt attempt(AcademyLesson lesson, int index, String id,
    bool correct, {DateTime? date}) {
  final q = lesson.questions[index];
  final option = correct ? q.correctOptionId
      : q.options.firstWhere((o) => o.optionId != q.correctOptionId).optionId;
  return LearnerAttempt(
    id: id, timestampUtc: date ?? now,
    answer: AcademyAnswer(
      lessonId: lesson.lessonId, questionId: q.questionId,
      skillTag: q.skillTag, schemaVersion: lesson.schemaVersion,
      selectedOptionId: option),
    correct: correct);
}

List<LearningRecommendation> recommend(LearnerProgress progress,
    {bool consent = true, DateTime? clock}) =>
    LearningRecommendationEngine.recommend(
      lessons: lessons, progress: progress,
      nowUtc: clock ?? now, hasConsent: consent);

void main() {
  test('C3.2 opt-out never recommends; new user gets all catalog lessons', () {
    final ledger = LearnerProgress([attempt(lessons.first, 0, 'x', false)]);
    expect(recommend(ledger, consent: false), isEmpty);
    final fresh = recommend(LearnerProgress());
    expect(fresh, hasLength(lessons.length));
    expect(fresh.every((r) =>
        r.reason == RecommendationReason.notStarted), isTrue);
    expect(fresh.map((r) => r.lesson.lessonId).toSet(), hasLength(lessons.length));
    expect(() => recommend(ledger, clock: DateTime(2026, 10, 17)),
        throwsArgumentError);
  });

  test('C3.2 enough samples triggers weak skill ahead of isolated error', () {
    final progress = LearnerProgress([
      attempt(lessons[0], 0, 'a', false),
      attempt(lessons[0], 1, 'b', false),
      attempt(lessons[0], 2, 'c', true),
      attempt(lessons[1], 0, 'd', false),
    ]);
    final result = recommend(progress);
    expect(result.first.lesson.lessonId, lessons[0].lessonId);
    expect(result.first.reason, RecommendationReason.lowAccuracy);
    expect(result.first.attempts, 3);
    expect(result.first.correct, 1);
    expect(result[1].reason, RecommendationReason.recentMistake);
    expect(result[1].attempts, 1);
  });

  test('C3.2 later correct or outdated wrong does not remain recent', () {
    final updated = LearnerProgress([
      attempt(lessons[0], 0, 'early', false,
          date: now.subtract(const Duration(hours: 1))),
      attempt(lessons[0], 0, 'later', true),
    ]);
    final result = recommend(updated)
        .firstWhere((r) => r.lesson.lessonId == lessons[0].lessonId);
    expect(result.recentWrong, 0);
    expect(result.reason, RecommendationReason.unfinished);
    final old = LearnerProgress([
      attempt(lessons[0], 0, 'stale', false,
          date: now.subtract(const Duration(days: 20))),
    ]);
    final stale = recommend(old)
        .firstWhere((r) => r.lesson.lessonId == lessons[0].lessonId);
    expect(stale.reason, RecommendationReason.unfinished);
    expect(stale.recentWrong, 0);
  });

  test('C3.2 incompatible question, lesson, or answer records are skipped', () {
    final valid = attempt(lessons[0], 0, 'valid', false);
    final wrongLesson = LearnerAttempt(
      id: 'wrong-lesson', timestampUtc: now,
      answer: AcademyAnswer(
        lessonId: 'unknown-lesson', questionId: valid.answer.questionId,
        skillTag: valid.answer.skillTag, schemaVersion: 1,
        selectedOptionId: valid.answer.selectedOptionId),
      correct: false);
    final wrongSchemaTag = LearnerAttempt(
      id: 'wrong-tag', timestampUtc: now,
      answer: AcademyAnswer(
        lessonId: valid.answer.lessonId,
        questionId: valid.answer.questionId,
        skillTag: 'replaced_skill', schemaVersion: 1,
        selectedOptionId: valid.answer.selectedOptionId),
      correct: false);
    final wrongGrade = LearnerAttempt(
      id: 'wrong-grade', timestampUtc: now,
      answer: valid.answer, correct: true);
    final ledger = LearnerProgress([valid, wrongLesson, wrongSchemaTag, wrongGrade]);
    final chosen = recommend(ledger)
        .firstWhere((r) => r.lesson.lessonId == lessons[0].lessonId);
    expect(chosen.attempts, 1);
    expect(chosen.reason, RecommendationReason.recentMistake);
  });

  test('C3.2 order and targets are independent of archive insertion order', () {
    final a = attempt(lessons[1], 0, 'a', false);
    final b = attempt(lessons[0], 0, 'b', false);
    final left = recommend(LearnerProgress([a, b]));
    final right = recommend(LearnerProgress([b, a]));
    expect(left.map((r) => r.lesson.lessonId).toList(),
        right.map((r) => r.lesson.lessonId).toList());
    expect(left.map((r) => r.questionId).toList(),
        right.map((r) => r.questionId).toList());
  });

  testWidgets('C3.2 visible local suggestions switch language and open a question',
      (tester) async {
    final store = MemoryLearnerStore();
    await store.write(LearnerProgress([
      attempt(lessons[0], 0, 'a', false),
      attempt(lessons[0], 1, 'b', false),
      attempt(lessons[0], 2, 'c', true),
    ]));
    await tester.pumpWidget(MaterialApp(
        home: AcademyPage(isEnglish: false, learnerStore: store)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('c3_2_recommendations')), findsOneWidget);
    expect(find.textContaining('推薦下一堂'), findsOneWidget);
    await tester.tap(find.byKey(const Key('academy_toggle_locale')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Recommended next'), findsOneWidget);
    final entry = find.byKey(Key('c3_2_recommend_${lessons[0].lessonId}'));
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byKey(Key('academy_question_${lessons[0].questions.first.questionId}')),
        findsOneWidget);
  });

  testWidgets('C3.2 opt-out hides suggestions; consent and deletion control them',
      (tester) async {
    final store = MemoryLearnerStore();
    await tester.pumpWidget(MaterialApp(
        home: AcademyPage(isEnglish: true, learnerStore: store)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('c3_2_recommendations')), findsNothing);
    await tester.tap(find.byKey(const Key('c3_enable')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('c3_2_recommendations')), findsOneWidget);
    final progress = find.byKey(const Key('c3_show_progress'));
    await tester.ensureVisible(progress);
    await tester.tap(progress);
    await tester.pumpAndSettle();
    final delete = find.byKey(const Key('c3_delete'));
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete all learning history').last);
    await tester.pumpAndSettle();
    expect(await store.read(), isNull);
    await tester.tap(find.byKey(const Key('c3_back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('c3_2_recommendations')), findsNothing);
  });
}
