import 'package:bridge_dds_adapter/bridge_dds_adapter.dart';

/// If this compiles with 'dart compile js', Web has no native dart:io import.
void main() {
  final analyzer = DdsPythonProcessAnalyzer(workerScript: 'UNSUPPORTED');
  final unsupported = const UnsupportedDoubleDummyAnalyzer();
  assert(analyzer is DoubleDummyAnalyzer);
  assert(unsupported is DoubleDummyAnalyzer);
}
