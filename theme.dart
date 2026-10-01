import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_state.dart';
import '../core/prayer_calc.dart';

/// Design notes
/// * The one bold element is the "sky" at the top of the Today screen: its
///   colours follow the current prayer window, from pre-dawn indigo through
///   midday blue, afternoon amber, sunset rose and night ink.
/// * Everything else stays quiet: cool stone backgrounds (not cream), an
///   Iznik-tile green for actions and a lapis blue for secondary accents.
/// * Figtree for the interface, Amiri for Arabic.
class AppColors {
  static const ink = Color(0xFF1B2733);
  static const stone = Color(0xFFF2F4F3);
  static const iznik = Color(0xFF1F6F5C);
  static const iznikNight = Color(0xFF63C7A9);
  static const lapis = Color(0xFF2B4C8C);
  static const lapisNight = Color(0xFF93AEE6);
  static const nightBg = Color(0xFF0E151D);
  static const nightSurface = Color(0xFF16202A);

  static const missed = Color(0xFFB3261E);
  static const late = Color(0xFFC77B12);
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.iznik,
      brightness: b,
    ).copyWith(
      primary: dark ? AppColors.iznikNight : AppColors.iznik,
      secondary: dark ? AppColors.lapisNight : AppColors.lapis,
      surface: dark ? AppColors.nightSurface : Colors.white,
      onSurface: dark ? const Color(0xFFE4EAEE) : AppColors.ink,
    );
    final bg = dark ? AppColors.nightBg : AppColors.stone;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
    );
    final text = GoogleFonts.figtreeTextTheme(base.textTheme).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.figtree(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? AppColors.nightSurface : Colors.white,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.onSurface.withValues(alpha: 0.08),
        space: 1,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}

/// Sky colours for the Today header, keyed to the time of day.
List<Color> skyColours(Prayer? current, {required bool beforeNoon}) {
  switch (current) {
    case Prayer.fajr:
      return const [Color(0xFF26335C), Color(0xFF8E7BB0), Color(0xFFE2B6B8)];
    case Prayer.dhuhr:
      return const [Color(0xFF2F78C4), Color(0xFF6FB0E3), Color(0xFFBFE2F6)];
    case Prayer.asr:
      return const [Color(0xFFB9692A), Color(0xFFDD9A4B), Color(0xFFF1D29B)];
    case Prayer.maghrib:
      return const [Color(0xFF5E2346), Color(0xFFB2465A), Color(0xFFEB8A5E)];
    case Prayer.isha:
      return const [Color(0xFF0B1426), Color(0xFF1B2A4D), Color(0xFF34497A)];
    case null:
      // Between sunrise and Dhuhr, or late night after Isha ends.
      return beforeNoon
          ? const [Color(0xFF4F8CC9), Color(0xFF9CC7EA), Color(0xFFF4D7A6)]
          : const [Color(0xFF0B1426), Color(0xFF1B2A4D), Color(0xFF34497A)];
  }
}

TextStyle arabicStyle(BuildContext context, {double size = 26, Color? color}) {
  return GoogleFonts.amiri(
    fontSize: size * AppState.instance.settings.arabicScale,
    height: 1.9,
    color: color ?? Theme.of(context).colorScheme.onSurface,
  );
}

Color statusColour(BuildContext context, PrayerStatus s) {
  final scheme = Theme.of(context).colorScheme;
  switch (s) {
    case PrayerStatus.onTime:
      return scheme.primary;
    case PrayerStatus.late:
      return AppColors.late;
    case PrayerStatus.missed:
      return AppColors.missed;
    case PrayerStatus.exempt:
      return scheme.secondary;
    case PrayerStatus.none:
      return scheme.onSurface.withValues(alpha: 0.25);
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
      ),
    );
  }
}

/// A plain rounded surface; used sparingly so screens don't become card grids.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: margin,
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
