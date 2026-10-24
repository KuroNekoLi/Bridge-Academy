import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'game_systems.dart';

/// Finite, human-editable annotation slots. No arbitrary rule script, eval,
/// .bbsa patching or implied neural network retraining.
enum CustomRuleSlot {
  oneNotrumpOpening,
  twoClubsOverOneNotrump,
  twoDiamondsOverOneNotrump,
  twoHeartsOverOneNotrump,
}

enum DraftIssueSeverity { warning, error }

final class DraftIssue {
  const DraftIssue(this.code, this.severity, this.slot);
  final String code;
  final DraftIssueSeverity severity;
  final CustomRuleSlot? slot;
}

abstract final class CustomRuleCatalog {
  static const Map<CustomRuleSlot, List<String>> choices = {
    CustomRuleSlot.oneNotrumpOpening: ['12_14', '13_15', '15_17'],
    CustomRuleSlot.twoClubsOverOneNotrump: ['STAYMAN', 'NATURAL'],
    CustomRuleSlot.twoDiamondsOverOneNotrump: ['TRANSFER_HEARTS', 'NATURAL'],
    CustomRuleSlot.twoHeartsOverOneNotrump: ['TRANSFER_SPADES', 'NATURAL'],
  };

  static const Map<CustomRuleSlot, String> publicAuctions = {
    CustomRuleSlot.oneNotrumpOpening: '1NT',
    CustomRuleSlot.twoClubsOverOneNotrump: '1NT-P-2C',
    CustomRuleSlot.twoDiamondsOverOneNotrump: '1NT-P-2D',
    CustomRuleSlot.twoHeartsOverOneNotrump: '1NT-P-2H',
  };
}

final class CustomConventionRule {
  CustomConventionRule(this.slot, this.choice) {
    if (!CustomRuleCatalog.choices[slot]!.contains(choice)) {
      throw const FormatException('Unsupported rule option');
    }
  }

  final CustomRuleSlot slot;
  final String choice;

  Map<String, String> toJson() => {
    'slot': slot.name,
    'choice': choice,
  };

  factory CustomConventionRule.fromJson(Object? raw) {
    if (raw is! Map || raw.length != 2 ||
        !raw.keys.toSet().containsAll(const ['slot', 'choice']) ||
        raw['slot'] is! String || raw['choice'] is! String) {
      throw const FormatException('Invalid custom rule schema');
    }
    try {
      return CustomConventionRule(
        CustomRuleSlot.values.byName(raw['slot'] as String),
        raw['choice'] as String,
      );
    } catch (_) {
      throw const FormatException('Unsupported custom convention rule');
    }
  }
}

/// This is not a live game profile and MUST NOT enter ConventionCatalog,
/// PartnershipSystem or BEN/EPBot routing as a playable system.
final class CustomConventionDraft {
  CustomConventionDraft._({
    required this.id,
    required this.label,
    required this.base,
    required this.revision,
    required this.previousFingerprint,
    required List<CustomConventionRule> rules,
  }) : rules = List.unmodifiable(rules),
       fingerprint = _digest(id, label, base, revision,
           previousFingerprint, rules);

  factory CustomConventionDraft.create({
    required String id,
    required String label,
    required PartnershipSystem base,
  }) {
    _verifyIdentity(id, label);
    _verifyBase(base);
    return CustomConventionDraft._(
      id: id, label: label, base: base, revision: 1,
      previousFingerprint: null, rules: const [],
    );
  }

  final String id;
  final String label;
  final PartnershipSystem base;
  final int revision;
  final String? previousFingerprint;
  final List<CustomConventionRule> rules;
  final String fingerprint;

  /// "ENGINE_UNVERIFIED" is a deliberately immutable release guard.
  /// A UI user editing a rule cannot authorize BEN NN retraining or a BBA CC.
  String get runtimeSupport =>
      rules.isEmpty ? 'UNCHANGED_BASE_ONLY' : 'ENGINE_UNVERIFIED';

  bool get isPlayableCustomSystem => false;

  List<DraftIssue> get issues {
    final found = <DraftIssue>[];
    final seen = <CustomRuleSlot, String>{};
    for (final rule in rules) {
      if (seen.containsKey(rule.slot)) {
        found.add(DraftIssue(
          seen[rule.slot] == rule.choice
              ? 'duplicate_rule' : 'conflicting_auction_meaning',
          seen[rule.slot] == rule.choice
              ? DraftIssueSeverity.warning : DraftIssueSeverity.error,
          rule.slot,
        ));
      }
      seen[rule.slot] = rule.choice;
    }
    if (rules.length > CustomRuleSlot.values.length) {
      found.add(const DraftIssue(
          'too_many_rules', DraftIssueSeverity.error, null));
    }
    return List.unmodifiable(found);
  }

