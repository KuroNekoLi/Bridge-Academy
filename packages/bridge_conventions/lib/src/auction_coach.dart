import 'custom_convention_draft.dart';
import 'game_systems.dart';

/// M5.1 is an evidence-bounded public auction reviewer, NOT a BEN/LLM
/// explanation of private reasoning or a bridge legality/strategy oracle.
enum CoachMeaningEvidence {
  unknown,
  userDraftOnly,
  baseNotReviewed,
}

final class CoachAuctionEntry {
  const CoachAuctionEntry({
    required this.index,
    required this.seat,
    required this.call,
    required this.publicPrefix,
    required this.profileId,
    required this.profileFingerprint,
    required this.evidence,
    this.ruleId,
    this.userSelectedMeaning,
  });

  final int index;
  final String seat;
  final String call;
  final String publicPrefix;
  final String profileId;
  final String profileFingerprint;
  final CoachMeaningEvidence evidence;

  /// A locally edited author's intention, NEVER the AI's actual reasoning.
  final String? ruleId;
  final String? userSelectedMeaning;

  bool get isEngineVerified => false;
  bool get hasOptimalBidEvidence => false;
}

final class CoachAuctionReport {
  CoachAuctionReport._({
    required this.dealer,
    required this.gameSystemsFingerprint,
    required List<CoachAuctionEntry> entries,
    required this.draftFingerprint,
  }) : entries = List.unmodifiable(entries);

  final String dealer;
  final String gameSystemsFingerprint;
  final List<CoachAuctionEntry> entries;
  final String? draftFingerprint;

  /// No authority to recommend a "best bid" until actual pinned model
  /// proposals + evaluated alternatives exist.
  List<String> get verifiedCandidateCalls => const [];
  bool get expertApproved => false;
  bool get explainsBenPrivateReasoning => false;
}

/// Describes ONLY public transcript and explicit local user annotations.
/// The trusted GameSystems pin must come from the session or known catalog,
/// never a client-claimed "SUPPORTED" value.
abstract final class PublicAuctionCoach {
  static const _seats = 'NESW';

  static CoachAuctionReport review({
    required String dealer,
    required List<String> calls,
    required GameSystems systems,
    CustomConventionDraft? draft,
    bool? draftNorthSouth,
  }) {
    if (dealer.length != 1 || !_seats.contains(dealer) ||
        calls.length > 64) {
      throw const FormatException('Invalid public auction');
    }
    if ((draft == null && draftNorthSouth != null) ||
        (draft != null &&
            (draftNorthSouth == null || draft.rules.isEmpty ||
             draft.base != systems.forPartnership(
                 northSouthSeat: draftNorthSouth) ||
             !draft.canSave))) {
      throw const FormatException('Custom draft does not match a base system');
    }
    final normalized = <String>[];
    for (final call in calls) {
      if (call.length > 4 || !RegExp(r'^(P|PASS|X|XX|[1-7](C|D|H|S|N|NT))$')
          .hasMatch(call)) {
        throw const FormatException('Invalid public call syntax');
      }
      normalized.add(call == 'PASS' ? 'P' :
          call.length == 2 && call.endsWith('N') ? '${call[0]}NT' : call);
    }
    final output = <CoachAuctionEntry>[];
    final start = _seats.indexOf(dealer);
    for (var i = 0; i < normalized.length; i++) {
      final seatIndex = (start + i) % 4;
      final profile = systems.forPartnership(
          northSouthSeat: seatIndex.isEven);
      final prefix = normalized.take(i + 1).join('-');
      // Both an unmodified BEN base and an edited custom card have NO
      // peer-reviewed convention meaning in this engine-independent layer.
      String? selectedMeaning;
      String? ruleId;
      if (draft != null && (seatIndex.isEven == draftNorthSouth) &&
          profile == draft.base) {
        final matches = draft.rules.where((r) =>
            CustomRuleCatalog.publicAuctions[r.slot] == prefix);
        if (matches.length == 1) {
          selectedMeaning = matches.single.choice;
          ruleId = 'USER_DRAFT:${matches.single.slot.name}';
        }
      }
      output.add(CoachAuctionEntry(
        index: i,
        seat: _seats[seatIndex],
        call: normalized[i],
        publicPrefix: prefix,
        profileId: profile.profileId,
        profileFingerprint: profile.profileFingerprint,
        evidence: selectedMeaning != null
            ? CoachMeaningEvidence.userDraftOnly
            : CustomRuleCatalog.publicAuctions.values.contains(prefix)
                ? CoachMeaningEvidence.baseNotReviewed
                : CoachMeaningEvidence.unknown,
        ruleId: ruleId,
        userSelectedMeaning: selectedMeaning,
      ));
    }
    return CoachAuctionReport._(
      dealer: dealer,
      gameSystemsFingerprint: systems.fingerprint,
      entries: output,
      draftFingerprint: draft?.fingerprint,
    );
  }
}
