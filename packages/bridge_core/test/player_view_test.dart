import 'dart:convert';
import 'package:bridge_core/bridge_core.dart';
import 'package:test/test.dart';

GameState dealWithNorthDeclarer() {
  var game = GameState.start(
      Deal.suitPerSeat(), Seat.north, Vulnerability.none);
  for (final call in const [Bid(1, Strain.notrump), Pass(), Pass(), Pass()]) {
    game = BridgeGame.apply(game, CallAction(game.turn!, call));
  }
  return game;
}

void main() {
  group('M2 PlayerView information boundary', () {
    test('at auction each seat sees only own hand; never opponent cards', () {
      final game = GameState.start(
          Deal.suitPerSeat(), Seat.north, Vulnerability.none);
      for (final seat in Seat.values) {
        final view = PlayerView.forSeat(game, seat);
        final json = jsonEncode(view.toJson());
        expect(view.ownCards.toSet(), game.hands[seat]);
        expect(view.dummyCards, isNull);
        expect(view.legalCards, isEmpty);
        expect(view.remainingCards.values, everyElement(13));
        expect(view.toJson().containsKey('deal'), false);
        expect(view.toJson().containsKey('dealPbn'), false);
        for (final other in Seat.values.where((s) => s != seat)) {
          for (final card in game.hands[other]!) {
            expect(json.contains('"${card.code}"'), false,
                reason: 'leaked opponent card to ${seat.name}');
          }
        }
      }
    });

    test('dummy is only exposed after lead; declarer controls dummy turn', () {
      var game = dealWithNorthDeclarer();
      for (final seat in Seat.values) {
        expect(PlayerView.forSeat(game, seat).dummyCards, isNull);
      }
      final first = game.legalCards(Seat.east).first;
      game = BridgeGame.apply(game, CardAction(Seat.east, Seat.east, first));
      for (final seat in Seat.values) {
        final view = PlayerView.forSeat(game, seat);
        expect(view.dummyCards!.toSet(), game.hands[Seat.south]);
        expect(view.dummyExposed, true);
      }
      final declarer = PlayerView.forSeat(game, Seat.north);
      final dummy = PlayerView.forSeat(game, Seat.south);
      expect(declarer.canAct, true);
      expect(declarer.legalCards.toSet(), game.hands[Seat.south]);
      expect(dummy.canAct, false);
      expect(dummy.legalCards, isEmpty);
      final json = jsonEncode(declarer.toJson());
      for (final card in game.hands[Seat.east]!) {
        expect(json.contains('"${card.code}"'), false);
      }
    });

    test('DTO collections cannot be modified and no privileged state fields', () {
      final view = PlayerView.forSeat(dealWithNorthDeclarer(), Seat.north);
      expect(() => view.ownCards.clear(), throwsUnsupportedError);
      expect(() => view.remainingCards.clear(), throwsUnsupportedError);
      expect(() => view.auction.clear(), throwsUnsupportedError);
      expect(view.toJson()['schemaVersion'], 1);
      expect(view.toJson().containsKey('hands'), false);
      expect(view.toJson().containsKey('events'), false);
    });

    test('only active seat has legal choices and canAct', () {
      final game = dealWithNorthDeclarer();
      final east = PlayerView.forSeat(game, Seat.east);
      final north = PlayerView.forSeat(game, Seat.north);
      expect(east.canAct, true);
      expect(east.legalCards.toSet(), game.legalCards(Seat.east));
      expect(north.canAct, false);
      expect(north.legalCards, isEmpty);
      expect(east.toJson()['turn'], 'E');
    });
  });
}

