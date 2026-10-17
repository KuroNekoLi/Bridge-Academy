import '../academy/academy_models.dart';
import 'learner_progress.dart';

enum RecommendationReason { lowAccuracy, recentMistake, notStarted, unfinished, review }

final class LearningRecommendation {
  const LearningRecommendation({
    required this.lesson, required this.reason, required this.questionId,
    required this.attempts, required this.correct, required this.completed,
    required this.recentWrong,
  });
  final AcademyLesson lesson;
  final RecommendationReason reason;
  final String questionId;
  final int attempts;
  final int correct;
  final int completed;
  final int recentWrong;
  double? get accuracy => attempts == 0 ? null : correct / attempts;
}

/// Pure local rules, not AI diagnosis. No networking or secondary persistence.
abstract final class LearningRecommendationEngine {
  static const minSamples = 3;
  static const recentWindow = Duration(days: 14);

  static List<LearningRecommendation> recommend({
    required List<AcademyLesson> lessons,
    required LearnerProgress progress,
    required DateTime nowUtc,
    required bool hasConsent,
  }) {
    if (!hasConsent) return const <LearningRecommendation>[];
    if (!nowUtc.isUtc) {
      throw ArgumentError.value(nowUtc, 'nowUtc', 'UTC required');
    }
    AcademyValidator.validate(lessons);
    final questions = <String, ({AcademyLesson lesson, AcademyQuestion question})>{
      for (final lesson in lessons)
        for (final question in lesson.questions)
          question.questionId: (lesson: lesson, question: question),
    };
    final valid = <LearnerAttempt>[];
    final latest = <String, LearnerAttempt>{};
    final completed = <String>{};

    for (final attempt in progress.attempts) {
      final found = questions[attempt.answer.questionId];
      if (found == null ||
          attempt.answer.lessonId != found.lesson.lessonId ||
          attempt.answer.schemaVersion != found.lesson.schemaVersion ||
          attempt.answer.skillTag != found.question.skillTag ||
          !found.question.hasOption(attempt.answer.selectedOptionId) ||
          attempt.correct != found.question.isCorrect(attempt.answer.selectedOptionId)) {
        // Obsolete or inconsistent records cannot influence today's catalog.
        continue;
      }
      valid.add(attempt);
      if (attempt.correct) completed.add(attempt.answer.questionId);
      final previous = latest[attempt.answer.questionId];
      if (previous == null ||
          attempt.timestampUtc.isAfter(previous.timestampUtc) ||
          (attempt.timestampUtc.isAtSameMomentAs(previous.timestampUtc) &&
              attempt.id.compareTo(previous.id) > 0)) {
        latest[attempt.answer.questionId] = attempt;
      }
    }

    final picks = <LearningRecommendation>[];
    for (final lesson in lessons) {
      final attempts = valid.where((a) => a.answer.lessonId == lesson.lessonId).toList();
      final correct = attempts.where((a) => a.correct).length;
      final done = lesson.questions.where((q) => completed.contains(q.questionId)).length;
      final recent = <String>[];
      for (final question in lesson.questions) {
        final last = latest[question.questionId];
        if (last == null || last.correct) continue;
        final age = nowUtc.difference(last.timestampUtc);
        if (!age.isNegative && age <= recentWindow) {
          recent.add(question.questionId);
        }
      }

      final RecommendationReason reason;
      if (attempts.length >= minSamples && correct / attempts.length < 0.7) {
        reason = RecommendationReason.lowAccuracy;
      } else if (recent.isNotEmpty) {
        reason = RecommendationReason.recentMistake;
      } else if (attempts.isEmpty) {
        reason = RecommendationReason.notStarted;
      } else if (done < lesson.questions.length) {
        reason = RecommendationReason.unfinished;
      } else {
        reason = RecommendationReason.review;
      }

      final targets = recent.isNotEmpty
          ? recent
          : lesson.questions.where((q) => !completed.contains(q.questionId))
              .map((q) => q.questionId).toList();
      picks.add(LearningRecommendation(
        lesson: lesson, reason: reason,
        questionId: targets.isEmpty ? lesson.questions.first.questionId : targets.first,
        attempts: attempts.length, correct: correct, completed: done,
        recentWrong: recent.length,
      ));
    }
    int priority(RecommendationReason r) => switch (r) {
      RecommendationReason.lowAccuracy => 0,
      RecommendationReason.recentMistake => 1,
      RecommendationReason.notStarted => 2,
      RecommendationReason.unfinished => 3,
      RecommendationReason.review => 4,
    };
    picks.sort((a, b) {
      final first = priority(a.reason).compareTo(priority(b.reason));
      if (first != 0) return first;
      final rate = (a.accuracy ?? 1).compareTo(b.accuracy ?? 1);
      return rate != 0 ? rate : a.lesson.lessonId.compareTo(b.lesson.lessonId);
    });
    return List.unmodifiable(picks);
  }
}
