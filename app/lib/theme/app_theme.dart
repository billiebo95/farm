import 'package:flutter/material.dart';

/// Visual language ported from `Аптека Опт v2.dc.html`:
/// calm/clinical, white with a soft pine-green accent, dense lists.
class AppColors {
  AppColors._();

  static const accent = Color(0xFF1F6F5C);
  static const accentDark = Color(0xFF175546);
  static const accentSoftBg = Color(0xFFE6EFEB);
  static const accentSoftFg = Color(0xFF4F7C6F);

  static const canvasBg = Color(0xFFEDF0EF);
  static const screenBg = Color(0xFFF4F6F5);
  static const surface = Color(0xFFFFFFFF);
  static const inputBg = Color(0xFFFBFCFC);
  static const chipBg = Color(0xFFF1F4F3);

  static const textPrimary = Color(0xFF14181A);
  static const textSecondary = Color(0xFF6B7573);
  static const textTertiary = Color(0xFF8B9391);
  static const textMuted = Color(0xFF5C6663);
  static const textDim = Color(0xFF3A4442);

  static const borderLight = Color(0xFFDDE3E1);
  static const borderCard = Color(0xFFE4E9E7);
  static const borderHairline = Color(0xFFF0F3F2);
  static const borderIdle = Color(0xFFD3DAD8);

  static const warnBg = Color(0xFFFBEDE4);
  static const warnFg = Color(0xFFB4551F);
  static const dangerBg = Color(0xFFF6E6DC);
  static const dangerFg = Color(0xFF8B4A1F);

  static const markBg = Color(0xFFE4EDF5);
  static const markFg = Color(0xFF2A5C8A);

  static const disabledBg = Color(0xFFB9C3C0);

  static const adminBg = Color(0xFF14181A);
  static const adminAccent = Color(0xFF7FB3A2);
  static const adminChipIdle = Color(0x1FFFFFFF); // rgba(255,255,255,.12)
  static const adminPinMsg = Color(0xFFE0A08A);

  static const idleIcon = Color(0xFF98A19E);
}

class AppText {
  AppText._();

  static const _ui = null; // use platform default (Roboto/San Francisco)
  static const _mono = 'monospace';

  static const display = TextStyle(
    fontFamily: _ui,
    fontWeight: FontWeight.w700,
    fontSize: 26,
    height: 1.1,
    letterSpacing: -0.6,
    color: AppColors.textPrimary,
  );

  static const title = TextStyle(
    fontFamily: _ui,
    fontWeight: FontWeight.w700,
    fontSize: 30,
    height: 1.15,
    letterSpacing: -0.6,
    color: AppColors.textPrimary,
  );

  static const h2 = TextStyle(
    fontFamily: _ui,
    fontWeight: FontWeight.w700,
    fontSize: 26,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const h3 = TextStyle(
    fontFamily: _ui,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static const bodyDark = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 13,
    height: 1.5,
    color: AppColors.textDim,
  );

  static const label = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 12,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
  );

  static const button = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 17,
    color: Colors.white,
  );

  static const productName = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  static const meta = TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1.35,
    color: AppColors.textSecondary,
  );

  static const price = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 18,
    color: AppColors.textPrimary,
  );

  static const code = TextStyle(
    fontFamily: _mono,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const codeLg = TextStyle(
    fontFamily: _mono,
    fontWeight: FontWeight.w700,
    fontSize: 19,
    letterSpacing: 1,
    color: AppColors.textPrimary,
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      primary: AppColors.accent,
    ),
    scaffoldBackgroundColor: AppColors.canvasBg,
  );
  return base.copyWith(
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.accent),
  );
}
