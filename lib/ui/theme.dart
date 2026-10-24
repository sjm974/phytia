import 'package:flutter/material.dart';

const Color phytiaGreen = Color(0xFF1E6B45);
const Color phytiaGreenDark = Color(0xFF11402A);
const Color phytiaDark = Color(0xFF15241B);
const Color phytiaSand = Color(0xFFF5F7F2);

ThemeData buildPhytiaTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: phytiaGreen)
      .copyWith(primary: phytiaGreen, surface: phytiaSand);
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);

  final rounded = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: scheme.outlineVariant),
  );

  return base.copyWith(
    scaffoldBackgroundColor: phytiaSand,
    appBarTheme: AppBarTheme(
      backgroundColor: phytiaSand,
      surfaceTintColor: Colors.transparent,
      foregroundColor: phytiaDark,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: phytiaDark,
      ),
    ),
    textTheme: base.textTheme.copyWith(
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.35),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: phytiaDark,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: rounded,
      enabledBorder: rounded,
      focusedBorder: rounded.copyWith(
        borderSide: const BorderSide(color: phytiaGreen, width: 1.6),
      ),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFDDEFE1),
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: const TextStyle(
        fontSize: 13,
        color: phytiaDark,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
