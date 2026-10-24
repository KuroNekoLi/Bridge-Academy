import 'package:bridge_ben_adapter/bridge_ben_adapter.dart';
import 'package:bridge_conventions/bridge_conventions.dart';
import 'package:bridge_core/bridge_core.dart';

import 'bba_precision_loopback_transport.dart';
import 'precision_bidding_provider.dart';

/// M3.4 technical E2E policy, deliberately NOT competitive robot strength.
///
/// Both partnerships' auctions are interpreted by native EPBot BBA cards,
/// so BEN neural is never asked to misread artificial Precision opponents.
/// Cardplay is explicitly deterministic research-only: this cannot be
/// advertised as full BEN/BBA playing strength. M3.5 gates remain no-go.
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
      // This is a diagnostic legal-card source, NOT a Precision-aware model.
      return const DeterministicTrainingBot().choose(view);
    }
    if (view.phase != Phase.auction) {
      throw const PrecisionProviderException('unsupported_game_phase');
    }
    final request = Map<String, Object>.unmodifiable({
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
}
