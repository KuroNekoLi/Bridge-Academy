import 'dart:convert';

import 'package:bridge_academy_flutter/src/academy/academy_catalog.dart';
import 'package:bridge_academy_flutter/src/academy/academy_models.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter_test/flutter_test.dart';

AcademyAnswer choose(
  AcademyLesson lesson,
  AcademyQuestion question,
  String optionId,
) =>
    AcademyAnswer(
      lessonId: lesson.lessonId,
      questionId: question.questionId,
      skillTag: question.skillTag,
      schemaVersion: lesson.schemaVersion,
      selectedOptionId: optionId,
    );

void main() {
  test('B4 has 3 original lessons, 9 questions and globally stable IDs', () {
    final lessons = AcademyCatalog.validated();
    expect(lessons, hasLength(3));
    expect(lessons.expand((lesson) => lesson.questions), hasLength(9));
    expect(lessons.map((lesson) => lesson.lessonId).toSet(), hasLength(3));
    expect(
        lessons.expand((lesson) => lesson.questions)
            .map((question) => question.questionId).toSet(),
        hasLength(9));
    for (final lesson in lessons) {
      expect(lesson.schemaVersion, AcademyValidator.schemaVersion);
      for (final question in lesson.questions) {
        expect(question.skillTag, lesson.skillTag);
        expect(question.explanation.ruleReference, isNotEmpty);
        expect(question.prompt.zhTw, isNotEmpty);
        expect(question.prompt.en, isNotEmpty);
      }
    }
  });

  test('B4 every exercise accepts exactly its authored correct answer', () {
    final practice = AcademyPractice();
    for (final lesson in AcademyCatalog.validated()) {
      for (final question in lesson.questions) {
        for (final option in question.options) {
          final feedback = practice.submit(
            lesson: lesson,
            question: question,
            answer: choose(lesson, question, option.optionId),
          );
          expect(feedback.correct,
              option.optionId == question.correctOptionId);
        }
        expect(practice.isCompleted(question.questionId), isTrue);
      }
      expect(practice.completedCount(lesson), lesson.questions.length);
    }
  });

  test('B4 wrong answer never passes and correct answer is idempotent', () {
    final lesson = AcademyCatalog.lessons.first;
    final question = lesson.questions.first;
    final wrong = question.options.first.optionId;
    expect(wrong, isNot(question.correctOptionId));
    final practice = AcademyPractice();
    final failed = practice.submit(
      lesson: lesson, question: question,
      answer: choose(lesson, question, wrong),
    );
    expect(failed.correct, false);
    expect(failed.newlyCompleted, false);
    expect(practice.completedCount(lesson), 0);

    final correct = choose(lesson, question, question.correctOptionId);
    expect(practice.submit(
      lesson: lesson, question: question, answer: correct,
    ).newlyCompleted, true);
    expect(practice.submit(
      lesson: lesson, question: question, answer: correct,
    ).newlyCompleted, false);
    expect(practice.completedCount(lesson), 1);

    expect(() => practice.submit(
      lesson: lesson, question: question,
      answer: choose(lesson, question, 'invalid-option'),
    ), throwsFormatException);
    final stale = AcademyAnswer(
      lessonId: lesson.lessonId,
      questionId: question.questionId,
      skillTag: question.skillTag,
      schemaVersion: 9,
      selectedOptionId: question.correctOptionId,
    );
    expect(() => practice.submit(
      lesson: lesson, question: question, answer: stale,
    ), throwsFormatException);
  });

  test('B4 lesson and answer JSON round trip preserves IDs and schema', () {
    for (final lesson in AcademyCatalog.validated()) {
      final json = jsonDecode(jsonEncode(lesson.toJson()));
      final decoded = AcademyLesson.fromJson(json);
      expect(decoded.toJson(), lesson.toJson());
      for (final question in decoded.questions) {
        final original = choose(decoded, question, question.correctOptionId);
        final restored = AcademyAnswer.fromJson(
            jsonDecode(jsonEncode(original.toJson())));
        expect(restored.toJson(), original.toJson());
      }
    }
  });

  test('B4 malformed content fails closed: locale, duplicate, missing answer',
      () {
    final lesson = AcademyCatalog.lessons.first;
    expect(() => AcademyValidator.validate([lesson, lesson]),
        throwsFormatException);

    final invalidLocale = jsonDecode(jsonEncode(lesson.toJson()))
        as Map<String, dynamic>;
    (invalidLocale['title'] as Map<String, dynamic>)['en'] = '';
    expect(() => AcademyValidator.validate([
      AcademyLesson.fromJson(invalidLocale),
    ]), throwsFormatException);

    final invalidCorrect = jsonDecode(jsonEncode(lesson.toJson()))
        as Map<String, dynamic>;
    final questions = invalidCorrect['questions'] as List<dynamic>;
    (questions.first as Map<String, dynamic>)['correctOptionId'] = 'unknown';
    expect(() => AcademyValidator.validate([
      AcademyLesson.fromJson(invalidCorrect),
    ]), throwsFormatException);

    final duplicateQuestion = jsonDecode(jsonEncode(lesson.toJson()))
        as Map<String, dynamic>;
    final duplicated = duplicateQuestion['questions'] as List<dynamic>;
    duplicated[1]['questionId'] = duplicated[0]['questionId'];
    expect(() => AcademyValidator.validate([
      AcademyLesson.fromJson(duplicateQuestion),
    ]), throwsFormatException);
  });

  test('B4 referenced fundamental rules match Bridge Core seat/bid types',
      () {
    expect(Seat.north.partner, Seat.south);
    expect(Seat.east.partner, Seat.west);
    expect(const Bid(4, Strain.spades).code, '4S');
    expect(const Pass().code, 'PASS');
    // HCP is an explicitly authored teaching shorthand; it is not the
    // authoritative scoring or auction legality rule of Bridge Core.
    expect(AcademyCatalog.lessons[1].questions[2].correctOptionId, 'b');
  });
}
