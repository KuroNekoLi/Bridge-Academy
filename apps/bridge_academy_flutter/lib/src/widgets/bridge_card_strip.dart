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
  });
  final List<Widget> children;
  final AppCopy copy;
  final String id;
  final bool centerWhenFits;

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
              padding: const EdgeInsets.only(bottom: 14),
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
