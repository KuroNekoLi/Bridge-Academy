import 'package:bridge_ben_adapter/bridge_ben_adapter.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:test/test.dart';

class _RecordingTransport implements BenTransport {
  String? route;
  Map<String, String>? query;

  @override
  Future<Map<String, dynamic>> get(
    String path, Map<String, String> parameters,
  ) async {
    route = path;
    query = Map.unmodifiable(parameters);
    return {'bid': 'PASS'};
  }
}

void main() {
  test('P1-A1: BEN receives actual board 2 East dealer / NS vulnerability',
      () async {
    final board = BoardDefinition.forNumber(2);
    final game = GameState.start(
      Deal.suitPerSeat(), board.dealer, board.vulnerability,
    );
    final transport = _RecordingTransport();
    final action = await BenBotPolicy(transport).choose(
      PlayerView.forSeat(game, Seat.east),
    );
    expect(action, isA<CallAction>());
    expect(transport.route, '/bid');
    expect(transport.query!['dealer'], 'E');
    expect(transport.query!['vul'], 'NS');
    expect(transport.query!['seat'], 'E');
    expect(transport.query!.containsKey('deal'), isFalse);
    expect(transport.query!.containsKey('dummy'), isFalse);
  });

  test('P1-A1: BEN receives board 3 South dealer / EW vulnerability',
      () async {
    final board = BoardDefinition.forNumber(3);
    final game = GameState.start(
      Deal.suitPerSeat(), board.dealer, board.vulnerability,
    );
    final transport = _RecordingTransport();
    await BenBotPolicy(transport).choose(
      PlayerView.forSeat(game, Seat.south),
    );
    expect(transport.query!['dealer'], 'S');
    expect(transport.query!['vul'], 'EW');
    expect(transport.query!.containsKey('hands'), isFalse);
  });
}
