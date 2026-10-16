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
    return lines.join('\n');
  }
}
