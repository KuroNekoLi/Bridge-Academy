import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:test/test.dart';

void main() {
  final systems = GameSystems(
      northSouth: ConventionCatalog.sayc,
      eastWest: ConventionCatalog.twoOverOne);

  CustomConventionDraft userCard() => CustomConventionDraft.create(
        id: 'coach_sayc',
        label: 'My SAYC',
        base: ConventionCatalog.sayc,
      ).withRule(CustomConventionRule(
        CustomRuleSlot.twoClubsOverOneNotrump, 'STAYMAN',
      ));

  test('M5.1 public dealer/seat attribution and immutable version pins', () {
    final report = PublicAuctionCoach.review(
      dealer: 'E', systems: systems, calls: ['1NT', 'P', '2C', 'P'],
    );
    expect(report.entries.map((e) => e.seat), ['E', 'S', 'W', 'N']);
    expect(report.entries.map((e) => e.profileId), [
      'BA-21GF', 'BA-SAYC', 'BA-21GF', 'BA-SAYC',
    ]);
    expect(report.entries[2].evidence, CoachMeaningEvidence.baseNotReviewed);
    expect(report.entries[2].isEngineVerified, false);
    expect(report.entries[2].userSelectedMeaning, isNull);
    expect(report.gameSystemsFingerprint, systems.fingerprint);
    expect(report.verifiedCandidateCalls, isEmpty);
    expect(report.expertApproved, false);
    expect(report.explainsBenPrivateReasoning, false);
    expect(() => report.entries.clear(), throwsUnsupportedError);
  });

  test('M5.2 only annotates author intent for specified partnership', () {
    final shared = GameSystems(
      northSouth: ConventionCatalog.sayc,
      eastWest: ConventionCatalog.sayc,
    );
    final report = PublicAuctionCoach.review(
      dealer: 'N',
      systems: shared,
      calls: ['1NT', 'PASS', '2C', 'P'],
      draft: userCard(),
      draftNorthSouth: true,
    );
    expect(report.entries[2].publicPrefix, '1NT-P-2C');
    expect(report.entries[2].evidence, CoachMeaningEvidence.userDraftOnly);
    expect(report.entries[2].ruleId,
        'USER_DRAFT:twoClubsOverOneNotrump');
    expect(report.entries[2].userSelectedMeaning, 'STAYMAN');
    expect(report.entries[2].isEngineVerified, false);
    expect(report.draftFingerprint, userCard().fingerprint);
    expect(report.verifiedCandidateCalls, isEmpty);

    final otherSide = PublicAuctionCoach.review(
      dealer: 'E', systems: shared, calls: ['1NT', 'P', '2C'],
      draft: userCard(), draftNorthSouth: true,
    );
    expect(otherSide.entries.last.userSelectedMeaning, isNull);
    expect(otherSide.entries.last.evidence,
        CoachMeaningEvidence.baseNotReviewed);
  });

  test('M5.1 unknown includes noncatalog auction and contested context', () {
    final r = PublicAuctionCoach.review(
      dealer: 'N', systems: systems, calls: ['1H', 'X', 'XX', 'P'],
    );
    expect(r.entries.every(
        (entry) => entry.evidence == CoachMeaningEvidence.unknown), true);
    expect(r.entries.last.publicPrefix, '1H-X-XX-P');
  });

  test('M5.1 rejects malformed input, unknown dealer and unbounded auction', () {
    for (final calls in [
      ['1NT', 'P', '2NT!'],
      ['1NT', 'HIDDEN_CARD'],
      List.filled(65, 'P'),
      ['1NT', ' p ', '2C'],
      ['{privatedeal}'],
    ]) {
      expect(() => PublicAuctionCoach.review(
        dealer: 'N', systems: systems, calls: calls),
        throwsFormatException);
    }
    expect(() => PublicAuctionCoach.review(
        dealer: 'Q', systems: systems, calls: const []),
        throwsFormatException);
  });

  test('M5.2 forbids a user draft from masquerading as another side', () {
    expect(() => PublicAuctionCoach.review(
      dealer: 'N', systems: systems, calls: ['1NT', 'P', '2C'],
      draft: userCard(),
    ), throwsFormatException);
    expect(() => PublicAuctionCoach.review(
      dealer: 'N', systems: systems, calls: ['1NT', 'P', '2C'],
      draft: userCard(), draftNorthSouth: false,
    ), throwsFormatException);
    expect(() => PublicAuctionCoach.review(
      dealer: 'N', systems: systems, calls: ['1NT', 'P', '2C'],
      draftNorthSouth: true,
    ), throwsFormatException);
  });

  test('M5.1 canonical 1N notation and no false observed meaning', () {
    final report = PublicAuctionCoach.review(
      dealer: 'N', systems: systems, calls: ['1N', 'P', '2C'],
    );
    expect(report.entries.last.publicPrefix, '1NT-P-2C');
    expect(report.entries.last.evidence,
        CoachMeaningEvidence.baseNotReviewed);
  });
}
