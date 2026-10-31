import 'package:bridge_academy_flutter/src/bridge_session.dart';
import 'package:bridge_academy_flutter/src/widgets/bridge_practice_selection.dart';
import 'package:bridge_core/bridge_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('practice choices preserve the previous table defaults', () {
    final choices = BridgePracticeSelection();
    addTearDown(choices.dispose);
    expect(choices.seat, Seat.north);
    expect(choices.mode, OpponentMode.demo);
    expect(choices.board, BoardMode.training);
    expect(choices.level, 3);
    expect(choices.strain, Strain.notrump);
  });

  test('practice choices notify independently of game/session state', () {
    final choices = BridgePracticeSelection();
    addTearDown(choices.dispose);
    var notifications = 0;
    choices.addListener(() => notifications++);
    choices.setSeat(Seat.east);
    choices.setMode(OpponentMode.ben);
    choices.setBoard(BoardMode.fresh);
    choices.setLevel(5);
    choices.setStrain(Strain.spades);
    expect(notifications, 5);
    expect(choices.seat, Seat.east);
    expect(choices.mode, OpponentMode.ben);
    expect(choices.board, BoardMode.fresh);
    expect(choices.level, 5);
    expect(choices.strain, Strain.spades);
  });
}
