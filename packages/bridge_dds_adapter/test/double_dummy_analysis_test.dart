import 'dart:io';
import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_dds_adapter/bridge_dds_adapter.dart';
import 'package:test/test.dart';

GameState _completedState() {
  final deal = Deal.suitPerSeat();
  var state = GameState.justDeclareStart(
    deal, Seat.north, Vulnerability.ns,
    const Contract(level: 1, strain: Strain.notrump, declarer: Seat.north),
  );
  while (!state.isFinished) {
    final owner = state.turn!;
    final actor = owner == state.contract!.dummy
        ? state.contract!.declarer : owner;
    state = BridgeGame.apply(state,
        CardAction(actor, owner, state.legalCards(owner).first));
  }
  return state;
}

Future<File> _temporaryPythonWorker(
    Directory directory, String source) async {
  final script = File('${directory.path}/worker.py');
  await script.writeAsString(source);
  return script;
}

void main() {
  test('Reject unfinished archive, corrupt archive, and pass out', () {
    final unfinished = GameTranscript.encode(GameState.start(
        Deal.suitPerSeat(), Seat.north, Vulnerability.none));
    expect(() => TrustedCompletedBoard.fromTrustedTranscript(unfinished),
      throwsA(isA<DoubleDummyAnalysisException>().having(
        (e) => e.code, 'code', DoubleDummyFailureCode.notFinished)));
    final corrupt = Map<String, dynamic>.from(unfinished)
      ..['dealPbn'] = 'N:AAA.X.Y.Z';
    expect(() => TrustedCompletedBoard.fromTrustedTranscript(corrupt),
      throwsA(isA<DoubleDummyAnalysisException>().having(
        (e) => e.code, 'code', DoubleDummyFailureCode.invalidTranscript)));
    var state = GameState.start(Deal.suitPerSeat(),
        Seat.north, Vulnerability.none);
    for (final seat in Seat.values) {
      state = BridgeGame.apply(state, CallAction(seat, const Pass()));
    }
    expect(() => TrustedCompletedBoard.fromTrustedTranscript(
        GameTranscript.encode(state)),
      throwsA(isA<DoubleDummyAnalysisException>().having(
        (e) => e.code, 'code', DoubleDummyFailureCode.notFinished)));
  });

  test('Terminal 13-trick archive is accepted without exposing card data', () {
    final state = _completedState();
    expect(state.tricks.length, 13);
    final board = TrustedCompletedBoard.fromTrustedTranscript(
        GameTranscript.encode(state));
    expect(board.fixtureOnly, false);
    expect(board.toString().contains('N:'), false);
    expect(board.fingerprint, state.historyFingerprint);
    expect(board.toPrivateWorkerPbn(), state.deal.toPbn());
  });

  test('Invalid DDS matrix, wrong upstream revision and extra keys rejected', () {
    final board = TrustedCompletedBoard.explicitTeachingFixture(
      originalDeal: Deal.suitPerSeat(),
      dealer: Seat.north, vulnerability: Vulnerability.ew);
    Map<String, dynamic> response(List<List<int>> rows) => {
      'schemaVersion': 1,
      'solverCommit': DoubleDummyTable.upstreamCommit,
      'engine': 'dds3-python-calc_dd_table',
      'resTable': rows,
    };
    final zero = List.generate(5, (_) => List.filled(4, 0));
    expect(() => DoubleDummyTable.fromWorkerResponse(
        {...response(zero), 'dealPbn': 'SECRET'}, board),
      throwsA(isA<DoubleDummyAnalysisException>()));
    expect(() => DoubleDummyTable.fromWorkerResponse(
        {...response(zero), 'solverCommit': 'other-version'}, board),
      throwsA(isA<DoubleDummyAnalysisException>()));
    expect(() => DoubleDummyTable.fromWorkerResponse(
        response([...zero.take(4), [14, 0, 0, 0]]), board),
      throwsA(isA<DoubleDummyAnalysisException>()));
    final table = DoubleDummyTable.fromWorkerResponse(response(zero), board);
    expect(table.tricks(strain: Strain.notrump, declarer: Seat.west), 0);
    expect(table.byStrain.length, 5);
    expect(table.byStrain.values.every((row) => row.length == 4), true);
  });

  test('Native process contract + 5x4 mapping (FAKE runner, not DDS)', () async {
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) return;
    final dir = await Directory.systemTemp.createTemp('c1-dds-contract-');
    addTearDown(() => dir.delete(recursive: true));
    final script = await _temporaryPythonWorker(dir, """
import json,sys
request=json.load(sys.stdin)
assert set(request)=={'schemaVersion','pbn'}
rows=[[10,11,12,13],[6,7,8,9],[2,3,4,5],[0,1,2,3],[4,5,6,7]]
print(json.dumps({'schemaVersion':1,'solverCommit':
'abb1127ba096676a4849f341f300c9827a732342',
'engine':'dds3-python-calc_dd_table','resTable':rows}))
""");
    final service = DdsPythonProcessAnalyzer(workerScript: script.path);
    final board = TrustedCompletedBoard.explicitTeachingFixture(
      originalDeal: Deal.suitPerSeat(),
      dealer: Seat.north, vulnerability: Vulnerability.both);
    final table = await service.analyze(board);
    expect(table.tricks(strain: Strain.spades, declarer: Seat.north), 10);
    expect(table.tricks(strain: Strain.hearts, declarer: Seat.south), 8);
    expect(table.tricks(strain: Strain.diamonds, declarer: Seat.west), 5);
    expect(table.tricks(strain: Strain.clubs, declarer: Seat.east), 1);
    expect(table.tricks(strain: Strain.notrump, declarer: Seat.north), 4);
    expect(table.fixtureOnly, true);
  });

  test('Timeout and errors fail closed; private PBN never in errors', () async {
    if (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows) return;
    final dir = await Directory.systemTemp.createTemp('c1-dds-negative-');
    addTearDown(() => dir.delete(recursive: true));
    final slow = await _temporaryPythonWorker(dir,
        'import time\ntime.sleep(2)\n');
    final board = TrustedCompletedBoard.explicitTeachingFixture(
      originalDeal: Deal.suitPerSeat(), dealer: Seat.north,
      vulnerability: Vulnerability.none);
    await expectLater(
      DdsPythonProcessAnalyzer(workerScript: slow.path,
        timeout: const Duration(milliseconds: 100)).analyze(board),
      throwsA(isA<DoubleDummyAnalysisException>().having(
          (e) => e.code, 'code', DoubleDummyFailureCode.timeout)));
    final noisy = await _temporaryPythonWorker(dir,
      'import sys\nsys.stderr.write("N:PRIVATE_PBN")\nsys.exit(2)\n');
    try {
      await DdsPythonProcessAnalyzer(workerScript: noisy.path).analyze(board);
      fail('Should have rejected failing worker');
    } on DoubleDummyAnalysisException catch (e) {
      expect(e.code, DoubleDummyFailureCode.solverFailure);
      expect(e.toString(), isNot(contains('PRIVATE_PBN')));
    }
  });

  test('Unsupported native environment is explicit', () async {
    final board = TrustedCompletedBoard.explicitTeachingFixture(
      originalDeal: Deal.suitPerSeat(),
      dealer: Seat.north, vulnerability: Vulnerability.none);
    await expectLater(const UnsupportedDoubleDummyAnalyzer().analyze(board),
      throwsA(isA<DoubleDummyAnalysisException>().having(
        (e) => e.code, 'code', DoubleDummyFailureCode.unsupportedPlatform)));
  });
}
