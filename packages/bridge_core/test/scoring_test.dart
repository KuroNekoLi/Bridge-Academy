import 'package:bridge_core/bridge_core.dart';
import 'package:test/test.dart';

void main() {
  group('Duplicate NS signed scoring', () {
    final cases = <(Contract, int, Vulnerability, int)>[
      (const Contract(level: 3, strain: Strain.notrump, declarer: Seat.east),
        8, Vulnerability.none, 50),
      (const Contract(level: 3, strain: Strain.notrump, declarer: Seat.north),
        9, Vulnerability.none, 400),
      (const Contract(level: 1, strain: Strain.notrump, declarer: Seat.north),
        8, Vulnerability.none, 120),
      (const Contract(level: 4, strain: Strain.spades,
          declarer: Seat.south, doubling: Doubling.doubled),
        10, Vulnerability.none, 590),
      (const Contract(level: 6, strain: Strain.notrump, declarer: Seat.north),
        12, Vulnerability.ns, 1440),
      (const Contract(level: 7, strain: Strain.notrump, declarer: Seat.north),
        13, Vulnerability.both, 2220),
      (const Contract(level: 2, strain: Strain.hearts,
          declarer: Seat.north, doubling: Doubling.doubled),
        5, Vulnerability.none, -500),
      (const Contract(level: 2, strain: Strain.hearts,
          declarer: Seat.north, doubling: Doubling.redoubled),
        5, Vulnerability.none, -1000),
      (const Contract(level: 4, strain: Strain.hearts, declarer: Seat.west),
        9, Vulnerability.ew, 100),
      (const Contract(level: 2, strain: Strain.clubs, declarer: Seat.north),
        8, Vulnerability.none, 90),
      (const Contract(level: 1, strain: Strain.diamonds,
          declarer: Seat.east, doubling: Doubling.redoubled),
        7, Vulnerability.none, -230),
    ];
    for (final (contract, tricks, vul, expected) in cases) {
      test('${contract.label} ${contract.declarer.letter} $tricks tricks, '
          '${vul.name}', () {
        expect(DuplicateScore.score(contract, tricks, vul), expected);
      });
    }

    test('score sign inverses NS/EW with same vulnerability', () {
      for (final strain in Strain.values) {
        for (final vul in [Vulnerability.none, Vulnerability.both]) {
          final north = Contract(level: 3, strain: strain, declarer: Seat.north);
          final east = Contract(level: 3, strain: strain, declarer: Seat.east);
          for (var tricks = 0; tricks <= 13; tricks++) {
            expect(DuplicateScore.score(north, tricks, vul),
                -DuplicateScore.score(east, tricks, vul));
          }
        }
      }
    });

    test('trick count bounds', () {
      expect(() => DuplicateScore.score(
          const Contract(level: 1, strain: Strain.clubs,
              declarer: Seat.north), 14, Vulnerability.none),
          throwsRangeError);
    });
  });
}

