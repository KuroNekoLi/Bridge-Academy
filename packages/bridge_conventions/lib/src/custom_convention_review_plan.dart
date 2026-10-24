import 'custom_convention_draft.dart';

/// A request for expert evidence, not a fixture result or engine approval.
enum ConventionReviewScenario {
  uncontested,
  competitive,
  passedHand,
  forcingOrInvitational,
  alertAndDisclosure,
  opponentInterpretation,
}

final class ConventionReviewTask {
  const ConventionReviewTask({
    required this.ruleId,
    required this.publicAuction,
    required this.draftChoice,
    required this.scenario,
  });

  final String ruleId;
  final String publicAuction;
  final String draftChoice;
  final ConventionReviewScenario scenario;

  Map<String, Object> toJson() => {
    'ruleId': ruleId,
    'publicAuctionPrefix': publicAuction,
    'draftChoice': draftChoice,
    'scenario': scenario.name,
    'reviewStatus': 'NOT_REVIEWED',
    'engineObservedBehavior': 'NOT_RUN',
  };
}

/// Creates a bounded checklist that human experts and a future pinned-engine
/// golden harness can fill in. It contains no hidden cards, predicted bids,
/// forged AI explanation, or player-supplied engine authority.
///
/// Production support must never be inferred from checklist completion alone:
/// a trusted operator must independently attest exact engine artifacts and
/// replay actual behavior before server-side activation is even considered.
final class CustomConventionReviewPlan {
  CustomConventionReviewPlan._(this.draft, List<ConventionReviewTask> tasks)
      : tasks = List.unmodifiable(tasks);

  factory CustomConventionReviewPlan.forDraft(CustomConventionDraft draft) {
    if (!draft.canSave) {
      throw const FormatException('Conflicting draft is not reviewable');
    }
    return CustomConventionReviewPlan._(
      draft,
      [
        for (final slot in CustomRuleSlot.values)
          for (final rule in draft.rules)
            if (rule.slot == slot)
              for (final scenario in ConventionReviewScenario.values)
                ConventionReviewTask(
                  ruleId: 'USER_DRAFT:${slot.name}',
                  publicAuction: CustomRuleCatalog.publicAuctions[slot]!,
                  draftChoice: rule.choice,
                  scenario: scenario,
                ),
      ],
    );
  }

  final CustomConventionDraft draft;
  final List<ConventionReviewTask> tasks;

  /// Proposed project-wide acceptance target, not accomplished evidence.
  int get targetExpertGoldenCases => 100;
  int get observedEngineGoldenCases => 0;
  bool get isEngineVerified => false;
  bool get eligibleForProduction => false;

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'purpose': 'EXPERT_REVIEW_REQUEST_ONLY',
    'draftId': draft.id,
    'draftRevision': draft.revision,
    'draftFingerprint': draft.fingerprint,
    'baseSystem': draft.base.profileId,
    'baseFingerprint': draft.base.profileFingerprint,
    'requestedExpertGoldenCases': targetExpertGoldenCases,
    'verifiedCases': observedEngineGoldenCases,
    'engineCertified': false,
    'tasks': [for (final task in tasks) task.toJson()],
  };
}
