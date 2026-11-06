import 'package:flutter/material.dart';

/// Fixed brand palette. The demo is dark-first; every accent is also supplied
/// with a light-theme counterpart so charts and status chips stay legible.
abstract final class AppColors {
  // Dark theme: calm navy, no glows.
  static const navy = Color(0xFF0B1120);
  static const navyElevated = Color(0xFF0E1526);
  static const slate = Color(0xFF121A2C);
  static const slateAlt = Color(0xFF182238);
  static const slateBorder = Color(0xFF1F2A42);

  static const ink = Color(0xFFE7EBF3);
  static const inkSecondary = Color(0xFFA3AEC2);
  static const inkMuted = Color(0xFF7D879A);
  static const sky = Color(0xFF38BDF8);
  static const darkBlue = Color(0xFF6E9BFF);
  static const skySoft = Color(0x266E9BFF);
  static const amber = Color(0xFFFBBF24);
  static const coral = Color(0xFFF87171);
  static const violet = Color(0xFFC4B5FD);
  static const teal = Color(0xFF2DD4BF);
  static const mint = Color(0xFF4ADE80);

  // Light "executive" theme.
  static const paper = Color(0xFFF4F5F7);
  static const paperElevated = Color(0xFFFFFFFF);
  static const paperAlt = Color(0xFFEEF0F4);
  static const paperBorder = Color(0xFFE2E5EB);

  static const lightInk = Color(0xFF0F172A);
  static const lightInkSecondary = Color(0xFF475569);
  static const lightInkMuted = Color(0xFF64748B);
  static const blue = Color(0xFF2F6FEB);
  static const blueSoft = Color(0xFFDBE7FF);
  static const heroWash = Color(0xFFDCE7FF);
  static const lightAmber = Color(0xFFB45309);
  static const lightCoral = Color(0xFFB91C1C);
  static const lightViolet = Color(0xFF7C3AED);
  static const lightTeal = Color(0xFF0F766E);
  static const green = Color(0xFF15803D);

  // Brand lime: only the logo mark and the DEMO pill.
  static const lime = Color(0xFFB6F36A);
  static const limeInk = Color(0xFF3B6E12);
  static const limeSoft = Color(0xFFE8F5D9);

  static const chartPalette = [sky, teal, amber, violet, mint, coral];

  static const lightChartPalette = [
    blue,
    Color(0xFF14B8A6),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFF0EA5E9),
    Color(0xFFEF4444),
  ];

  /// Lawyer, Cloud, HR, Accountant, Global — catalogue order.
  static const lightUnitColors = [
    blue,
    Color(0xFF7C9CF5),
    Color(0xFF14B8A6),
    Color(0xFFF59E0B),
    Color(0xFFA78BFA),
  ];

  static const darkUnitColors = [sky, Color(0xFFA5B8FA), teal, amber, violet];

  static const lightAvatarColors = [
    Color(0xFF1D4ED8),
    Color(0xFF6D28D9),
    Color(0xFF0F766E),
    Color(0xFFB45309),
    Color(0xFFBE123C),
    Color(0xFF334155),
  ];

  static const darkAvatarColors = [
    Color(0xFF93B4FF),
    Color(0xFFC4B5FD),
    Color(0xFF5EEAD4),
    Color(0xFFFCD34D),
    Color(0xFFFDA4AF),
    Color(0xFFCBD5E1),
  ];
}

@immutable
class PulsePalette extends ThemeExtension<PulsePalette> {
  const PulsePalette({
    required this.background,
    required this.backgroundElevated,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
    required this.sky,
    required this.amber,
    required this.coral,
    required this.violet,
    required this.teal,
    required this.positive,
    required this.negative,
    required this.warning,
    required this.chart,
    required this.isDark,
    required this.heroWash,
    required this.cardShadow,
    required this.unitColors,
    required this.avatarColors,
    required this.brand,
    required this.brandTile,
    required this.brandSoft,
    required this.brandInk,
  });

  final Color background;
  final Color backgroundElevated;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accentInk;
  final Color accentSoft;
  final Color sky;
  final Color amber;
  final Color coral;
  final Color violet;
  final Color teal;
  final Color positive;
  final Color negative;
  final Color warning;
  final List<Color> chart;
  final bool isDark;

  /// Soft wash behind the top of Overview.
  final Color heroWash;

  /// Card shadow colour (transparent in dark mode).
  final Color cardShadow;

  /// One colour per business unit, in catalogue order.
  final List<Color> unitColors;

  /// Stable per-person avatar colours.
  final List<Color> avatarColors;

  /// Brand lime pulse line.
  final Color brand;

  /// Logo tile background.
  final Color brandTile;

  /// DEMO pill background.
  final Color brandSoft;

  /// DEMO pill text.
  final Color brandInk;

  static const dark = PulsePalette(
    background: AppColors.navy,
    backgroundElevated: AppColors.navyElevated,
    surface: AppColors.slate,
    surfaceAlt: AppColors.slateAlt,
    border: AppColors.slateBorder,
    textPrimary: AppColors.ink,
    textSecondary: AppColors.inkSecondary,
    textMuted: AppColors.inkMuted,
    accent: AppColors.darkBlue,
    accentInk: AppColors.navy,
    accentSoft: AppColors.skySoft,
    sky: AppColors.sky,
    amber: AppColors.amber,
    coral: AppColors.coral,
    violet: AppColors.violet,
    teal: AppColors.teal,
    positive: AppColors.mint,
    negative: AppColors.coral,
    warning: AppColors.amber,
    chart: AppColors.chartPalette,
    isDark: true,
    heroWash: Color(0xFF13254A),
    cardShadow: Color(0x00000000),
    unitColors: AppColors.darkUnitColors,
    avatarColors: AppColors.darkAvatarColors,
    brand: AppColors.lime,
    brandTile: Color(0xFF16233A),
    brandSoft: Color(0xFF1B2A16),
    brandInk: AppColors.lime,
  );

