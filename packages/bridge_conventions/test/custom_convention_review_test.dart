import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:test/test.dart';

void main() {
  CustomConventionDraft newDraft() => CustomConventionDraft.create(
      id: 'm4_example', label: 'My SAYC', base: ConventionCatalog.sayc);

  test('M4.3 no user-defined behavior can claim BEN/BBA engine support', () {
    final initial = newDraft();
    final original = CustomConventionReviewer.assess(initial);
    expect(original.executionStatus, CustomExecutionStatus.unchangedBase);
    expect(original.canUseAsAiSystem, isFalse);
    expect(original.hasExecutableEvidence, isFalse);

    final changed = initial.withRule(CustomConventionRule(
        CustomRuleSlot.twoClubsOverOneNotrump, 'NATURAL'));
    final review = CustomConventionReviewer.assess(changed);
    expect(review.executionStatus, CustomExecutionStatus.engineEvidenceRequired);
    expect(review.canUseAsAiSystem, isFalse);
    expect(review.hasExecutableEvidence, isFalse);
    expect(review.rules.single.auction, '1NT-P-2C');
    expect(review.rules.single.choice, 'NATURAL');
    expect(review.rules.single.ruleId, startsWith('USER_DRAFT:'));
    expect(review.rules.single.reason, 'no_pinned_engine_rule_evidence');
    expect(changed.isPlayableCustomSystem, false);
    expect(ConventionCatalog.resolve(changed.id, changed.revision), isNull);
  });

  test('M4.4 previews authors intention but does not invent AI behavior', () {
    final a = newDraft().withRule(CustomConventionRule(
        CustomRuleSlot.twoClubsOverOneNotrump, 'STAYMAN'));
    final changed = CustomConventionReviewer.preview(a, '1NT-PASS-2C');
    expect(changed.auction, '1NT-P-2C');
    expect(changed.userSelectedMeaning, 'STAYMAN');
    expect(changed.source, CustomMeaningSource.userDraft);
    expect(changed.engineVerified, isFalse);
    expect(changed.ruleId, startsWith('USER_DRAFT:'));

    final base = CustomConventionReviewer.preview(a, '1NT-P-2D');
    expect(base.source, CustomMeaningSource.baseUnverified);
    expect(base.userSelectedMeaning, isNull);
    expect(base.engineVerified, isFalse);

    final unknown = CustomConventionReviewer.preview(a, '2H-P-2S');
    expect(unknown.source, CustomMeaningSource.noRule);
    expect(unknown.userSelectedMeaning, isNull);
    expect(unknown.engineVerified, isFalse);
  });

  test('M4.4 untrusted input may not guess convention meaning', () {
    final d = newDraft();
    for (final bad in [
      '', '1NT--2C', '8C', '1C-P-BBA:LIB', '1NTPASS2C',
      '1NT-P-2C; rm all', '1NT-P-2C-DEAL', '1NT-P-2C-',
      '1NT-P-2C' * 30,
    ]) {
      expect(() => CustomConventionReviewer.preview(d, bad),
          throwsFormatException, reason: bad);
    }
    expect(CustomConventionReviewer.preview(d, '1N-P-2C').auction,
        '1NT-P-2C');
  });

  test('all editable slots are identifiable without claiming evidence', () {
    var d = newDraft();
    for (final slot in CustomRuleSlot.values) {
      d = d.withRule(CustomConventionRule(
          slot, CustomRuleCatalog.choices[slot]!.first));
    }
    final report = CustomConventionReviewer.assess(d);
    expect(report.rules.length, CustomRuleSlot.values.length);
    expect(report.rules.map((x) => x.auction).toSet().length, 4);
    expect(report.rules.every((x) =>
        x.executionStatus == CustomExecutionStatus.engineEvidenceRequired),
        true);
    expect(report.canUseAsAiSystem, false);
  });
}
