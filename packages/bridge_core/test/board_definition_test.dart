import 'package:bridge_core/bridge_core.dart';
import 'package:test/test.dart';

void main() {
  group('P1-A1 WBF Law 2 duplicate board cycle', () {
    const expectedVulnerability = <Vulnerability>[
      Vulnerability.none,
      Vulnerability.ns,
      Vulnerability.ew,
      Vulnerability.both,
      Vulnerability.ns,
      Vulnerability.ew,
      Vulnerability.both,
      Vulnerability.none,
      Vulnerability.ew,
      Vulnerability.both,
      Vulnerability.none,
      Vulnerability.ns,
      Vulnerability.both,
      Vulnerability.none,
      Vulnerability.ns,
      Vulnerability.ew,
    ];

    test('boards 1..32 have canonical dealers and vulnerabilities', () {
      for (var number = 1; number <= 32; number++) {
        final board = BoardDefinition.forNumber(number);
        expect(board.number, number);
        expect(board.dealer, Seat.values[(number - 1) % 4],
            reason: 'board $number dealer');
        expect(board.vulnerability,
            expectedVulnerability[(number - 1) % 16],
            reason: 'board $number vulnerability');
      }
      expect(BoardDefinition.forNumber(17).dealer,
          BoardDefinition.forNumber(1).dealer);
      expect(BoardDefinition.forNumber(17).vulnerability,
          BoardDefinition.forNumber(1).vulnerability);
      expect(BoardDefinition.forNumber(32).vulnerability, Vulnerability.ew);
    });

    test('invalid board numbers are rejected', () {
      expect(() => BoardDefinition.forNumber(0), throwsRangeError);
      expect(() => BoardDefinition.forNumber(-1), throwsRangeError);
    });

    test('vulnerability changes real NS-signed duplicate scoring', () {
      const north3NT = Contract(
          level: 3, strain: Strain.notrump, declarer: Seat.north);
      const east3NT = Contract(
          level: 3, strain: Strain.notrump, declarer: Seat.east);
      expect(DuplicateScore.score(
          north3NT, 9, BoardDefinition.forNumber(1).vulnerability), 400);
      expect(DuplicateScore.score(
          north3NT, 9, BoardDefinition.forNumber(2).vulnerability), 600);
      expect(DuplicateScore.score(
          north3NT, 9, BoardDefinition.forNumber(3).vulnerability), 400);
      expect(DuplicateScore.score(
          east3NT, 9, BoardDefinition.forNumber(3).vulnerability), -600);
      expect(DuplicateScore.score(
          east3NT, 9, BoardDefinition.forNumber(2).vulnerability), -400);
    });

    test('immutable value identity follows board number', () {
      expect(BoardDefinition.forNumber(1), BoardDefinition.forNumber(1));
      expect(BoardDefinition.forNumber(17),
          isNot(BoardDefinition.forNumber(1)));
      expect(BoardDefinition.forNumber(17).hashCode, 17.hashCode);
    });
  });
}
