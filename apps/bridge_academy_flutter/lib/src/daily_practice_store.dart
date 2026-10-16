import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'daily_practice.dart';
import 'secure_session_persistence.dart';

/// A bounded separate ledger: public daily metadata and raw duplicate scores,
/// never other players' hidden cards. Active deal remains in the checkpoint.
abstract interface class DailyPracticeStore {
  Future<List<DailyPracticeProgress>> read();
  Future<void> write(List<DailyPracticeProgress> entries);
}

final class MemoryDailyPracticeStore implements DailyPracticeStore {
  List<DailyPracticeProgress> _entries = [];
  @override
  Future<List<DailyPracticeProgress>> read() async => List.unmodifiable(_entries);
  @override
  Future<void> write(List<DailyPracticeProgress> entries) async {
    _entries = List.unmodifiable(entries);
  }
}

/// AES-GCM with purpose-specific AAD and a separate, atomic single-record
/// namespace. Native SQLite is transactional; web origin storage is best effort.
final class EncryptedDailyPracticeStore implements DailyPracticeStore {
  EncryptedDailyPracticeStore({
    required AtomicArchiveRecordStore records,
    required ArchiveEncryptionKeyProvider keys,
  }) : _records = records, _keys = keys;

  factory EncryptedDailyPracticeStore.native() =>
      EncryptedDailyPracticeStore(
        records: SqfliteAtomicArchiveRecordStore(
          databaseFile: 'bridge_academy_daily_practice.sqlite',
        ),
        keys: NativeArchiveEncryptionKeyProvider(),
      );

  factory EncryptedDailyPracticeStore.browser({
    SharedPreferencesAsync? preferences,
  }) => EncryptedDailyPracticeStore(
        records: BrowserSingleRecordArchiveStore(
          preferences: preferences,
          storageKey: 'bridge_academy.encrypted_daily_practice.v1',
        ),
        keys: NativeArchiveEncryptionKeyProvider(),
      );

  static const maxDays = 45;
  static const _maxPlaintextBytes = 32 * 1024;
  static final _cipher = AesGcm.with256bits();
  static final _aad = utf8.encode('bridge-academy/daily-practice/v1');

  final AtomicArchiveRecordStore _records;
  final ArchiveEncryptionKeyProvider _keys;

  Future<SecretKey> _key() async {
    final bytes = await _keys.loadOrCreateKey();
    if (bytes.length != 32) {
      throw const FormatException('Invalid daily encryption key');
    }
    return SecretKey(bytes);
  }

  static void _validate(List<DailyPracticeProgress> entries) {
    if (entries.length > maxDays ||
        entries.map((p) => p.challengeId).toSet().length != entries.length) {
      throw const FormatException('Invalid daily practice ledger');
    }
  }

  @override
  Future<List<DailyPracticeProgress>> read() async {
    final record = await _records.readRecord();
    if (record == null) return [];
    if (record.length != 4 ||
        record['v'] != 1 ||
        record['nonce'] is! String ||
        record['ciphertext'] is! String ||
        record['mac'] is! String) {
      throw const FormatException('Unknown daily ledger format');
    }
    final box = SecretBox(
      base64Decode(record['ciphertext'] as String),
      nonce: base64Decode(record['nonce'] as String),
      mac: Mac(base64Decode(record['mac'] as String)),
    );
    final plaintext = await _cipher.decrypt(
      box, secretKey: await _key(), aad: _aad,
    );
    if (plaintext.length > _maxPlaintextBytes) {
      throw const FormatException('Daily ledger is too large');
    }
    final decoded = jsonDecode(utf8.decode(plaintext));
    if (decoded is! Map<String, dynamic> || decoded.length != 2 ||
        decoded['v'] != 1 || decoded['entries'] is! List) {
      throw const FormatException('Invalid daily ledger');
    }
    final entries = (decoded['entries'] as List)
        .map(DailyPracticeProgress.fromJson).toList();
    _validate(entries);
    return List.unmodifiable(entries);
  }

  @override
  Future<void> write(List<DailyPracticeProgress> entries) async {
    _validate(entries);
    final encoded = utf8.encode(jsonEncode({
      'v': 1,
      'entries': entries.map((p) => p.toJson()).toList(),
    }));
    if (encoded.length > _maxPlaintextBytes) {
      throw const FormatException('Daily ledger is too large');
    }
    final box = await _cipher.encrypt(
      encoded, secretKey: await _key(), aad: _aad,
    );
    await _records.replaceRecord({
      'v': 1,
      'nonce': base64Encode(box.nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
  }
}
