import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_copy.dart';

/// Layout only: callers supply widgets made from their authorized projection.
/// A narrow hand scrolls without overlapping or shrinking card touch targets.
class BridgeCardStrip extends StatefulWidget {
  const BridgeCardStrip({
    super.key,
    required this.children,
    required this.copy,
    required this.id,
    this.centerWhenFits = false,
    this.useFan = false,
    this.hintColor,
    this.selectedIndex,
  });
  final List<Widget> children;
  final AppCopy copy;
  final String id;
  final bool centerWhenFits;
  final bool useFan;
  final Color? hintColor;
  final int? selectedIndex;

  @override
  State<BridgeCardStrip> createState() => _BridgeCardStripState();
}

class _BridgeCardStripState extends State<BridgeCardStrip> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final contentWidth =
          widget.children.length * 68 +
          (widget.children.length - 1).clamp(0, widget.children.length) * 6;
      final overflow =
          constraints.hasBoundedWidth && contentWidth > constraints.maxWidth;
      final cards = [
        for (final child in widget.children) SizedBox(width: 68, child: child),
      ];
      // Keep tap/confirmation ownership in the caller. The fan itself is a
      // radial layout: each card's long axis points away from one shared hub.
      if (widget.useFan &&
          cards.length > 1 &&
          constraints.hasBoundedWidth &&
          constraints.maxWidth >= 240 &&
          MediaQuery.textScalerOf(context).scale(14) <= 19) {
        const cardWidth = 68.0;
        const cardHeight = 100.0;
        const maxAngle = 1.08; // 62 degrees either side, 124 total.
        const selectedLift = 14.0;
        final width = math.min(constraints.maxWidth, 440.0);
        final half = (cards.length - 1) / 2;
        final baseRadius =
            (((width - cardWidth * math.cos(maxAngle)) /
                        (2 * math.sin(maxAngle))) -
                    cardHeight -
                    selectedLift)
                .clamp(8.0, 56.0);
        final handHeight = baseRadius + cardHeight + selectedLift;
        final order = List<int>.generate(cards.length, (index) => index);
        final selectedIndex = widget.selectedIndex;
        if (selectedIndex != null &&
            selectedIndex >= 0 &&
            selectedIndex < cards.length) {
          order
            ..remove(selectedIndex)
            ..add(selectedIndex);
        }
        return Align(
          alignment: widget.centerWhenFits
              ? Alignment.center
              : Alignment.topLeft,
          child: SizedBox(
            key: Key('${widget.id}_card_strip'),
            width: width,
            height: handHeight,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (final index in order)
                  Builder(
                    builder: (context) {
                      final normalized = (index - half) / half;
                      final angle = normalized * maxAngle;
                      final relief = normalized.abs() * 5;
                      final hubX = width / 2;
                      final hubY = handHeight;
                      final bottomX = hubX + math.sin(angle) * baseRadius;
                      final bottomY = hubY - math.cos(angle) * baseRadius;
                      final selected = widget.selectedIndex == index;
                      final lift = selected ? selectedLift : 0.0;
                      final radialNudge = relief + lift;
                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutCubic,
                        left:
                            bottomX -
                            cardWidth / 2 +
                            math.sin(angle) * radialNudge,
                        top:
                            bottomY -
                            cardHeight -
                            (math.cos(angle) * radialNudge),
                        width: cardWidth,
                        height: cardHeight,
                        child: Transform.rotate(
                          angle: angle,
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            width: cardWidth,
                            height: cardHeight,
                            child: cards[index],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      }
      if (!overflow) {
        return Wrap(
          key: Key('${widget.id}_card_strip'),
          spacing: 6,
          alignment: widget.centerWhenFits
              ? WrapAlignment.center
              : WrapAlignment.start,
          children: cards,
        );
      }
      return Column(
        key: Key('${widget.id}_card_strip'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.copy.t('handScrollHint'),
            key: Key('${widget.id}_scroll_hint'),
            style: TextStyle(color: widget.hintColor),
          ),
          const SizedBox(height: 4),
          Scrollbar(
            controller: _scroll,
            thumbVisibility: true,
            interactive: true,
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.useFan ? 0 : 14),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  key: Key('${widget.id}_scroll'),
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var index = 0; index < cards.length; index++) ...[
                        if (index > 0) const SizedBox(width: 6),
                        cards[index],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
