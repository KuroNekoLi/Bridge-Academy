import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:test/test.dart';

void main() {
  CustomConventionArchive history() {
    final one = CustomConventionDraft.create(
      id: 'history_1', label: 'SAYC history', base: ConventionCatalog.sayc);
    final two = one.withRule(CustomConventionRule(
      CustomRuleSlot.oneNotrumpOpening, '13_15'));
    final three = two.withRule(CustomConventionRule(
      CustomRuleSlot.twoClubsOverOneNotrump, 'STAYMAN'));
    final four = three.withRule(CustomConventionRule(
      CustomRuleSlot.oneNotrumpOpening, '15_17'));
    final five = four.withoutRule(CustomRuleSlot.twoClubsOverOneNotrump);
    return CustomConventionArchive.empty().append(one)
        .append(two).append(three).append(four).append(five);
  }

  test('M4.6 changed, added and removed rules carry public auction provenance',
      () {
    final archive = history();
    final diff = CustomConventionHistory.compare(
      archive, fromRevision: 3, toRevision: 5);
    expect(diff.fromRevision, 3);
    expect(diff.toRevision, 5);
    expect(diff.changes, hasLength(2));
    expect(diff.isEngineValidated, isFalse);
    final nt = diff.changes.singleWhere(
        (c) => c.slot == CustomRuleSlot.oneNotrumpOpening);
    expect(nt.kind, CustomRuleChangeKind.changed);
    expect(nt.auction, '1NT');
    expect(nt.beforeChoice, '13_15');
    expect(nt.afterChoice, '15_17');
    final club = diff.changes.singleWhere(
        (c) => c.slot == CustomRuleSlot.twoClubsOverOneNotrump);
    expect(club.kind, CustomRuleChangeKind.removed);
    expect(club.afterChoice, isNull);
    expect(club.beforeChoice, 'STAYMAN');
  });

  test('M4.6 supports older revisions and stable hashes', () {
    final archive = history();
    final added = CustomConventionHistory.compare(
        archive, fromRevision: 1, toRevision: 2);
    expect(added.changes.single.kind, CustomRuleChangeKind.added);
    expect(added.changes.single.beforeChoice, isNull);
    expect(added.changes.single.afterChoice, '13_15');
    expect(added.fromFingerprint, archive.revisions.first.fingerprint);
    expect(added.toFingerprint, archive.revisions[1].fingerprint);
    expect(() => added.changes.clear(), throwsUnsupportedError);
    final empty = CustomConventionHistory.compare(
        archive, fromRevision: 2, toRevision: 5);
    expect(empty.isUnchanged, isFalse);
  });

  test('M4.6 refuses unrecorded or reversed revisions', () {
    final archive = history();
    for (final pair in [[0, 3], [3, 3], [5, 2], [1, 6]]) {
      expect(() => CustomConventionHistory.compare(archive,
          fromRevision: pair[0], toRevision: pair[1]),
          throwsFormatException);
    }
    expect(() => CustomConventionHistory.compare(
      CustomConventionArchive.empty(), fromRevision: 1, toRevision: 2,
    ), throwsFormatException);
  });
}
