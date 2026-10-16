import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'session_persistence.dart';

/// A single committed SQLite row, replaced in one SQL transaction. The
/// implementation must never log/read out decrypted transcript material.
abstract interface class AtomicArchiveRecordStore {
  Future<Map<String, dynamic>?> readRecord();
  Future<void> replaceRecord(Map<String, dynamic> record);
  Future<void> clearRecord();
}

/// Random 256-bit key is generated once and kept only in platform secure
/// storage. Missing/revoked keys never cause an old ciphertext to be accepted.
abstract interface class ArchiveEncryptionKeyProvider {
  Future<List<int>> loadOrCreateKey();
}

final class NativeArchiveEncryptionKeyProvider
    implements ArchiveEncryptionKeyProvider {
  NativeArchiveEncryptionKeyProvider({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;
  static const _keyName = 'bridge_academy.archive.aes256.v1';

  @override
  Future<List<int>> loadOrCreateKey() async {
    final existing = await _secureStorage.read(key: _keyName);
    if (existing != null) {
      final bytes = base64Decode(existing);
      if (bytes.length != 32) {
        throw const FormatException('Invalid secured archive key');
      }
      return bytes;
    }
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    await _secureStorage.write(key: _keyName, value: base64Encode(bytes));
    return bytes;
  }
}

/// Android/iOS transactional local database. Exactly one row is replaced in a
/// SQLite transaction, so readers never see a half-updated active marker.
final class SqfliteAtomicArchiveRecordStore
    implements AtomicArchiveRecordStore {
  SqfliteAtomicArchiveRecordStore({
    Future<Database> Function()? openDatabase,
    String databaseFile = 'bridge_academy_secure_archive.sqlite',
  }) : _openOverride = openDatabase, _databaseFile = databaseFile;

  final Future<Database> Function()? _openOverride;
  final String _databaseFile;
  Future<Database>? _database;

  Future<Database> _open() => _database ??= _openOverride?.call() ??
      _openDefault(_databaseFile);

  static Future<Database> _openDefault(String file) async {
    final base = await getDatabasesPath();
    return openDatabase(
      '$base/$file',
      version: 1,
      onCreate: (db, _) async {
        await db.execute('CREATE TABLE local_checkpoint ('
            'id INTEGER PRIMARY KEY CHECK (id = 1), '
            'value TEXT NOT NULL)');
      },
    );
  }

  @override
  Future<Map<String, dynamic>?> readRecord() async {
    final db = await _open();
    final rows = await db.query('local_checkpoint',
        columns: ['value'], where: 'id = ?', whereArgs: [1], limit: 1);
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(
        jsonDecode(rows.single['value']! as String) as Map);
  }

  @override
  Future<void> replaceRecord(Map<String, dynamic> record) async {
    final db = await _open();
    await db.transaction((txn) async {
      await txn.insert('local_checkpoint',
          {'id': 1, 'value': jsonEncode(record)},
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<void> clearRecord() async {
    final db = await _open();
    await db.transaction((txn) async {
      await txn.delete('local_checkpoint', where: 'id = ?', whereArgs: [1]);
    });
  }
}

/// Browser-only *single-key* encrypted checkpoint record.
///
/// SharedPreferencesAsync uses origin-local LocalStorage on Web. Updating one
/// record avoids cross-key torn markers, but is NOT an ACID/fsync guarantee,
/// cross-tab compare-and-swap or protection against same-origin JavaScript.
/// This adapter must never be used as a substitute for native SQLite.
final class BrowserSingleRecordArchiveStore
    implements AtomicArchiveRecordStore {
  BrowserSingleRecordArchiveStore({
    SharedPreferencesAsync? preferences,
    String storageKey = key,
  }) : _preferences = preferences ?? SharedPreferencesAsync(),
       _storageKey = storageKey;

  static const key = 'bridge_academy.encrypted_web_checkpoint.v1';
  final SharedPreferencesAsync _preferences;
  final String _storageKey;

  @override
  Future<Map<String, dynamic>?> readRecord() async {
    final raw = await _preferences.getString(_storageKey);
    if (raw == null) return null;
    if (raw.length > 512 * 1024) {
      throw const FormatException('Oversized browser archive');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid browser archive');
    }
    return decoded;
  }

  @override
  Future<void> replaceRecord(Map<String, dynamic> record) =>
      _preferences.setString(_storageKey, jsonEncode(record));

  @override
  Future<void> clearRecord() => _preferences.remove(_storageKey);
}

/// Android/iOS encrypted checkpoint store. All four hands are encrypted with
/// random-nonce AES-256-GCM and never serialized in plaintext in SQLite.
///
/// Each atomic SQLite record holds current and previous authenticated boxes.
/// Recovery from a damaged latest box is an explicit, persistent player
/// consent event. Decryption and replay validation happen BEFORE any returned
/// archive is used by BridgeSession.
final class EncryptedTransactionalSessionArchiveStore
    implements SessionArchiveStore, RecoveryAwareSessionArchiveStore {
  EncryptedTransactionalSessionArchiveStore({
    required AtomicArchiveRecordStore records,
    required ArchiveEncryptionKeyProvider keys,
    SessionArchiveStore? legacy,
  }) : _records = records, _keys = keys, _legacy = legacy;

  factory EncryptedTransactionalSessionArchiveStore.native() =>
      EncryptedTransactionalSessionArchiveStore(
        records: SqfliteAtomicArchiveRecordStore(),
        keys: NativeArchiveEncryptionKeyProvider(),
        legacy: PreferencesSessionArchiveStore(),
      );

  /// WebCrypto-backed key (experimental flutter_secure_storage Web) and one
  /// encrypted origin-local record. NOT native SQL transaction semantics.
  ///
  /// Requires HTTPS or localhost. Missing WebCrypto/key fails closed without
  /// writing the privileged game as plaintext. A successful encryption does
  /// not defend against XSS, malicious extensions or other same-origin code.
  factory EncryptedTransactionalSessionArchiveStore.browser({
    SharedPreferencesAsync? preferences,
    ArchiveEncryptionKeyProvider? keys,
    SessionArchiveStore? legacy,
  }) {
    final prefs = preferences ?? SharedPreferencesAsync();
    return EncryptedTransactionalSessionArchiveStore(
      records: BrowserSingleRecordArchiveStore(preferences: prefs),
      keys: keys ?? NativeArchiveEncryptionKeyProvider(),
      legacy: legacy ?? PreferencesSessionArchiveStore(preferences: prefs),
    );
  }

  static const _version = 3;
  static final _algorithm = AesGcm.with256bits();
  static final _aad = utf8.encode('bridge-academy/session/v3');

  final AtomicArchiveRecordStore _records;
  final ArchiveEncryptionKeyProvider _keys;
  final SessionArchiveStore? _legacy;
  bool _recovered = false;

  @override
  bool get recoveredOlderCheckpoint => _recovered;

  Future<SecretKey> _secretKey() async {
    final bytes = await _keys.loadOrCreateKey();
    if (bytes.length != 32) {
      throw const FormatException('Invalid archive encryption key length');
    }
    return SecretKey(bytes);
  }

  static Map<String, dynamic> _checked(Map<String, dynamic> record) {
    if (record['version'] != _version ||
        record['generation'] is! int ||
        (record['generation'] as int) < 1 ||
        record['active'] is! Map ||
        record['recoveryPending'] is! bool ||
        (record['previous'] != null && record['previous'] is! Map) ||
        (record['previousGeneration'] != null &&
            record['previousGeneration'] is! int)) {
      throw const FormatException('Invalid encrypted checkpoint metadata');
    }
    return record;
  }

  Future<Map<String, dynamic>> _seal(String text, SecretKey key) async {
    final box = await _algorithm.encrypt(
      utf8.encode(text),
      secretKey: key,
      aad: _aad,
    );
    return {
      'nonce': base64Encode(box.nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
  }

  Future<String> _openBox(Map raw, SecretKey key) async {
    final json = Map<String, dynamic>.from(raw);
    final box = SecretBox(
      base64Decode(json['ciphertext'] as String),
      nonce: base64Decode(json['nonce'] as String),
      mac: Mac(base64Decode(json['mac'] as String)),
    );
    final plaintext = await _algorithm.decrypt(
      box, secretKey: key, aad: _aad,
    );
    final archive = utf8.decode(plaintext);
    // AES-GCM authentication alone does not prove a valid bridge transcript.
    SavedBoardCodec.decode(archive);
    return archive;
  }

  Future<String?> _tryOpen(Map? raw, SecretKey key) async {
    if (raw == null) return null;
    try {
      return await _openBox(raw, key);
    } catch (_) {
      // Do not expose cryptographic errors or private hands to UI/logs.
      return null;
    }
  }

  Future<void> _save(
    String archive, {
    required bool recoveryPending,
    bool useCurrentAsBackup = true,
  }) async {
    SavedBoardCodec.decode(archive);
    final existing = await _records.readRecord();
    if (existing != null) _checked(existing);
    final key = await _secretKey();
    final generation = (existing == null ? 0 : existing['generation'] as int) + 1;
    final active = await _seal(archive, key);
    await _records.replaceRecord({
      'version': _version,
      'generation': generation,
      'active': active,
      'previousGeneration': useCurrentAsBackup && existing != null
          ? existing['generation']
          : null,
      'previous': useCurrentAsBackup && existing != null
          ? existing['active']
          : null,
      'recoveryPending': recoveryPending,
    });
  }

  @override
  Future<void> write(String archive) => _save(
        archive, recoveryPending: false,
      );

  @override
  Future<String?> read() async {
    _recovered = false;
    final record = await _records.readRecord();
    if (record == null) {
      final legacy = _legacy;
      if (legacy == null) return null;
      final prior = await legacy.read();
      if (prior == null) return null;
      SavedBoardCodec.decode(prior);
      final lostEvents = legacy is RecoveryAwareSessionArchiveStore
          ? (legacy as RecoveryAwareSessionArchiveStore).recoveredOlderCheckpoint
          : false;
      // Preserve recovery consent in the SAME atomic encrypted commit.
      await _save(prior, recoveryPending: lostEvents);
      await legacy.clear();
      _recovered = lostEvents;
      return prior;
    }
    _checked(record);
    final key = await _secretKey();
    final current = await _tryOpen(record['active'] as Map, key);
    if (current != null) {
      _recovered = record['recoveryPending'] as bool;
      // Plaintext legacy data must never remain after a successful migration.
      await _legacy?.clear();
      return current;
    }

    final generation = record['generation'] as int;
    if (record['previousGeneration'] != generation - 1) {
      throw const FormatException('No valid committed backup');
    }
    final previous = await _tryOpen(record['previous'] as Map?, key);
    if (previous == null) {
      throw const FormatException('Both checkpoint generations invalid');
    }
    await _records.replaceRecord({
      'version': _version,
      'generation': generation - 1,
      'active': record['previous'],
      'previousGeneration': null,
      'previous': null,
      'recoveryPending': true,
    });
    _recovered = true;
    await _legacy?.clear();
    return previous;
  }

  @override
  Future<void> acknowledgeRecoveredCheckpoint() async {
    final record = await _records.readRecord();
    if (record == null) {
      throw const FormatException('No committed checkpoint');
    }
    _checked(record);
    if (record['recoveryPending'] != true) {
      _recovered = false;
      return;
    }
    final key = await _secretKey();
    if (await _tryOpen(record['active'] as Map, key) == null) {
      throw const FormatException('No valid checkpoint to acknowledge');
    }
    await _records.replaceRecord({
      ...record,
      'recoveryPending': false,
    });
    _recovered = false;
  }

  @override
  Future<void> clear() async {
    await _records.clearRecord();
    await _legacy?.clear();
    _recovered = false;
  }
}
