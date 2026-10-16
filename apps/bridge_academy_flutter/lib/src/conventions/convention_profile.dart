import 'package:bridge_core/bridge_core.dart';

/// Agreements describe a partnership's *claimed* meaning, never the real
/// hidden hands, an AI's private reasoning, or bid legality.
enum ConventionReviewStatus { unreviewed, proposed }
enum ConventionMatchStatus { matched, unknown, unsupported }

class ConventionAgreement {
  const ConventionAgreement({
    required this.ruleId,
    required this.calls,
    required this.relativeSeats,
    required this.meaningKey,
    required this.assumptionKey,
    required this.reviewStatus,
    required this.reference,
    this.previewOnly = false,
  });

  final String ruleId;
  /// Chronological non-PASS calls, exactly matched. Doubles are unsupported.
  final List<String> calls;
  /// Seat offsets from the first bidder (opener=0, partner=2).
  final List<int> relativeSeats;
  final String meaningKey;
  final String assumptionKey;
  final ConventionReviewStatus reviewStatus;
  final String reference;
  final bool previewOnly;
}

class ConventionProfile {
  const ConventionProfile({
    required this.id,
    required this.revision,
    required this.locales,
    required this.agreements,
    required this.references,
    required this.reviewStatus,
  });
  final String id;
  final int revision;
  final List<String> locales;
  final List<ConventionAgreement> agreements;
  final List<String> references;
  final ConventionReviewStatus reviewStatus;
}

/// A public-only snapshot. Does not accept Deal, GameState, or other hands.
class BidContext {
  const BidContext({
    required this.dealer,
    required this.viewer,
    required this.vulnerability,
    required this.auction,
  });
  factory BidContext.fromView(PlayerView view) => BidContext(
    dealer: view.dealer,
    viewer: view.viewer,
    vulnerability: view.vulnerability,
    auction: view.auction,
  );
  final Seat dealer;
  final Seat viewer;
  final Vulnerability vulnerability;
  final List<AuctionEntry> auction;
  Seat get partnership => viewer.partner;
}

class BidExplanation {
  const BidExplanation({
    required this.status,
    required this.profileId,
    required this.revision,
    this.ruleId,
    this.meaningKey = 'biddingUnknown',
    this.assumptionKey = 'b3AssumptionUnknown',
    this.reviewStatus,
    this.reference,
    this.preview = false,
  });

  final ConventionMatchStatus status;
  final String profileId;
  final int revision;
  final String? ruleId;
  final String meaningKey;
  final String assumptionKey;
  final ConventionReviewStatus? reviewStatus;
  final String? reference;
  final bool preview;
  bool get matched => status == ConventionMatchStatus.matched;
}

abstract final class ConventionProfiles {
  // B3.1 migration contract: the default profile keeps the original ID,
  // revision and localized keys exactly. Its educational status is explicit.
  static const String id = 'BA-NATURAL-NT';
  static const _source = 'docs/product/B3_BIDDING_PRACTICE_ACCEPTANCE.md';
  static const _stayman = 'https://cdn.acbl.org/assets/documents/teachers/Teacher-Manuals/Commonly-Used-Conventions-Lesson-1.pdf';
  static const _jacoby = 'https://cdn.acbl.org/assets/documents/teachers/Teacher-Manuals/Commonly-Used-Conventions-Lesson-2.pdf';

  static const List<ConventionAgreement> _core = [
    ConventionAgreement(
      ruleId: 'NAT-1NT-OPEN', calls: ['1NT'], relativeSeats: [0],
      meaningKey: 'biddingOpening1NT', assumptionKey: 'b3AssumptionNatural',
      reviewStatus: ConventionReviewStatus.unreviewed, reference: _source,
    ),
    ConventionAgreement(
      ruleId: 'NAT-2NT-INV', calls: ['1NT', '2NT'],
      relativeSeats: [0, 2], meaningKey: 'biddingInvite2NT',
      assumptionKey: 'b3AssumptionNatural',
      reviewStatus: ConventionReviewStatus.unreviewed, reference: _source,
    ),
    ConventionAgreement(
      ruleId: 'NAT-3NT-GAME', calls: ['1NT', '3NT'],
      relativeSeats: [0, 2], meaningKey: 'biddingGame3NT',
      assumptionKey: 'b3AssumptionNatural',
      reviewStatus: ConventionReviewStatus.unreviewed, reference: _source,
    ),
    ConventionAgreement(
      ruleId: 'NAT-3NT-ACCEPT', calls: ['1NT', '2NT', '3NT'],
      relativeSeats: [0, 2, 0], meaningKey: 'biddingAccept3NT',
      assumptionKey: 'b3AssumptionNatural',
      reviewStatus: ConventionReviewStatus.unreviewed, reference: _source,
    ),
  ];

