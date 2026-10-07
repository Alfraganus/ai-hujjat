import 'package:flutter/material.dart';

/// Brand colours that Material's ColorScheme has no slot for.
@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.sidebar,
    required this.sidebarText,
    required this.sidebarMuted,
    required this.sidebarSelected,
    required this.marker,
    required this.onMarker,
    required this.gradientStart,
    required this.gradientEnd,
    required this.success,
    required this.warning,
  });

  final Color sidebar;
  final Color sidebarText;
  final Color sidebarMuted;
  final Color sidebarSelected;

  /// Highlighter-pen colour: used wherever the app marks the relevant passage.
  final Color marker;
  final Color onMarker;
  final Color gradientStart;
  final Color gradientEnd;
  final Color success;
  final Color warning;

  LinearGradient get gradient =>
      LinearGradient(colors: [gradientStart, gradientEnd], begin: Alignment.topLeft, end: Alignment.bottomRight);

  static const light = BrandColors(
    sidebar: Color(0xFF12142B),
    sidebarText: Color(0xFFE6E8FA),
    sidebarMuted: Color(0xFF8A8EB8),
    sidebarSelected: Color(0x24FFFFFF),
    marker: Color(0xFFFFE066),
    onMarker: Color(0xFF3A2F00),
    gradientStart: Color(0xFF6366F1),
    gradientEnd: Color(0xFF9B5CF6),
    success: Color(0xFF16A34A),
    warning: Color(0xFFF59E0B),
  );

  static const dark = BrandColors(
    sidebar: Color(0xFF0A0B18),
    sidebarText: Color(0xFFE6E8FA),
    sidebarMuted: Color(0xFF7C80A6),
    sidebarSelected: Color(0x1FFFFFFF),
    marker: Color(0x66FFD43B),
    onMarker: Color(0xFFFFF3BF),
    gradientStart: Color(0xFF6366F1),
    gradientEnd: Color(0xFF9B5CF6),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
  );

  @override
  BrandColors copyWith() => this;

  @override
  BrandColors lerp(BrandColors? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension BrandTheme on BuildContext {
  BrandColors get brand => Theme.of(this).extension<BrandColors>()!;
}

/// Soft palette for category icons: (tint, strong).
const _categoryPalette = <(Color, Color)>[
  (Color(0xFFE0E7FF), Color(0xFF4F46E5)),
  (Color(0xFFFCE7F3), Color(0xFFDB2777)),
  (Color(0xFFD1FAE5), Color(0xFF059669)),
  (Color(0xFFFEF3C7), Color(0xFFD97706)),
  (Color(0xFFE0F2FE), Color(0xFF0284C7)),
  (Color(0xFFF3E8FF), Color(0xFF9333EA)),
  (Color(0xFFFFE4E6), Color(0xFFE11D48)),
  (Color(0xFFCCFBF1), Color(0xFF0D9488)),
];

/// Stable colour pair for a category id; tint is darkened in dark mode.
({Color tint, Color strong}) categoryColors(BuildContext context, int id) {
  final (tint, strong) = _categoryPalette[id.abs() % _categoryPalette.length];
  final dark = Theme.of(context).brightness == Brightness.dark;
  return (
    tint: dark ? strong.withValues(alpha: 0.18) : tint,
    strong: dark ? Color.lerp(strong, Colors.white, 0.35)! : strong,
  );
}

ThemeData buildTheme(Brightness brightness, {String? fontFamily}) {
  final dark = brightness == Brightness.dark;
  final brand = dark ? BrandColors.dark : BrandColors.light;

  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6366F1),
    brightness: brightness,
  ).copyWith(
    primary: dark ? const Color(0xFF8B8DFB) : const Color(0xFF4F46E5),
    onPrimary: dark ? const Color(0xFF14152E) : Colors.white,
    surface: dark ? const Color(0xFF171A30) : Colors.white,
    onSurface: dark ? const Color(0xFFE8EAF8) : const Color(0xFF1B1D36),
    onSurfaceVariant: dark ? const Color(0xFF9EA2C8) : const Color(0xFF5E6283),
    outline: dark ? const Color(0xFF363A5C) : const Color(0xFFD5D8EA),
    outlineVariant: dark ? const Color(0xFF272B47) : const Color(0xFFE6E8F4),
    surfaceContainerLowest: dark ? const Color(0xFF0E1020) : const Color(0xFFF4F5FB),
    surfaceContainerLow: dark ? const Color(0xFF14172C) : const Color(0xFFF8F9FD),
    surfaceContainerHighest: dark ? const Color(0xFF22264A) : const Color(0xFFECEEF8),
    primaryContainer: dark ? const Color(0xFF2A2C5C) : const Color(0xFFE6E8FF),
    onPrimaryContainer: dark ? const Color(0xFFDADBFF) : const Color(0xFF2A2780),
    error: dark ? const Color(0xFFFF8A8A) : const Color(0xFFD92D4A),
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: fontFamily,
    scaffoldBackgroundColor: scheme.surfaceContainerLowest,
    visualDensity: VisualDensity.standard,
    splashFactory: InkSparkle.splashFactory,
  );

  final text = base.textTheme;
  OutlineInputBorder border(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c, width: w));

  return base.copyWith(
    extensions: [brand],
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: text.bodyLarge?.copyWith(height: 1.55),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.5),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1, thickness: 1),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(scheme.outlineVariant),
      enabledBorder: border(scheme.outlineVariant),
      focusedBorder: border(scheme.primary, 1.6),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 1.6),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      width: 360,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: brand.sidebar, borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
    sliderTheme: base.sliderTheme.copyWith(trackHeight: 4),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: scheme.outline),
      ),
    ),
  );
}
