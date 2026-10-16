import 'double_dummy_analysis.dart';

/// Dart Web / unsupported runtime: retain the same public constructor shape
/// as native without ever importing dart:io or spawning a fake solver.
final class DdsPythonProcessAnalyzer implements DoubleDummyAnalyzer {
  DdsPythonProcessAnalyzer({
    required this.workerScript,
    this.pythonExecutable = 'python3',
    this.timeout = const Duration(seconds: 30),
    this.maxOutputBytes = 4096,
    this.environment = const {},
  });

  final String workerScript;
  final String pythonExecutable;
  final Duration timeout;
  final int maxOutputBytes;
  final Map<String, String> environment;

  @override
  Future<DoubleDummyTable> analyze(TrustedCompletedBoard board) =>
      analyzeWithCancellation(board);

  Future<DoubleDummyTable> analyzeWithCancellation(
      TrustedCompletedBoard board, {DdsAnalysisCancellation? cancellation}) async =>
      throw const DoubleDummyAnalysisException(
          DoubleDummyFailureCode.unsupportedPlatform);
}
