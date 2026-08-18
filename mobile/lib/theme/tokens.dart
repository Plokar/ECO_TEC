import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand tokens — the single source of truth for colour, type and spacing.
/// Mirrors the marketing site's `web/app/globals.css`. Never hardcode a hex
/// anywhere else in the app.
///
/// The app is printed on the same cream paper as the site: thick ink outlines,
/// hard offset shadows with no blur, fat rounded shapes, and nothing that sits
/// perfectly straight. Nothing here should read as a stock Material component.
abstract final class Tokens {
  // -- Paper --------------------------------------------------------------
  /// The ground everything sits on.
  static const page = Color(0xFFFFF7EA);

  /// A card cut out of white and stuck onto the page.
  static const paper = Color(0xFFFFFFFF);

  /// Second-tier fill: progress tracks, avatar backs, quiet rows.
  static const pageSubtle = Color(0xFFEAF7EC);

  /// Outline, drop shadow and body text — one colour doing all three is what
  /// makes the whole app look drawn by a single pen.
  static const ink = Color(0xFF14261C);
  static const inkDim = Color(0xFF4F6659);

  // -- Pops — meaning, never decoration. ----------------------------------
  static const questGreen = Color(0xFF00E676);
  static const questGreenDeep = Color(0xFF00A855);
  static const leaf = Color(0xFF7CC47F);
  static const streakFire = Color(0xFFFF6B35);
  static const duelViolet = Color(0xFF7C4DFF);
  static const impactCyan = Color(0xFF00C2F0);
  static const gold = Color(0xFFFFC53D);
  static const alertRed = Color(0xFFFF4D5E);
  static const sky = Color(0xFFBFE8FA);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [questGreenDeep, impactCyan, duelViolet],
  );

  // 4pt grid
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s48 = 48.0;

  // Radii — everything is rounder than a stock Material app.
  static const rCard = 24.0;
  static const rChip = 14.0;
  static const rPill = 999.0;
  static const rSheet = 30.0;

  /// Outline weight, matching the site's 3px sticker border.
  static const stroke = 3.0;

  /// The one shape the app is made of. `accent` swaps the shadow to a colour,
  /// which is how a card says "this one matters". The outline stays ink so the
  /// pen never changes mid-page.
  static BoxDecoration card({
    Color fill = paper,
    Color? accent,
    double radius = rCard,
    double offset = 5,
  }) => BoxDecoration(
    color: fill,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: ink, width: stroke),
    boxShadow: [
      BoxShadow(
        color: accent ?? ink,
        offset: Offset(offset, offset),
        blurRadius: 0,
      ),
    ],
  );

  /// A stuck-on label: solid colour, ink outline, small hard shadow.
  static BoxDecoration chip(Color fill, {double radius = rPill}) =>
      BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: ink, width: 2),
        boxShadow: const [
          BoxShadow(color: ink, offset: Offset(2, 2), blurRadius: 0),
        ],
      );

  /// Bin colour for a detected litter class. Always paired with a text label in
  /// the UI — colour alone must never carry meaning (colour-blind, sunlight).
  static Color bin(String className) => switch (className) {
    'plastic' => impactCyan,
    'glass' => questGreen,
    'metal' => gold,
    'paper' => duelViolet,
    'cigarette' => streakFire,
    'organic' => leaf,
    _ => inkDim,
  };

  /// Rarity colour, keyed by `Rarity.name` so this file stays free of the game
  /// model and the model stays free of hexes.
  static Color rarity(String name) => switch (name) {
    'uncommon' => impactCyan,
    'rare' => duelViolet,
    'epic' => streakFire,
    'legendary' => gold,
    _ => leaf,
  };

  /// Avatar background, keyed by `Avatar.tint`.
  static Color tint(String name) => switch (name) {
    'cyan' => impactCyan,
    'violet' => duelViolet,
    'gold' => gold,
    'fire' => streakFire,
    'leaf' => leaf,
    'sky' => sky,
    'red' => alertRed,
    _ => questGreen,
  };

  /// Text that survives on a filled chip. Bright fills take ink, dark ones take
  /// paper — checked rather than guessed, so a new accent can't ship unreadable.
  static Color onFill(Color fill) =>
      fill.computeLuminance() > 0.42 ? ink : paper;
}

