import 'package:flutter/material.dart';

const _primary = Color(0xFF50BFF7);
final primary = MaterialColor(
  _primary.value,
  const <int, Color>{
    50: Color(0xFFEAF7FE),
    100: Color(0xFFCBECFD),
    200: Color(0xFFA8DFFB),
    300: Color(0xFF85D2F9),
    400: Color(0xFF6AC9F8),
    500: _primary,
    600: Color(0xFF49B9F6),
    700: Color(0xFF40B1F5),
    800: Color(0xFF37A9F3),
    900: Color(0xFF279BF1),
  },
);
const _primaryDark = Color(0xFF0A6994);
final primaryDark = MaterialColor(
  _primaryDark.value,
  const <int, Color>{
    50: Color(0xFFE2EDF2),
    100: Color(0xFFB6D2DF),
    200: Color(0xFF85B4CA),
    300: Color(0xFF5496B4),
    400: Color(0xFF2F80A4),
    500: _primaryDark,
    600: Color(0xFF09618C),
    700: Color(0xFF075681),
    800: Color(0xFF054C77),
    900: Color(0xFF033B65),
  },
);
const _accent = Color(0xFF158BFF);
final accent = MaterialColor(
  _accent.value,
  const <int, Color>{
    50: Color(0xFFE3F1FF),
    100: Color(0xFFB9DCFF),
    200: Color(0xFF8AC5FF),
    300: Color(0xFF5BAEFF),
    400: Color(0xFF389CFF),
    500: _accent,
    600: Color(0xFF1283FF),
    700: Color(0xFF0F78FF),
    800: Color(0xFF0C6EFF),
    900: Color(0xFF065BFF),
  },
);

final lightColorScheme = ColorScheme.light(
  primary: primary,
  primaryVariant: primaryDark,
  secondary: accent.shade500,
  secondaryVariant: accent.shade800,
  onSecondary: Colors.white,
);
final darkColorScheme = ColorScheme.dark(
  primary: primary,
  primaryVariant: primaryDark,
  secondary: accent.shade500,
  secondaryVariant: accent.shade800,
  onSecondary: Colors.white,
);

final lightTextTheme = Typography.blackMountainView;
final darkTextTheme = Typography.whiteMountainView;

final lightThemeData = ThemeData.from(
  colorScheme: lightColorScheme,
  textTheme: lightTextTheme,
);
final darkThemeData = ThemeData.from(
  colorScheme: darkColorScheme,
  textTheme: darkTextTheme,
);