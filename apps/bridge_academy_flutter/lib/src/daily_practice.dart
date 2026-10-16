import 'dart:convert';

import 'package:bridge_core/bridge_core.dart';
import 'package:crypto/crypto.dart';

import 'four_board_practice.dart';

/// B6-1: deterministic local, non-competitive original deals. This is NOT
/// a fair-play server or a ranking/IMP match. Stable across Dart RNG versions.
final class DailyPracticeManifest {
  DailyPracticeManifest._(this.utcDay, this.revision, this.startBoard);

  static const revisionV1 = 1;
  static final _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  factory DailyPracticeManifest.forDate(DateTime date, {int revision = revisionV1}) {
    if (revision != revisionV1) {
      throw const FormatException('Unsupported daily manifest revision');
    }
    final day = DateTime.utc(date.toUtc().year, date.toUtc().month,
        date.toUtc().day);
    return DailyPracticeManifest._(
      _format(day), revision, (day.difference(DateTime.utc(1970)).inDays + 1) * 4 + 1,
    );
  }

  factory DailyPracticeManifest.fromUtcDay(String day,
      {int revision = revisionV1}) {
    if (!_datePattern.hasMatch(day)) {
      throw const FormatException('Invalid UTC daily date');
    }
    final date = DateTime.tryParse('${day}T00:00:00Z');
    if (date == null || _format(date.toUtc()) != day) {
      throw const FormatException('Invalid UTC daily date');
    }
    return DailyPracticeManifest.forDate(date, revision: revision);
  }

  static String _format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  final String utcDay;
  final int revision;
  final int startBoard;
  String get challengeId => 'daily_${utcDay}_v$revision';

  BoardDefinition boardAt(int index) =>
      BoardDefinition.forNumber(_number(index));

  int _number(int index) {
    if (index < 0 || index >= 4) {
      throw RangeError.range(index, 0, 3, 'daily board index');
    }
    return startBoard + index;
  }

  /// SHA-256 ordering over a canonical 52-card list. The domain separator,
  /// UTF-8 bytes and tie-break are part of v1's published algorithm.
  Deal dealAt(int index) {
    _number(index);
    final cards = [
      for (final suit in Suit.values)
        for (final rank in Rank.values) Card(suit, rank),
    ];
    List<int> digest(Card c) => sha256.convert(utf8.encode(
      'BA-DAILY-PBN-v1|$challengeId|$index|${c.code}',
    )).bytes;
    // Explicit byte-by-byte SHA order, then canonical card code.
    final deck = cards.map((card) => (card: card, hash: digest(card))).toList()
      ..sort((a, b) {
        for (var i = 0; i < 32; i++) {
          if (a.hash[i] != b.hash[i]) {
            return a.hash[i].compareTo(b.hash[i]);
          }
        }
        return a.card.code.compareTo(b.card.code);
      });
    return Deal({
      for (var i = 0; i < 4; i++)
        Seat.values[i]: deck.skip(i * 13).take(13).map((entry) => entry.card),
    });
  }
}

/// Only public metadata/results. Never serializes privileged 52-card deals.
final class DailyPracticeProgress {
  DailyPracticeProgress({
    required this.manifest,
    required this.practice,
  }) {
    if (practice.startBoard != manifest.startBoard) {
      throw const FormatException('Daily practice board mismatch');
    }
  }

  factory DailyPracticeProgress.newChallenge(DailyPracticeManifest manifest,
          Seat seat) =>
      DailyPracticeProgress(
        manifest: manifest,
        practice: FourBoardPractice(
          startBoard: manifest.startBoard, humanSeat: seat, results: const [],
        ),
      );

  final DailyPracticeManifest manifest;
  final FourBoardPractice practice;
  String get challengeId => manifest.challengeId;
  Seat get humanSeat => practice.humanSeat;
  int get completed => practice.completed;
  bool get isComplete => practice.isComplete;
  int get nextBoardNumber => practice.nextBoardNumber;
  int get humanNetScore => practice.humanNetScore;
  List<FourBoardResult> get results => practice.results;

  DailyPracticeProgress withResult(FourBoardResult result) =>
      DailyPracticeProgress(
        manifest: manifest, practice: practice.withResult(result),
      );

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'day': manifest.utcDay,
        'revision': manifest.revision,
        'challengeId': challengeId,
        'practice': practice.toJson(),
      };

  factory DailyPracticeProgress.fromJson(Object? source) {
    if (source is! Map<String, dynamic> || source.length != 5 ||
        source['schemaVersion'] != 1 || source['day'] is! String ||
        source['revision'] is! int || source['challengeId'] is! String) {
      throw const FormatException('Invalid daily progress');
    }
    final manifest = DailyPracticeManifest.fromUtcDay(
      source['day'] as String, revision: source['revision'] as int,
    );
    if (manifest.challengeId != source['challengeId']) {
      throw const FormatException('Daily challenge ID mismatch');
    }
    return DailyPracticeProgress(
      manifest: manifest,
      practice: FourBoardPractice.fromJson(source['practice']),
    );
  }
}
