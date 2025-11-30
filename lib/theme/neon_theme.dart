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
        textTheme: GoogleFonts.pressStart2pTextTheme(
          const TextTheme(
            headlineLarge: TextStyle(fontSize: 24, color: textPrimary),
            headlineMedium: TextStyle(fontSize: 18, color: textPrimary),
            bodyLarge: TextStyle(fontSize: 12, color: textPrimary),
            bodyMedium: TextStyle(fontSize: 10, color: textSecondary),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: bgDark,
          elevation: 0,
          titleTextStyle: GoogleFonts.pressStart2p(fontSize: 14, color: textPrimary),
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
          labelStyle: GoogleFonts.pressStart2p(fontSize: 10, color: textSecondary),
          hintStyle: GoogleFonts.pressStart2p(fontSize: 10, color: textSecondary.withOpacity(0.5)),
        ),
      );
}
