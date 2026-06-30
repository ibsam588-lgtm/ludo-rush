import 'package:flutter/material.dart';

// ── Ludo Star palette ──────────────────────────────────────────────────────────

const Color bgDeep = Color(0xFF1A0028);
const Color bgMagenta = Color(0xFF6B0F6E);
const Color bgPurple = Color(0xFF3D0B5E);
const Color goldColor = Color(0xFFFFD426);
const Color goldDark = Color(0xFFC8940A);
const Color amberColor = Color(0xFFFF9A00);
const Color greenBtn = Color(0xFF4CAF50);
const Color greenDark = Color(0xFF388E3C);
const Color blueBtn = Color(0xFF2196F3);
const Color salmonCard = Color(0xFFFF8A65);
const Color creamCell = Color(0xFFFFF8E1);
const Color boardRed = Color(0xFFE53935);
const Color boardBlue = Color(0xFF1E88E5);
const Color boardGreen = Color(0xFF43A047);
const Color boardYellow = Color(0xFFFFB300);
const Color boardPurple = Color(0xFF8E35D9);
const Color boardCyan = Color(0xFF00B8D9);
const Color boardOrange = Color(0xFFFF6D00);
const Color woodBrown = Color(0xFF6D3B1E);
const Color woodLight = Color(0xFF8B4E2A);

class AppColors {
  // Board piece / quadrant colors
  static const Color red = boardRed;
  static const Color blue = boardBlue;
  static const Color yellow = boardYellow;
  static const Color green = boardGreen;
  static const Color purple = boardPurple;
  static const Color cyan = boardCyan;
  static const Color orange = boardOrange;

  // Soft tints for home lanes
  static const Color redSoft = Color(0x44E53935);
  static const Color blueSoft = Color(0x441E88E5);
  static const Color yellowSoft = Color(0x44FFB300);
  static const Color greenSoft = Color(0x4443A047);

  // UI accents
  static const Color gold = goldColor;
  static const Color amber = amberColor;
  static const Color navy = Color(0xFF1A237E);
  static const Color navyDeep = Color(0xFF0D1B5E);
  static const Color ivory = creamCell;
  static const Color goldDarkC = goldDark;

  // Dark theme backgrounds — all Ludo Star maroon/purple tones
  static const Color darkBgPage = bgDeep;
  static const Color darkBgSurface = bgPurple;
  static const Color darkBgCard = Color(0xFF2E0845);
  static const Color darkBgCardHi = bgMagenta;
  static const Color darkBgHeader = Color(0xFF260040);
  static const Color darkBgMetric = Color(0x33FFD426);
  static const Color darkBgSel = Color(0xFF7B1FA2);
  static const Color darkBgDanger = Color(0xFF2A1218);
  static const Color darkBgInput = Color(0xFF35104F);

  static const Color darkTxtPrimary = Color(0xFFFFFFFF);
  static const Color darkTxtSecondary = Color(0xEEFFF0FF);
  static const Color darkTxtMuted = Color(0xCCFFECA8);
  static const Color darkTxtDim = Color(0x77FFFFFF);

  static const Color darkStrokeCard = Color(0x77FFD426);
  static const Color darkStrokeCardAlt = Color(0x55FFD426);
  static const Color darkStrokeCardGlow = Color(0xBBFFD426);
  static const Color darkStrokeDanger = Color(0x55E53935);

  // Light theme (kept for backwards compat, but app always uses dark Ludo Star style)
  static const Color lightBgPage = Color(0xFFFFF0FB);
  static const Color lightBgSurface = Color(0xFFFFE15A);
  static const Color lightBgCard = Color(0xFFFFFFFF);
  static const Color lightBgHeader = Color(0xFFFF4FA3);
  static const Color lightBgMetric = Color(0xFFFFF0A6);
  static const Color lightBgSel = Color(0xFF40D8FF);

  static const Color lightTxtPrimary = Color(0xFF25102F);
  static const Color lightTxtSecondary = Color(0xFF5A245C);
  static const Color lightTxtMuted = Color(0xFF7A3E7F);

  static const Color lightStrokeCard = Color(0xFF8D4CFF);
  static const Color lightStrokeCardAlt = Color(0xFFD7C8FF);
  static const Color lightStrokeCardGlow = Color(0xFFFF4FA3);

  static const List<Color> seatColors = [
    red,
    blue,
    yellow,
    green,
    purple,
    cyan,
  ];
  static const List<Color> seatSoftColors = [
    Color(0xFFFF6F60),
    Color(0xFF42A5F5),
    Color(0xFFFFCA28),
    Color(0xFF66BB6A),
    Color(0xFFB86BFF),
    Color(0xFF35DFFF),
  ];

  static Color seatColor(int seat) =>
      seatColors[seat.clamp(0, seatColors.length - 1)];
  static Color seatColorSoft(int seat) =>
      seatSoftColors[seat.clamp(0, seatSoftColors.length - 1)];
}

class AppTheme {
  static ThemeData buildTheme() => dark();

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: goldColor,
        secondary: amberColor,
        surface: Color(0xFF2E0845),
        onPrimary: Color(0xFF1A0800),
        onSurface: Colors.white,
        tertiary: greenBtn,
      ),
      cardColor: const Color(0xFF2E0845),
      fontFamily: 'sans-serif',
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBgPage,
      colorScheme: const ColorScheme.light(
        primary: goldColor,
        secondary: amberColor,
        surface: Colors.white,
        onPrimary: Color(0xFF1A0800),
        onSurface: Color(0xFF25102F),
      ),
      cardColor: Colors.white,
    );
  }
}

// ── Context extensions ─────────────────────────────────────────────────────────

extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bgPage => isDark ? AppColors.darkBgPage : AppColors.lightBgPage;
  Color get bgCard => isDark ? AppColors.darkBgCard : AppColors.lightBgCard;
  Color get bgHeader =>
      isDark ? AppColors.darkBgHeader : AppColors.lightBgHeader;
  Color get bgSel => isDark ? AppColors.darkBgSel : AppColors.lightBgSel;

  Color get txtPrimary =>
      isDark ? AppColors.darkTxtPrimary : AppColors.lightTxtPrimary;
  Color get txtSecondary =>
      isDark ? AppColors.darkTxtSecondary : AppColors.lightTxtSecondary;
  Color get txtMuted =>
      isDark ? AppColors.darkTxtMuted : AppColors.lightTxtMuted;

  Color get strokeCard =>
      isDark ? AppColors.darkStrokeCard : AppColors.lightStrokeCard;
  Color get strokeCardGlow =>
      isDark ? AppColors.darkStrokeCardGlow : AppColors.lightStrokeCardGlow;
}
