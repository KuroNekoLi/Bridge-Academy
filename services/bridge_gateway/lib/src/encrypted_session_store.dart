import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// One encrypted, atomic checkpoint per anonymous session.
/// This is a single-process local-development store, NOT cluster-safe.
class EncryptedSessionStore {
  EncryptedSessionStore({
    required Directory directory,
    required List<int> key,
  })  : _directory = directory,
        _key = SecretKey(Uint8List.fromList(key)) {
    if (key.length != 32) {
      throw ArgumentError('A 256-bit checkpoint key is required');
    }
  }

  final Directory _directory;
  final SecretKey _key;
  final AesGcm _cipher = AesGcm.with256bits();
  final Random _rng = Random.secure();
  RandomAccessFile? _lock;

  Future<Map<String, Map<String, dynamic>>> open() async {
    if (_lock != null) throw StateError('Store already opened');
    await _directory.create(recursive: true);
    final lockFile = File('${_directory.path}/gateway.lock');
    final lock = await lockFile.open(mode: FileMode.append);
    try {
      // Nonblocking exclusive lock: a second gateway cannot use this dir.
      await lock.lock(FileLock.exclusive);
      _lock = lock;
      final loaded = <String, Map<String, dynamic>>{};
      await for (final entity in _directory.list(followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.session')) continue;
        final name = entity.uri.pathSegments.last;
        final id = name.substring(0, name.length - '.session'.length);
        if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(id)) {
          throw StateError('Invalid session checkpoint name');
        }
        final map = jsonDecode(await entity.readAsString());
        if (map is! Map<String, dynamic> || map['format'] != 1) {
          throw StateError('Unsupported session checkpoint format');
        }
        final secret = SecretBox(
          base64Url.decode(map['ciphertext'] as String),
          nonce: base64Url.decode(map['nonce'] as String),
          mac: Mac(base64Url.decode(map['mac'] as String)),
        );
        final plain = await _cipher.decrypt(secret, secretKey: _key);
        final decoded = jsonDecode(utf8.decode(plain));
        if (decoded is! Map<String, dynamic> || decoded['format'] != 1) {
          throw StateError('Invalid decrypted session checkpoint');
        }
        loaded[id] = decoded;
      }
      return loaded;
    } catch (_) {
      _lock = null;
      await lock.unlock();
      await lock.close();
      // No salvage/empty-state fallback after wrong key or corruption.
      rethrow;
    }
  }

  Future<void> save(String sessionDigest, Map<String, Object?> data) async {
    if (_lock == null || !RegExp(r'^[0-9a-f]{64}$').hasMatch(sessionDigest)) {
      throw StateError('Checkpoint store not ready');
    }
    final nonce = List<int>.generate(12, (_) => _rng.nextInt(256));
    final encrypted = await _cipher.encrypt(
      utf8.encode(jsonEncode({'format': 1, ...data})),
      secretKey: _key,
      nonce: nonce,
    );
    final sealed = jsonEncode({
      'format': 1,
      'nonce': base64Url.encode(encrypted.nonce),
      'ciphertext': base64Url.encode(encrypted.cipherText),
      'mac': base64Url.encode(encrypted.mac.bytes),
    });
    final destination = File('${_directory.path}/$sessionDigest.session');
    final temp = File(
        '${_directory.path}/.$sessionDigest.${DateTime.now().microsecondsSinceEpoch}.tmp');
    try {
      await temp.writeAsString(sealed, flush: true);
      await temp.rename(destination.path);
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }

  Future<void> remove(String sessionDigest) async {
    final file = File('${_directory.path}/$sessionDigest.session');
    if (await file.exists()) await file.delete();
  }

  Future<void> close() async {
    final handle = _lock;
    _lock = null;
    if (handle != null) {
      await handle.unlock();
      await handle.close();
    }
  }
}
