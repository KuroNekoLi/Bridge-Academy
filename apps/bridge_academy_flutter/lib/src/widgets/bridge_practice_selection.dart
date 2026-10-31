import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:flutter/foundation.dart';
import '../bridge_session.dart';

/// Persists launch selections even while the focus table temporarily hides the hub.
/// This controller owns UI preferences only, never GameState.
class BridgePracticeSelection extends ChangeNotifier {
  Seat seat = Seat.north;
  OpponentMode mode = OpponentMode.demo;
  BoardMode board = BoardMode.training;
  int level = 3;
  Strain strain = Strain.notrump;
  bool _restored = false;

  void syncRestored(BridgeSession session) {
    if (_restored || !session.restoredFromStorage) return;
    _restored = true;
    seat = session.humanSeat;
    mode = session.mode;
    board = session.boardMode == BoardMode.bidding || session.boardMode == BoardMode.daily
        ? BoardMode.fresh : session.boardMode;
    notifyListeners();
  }

  void setSeat(Seat value) { seat = value; notifyListeners(); }
  void setMode(OpponentMode value) { mode = value; notifyListeners(); }
  void setBoard(BoardMode value) { board = value; notifyListeners(); }
  void setLevel(int value) { level = value; notifyListeners(); }
  void setStrain(Strain value) { strain = value; notifyListeners(); }
}

