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
  });
  final List<Widget> children;
  final AppCopy copy;
  final String id;
  final bool centerWhenFits;
  final bool useFan;

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
      // Later cards cover earlier ones. Keep >=48 logical pixels of every
      // target exposed; a fully compressed 13-card phone fan would not do so.
      final fanMinimum = 68 + (cards.length - 1) * 48;
      if (widget.useFan &&
          cards.length > 1 &&
          constraints.hasBoundedWidth &&
          constraints.maxWidth >= fanMinimum &&
          MediaQuery.textScalerOf(context).scale(14) <= 19) {
        final width = contentWidth.clamp(fanMinimum, constraints.maxWidth).toDouble();
        final middle = (cards.length - 1) / 2;
        return Align(
          alignment: widget.centerWhenFits
              ? Alignment.center
              : Alignment.centerLeft,
          child: SizedBox(
            key: Key('${widget.id}_card_strip'),
            width: width,
            height: 100,
            child: FlatCardFan(children: [
              for (var index = 0; index < cards.length; index++)
                Transform.translate(
                  offset: Offset(0, 6 * (index - middle) * (index - middle) /
                      (middle * middle) - 3),
                  child: Transform.rotate(
                    angle: (index - middle) / middle * .06,
                    child: cards[index],
                  ),
                ),
            ]),
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
