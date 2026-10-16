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

/// Reports when the last read had to recover a prior committed version.
/// No hidden cards or transcript data are exposed through this interface.
abstract interface class RecoveryAwareSessionArchiveStore {
  bool get recoveredOlderCheckpoint;

  /// Persist acknowledgment before allowing actions to resume. An unsuccessful
  /// write must leave the player warning in force across app restarts.
  Future<void> acknowledgeRecoveredCheckpoint();
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
final class PreferencesSessionArchiveStore
    implements SessionArchiveStore, RecoveryAwareSessionArchiveStore {
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
  bool _recoveredOlderCheckpoint = false;

  @override
  bool get recoveredOlderCheckpoint => _recoveredOlderCheckpoint;

  static String _slotKey(String slot) =>
      slot == 'a' ? slotAKey : slotBKey;

  static String _other(String slot) => slot == 'a' ? 'b' : 'a';

  static ({String slot, int generation, bool recoveryPending})?
      _parseMarker(String? raw) {
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> ||
        (decoded['slot'] != 'a' && decoded['slot'] != 'b') ||
        decoded['generation'] is! int ||
        (decoded['generation'] as int) < 1 ||
        (decoded['recoveryPending'] != null &&
            decoded['recoveryPending'] is! bool)) {
      throw const FormatException('Invalid checkpoint commit marker');
    }
    return (
      slot: decoded['slot'] as String,
      generation: decoded['generation'] as int,
      recoveryPending: decoded['recoveryPending'] == true,
    );
  }

  static String _encodeEnvelope(String archive, int generation) => jsonEncode({
        'storeVersion': _storeVersion,
        'generation': generation,
        'sha256': sha256.convert(utf8.encode(archive)).toString(),
        'archive': archive,
      });

  static ({String archive, int generation}) _decodeEnvelope(String? raw) {
    if (raw == null || raw.length > 512 * 1024) {
      throw const FormatException('Missing or oversized checkpoint slot');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> ||
        decoded['storeVersion'] != _storeVersion ||
        decoded['archive'] is! String ||
        decoded['generation'] is! int ||
        (decoded['generation'] as int) < 1 ||
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
    return (archive: archive, generation: decoded['generation'] as int);
  }

  Future<({String archive, int generation})?> _readSlot(String slot) async {
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
    _recoveredOlderCheckpoint = false;
    final active = _parseMarker(await _store.getString(activeKey));
    if (active != null) {
      final committed = await _readSlot(active.slot);
      if (committed != null && committed.generation == active.generation) {
        // The warning is durable, not a one-time read event. A killed app
        // must show it again until the player explicitly acknowledges it.
        _recoveredOlderCheckpoint = active.recoveryPending;
        return committed.archive;
      }
      final previous = await _readSlot(_other(active.slot));
      // A pending write in the other slot has a GREATER generation and is
      // uncommitted, even when the current active slot is unreadable.
      if (previous == null ||
          previous.generation != active.generation - 1) {
        throw const FormatException('No recoverable committed checkpoint');
      }
      await _store.setString(activeKey, jsonEncode({
        'slot': _other(active.slot),
        'generation': previous.generation,
        'recoveryPending': true,
      }));
      // A valid backup may have fewer player actions than the lost save.
      _recoveredOlderCheckpoint = true;
      return previous.archive;
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
  Future<void> acknowledgeRecoveredCheckpoint() async {
    final active = _parseMarker(await _store.getString(activeKey));
    if (active == null || !active.recoveryPending) {
      _recoveredOlderCheckpoint = false;
      return;
    }
    // Do not clear an acknowledgement on an invalid or torn slot.
    final valid = await _readSlot(active.slot);
    if (valid == null || valid.generation != active.generation) {
      throw const FormatException('No valid checkpoint to acknowledge');
    }
    await _store.setString(activeKey, jsonEncode({
      'slot': active.slot,
      'generation': active.generation,
      'recoveryPending': false,
    }));
    _recoveredOlderCheckpoint = false;
  }

  @override
  Future<void> write(String archive) async {
    SavedBoardCodec.decode(archive);
    final active = _parseMarker(await _store.getString(activeKey));
    final generation = (active?.generation ?? 0) + 1;
    final target = active?.slot == 'a' ? 'b' : 'a';
    await _store.setString(
        _slotKey(target), _encodeEnvelope(archive, generation));
    final checked = await _readSlot(target);
    if (checked == null ||
        checked.archive != archive ||
        checked.generation != generation) {
      throw StateError('Pending checkpoint validation failed');
    }
    await _store.setString(activeKey, jsonEncode({
      'slot': target,
      'generation': generation,
    }));
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
    this.historyId,
  });

  final BoardDefinition board;
  final Seat humanSeat;
  final String opponentMode;
  final String boardMode;
  final GameState state;
  final Map<String, dynamic> transcript;
  final String? historyId;
}

abstract final class SavedBoardCodec {
  static const schemaVersion = 1;

  static String encode({
    required BoardDefinition board,
    required Seat humanSeat,
    required String opponentMode,
    required String boardMode,
    required SinglePlayerCoordinator coordinator,
    String? historyId,
  }) => jsonEncode({
        'schemaVersion': schemaVersion,
        'historyId': ?historyId,
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
    final id = decoded['historyId'];
    if (id != null && (id is! String ||
        !RegExp(r'^[a-zA-Z0-9_-]{8,64}$').hasMatch(id))) {
      throw const FormatException('Invalid game history ID');
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
      historyId: id as String?,
    );
  }
}
