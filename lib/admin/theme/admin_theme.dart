import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF0F6D3F); // Professional Green
  static const Color secondaryColor = Color(0xFF1C7C54);
  
  // Clean Light Theme Palette
  static const Color scaffoldBackground = Color(0xFFF8F9FA); // Very light gray for depth
  static const Color cardBackground = Colors.white;
  static const Color sidebarBackground = Colors.white;
  static const Color topBarBackground = Colors.white;
  
  static const Color primaryText = Color(0xFF1A1C1E); // Near black
  static const Color secondaryText = Color(0xFF5E6368); // Soft charcoal
  static const Color dividerColor = Color(0xFFEFF1F3);
  
  // Semantic Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color critical = Color(0xFFD32F2F);
  static const Color info = Color(0xFF0288D1);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: scaffoldBackground,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: cardBackground,
      background: scaffoldBackground,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: primaryText,
      onBackground: primaryText,
      onError: Colors.white,
      outline: dividerColor,
      error: critical,
    ),
    dividerColor: dividerColor,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    textTheme: GoogleFonts.outfitTextTheme(const TextTheme(
      displayLarge: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: primaryText, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: primaryText, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: primaryText),
      bodyMedium: TextStyle(color: secondaryText),
      labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    )),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: dividerColor, width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: topBarBackground,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: primaryText),
      titleTextStyle: TextStyle(color: primaryText, fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  // Keep darkTheme reference if needed but default to light
  static final ThemeData darkTheme = lightTheme; 
}
