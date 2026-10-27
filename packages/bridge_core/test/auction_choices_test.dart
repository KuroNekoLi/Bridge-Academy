import 'package:bridge_core/bridge_core.dart';
import 'package:test/test.dart';

void main() {
  test('public choices and reducer agree; initial, X/XX, pass-out and 7NT boundaries', () {
    var state = GameState.start(Deal.shuffled(seed: 66), Seat.west, Vulnerability.none);
    List<String> codes() => BridgeGame.legalCalls(phase: state.phase, turn: state.turn,
      actor: state.turn ?? Seat.west, auction: state.auction).map((c) => c.code).toList();
    expect(codes().length, 36); expect(codes(), containsAll(['PASS', '1C', '7NT']));
    expect(codes(), isNot(contains('X'))); expect(codes(), isNot(contains('XX')));
    void apply(Call call) { state = BridgeGame.apply(state, CallAction(state.turn!, call)); }
    apply(const Bid(1, Strain.hearts));
    expect(codes(), contains('X')); expect(codes(), isNot(contains('1D')));
    final before = state;
    expect(() => BridgeGame.apply(state, CallAction(state.turn!, const RedoubleCall())), throwsA(isA<RuleViolation>()));
    expect(state, same(before)); expect(state.version, 1);
    apply(const DoubleCall()); expect(codes(), contains('XX')); expect(codes(), isNot(contains('X')));
    apply(const RedoubleCall()); expect(codes(), isNot(contains('XX')));
    apply(const Bid(7, Strain.notrump)); expect(codes(), ['PASS', 'X']);
    apply(const Pass()); expect(codes(), ['PASS']);
    apply(const Pass()); expect(codes(), ['PASS', 'X']);
    apply(const Pass()); expect(codes(), isEmpty);
    expect(BridgeGame.legalCalls(phase: Phase.auction, turn: Seat.north,
      actor: Seat.south, auction: const []), isEmpty);
    state = GameState.start(Deal.shuffled(seed: 67), Seat.north, Vulnerability.none);
    for (var i = 0; i < 4; i++) { apply(const Pass()); }
    expect(state.isPassOut, isTrue); expect(codes(), isEmpty);
  });
}
