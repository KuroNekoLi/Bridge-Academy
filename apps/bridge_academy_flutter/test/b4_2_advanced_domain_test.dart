import 'package:bridge_academy_flutter/src/academy/academy_catalog.dart';
import 'package:bridge_academy_flutter/src/academy/academy_models.dart';
import 'package:bridge_academy_flutter/src/conventions/convention_profile.dart';
import 'package:bridge_academy_flutter/src/learning_progress/learner_progress.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final lessons = AcademyCatalog.validated();
  final advanced = lessons.where((lesson) =>
      lesson.lessonId.startsWith('b4.advanced-')).toList();

  test('B4.2 retains beginner IDs and adds 12 bilingual, unique questions', () {
    expect(lessons.length, 6);
    expect(lessons.take(3).map((l) => l.lessonId).toList(), [
      'b4.cards-and-seats', 'b4.hcp-intro', 'b4.play-and-contract',
    ]);
    expect(advanced.length, 3);
    expect(advanced.map((l) => l.skillTag).toSet(),
        {'defense_rules', 'contract_planning', 'convention_literacy'});
    expect(advanced.expand((l) => l.questions).length, 12);
    expect(lessons.expand((l) => l.questions)
        .map((q) => q.questionId).toSet().length, 21);
    for (final lesson in advanced) {
      expect(lesson.schemaVersion, 1);
      for (final q in lesson.questions) {
        expect(q.questionId, startsWith('b4.2.'));
        expect(q.skillTag, lesson.skillTag);
        expect(q.explanation.ruleReference, isNotEmpty);
        expect(q.prompt.zhTw, isNotEmpty);
        expect(q.prompt.en, isNotEmpty);
        final practice = AcademyPractice();
        for (final option in q.options) {
          final result = practice.submit(
            lesson: lesson, question: q,
            answer: AcademyAnswer(
              lessonId: lesson.lessonId,
              questionId: q.questionId, skillTag: q.skillTag,
              schemaVersion: lesson.schemaVersion,
              selectedOptionId: option.optionId,
            ),
          );
          expect(result.correct, option.optionId == q.correctOptionId);
        }
        expect(practice.completedCount(lesson), 1);
      }
    }
  });

  test('Contract rules and signed score match authoritative Bridge Core', () {
    const ntNorth = Contract(level: 3, strain: Strain.notrump,
        declarer: Seat.north);
    const ntEast = Contract(level: 3, strain: Strain.notrump,
        declarer: Seat.east);
    const heartsSouth = Contract(level: 4, strain: Strain.hearts,
        declarer: Seat.south);
    expect(ntNorth.targetTricks, 9);
    expect(heartsSouth.targetTricks, 10);
    expect(DuplicateScore.score(ntNorth, 9, Vulnerability.none), 400);
    expect(DuplicateScore.score(ntEast, 9, Vulnerability.none), -400);
    expect(DuplicateScore.score(heartsSouth, 9, Vulnerability.none), -50);
    final byId = {for (final l in advanced) for (final q in l.questions)
      q.questionId: q};
    expect(byId['b4.2.nt-target']!.correctOptionId, 'b');
    expect(byId['b4.2.four-hearts-one-down']!.correctOptionId, 'b');
    expect(byId['b4.2.nt-nonvul-game-score']!.correctOptionId, 'b');
    expect(byId['b4.2.ew-score-sign']!.correctOptionId, 'a');
  });

  test('Teaching preview only matches public, uncontested bidding context', () {
    BidExplanation resolve(Call response, {bool interfered = false}) {
      return ConventionExplanationEngine.resolve(
        BidContext(
          dealer: Seat.north, viewer: Seat.south,
          vulnerability: Vulnerability.none,
          auction: [
            const AuctionEntry(Seat.north, Bid(1, Strain.notrump)),
            AuctionEntry(Seat.east, interfered
                ? const Bid(2, Strain.diamonds) : const Pass()),
            AuctionEntry(Seat.south, response),
          ],
        ),
        profile: ConventionProfiles.preview,
      );
    }
    final stayman = resolve(const Bid(2, Strain.clubs));
    expect(stayman.ruleId, 'PREVIEW-STAYMAN-2C');
    expect(stayman.preview, true);
    expect(stayman.reviewStatus, ConventionReviewStatus.unreviewed);
    final jacoby = resolve(const Bid(2, Strain.diamonds));
    expect(jacoby.ruleId, 'PREVIEW-JACOBY-2D');
    expect(jacoby.preview, true);
    final competitive = resolve(const Bid(3, Strain.clubs), interfered: true);
    expect(competitive.status, ConventionMatchStatus.unknown);
    expect(competitive.matched, false);
  });

  test('B4.2 results remain readable by C3 schema v1', () {
    final lesson = advanced.last;
    final q = lesson.questions.first;
    final answer = AcademyAnswer(
      lessonId: lesson.lessonId,
      questionId: q.questionId,
      schemaVersion: lesson.schemaVersion,
      skillTag: q.skillTag,
      selectedOptionId: q.correctOptionId,
    );
    final restored = AcademyAnswer.fromJson(answer.toJson());
    final ledger = LearnerProgress();
    expect(ledger.record(LearnerAttempt(
      id: 'b4.2-1', timestampUtc: DateTime.utc(2026, 10, 17),
      answer: restored, correct: q.isCorrect(restored.selectedOptionId),
    )), true);
    expect(ledger.completedCount, 1);
    expect(ledger.skill('convention_literacy').accuracy, 1);
  });
}
