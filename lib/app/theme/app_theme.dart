import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_motion.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData dark() => _build(PulsePalette.dark, Brightness.dark);

  static ThemeData light() => _build(PulsePalette.light, Brightness.light);

  static ThemeData _build(PulsePalette palette, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: palette.accent,
      onPrimary: palette.accentInk,
      primaryContainer: palette.accentSoft,
      onPrimaryContainer: palette.textPrimary,
      secondary: palette.sky,
      onSecondary: brightness == Brightness.dark
          ? AppColors.navy
          : Colors.white,
      secondaryContainer: palette.surfaceAlt,
      onSecondaryContainer: palette.textPrimary,
      tertiary: palette.violet,
      onTertiary: brightness == Brightness.dark ? AppColors.navy : Colors.white,
      error: palette.negative,
      onError: Colors.white,
      surface: palette.surface,
      onSurface: palette.textPrimary,
      surfaceContainerHighest: palette.surfaceAlt,
      onSurfaceVariant: palette.textSecondary,
      outline: palette.border,
      outlineVariant: palette.border.withValues(alpha: 0.7),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: palette.textPrimary,
      onInverseSurface: palette.background,
      inversePrimary: palette.accent,
    );

    final textTheme = AppTypography.textTheme(palette);
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PulsePageTransitionsBuilder(),
          TargetPlatform.iOS: PulsePageTransitionsBuilder(),
          TargetPlatform.macOS: PulsePageTransitionsBuilder(),
          TargetPlatform.linux: PulsePageTransitionsBuilder(),
          TargetPlatform.windows: PulsePageTransitionsBuilder(),
        },
      ),
      extensions: [palette],
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: palette.textPrimary,
        systemOverlayStyle: palette.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: palette.textSecondary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: palette.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: palette.textSecondary),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: palette.accentSoft,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? palette.accent : palette.textMuted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? palette.textPrimary : palette.textMuted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 11,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.surface,
        selectedColor: palette.accentSoft,
        disabledColor: palette.surfaceAlt,
        side: BorderSide(color: palette.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        labelStyle: textTheme.labelLarge?.copyWith(fontSize: 12.5),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: palette.textPrimary,
          fontSize: 12.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        showCheckmark: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.accentInk,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.textPrimary,
          minimumSize: const Size(44, 44),
          side: BorderSide(color: palette.border),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.textSecondary,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.textSecondary,
          minimumSize: const Size(40, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
        prefixIconColor: palette.textMuted,
        suffixIconColor: palette.textMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.accent, width: 1.4),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.backgroundElevated,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: palette.backgroundElevated,
        showDragHandle: true,
        dragHandleColor: palette.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        constraints: const BoxConstraints(maxWidth: 720),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.backgroundElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: palette.border),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceAlt,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: palette.textPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: palette.border),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: palette.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.border),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: palette.textPrimary),
        waitDuration: const Duration(milliseconds: 350),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.textSecondary,
        textColor: palette.textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.accent,
        linearTrackColor: palette.surfaceAlt,
        circularTrackColor: palette.surfaceAlt,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return palette.accentSoft;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? palette.textPrimary
                : palette.textMuted;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: palette.border)),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelMedium?.copyWith(fontSize: 12),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: _PulsePageTransitionsBuilder(),
          TargetPlatform.android: _PulsePageTransitionsBuilder(),
          TargetPlatform.macOS: _PulsePageTransitionsBuilder(),
        },
      ),
    );
  }
}

class _PulsePageTransitionsBuilder extends PageTransitionsBuilder {
  const _PulsePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.emphasized,
      reverseCurve: AppMotion.exit,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
