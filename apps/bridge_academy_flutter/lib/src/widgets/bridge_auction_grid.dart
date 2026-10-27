import 'dart:math' as math;
import 'package:bridge_core/bridge_core.dart' hide Card;
import 'package:flutter/material.dart';
import '../app_copy.dart';
import 'bridge_bidding_box.dart';

// Nickel AuctionGrid.tsx interaction adaptation; exact source in RESEARCH_REPORTS.
// Receives only public auction entries; never Deal or AI hidden reasoning.
class BridgeAuctionGrid extends StatefulWidget {
  const BridgeAuctionGrid({
    super.key,
    required this.view,
    required this.copy,
    this.height = 220,
  });
  final PlayerView view;
  final AppCopy copy;
  final double height;
  @override
  State<BridgeAuctionGrid> createState() => _BridgeAuctionGridState();
}

class _BridgeAuctionGridState extends State<BridgeAuctionGrid> {
  final _scroll = ScrollController();
  @override
  void initState() {
    super.initState();
    _follow();
  }

  @override
  void didUpdateWidget(BridgeAuctionGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.view.auction.length != widget.view.auction.length ||
        oldWidget.view.dealer != widget.view.dealer) {
      _follow();
    }
  }

  void _follow() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
  });
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _inspect(AuctionEntry entry) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${widget.copy.seat(entry.seat.letter)} · ${callDisplay(widget.copy, entry.call)}',
        ),
        content: Text(widget.copy.t('callMeaningUnknown')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.copy.t('close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view, copy = widget.copy;
    final pending = view.phase == Phase.auction && view.turn != null;
    final count = view.dealer.index + view.auction.length;
    final rows = math.max(1, ((count + (pending ? 1 : 0)) / 4).ceil());
    final textSize = MediaQuery.textScalerOf(context).scale(14);
    final cellHeight = math.max(48.0, textSize * 1.5 + 18);
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        key: const Key('auction_grid'),
        height: math.min(widget.height, constraints.maxHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: math.max(
                  constraints.maxWidth,
                  math.max(192, textSize * 14),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (final seat in Seat.values)
                          Expanded(
                            child: Tooltip(
                              message: seat == view.viewer
                                  ? copy.t('yourSeat')
                                  : copy.seat(seat.letter),
                              child: Container(
                                key: Key('auction_header_${seat.letter}'),
                                height: cellHeight,
                                alignment: Alignment.center,
                                color: view.turn == seat && pending
                                    ? const Color(0xFFF4D374)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                child: Text(
                                  '${seat.letter}${seat == view.viewer ? ' ★' : ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scroll,
                        key: const Key('auction_rows'),
                        itemCount: rows,
                        itemBuilder: (context, row) => Row(
                          children: [
                            for (var col = 0; col < 4; col++)
                              Expanded(
                                child: SizedBox(
                                  height: cellHeight,
                                  child: Builder(
                                    builder: (context) {
                                      final index =
                                          row * 4 + col - view.dealer.index;
                                      if (index >= 0 &&
                                          index < view.auction.length) {
                                        final entry = view.auction[index];
                                        return ColoredBox(
                                          color:
                                              index == view.auction.length - 1
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primaryContainer
                                              : Colors.transparent,
                                          child: TextButton(
                                            key: Key('auction_call_$index'),
                                            onPressed: () => _inspect(entry),
                                            child: Semantics(
                                              label:
                                                  '${copy.seat(entry.seat.letter)} ${callLabel(copy, entry.call)}',
                                              excludeSemantics: true,
                                              child: Text(
                                                entry.call is Pass
                                                    ? 'PASS'
                                                    : callDisplay(
                                                        copy,
                                                        entry.call,
                                                      ),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      if (pending &&
                                          index == view.auction.length) {
                                        return Center(
                                          child: Semantics(
                                            label:
                                                '${copy.seat(view.turn!.letter)} ${copy.t('awaitingCall')}',
                                            child: Text(
                                              '?',
                                              key: Key(
                                                'auction_pending_${view.turn!.letter}',
                                              ),
                                              style: TextStyle(
                                                fontSize: 24,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (pending)
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          copy.formatTurn(view.turn!.letter),
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
