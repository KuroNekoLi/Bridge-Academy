import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'double_dummy_analysis.dart';

/// A fail-closed, separate-process DDS3 Python worker.
///
/// Never pass full PBN as a command argument, environment variable or log.
/// Never re-use this adapter from live play/normal BotPolicy. The native DDS3
/// installation is intentionally external: no downloaded binary is vendored.
final class DdsPythonProcessAnalyzer implements DoubleDummyAnalyzer {
  DdsPythonProcessAnalyzer({
    required this.workerScript,
    this.pythonExecutable = 'python3',
    this.timeout = const Duration(seconds: 30),
    this.maxOutputBytes = 4096,
    this.environment = const {},
  }) {
    if (timeout <= Duration.zero || maxOutputBytes < 256 ||
        workerScript.isEmpty || pythonExecutable.isEmpty) {
      throw ArgumentError('Invalid DDS worker configuration');
    }
  }

  final String workerScript;
  final String pythonExecutable;
  final Duration timeout;
  final int maxOutputBytes;
  final Map<String, String> environment;

  @override
  Future<DoubleDummyTable> analyze(TrustedCompletedBoard board) async {
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) {
      throw const DoubleDummyAnalysisException(
          DoubleDummyFailureCode.unsupportedPlatform);
    }
    if (!File(workerScript).existsSync()) {
      throw const DoubleDummyAnalysisException(
          DoubleDummyFailureCode.unavailable);
    }

    Process process;
    try {
      process = await Process.start(
        pythonExecutable,
        [workerScript],
        environment: environment,
        includeParentEnvironment: true,
        runInShell: false,
      );
    } catch (_) {
      throw const DoubleDummyAnalysisException(
          DoubleDummyFailureCode.unavailable);
    }

    Timer? timer;
    var timedOut = false;
    var exceeded = false;
    final bytes = <int>[];

    // Consume both channels concurrently: a full stderr pipe must not
    // deadlock the process. Neither stderr nor its possible private input
    // fragments are ever included in thrown errors.
    final standardOut = process.stdout.listen((chunk) {
      if (bytes.length + chunk.length > maxOutputBytes) {
        exceeded = true;
        process.kill();
      } else {
        bytes.addAll(chunk);
      }
    });
    final discardedErr = process.stderr.drain<void>();
    try {
      timer = Timer(timeout, () {
        timedOut = true;
        process.kill();
      });
      process.stdin.add(utf8.encode(jsonEncode({
        'schemaVersion': 1,
        'pbn': board.toPrivateWorkerPbn(),
      })));
      await process.stdin.close();
      final exitCode = await process.exitCode;
      await standardOut.asFuture<void>();
      await discardedErr;
      if (timedOut) {
        throw const DoubleDummyAnalysisException(
            DoubleDummyFailureCode.timeout);
      }
      if (exceeded) {
        throw const DoubleDummyAnalysisException(
            DoubleDummyFailureCode.malformedResponse);
      }
      if (exitCode != 0) {
        throw const DoubleDummyAnalysisException(
            DoubleDummyFailureCode.solverFailure);
      }
      final dynamic decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const DoubleDummyAnalysisException(
            DoubleDummyFailureCode.malformedResponse);
      }
      return DoubleDummyTable.fromWorkerResponse(decoded, board);
    } on DoubleDummyAnalysisException {
      rethrow;
    } catch (_) {
      throw const DoubleDummyAnalysisException(
          DoubleDummyFailureCode.malformedResponse);
    } finally {
      timer?.cancel();
      if (timedOut || exceeded) process.kill();
    }
  }
}