  static const List<ConventionAgreement> _previews = [
    ConventionAgreement(
      ruleId: 'PREVIEW-STAYMAN-2C', calls: ['1NT', '2C'],
      relativeSeats: [0, 2], meaningKey: 'b3Stayman',
      assumptionKey: 'b3AssumptionPreview',
      reviewStatus: ConventionReviewStatus.unreviewed,
      reference: _stayman, previewOnly: true,
    ),
    ConventionAgreement(
      ruleId: 'PREVIEW-JACOBY-2D', calls: ['1NT', '2D'],
      relativeSeats: [0, 2], meaningKey: 'b3JacobyHearts',
      assumptionKey: 'b3AssumptionPreview',
      reviewStatus: ConventionReviewStatus.unreviewed,
      reference: _jacoby, previewOnly: true,
    ),
    ConventionAgreement(
      ruleId: 'PREVIEW-JACOBY-2H', calls: ['1NT', '2H'],
      relativeSeats: [0, 2], meaningKey: 'b3JacobySpades',
      assumptionKey: 'b3AssumptionPreview',
      reviewStatus: ConventionReviewStatus.unreviewed,
      reference: _jacoby, previewOnly: true,
    ),
  ];

  static const basic = ConventionProfile(
    id: id, revision: 1, locales: ['zh-TW', 'en'],
    agreements: _core, references: [_source],
    reviewStatus: ConventionReviewStatus.unreviewed,
  );
  // Revision 2 is opt-in for display of *proposed* conventions only.
  // This does NOT switch the B3.1 rules bot or train BEN.
  static const preview = ConventionProfile(
    id: id, revision: 2, locales: ['zh-TW', 'en'],
    agreements: [..._core, ..._previews],
    references: [_source, _stayman, _jacoby],
    reviewStatus: ConventionReviewStatus.proposed,
  );
}

abstract final class ConventionExplanationEngine {
  static BidExplanation resolve(
    BidContext context, {
    ConventionProfile profile = ConventionProfiles.basic,
    int? expectedRevision,
  }) {
    BidExplanation noMatch(ConventionMatchStatus status) => BidExplanation(
      status: status,
      profileId: profile.id,
      revision: profile.revision,
    );

    if (profile.id != ConventionProfiles.id ||
        profile.revision < 1 ||
        (expectedRevision != null && expectedRevision != profile.revision)) {
      return noMatch(ConventionMatchStatus.unsupported);
    }

    final auction = context.auction;
    if (auction.isEmpty) return noMatch(ConventionMatchStatus.unknown);

    // Fail closed on malformed, contradictory, competitive, or interrupted
    // sequences, never infer hidden hands or rewrite Bridge Core's auction.
    var next = context.dealer;
    var highestBidRank = -1;
    var sawBid = false;
    var passes = 0;
    for (final entry in auction) {
      if (entry.seat != next) return noMatch(ConventionMatchStatus.unknown);
      next = next.next;
      if (entry.call is Pass) {
        passes++;
        if (passes > (sawBid ? 3 : 4)) {
          return noMatch(ConventionMatchStatus.unknown);
        }
      } else if (entry.call is Bid) {
        if (passes >= (sawBid ? 3 : 4)) {
          return noMatch(ConventionMatchStatus.unknown);
        }
        final bid = entry.call as Bid;
        final rank = (bid.level - 1) * 5 + bid.strain.index;
        if (rank <= highestBidRank) {
          return noMatch(ConventionMatchStatus.unknown);
        }
        highestBidRank = rank;
        sawBid = true;
        passes = 0;
      } else {
        // X / XX meanings are agreement-dependent and unsupported here.
        return noMatch(ConventionMatchStatus.unknown);
      }
    }

    final nonPass = auction.where((entry) => entry.call is! Pass).toList();
    if (nonPass.isEmpty) return noMatch(ConventionMatchStatus.unknown);
    final opener = nonPass.first.seat;
    // Any opponent bid, even a later unmodeled one, invalidates our
    // uncontested teaching assumptions.
    if (nonPass.any((entry) =>
        entry.seat != opener && entry.seat != opener.partner)) {
      return noMatch(ConventionMatchStatus.unknown);
    }

    final rules = profile.agreements.where((rule) =>
        !rule.previewOnly || profile.revision >= 2);
    ConventionAgreement? match;
    for (final rule in rules) {
      if (rule.calls.length != nonPass.length ||
          rule.relativeSeats.length != nonPass.length) {
        continue;
      }
      var valid = true;
      for (var i = 0; i < nonPass.length; i++) {
        final expectedSeat = Seat.values[
            (opener.index + rule.relativeSeats[i]) % Seat.values.length];
        if (nonPass[i].call.code != rule.calls[i] ||
            nonPass[i].seat != expectedSeat) {
          valid = false;
          break;
        }
      }
      if (valid) {
        if (match != null) return noMatch(ConventionMatchStatus.unknown);
        match = rule;
      }
    }
    if (match == null) return noMatch(ConventionMatchStatus.unknown);
    return BidExplanation(
      status: ConventionMatchStatus.matched,
      profileId: profile.id,
      revision: profile.revision,
      ruleId: match.ruleId,
      meaningKey: match.meaningKey,
      assumptionKey: match.assumptionKey,
      reviewStatus: match.reviewStatus,
      reference: match.reference,
      preview: match.previewOnly,
    );
  }
}
