import 'custom_convention_archive.dart';
import 'custom_convention_draft.dart';

/// Describes user-authored rule changes, not changes to BEN/BBA behavior.
enum CustomRuleChangeKind { added, changed, removed }

final class CustomRuleChange {
  const CustomRuleChange({
    required this.slot,
    required this.auction,
    required this.kind,
    required this.beforeChoice,
    required this.afterChoice,
  });

  final CustomRuleSlot slot;
  final String auction;
  final CustomRuleChangeKind kind;
  final String? beforeChoice;
  final String? afterChoice;
}

final class CustomRevisionDiff {
  CustomRevisionDiff._({
    required this.fromRevision,
    required this.toRevision,
    required this.fromFingerprint,
    required this.toFingerprint,
    required List<CustomRuleChange> changes,
  }) : changes = List.unmodifiable(changes);

  final int fromRevision;
  final int toRevision;
  final String fromFingerprint;
  final String toFingerprint;
  final List<CustomRuleChange> changes;

  bool get isUnchanged => changes.isEmpty;
  bool get isEngineValidated => false;
}

/// Comparisons are scoped to one verified immutable archive, not arbitrary
/// uploaded versions. Consequently they cannot launder an unrelated base,
/// a fork, or a fake runtime capability into a "verified" convention.
abstract final class CustomConventionHistory {
  static CustomRevisionDiff compare(
    CustomConventionArchive archive, {
    required int fromRevision,
    required int toRevision,
  }) {
    if (fromRevision < 1 || fromRevision >= toRevision ||
        toRevision > archive.revisions.length) {
      throw const FormatException('Invalid convention revision comparison');
    }
    final before = archive.revisions[fromRevision - 1];
    final after = archive.revisions[toRevision - 1];
    if (before.revision != fromRevision || after.revision != toRevision ||
        before.id != after.id || before.base != after.base) {
      throw const FormatException('Mismatched convention history');
    }
    final fromRules = {for (final r in before.rules) r.slot: r.choice};
    final toRules = {for (final r in after.rules) r.slot: r.choice};
    final changes = <CustomRuleChange>[];
    for (final slot in CustomRuleSlot.values) {
      final previous = fromRules[slot];
      final current = toRules[slot];
      if (previous == current) continue;
      final kind = previous == null
          ? CustomRuleChangeKind.added
          : current == null
              ? CustomRuleChangeKind.removed
              : CustomRuleChangeKind.changed;
      changes.add(CustomRuleChange(
        slot: slot,
        auction: CustomRuleCatalog.publicAuctions[slot]!,
        kind: kind,
        beforeChoice: previous,
        afterChoice: current,
      ));
    }
    return CustomRevisionDiff._(
      fromRevision: fromRevision,
      toRevision: toRevision,
      fromFingerprint: before.fingerprint,
      toFingerprint: after.fingerprint,
      changes: changes,
    );
  }
}
