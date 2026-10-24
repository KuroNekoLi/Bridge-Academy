import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_precision_adapter/bridge_precision_adapter.dart';
import 'package:test/test.dart';

final class _Record implements BbaTableBidTransport {
  @override
  Future<bool> researchReady() async => true;
  Map<String, Object>? last;
  Map<String, Object?>? inferenceOverride;
  @override
  Future<Map<String, Object?>> auctionInference(Map<String, Object> payload) async {
    last = payload;
    return inferenceOverride ?? {
      'provider': 'BBA_NATIVE_EPBOT',
      'profileId': PrecisionResearchCatalog.selectedProductProfileId,
      'revision': 1,
      'cardSha256': PrecisionResearchCatalog.selectedCardSha256,
      'source': 'BBA_AUCTION_ESTIMATE',
      'suitEstimates': {
        for (final seat in const ['N', 'E', 'S', 'W'])
          seat: {'C': 1, 'D': 2, 'H': 3, 'S': 4},
      },
    };
  }

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


  test('convention estimates change real legal-card preference, not simply '
      'first legal card', () async {
    const fixture = 'N:AJ5.KQ7.A982.K76 32.9843.J73.Q943 '
        'QT6.AJ6.KT6.JT52 K9874.T52.Q54.A8';
    final state = GameState.justDeclareStart(
      Deal.fromPbn(fixture), Seat.north, Vulnerability.none,
      const Contract(level: 3, strain: Strain.notrump,
          declarer: Seat.north, doubling: Doubling.none),
    );
    final v = PlayerView.forSeat(state, Seat.east);
    final fake = _Record();
    final policy = BbaResearchTablePolicy(fake, GameSystems(
        northSouth: ConventionCatalog.precisionMeckwell,
        eastWest: ConventionCatalog.sayc));
    Map<String, Object?> response(Map<String, Map<String, int>> estimates) => {
      'provider': 'BBA_NATIVE_EPBOT',
      'profileId': PrecisionResearchCatalog.selectedProductProfileId,
      'revision': 1,
      'cardSha256': PrecisionResearchCatalog.selectedCardSha256,
      'source': 'BBA_AUCTION_ESTIMATE', 'suitEstimates': estimates,
    };
    final basic = {
      for (final seat in const ['N','E','S','W'])
        seat: {'C': 0, 'D': 0, 'H': 0, 'S': 0},
    };
    fake.inferenceOverride = response({
      ...basic, 'W': {'C': 0, 'D': 0, 'H': 13, 'S': 0},
    });
    final hearts = (await policy.choose(v) as CardAction).card;
    expect(hearts.suit, Suit.hearts);
    expect(v.legalCards, contains(hearts));
    fake.inferenceOverride = response({
      ...basic, 'W': {'C': 13, 'D': 0, 'H': 0, 'S': 0},
    });
    final clubs = (await policy.choose(v) as CardAction).card;
    expect(clubs.suit, Suit.clubs);
    expect(clubs, isNot(hearts));

    fake.inferenceOverride = response({
      ...basic, 'W': {'C': 200, 'D': 0, 'H': 0, 'S': 0},
    });
    await expectLater(policy.choose(v),
        throwsA(isA<PrecisionProviderException>()));
  });


  test('experimental routing never silently changes non-Precision games', () {
    expect(BbaResearchTablePolicy.isSupported(GameSystems(
      northSouth: ConventionCatalog.twoOverOne,
      eastWest: ConventionCatalog.sayc,
    )), false);
  });
  test('real convention estimate is required for play, and only legal cards '
      'may be proposed', () async {
    final systems = GameSystems(
        northSouth: ConventionCatalog.precisionMeckwell,
        eastWest: ConventionCatalog.sayc);
    final engine = _Record();
    final policy = BbaResearchTablePolicy(engine, systems);
    final state = GameState.justDeclareStart(
      Deal.suitPerSeat(), Seat.north, Vulnerability.none,
      const Contract(level: 3, strain: Strain.notrump,
          declarer: Seat.north, doubling: Doubling.none),
    );
    final lead = PlayerView.forSeat(state, state.actorToPlay!);
    expect(lead.phase, Phase.play);
    final proposal = await policy.choose(lead);
    expect(proposal, isA<CardAction>());
    expect(lead.legalCards, contains((proposal as CardAction).card));
    expect(engine.last!['seat'], lead.viewer.letter);
    expect(engine.last!.keys, isNot(contains('deal')));
    expect(engine.last!.keys, isNot(contains('dummy')));
    expect(engine.last!.keys, isNot(contains('hands')));
  });

}