  static const light = PulsePalette(
    background: AppColors.paper,
    backgroundElevated: AppColors.paperElevated,
    surface: AppColors.paperElevated,
    surfaceAlt: AppColors.paperAlt,
    border: AppColors.paperBorder,
    textPrimary: AppColors.lightInk,
    textSecondary: AppColors.lightInkSecondary,
    textMuted: AppColors.lightInkMuted,
    accent: AppColors.blue,
    accentInk: Colors.white,
    accentSoft: AppColors.blueSoft,
    sky: Color(0xFF0EA5E9),
    amber: AppColors.lightAmber,
    coral: AppColors.lightCoral,
    violet: AppColors.lightViolet,
    teal: AppColors.lightTeal,
    positive: AppColors.green,
    negative: AppColors.lightCoral,
    warning: AppColors.lightAmber,
    chart: AppColors.lightChartPalette,
    isDark: false,
    heroWash: AppColors.heroWash,
    cardShadow: Color(0x140F172A),
    unitColors: AppColors.lightUnitColors,
    avatarColors: AppColors.lightAvatarColors,
    brand: AppColors.lime,
    brandTile: AppColors.lightInk,
    brandSoft: AppColors.limeSoft,
    brandInk: AppColors.limeInk,
  );

  @override
  PulsePalette copyWith({
    Color? background,
    Color? backgroundElevated,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? accentInk,
    Color? accentSoft,
    Color? sky,
    Color? amber,
    Color? coral,
    Color? violet,
    Color? teal,
    Color? positive,
    Color? negative,
    Color? warning,
    List<Color>? chart,
    bool? isDark,
    Color? heroWash,
    Color? cardShadow,
    List<Color>? unitColors,
    List<Color>? avatarColors,
    Color? brand,
    Color? brandTile,
    Color? brandSoft,
    Color? brandInk,
  }) {
    return PulsePalette(
      background: background ?? this.background,
      backgroundElevated: backgroundElevated ?? this.backgroundElevated,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      accentSoft: accentSoft ?? this.accentSoft,
      sky: sky ?? this.sky,
      amber: amber ?? this.amber,
      coral: coral ?? this.coral,
      violet: violet ?? this.violet,
      teal: teal ?? this.teal,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      warning: warning ?? this.warning,
      chart: chart ?? this.chart,
      isDark: isDark ?? this.isDark,
      heroWash: heroWash ?? this.heroWash,
      cardShadow: cardShadow ?? this.cardShadow,
      unitColors: unitColors ?? this.unitColors,
      avatarColors: avatarColors ?? this.avatarColors,
      brand: brand ?? this.brand,
      brandTile: brandTile ?? this.brandTile,
      brandSoft: brandSoft ?? this.brandSoft,
      brandInk: brandInk ?? this.brandInk,
    );
  }

  @override
  PulsePalette lerp(ThemeExtension<PulsePalette>? other, double t) {
    if (other is! PulsePalette) return this;
    Color blend(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return PulsePalette(
      background: blend(background, other.background),
      backgroundElevated: blend(backgroundElevated, other.backgroundElevated),
      surface: blend(surface, other.surface),
      surfaceAlt: blend(surfaceAlt, other.surfaceAlt),
      border: blend(border, other.border),
      textPrimary: blend(textPrimary, other.textPrimary),
      textSecondary: blend(textSecondary, other.textSecondary),
      textMuted: blend(textMuted, other.textMuted),
      accent: blend(accent, other.accent),
      accentInk: blend(accentInk, other.accentInk),
      accentSoft: blend(accentSoft, other.accentSoft),
      sky: blend(sky, other.sky),
      amber: blend(amber, other.amber),
      coral: blend(coral, other.coral),
      violet: blend(violet, other.violet),
      teal: blend(teal, other.teal),
      positive: blend(positive, other.positive),
      negative: blend(negative, other.negative),
      warning: blend(warning, other.warning),
      chart: [
        for (var i = 0; i < chart.length; i++)
          blend(chart[i], other.chart[i % other.chart.length]),
      ],
      isDark: t < 0.5 ? isDark : other.isDark,
      heroWash: blend(heroWash, other.heroWash),
      cardShadow: blend(cardShadow, other.cardShadow),
      unitColors: [
        for (var i = 0; i < unitColors.length; i++)
          blend(unitColors[i], other.unitColors[i % other.unitColors.length]),
      ],
      avatarColors: [
        for (var i = 0; i < avatarColors.length; i++)
          blend(
            avatarColors[i],
            other.avatarColors[i % other.avatarColors.length],
          ),
      ],
      brand: blend(brand, other.brand),
      brandTile: blend(brandTile, other.brandTile),
      brandSoft: blend(brandSoft, other.brandSoft),
      brandInk: blend(brandInk, other.brandInk),
    );
  }
}

extension PulsePaletteContext on BuildContext {
  PulsePalette get pulse =>
      Theme.of(this).extension<PulsePalette>() ?? PulsePalette.light;
}
