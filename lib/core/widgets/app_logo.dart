import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../config/theme.dart';

/// Official PrepMate AI logo widget (Screen 13).
///
/// Supports plain SVG/PNG rendering, elevated brand mark container with
/// glow, and optional sparkle AI badge.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 40,
    this.elevated = false,
    this.showBadge = false,
    this.semanticLabel = 'PrepMate AI Logo',
  });

  /// The width and height of the logo square.
  final double size;

  /// Whether to render inside the elevated rounded card with subtle ambient glow.
  final bool elevated;

  /// Whether to render the floating sparkle ping badge at top-right.
  final bool showBadge;

  /// Accessible label for screen readers.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    Widget logoImage = SvgPicture.asset(
      'assets/logos/prepmate_ai_logo.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticsLabel: semanticLabel,
      placeholderBuilder: (_) => Image.asset(
        'assets/logos/prepmate_ai_logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );

    if (!elevated) {
      return Semantics(label: semanticLabel, image: true, child: logoImage);
    }

    final cardSize = size * 1.35;
    final borderRadius = BorderRadius.circular(size * 0.32);

    return Semantics(
      label: semanticLabel,
      image: true,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Soft ambient glow
          Container(
            width: cardSize,
            height: cardSize,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.18),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          // Elevated white surface container
          Container(
            width: cardSize,
            height: cardSize,
            padding: EdgeInsets.all(size * 0.16),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: borderRadius,
              border: Border.all(color: colors.border.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: colors.textPrimary.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: logoImage,
          ),
          // Floating sparkle badge
          if (showBadge)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.textPrimary.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: colors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
