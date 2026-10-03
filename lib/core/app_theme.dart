import 'package:flutter/material.dart';

/// AtomIQ visual identity adapted from the bright ChemLab/abc_app system.
/// A calm cyan brand, airy blue-white surfaces, soft cards and warm accents keep
/// chemistry content friendly without reducing equation legibility.
abstract final class AppColors {
  // Text
  static const ink = Color(0xFF162033);
  static const muted = Color(0xFF8993A4);

  // Brand palette from abc_app.
  static const blue = Color(0xFF4DB7E8);
  static const cyan = Color(0xFF2196C9);
  static const violet = Color(0xFF777FBC);

  // Signal colors
  static const coral = Color(0xFFE98EAA);
  static const mint = Color(0xFF63B96A);

  // Surfaces
  static const background = Color(0xFFF1FAFE);
  static const surface = Colors.white;
  static const line = Color(0xFFE4EAF0);
  static const soft = Color(0xFFEAF7FC);

  static const accent = Color(0xFFFFB21C);
  static const accentDeep = Color(0xFFB57600);

  static const gridDot = Color(0x00000000);

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF58C0EE), Color(0xFF46ACE0)],
  );
  static const aquaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4DB7E8), Color(0xFF2196C9)],
  );
  static const warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9A76), Color(0xFFFFB21C)],
  );
}

abstract final class AppFonts {
  static const sans = 'Montserrat';
  static const mono = 'JBMono';
}

/// Reusable text treatment for anything that is being *counted*: equations,
/// formulas, coefficients, atom tallies. Tabular figures keep numbers aligned.
TextStyle formulaStyle({
  double fontSize = 14,
  Color color = AppColors.ink,
  FontWeight weight = FontWeight.w500,
  double? height,
}) => TextStyle(
  fontFamily: AppFonts.mono,
  fontSize: fontSize,
  color: color,
  fontWeight: weight,
  height: height,
  fontFeatures: const [FontFeature.tabularFigures()],
);

abstract final class AppTheme {
  static ThemeData light({String fontFamily = AppFonts.sans}) {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        primary: AppColors.blue,
        surface: AppColors.background,
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.4,
          color: AppColors.ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 27,
          fontWeight: FontWeight.w700,
          letterSpacing: -.9,
          color: AppColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -.5,
          color: AppColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        bodyLarge: TextStyle(fontSize: 15, height: 1.6, color: AppColors.ink),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.55,
          color: AppColors.muted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Color(0x14000000),
        foregroundColor: AppColors.ink,
        centerTitle: true,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.4),
        ),
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue,
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
