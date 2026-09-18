import 'package:flutter/material.dart';

class PrepMatePageTransitions extends PageTransitionsBuilder {
  const PrepMatePageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: curved.drive(
          Tween(begin: const Offset(0.04, 0), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }
}

class TabEntrance extends StatefulWidget {
  const TabEntrance({super.key, required this.active, required this.child});
  final bool active;
  final Widget child;
  @override
  State<TabEntrance> createState() => _TabEntranceState();
}

class _TabEntranceState extends State<TabEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: 1,
  );
  @override
  void didUpdateWidget(TabEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active &&
        !oldWidget.active &&
        !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _controller,
    child: SlideTransition(
      position: _controller.drive(
        Tween(begin: const Offset(0, 0.015), end: Offset.zero),
      ),
      child: TickerMode(enabled: widget.active, child: widget.child),
    ),
  );
}
