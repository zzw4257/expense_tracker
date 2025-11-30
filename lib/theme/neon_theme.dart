import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NeonTheme {
  static const Color bgDark = Color(0xFF0D0D1A);
  static const Color bgCard = Color(0xFF1A1A2E);
  static const Color neonPink = Color(0xFFFF00FF);
  static const Color neonCyan = Color(0xFF00FFFF);
  static const Color neonGreen = Color(0xFF00FF88);
  static const Color neonYellow = Color(0xFFFFD700);
  static const Color neonOrange = Color(0xFFFF6B35);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);

  // 使用更清晰的字体 - JetBrains Mono 或 Fira Code 风格
  static TextStyle titleStyle({double size = 20, Color? color}) => GoogleFonts.orbitron(
        fontSize: size,
        fontWeight: FontWeight.bold,
        color: color ?? textPrimary,
        letterSpacing: 2,
      );

  static TextStyle bodyStyle({double size = 14, Color? color, FontWeight? weight}) => GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight ?? FontWeight.normal,
        color: color ?? textPrimary,
      );

  static TextStyle labelStyle({double size = 12, Color? color}) => GoogleFonts.jetBrainsMono(
        fontSize: size,
        color: color ?? textSecondary,
      );

  static LinearGradient get neonGradient => const LinearGradient(
        colors: [neonPink, neonCyan],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: neonPink.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(color: neonPink.withOpacity(0.1), blurRadius: 20, spreadRadius: -5),
        ],
      );

  static BoxDecoration neonBorder({Color color = neonPink}) => BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 10),
        ],
      );

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bgDark,
        primaryColor: neonPink,
        colorScheme: const ColorScheme.dark(
          primary: neonPink,
          secondary: neonCyan,
          surface: bgCard,
        ),
        textTheme: TextTheme(
          headlineLarge: titleStyle(size: 28),
          headlineMedium: titleStyle(size: 22),
          headlineSmall: titleStyle(size: 18),
          titleLarge: bodyStyle(size: 18, weight: FontWeight.bold),
          titleMedium: bodyStyle(size: 16, weight: FontWeight.w600),
          bodyLarge: bodyStyle(size: 15),
          bodyMedium: bodyStyle(size: 14),
          bodySmall: labelStyle(size: 12),
          labelLarge: labelStyle(size: 14),
          labelMedium: labelStyle(size: 12),
          labelSmall: labelStyle(size: 11),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: bgDark,
          elevation: 0,
          titleTextStyle: titleStyle(size: 18),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: neonPink,
          foregroundColor: bgDark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: bgCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: neonPink.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: neonPink.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: neonCyan, width: 2),
          ),
          labelStyle: labelStyle(size: 14),
          hintStyle: labelStyle(size: 14, color: textSecondary.withOpacity(0.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: neonPink,
            foregroundColor: bgDark,
            textStyle: bodyStyle(size: 14, weight: FontWeight.bold),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
}
