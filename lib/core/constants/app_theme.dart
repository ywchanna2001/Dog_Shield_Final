import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF4A78B7);
  static const Color secondaryColor = Color(0xFF2E5894);
  static const Color accentColor = Color(0xFF5FDEEF);
  static const Color errorColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFFA726);
  static const Color successColor = Color(0xFF43A047);
  static const Color infoColor = Color(0xFF2196F3);

  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color backgroundDark = Color(0xFF1C2A3A);

  static const Color textPrimaryLight = Color(0xFF323F4B);
  static const Color textSecondaryLight = Color(0xFF617587);
  static const Color textPrimaryDark = Color(0xFFF5F7FA);
  static const Color textSecondaryDark = Color(0xFFB0BEC5);

  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF273546);

  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF405365);

  // Light theme
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceLight,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimaryLight,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme).copyWith(
      displayLarge: const TextStyle(color: textPrimaryLight, fontWeight: FontWeight.bold),
      displayMedium: const TextStyle(color: textPrimaryLight, fontWeight: FontWeight.bold),
      displaySmall: const TextStyle(color: textPrimaryLight, fontWeight: FontWeight.bold),
      headlineMedium: const TextStyle(color: textPrimaryLight, fontWeight: FontWeight.w600),
      headlineSmall: const TextStyle(color: textPrimaryLight),
      titleLarge: const TextStyle(color: textPrimaryLight, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(color: textPrimaryLight),
      titleSmall: const TextStyle(color: textSecondaryLight),
      bodyLarge: const TextStyle(color: textPrimaryLight),
      bodyMedium: const TextStyle(color: textPrimaryLight),
      bodySmall: const TextStyle(color: textSecondaryLight),
      labelLarge: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
      labelSmall: const TextStyle(color: textSecondaryLight),
    ),
    cardTheme: CardThemeData(
      color: surfaceLight,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black12,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        minimumSize: const Size(double.infinity, 50),
        side: const BorderSide(color: primaryColor, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: dividerLight, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: dividerLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      labelStyle: const TextStyle(color: textSecondaryLight),
      hintStyle: const TextStyle(color: textSecondaryLight),
      errorStyle: const TextStyle(color: errorColor, fontSize: 12),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceLight,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondaryLight,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentColor,
      foregroundColor: Colors.white,
    ),
    dividerTheme: const DividerThemeData(color: dividerLight, thickness: 1, space: 1),
    chipTheme: ChipThemeData(
      backgroundColor: primaryColor.withOpacity(0.1),
      disabledColor: dividerLight,
      selectedColor: primaryColor,
      secondarySelectedColor: secondaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(color: textPrimaryLight),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      brightness: Brightness.light,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: textSecondaryLight,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceDark,
      contentTextStyle: const TextStyle(fontFamily: 'Poppins', color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      surface: surfaceDark,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimaryDark,
      onError: Colors.white,
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: const TextStyle(color: textPrimaryDark, fontWeight: FontWeight.bold),
      displayMedium: const TextStyle(color: textPrimaryDark, fontWeight: FontWeight.bold),
      displaySmall: const TextStyle(color: textPrimaryDark, fontWeight: FontWeight.bold),
      headlineMedium: const TextStyle(color: textPrimaryDark, fontWeight: FontWeight.w600),
      headlineSmall: const TextStyle(color: textPrimaryDark),
      titleLarge: const TextStyle(color: textPrimaryDark, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(color: textPrimaryDark),
      titleSmall: const TextStyle(color: textSecondaryDark),
      bodyLarge: const TextStyle(color: textPrimaryDark),
      bodyMedium: const TextStyle(color: textPrimaryDark),
      bodySmall: const TextStyle(color: textSecondaryDark),
      labelLarge: const TextStyle(color: accentColor, fontWeight: FontWeight.w600),
      labelSmall: const TextStyle(color: textSecondaryDark),
    ),
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black45,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentColor,
        minimumSize: const Size(double.infinity, 50),
        side: const BorderSide(color: accentColor, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentColor,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: dividerDark, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: dividerDark, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: accentColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      labelStyle: const TextStyle(color: textSecondaryDark),
      hintStyle: const TextStyle(color: textSecondaryDark),
      errorStyle: const TextStyle(color: errorColor, fontSize: 12),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceDark,
      elevation: 0,
      iconTheme: IconThemeData(color: textPrimaryDark),
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        color: textPrimaryDark,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceDark,
      selectedItemColor: accentColor,
      unselectedItemColor: textSecondaryDark,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentColor,
      foregroundColor: textPrimaryDark,
    ),
    dividerTheme: const DividerThemeData(color: dividerDark, thickness: 1, space: 1),
    chipTheme: ChipThemeData(
      backgroundColor: primaryColor.withOpacity(0.2),
      disabledColor: dividerDark,
      selectedColor: primaryColor,
      secondarySelectedColor: accentColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(color: textPrimaryDark),
      secondaryLabelStyle: const TextStyle(color: textPrimaryDark),
      brightness: Brightness.dark,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: accentColor,
      unselectedLabelColor: textSecondaryDark,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceDark,
      contentTextStyle: const TextStyle(fontFamily: 'Poppins', color: textPrimaryDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
