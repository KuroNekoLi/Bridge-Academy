import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:test/test.dart';

void main() {
  test('M4.7 operator review plan requires 6 scenarios per edited rule, '
      'never engine attests or invents behavior', () {
    final base = CustomConventionDraft.create(
      id: 'my_sayc', label: 'My SAYC', base: ConventionCatalog.sayc,
    );
    final changed = base.withRule(CustomConventionRule(
      CustomRuleSlot.oneNotrumpOpening, '13_15')).withRule(
      CustomConventionRule(
        CustomRuleSlot.twoClubsOverOneNotrump, 'NATURAL'));
    final plan = CustomConventionReviewPlan.forDraft(changed);
    expect(plan.tasks, hasLength(12));
    expect(plan.targetExpertGoldenCases, 100);
    expect(plan.observedEngineGoldenCases, 0);
    expect(plan.isEngineVerified, false);
    expect(plan.eligibleForProduction, false);
    expect(plan.tasks.every((t) =>
        t.ruleId.startsWith('USER_DRAFT:')), true);
    expect(plan.tasks.where((t) => t.publicAuction == '1NT'),
        hasLength(6));
    final serialized = plan.toJson();
    expect(serialized['engineCertified'], false);
    expect(serialized['verifiedCases'], 0);
    expect(serialized['baseFingerprint'],
        ConventionCatalog.sayc.profileFingerprint);
    expect(serialized['draftFingerprint'], changed.fingerprint);
    expect(serialized.containsKey('hand'), false);
    expect(serialized.containsKey('deal'), false);
    final entries = serialized['tasks'] as List;
    expect(entries.every((x) => (x as Map)['reviewStatus'] ==
        'NOT_REVIEWED'), true);
    expect(entries.every((x) => (x as Map)['engineObservedBehavior'] ==
        'NOT_RUN'), true);
    expect(() => plan.tasks.clear(), throwsUnsupportedError);
  });

  test('M4.7 six scenarios use bounded public auction prefixes',
      () {
    final edited = CustomConventionDraft.create(
        id: 'my_21gf', label: 'My 2/1',
        base: ConventionCatalog.twoOverOne,
      ).withRule(CustomConventionRule(
        CustomRuleSlot.twoDiamondsOverOneNotrump, 'TRANSFER_HEARTS'));
    final plan = CustomConventionReviewPlan.forDraft(edited);
    expect(plan.tasks.map((t) => t.scenario).toSet().length,
        ConventionReviewScenario.values.length);
    expect(plan.tasks.singleWhere((t) =>
        t.scenario == ConventionReviewScenario.opponentInterpretation)
        .publicAuction, '1NT-P-2D');
    expect(CustomConventionReviewPlan.forDraft(
        CustomConventionDraft.create(id: 'plain_21',
          label: 'Unchanged', base: ConventionCatalog.twoOverOne))
        .tasks, isEmpty);
  });
}
