import 'package:bridge_ben_adapter/bridge_ben_adapter.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:test/test.dart';

class RecordingTransport implements BenTransport {
  RecordingTransport(this.reply);
  Map<String, dynamic> reply;
  String? route;
  Map<String, String>? query;
  @override
  Future<Map<String, dynamic>> get(String path, Map<String, String> args) async {
    route = path;
    query = Map.of(args);
    return reply;
  }
}

GameState noTrumpGame() {
  var state = GameState.start(
      Deal.suitPerSeat(), Seat.north, Vulnerability.ns);
  for (final call in const [Bid(1, Strain.notrump), Pass(), Pass(), Pass()]) {
    state = BridgeGame.apply(state, CallAction(state.turn!, call));
  }
  return state;
}

void main() {
  group('M2.2 seat-scoped BID/LEAD/PLAY system routing', () {
    final mixed = GameSystems(
      northSouth: ConventionCatalog.twoOverOne,
      eastWest: ConventionCatalog.sayc,
    );

    test('north bids in 21GF versus EW SAYC without leaking other cards', () async {
      final transport = RecordingTransport({'bid': 'PASS'});
      await BenBotPolicy(transport, gameSystems: mixed).choose(
        PlayerView.forSeat(
          GameState.start(Deal.suitPerSeat(), Seat.north, Vulnerability.none),
          Seat.north));
      expect(transport.route, '/bid');
      expect(transport.query!['ourSystem'], '21GF');
      expect(transport.query!['theirSystem'], 'SAYC');
      expect(transport.query!.keys, isNot(contains('deal')));
      expect(transport.query!.keys, isNot(contains('dummy')));
    });

    test('east BID swaps our and opponent systems', () async {
      final transport = RecordingTransport({'bid': 'PASS'});
      await BenBotPolicy(transport, gameSystems: mixed).choose(
        PlayerView.forSeat(
          GameState.start(Deal.suitPerSeat(), Seat.east, Vulnerability.none),
          Seat.east));
      expect(transport.query!['ourSystem'], 'SAYC');
      expect(transport.query!['theirSystem'], '21GF');
    });

    test('south/north partner parity is not turn-index inference', () async {
      var game = GameState.start(
          Deal.suitPerSeat(), Seat.north, Vulnerability.none);
      game = BridgeGame.apply(game, const CallAction(Seat.north, Pass()));
      game = BridgeGame.apply(game, const CallAction(Seat.east, Pass()));
      final transport = RecordingTransport({'bid': 'PASS'});
      await BenBotPolicy(transport, gameSystems: mixed).choose(
          PlayerView.forSeat(game, Seat.south));
      expect(transport.query!['ourSystem'], '21GF');
      expect(transport.query!['theirSystem'], 'SAYC');
    });

    test('opening lead retains the correct partnership system', () async {
      final game = noTrumpGame();
      final transport = RecordingTransport({'card': 'D2'});
      await BenBotPolicy(transport, gameSystems: mixed).choose(
          PlayerView.forSeat(game, Seat.east));
      expect(transport.route, '/lead');
      expect(transport.query!['ourSystem'], 'SAYC');
      expect(transport.query!['theirSystem'], '21GF');
      expect(transport.query, isNot(contains('dummy')));
    });

    test('legacy game stays free of system query fields', () async {
      final transport = RecordingTransport({'bid': 'PASS'});
      await BenBotPolicy(transport,
          gameSystems: GameSystems.legacyUnverified()).choose(
        PlayerView.forSeat(
          GameState.start(Deal.suitPerSeat(), Seat.north, Vulnerability.none),
          Seat.north));
      expect(transport.query, isNot(contains('ourSystem')));
      expect(transport.query, isNot(contains('theirSystem')));
    });

    test('mixed verified and legacy profiles fail closed', () async {
      final bad = GameSystems(
        northSouth: ConventionCatalog.twoOverOne,
        eastWest: ConventionCatalog.legacyUnverified,
      );
      final transport = RecordingTransport({'bid': 'PASS'});
      await expectLater(
        BenBotPolicy(transport, gameSystems: bad).choose(
          PlayerView.forSeat(
            GameState.start(Deal.suitPerSeat(), Seat.north, Vulnerability.none),
            Seat.north)),
        throwsA(isA<BenApiException>()),
      );
      expect(transport.route, isNull);
    });
  });

  group('M2-F03: BEN wire contract (RECORDED FAKE, not real BEN)', () {
    test('/bid gets own original hand, dealer, absolute vulnerability and ctx',
        () async {
      final fake = RecordingTransport({'bid': '1N', 'who': 'NN'});
      final bot = BenBotPolicy(fake);
      final state = GameState.start(
          Deal.suitPerSeat(), Seat.north, Vulnerability.ns);
      final result = await bot.choose(PlayerView.forSeat(state, Seat.north));
      expect(result, isA<CallAction>());
      expect((result as CallAction).call, isA<Bid>());
      final bid = result.call as Bid;
      expect(bid.level, 1);
      expect(bid.strain, Strain.notrump);
      expect(fake.route, '/bid');
      expect(fake.query, {
        'hand': '...AKQJT98765432',
        'seat': 'N', 'dealer': 'N', 'vul': 'NS', 'ctx': '',
      });
    });

    test('ctx uses P, X, XX and N for notrump', () {
      final history = <AuctionEntry>[
        const AuctionEntry(Seat.north, Bid(1, Strain.notrump)),
        const AuctionEntry(Seat.east, DoubleCall()),
        const AuctionEntry(Seat.south, RedoubleCall()),
        const AuctionEntry(Seat.west, Pass()),
      ];
      expect(BenProtocol.auction(history), '1N-X-XX-P');
      expect(BenProtocol.vulnerability(Vulnerability.both), 'Both');
      expect(BenProtocol.vulnerability(Vulnerability.ew), 'EW');
      expect(BenProtocol.vulnerability(Vulnerability.none), '');
    });

    test('/lead uses leader own 13, not exposed dummy', () async {
      final game = noTrumpGame();
      final transport = RecordingTransport({'card': 'D2'});
      final action =
          await BenBotPolicy(transport).choose(PlayerView.forSeat(game, Seat.east));
      expect(transport.route, '/lead');
      expect(transport.query!['hand'], '..AKQJT98765432.');
      expect(transport.query!['ctx'], '1N-P-P-P');
      expect(transport.query!.containsKey('dummy'), false);
      expect(transport.query!.containsKey('played'), false);
      expect((action as CardAction).actor, Seat.east);
      expect(action.handOwner, Seat.east);
      expect(action.card, const Card(Suit.diamonds, Rank.two));
    });

    test('/play by declarer for dummy only sends declarer+exposed dummy hands',
        () async {
      var game = noTrumpGame();
      game = BridgeGame.apply(game, const CardAction(
          Seat.east, Seat.east, Card(Suit.diamonds, Rank.two)));
      final transport = RecordingTransport({'card': 'H2', 'player': 1});
      final action =
          await BenBotPolicy(transport).choose(PlayerView.forSeat(game, Seat.north));
      expect(transport.route, '/play');
      expect(transport.query, containsPair('seat', 'N'));
      expect(transport.query, containsPair('hand', '...AKQJT98765432'));
      expect(transport.query, containsPair('dummy', '.AKQJT98765432..'));
      expect(transport.query, containsPair('played', 'D2'));
      expect(transport.query!.containsKey('deal'), false);
      expect(action, isA<CardAction>());
      final card = action as CardAction;
      expect(card.actor, Seat.north);
      expect(card.handOwner, Seat.south);
      expect(card.card, const Card(Suit.hearts, Rank.two));
    });

    test('reconstruct original hand from remaining cards and public plays',
        () {
      var game = noTrumpGame();
      for (final p in [
        const CardAction(Seat.east, Seat.east, Card(Suit.diamonds, Rank.two)),
        const CardAction(Seat.north, Seat.south, Card(Suit.hearts, Rank.two)),
        const CardAction(Seat.west, Seat.west, Card(Suit.spades, Rank.two)),
        const CardAction(Seat.north, Seat.north, Card(Suit.clubs, Rank.two)),
      ]) {
        game = BridgeGame.apply(game, p);
      }
      final east = PlayerView.forSeat(game, Seat.east);
      expect(east.ownCards.length, 12);
      expect(BenProtocol.originalHand(east, Seat.east), '..AKQJT98765432.');
      expect(BenProtocol.played(east), 'D2H2S2C2');
      expect(BenProtocol.originalHand(east, Seat.south),
          '.AKQJT98765432..');
      expect(() => BenProtocol.originalHand(east, Seat.west),
          throwsA(isA<BenApiException>()));
    });

    test('reject illegal BEN card before Bridge Core commits it', () async {
      final fake = RecordingTransport({'card': 'SA'});
      final game = noTrumpGame();
      await expectLater(
          BenBotPolicy(fake).choose(PlayerView.forSeat(game, Seat.east)),
          throwsA(isA<BenApiException>()));
    });

    test('reject missing bid, unknown card, out-of-turn view', () async {
      expect(() => BenProtocol.parseCall(null), throwsA(isA<BenApiException>()));
      expect(() => BenProtocol.parseCall('8NT'), throwsA(isA<BenApiException>()));
      expect(() => BenProtocol.parseCard('ZZ'), throwsA(isA<BenApiException>()));
      final game = noTrumpGame();
      await expectLater(
          BenBotPolicy(RecordingTransport({'bid': 'PASS'}))
              .choose(PlayerView.forSeat(game, Seat.west)),
          throwsA(isA<BenApiException>()));
    });

    test('parse call aliases including Pass, Double and Redouble', () {
      expect(BenProtocol.parseCall('PASS'), isA<Pass>());
      expect(BenProtocol.parseCall('--'), isA<Pass>());
      expect(BenProtocol.parseCall('Db'), isA<DoubleCall>());
      expect(BenProtocol.parseCall('Rd'), isA<RedoubleCall>());
      expect((BenProtocol.parseCall('3NT') as Bid).strain, Strain.notrump);
    });
  });
}

