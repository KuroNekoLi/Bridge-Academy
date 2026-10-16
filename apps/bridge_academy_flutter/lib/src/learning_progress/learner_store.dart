import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../secure_session_persistence.dart';
import 'learner_progress.dart';

abstract interface class LearnerStore {
  Future<LearnerProgress?> read();
  Future<void> write(LearnerProgress progress);
  Future<void> clear();
}

final class MemoryLearnerStore implements LearnerStore {
  LearnerProgress? _value;
  @override
  Future<LearnerProgress?> read() async =>
      _value == null ? null : LearnerProgress.fromJson(_value!.toJson());
  @override
  Future<void> write(LearnerProgress progress) async =>
      _value = LearnerProgress.fromJson(progress.toJson());
  @override
  Future<void> clear() async => _value = null;
}

final class EncryptedLearnerStore implements LearnerStore {
  EncryptedLearnerStore({
    required AtomicArchiveRecordStore records,
    required ArchiveEncryptionKeyProvider keys,
  }) : _records = records, _keys = keys;
  factory EncryptedLearnerStore.native() => EncryptedLearnerStore(
    records: SqfliteAtomicArchiveRecordStore(
      databaseFile: 'bridge_academy_learner.sqlite'),
    keys: NativeArchiveEncryptionKeyProvider());
  factory EncryptedLearnerStore.browser({SharedPreferencesAsync? preferences}) =>
      EncryptedLearnerStore(
        records: BrowserSingleRecordArchiveStore(
          preferences: preferences,
          storageKey: 'bridge_academy.encrypted_learner.v1'),
        keys: NativeArchiveEncryptionKeyProvider());
  static final _cipher = AesGcm.with256bits();
  static final _aad = utf8.encode('bridge-academy/learner/v1');
  final AtomicArchiveRecordStore _records;
  final ArchiveEncryptionKeyProvider _keys;
  Future<SecretKey> _key() async {
    final bytes = await _keys.loadOrCreateKey();
    if (bytes.length != 32) throw const FormatException('Invalid AES key');
    return SecretKey(bytes);
  }
  @override
  Future<LearnerProgress?> read() async {
    final raw = await _records.readRecord();
    if (raw == null) return null; // no record: default opt-out
    if (raw.length != 4 || raw['v'] != 1 ||
        raw['nonce'] is! String || raw['mac'] is! String ||
        raw['ciphertext'] is! String) {
      throw const FormatException('Unknown encrypted learner format');
    }
    final box = SecretBox(base64Decode(raw['ciphertext'] as String),
      nonce: base64Decode(raw['nonce'] as String),
      mac: Mac(base64Decode(raw['mac'] as String)));
    final bytes = await _cipher.decrypt(box,
      secretKey: await _key(), aad: _aad);
    if (bytes.length > 96 * 1024) throw const FormatException('Oversized learner record');
    return LearnerProgress.fromJson(jsonDecode(utf8.decode(bytes)));
  }
  @override
  Future<void> write(LearnerProgress progress) async {
    final bytes = utf8.encode(jsonEncode(progress.toJson()));
    if (bytes.length > 96 * 1024) throw const FormatException('Oversized learner record');
    final box = await _cipher.encrypt(bytes,
      secretKey: await _key(), aad: _aad);
    await _records.replaceRecord({
      'v': 1, 'nonce': base64Encode(box.nonce),
      'mac': base64Encode(box.mac.bytes),
      'ciphertext': base64Encode(box.cipherText),
    });
  }
  @override
  Future<void> clear() => _records.clearRecord();
}
