import 'package:bridge_core/bridge_core.dart' as b;
import 'package:card_game/card_game.dart' as c;
import 'package:flutter/material.dart';

/// Upstream CardRow's stack limit only allows the last card when set to one.
/// This API-level adapter proposes one permitted bridge card from any index.
class BridgeProbeRow extends c.CardRow<b.Card, String> {
  BridgeProbeRow(
      {super.key,
      required super.value,
      required super.values,
      required this.allowed,
      super.onCardPressed})
      : super(spacing: 68);
  final bool Function(b.Card) allowed;

  @override
  List<b.Card>? getDraggableCardValues(int index, b.Card value) =>
      allowed(value) ? [value] : null;
}

/// Research only. The app does not depend on this package. No Deal or AI.
class BridgeCardGameProbe extends StatefulWidget {
  const BridgeCardGameProbe(
      {super.key,
      required this.view,
      required this.onPropose,
      this.paused = false});
  final b.PlayerView view;
  final void Function(b.Card card, int version) onPropose;
  final bool paused;
  @override
  State<BridgeCardGameProbe> createState() => _BridgeCardGameProbeState();
}

class _BridgeCardGameProbeState extends State<BridgeCardGameProbe> {
  int? _sent;
  @override
  void didUpdateWidget(BridgeCardGameProbe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.view.version != widget.view.version) _sent = null;
  }

  bool _allowed(b.Card card, String group) =>
      !widget.paused &&
      _sent != widget.view.version &&
      widget.view.canAct &&
      group == '${widget.view.turn?.letter}:${widget.view.version}' &&
      widget.view.legalCards.contains(card);

  void _propose(b.Card card, String group) {
    if (!_allowed(card, group)) return;
    setState(() => _sent = widget.view.version);
    widget.onPropose(card, widget.view.version);
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.view;
    final groups = {
      '${v.viewer.letter}:${v.version}': v.ownCards,
      if (v.dummyExposed &&
          v.dummyCards != null &&
          v.contract!.dummy != v.viewer)
        '${v.contract!.dummy.letter}:${v.version}': v.dummyCards!,
    };
    return SizedBox(
        height: 340,
        width: 680,
        child: c.CardGame<b.Card, String>(
            gameKey: 'authorized-projection',
            style: c.CardGameStyle(
                cardSize: const Size(64, 92),
                cardBuilder: (card, group, flipped, state) => TextButton(
                    key: ValueKey('probe_${card.code}'),
                    onPressed: _allowed(card, group)
                        ? () => _propose(card, group)
                        : null,
                    child: Text(card.code)),
                emptyGroupBuilder: (group, state) => ColoredBox(
                    key: ValueKey('probe_target_$group'),
                    color: state == c.CardState.highlighted
                        ? Colors.green
                        : Colors.grey)),
            children: [
              for (var i = 0; i < groups.length; i++)
                Positioned(
                    top: 8 + i * 108,
                    left: 8,
                    right: 8,
                    child: BridgeProbeRow(
                        value: groups.keys.elementAt(i),
                        values: groups.values.elementAt(i),
                        allowed: (card) =>
                            _allowed(card, groups.keys.elementAt(i)),
                        onCardPressed: (card) =>
                            _propose(card, groups.keys.elementAt(i)))),
              Positioned(
                  top: 228,
                  left: 8,
                  right: 8,
                  child: c.CardRow<b.Card, String>(
                      value: 'public',
                      values: [for (final p in v.currentTrick) p.card],
                      canCardBeGrabbed: (_, __) => false,
                      canMoveCardHere: (move) =>
                          move.cardValues.length == 1 &&
                          _allowed(move.cardValues.single, move.fromGroupValue),
                      onCardMovedHere: (move) {
                        if (move.cardValues.length == 1) {
                          _propose(move.cardValues.single, move.fromGroupValue);
                        }
                      })),
            ]));
  }
}
