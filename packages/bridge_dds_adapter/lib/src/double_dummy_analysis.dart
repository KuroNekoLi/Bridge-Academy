import 'dart:async';

import 'package:bridge_core/bridge_core.dart';

/// Typed, sanitized failure modes. Never put a private Deal or raw PBN in a
/// public error, exception, trace, or analytics payload.
enum DoubleDummyFailureCode {
  invalidTranscript,
  cancelled,
  notFinished,
  unsupportedPlatform,
  unavailable,
  timeout,
  solverFailure,
  malformedResponse,
}

final class DoubleDummyAnalysisException implements Exception {
  const DoubleDummyAnalysisException(this.code);
  final DoubleDummyFailureCode code;

  @override
  String toString() => 'DoubleDummyAnalysisException: ${code.name}';
}

/// Cooperative process cancellation; native adapter kills the worker.
/// Cancellation is per invocation and does not mutate a Bridge Core board.
final class DdsAnalysisCancellation {
  final Completer<void> _done = Completer<void>();
  bool get isCancelled => _done.isCompleted;
  Future<void> get whenCancelled => _done.future;
  void cancel() {
    if (!_done.isCompleted) _done.complete();
  }
}

/// A capability created exclusively by a trusted archive after Bridge Core
/// has replayed ALL events, or by an explicitly identified test fixture.
///
/// Callers MUST enforce user authorization before retrieving a trusted
/// archive. This class is not a cryptographic authentication token.
final class TrustedCompletedBoard {
  TrustedCompletedBoard._(this._deal, this.dealer, this.vulnerability,
      this.fingerprint, this.fixtureOnly);

  final Deal _deal;
  final Seat dealer;
  final Vulnerability vulnerability;
  final String fingerprint;
  final bool fixtureOnly;

  /// This API must be called only inside a trusted local/server storage layer.
  /// A PlayerView, untrusted remote request, or unfinished saved game is NOT
  /// an acceptable source. Full original deal never leaves this package.
  factory TrustedCompletedBoard.fromTrustedTranscript(
      Map<String, dynamic> trustedStorageArchive) {
    final GameState state;
    try {
      state = GameTranscript.decode(trustedStorageArchive);
    } catch (_) {
      throw const DoubleDummyAnalysisException(
          DoubleDummyFailureCode.invalidTranscript);
    }
    if (!state.isFinished || state.contract == null ||
        state.tricks.length != 13 || state.nsScore == null) {
      throw const DoubleDummyAnalysisException(
          DoubleDummyFailureCode.notFinished);
    }
    return TrustedCompletedBoard._(
      state.deal, state.dealer, state.vulnerability,
      state.historyFingerprint, false);
  }

  /// Test-only fixture path: never call with a live deal or user-supplied PBN.
  /// This method deliberately states its reduced trust guarantees.
  factory TrustedCompletedBoard.explicitTeachingFixture({
    required Deal originalDeal,
    required Seat dealer,
    required Vulnerability vulnerability,
  }) => TrustedCompletedBoard._(
      originalDeal, dealer, vulnerability, 'TEACHING_FIXTURE', true);

  /// Internal canonical PBN for the sandboxed worker. Do not log or display.
  String toPrivateWorkerPbn() => _deal.toPbn();
}

/// DDS native row order S, H, D, C, NT; columns N, E, S, W.
/// A value is the number of tricks the named *declarer's partnership* may
/// take under double-dummy information, from the initial 52-card position.
final class DoubleDummyTable {
  DoubleDummyTable._(this._rows, {
    required this.solverCommit,
    required this.adapter,
    required this.boardFingerprint,
    required this.fixtureOnly,
  });

  static const upstreamCommit =
      'abb1127ba096676a4849f341f300c9827a732342';
  final List<List<int>> _rows;
  final String solverCommit;
  final String adapter;
  final String boardFingerprint;
  final bool fixtureOnly;

  int tricks({required Strain strain, required Seat declarer}) {
    final row = switch (strain) {
      Strain.spades => 0,
      Strain.hearts => 1,
      Strain.diamonds => 2,
      Strain.clubs => 3,
      Strain.notrump => 4,
    };
    return _rows[row][declarer.index];
  }

  Map<Strain, Map<Seat, int>> get byStrain =>
      Map<Strain, Map<Seat, int>>.unmodifiable({
        for (final strain in Strain.values)
          strain: Map<Seat, int>.unmodifiable({
            for (final seat in Seat.values)
              seat: tricks(strain: strain, declarer: seat),
          }),
      });

  factory DoubleDummyTable.fromWorkerResponse(
      Map<String, dynamic> payload, TrustedCompletedBoard board) {
    if (payload.keys.toSet().difference(
        {'schemaVersion', 'solverCommit', 'engine', 'resTable'}).isNotEmpty ||
        payload.length != 4 || payload['schemaVersion'] != 1 ||
        payload['solverCommit'] != upstreamCommit ||
        payload['engine'] != 'dds3-python-calc_dd_table') {
      throw const DoubleDummyAnalysisException(
          DoubleDummyFailureCode.malformedResponse);
    }
    final rows = payload['resTable'];
    if (rows is! List || rows.length != 5) {
      throw const DoubleDummyAnalysisException(
          DoubleDummyFailureCode.malformedResponse);
    }
    final typed = <List<int>>[];
    for (final row in rows) {
      if (row is! List || row.length != 4 ||
          row.any((v) => v is! int || v < 0 || v > 13)) {
        throw const DoubleDummyAnalysisException(
            DoubleDummyFailureCode.malformedResponse);
      }
      typed.add(List<int>.unmodifiable(row.cast<int>()));
    }
    return DoubleDummyTable._(List.unmodifiable(typed),
        solverCommit: upstreamCommit,
        adapter: 'dds3-python-calc_dd_table',
        boardFingerprint: board.fingerprint,
        fixtureOnly: board.fixtureOnly);
  }
}

/// Trusted postgame service; always inject the runtime adapter.
abstract interface class DoubleDummyAnalyzer {
  Future<DoubleDummyTable> analyze(TrustedCompletedBoard board);
}

/// Explicitly fail on runtimes with no installed verified native DDS worker.
final class UnsupportedDoubleDummyAnalyzer implements DoubleDummyAnalyzer {
  const UnsupportedDoubleDummyAnalyzer();
  @override
  Future<DoubleDummyTable> analyze(TrustedCompletedBoard board) async =>
      throw const DoubleDummyAnalysisException(
          DoubleDummyFailureCode.unsupportedPlatform);
}
