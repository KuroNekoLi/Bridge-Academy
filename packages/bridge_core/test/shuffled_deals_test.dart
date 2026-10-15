import 'package:bridge_core/bridge_core.dart';
import 'package:test/test.dart';

void main() {
  test('M2-F10: 100 shuffled fixed seeds produce 52 unique valid cards', () {
    final distinctBoards = <String>{};
    for (var seed = 2026101500; seed < 2026101600; seed++) {
      final deal = Deal.shuffled(seed: seed);
      final canonical = deal.toPbn();
      expect(Deal.shuffled(seed: seed).toPbn(), canonical);
      expect(Deal.fromPbn(canonical).toPbn(), canonical);
      expect(deal.hands.keys.toSet(), Seat.values.toSet());
      expect(deal.hands.values.map((cards) => cards.length),
          everyElement(13));
      final combined = deal.hands.values.expand((cards) => cards).toList();
      expect(combined.length, 52);
      expect(combined.toSet().length, 52);
      distinctBoards.add(canonical);
    }
    expect(distinctBoards.length, 100);
  });

  test('M2-F10: unseeded shuffled hands still respect 52-card invariants',
      () {
    final deal = Deal.shuffled();
    expect(deal.hands[Seat.north]!.length, 13);
    expect(deal.hands.values.expand((cards) => cards).toSet().length, 52);
    expect(Deal.fromPbn(deal.toPbn()).toPbn(), deal.toPbn());
  });
}

