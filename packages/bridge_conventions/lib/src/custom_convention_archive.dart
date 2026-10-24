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