/// Display face (Baloo 2) — headlines, XP counters, leaderboard ranks. Chunky
/// and rounded, the same face the wordmark is drawn in. Tabular figures so
/// animated counters don't jitter.
TextStyle display({
  double size = 40,
  FontWeight weight = FontWeight.w800,
  Color color = Tokens.ink,
  double tracking = -0.005,
}) => GoogleFonts.baloo2(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: size * tracking,
  height: 1.1,
  fontFeatures: const [FontFeature.tabularFigures()],
);

/// UI face (Nunito) — everything that is not a headline or a number. Rounded
/// terminals, so body text does not fight the display face.
TextStyle ui({
  double size = 16,
  FontWeight weight = FontWeight.w600,
  Color color = Tokens.ink,
  double tracking = 0,
  double height = 1.4,
}) => GoogleFonts.nunito(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: tracking,
  height: height,
);

/// Uppercase micro-label — section headers, chips, metric captions.
TextStyle label({Color color = Tokens.inkDim}) =>
    ui(size: 12, weight: FontWeight.w800, color: color, tracking: 0.6);

ThemeData ecoQuestTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Tokens.page,
    colorScheme: const ColorScheme.light(
      primary: Tokens.questGreenDeep,
      onPrimary: Tokens.paper,
      secondary: Tokens.impactCyan,
      surface: Tokens.paper,
      onSurface: Tokens.ink,
      error: Tokens.alertRed,
      outline: Tokens.ink,
    ),
    textTheme: GoogleFonts.nunitoTextTheme(
      base.textTheme,
    ).apply(bodyColor: Tokens.ink, displayColor: Tokens.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: Tokens.page,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Tokens.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: display(size: 24),
      // Cream ground needs dark status-bar icons, on both platforms.
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    cardTheme: CardThemeData(
      color: Tokens.paper,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.rCard),
        side: const BorderSide(color: Tokens.ink, width: Tokens.stroke),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Tokens.ink, thickness: 2),
    // Buttons are drawn, not shaded: fat outline, stadium shape, bold label.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Tokens.questGreen,
        foregroundColor: Tokens.ink,
        disabledBackgroundColor: Tokens.pageSubtle,
        disabledForegroundColor: Tokens.inkDim,
        // >= 48dp: one-handed, walking, gloves in winter.
        minimumSize: const Size.fromHeight(54),
        textStyle: display(size: 17, color: Tokens.ink),
        shape: const StadiumBorder(
          side: BorderSide(color: Tokens.ink, width: Tokens.stroke),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Tokens.ink,
        backgroundColor: Tokens.paper,
        minimumSize: const Size.fromHeight(54),
        textStyle: display(size: 17, color: Tokens.ink),
        shape: const StadiumBorder(
          side: BorderSide(color: Tokens.ink, width: Tokens.stroke),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Tokens.questGreenDeep,
        textStyle: ui(size: 15, weight: FontWeight.w800),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Tokens.paper,
      hintStyle: ui(color: Tokens.inkDim),
      labelStyle: ui(size: 14, color: Tokens.inkDim),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Tokens.s16,
        vertical: Tokens.s16,
      ),
      border: _field(Tokens.ink),
      enabledBorder: _field(Tokens.ink),
      focusedBorder: _field(Tokens.questGreenDeep),
      errorBorder: _field(Tokens.alertRed),
      focusedErrorBorder: _field(Tokens.alertRed),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Tokens.page,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Tokens.rSheet),
        ),
        side: BorderSide(color: Tokens.ink, width: Tokens.stroke),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Tokens.page,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.rCard),
        side: const BorderSide(color: Tokens.ink, width: Tokens.stroke),
      ),
      titleTextStyle: display(size: 22),
      contentTextStyle: ui(size: 15, color: Tokens.inkDim),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Tokens.ink,
      contentTextStyle: ui(color: Tokens.page),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tokens.rChip),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Tokens.questGreenDeep,
      linearTrackColor: Tokens.pageSubtle,
      circularTrackColor: Tokens.pageSubtle,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Tokens.ink,
      unselectedLabelColor: Tokens.inkDim,
      labelStyle: display(size: 15),
      unselectedLabelStyle: display(size: 15, color: Tokens.inkDim),
      indicatorColor: Tokens.questGreenDeep,
      dividerColor: Colors.transparent,
    ),
  );
}

OutlineInputBorder _field(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(Tokens.rChip),
  borderSide: BorderSide(color: color, width: Tokens.stroke),
);
