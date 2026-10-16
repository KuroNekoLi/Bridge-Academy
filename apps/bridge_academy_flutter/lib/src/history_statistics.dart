import 'completed_history_store.dart';

/// Aggregates only bounded, terminal and user-authorized history summaries.
/// Does not read a Deal, hidden hand, transcript, BEN action or raw PBN.
final class HistoryStatistics {
  const HistoryStatistics({
    required this.boards,
    required this.contracts,
    required this.knownContractOutcomes,
    required this.made,
    required this.passOut,
    required this.practice,
    required this.netHumanScore,
  });

  factory HistoryStatistics.from(Iterable<HistorySummary> records) {
    var boards = 0;
    var contracts = 0;
    var knownContractOutcomes = 0;
    var made = 0;
    var passOut = 0;
    var practice = 0;
    var netHumanScore = 0;
    for (final record in records) {
      boards++;
      // NS score is the domain's signed duplicate score. For E/W humans,
      // invert the sign; never mislabel it as MP, IMP or world ranking.
      netHumanScore += record.humanSeat.isNS ? record.score : -record.score;
      if (record.isPractice) practice++;
      if (record.contract == 'PASS OUT') {
        passOut++;
      } else {
        contracts++;
        if (record.contractMade != null) {
          knownContractOutcomes++;
          if (record.contractMade!) made++;
        }
      }
    }
    return HistoryStatistics(
      boards: boards,
      contracts: contracts,
      knownContractOutcomes: knownContractOutcomes,
      made: made,
      passOut: passOut,
      practice: practice,
      netHumanScore: netHumanScore,
    );
  }

  final int boards;
  final int contracts;
  final int knownContractOutcomes;
  final int made;
  final int passOut;
  final int practice;
  final int netHumanScore;

  /// Null if there were no contracts with a verified made/down result.
  int? get madePercent => knownContractOutcomes == 0
      ? null
      : (100 * made / knownContractOutcomes).round();
}
