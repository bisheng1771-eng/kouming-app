import 'package:flutter/material.dart';

/// KouMing Theme - Abyss Dark Style
class KouMingTheme {
  static const deep = Color(0xFF060D1A);
  static const mid = Color(0xFF0C1A30);
  static const surface = Color(0xFF132240);
  static const gold = Color(0xFFFFD700);
  static const warm = Color(0xFFFFAA33);
  static const water = Color(0xFF4A9EFF);
  static const lantern = Color(0xFFFF4444);
  static const spirit = Color(0xFF80DEEA);
  static const purple = Color(0xFFB388FF);
  static const text = Color(0xFFC8DDF0);
  static const dim = Color(0xFF4A6A8A);

  static const payGradient = [Color(0xFFFFD700), Color(0xFFFF8C00)];

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: deep,
        colorScheme: const ColorScheme.dark(
          primary: gold,
          secondary: purple,
          surface: surface,
          onPrimary: Color(0xFF1A1A2E),
          onSurface: text,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'MaShanZheng',
            fontSize: 28,
            color: gold,
            letterSpacing: 6,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: text, fontSize: 14),
          bodyMedium: TextStyle(color: text, fontSize: 12),
          titleLarge: TextStyle(
            fontFamily: 'MaShanZheng',
            fontSize: 24,
            color: gold,
          ),
          titleMedium: TextStyle(
            fontFamily: 'ZCOOLXiaoWei',
            fontSize: 16,
            color: gold,
          ),
          labelSmall: TextStyle(color: dim, fontSize: 10),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0x1AFFD700)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0x0AFFFFFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0x29FFD700)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: gold),
          ),
          hintStyle: const TextStyle(color: dim),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xF2060D1A),
          selectedItemColor: gold,
          unselectedItemColor: dim,
          type: BottomNavigationBarType.fixed,
        ),
      );
}

enum GlowTier {
  none(0, '', ''),
  faint(1, '\u2728', 'Faint'),
  bright(2, '\u{1F4AB}', 'Bright'),
  radiant(3, '\u{1F31F}', 'Radiant'),
  miracle(4, '\u{1F386}', 'Miracle');

  const GlowTier(this.level, this.emoji, this.label);
  final int level;
  final String emoji;
  final String label;

  static GlowTier fromLights(int lights) {
    if (lights >= 1000) return miracle;
    if (lights >= 200) return radiant;
    if (lights >= 50) return bright;
    if (lights >= 10) return faint;
    return none;
  }
}

enum WishCategory {
  study('study', 'Study', '📚'),
  health('health', 'Health', '💪'),
  love('love', 'Love', '💕'),
  money('money', 'Money', '💰'),
  other('default', 'Other', '✨');

  const WishCategory(this.key, this.label, this.emoji);
  final String key;
  final String label;
  final String emoji;

  static WishCategory fromText(String text) {
    if (RegExp(r'school|exam|offer|interview|grade|college|university')
        .hasMatch(text)) {
      return study;
    }
    if (RegExp(r'health|body|surgery|recover|sick|safe').hasMatch(text)) {
      return health;
    }
    if (RegExp(r'love|crush|date|together|relationship').hasMatch(text)) {
      return love;
    }
    if (RegExp(r'money|rich|salary|bonus|invest|pay|job').hasMatch(text)) {
      return money;
    }
    return other;
  }
}
