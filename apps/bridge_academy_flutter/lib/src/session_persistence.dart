import 'dart:convert';

import 'package:bridge_core/bridge_core.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Trusted game snapshots contain ALL FOUR PRIVATE HANDS. Never expose them
/// to widgets, player API objects, analytics, logs, or an AI transport.
abstract interface class SessionArchiveStore {
  Future<String?> read();
  Future<void> write(String archive);
  Future<void> clear();
}

/// A small key-value boundary, injectable to simulate interrupted writes.
/// Individual keys can be updated, but multiple keys are NOT an atomic disk
/// transaction. This design tolerates common torn-write scenarios, not power
/// loss/fsync failure, hostile local modification, or concurrent writers.
abstract interface class CheckpointKeyValueStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

final class _PreferencesKeyValueStore implements CheckpointKeyValueStore {
  _PreferencesKeyValueStore(this._preferences);
  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> remove(String key) => _preferences.remove(key);
}

/// Two-slot, best-effort versioned snapshots.
///
/// Writes update the INACTIVE slot, check it, then update an active marker.
/// The previously committed slot remains intact. On a torn/corrupt active
/// snapshot the previous committed snapshot can be recovered.
///
/// SHA-256 is for ACCIDENTAL corruption detection, NOT authentication or
/// encryption. SharedPreferences remains plaintext and is NOT a database.
final class PreferencesSessionArchiveStore implements SessionArchiveStore {
  PreferencesSessionArchiveStore({
    SharedPreferencesAsync? preferences,
    CheckpointKeyValueStore? keyValueStore,
  }) : _store = keyValueStore ??
            _PreferencesKeyValueStore(preferences ?? SharedPreferencesAsync());

  /// Former v1 single-key storage; migrated after successful validation.
  static const key = 'bridge_academy.local_game.v1';
  static const activeKey = 'bridge_academy.local_game.v2.active';
  static const slotAKey = 'bridge_academy.local_game.v2.slot.a';
  static const slotBKey = 'bridge_academy.local_game.v2.slot.b';
  static const _storeVersion = 2;

  final CheckpointKeyValueStore _store;

  static String _slotKey(String slot) =>
      slot == 'a' ? slotAKey : slotBKey;

  static String _other(String slot) => slot == 'a' ? 'b' : 'a';

  static String _encodeEnvelope(String archive) => jsonEncode({
        'storeVersion': _storeVersion,
        'sha256': sha256.convert(utf8.encode(archive)).toString(),
        'archive': archive,
      });

  static String _decodeEnvelope(String? raw) {
    if (raw == null || raw.length > 512 * 1024) {
      throw const FormatException('Missing or oversized checkpoint slot');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> ||
        decoded['storeVersion'] != _storeVersion ||
        decoded['archive'] is! String ||
        decoded['sha256'] is! String) {
      throw const FormatException('Unsupported or invalid checkpoint slot');
    }
    final archive = decoded['archive'] as String;
    final expected = sha256.convert(utf8.encode(archive)).toString();
    if (decoded['sha256'] != expected) {
      throw const FormatException('Checkpoint slot checksum mismatch');
    }
    // A checksum alone is insufficient: replay all real events through the
    // authoritative Bridge Core and reject invalid board/version/calls.
    SavedBoardCodec.decode(archive);
    return archive;
  }