  bool get canSave => issues.every(
      (issue) => issue.severity != DraftIssueSeverity.error);

  /// Replacing a slot creates a NEW revision; old snapshots stay unchanged.
  CustomConventionDraft withRule(CustomConventionRule value) {
    final next = [
      for (final rule in rules)
        if (rule.slot != value.slot) rule,
      value,
    ];
    return _next(next);
  }

  CustomConventionDraft withoutRule(CustomRuleSlot slot) =>
      _next([for (final rule in rules) if (rule.slot != slot) rule]);

  CustomConventionDraft _next(List<CustomConventionRule> next) =>
      CustomConventionDraft._(
        id: id, label: label, base: base,
        revision: revision + 1, previousFingerprint: fingerprint,
        rules: next,
      );

  static String _digest(
    String id, String label, PartnershipSystem base, int revision,
    String? previous, List<CustomConventionRule> rules,
  ) {
    final sorted = [...rules]..sort((a, b) =>
        a.slot.index.compareTo(b.slot.index));
    final canonical = jsonEncode([
      'bridge-academy-custom-draft-v1',
      id, label, base.profileFingerprint, revision, previous,
      for (final r in sorted) [r.slot.name, r.choice],
    ]);
    return 'sha256:${sha256.convert(utf8.encode(canonical))}';
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'id': id,
    'label': label,
    'base': base.toJson(),
    'revision': revision,
    'previousFingerprint': previousFingerprint,
    'rules': rules.map((rule) => rule.toJson()).toList(growable: false),
    'fingerprint': fingerprint,
    'runtimeSupport': runtimeSupport,
  };

  factory CustomConventionDraft.fromJson(Object? raw) {
    const fields = {
      'schemaVersion', 'id', 'label', 'base', 'revision',
      'previousFingerprint', 'rules', 'fingerprint', 'runtimeSupport',
    };
    if (raw is! Map || raw.length != fields.length ||
        !raw.keys.toSet().containsAll(fields) ||
        raw['schemaVersion'] != 1 ||
        raw['id'] is! String || raw['label'] is! String ||
        raw['revision'] is! int || (raw['revision'] as int) < 1 ||
        raw['rules'] is! List) {
      throw const FormatException('Invalid custom draft schema');
    }
    final id = raw['id'] as String;
    final label = raw['label'] as String;
    _verifyIdentity(id, label);
    final base = PartnershipSystem.fromTrustedJson(raw['base']);
    _verifyBase(base);
    final previous = raw['previousFingerprint'];
    if (previous != null &&
        (previous is! String ||
          !RegExp(r'^sha256:[a-f0-9]{64}$').hasMatch(previous))) {
      throw const FormatException('Invalid previous revision digest');
    }
    if (((raw['revision'] as int) == 1) != (previous == null)) {
      throw const FormatException('Invalid revision linkage');
    }
    final rules = (raw['rules'] as List)
        .map(CustomConventionRule.fromJson).toList();
    if (rules.length > 16) {
      throw const FormatException('Too many custom rules');
    }
    final restored = CustomConventionDraft._(
      id: id, label: label, base: base,
      revision: raw['revision'] as int,
      previousFingerprint: previous as String?,
      rules: rules,
    );
    if (raw['fingerprint'] != restored.fingerprint ||
        raw['runtimeSupport'] != restored.runtimeSupport ||
        !restored.canSave) {
      throw const FormatException('Draft fingerprint or rules mismatch');
    }
    return restored;
  }

  static void _verifyIdentity(String id, String label) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{3,40}$').hasMatch(id) ||
        label.trim() != label || label.isEmpty ||
        label.runes.length > 48 || label.contains(RegExp(r'[\\x00-\\x1f]'))) {
      throw const FormatException('Invalid custom draft identity');
    }
  }

  static void _verifyBase(PartnershipSystem base) {
    if (base != ConventionCatalog.sayc &&
        base != ConventionCatalog.twoOverOne) {
      throw const FormatException('Draft must clone a verified BEN base');
    }
  }
}
