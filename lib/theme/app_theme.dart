import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/screen_scale.dart';

class AppTheme {
  // La Pino'z exact Light Palette
  static const Color primaryColor = Color(0xFF0F6D3F); // Brand Green
  static const Color lightGreen = Color(0xFFE6F4EC); // Veg background
  static const Color starGreen = Color(0xFF1C7C54); // Rating badge
  static const Color accentOrange = Color(0xFFFF9F43);
  static const Color lightOrange = Color(0xFFFFF1E6);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF1C1C1E);
  static const Color secondaryText = Color(0xFF6E6E73);
  static const Color borderColor = Color(0xFFE5E5EA);
  static const Color searchBarBackground = Color(0xFFF2F2F7);
  static const Color menuButtonBackgound = Color(0xFF1C1C1E);

  static final ThemeData themeData = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundColor,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryText,
      surface: backgroundColor,
      onPrimary: Colors.white,
      onSurface: primaryText,
      outline: borderColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.outfit(
        color: primaryText,
        fontSize: 18.sp, // Increased
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: primaryText, size: 24.w),
    ),
    cardTheme: CardThemeData(
      color: backgroundColor,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: borderColor, width: 1.w),
      ),
      margin: EdgeInsets.all(8.w),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.outfit(color: primaryText, fontSize: 34.sp, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.outfit(color: primaryText, fontSize: 30.sp, fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.outfit(color: primaryText, fontSize: 22.sp, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.outfit(color: primaryText, fontSize: 18.sp, fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.outfit(color: primaryText, fontSize: 16.sp, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.outfit(color: primaryText, fontSize: 16.sp, fontWeight: FontWeight.normal),
      bodyMedium: GoogleFonts.outfit(color: secondaryText, fontSize: 14.sp, fontWeight: FontWeight.normal),
      bodySmall: GoogleFonts.outfit(color: secondaryText, fontSize: 12.sp, fontWeight: FontWeight.normal),
    ),
    dividerTheme: const DividerThemeData(
      color: borderColor,
      thickness: 1,
      space: 1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: primaryText,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(color: primaryText, width: 1.5.w),
        ),
        textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15.sp),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: lightGreen,
      secondarySelectedColor: lightGreen,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      labelStyle: GoogleFonts.outfit(color: primaryText, fontSize: 13.sp, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: borderColor, width: 1.w),
      ),
    ),
  );
}
