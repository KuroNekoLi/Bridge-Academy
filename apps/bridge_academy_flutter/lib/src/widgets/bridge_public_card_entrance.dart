import 'package:flutter/material.dart';

/// Visual feedback for an already-public play. Never schedules game actions.
class BridgePublicCardEntrance extends StatefulWidget {
  const BridgePublicCardEntrance({
    super.key,
    required this.animate,
    required this.child,
    this.from = const Offset(0, 12),
  });

  final bool animate;
  final Widget child;
  final Offset from;

  @override
  State<BridgePublicCardEntrance> createState() =>
      _BridgePublicCardEntranceState();
}

class _BridgePublicCardEntranceState extends State<BridgePublicCardEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: widget.animate ? 0 : 1,
    );
    if (widget.animate) _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _controller.value = 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      final value = Curves.easeOut.transform(_controller.value);
      return Transform.translate(
        offset: widget.from * (1 - value),
        child: Opacity(
          opacity: value,
          // A screen reader sees the accepted play immediately.
          alwaysIncludeSemantics: true,
          child: child,
        ),
      );
    },
    child: widget.child,
  );
}
