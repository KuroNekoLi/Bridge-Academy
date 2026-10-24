import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:test/test.dart';

void main() {
  CustomConventionDraft initial() => CustomConventionDraft.create(
      id: 'custom_21', label: 'My 2/1', base: ConventionCatalog.twoOverOne);

  test('M4.2 appends exactly consecutive immutable snapshots', () {
    final one = initial();
    final two = one.withRule(CustomConventionRule(
        CustomRuleSlot.twoClubsOverOneNotrump, 'NATURAL'));
    final three = two.withRule(CustomConventionRule(
        CustomRuleSlot.oneNotrumpOpening, '15_17'));
    final archive = CustomConventionArchive.empty()
        .append(one).append(two).append(three);
    expect(archive.revisions, hasLength(3));
    expect(archive.latest!.fingerprint, three.fingerprint);
    expect(archive.revisions.first.rules, isEmpty);
    expect(archive.latest!.runtimeSupport, 'ENGINE_UNVERIFIED');
    expect(CustomConventionArchive.fromJson(archive.toJson())
        .latest!.fingerprint, three.fingerprint);
    expect(() => archive.revisions.clear(), throwsUnsupportedError);
  });

  test('rejects missing, forked, re-ordered and spoofed revisions', () {
    final one = initial();
    final two = one.withRule(CustomConventionRule(
        CustomRuleSlot.twoClubsOverOneNotrump, 'STAYMAN'));
    final branch = one.withRule(CustomConventionRule(
        CustomRuleSlot.twoClubsOverOneNotrump, 'NATURAL'));
    final a = CustomConventionArchive.empty().append(one).append(two);
    expect(() => a.append(branch), throwsFormatException);
    expect(() => a.append(one), throwsFormatException);
    expect(() => CustomConventionArchive.empty().append(two),
        throwsFormatException);
    final forged = a.toJson();
    forged['revisions'] = [two.toJson(), one.toJson()];
    expect(() => CustomConventionArchive.fromJson(forged),
        throwsFormatException);
    final bad = a.toJson();
    bad['revisions'] = [
      one.toJson(),
      {...two.toJson(), 'runtimeSupport': 'SUPPORTED'},
    ];
    expect(() => CustomConventionArchive.fromJson(bad),
        throwsFormatException);
  });

  test('enforces single base, identity and label throughout history', () {
    final one = initial();
    final otherBase = CustomConventionDraft.create(
        id: 'custom_21', label: 'My 2/1', base: ConventionCatalog.sayc);
    expect(() => CustomConventionArchive.empty().append(one).append(otherBase),
        throwsFormatException);
    expect(() => CustomConventionArchive.fromJson({
      'schemaVersion': 1, 'revisions': [], 'secret': 'no',
    }), throwsFormatException);
  });
  test('M4.5 portable import allows only verified forward history', () {
    final one = initial();
    final two = one.withRule(CustomConventionRule(
        CustomRuleSlot.oneNotrumpOpening, '13_15'));
    final three = two.withRule(CustomConventionRule(
        CustomRuleSlot.twoClubsOverOneNotrump, 'NATURAL'));
    final local = CustomConventionArchive.empty().append(one).append(two);
    final ahead = local.append(three);
    expect(CustomArchiveImport.compare(
        local: local, incoming: ahead, expectedBase: 'BA-21GF'),
        CustomArchiveRestore.fastForward);
    expect(CustomArchiveImport.compare(
        local: local, incoming: local, expectedBase: 'BA-21GF'),
        CustomArchiveRestore.identical);
    expect(CustomArchiveImport.compare(
        local: ahead, incoming: local, expectedBase: 'BA-21GF'),
        CustomArchiveRestore.divergent);
    final fork = CustomConventionArchive.empty().append(one).append(
        one.withRule(CustomConventionRule(
            CustomRuleSlot.oneNotrumpOpening, '12_14')));
    expect(CustomArchiveImport.compare(
        local: local, incoming: fork, expectedBase: 'BA-21GF'),
        CustomArchiveRestore.divergent);
    expect(() => CustomArchiveImport.compare(
        local: local, incoming: ahead, expectedBase: 'BA-SAYC'),
        throwsFormatException);
    expect(() => CustomArchiveImport.compare(
        local: local, incoming: CustomConventionArchive.empty(),
        expectedBase: 'BA-21GF'), throwsFormatException);
    // Portable history is data only, never accepted by live engine catalog.
    expect(ConventionCatalog.resolve(ahead.latest!.id,
        ahead.latest!.revision), isNull);
  });

}
