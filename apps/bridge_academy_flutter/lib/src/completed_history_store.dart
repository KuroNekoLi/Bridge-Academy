import 'dart:convert';

import 'package:bridge_core/bridge_core.dart';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_session_persistence.dart';
import 'session_persistence.dart';

/// One terminal board. Archive is PRIVILEGED (all four hands); never pass this
/// object to Flutter widgets, telemetry, logs or an AI. Use [HistorySummary].
final class StoredHistoryBoard {
  const StoredHistoryBoard({
    required this.id,
    required this.savedAt,
    required this.archive,
  });

  final String id;
  final DateTime savedAt;
  final String archive;
}

final class HistorySummary {
  const HistorySummary({
    required this.id,
    required this.savedAt,
    required this.boardNumber,
    required this.humanSeat,
    required this.contract,
    required this.score,
    required this.tricks,
    required this.isPractice,
  });
  final String id;
  final DateTime savedAt;
  final int boardNumber;
  final Seat humanSeat;
  final String contract;
  final int score;
  final int tricks;
  final bool isPractice;
}

abstract interface class CompletedHistoryStore {
  Future<List<StoredHistoryBoard>> read();
  Future<void> write(List<StoredHistoryBoard> items);
  /// A deletion tombstone prevents a still-current finished checkpoint from
  /// silently recreating the same history item after an app restart.
  Future<void> delete(String id);
  Future<bool> isDeleted(String id);
}

/// Test-only, process-local storage. Not suitable for player history.
final class MemoryCompletedHistoryStore implements CompletedHistoryStore {
  List<StoredHistoryBoard> _records = [];
  final Set<String> _deletedIds = {};

  @override
  Future<List<StoredHistoryBoard>> read() async => List.of(_records);

  @override
  Future<void> write(List<StoredHistoryBoard> items) async {
    _records = List.of(items.where((item) => !_deletedIds.contains(item.id)));
  }

  @override
  Future<void> delete(String id) async {
    _deletedIds.add(id);
    _records = _records.where((item) => item.id != id).toList();
  }

  @override
  Future<bool> isDeleted(String id) async => _deletedIds.contains(id);
}

/// Encrypted, single-record bounded history collection. Each update commits
/// the complete ordered collection into its OWN storage namespace, leaving
/// the active recovery checkpoint untouched.
///
/// Web is origin-local WebCrypto encrypted best-effort storage, not ACID; no
/// protection against XSS, malicious extensions or concurrent browser tabs.
final class EncryptedCompletedHistoryStore implements CompletedHistoryStore {
  EncryptedCompletedHistoryStore({
    required AtomicArchiveRecordStore records,
    required ArchiveEncryptionKeyProvider keys,
  }) : _records = records, _keys = keys;

  factory EncryptedCompletedHistoryStore.native() =>
      EncryptedCompletedHistoryStore(
        records: SqfliteAtomicArchiveRecordStore(
          databaseFile: 'bridge_academy_completed_history.sqlite',
        ),
        keys: NativeArchiveEncryptionKeyProvider(),
      );

  factory EncryptedCompletedHistoryStore.browser({
    SharedPreferencesAsync? preferences,
  }) => EncryptedCompletedHistoryStore(
        records: BrowserSingleRecordArchiveStore(
          preferences: preferences,
          storageKey: 'bridge_academy.encrypted_history.v1',
        ),
        keys: NativeArchiveEncryptionKeyProvider(),
      );

  static const maxItems = 12;
  static const _maxPlaintextBytes = 320 * 1024;
  static const _version = 1;
  static final _crypto = AesGcm.with256bits();
  static final _aad = utf8.encode('bridge-academy/completed-history/v1');

  final AtomicArchiveRecordStore _records;
  final ArchiveEncryptionKeyProvider _keys;

