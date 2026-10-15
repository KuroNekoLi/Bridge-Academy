import 'model.dart';

/// Pure Duplicate scoring, always from the North-South perspective.
abstract final class DuplicateScore {
  static int score(Contract contract, int declarerTricks, Vulnerability vul) {
    if (declarerTricks < 0 || declarerTricks > 13) {
      throw RangeError.range(declarerTricks, 0, 13, 'declarerTricks');
    }
    final vulnerable = vul.isVulnerable(contract.declarer);
    final made = declarerTricks - contract.targetTricks;
    int declaringScore;
    if (made < 0) {
      final down = -made;
      if (contract.doubling == Doubling.none) {
        declaringScore = -(down * (vulnerable ? 100 : 50));
      } else {
        final penalty = vulnerable
            ? 200 + 300 * (down - 1)
            : (down == 1 ? 100 : down == 2 ? 300 :
                down == 3 ? 500 : 500 + 300 * (down - 3));
        declaringScore = -penalty *
            (contract.doubling == Doubling.redoubled ? 2 : 1);
      }
    } else {
      final level = contract.level;
      final base = switch (contract.strain) {
        Strain.clubs || Strain.diamonds => 20 * level,
        Strain.hearts || Strain.spades => 30 * level,
        Strain.notrump => 40 + 30 * (level - 1),
      };
      final multiplier = switch (contract.doubling) {
        Doubling.none => 1,
        Doubling.doubled => 2,
        Doubling.redoubled => 4,
      };
      final trickScore = base * multiplier;
      final bonus = trickScore >= 100 ? (vulnerable ? 500 : 300) : 50;
      final slam = level == 7 ? (vulnerable ? 1500 : 1000) :
          level == 6 ? (vulnerable ? 750 : 500) : 0;
      final insult = switch (contract.doubling) {
        Doubling.none => 0,
        Doubling.doubled => 50,
        Doubling.redoubled => 100,
      };
      final regularOvertrick =
          contract.strain == Strain.clubs || contract.strain == Strain.diamonds
              ? 20 : 30;
      final overtrick = switch (contract.doubling) {
        Doubling.none => regularOvertrick,
        Doubling.doubled => vulnerable ? 200 : 100,
        Doubling.redoubled => vulnerable ? 400 : 200,
      };
      declaringScore = trickScore + bonus + slam + insult + made * overtrick;
    }
    return contract.declarer.isNS ? declaringScore : -declaringScore;
  }
}

