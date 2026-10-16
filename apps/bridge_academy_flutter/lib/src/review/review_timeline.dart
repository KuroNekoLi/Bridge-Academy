import 'package:bridge_core/bridge_core.dart';

import '../conventions/convention_profile.dart';

/// A rules-scoped review of a terminal replay. No hidden Deal or PBN enters
/// this model: it consumes only immutable, human-filtered ReplayFrames.
enum ReviewEventType { start, auction, play }

enum ReviewEvidence { rule, convention, unknown }

class ReviewInsight {
  const ReviewInsight(this.key, this.evidence, {this.ruleId});
  final String key;
  final ReviewEvidence evidence;
  final String? ruleId;
}

class ReviewStep {
  const ReviewStep({
    required this.index,
    required this.frame,
    required this.eventType,
    required this.trickNumber,
    required this.insights,
    required this.isKeyEvent,
  });

  final int index;
  final ReplayFrame frame;
  final ReviewEventType eventType;
  final int trickNumber;
  final List<ReviewInsight> insights;
  final bool isKeyEvent;

  int? get targetTricks => frame.view.contract?.targetTricks;
}

/// Frame index always corresponds to Bridge Core's canonical event version.
/// The timeline does not replay, change or score game actions.
class ReviewTimeline {
  ReviewTimeline._(this.steps, this.historyFingerprint);

  final List<ReviewStep> steps;
  final String historyFingerprint;
  int get lastIndex => steps.length - 1;

  static ReviewTimeline fromReplay(CompletedReplay replay) {
    final frames = replay.frames;
    if (frames.isEmpty ||
        frames.first.action != null ||
        frames.last.view.phase != Phase.finished) {
      throw const FormatException('Review requires a completed replay');
    }

    final steps = <ReviewStep>[];
    final viewer = frames.first.view.viewer;
    for (var index = 0; index < frames.length; index++) {
      final frame = frames[index];
      final view = frame.view;
      final action = frame.action;
      if (view.viewer != viewer ||
          view.version != index ||
          (index > 0 && action == null)) {
        throw const FormatException('Invalid replay frame order');
      }
      final previous = index > 0 ? frames[index - 1].view : null;
      final insights = <ReviewInsight>[];
      var keyEvent = index == 0 || index == frames.length - 1;
      var event = ReviewEventType.start;

      if (action is CallAction) {
        event = ReviewEventType.auction;
        final call = action.call;
        if (call is Bid) {
          insights.add(const ReviewInsight('reviewBidRule', ReviewEvidence.rule));
          keyEvent = true;
          // The profile describes an *assumed* public agreement only.
          // It never verifies anyone's private HCP or BEN decision.
          final matched = ConventionExplanationEngine.resolve(
              BidContext.fromView(view));
          if (matched.matched) {
            insights.add(ReviewInsight(
                matched.meaningKey, ReviewEvidence.convention,
                ruleId: matched.ruleId));
            insights.add(ReviewInsight(
                matched.assumptionKey, ReviewEvidence.convention));
          } else {
            insights.add(const ReviewInsight(
                'reviewConventionUnknown', ReviewEvidence.unknown));
          }
        } else if (call is DoubleCall) {
          keyEvent = true;
          insights.add(const ReviewInsight('reviewDoubleRule', ReviewEvidence.rule));
          insights.add(const ReviewInsight(
              'reviewConventionUnknown', ReviewEvidence.unknown));
        } else if (call is RedoubleCall) {
          keyEvent = true;
          insights.add(const ReviewInsight(
              'reviewRedoubleRule', ReviewEvidence.rule));
          insights.add(const ReviewInsight(
              'reviewConventionUnknown', ReviewEvidence.unknown));
        } else if (view.phase == Phase.finished && view.contract == null) {
          insights.add(const ReviewInsight('reviewPassOutRule', ReviewEvidence.rule));
          keyEvent = true;
        } else {
          insights.add(const ReviewInsight('reviewPassRule', ReviewEvidence.rule));
        }
        if (previous?.contract == null && view.contract != null) {
          insights.add(const ReviewInsight('reviewContractRule', ReviewEvidence.rule));
          insights.add(ReviewInsight(
              view.contract!.strain == Strain.notrump
                  ? 'reviewNoTrumpRule' : 'reviewTrumpRule',
              ReviewEvidence.rule));
          keyEvent = true;
        }
      } else if (action is CardAction) {
        event = ReviewEventType.play;
        if (previous == null) {
          throw const FormatException('Play event without earlier frame');
        }
        if (previous.currentTrick.isEmpty) {
          insights.add(const ReviewInsight('reviewLeadRule', ReviewEvidence.rule));
          keyEvent = true;
        } else if (previous.currentTrick.first.card.suit == action.card.suit) {
          insights.add(const ReviewInsight('reviewFollowSuit', ReviewEvidence.rule));
        } else {
          // A different suit does not prove a void from a public replay.
          insights.add(const ReviewInsight(
              'reviewOffSuitUnknown', ReviewEvidence.unknown));
        }
        if (!previous.dummyExposed && view.dummyExposed) {
          insights.add(const ReviewInsight(
              'reviewDummyReveal', ReviewEvidence.rule));
          keyEvent = true;
        }
        if (action.actor != action.handOwner) {
          insights.add(const ReviewInsight(
              'reviewDummyControl', ReviewEvidence.rule));
        }
        if (view.completedTricks.length > previous.completedTricks.length) {
          insights.add(const ReviewInsight(
              'reviewTrickComplete', ReviewEvidence.rule));
          keyEvent = true;
        }
      } else if (index == 0) {
        insights.add(const ReviewInsight('reviewStartRule', ReviewEvidence.rule));
      }
      if (view.phase == Phase.finished && view.nsScore != null &&
          (previous == null || previous.phase != Phase.finished)) {
        insights.add(const ReviewInsight(
            'reviewOfficialScore', ReviewEvidence.rule));
      }
      steps.add(ReviewStep(
        index: index,
        frame: frame,
        eventType: event,
        trickNumber: view.completedTricks.length +
            (view.currentTrick.isNotEmpty ? 1 : 0),
        insights: List.unmodifiable(insights),
        isKeyEvent: keyEvent,
      ));
    }
    return ReviewTimeline._(List.unmodifiable(steps), replay.historyFingerprint);
  }

  int? nextKeyAfter(int index) {
    for (var i = index + 1; i < steps.length; i++) {
      if (steps[i].isKeyEvent) return i;
    }
    return null;
  }

  int? previousKeyBefore(int index) {
    for (var i = index - 1; i >= 0; i--) {
      if (steps[i].isKeyEvent) return i;
    }
    return null;
  }
}
