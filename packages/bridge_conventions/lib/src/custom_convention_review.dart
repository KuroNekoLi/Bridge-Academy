import 'custom_convention_draft.dart';

/// A user-authored description is NOT an AI behavior assertion.
/// Only a trusted, server-owned engine manifest can authorize a custom profile.
enum CustomExecutionStatus {
  unchangedBase,
  engineEvidenceRequired,
  invalidDraft,
}

enum CustomMeaningSource {
  userDraft,
  baseUnverified,
  noRule,
}

/// Bounded public auction preview; never uses hand/deal/private info.
final class CustomAuctionPreview {
  const CustomAuctionPreview({
    required this.auction,
    required this.ruleId,
    required this.userSelectedMeaning,
    required this.source,
    required this.engineVerified,
  });

  final String auction;
  final String? ruleId;
  final String? userSelectedMeaning;
  final CustomMeaningSource source;
  final bool engineVerified;
}

final class CustomRuleAssessment {
  const CustomRuleAssessment({
    required this.ruleId,
    required this.auction,
    required this.choice,
    required this.executionStatus,
    required this.reason,
  });

  final String ruleId;
  final String auction;
  final String choice;
  final CustomExecutionStatus executionStatus;
  final String reason;
}

final class CustomConventionReview {
  CustomConventionReview._({
    required this.executionStatus,
    required List<CustomRuleAssessment> rules,
    required this.reason,
  }) : rules = List.unmodifiable(rules);

  final CustomExecutionStatus executionStatus;
  final List<CustomRuleAssessment> rules;
  final String reason;

  bool get canUseAsAiSystem => false;
  bool get hasExecutableEvidence => false;
}

/// Fail-closed review of local draft intent against the known engine
/// inventory. BEN 21GF/SAYC have pinned base models, but *no approved
/// engine mapping for edited rules*. No mock card/JSON can grant support.
abstract final class CustomConventionReviewer {
  static CustomConventionReview assess(CustomConventionDraft draft) {
    if (!draft.canSave) {
      return CustomConventionReview._(
        executionStatus: CustomExecutionStatus.invalidDraft,
        rules: const [],
        reason: 'conflicting_draft_rules',
      );
    }
    if (draft.rules.isEmpty) {
      return CustomConventionReview._(
        executionStatus: CustomExecutionStatus.unchangedBase,
        rules: const [],
        reason: 'base_only_no_custom_ai_profile',
      );
    }
    return CustomConventionReview._(
      executionStatus: CustomExecutionStatus.engineEvidenceRequired,
      rules: [
        for (final rule in draft.rules)
          CustomRuleAssessment(
            ruleId: 'USER_DRAFT:${rule.slot.name}',
            auction: CustomRuleCatalog.publicAuctions[rule.slot]!,
            choice: rule.choice,
            executionStatus: CustomExecutionStatus.engineEvidenceRequired,
            reason: 'no_pinned_engine_rule_evidence',
          ),
      ],
      reason: 'requires_engine_approval',
    );
  }

  /// Input is a *public* chronological auction, e.g. 1NT-P-2C.
  /// Do not accept an AI response or treat an unsupported sequence as known.
  static CustomAuctionPreview preview(
      CustomConventionDraft draft, String publicAuction) {
    final normalized = _normalize(publicAuction);
    CustomConventionRule? selected;
    for (final rule in draft.rules) {
      if (CustomRuleCatalog.publicAuctions[rule.slot] == normalized) {
        selected = rule;
        break;
      }
    }
    if (selected != null) {
      return CustomAuctionPreview(
        auction: normalized, ruleId: 'USER_DRAFT:${selected.slot.name}',
        userSelectedMeaning: selected.choice,
        source: CustomMeaningSource.userDraft,
        engineVerified: false,
      );
    }
    return CustomAuctionPreview(
      auction: normalized, ruleId: null,
      userSelectedMeaning: null,
      source: CustomRuleCatalog.publicAuctions.values.contains(normalized)
          ? CustomMeaningSource.baseUnverified
          : CustomMeaningSource.noRule,
      engineVerified: false,
    );
  }

  static String _normalize(String auction) {
    // Explicitly bounded; the preview does not simulate auction legality.
    if (auction.isEmpty || auction.length > 80) {
      throw const FormatException('Invalid auction length');
    }
    final tokens = auction.toUpperCase().split('-');
    if (tokens.length > 20 || tokens.any((token) =>
        !RegExp(r'^(PASS|P|X|XX|[1-7](C|D|H|S|N|NT))$').hasMatch(token))) {
      throw const FormatException('Invalid public auction');
    }
    return tokens.map((token) {
      if (token == 'PASS') return 'P';
      if (token.endsWith('NT')) return '${token.substring(0, token.length - 2)}NT';
      if (token.length == 2 && token.endsWith('N')) {
        return '${token[0]}NT';
      }
      return token;
    }).join('-');
  }
}
