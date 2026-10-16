import 'package:bridge_core/bridge_core.dart';

/// A private, local practice set. These are scores, NOT IMP or matchpoints.
/// No 52-card Deal, PBN or privileged event log is serialized here.
final class FourBoardResult {
  const FourBoardResult({
    required this.id,
    required this.boardNumber,
    required this.contract,
    required this.nsScore,
  });

  final String id;
  final int boardNumber;
  final String contract;
  final int nsScore;

  Map<String, Object?> toJson() => {
        'id': id, 'board': boardNumber,
        'contract': contract, 'nsScore': nsScore,
      };

  factory FourBoardResult.fromJson(Object? raw) {
    if (raw is! Map<String, dynamic> ||
        raw.length != 4 ||
        raw['id'] is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{8,64}$').hasMatch(raw['id'] as String) ||
        raw['board'] is! int ||
        raw['contract'] is! String ||
        raw['nsScore'] is! int ||
        (raw['contract'] as String).length > 24) {
      throw const FormatException('Invalid four-board result');
    }
    BoardDefinition.forNumber(raw['board'] as int);
    return FourBoardResult(
      id: raw['id'] as String,
      boardNumber: raw['board'] as int,
      contract: raw['contract'] as String,
      nsScore: raw['nsScore'] as int,
    );
  }
}

/// Exactly four sequential duplicate board numbers, one attempt per board.
/// No competitive comparison is implied by the signed score sum.
final class FourBoardPractice {
  FourBoardPractice({
    required this.startBoard,
    required this.humanSeat,
    required Iterable<FourBoardResult> results,
  }) : results = List.unmodifiable(results) {
    BoardDefinition.forNumber(startBoard);
    if (this.results.length > 4 ||
        this.results.indexed.any((item) =>
            item.$2.boardNumber != startBoard + item.$1) ||
        this.results.map((item) => item.id).toSet().length !=
            this.results.length) {
      throw const FormatException('Invalid four-board sequence');
    }
  }

  final int startBoard;
  final Seat humanSeat;
  final List<FourBoardResult> results;

  int get completed => results.length;
  bool get isComplete => completed == 4;
  int get nextBoardNumber => startBoard + completed;
  int get humanNetScore => results.fold(0, (sum, result) =>
      sum + (humanSeat.isNS ? result.nsScore : -result.nsScore));

  FourBoardPractice withResult(FourBoardResult result) {
    if (isComplete || result.boardNumber != nextBoardNumber ||
        results.any((item) => item.id == result.id)) {
      throw const FormatException('Duplicate or out-of-order practice board');
    }
    return FourBoardPractice(
      startBoard: startBoard,
      humanSeat: humanSeat,
      results: [...results, result],
    );
  }

  Map<String, Object?> toJson() => {
        'v': 1,
        'startBoard': startBoard,
        'humanSeat': humanSeat.letter,
        'results': results.map((item) => item.toJson()).toList(),
      };

  factory FourBoardPractice.fromJson(Object? raw) {
    if (raw is! Map<String, dynamic> ||
        raw.length != 4 ||
        raw['v'] != 1 ||
        raw['startBoard'] is! int ||
        raw['humanSeat'] is! String ||
        raw['results'] is! List) {
      throw const FormatException('Invalid four-board practice');
    }
    try {
      return FourBoardPractice(
        startBoard: raw['startBoard'] as int,
        humanSeat: Seat.fromLetter(raw['humanSeat'] as String),
        results: (raw['results'] as List)
            .map(FourBoardResult.fromJson),
      );
    } on ArgumentError {
      throw const FormatException('Invalid practice seat');
    }
  }
}
