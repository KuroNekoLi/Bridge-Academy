import 'dart:convert';

import 'package:bridge_core/bridge_core.dart';

import 'session_persistence.dart';

/// Strict first-party PBN import for COMPLETED local history only.
/// Not an arbitrary tournament PBN interpreter and never a live BEN input.
/// All four hands remain inside an encrypted CompletedHistoryStore; callers
/// only receive an opaque privileged archive, not an unrestricted PlayerView.
abstract final class CompletedPbnImport {
  static const maxChars = 65536;
  static const _tags = {
    'Event', 'Site', 'Board', 'Dealer', 'Vulnerable', 'Deal', 'Scoring',
    'Declarer', 'Contract', 'Result', 'Score', 'Auction', 'Play',
  };

  static String toLocalArchive(
    String source, {
    required String historyId,
  }) {
    if (source.length > maxChars || source.trim().isEmpty ||
        !RegExp(r'^[a-zA-Z0-9_-]{8,64}$').hasMatch(historyId)) {
      throw const FormatException('Invalid PBN input');
    }

    final tags = <String, String>{};
    final bids = <String>[];
    final plays = <String>[];
    String? section;
    for (final original in source.replaceAll('\r\n', '\n').split('\n')) {
      final line = original.trim();
      if (line.isEmpty) continue;
      final match = RegExp(r'^\[([A-Za-z]+) "([^"]*)"\]$').firstMatch(line);
      if (match != null) {
        final name = match.group(1)!;
        if (!_tags.contains(name) || tags.containsKey(name)) {
          throw const FormatException('Duplicate or unknown PBN tag');
        }
        tags[name] = match.group(2)!;
        section = name == 'Auction' || name == 'Play' ? name : null;
        continue;
      }
      // Comments, notes, incomplete hands, multi-deal PBN, NAG symbols and
      // unrecognised extensions are intentionally unsupported in this slice.
      if (line.startsWith('[') || line.startsWith('{') ||
          line.startsWith('%') || line.startsWith(';') ||
          (section != 'Auction' && section != 'Play')) {
        throw const FormatException('Unsupported PBN syntax');
      }
      if (section == 'Auction') {
        bids.addAll(line.split(RegExp(r'\s+')));
      } else {
        plays.add(line);
      }
    }

    const required = {
      'Board', 'Dealer', 'Vulnerable', 'Deal', 'Contract',
      'Score', 'Auction',
    };
    if (!tags.keys.toSet().containsAll(required)) {
      throw const FormatException('Missing required PBN tags');
    }
    final boardNumber = int.tryParse(tags['Board']!);
    if (boardNumber == null || boardNumber < 1 || boardNumber > 99999) {
      throw const FormatException('Invalid board');
    }
    final board = BoardDefinition.forNumber(boardNumber);
    final dealer = Seat.fromLetter(tags['Dealer']!);
    if (board.dealer != dealer || tags['Auction'] != dealer.letter) {
      throw const FormatException('Board/dealer/auction mismatch');
    }
    final vul = switch (tags['Vulnerable']) {
      'None' => Vulnerability.none,
      'NS' => Vulnerability.ns,
      'EW' => Vulnerability.ew,
      'All' => Vulnerability.both,
      _ => throw const FormatException('Invalid vulnerability'),
    };
    if (board.vulnerability != vul) {
      throw const FormatException('Board/vulnerability mismatch');
    }

    final deal = Deal.fromPbn(tags['Deal']!);
    var state = GameState.start(deal, dealer, vul);
    if (bids.length < 4 || bids.length > 320) {
      throw const FormatException('Missing or excessive auction calls');
    }
    for (final bid in bids) {
      if (state.phase != Phase.auction || state.turn == null) {
        throw const FormatException('Extra calls after completed auction');
      }
      state = BridgeGame.apply(state,
          CallAction(state.turn!, _parseCall(bid)));
    }

    if (state.contract == null) {
      if (!state.isFinished ||
          tags['Contract'] != 'Pass' || tags.containsKey('Play') ||
          tags.containsKey('Result') || tags.containsKey('Declarer') ||
          plays.isNotEmpty) {
        throw const FormatException('Invalid Pass Out');
      }
    } else {
      final contract = state.contract!;
      if (tags['Contract'] != contract.label ||
          tags['Declarer'] != contract.declarer.letter ||
          tags['Play'] != contract.openingLeader.letter ||
          plays.length != 13 || tags['Result'] == null) {
        throw const FormatException('Contract or play metadata mismatch');
      }
      final columns = <Seat>[
        contract.openingLeader,
        contract.openingLeader.next,
        contract.openingLeader.next.next,
        contract.openingLeader.next.next.next,
      ];
      for (final row in plays) {
        final cards = row.split(RegExp(r'\s+'));
        if (cards.length != 4) {
          throw const FormatException('Each PBN trick needs four cards');
        }
        final bySeat = <Seat, Card>{
          for (var i = 0; i < 4; i++) columns[i]: _parseCard(cards[i]),
        };
        for (var i = 0; i < 4; i++) {
          if (state.phase != Phase.play || state.turn == null ||
              state.actorToPlay == null) {
            throw const FormatException('Unexpected end of PBN play');
          }
          final handOwner = state.turn!;
          state = BridgeGame.apply(state, CardAction(
            state.actorToPlay!, handOwner, bySeat[handOwner]!,
          ));
        }
      }
      final result = int.tryParse(tags['Result']!);
      if (result == null || result < 0 || result > 13 ||
          result != state.tricks.where((trick) =>
            trick.winner.isNS == contract.declarer.isNS).length) {
        throw const FormatException('PBN result differs from Bridge Core');
      }
    }

    if (!state.isFinished || state.nsScore == null) {
      throw const FormatException('PBN game not finished');
    }
    final scoreMatch = RegExp(r'^NS ([+-]?\d+)$')
        .firstMatch(tags['Score']!);
    if (scoreMatch == null ||
        int.tryParse(scoreMatch.group(1)!) != state.nsScore) {
      throw const FormatException('PBN score differs from Bridge Core');
    }
    // Derived from valid Core events. Importing a completed board does NOT
    // resume live play, trust claims from PBN, or call BEN.
    final archive = jsonEncode({
      'schemaVersion': SavedBoardCodec.schemaVersion,
      'boardNumber': board.number,
      'humanSeat': Seat.north.letter,
      'opponentMode': 'demo',
      'boardMode': 'training',
      'eventVersion': state.version,
      'historyId': historyId,
      'historyFingerprint': state.historyFingerprint,
      'transcript': GameTranscript.encode(state),
    });
    SavedBoardCodec.decode(archive); // Full second-pass trust validation.
    return archive;
  }

  static Call _parseCall(String raw) {
    final value = raw.toUpperCase();
    if (value == 'PASS' || value == 'P') return const Pass();
    if (value == 'X') return const DoubleCall();
    if (value == 'XX') return const RedoubleCall();
    final match = RegExp(r'^([1-7])(NT|[CDHS])$').firstMatch(value);
    if (match == null) {
      throw const FormatException('Unsupported auction call');
    }
    final strain = Strain.values.firstWhere(
      (s) => s.code == match.group(2),
    );
    return Bid(int.parse(match.group(1)!), strain);
  }

  static Card _parseCard(String raw) {
    final match = RegExp(r'^([CDHS])([2-9TJQKA])$')
        .firstMatch(raw.toUpperCase());
    if (match == null) throw const FormatException('Invalid PBN card');
    final suit = Suit.values.firstWhere((s) => s.pbn == match.group(1));
    return Card(suit, Rank.fromSymbol(match.group(2)!));
  }
}
