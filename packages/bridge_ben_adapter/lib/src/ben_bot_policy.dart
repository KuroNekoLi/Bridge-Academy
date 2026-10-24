import 'package:bridge_core/bridge_core.dart';
import 'package:bridge_conventions/bridge_conventions.dart';
import 'ben_transport.dart';

/// Stateless BEN robot. Takes a filtered PlayerView, never GameState or Deal.
/// The coordinator validates the resulting proposal with BridgeGame.apply.
class BenBotPolicy implements BotPolicy {
  const BenBotPolicy(this.transport, {this.gameSystems});
  final BenTransport transport;
  final GameSystems? gameSystems;

  @override
  Future<GameAction> choose(PlayerView view) async {
    if (!view.canAct || view.actorToPlay != view.viewer) {
      throw const BenApiException('state', 'Not controlling robot turn');
    }
    final query = <String, String>{
      'hand': BenProtocol.originalHand(view, view.viewer),
      'seat': view.viewer.letter,
      'dealer': view.dealer.letter,
      'vul': BenProtocol.vulnerability(view.vulnerability),
      'ctx': BenProtocol.auction(view.auction),
    };
    // BEN supports request-scoped partnership systems on bid, lead and play.
    // Never silently mix pinned and legacy opponents.
    final systems = gameSystems;
    if (systems != null &&
        (!systems.northSouth.isLegacyUnverified ||
         !systems.eastWest.isLegacyUnverified)) {
      final ours = systems.forPartnership(northSouthSeat: view.viewer.isNS);
      final theirs = systems.forPartnership(northSouthSeat: !view.viewer.isNS);
      if (ours.isLegacyUnverified || theirs.isLegacyUnverified ||
          ours.engineId != 'BEN' || theirs.engineId != 'BEN') {
        throw const BenApiException('system', 'Unverified mixed partnership systems');
      }
      query['ourSystem'] = ours.modelId;
      query['theirSystem'] = theirs.modelId;
    }
    if (view.phase == Phase.auction) {
      final response = await transport.get('/bid', query);
      return CallAction(view.viewer, BenProtocol.parseCall(response['bid']));
    }
    if (view.phase != Phase.play || view.turn == null || view.contract == null) {
      throw const BenApiException('state', 'Expected contract play');
    }
    final opening = view.completedTricks.isEmpty && view.currentTrick.isEmpty;
    final route = opening ? '/lead' : '/play';
    if (!opening) {
      if (view.dummyCards == null) {
        throw const BenApiException('state', 'Dummy has not been exposed');
      }
      query['dummy'] = BenProtocol.originalHand(view, view.contract!.dummy);
      query['played'] = BenProtocol.played(view);
    }
    final response = await transport.get(route, query);
    final card = BenProtocol.parseCard(response['card']);
    if (!view.legalCards.contains(card)) {
      throw const BenApiException('illegal', 'BEN proposed a non-legal card');
    }
    return CardAction(view.viewer, view.turn!, card);
  }
}

/// Encodes BEN request context entirely from permitted information.
abstract final class BenProtocol {
  static String vulnerability(Vulnerability vul) => switch (vul) {
    Vulnerability.none => '',
    Vulnerability.ns => 'NS',
    Vulnerability.ew => 'EW',
    Vulnerability.both => 'Both',
  };

  /// New-style dash-separated auction; N for NT, P for PASS.
  static String auction(List<AuctionEntry> entries) =>
      entries.map((entry) {
        final call = entry.call;
        if (call is Pass) return 'P';
        if (call is DoubleCall) return 'X';
        if (call is RedoubleCall) return 'XX';
        if (call is Bid) {
          final strain = call.strain == Strain.notrump ? 'N' : call.strain.code;
          return '${call.level}$strain';
        }
        throw const BenApiException('request', 'Unsupported call type');
      }).join('-');

  /// Rebuild the original 13 cards from the current hand + publicly played
  /// cards. The exposed dummy is the ONLY other seat permitted here.
  static String originalHand(PlayerView view, Seat seat) {
    final cards = <Card>{};
    if (seat == view.viewer) {
      cards.addAll(view.ownCards);
    } else if (seat == view.contract?.dummy && view.dummyExposed) {
      cards.addAll(view.dummyCards ?? const <Card>[]);
    } else {
      throw const BenApiException('privacy', 'Non-public hand requested');
    }
    for (final trick in view.completedTricks) {
      for (final played in trick.plays) {
        if (played.handOwner == seat) cards.add(played.card);
      }
    }
    for (final played in view.currentTrick) {
      if (played.handOwner == seat) cards.add(played.card);
    }
    if (cards.length != 13) {
      throw const BenApiException('state', 'Incomplete known original hand');
    }
    return [Suit.spades, Suit.hearts, Suit.diamonds, Suit.clubs].map((suit) {
      final ranks = cards.where((c) => c.suit == suit).map((c) => c.rank).toList()
        ..sort((a, b) => b.index.compareTo(a.index));
      return ranks.map((r) => r.symbol).join();
    }).join('.');
  }

  static String played(PlayerView view) => [
    for (final trick in view.completedTricks)
      for (final p in trick.plays) p.card.code,
    for (final p in view.currentTrick) p.card.code,
  ].join();

  static Call parseCall(Object? value) {
    if (value is! String) {
      throw const BenApiException('response', 'Bid must be string');
    }
    final code = value.trim().toUpperCase();
    if (const {'PASS', 'P', '--', 'PA'}.contains(code)) return const Pass();
    if (const {'X', 'DB', 'DOUBLE'}.contains(code)) return const DoubleCall();
    if (const {'XX', 'RD', 'REDOUBLE'}.contains(code)) return const RedoubleCall();
    final match = RegExp(r'^([1-7])(C|D|H|S|N|NT)$').firstMatch(code);
    if (match == null) {
      throw const BenApiException('response', 'Unknown BEN bid code');
    }
    final strain = switch (match.group(2)) {
      'C' => Strain.clubs,
      'D' => Strain.diamonds,
      'H' => Strain.hearts,
      'S' => Strain.spades,
      'N' || 'NT' => Strain.notrump,
      _ => throw const BenApiException('response', 'Unknown strain'),
    };
    return Bid(int.parse(match.group(1)!), strain);
  }

  static Card parseCard(Object? value) {
    if (value is! String) {
      throw const BenApiException('response', 'Card must be string');
    }
    final code = value.trim().toUpperCase();
    if (!RegExp(r'^[CDHS][2-9TJQKA]$').hasMatch(code)) {
      throw const BenApiException('response', 'Unknown BEN card code');
    }
    final suit = Suit.values.firstWhere((s) => s.pbn == code[0]);
    return Card(suit, Rank.fromSymbol(code[1]));
  }
}

