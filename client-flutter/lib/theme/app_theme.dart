import 'package:flutter/material.dart';

class AppColors {
  // Piece colors — classic vivid Ludo palette
  static const Color red    = Color(0xffF32B2B);
  static const Color blue   = Color(0xff1565E0);
  static const Color yellow = Color(0xffFFD000);
  static const Color green  = Color(0xff2DB34A);

  // Home-lane soft tints
  static const Color redSoft    = Color(0xffFF8A80);
  static const Color blueSoft   = Color(0xff82B1FF);
  static const Color yellowSoft = Color(0xffFFE57F);
  static const Color greenSoft  = Color(0xff69F0AE);

  // UI accents
  static const Color gold      = Color(0xffFFD426);
  static const Color amber     = Color(0xffFF9A00);
  static const Color teal      = Color(0xff32D3C8);
  static const Color navy      = Color(0xff1A237E);
  static const Color navyDeep  = Color(0xff0D1B5E);
  static const Color goldDark  = Color(0xffC8940A);
  static const Color ivory     = Color(0xffF5F0DC);

  // Dark-theme backgrounds
  static const Color darkBgPage    = Color(0xff150020);
  static const Color darkBgSurface = Color(0xff2A0B49);
  static const Color darkBgCard    = Color(0xff3B145B);
  static const Color darkBgCardHi  = Color(0xff6E1C83);
  static const Color darkBgHeader  = Color(0xff4D0F69);
  static const Color darkBgMetric  = Color(0x33FFD426);
  static const Color darkBgSel     = Color(0xff9A24D4);
  static const Color darkBgDanger  = Color(0xff2A1218);
  static const Color darkBgInput   = Color(0xff35104F);

  static const Color darkTxtPrimary   = Color(0xffFFFFFF);
  static const Color darkTxtSecondary = Color(0xEEFFF0FF);
  static const Color darkTxtMuted     = Color(0xCCFFECA8);
  static const Color darkTxtDim       = Color(0x77FFFFFF);

  static const Color darkStrokeCard    = Color(0x77FFD426);
  static const Color darkStrokeCardAlt = Color(0x55FFD426);
  static const Color darkStrokeCardGlow= Color(0xBBFFD426);
  static const Color darkStrokeDanger  = Color(0x55E53935);

  // Light-theme backgrounds
  static const Color lightBgPage    = Color(0xffFFF0FB);
  static const Color lightBgSurface = Color(0xffFFE15A);
  static const Color lightBgCard    = Color(0xffFFFFFF);
  static const Color lightBgHeader  = Color(0xffFF4FA3);
  static const Color lightBgMetric  = Color(0xffFFF0A6);
  static const Color lightBgSel     = Color(0xff40D8FF);

  static const Color lightTxtPrimary   = Color(0xff25102F);
  static const Color lightTxtSecondary = Color(0xff5A245C);
  static const Color lightTxtMuted     = Color(0xff7A3E7F);

  static const Color lightStrokeCard    = Color(0xff8D4CFF);
  static const Color lightStrokeCardAlt = Color(0xffD7C8FF);
  static const Color lightStrokeCardGlow= Color(0xffFF4FA3);

  static const List<Color> seatColors = [red, blue, yellow, green];
  static const List<Color> seatSoftColors = [redSoft, blueSoft, yellowSoft, greenSoft];
}

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBgPage,
      colorScheme: ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.amber,
        surface: AppColors.darkBgCard,
        onPrimary: const Color(0xff1A0800),
        onSurface: AppColors.darkTxtPrimary,
      ),
      cardColor: AppColors.darkBgCard,
      fontFamily: 'sans-serif',
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBgPage,
      colorScheme: ColorScheme.light(
        primary: AppColors.gold,
        secondary: AppColors.amber,
        surface: AppColors.lightBgCard,
        onPrimary: const Color(0xff1A0800),
        onSurface: AppColors.lightTxtPrimary,
      ),
      cardColor: AppColors.lightBgCard,
    );
  }
}

// Convenience extension on ThemeManager-style functions
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bgPage    => isDark ? AppColors.darkBgPage    : AppColors.lightBgPage;
  Color get bgCard    => isDark ? AppColors.darkBgCard    : AppColors.lightBgCard;
  Color get bgHeader  => isDark ? AppColors.darkBgHeader  : AppColors.lightBgHeader;
  Color get bgSel     => isDark ? AppColors.darkBgSel     : AppColors.lightBgSel;
  Color get txtPrimary   => isDark ? AppColors.darkTxtPrimary   : AppColors.lightTxtPrimary;
  Color get txtSecondary => isDark ? AppColors.darkTxtSecondary : AppColors.lightTxtSecondary;
  Color get txtMuted     => isDark ? AppColors.darkTxtMuted     : AppColors.lightTxtMuted;
  Color get strokeCard   => isDark ? AppColors.darkStrokeCard   : AppColors.lightStrokeCard;
  Color get strokeCardGlow => isDark ? AppColors.darkStrokeCardGlow : AppColors.lightStrokeCardGlow;
}
