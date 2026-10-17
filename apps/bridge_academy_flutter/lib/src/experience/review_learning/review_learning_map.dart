import 'package:bridge_core/bridge_core.dart';
import '../../academy/academy_catalog.dart';
import '../../academy/academy_models.dart';
import '../../review/review_timeline.dart';

/// Stable public catalog link, never a privileged Deal or a learner record.
class ReviewLearningTarget {
  const ReviewLearningTarget({
    required this.lessonId,
    required this.questionId,
    required this.skillTag,
    required this.schemaVersion,
    required this.evidenceKey,
  });

  final String lessonId;
  final String questionId;
  final String skillTag;
  final int schemaVersion;
  final String evidenceKey;
}

/// Only explicit Bridge Core rule evidence may create an educational link.
/// Unknown strategy, proposed conventions and DDS double-dummy results cannot.
abstract final class ReviewLearningMap {
  static ReviewLearningTarget? forStep(
    ReviewStep step, {List<AcademyLesson>? catalog}) {
    final lessons = catalog ?? AcademyCatalog.validated();
    for (final insight in step.insights) {
      if (insight.evidence != ReviewEvidence.rule) continue;
      String? questionId;
      if (insight.key == 'reviewPassOutRule' &&
          step.frame.view.phase == Phase.finished &&
          step.frame.view.contract == null) {
        questionId = 'b4.play.pass-out';
      } else if (insight.key == 'reviewFollowSuit') {
        questionId = 'b4.play.follow-suit';
      } else if (insight.key == 'reviewContractRule') {
        final contract = step.frame.view.contract;
        if (contract != null && contract.level == 4 &&
            contract.strain == Strain.spades) {
          questionId = 'b4.play.four-spades';
        }
      }
      if (questionId == null) {
        continue;
      }
      for (final lesson in lessons) {
        if (lesson.schemaVersion != AcademyValidator.schemaVersion ||
            lesson.skillTag.trim().isEmpty) {
          continue;
        }
        for (final q in lesson.questions) {
          if (q.questionId == questionId &&
              q.skillTag == lesson.skillTag &&
              q.explanation.ruleReference.trim().isNotEmpty) {
            return ReviewLearningTarget(
              lessonId: lesson.lessonId,
              questionId: q.questionId,
              skillTag: q.skillTag,
              schemaVersion: lesson.schemaVersion,
              evidenceKey: insight.key,
            );
          }
        }
      }
    }
    return null;
  }
}
