import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A small, accessible pulse animation for pending work.
class AppLoading extends StatefulWidget {
  const AppLoading({super.key, this.color, this.strokeWidth = 3});
  final Color? color;
  final double strokeWidth;

  @override
  State<AppLoading> createState() => _AppLoadingState();
}

class _AppLoadingState extends State<AppLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading',
    liveRegion: true,
    child: SizedBox(
      width: 32,
      height: 24,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              final pulse =
                  (math.sin((_controller.value * 2 * math.pi) - index) + 1) / 2;
              return Transform.translate(
                offset: Offset(0, -3 * pulse),
                child: Opacity(
                  opacity: 0.35 + pulse * 0.65,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          widget.color ?? Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    ),
  );
}

/// Animated placeholders preserve the page's layout while data loads.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({super.key, this.rows = 3});
  final int rows;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading content',
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLoading(),
          for (var i = 0; i < rows; i++)
            Container(
              height: 64,
              margin: const EdgeInsets.only(top: 14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
        ],
      ),
    ),
  );
}
