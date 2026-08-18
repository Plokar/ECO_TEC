import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand tokens — the single source of truth for colour, type and spacing.
/// Mirrors BRANDING.md §8. Never hardcode a hex anywhere else in the app.
abstract final class Tokens {
  // Core
  static const questGreen = Color(0xFF00E676);
  static const questGreenDeep = Color(0xFF00A855);
  static const deepForest = Color(0xFF0A1F16);
  static const forestSurface = Color(0xFF12291E);
  static const forestLine = Color(0xFF1E3D2C);
  static const bone = Color(0xFFF2F7F4);
  static const boneDim = Color(0xFF8FA69A);

  // Semantic accents — meaning, never decoration.
  static const streakFire = Color(0xFFFF6B35);
  static const duelViolet = Color(0xFF7C4DFF);
  static const impactCyan = Color(0xFF00D4FF);
  static const gold = Color(0xFFFFC53D);
  static const alertRed = Color(0xFFFF4D5E);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [questGreen, impactCyan],
  );

  // 4pt grid
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s48 = 48.0;

  // Radii
  static const rCard = 12.0;
  static const rPill = 999.0;
  static const rSheet = 20.0;

  /// Bin colour for a detected litter class. Always paired with a text label in
  /// the UI — colour alone must never carry meaning (colour-blind, sunlight).
  static Color bin(String className) => switch (className) {
    'plastic' => impactCyan,
    'glass' => questGreen,
    'metal' => gold,
    'paper' => duelViolet,
    'cigarette' => streakFire,
    'organic' => questGreenDeep,
    _ => boneDim,
  };
}

/// Display face (Space Grotesk) — headlines, XP counters, leaderboard ranks.
/// Tabular figures so animated counters don't jitter.
TextStyle display({
  double size = 40,
  FontWeight weight = FontWeight.w700,
  Color color = Tokens.bone,
  double tracking = -0.03,
}) => GoogleFonts.spaceGrotesk(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: size * tracking,
  height: 1.1,
  fontFeatures: const [FontFeature.tabularFigures()],
);

/// UI face (Inter) — everything that isn't a headline or a number.
TextStyle ui({
  double size = 16,
  FontWeight weight = FontWeight.w400,
  Color color = Tokens.bone,
  double tracking = 0,
  double height = 1.4,
}) => GoogleFonts.inter(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: tracking,
  height: height,
);

/// Uppercase micro-label — section headers, chips, metric captions.
TextStyle label({Color color = Tokens.boneDim}) =>
    ui(size: 13, weight: FontWeight.w600, color: color, tracking: 0.52);

ThemeData ecoQuestTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Tokens.deepForest,
    colorScheme: const ColorScheme.dark(
      primary: Tokens.questGreen,
      onPrimary: Tokens.deepForest,
      secondary: Tokens.impactCyan,
      surface: Tokens.forestSurface,
      onSurface: Tokens.bone,
      error: Tokens.alertRed,
      outline: Tokens.forestLine,
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: Tokens.bone,
      displayColor: Tokens.bone,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Tokens.deepForest,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: display(size: 22),
    ),
    // Elevation via surface colour, not shadow — shadows vanish on dark.
    cardTheme: const CardThemeData(
      color: Tokens.forestSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(color: Tokens.forestLine, thickness: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Tokens.questGreen,
        foregroundColor: Tokens.deepForest,
        // >= 48dp: one-handed, walking, gloves in winter.
        minimumSize: const Size.fromHeight(52),
        textStyle: ui(size: 16, weight: FontWeight.w600),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Tokens.bone,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: Tokens.forestLine),
        textStyle: ui(size: 16, weight: FontWeight.w600),
        shape: const StadiumBorder(),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Tokens.forestSurface,
      hintStyle: ui(color: Tokens.boneDim),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Tokens.s16,
        vertical: Tokens.s16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Tokens.rCard),
        borderSide: const BorderSide(color: Tokens.forestLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Tokens.rCard),
        borderSide: const BorderSide(color: Tokens.forestLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Tokens.rCard),
        borderSide: const BorderSide(color: Tokens.questGreen),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Tokens.forestSurface,
      indicatorColor: Tokens.questGreen.withValues(alpha: 0.16),
      surfaceTintColor: Colors.transparent,
      height: 68,
      labelTextStyle: WidgetStatePropertyAll(label(color: Tokens.boneDim)),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? Tokens.questGreen
              : Tokens.boneDim,
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Tokens.forestSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Tokens.rSheet),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Tokens.forestSurface,
      contentTextStyle: ui(),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.rCard),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Tokens.questGreen,
      linearTrackColor: Tokens.forestLine,
      circularTrackColor: Tokens.forestLine,
    ),
  );
}
