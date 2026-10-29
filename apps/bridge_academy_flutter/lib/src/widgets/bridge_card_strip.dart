import 'package:flutter/material.dart';
import 'package:playing_cards/playing_cards.dart' show FlatCardFan;

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
    this.compactFan = false,
    this.selectedIndex,
  });
  final List<Widget> children;
  final AppCopy copy;
  final String id;
  final bool centerWhenFits;
  final bool useFan;
  final Color? hintColor;
  final bool compactFan;
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
      // Compact fans require caller-owned selection/confirmation. The default
      // keeps 48px exposed; large text always uses the accessible scroll layout.
      final fanMinimum = 68 + (cards.length - 1) * 48;
      if (widget.useFan &&
          cards.length > 1 &&
          constraints.hasBoundedWidth &&
          (widget.compactFan
              ? constraints.maxWidth >= 68
              : constraints.maxWidth >= fanMinimum) &&
          MediaQuery.textScalerOf(context).scale(14) <= 19) {
        final width = contentWidth
            .clamp(widget.compactFan ? 68 : fanMinimum, constraints.maxWidth)
            .toDouble();
        final middle = (cards.length - 1) / 2;
        return Align(
          alignment: widget.centerWhenFits
              ? Alignment.center
              : Alignment.centerLeft,
          child: SizedBox(
            key: Key('${widget.id}_card_strip'),
            width: width,
            height: widget.compactFan ? 148 : 100,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: widget.compactFan ? 32 : 0,
                  height: 100,
                  child: FlatCardFan(
                    children: [
                      for (var index = 0; index < cards.length; index++)
                        Transform.translate(
                          offset: Offset(
                            0,
                            widget.compactFan
                                ? 25 *
                                          (index - middle) *
                                          (index - middle) /
                                          (middle * middle) -
                                      12
                                : 6 *
                                          (index - middle) *
                                          (index - middle) /
                                          (middle * middle) -
                                      3,
                          ),
                          child: Transform.rotate(
                            angle:
                                (index - middle) /
                                middle *
                                (widget.compactFan ? .50 : .08),
                            child: widget.selectedIndex == index
                                ? const SizedBox(width: 68, height: 92)
                                : cards[index],
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.selectedIndex case final int selected
                    when selected >= 0 && selected < cards.length)
                  Positioned(
                    left: selected * (width - 68) / (cards.length - 1),
                    top: 0,
                    width: 68,
                    child: Transform.rotate(
                      angle:
                          (selected - middle) /
                          middle *
                          (widget.compactFan ? .38 : .08),
                      child: cards[selected],
                    ),
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
