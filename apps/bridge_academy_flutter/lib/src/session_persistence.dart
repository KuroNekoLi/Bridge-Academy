import 'dart:convert';

import 'package:bridge_core/bridge_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Only a trusted local application service may handle the raw archive.
/// The serialized string contains ALL FOUR PRIVATE HANDS. Do not expose it
/// to widgets, AI transports, analytics or logs.
abstract interface class SessionArchiveStore {
  Future<String?> read();
  Future<void> write(String archive);
  Future<void> clear();
}

/// Cross-platform best-effort checkpoint store. SharedPreferences is NOT
/// encrypted or guaranteed to fsync on return; not a production critical-data
/// storage or multi-user anti-cheat implementation.
final class PreferencesSessionArchiveStore implements SessionArchiveStore {
  PreferencesSessionArchiveStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const key = 'bridge_academy.local_game.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(key);

  @override
  Future<void> write(String archive) => _preferences.setString(key, archive);

  @override
  Future<void> clear() => _preferences.remove(key);
}

/// Privileged local checkpoint data. Never use this type as a Flutter
/// view model: its reconstructed GameState contains every hidden hand.
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
