import 'package:bridge_ben_adapter/bridge_ben_adapter.dart';
import 'package:bridge_conventions/src/precision_research.dart';
import 'package:bridge_core/bridge_core.dart';

/// Typed transport: only a proposed auction call can cross this boundary.
/// Implementation must use localhost, POST and bounded request/response bodies.
abstract interface class PrecisionBidTransport {
  Future<Map<String, Object?>> bid(Map<String, Object> payload);
}

/// Fail-closed integration errors. Never include a hand, URL, or native trace.
final class PrecisionProviderException implements Exception {
  const PrecisionProviderException(this.code);
  final String code;

  @override
  String toString() => 'PrecisionProviderException($code)';
}

/// M3.3 auction-only proposal source. Not a whole-game BotPolicy:
/// BEN has no Precision opponent reader, and EPBot card play is NOT validated.
/// Caller/Bridge Core must still reject illegal calls before mutation.
final class BbaPrecisionBiddingProvider implements BotPolicy {
  const BbaPrecisionBiddingProvider({
    required this.transport,
    required this.precisionSideIsNS,
    required this.opponentModel,
  });

  final PrecisionBidTransport transport;
  final bool precisionSideIsNS;
  /// Opponent convention interpretation uses the matching BEN .bbsa card,
  /// NOT a fictitious Precision neural model.
  final String opponentModel;

  @override
  Future<GameAction> choose(PlayerView view) async {
    if (view.phase != Phase.auction ||
        !view.canAct ||
        view.actorToPlay != view.viewer ||
        view.viewer.isNS != precisionSideIsNS) {
      throw const PrecisionProviderException('not_precision_auction_turn');
    }
    if (!const {'21GF', 'SAYC'}.contains(opponentModel)) {
      throw const PrecisionProviderException('unsupported_opponent_convention');
    }
    final payload = <String, Object>{
      'version': 1,
      'profileId': PrecisionResearchCatalog.selectedProductProfileId,
      'revision': PrecisionResearchCatalog.selectedProductRevision,
      'cardSha256': PrecisionResearchCatalog.selectedCardSha256,
      'opponentModel': opponentModel,
      'seat': view.viewer.letter,
      'dealer': view.dealer.letter,
      'vul': BenProtocol.vulnerability(view.vulnerability),
      'ctx': BenProtocol.auction(view.auction),
      'hand': BenProtocol.originalHand(view, view.viewer),
    };
    final result = await transport.bid(Map.unmodifiable(payload));
    if (result.length != 5 ||
        result['provider'] != 'BBA_NATIVE_EPBOT' ||
        result['profileId'] != PrecisionResearchCatalog.selectedProductProfileId ||
        result['revision'] != PrecisionResearchCatalog.selectedProductRevision ||
        result['cardSha256'] != PrecisionResearchCatalog.selectedCardSha256 ||
        result['bid'] is! String) {
      throw const PrecisionProviderException('invalid_native_response');
    }
    try {
      // Parse syntax here; legal auction transitions still belong to Bridge Core.
      return CallAction(view.viewer, BenProtocol.parseCall(result['bid'] as String));
    } catch (_) {
      throw const PrecisionProviderException('invalid_native_proposal');
    }
  }
}