  static void _validate(StoredHistoryBoard item) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{8,64}$').hasMatch(item.id) ||
        item.savedAt.isAfter(DateTime.now().toUtc().add(const Duration(days: 1)))) {
      throw const FormatException('Invalid completed history metadata');
    }
    final saved = SavedBoardCodec.decode(item.archive);
    if (!saved.state.isFinished) {
      throw const FormatException('Unfinished deal in completed history');
    }
  }

  Future<SecretKey> _key() async {
    final bytes = await _keys.loadOrCreateKey();
    if (bytes.length != 32) throw const FormatException('Invalid history key');
    return SecretKey(bytes);
  }

  static const _maxDeletedIds = 64;
  static final _idPattern = RegExp(r'^[a-zA-Z0-9_-]{8,64}$');

  Future<({List<StoredHistoryBoard> items, List<String> deleted})>
      _load() async {
    final record = await _records.readRecord();
    if (record == null) return (items: <StoredHistoryBoard>[], deleted: <String>[]);
    if (record.length != 4 ||
        record['v'] != _version ||
        record['nonce'] is! String ||
        record['ciphertext'] is! String ||
        record['mac'] is! String) {
      throw const FormatException('Unsupported encrypted history');
    }
    final box = SecretBox(
      base64Decode(record['ciphertext'] as String),
      nonce: base64Decode(record['nonce'] as String),
      mac: Mac(base64Decode(record['mac'] as String)),
    );
    final plaintext = await _crypto.decrypt(
      box, secretKey: await _key(), aad: _aad,
    );
    if (plaintext.length > _maxPlaintextBytes) {
      throw const FormatException('History exceeds configured bound');
    }
    final data = jsonDecode(utf8.decode(plaintext));
    if (data is! Map<String, dynamic> ||
        (data.length != 2 && data.length != 3) ||
        data['v'] != _version ||
        data['items'] is! List ||
        (data.containsKey('deleted') && data['deleted'] is! List)) {
      throw const FormatException('Invalid history data');
    }
    final tombstones = data['deleted'] as List? ?? [];
    if (tombstones.length > _maxDeletedIds ||
        tombstones.any((id) => id is! String || !_idPattern.hasMatch(id))) {
      throw const FormatException('Invalid deletion markers');
    }
    final deleted = tombstones.cast<String>();
    if (deleted.toSet().length != deleted.length) {
      throw const FormatException('Duplicate deletion markers');
    }
    final list = data['items'] as List;
    if (list.length > maxItems) {
      throw const FormatException('History contains too many items');
    }
    final seen = <String>{};
    final results = <StoredHistoryBoard>[];
    for (final element in list) {
      if (element is! Map<String, dynamic> ||
          element.length != 3 ||
          element['id'] is! String ||
          element['savedAt'] is! String ||
          element['archive'] is! String) {
        throw const FormatException('Invalid history item');
      }
      final item = StoredHistoryBoard(
        id: element['id'] as String,
        savedAt: DateTime.parse(element['savedAt'] as String).toUtc(),
        archive: element['archive'] as String,
      );
      _validate(item);
      if (!seen.add(item.id) || deleted.contains(item.id)) {
        throw const FormatException('Duplicate or deleted history item');
      }
      results.add(item);
    }
    return (items: results, deleted: deleted);
  }

  Future<void> _save(List<StoredHistoryBoard> items,
      List<String> deleted) async {
    if (items.length > maxItems ||
        items.map((e) => e.id).toSet().length != items.length ||
        deleted.length > _maxDeletedIds ||
        deleted.toSet().length != deleted.length ||
        deleted.any((id) => !_idPattern.hasMatch(id)) ||
        items.any((item) => deleted.contains(item.id))) {
      throw const FormatException('Invalid history count or deletion marker');
    }
    for (final item in items) {
      _validate(item);
    }
    final encoded = utf8.encode(jsonEncode({
      'v': _version,
      'items': [
        for (final item in items)
          {
            'id': item.id,
            'savedAt': item.savedAt.toUtc().toIso8601String(),
            'archive': item.archive,
          },
      ],
      'deleted': deleted,
    }));
    if (encoded.length > _maxPlaintextBytes) {
      throw const FormatException('History storage full');
    }
    final encrypted = await _crypto.encrypt(
      encoded, secretKey: await _key(), aad: _aad,
    );
    await _records.replaceRecord({
      'v': _version,
      'nonce': base64Encode(encrypted.nonce),
      'ciphertext': base64Encode(encrypted.cipherText),
      'mac': base64Encode(encrypted.mac.bytes),
    });
  }

  @override
  Future<List<StoredHistoryBoard>> read() async =>
      List.unmodifiable((await _load()).items);

  @override
  Future<void> write(List<StoredHistoryBoard> items) async {
    final state = await _load();
    await _save(items, state.deleted);
  }

  @override
  Future<void> delete(String id) async {
    if (!_idPattern.hasMatch(id)) {
      throw const FormatException('Invalid history ID');
    }
    final state = await _load();
    if (state.deleted.contains(id)) return;
    // Bounded retention: oldest deletion markers can be discarded because
    // only the current checkpoint can rearchive one old ID after restart.
    final tombstones = [id, ...state.deleted].take(_maxDeletedIds).toList();
    await _save(
      state.items.where((item) => item.id != id).toList(), tombstones,
    );
  }

  @override
  Future<bool> isDeleted(String id) async =>
      (await _load()).deleted.contains(id);
}
