import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scan_serve/utils/screen_scale.dart';

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
  static const Color secondaryText = Color(0xFF45494C); // Darker charcoal for better contrast
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
      ),
    ),
    textTheme: GoogleFonts.outfitTextTheme(TextTheme(
      displayLarge: TextStyle(color: primaryText, fontWeight: FontWeight.bold, fontSize: 36.sp), // Increased as requested
      displayMedium: TextStyle(color: primaryText, fontWeight: FontWeight.bold, fontSize: 28.sp),
      titleLarge: TextStyle(color: primaryText, fontWeight: FontWeight.w600, fontSize: 24.sp),
      titleMedium: TextStyle(color: primaryText, fontWeight: FontWeight.w600, fontSize: 20.sp),
      bodyLarge: TextStyle(color: primaryText, fontSize: 17.sp),
      bodyMedium: TextStyle(color: secondaryText, fontSize: 15.sp),
      labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.sp),
    )),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: dividerColor, width: 1.w),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: topBarBackground,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: primaryText, size: 24),
      titleTextStyle: TextStyle(color: primaryText, fontSize: 20.sp, fontWeight: FontWeight.bold),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: primaryText,
      contentTextStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w500),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: MaterialStateProperty.resolveWith((states) {
        if (!states.contains(MaterialState.selected)) {
          return const Color(0xFF000000); // Black border when OFF for visibility
        }
        return null;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (!states.contains(MaterialState.selected)) {
          return Colors.transparent; // Transparent track to show the border
        }
        return null;
      }),
    ),
  );

  // Keep darkTheme reference if needed but default to light
  static final ThemeData darkTheme = lightTheme; 
}
