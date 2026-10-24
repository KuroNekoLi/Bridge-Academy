import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:test/test.dart';

void main() {
  CustomConventionDraft draft() => CustomConventionDraft.create(
    id: 'private_1', label: 'My SAYC', base: ConventionCatalog.sayc);

  test('M4.1 cloned revision is an archive, not a runnable model', () {
    final original = draft();
    expect(original.revision, 1);
    expect(original.rules, isEmpty);
    expect(original.runtimeSupport, 'UNCHANGED_BASE_ONLY');
    expect(original.isPlayableCustomSystem, isFalse);
    expect(original.base.profileFingerprint,
        ConventionCatalog.sayc.profileFingerprint);
    expect(CustomConventionDraft.fromJson(original.toJson()).fingerprint,
        original.fingerprint);
    expect(ConventionCatalog.resolve('private_1', 1), isNull);
  });

  test('editing a slot creates chained, immutable, reproducible revisions', () {
    final initial = draft();
    final r2 = initial.withRule(CustomConventionRule(
      CustomRuleSlot.twoClubsOverOneNotrump, 'NATURAL'));
    final r3 = r2.withRule(CustomConventionRule(
      CustomRuleSlot.twoClubsOverOneNotrump, 'STAYMAN'));
    final r4 = r3.withoutRule(CustomRuleSlot.twoClubsOverOneNotrump);
    expect(initial.rules, isEmpty);
    expect(r2.revision, 2);
    expect(r3.revision, 3);
    expect(r3.previousFingerprint, r2.fingerprint);
    expect(r4.previousFingerprint, r3.fingerprint);
    expect(r3.fingerprint, isNot(r2.fingerprint));
    expect(r4.runtimeSupport, 'UNCHANGED_BASE_ONLY');
    expect(r2.runtimeSupport, 'ENGINE_UNVERIFIED');
    expect(r2.isPlayableCustomSystem, isFalse);
    expect(r3.rules.single.choice, 'STAYMAN');
    expect(CustomConventionDraft.fromJson(r3.toJson()).fingerprint,
        r3.fingerprint);
  });

  test('only finite agreed rule choices can be edited', () {
    expect(
      () => CustomConventionRule(
        CustomRuleSlot.twoDiamondsOverOneNotrump, 'CALL_NATIVE_LIB'),
      throwsFormatException,
    );
    expect(
      () => CustomConventionDraft.create(
        id: 'bad', label: 'A', base: ConventionCatalog.precisionMeckwell),
      throwsFormatException,
    );
    expect(
      () => CustomConventionDraft.create(
        id: 'bad/path', label: 'A', base: ConventionCatalog.sayc),
      throwsFormatException,
    );
  });

  test('unknown fields, forged engine capability and altered rule fail closed', () {
    final v = draft().withRule(CustomConventionRule(
      CustomRuleSlot.oneNotrumpOpening, '13_15'));
    final json = v.toJson();
    expect(
      () => CustomConventionDraft.fromJson({
        ...json, 'runtimeSupport': 'SUPPORTED',
      }),
      throwsFormatException,
    );
    final mutated = Map<String, Object?>.from(json);
    mutated['rules'] = [
      {'slot': 'oneNotrumpOpening', 'choice': '15_17'},
    ];
    expect(() => CustomConventionDraft.fromJson(mutated),
        throwsFormatException);
    expect(
      () => CustomConventionDraft.fromJson({...json, 'privateDeal': 'secret'}),
      throwsFormatException,
    );
    expect(() => CustomConventionDraft.fromJson({
      ...json, 'fingerprint': 'sha256:fake',
    }), throwsFormatException);
  });

  test('canonical SHA ignores input rule ordering on validated recovery', () {
    final a = draft().withRule(CustomConventionRule(
      CustomRuleSlot.oneNotrumpOpening, '15_17')).withRule(
        CustomConventionRule(CustomRuleSlot.twoClubsOverOneNotrump, 'STAYMAN'));
    // Hash includes revision ancestry by design; raw reordered JSON of the
    // same committed revision is semantically identical.
    final map = Map<String, Object?>.from(a.toJson());
    map['rules'] = (map['rules'] as List).reversed.toList();
    expect(CustomConventionDraft.fromJson(map).fingerprint, a.fingerprint);
  });

  test('cross-meaning duplicate auction is a validation error', () {
    final v = draft().withRule(CustomConventionRule(
      CustomRuleSlot.twoClubsOverOneNotrump, 'STAYMAN'));
    final encoded = Map<String, Object?>.from(v.toJson());
    encoded['rules'] = [
      {'slot': 'twoClubsOverOneNotrump', 'choice': 'STAYMAN'},
      {'slot': 'twoClubsOverOneNotrump', 'choice': 'NATURAL'},
    ];
    expect(() => CustomConventionDraft.fromJson(encoded),
        throwsFormatException);
    expect(v.issues, isEmpty);
    expect(v.canSave, isTrue);
  });

  test('original rules collection and canonical versions are immutable', () {
    final r = draft().withRule(CustomConventionRule(
      CustomRuleSlot.twoHeartsOverOneNotrump, 'TRANSFER_SPADES'));
    expect(() => r.rules.clear(), throwsUnsupportedError);
    expect(r.rules.single.choice, 'TRANSFER_SPADES');
    expect(CustomRuleCatalog.publicAuctions[
        CustomRuleSlot.twoHeartsOverOneNotrump], '1NT-P-2H');
  });
}
