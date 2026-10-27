import 'dart:math' as math;
import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:flutter/material.dart';
import '../app_copy.dart';

// Interaction adaptation: Nickel Bridge BidBox.tsx at 92a81b5e81cb7aac2eabc147e82f18e0040b512e.
// Flutter implementation; source/provenance and owner authorization in RESEARCH_REPORTS.
class BridgeBiddingBox extends StatefulWidget {
  const BridgeBiddingBox({
    super.key,
    required this.copy,
    required this.view,
    required this.canSubmit,
    required this.onSubmitCall,
  });
  final AppCopy copy;
  final PlayerView view;
  final bool canSubmit;
  final ValueChanged<Call> onSubmitCall;
  @override
  State<BridgeBiddingBox> createState() => _BridgeBiddingBoxState();
}

class _BridgeBiddingBoxState extends State<BridgeBiddingBox> {
  String? _selected;
  int? _expandedAt;
  int? _sentVersion;
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(BridgeBiddingBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    final a = oldWidget.view, b = widget.view;
    if (a.version != b.version ||
        a.viewer != b.viewer ||
        a.turn != b.turn ||
        a.phase != b.phase ||
        !widget.canSubmit ||
        !b.canAct) {
      _selected = null;
    }
    if (a.version != b.version ||
        a.viewer != b.viewer ||
        (!oldWidget.canSubmit && widget.canSubmit)) {
      _sentVersion = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view, copy = widget.copy;
    // Legal choices depend only on public auction data. Permissions remain locked
    // separately; rendering the next seat's public ladder reveals no private hand.
    final calls = BridgeGame.legalCalls(
      phase: view.phase,
      turn: view.turn,
      actor: view.turn ?? view.viewer,
      auction: view.auction,
    );
    final legal = calls.map((c) => c.code).toSet();
    final bids = calls.whereType<Bid>().toList();
    final first = bids.isEmpty ? 7 : bids.first.level;
    final last = _expandedAt == first ? 7 : math.min(7, first + 3);
    final allowed =
        widget.canSubmit && view.canAct && view.phase == Phase.auction;
    final locked = !allowed || _sentVersion == view.version;
    final selected = calls.where((c) => c.code == _selected).firstOrNull;
    final scale = MediaQuery.textScalerOf(context).scale(18);
    final cellWidth = math.max(48.0, scale * 2.5 + 12);
    final rowHeight = math.max(48.0, scale + 20);
    Widget choice(Call call, String key) => OutlinedButton(
      key: Key(key),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.all(4),
        backgroundColor: _selected == call.code
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        side: BorderSide(
          color: _selected == call.code
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor,
        ),
      ),
      onPressed: locked || !legal.contains(call.code)
          ? null
          : () => setState(() => _selected = call.code),
      child: Semantics(
        selected: _selected == call.code,
        label: callLabel(copy, call),
        excludeSemantics: true,
        child: Text(
          callDisplay(copy, call),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: locked || !legal.contains(call.code)
                ? null
                : call is Bid &&
                      (call.strain == Strain.hearts ||
                          call.strain == Strain.diamonds)
                ? const Color(0xFFB22030)
                : null,
          ),
        ),
      ),
    );
    return Card(
      key: const Key('auction_controls'),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: math.min(
                  MediaQuery.sizeOf(context).height < 900 ? 156 : 208,
                  (last - first + 1) * (rowHeight + 4),
                ),
                child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: math.max(box.maxWidth, cellWidth * 5 + 16),
                      child: ListView(
                        controller: _scroll,
                        children: [
                          for (var level = first; level <= last; level++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  for (final strain in Strain.values)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        child: SizedBox(
                                          height: rowHeight,
                                          child: choice(
                                            Bid(level, strain),
                                            'bid_$level${strain.code}',
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (last < 7)
                TextButton(
                  key: const Key('bid_more_levels'),
                  onPressed: locked
                      ? null
                      : () => setState(() => _expandedAt = first),
                  child: Text(copy.t('moreBidLevels')),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  for (final entry in <(Call, String)>[
                    (const Pass(), 'pass'),
                    (const DoubleCall(), 'double'),
                    (const RedoubleCall(), 'redouble'),
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: choice(entry.$1, entry.$2),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              FilledButton(
                key: const Key('make_bid'),
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: locked || selected == null
                    ? null
                    : () {
                        setState(() {
                          _sentVersion = view.version;
                          _selected = null;
                        });
                        widget.onSubmitCall(selected);
                      },
                child: Text(
                  _sentVersion == view.version
                      ? copy.t('submittingCall')
                      : !allowed
                      ? copy.t(view.canAct ? 'biddingPaused' : 'waitingBot')
                      : selected == null
                      ? copy.t('selectCall')
                      : '${copy.t('confirmCall')} ${callDisplay(copy, selected)}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String callDisplay(AppCopy copy, Call call) => switch (call) {
  Bid(:final level, :final strain) =>
    '$level${switch (strain) {
      Strain.clubs => '♣',
      Strain.diamonds => '♦',
      Strain.hearts => '♥',
      Strain.spades => '♠',
      Strain.notrump => 'NT',
    }}',
  Pass() => copy.t('pass'),
  DoubleCall() => 'X',
  RedoubleCall() => 'XX',
};
String callLabel(AppCopy copy, Call call) => call is Bid
    ? '${call.level} ${copy.t(bridgeStrainKey(call.strain))}'
    : call is Pass
    ? copy.t('pass')
    : copy.t(call is DoubleCall ? 'double' : 'redouble');
String bridgeStrainKey(Strain strain) => switch (strain) {
  Strain.clubs => 'strainC',
  Strain.diamonds => 'strainD',
  Strain.hearts => 'strainH',
  Strain.spades => 'strainS',
  Strain.notrump => 'strainNT',
};
