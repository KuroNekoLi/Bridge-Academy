import 'game.dart';
import 'model.dart';
import 'player_view.dart';

/// A bot receives ONLY the seat-filtered PlayerView. It never receives Deal,
/// GameState, full PBN or an omniscient double-dummy solver input.
abstract interface class BotPolicy {
  Future<GameAction> choose(PlayerView view);
}

/// Deterministic legality/smoke-test opponent — NOT BEN and NOT a strong AI.
/// Starts with 1NT if first to bid; otherwise passes; during play chooses the
/// lexicographically first legal card. Requires the Bridge Core to validate.
class DeterministicTrainingBot implements BotPolicy {
  const DeterministicTrainingBot();

  @override
  Future<GameAction> choose(PlayerView view) async {
    if (!view.canAct) throw const RuleViolation('Bot asked to play out of turn');
    if (view.phase == Phase.auction) {
      return CallAction(
        view.viewer,
        view.auction.isEmpty
            ? const Bid(1, Strain.notrump)
            : const Pass(),
      );
    }
    if (view.phase != Phase.play || view.turn == null || view.legalCards.isEmpty) {
      throw const RuleViolation('No legal card for bot');
    }
    return CardAction(view.viewer, view.turn!, view.legalCards.first);
  }
}

/// M2 local single-player authority: one human seat and three bot-controlled
/// seats. No public unrestricted getter for the privileged GameState.
class SinglePlayerCoordinator {
  SinglePlayerCoordinator({
    required Deal deal,
    required Seat dealer,
    required Vulnerability vulnerability,
    required this.humanSeat,
    required BotPolicy bot,
  }) : _state = GameState.start(deal, dealer, vulnerability),
       _bot = bot;

  final Seat humanSeat;
  final BotPolicy _bot;
  GameState _state;
  bool _botRunning = false;

  int get version => _state.version;
  bool get finished => _state.isFinished;

  /// Only the authorized human seat is exposed, not an arbitrary Seat.
  PlayerView get humanView => PlayerView.forSeat(_state, humanSeat);

  /// Optimistic concurrency rejects duplicate and stale human interactions.
  void submitHuman(GameAction action, {required int expectedVersion}) {
    if (_botRunning) throw const RuleViolation('Bot is resolving a turn');
    if (expectedVersion != _state.version) {
      throw const RuleViolation('Stale action version');
    }
    if (_state.actorToPlay != humanSeat || action.actor != humanSeat) {
      throw const RuleViolation('Action is not controlled by human seat');
    }
    _state = BridgeGame.apply(_state, action);
  }

  /// Drive bot seats until human input is needed or a terminal state is reached.
  /// A misbehaving bot action is rejected by Bridge Core without mutation.
  Future<int> runBots({int maxActions = 60}) async {
    if (_botRunning) throw const RuleViolation('Bot runner is already active');
    if (maxActions <= 0) throw ArgumentError.value(maxActions, 'maxActions');
    _botRunning = true;
    var applied = 0;
    try {
      while (!_state.isFinished && _state.actorToPlay != humanSeat) {
        if (applied >= maxActions) {
          throw const RuleViolation('Bot action budget exceeded');
        }
        final priorVersion = _state.version;
        final actingSeat = _state.actorToPlay!;
        final view = PlayerView.forSeat(_state, actingSeat);
        final proposal = await _bot.choose(view);
        if (_state.version != priorVersion) {
          throw const RuleViolation('Game changed during bot evaluation');
        }
        if (proposal.actor != actingSeat) {
          throw const RuleViolation('Bot proposed another seat action');
        }
        _state = BridgeGame.apply(_state, proposal);
        applied++;
      }
      return applied;
    } finally {
      _botRunning = false;
    }
  }
}

