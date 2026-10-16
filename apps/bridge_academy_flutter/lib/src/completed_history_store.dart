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
}

/// Test-only, process-local storage. Not suitable for player history.
final class MemoryCompletedHistoryStore implements CompletedHistoryStore {
  List<StoredHistoryBoard> _records = [];

  @override
  Future<List<StoredHistoryBoard>> read() async => List.of(_records);

  @override
  Future<void> write(List<StoredHistoryBoard> items) async {
    _records = List.of(items);
  }
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

  @override
  Future<List<StoredHistoryBoard>> read() async {
    final record = await _records.readRecord();
    if (record == null) return const [];
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
        data.length != 2 || data['v'] != _version ||
        data['items'] is! List) {
      throw const FormatException('Invalid history data');
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
      if (!seen.add(item.id)) {
        throw const FormatException('Duplicate history ID');
      }
      results.add(item);
    }
    return List.unmodifiable(results);
  }

  @override
  Future<void> write(List<StoredHistoryBoard> items) async {
    if (items.length > maxItems || items.map((e) => e.id).toSet().length != items.length) {
      throw const FormatException('Invalid history count or duplicate ID');
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
}
