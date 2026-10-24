import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_precision_adapter/bridge_precision_adapter.dart';
import 'package:test/test.dart';

final class _Record implements BbaTableBidTransport {
  @override
  Future<bool> researchReady() async => true;
  Map<String, Object>? last;
  @override
  Future<Map<String, Object?>> tableBid(Map<String, Object> payload) async {
    last = payload;
    return {
      'provider': 'BBA_NATIVE_EPBOT',
      'profileId': PrecisionResearchCatalog.selectedProductProfileId,
      'revision': 1,
      'cardSha256': PrecisionResearchCatalog.selectedCardSha256,
      'bid': 'PASS',
    };
  }
}

void main() {
  test('both BBA auction systems route per actor without exposed deal', () async {
    final systems = GameSystems(
      northSouth: ConventionCatalog.precisionMeckwell,
      eastWest: ConventionCatalog.sayc,
    );
    final transport = _Record();
    final policy = BbaResearchTablePolicy(transport, systems);
    final state = GameState.start(
        Deal.suitPerSeat(), Seat.east, Vulnerability.none);
    final e = await policy.choose(PlayerView.forSeat(state, Seat.east));
    expect(e, isA<CallAction>());
    expect(e.code, 'B:E:PASS');
    expect(transport.last!['northSouth'], 'BA-PRECISION-MECKWELL');
    expect(transport.last!['eastWest'], 'BA-SAYC');
    expect(transport.last!['seat'], 'E');
    expect(transport.last!.containsKey('deal'), false);
    expect(transport.last!.containsKey('dummy'), false);
    expect(transport.last!.containsKey('hands'), false);
  });

  test('rejects no Precision or two Precision and forged actor', () async {
    final transport = _Record();
    final none = GameSystems(
        northSouth: ConventionCatalog.sayc,
        eastWest: ConventionCatalog.twoOverOne);
    final both = GameSystems(
        northSouth: ConventionCatalog.precisionMeckwell,
        eastWest: ConventionCatalog.precisionMeckwell);
    expect(BbaResearchTablePolicy.isSupported(none), false);
    expect(BbaResearchTablePolicy.isSupported(both), false);
    await expectLater(
        BbaResearchTablePolicy(transport, none).choose(PlayerView.forSeat(
          GameState.start(Deal.suitPerSeat(), Seat.north, Vulnerability.none),
          Seat.north,
        )),
        throwsA(isA<PrecisionProviderException>()));
    expect(transport.last, isNull);
  });

  test('experimental routing never silently changes non-Precision games', () {
    expect(BbaResearchTablePolicy.isSupported(GameSystems(
      northSouth: ConventionCatalog.twoOverOne,
      eastWest: ConventionCatalog.sayc,
    )), false);
  });
}
