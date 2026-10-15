import 'model.dart';

/// Duplicate board metadata from WBF Laws of Duplicate Bridge, Law 2.
///
/// Board number is session metadata, independent of the actual four hands.
/// The same dealer/vulnerability pattern repeats every 16 boards.
final class BoardDefinition {
  const BoardDefinition._({
    required this.number,
    required this.dealer,
    required this.vulnerability,
  });

  factory BoardDefinition.forNumber(int number) {
    if (number < 1) {
      throw RangeError.value(number, 'number', 'Board numbers start at 1');
    }
    return BoardDefinition._(
      number: number,
      dealer: Seat.values[(number - 1) % Seat.values.length],
      vulnerability: _vulnerabilityCycle[(number - 1) % 16],
    );
  }

  final int number;
  final Seat dealer;
  final Vulnerability vulnerability;

  static const _vulnerabilityCycle = <Vulnerability>[
    Vulnerability.none, Vulnerability.ns,
    Vulnerability.ew, Vulnerability.both,
    Vulnerability.ns, Vulnerability.ew,
    Vulnerability.both, Vulnerability.none,
    Vulnerability.ew, Vulnerability.both,
    Vulnerability.none, Vulnerability.ns,
    Vulnerability.both, Vulnerability.none,
    Vulnerability.ns, Vulnerability.ew,
  ];

  @override
  bool operator ==(Object other) =>
      other is BoardDefinition && other.number == number;

  @override
  int get hashCode => number.hashCode;

  @override
  String toString() =>
      'Board $number (dealer: ${dealer.letter}, vul: ${vulnerability.name})';
}
