import 'package:bridge_core/bridge_core.dart';

/// SERVER-ONLY, reproducible test deals. A private Deal is never sent to an
/// untrusted client, the ordinary BEN player view, or CI diagnostics.
/// Rotated, fixed PBN hands form distinct deals for four dealer/vulnerability
/// combinations. These teaching fixtures are not competition-random deals.
final class A6BoardFixture {
  const A6BoardFixture(this.id, this.number, this.pbn, this.openingCall);

  final String id;
  final int number;
  final String pbn;
  final String openingCall;

  BoardDefinition get metadata => BoardDefinition.forNumber(number);
  Deal get deal => Deal.fromPbn(pbn);
}

const a6Fixtures = <A6BoardFixture>[
  A6BoardFixture(
    'A6-01-NT', 1,
    'N:AJ5.KQ7.A982.K76 32.9843.J73.Q943 '
    'QT6.AJ6.KT6.JT52 K9874.T52.Q54.A8', '3NT'),
  A6BoardFixture(
    'A6-02-S', 2,
    'N:32.9843.J73.Q943 QT6.AJ6.KT6.JT52 '
    'K9874.T52.Q54.A8 AJ5.KQ7.A982.K76', '4S'),
  A6BoardFixture(
    'A6-03-H', 3,
    'N:QT6.AJ6.KT6.JT52 K9874.T52.Q54.A8 '
    'AJ5.KQ7.A982.K76 32.9843.J73.Q943', '4H'),
  A6BoardFixture(
    'A6-04-C', 4,
    'N:K9874.T52.Q54.A8 AJ5.KQ7.A982.K76 '
    '32.9843.J73.Q943 QT6.AJ6.KT6.JT52', '5C'),
];
