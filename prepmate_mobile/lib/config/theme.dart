import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'page_transitions.dart';

/// Semantic colors used by PrepMate surfaces and feature states.
///
/// Feature widgets should prefer [Theme.of] component themes and text styles.
/// Use this extension when a semantic color is not represented by Material's
/// [ColorScheme] (for example success or warning).
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.screenBackground,
    required this.cardBackground,
    required this.elevatedSurface,
    required this.primary,
    required this.primarySoft,
    required this.secondary,
    required this.secondarySoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.iconSoftBackground,
    required this.mutedBackground,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.error,
    required this.errorSoft,
    required this.info,
    required this.infoSoft,
    required this.disabled,
    required this.onStatus,
  });

  final Color screenBackground;
  final Color cardBackground;
  final Color elevatedSurface;
  final Color primary;
  final Color primarySoft;
  final Color secondary;
  final Color secondarySoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color iconSoftBackground;
  final Color mutedBackground;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color error;
  final Color errorSoft;
  final Color info;
  final Color infoSoft;
  final Color disabled;
  final Color onStatus;

  static const light = AppColors(
    screenBackground: Color(0xFFF7F8FB),
    cardBackground: Color(0xFFFFFFFF),
    elevatedSurface: Color(0xFFFFFFFF),
    primary: Color(0xFF2457D6),
    primarySoft: Color(0xFFE9EFFF),
    secondary: Color(0xFF087E78),
    secondarySoft: Color(0xFFE1F4F1),
    textPrimary: Color(0xFF172033),
    textSecondary: Color(0xFF667085),
    border: Color(0xFFDDE2EA),
    iconSoftBackground: Color(0xFFEEF2F7),
    mutedBackground: Color(0xFFF1F4F8),
    success: Color(0xFF168653),
    successSoft: Color(0xFFE7F6EE),
    warning: Color(0xFFA15C00),
    warningSoft: Color(0xFFFFF2D8),
    error: Color(0xFFB42318),
    errorSoft: Color(0xFFFDECEA),
    info: Color(0xFF1769AA),
    infoSoft: Color(0xFFE7F2FB),
    disabled: Color(0xFF98A2B3),
    onStatus: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    screenBackground: Color(0xFF111722),
    cardBackground: Color(0xFF1A2230),
    elevatedSurface: Color(0xFF232D3D),
    primary: Color(0xFF9BB8FF),
    primarySoft: Color(0xFF24375F),
    secondary: Color(0xFF67D4CA),
    secondarySoft: Color(0xFF173E3D),
    textPrimary: Color(0xFFF5F7FA),
    textSecondary: Color(0xFFB1BAC8),
    border: Color(0xFF354154),
    iconSoftBackground: Color(0xFF273244),
    mutedBackground: Color(0xFF202A39),
    success: Color(0xFF5DD39A),
    successSoft: Color(0xFF173D2D),
    warning: Color(0xFFF4B860),
    warningSoft: Color(0xFF49351B),
    error: Color(0xFFFF8A80),
    errorSoft: Color(0xFF4B2426),
    info: Color(0xFF82C8FF),
    infoSoft: Color(0xFF183850),
    disabled: Color(0xFF717B8B),
    onStatus: Color(0xFF0E1623),
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  @override
  AppColors copyWith({
    Color? screenBackground,
    Color? cardBackground,
    Color? elevatedSurface,
    Color? primary,
    Color? primarySoft,
    Color? secondary,
    Color? secondarySoft,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? iconSoftBackground,
    Color? mutedBackground,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? error,
    Color? errorSoft,
    Color? info,
    Color? infoSoft,
    Color? disabled,
    Color? onStatus,
  }) {
    return AppColors(
      screenBackground: screenBackground ?? this.screenBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      secondary: secondary ?? this.secondary,
      secondarySoft: secondarySoft ?? this.secondarySoft,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      iconSoftBackground: iconSoftBackground ?? this.iconSoftBackground,
      mutedBackground: mutedBackground ?? this.mutedBackground,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      error: error ?? this.error,
      errorSoft: errorSoft ?? this.errorSoft,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
      disabled: disabled ?? this.disabled,
      onStatus: onStatus ?? this.onStatus,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    Color blend(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      screenBackground: blend(screenBackground, other.screenBackground),
      cardBackground: blend(cardBackground, other.cardBackground),
      elevatedSurface: blend(elevatedSurface, other.elevatedSurface),
      primary: blend(primary, other.primary),
      primarySoft: blend(primarySoft, other.primarySoft),
      secondary: blend(secondary, other.secondary),
      secondarySoft: blend(secondarySoft, other.secondarySoft),
      textPrimary: blend(textPrimary, other.textPrimary),
      textSecondary: blend(textSecondary, other.textSecondary),
      border: blend(border, other.border),
      iconSoftBackground: blend(iconSoftBackground, other.iconSoftBackground),
      mutedBackground: blend(mutedBackground, other.mutedBackground),
      success: blend(success, other.success),
      successSoft: blend(successSoft, other.successSoft),
      warning: blend(warning, other.warning),
      warningSoft: blend(warningSoft, other.warningSoft),
      error: blend(error, other.error),
      errorSoft: blend(errorSoft, other.errorSoft),
      info: blend(info, other.info),
      infoSoft: blend(infoSoft, other.infoSoft),
      disabled: blend(disabled, other.disabled),
      onStatus: blend(onStatus, other.onStatus),
    );
  }
}

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double screen = 20;
  static const double section = 24;
  static const double card = 16;
}

