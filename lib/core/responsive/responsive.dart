import 'package:flutter/material.dart';

enum AppLayoutSize { compact, medium, expanded, large }

abstract final class AppBreakpoints {
  static const double compact = 600;
  static const double medium = 1024;
  static const double expanded = 1440;

  static AppLayoutSize resolve(double width) {
    if (width < compact) return AppLayoutSize.compact;
    if (width < medium) return AppLayoutSize.medium;
    if (width < expanded) return AppLayoutSize.expanded;
    return AppLayoutSize.large;
  }
}

@immutable
class ResponsiveValue<T> {
  const ResponsiveValue({
    required this.compact,
    T? medium,
    T? expanded,
    T? large,
  }) : medium = medium ?? compact,
       expanded = expanded ?? medium ?? compact,
       large = large ?? expanded ?? medium ?? compact;

  final T compact;
  final T medium;
  final T expanded;
  final T large;

  T resolve(AppLayoutSize size) => switch (size) {
    AppLayoutSize.compact => compact,
    AppLayoutSize.medium => medium,
    AppLayoutSize.expanded => expanded,
    AppLayoutSize.large => large,
  };
}

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    AppLayoutSize size,
    BoxConstraints constraints,
  )
  builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => builder(
      context,
      AppBreakpoints.resolve(constraints.maxWidth),
      constraints,
    ),
  );
}

abstract final class AppContentWidths {
  static const double authentication = 480;
  static const double form = 760;
  static const double reading = 800;
  static const double dashboard = 1200;
  static const double workspace = 1440;
}

class AppContentConstraints extends StatelessWidget {
  const AppContentConstraints({
    super.key,
    required this.child,
    this.maxWidth = AppContentWidths.dashboard,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(padding: padding, child: child),
    ),
  );
}
