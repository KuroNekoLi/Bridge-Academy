import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_gateway/bridge_gateway.dart';
import 'package:test/test.dart';

import 'package:bridge_gateway/src/a6_board_fixtures.dart';

void main() {
  group('A6 server-only fixed four-board matrix', () {
    test('all 52 cards, unique deals, WBF dealer and vulnerability', () {
      expect(a6Fixtures, hasLength(4));
      final distinct = <String>{};
      for (var i = 0; i < a6Fixtures.length; i++) {
        final board = a6Fixtures[i];
        final deal = board.deal;
        expect(board.number, i + 1);
        expect(board.metadata.dealer, Seat.values[i]);
        expect(board.metadata.vulnerability, Vulnerability.values[i]);
        expect(deal.hands.length, 4);
        expect(deal.hands.values.every((cards) => cards.length == 13), isTrue);
        expect(deal.hands.values.expand((cards) => cards).toSet(), hasLength(52));
        expect(distinct.add(deal.toPbn()), isTrue);
        expect(Deal.fromPbn(deal.toPbn()).toPbn(), deal.toPbn());
      }
    });

    test('server-owned board metadata is projected without hidden Deal', () {
      for (final board in a6Fixtures) {
        final game = AuthoritativeGame(
          deal: board.deal,
          trainingBoard: board.metadata,
          backend: const UnavailableDecisionBackend(),
        );
        final result = game.view()['view']! as Map<String, Object?>;
        expect(result['dealer'], board.metadata.dealer.letter);
        expect(result['vulnerability'], board.metadata.vulnerability.name);
        expect(result['viewer'], 'N');
        expect(result['ownCards'], hasLength(13));
        expect(result['dummyCards'], isNull);
        expect(result.keys, isNot(contains('deal')));
        expect(result.keys, isNot(contains('hands')));
        expect(result.keys, isNot(contains('transcript')));
      }
    });
  });
}
