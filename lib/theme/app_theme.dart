import 'package:flutter/material.dart';

/// Colors sampled from the RSU student portal (reg4.rsu.ac.th):
/// deep navy top bar / sidebar highlight, warm gold accent from the
/// university flame logo, and soft tinted cards for the timetable.
class RsuColors {
  static const Color navy = Color(0xFF17235E); // top bar / primary
  static const Color navyDark = Color(0xFF0E1740); // dark-mode surface
  static const Color navyLight = Color(0xFF2A3A82); // hover / secondary
  static const Color gold = Color(0xFFE3A23C); // flame accent
  static const Color teal = Color(0xFF1AA7A0); // selected sidebar item
  static const Color background = Color(0xFFF4F6FB);
  static const Color backgroundDark = Color(0xFF0B0F2A);
  static const Color surfaceDark = Color(0xFF141B3C);
  static const Color danger = Color(0xFFE05B5B);

  // Course-card tints, echoing the pastel day colors in the portal grid.
  static const List<Color> courseTints = [
    Color(0xFFFFF4C2), // yellow
    Color(0xFFFFD9E0), // pink
    Color(0xFFFFE3C2), // orange
    Color(0xFFD7F0D1), // green
    Color(0xFFD6E4FF), // blue
    Color(0xFFE6D9FF), // purple
  ];

  static const List<Color> courseTintsDark = [
    Color(0xFF6B5A17),
    Color(0xFF6B2B3A),
    Color(0xFF6B4A1D),
    Color(0xFF285A2A),
    Color(0xFF26407A),
    Color(0xFF4A2F7A),
  ];
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: RsuColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: RsuColors.navy,
        brightness: Brightness.light,
        primary: RsuColors.navy,
        secondary: RsuColors.gold,
      ),
      fontFamily: 'Roboto',
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: RsuColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RsuColors.navy,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDADFEC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDADFEC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RsuColors.navy, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: RsuColors.backgroundDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: RsuColors.navyLight,
        brightness: Brightness.dark,
        primary: RsuColors.gold,
        secondary: RsuColors.teal,
        surface: RsuColors.surfaceDark,
      ),
      fontFamily: 'Roboto',
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: RsuColors.navyDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RsuColors.gold,
          foregroundColor: RsuColors.navyDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RsuColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2B3463)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2B3463)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RsuColors.gold, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: RsuColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: RsuColors.surfaceDark),
    );
  }
}
