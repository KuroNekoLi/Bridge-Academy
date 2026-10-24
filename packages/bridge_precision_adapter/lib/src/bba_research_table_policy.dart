import 'package:bridge_ben_adapter/bridge_ben_adapter.dart';
import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:bridge_core/bridge_core.dart';

import 'bba_precision_loopback_transport.dart';
import 'precision_bidding_provider.dart';

/// M3.4 technical E2E policy, deliberately NOT competitive robot strength.
///
/// Both partnerships' auctions are interpreted by native EPBot BBA cards,
/// so BEN neural is never asked to misread artificial Precision opponents.
/// Cardplay consumes bounded native BBA auction inferences to rank ONLY
/// Bridge Core-legal cards. This heuristic is not a learned BEN cardplayer,
/// complete single-dummy inference, or competitive-strength validation.
final class BbaResearchTablePolicy implements BotPolicy {
  const BbaResearchTablePolicy(this.transport, this.systems);
  final BbaTableBidTransport transport;
  final GameSystems systems;

  static bool isSupported(GameSystems pair) {
    final ns = pair.northSouth.profileId;
    final ew = pair.eastWest.profileId;
    const precision = 'BA-PRECISION-MECKWELL';
    const others = {'BA-21GF', 'BA-SAYC'};
    return (ns == precision && others.contains(ew)) ||
        (ew == precision && others.contains(ns));
  }

  @override
  Future<GameAction> choose(PlayerView view) async {
    if (!isSupported(systems) ||
        !view.canAct ||
        view.actorToPlay != view.viewer) {
      throw const PrecisionProviderException('unavailable_table_policy');
    }
    if (view.phase == Phase.play) {
      return _chooseInformedCard(view);
    }
    if (view.phase != Phase.auction) {
      throw const PrecisionProviderException('unsupported_game_phase');
    }
    final request = _request(view);
    final response = await transport.tableBid(request);
    if (response.length != 5 ||
        response['provider'] != 'BBA_NATIVE_EPBOT' ||
        response['profileId'] != PrecisionResearchCatalog.selectedProductProfileId ||
        response['revision'] != PrecisionResearchCatalog.selectedProductRevision ||
        response['cardSha256'] != PrecisionResearchCatalog.selectedCardSha256 ||
        response['bid'] is! String) {
      throw const PrecisionProviderException('invalid_native_response');
    }
    try {
      return CallAction(
          view.viewer, BenProtocol.parseCall(response['bid'] as String));
    } catch (_) {
      throw const PrecisionProviderException('invalid_native_proposal');
    }
  }
  Map<String, Object> _request(PlayerView view) =>
      Map<String, Object>.unmodifiable({
        'version': 1,
        'profileId': PrecisionResearchCatalog.selectedProductProfileId,
        'revision': PrecisionResearchCatalog.selectedProductRevision,
        'cardSha256': PrecisionResearchCatalog.selectedCardSha256,
        'northSouth': systems.northSouth.profileId,
        'eastWest': systems.eastWest.profileId,
        'seat': view.viewer.letter,
        'dealer': view.dealer.letter,
        'vul': BenProtocol.vulnerability(view.vulnerability),
        'ctx': BenProtocol.auction(view.auction),
        'hand': BenProtocol.originalHand(view, view.viewer),
      });

  Future<GameAction> _chooseInformedCard(PlayerView view) async {
    if (view.turn == null || view.contract == null ||
        view.legalCards.isEmpty) {
      throw const PrecisionProviderException('invalid_play_state');
    }
    final payload = _request(view); // own original hand + public auction ONLY
    final response = await transport.auctionInference(payload);
    if (response.length != 6 ||
        response['provider'] != 'BBA_NATIVE_EPBOT' ||
        response['profileId'] != PrecisionResearchCatalog.selectedProductProfileId ||
        response['revision'] != PrecisionResearchCatalog.selectedProductRevision ||
        response['cardSha256'] != PrecisionResearchCatalog.selectedCardSha256 ||
        response['source'] != 'BBA_AUCTION_ESTIMATE' ||
        response['suitEstimates'] is! Map) {
      throw const PrecisionProviderException('invalid_auction_estimates');
    }

    // The native model may output estimates, never actual hidden holdings.
    // Validate the *entire* four-seat distribution before using any value.
    const seats = ['N', 'E', 'S', 'W'];
    const suits = ['C', 'D', 'H', 'S'];
    final raw = response['suitEstimates'] as Map;
    if (raw.length != 4 || !seats.every(raw.containsKey)) {
      throw const PrecisionProviderException('invalid_auction_estimates');
    }
    final estimates = <String, Map<String, int>>{};
    for (final seat in seats) {
      final fields = raw[seat];
      if (fields is! Map || fields.length != 4 ||
          !suits.every(fields.containsKey)) {
        throw const PrecisionProviderException('invalid_auction_estimates');
      }
      final numbers = <String, int>{};
      for (final suit in suits) {
        final n = fields[suit];
        if (n is! int || n < 0 || n > 13) {
          throw const PrecisionProviderException('invalid_auction_estimates');
        }
        numbers[suit] = n;
      }
      estimates[seat] = numbers;
    }

    // Deliberately modest, explainable suit-support heuristic:
    // prefer suits that the BBA convention interpreter predicts for partner,
    // and avoid the two defenders' opponent suits when defending.
    // The 13-card owner/dummy remains the ONLY source of real card identity.
    final seat = view.turn!.letter;
    final at = seats.indexOf(seat);
    final partner = seats[(at + 2) % 4];
    final opponents = [
      seats[(at + 1) % 4], seats[(at + 3) % 4],
    ];
    final legal = view.legalCards.toList();
    final eligible = view.turn == view.viewer
        ? view.ownCards : (view.dummyCards ?? const <Card>[]);
    if (legal.any((card) => !eligible.contains(card))) {
      throw const PrecisionProviderException('illegal_play_projection');
    }
    int score(Card card) {
      final suit = card.suit.pbn;
      final ownLength = eligible.where((c) => c.suit == card.suit).length;
      final allied = estimates[partner]![suit]!;
      final enemies = opponents
          .map((seat) => estimates[seat]![suit]!).reduce((a, b) => a + b);
      return ownLength * 2 + allied * 3 - enemies;
    }
    // Choose low rank on a support-score tie; do not burn honors blindly.
    const ranks = '23456789TJQKA';
    legal.sort((a, b) {
      final bySuit = score(b).compareTo(score(a));
      if (bySuit != 0) return bySuit;
      final rank = ranks.indexOf(a.rank.symbol)
          .compareTo(ranks.indexOf(b.rank.symbol));
      if (rank != 0) return rank;
      return a.code.compareTo(b.code);
    });
    return CardAction(view.viewer, view.turn!, legal.first);
  }

}