  Future<String?> _readSlot(String slot) async {
    try {
      return _decodeEnvelope(await _store.getString(_slotKey(slot)));
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on RangeError {
      return null;
    } on RuleViolation {
      return null;
    }
  }

  @override
  Future<String?> read() async {
    final active = await _store.getString(activeKey);
    if (active != null) {
      if (active != 'a' && active != 'b') {
        throw const FormatException('Unknown active checkpoint slot');
      }
      final committed = await _readSlot(active);
      if (committed != null) return committed;
      final previous = await _readSlot(_other(active));
      if (previous == null) {
        throw const FormatException('No recoverable committed checkpoint');
      }
      // Repair the marker only after the previous slot has been validated.
      await _store.setString(activeKey, _other(active));
      return previous;
    }

    // No active marker = no committed v2 record. Ignore orphan slots from an
    // interrupted first write. The v1 record is still authoritative.
    final legacy = await _store.getString(key);
    if (legacy == null) return null;
    SavedBoardCodec.decode(legacy);
    await write(legacy);
    await _store.remove(key);
    return legacy;
  }

  @override
  Future<void> write(String archive) async {
    SavedBoardCodec.decode(archive);
    final active = await _store.getString(activeKey);
    if (active != null && active != 'a' && active != 'b') {
      throw const FormatException('Unknown active checkpoint slot');
    }
    final target = active == 'a' ? 'b' : 'a';
    await _store.setString(_slotKey(target), _encodeEnvelope(archive));
    final checked = await _readSlot(target);
    if (checked != archive) {
      throw StateError('Pending checkpoint validation failed');
    }
    await _store.setString(activeKey, target);
  }

  @override
  Future<void> clear() async {
    // Remove the legacy record first, then the only commit marker, so
    // unreferenced slots can never be mistaken for a committed checkpoint.
    await _store.remove(key);
    await _store.remove(activeKey);
    await _store.remove(slotAKey);
    await _store.remove(slotBKey);
  }
}

/// Privileged local checkpoint data. Never use as a Flutter view model:
/// its reconstructed GameState holds the four hidden hands.
final class SavedBoard {
  const SavedBoard({
    required this.board,
    required this.humanSeat,
    required this.opponentMode,
    required this.boardMode,
    required this.state,
    required this.transcript,
  });

  final BoardDefinition board;
  final Seat humanSeat;
  final String opponentMode;
  final String boardMode;
  final GameState state;
  final Map<String, dynamic> transcript;
}

abstract final class SavedBoardCodec {
  static const schemaVersion = 1;

  static String encode({
    required BoardDefinition board,
    required Seat humanSeat,
    required String opponentMode,
    required String boardMode,
    required SinglePlayerCoordinator coordinator,
  }) => jsonEncode({
        'schemaVersion': schemaVersion,
        'boardNumber': board.number,
        'humanSeat': humanSeat.letter,
        'opponentMode': opponentMode,
        'boardMode': boardMode,
        'eventVersion': coordinator.version,
        // Regression detection, NOT cryptographic integrity or encryption.
        'historyFingerprint': coordinator.historyFingerprint,
        'transcript': coordinator.snapshotForTrustedStorage(),
      });

  static SavedBoard decode(String raw) {
    // Avoid decoding unlimited user-controlled local data.
    if (raw.length > 256 * 1024) {
      throw const FormatException('Checkpoint exceeds size limit');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid session checkpoint');
    }
    if (decoded['schemaVersion'] != schemaVersion) {
      throw const FormatException('Unsupported session checkpoint version');
    }
    final number = decoded['boardNumber'];
    if (number is! int) throw const FormatException('Invalid board number');
    final board = BoardDefinition.forNumber(number);
    final seat = Seat.fromLetter(decoded['humanSeat'] as String);
    final opponentMode = decoded['opponentMode'];
    final boardMode = decoded['boardMode'];
    if (opponentMode != 'demo' && opponentMode != 'ben') {
      throw const FormatException('Unknown opponent mode');
    }
    if (boardMode != 'training' && boardMode != 'fresh') {
      throw const FormatException('Unknown board source');
    }
    final transcript = Map<String, dynamic>.from(decoded['transcript'] as Map);
    // Replay all actions under the same Bridge Core authority as live play.
    final state = GameTranscript.decode(transcript);
    if (state.dealer != board.dealer ||
        state.vulnerability != board.vulnerability ||
        decoded['eventVersion'] != state.version ||
        decoded['historyFingerprint'] != state.historyFingerprint) {
      throw const FormatException('Checkpoint does not match legal board');
    }
    return SavedBoard(
      board: board, humanSeat: seat, opponentMode: opponentMode as String,
      boardMode: boardMode as String, state: state, transcript: transcript,
    );
  }
}
