import 'package:bridge_academy_flutter/src/bidding_practice.dart';
import 'package:bridge_academy_flutter/src/conventions/convention_profile.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter_test/flutter_test.dart';

BidContext auctionOf(
  List<Call> calls, {
  Seat dealer = Seat.north,
  Seat viewer = Seat.south,
  Vulnerability vulnerability = Vulnerability.none,
}) {
  var actor = dealer;
  final entries = <AuctionEntry>[];
  for (final call in calls) {
    entries.add(AuctionEntry(actor, call));
    actor = actor.next;
  }
  return BidContext(
    dealer: dealer,
    viewer: viewer,
    vulnerability: vulnerability,
    auction: entries,
  );
}

void main() {
  const oneNotrump = Bid(1, Strain.notrump);

  group('versioned convention domain', () {
    test('B3.1 ID and revision remain stable', () {
      expect(ConventionProfiles.basic.id, BiddingPracticeProfile.id);
      expect(ConventionProfiles.basic.revision, BiddingPracticeProfile.revision);
      expect(ConventionProfiles.basic.locales, containsAll(['zh-TW', 'en']));
      expect(ConventionProfiles.basic.agreements.length, 4);
      expect(ConventionProfiles.preview.revision, 2);
      expect(ConventionProfiles.preview.agreements.length, 7);
      expect(ConventionProfiles.basic.agreements.map((a) => a.ruleId).toSet().length, 4);
    });

    test('opening after passes from any seat and vulnerability', () {
      for (final dealer in Seat.values) {
        for (final vulnerability in Vulnerability.values) {
          final view = auctionOf([
            const Pass(), oneNotrump, const Pass(),
          ], dealer: dealer, vulnerability: vulnerability);
          final result = ConventionExplanationEngine.resolve(view);
          expect(result.status, ConventionMatchStatus.matched);
          expect(result.ruleId, 'NAT-1NT-OPEN');
          expect(result.meaningKey, 'biddingOpening1NT');
          expect(result.reviewStatus, ConventionReviewStatus.unreviewed);
        }
      }
    });

    test('partner 2NT invitation, partner 3NT game, opener 3NT acceptance', () {
      final invitation = auctionOf([
        oneNotrump, const Pass(), const Bid(2, Strain.notrump),
        const Pass(),
      ]);
      expect(ConventionExplanationEngine.resolve(invitation).ruleId, 'NAT-2NT-INV');
      final game = auctionOf([
        oneNotrump, const Pass(), const Bid(3, Strain.notrump),
      ]);
      expect(ConventionExplanationEngine.resolve(game).ruleId, 'NAT-3NT-GAME');
      final acceptance = auctionOf([
        oneNotrump, const Pass(), const Bid(2, Strain.notrump),
        const Pass(), const Bid(3, Strain.notrump),
        const Pass(), const Pass(), const Pass(),
      ]);
      expect(ConventionExplanationEngine.resolve(acceptance).ruleId,
          'NAT-3NT-ACCEPT');
    });

    test('B3.1 helper delegates to engine without changing response keys', () {
      final history = auctionOf([
        oneNotrump, const Pass(), const Bid(2, Strain.notrump),
      ]).auction;
      expect(BiddingPracticeProfile.explain(history), 'biddingInvite2NT');
    });

    test('Stayman and Jacoby only match enabled preview profile', () {
      final candidates = <(Bid, String)>[
        (const Bid(2, Strain.clubs), 'PREVIEW-STAYMAN-2C'),
        (const Bid(2, Strain.diamonds), 'PREVIEW-JACOBY-2D'),
        (const Bid(2, Strain.hearts), 'PREVIEW-JACOBY-2H'),
      ];
      for (final (bid, id) in candidates) {
        final context = auctionOf([oneNotrump, const Pass(), bid]);
        expect(ConventionExplanationEngine.resolve(context).status,
            ConventionMatchStatus.unknown);
        final result = ConventionExplanationEngine.resolve(context,
            profile: ConventionProfiles.preview);
        expect(result.status, ConventionMatchStatus.matched);
        expect(result.ruleId, id);
        expect(result.preview, true);
        expect(result.reviewStatus, ConventionReviewStatus.unreviewed);
        expect(result.reference, startsWith('https://cdn.acbl.org/'));
      }
    });

    test('interference, double/redouble and nonopening 1NT are UNKNOWN', () {
      final contaminated = <List<Call>>[
        [oneNotrump, const Bid(2, Strain.clubs), const Bid(2, Strain.notrump)],
        [oneNotrump, const DoubleCall(), const Bid(2, Strain.clubs)],
        [oneNotrump, const Pass(), const RedoubleCall()],
        [const Bid(1, Strain.clubs), const Pass(), oneNotrump],
        [oneNotrump, const Pass(), const Bid(2, Strain.clubs),
         const Bid(2, Strain.hearts)],
        [oneNotrump, const Pass(), const Bid(2, Strain.clubs),
         const Pass(), const Bid(2, Strain.diamonds)],
      ];
      for (final calls in contaminated) {
        expect(ConventionExplanationEngine.resolve(auctionOf(calls),
          profile: ConventionProfiles.preview).status,
            ConventionMatchStatus.unknown);
      }
    });

    test('invalid chronology, invalid bid hierarchy, extra calls and passes', () {
      final wrongSeat = BidContext(
        dealer: Seat.north, viewer: Seat.south,
        vulnerability: Vulnerability.none,
        auction: const [
          AuctionEntry(Seat.north, Bid(1, Strain.notrump)),
          AuctionEntry(Seat.south, Bid(2, Strain.notrump)),
        ],
      );
      expect(ConventionExplanationEngine.resolve(wrongSeat).status,
          ConventionMatchStatus.unknown);
      for (final invalid in <List<Call>>[
        [const Bid(2, Strain.notrump), const Pass(),
         const Bid(1, Strain.notrump)],
        [oneNotrump, const Pass(), const Pass(), const Pass(),
         const Bid(2, Strain.notrump)],
        [const Pass(), const Pass(), const Pass(), const Pass(),
         oneNotrump],
      ]) {
        expect(ConventionExplanationEngine.resolve(auctionOf(invalid)).status,
            ConventionMatchStatus.unknown);
      }
    });

    test('unsupported profile version and unknown hand are fail-closed', () {
      final context = auctionOf([oneNotrump]);
      final unsupported = ConventionExplanationEngine.resolve(context,
        expectedRevision: 999);
      expect(unsupported.status, ConventionMatchStatus.unsupported);
      expect(unsupported.ruleId, null);
      expect(ConventionExplanationEngine.resolve(auctionOf([
        const Pass(), const Pass(),
      ])).status, ConventionMatchStatus.unknown);
    });
  });
}
