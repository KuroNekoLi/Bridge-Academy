import 'package:bridge_core/bridge_core.dart';

import 'session_persistence.dart';

/// Explicit postgame export. PBN contains ALL FOUR HANDS, unlike PlayerView.
/// Never call from unfinished games, telemetry, Bot transport or UI build().
abstract final class CompletedPbnExport {
  static String encode(SavedBoard saved) {
    final state = saved.state;
    if (!state.isFinished) {
      throw const FormatException('PBN export requires a completed deal');
    }
    // Standard PBN Auction + contract would imply an auction that never
    // happened. Declarer-training transcript v2 cannot be exported as one.
    if (state.isJustDeclare) {
      throw const FormatException('Just Declare has no real auction to export');
    }
    final contract = state.contract;
    final vulnerability = switch (state.vulnerability) {
      Vulnerability.none => 'None',
      Vulnerability.ns => 'NS',
      Vulnerability.ew => 'EW',
      Vulnerability.both => 'All',
    };
    final auction = state.auction.map((entry) {
      return switch (entry.call) {
        Pass() => 'Pass',
        DoubleCall() => 'X',
        RedoubleCall() => 'XX',
        Bid(:final level, :final strain) =>
            '$level${strain.code}',
      };
    }).toList();

    final result = contract == null
        ? null
        : state.tricks.where(
            (trick) => trick.winner.isNS == contract.declarer.isNS).length;
    final nsScore = state.nsScore!;

    final lines = <String>[
      '[Event "Bridge Academy completed practice"]',
      '[Site "Local"]',
      '[Board "${saved.board.number}"]',
      '[Dealer "${state.dealer.letter}"]',
      '[Vulnerable "$vulnerability"]',
      // This tag exposes ALL HANDS. Share only after explicit user consent.
      '[Deal "${state.deal.toPbn()}"]',
      '[Scoring "None"]',
      if (contract != null)
        '[Declarer "${contract.declarer.letter}"]',
      '[Contract "${contract?.label ?? 'Pass'}"]',
      if (contract != null)
        '[Result "$result"]',
      '[Score "NS ${nsScore >= 0 ? '+' : ''}$nsScore"]',
      '[Auction "${state.dealer.letter}"]',
      for (var i = 0; i < auction.length; i += 4)
        auction.skip(i).take(4).join(' '),
      '',
    ];
    if (contract != null) {
      if (state.tricks.length != 13 ||
          state.tricks.any((trick) => trick.plays.length != 4)) {
        throw const FormatException('Incomplete card play in terminal export');
      }
      final openingLeader = contract.openingLeader;
      lines.add('[Play "${openingLeader.letter}"]');
      // PBN v2.1 uses FIXED compass columns starting at the opening leader,
      // not the chronological order of cards within each later trick.
      // Bridge Core retains each card's actual hand owner and winner.
      final columns = [
        openingLeader,
        openingLeader.next,
        openingLeader.next.next,
        openingLeader.next.next.next,
      ];
      for (final trick in state.tricks) {
        lines.add(columns.map((seat) {
          final matches = trick.plays
              .where((play) => play.handOwner == seat).toList();
          if (matches.length != 1) {
            throw const FormatException('Invalid seat layout in PBN play');
          }
          return matches.single.card.code;
        }).join(' '));
      }
      lines.add('');
    }
    return lines.join('\n');
  }
}