abstract final class AppRadius {
  static const double xxs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;
}

abstract final class AppSizes {
  static const double inputHeight = 52;
  static const double buttonHeight = 52;
  static const double tapTarget = 48;
  static const double icon = 24;
  static const double iconSmall = 20;
}

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration emphasized = Duration(milliseconds: 320);
}

class AppTheme {
  AppTheme._();

  static const transitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: PrepMatePageTransitions(),
      TargetPlatform.iOS: PrepMatePageTransitions(),
    },
  );

  // Backward-compatible aliases while feature screens migrate to semantic
  // colors. New code should use AppColors.of(context).
  static final Color lightBackgrounds = AppColors.light.screenBackground;
  static final Color lightBackground = AppColors.light.screenBackground;
  static final Color lightSurface = AppColors.light.mutedBackground;
  static final Color primary = AppColors.light.primary;
  static final Color textPrimary = AppColors.light.textPrimary;
  static final Color headingPrimary = AppColors.light.primary;
  static final Color textSecondary = AppColors.light.textSecondary;
  static final Color darkBackground = AppColors.dark.screenBackground;
  static final Color darkSurface = AppColors.dark.cardBackground;
  static final Color darkTextPrimary = AppColors.dark.textPrimary;
  static final Color darkTextSecondary = AppColors.dark.textSecondary;

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF3568E8), Color(0xFF2457D6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<BoxShadow> lightShadow = [
    BoxShadow(color: Color(0x120F172A), offset: Offset(0, 4), blurRadius: 14),
  ];

  static const List<BoxShadow> darkShadow = [
    BoxShadow(color: Color(0x52000000), offset: Offset(0, 5), blurRadius: 16),
  ];

  static final ThemeData lightTheme = _build(
    brightness: Brightness.light,
    colors: AppColors.light,
  );

  static final ThemeData darkTheme = _build(
    brightness: Brightness.dark,
    colors: AppColors.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppColors colors,
  }) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: isDark ? const Color(0xFF102A63) : Colors.white,
      primaryContainer: colors.primarySoft,
      onPrimaryContainer: colors.textPrimary,
      secondary: colors.secondary,
      onSecondary: isDark ? const Color(0xFF073B38) : Colors.white,
      secondaryContainer: colors.secondarySoft,
      onSecondaryContainer: colors.textPrimary,
      error: colors.error,
      onError: colors.onStatus,
      errorContainer: colors.errorSoft,
      onErrorContainer: colors.textPrimary,
      surface: colors.cardBackground,
      onSurface: colors.textPrimary,
    );

    final baseTextTheme = ThemeData(
      brightness: brightness,
      fontFamily: 'Poppins',
      useMaterial3: true,
    ).textTheme;
    final textTheme = baseTextTheme
        .copyWith(
          displaySmall: const TextStyle(
            fontSize: 32,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          headlineMedium: const TextStyle(
            fontSize: 28,
            height: 1.25,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.35,
          ),
          headlineSmall: const TextStyle(
            fontSize: 24,
            height: 1.3,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: const TextStyle(
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: const TextStyle(fontSize: 16, height: 1.5),
          bodyMedium: const TextStyle(fontSize: 14, height: 1.5),
          bodySmall: const TextStyle(fontSize: 12, height: 1.45),
          labelLarge: const TextStyle(
            fontSize: 15,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
          labelMedium: const TextStyle(
            fontSize: 13,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
          labelSmall: const TextStyle(
            fontSize: 11,
            height: 1.35,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        )
        .apply(
          fontFamily: 'Poppins',
          bodyColor: colors.textPrimary,
          displayColor: colors.textPrimary,
        );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    final buttonPadding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[colors],
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: colors.screenBackground,
      canvasColor: colors.screenBackground,
      dividerColor: colors.border,
      disabledColor: colors.disabled,
      pageTransitionsTheme: transitions,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.screenBackground,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(
          color: colors.textPrimary,
          size: AppSizes.icon,
        ),
        actionsIconTheme: IconThemeData(
          color: colors.textPrimary,
          size: AppSizes.icon,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: colors.screenBackground,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: colors.screenBackground,
              ),
      ),
      cardTheme: CardThemeData(
        color: colors.cardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.cardBackground,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: colors.primary,
        ),
        helperStyle: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        errorStyle: textTheme.bodySmall?.copyWith(color: colors.error),
        prefixIconColor: colors.textSecondary,
        suffixIconColor: colors.textSecondary,
        border: inputBorder(colors.border),
        enabledBorder: inputBorder(colors.border),
        focusedBorder: inputBorder(colors.primary, 1.5),
        errorBorder: inputBorder(colors.error),
        focusedErrorBorder: inputBorder(colors.error, 1.5),
        disabledBorder: inputBorder(colors.border.withValues(alpha: 0.65)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(AppSizes.tapTarget, AppSizes.buttonHeight),
          ),
          padding: WidgetStatePropertyAll(buttonPadding),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(AppSizes.tapTarget, AppSizes.buttonHeight),
          ),
          padding: WidgetStatePropertyAll(buttonPadding),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(colors.primary),
          foregroundColor: WidgetStatePropertyAll(
            isDark ? const Color(0xFF102A63) : Colors.white,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(AppSizes.tapTarget, AppSizes.buttonHeight),
          ),
          padding: WidgetStatePropertyAll(buttonPadding),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          side: WidgetStatePropertyAll(BorderSide(color: colors.border)),
          foregroundColor: WidgetStatePropertyAll(colors.textPrimary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(AppSizes.tapTarget, AppSizes.tapTarget),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          shape: WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size.square(AppSizes.tapTarget),
          ),
          iconSize: const WidgetStatePropertyAll(AppSizes.icon),
          foregroundColor: WidgetStatePropertyAll(colors.textPrimary),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 1,
        focusElevation: 1,
        highlightElevation: 2,
        backgroundColor: colors.primary,
        foregroundColor: isDark ? const Color(0xFF102A63) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: colors.cardBackground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.primarySoft,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: AppSizes.icon,
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.textSecondary,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.cardBackground,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textSecondary,
        selectedLabelStyle: textTheme.labelSmall,
        unselectedLabelStyle: textTheme.labelSmall,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colors.primary,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
        dividerColor: colors.border,
        indicatorColor: colors.primary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.mutedBackground,
        selectedColor: colors.primarySoft,
        disabledColor: colors.mutedBackground.withValues(alpha: 0.65),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        labelStyle: textTheme.labelMedium!,
        secondaryLabelStyle: textTheme.labelMedium!.copyWith(
          color: colors.primary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.elevatedSurface,
        modalBackgroundColor: colors.elevatedSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.screenBackground,
        ),
        actionTextColor: isDark ? colors.primary : colors.primarySoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        insetPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      dividerTheme: DividerThemeData(color: colors.border, thickness: 1),
      listTileTheme: ListTileThemeData(
        iconColor: colors.textSecondary,
        textColor: colors.textPrimary,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        minTileHeight: AppSizes.tapTarget,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.primarySoft,
        circularTrackColor: colors.primarySoft,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : colors.disabled,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primarySoft
              : colors.mutedBackground,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxs),
        ),
      ),
    );
  }
}
