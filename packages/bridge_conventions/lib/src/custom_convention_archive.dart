/// Explicit restore rule. Never silently replace a locally edited history.
enum CustomArchiveRestore {
  identical,
  fastForward,
  divergent,
}

abstract final class CustomArchiveImport {
  static CustomArchiveRestore compare({
    required CustomConventionArchive local,
    required CustomConventionArchive incoming,
    required String expectedBase,
  }) {
    final candidate = incoming.latest;
    if (candidate == null || candidate.base.profileId != expectedBase) {
      throw const FormatException('Missing or wrong custom convention base');
    }
    final current = local.latest;
    if (current == null) return CustomArchiveRestore.fastForward;
    if (current.base != candidate.base ||
        current.id != candidate.id ||
        current.label != candidate.label ||
        incoming.revisions.length < local.revisions.length) {
      return CustomArchiveRestore.divergent;
    }
    for (var i = 0; i < local.revisions.length; i++) {
      if (local.revisions[i].fingerprint != incoming.revisions[i].fingerprint) {
        return CustomArchiveRestore.divergent;
      }
    }
    return local.revisions.length == incoming.revisions.length
        ? CustomArchiveRestore.identical
        : CustomArchiveRestore.fastForward;
  }
}

import 'custom_convention_draft.dart';

/// Untrusted local archive of consecutive immutable *draft* snapshots.
///
/// Verifies the adjacent revision hash chain and exact base pin. A SHA256
/// fingerprint detects accidental corruption, NOT malicious replacement of
/// an entire local archive or authorization to run the card in an AI engine.
final class CustomConventionArchive {
  CustomConventionArchive._(List<CustomConventionDraft> revisions)
      : revisions = List.unmodifiable(revisions);

  factory CustomConventionArchive.empty() =>
      CustomConventionArchive._(const []);

  final List<CustomConventionDraft> revisions;

  CustomConventionDraft? get latest =>
      revisions.isEmpty ? null : revisions.last;

  CustomConventionArchive append(CustomConventionDraft next) {
    if (!next.canSave) {
      throw const FormatException('Conflicting convention rules');
    }
    if (revisions.length >= 100) {
      throw const FormatException('Local convention archive is full');
    }
    final previous = latest;
    if (previous == null) {
      if (next.revision != 1 || next.previousFingerprint != null) {
        throw const FormatException('Archive must start at revision one');
      }
    } else if (next.id != previous.id ||
        next.base != previous.base ||
        next.label != previous.label ||
        next.revision != previous.revision + 1 ||
        next.previousFingerprint != previous.fingerprint) {
      throw const FormatException('Custom card revision chain mismatch');
    }
    return CustomConventionArchive._([...revisions, next]);
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'revisions': [for (final item in revisions) item.toJson()],
  };

  factory CustomConventionArchive.fromJson(Object? raw) {
    if (raw is! Map || raw.length != 2 ||
        raw['schemaVersion'] != 1 || raw['revisions'] is! List) {
      throw const FormatException('Invalid archive format');
    }
    final rows = raw['revisions'] as List;
    if (rows.length > 100) {
      throw const FormatException('Archive too large');
    }
    var archive = CustomConventionArchive.empty();
    for (final row in rows) {
      archive = archive.append(CustomConventionDraft.fromJson(row));
    }
    return archive;
  }
}
