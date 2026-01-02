// File: core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      fontFamily: 'Space Grotesk',
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20.0.r,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          fontFamily: 'Space Grotesk',
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12).r,
        ),
        color: Colors.white,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8).r,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ).r,
          textStyle:  TextStyle(
            fontSize: 16.r,
            fontWeight: FontWeight.w500,
            fontFamily: 'Space Grotesk',
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ).r,
          textStyle:  TextStyle(
            fontSize: 16.r,
            fontWeight: FontWeight.w500,
            fontFamily: 'Space Grotesk',
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          padding:  EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ).r,
          textStyle:  TextStyle(
            fontSize: 16.r,
            fontWeight: FontWeight.w500,
            fontFamily: 'Space Grotesk',
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide:  BorderSide(color: AppColors.primary, width: 2.r),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide:  BorderSide(color: Colors.red, width: 2.r),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide:  BorderSide(color: Colors.red, width: 2.r),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ).r,
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: 16.r,
          fontFamily: 'Space Grotesk',
        ),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        backgroundColor: Colors.white,
        titleTextStyle:  TextStyle(
          fontSize: 20.r,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          fontFamily: 'Space Grotesk',
        ),
        contentTextStyle: TextStyle(
          fontSize: 16.r,
          color: Colors.black87,
          fontFamily: 'Space Grotesk',
        ),
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme:  BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
          ),
        ),
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: Colors.grey[300],
        thickness: 1,
        space: 1,
      ),
      
      // Scaffold Background
      scaffoldBackgroundColor: Colors.white,
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32.r,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontFamily: 'Space Grotesk',
        ),
        displayMedium: TextStyle(
          fontSize: 28.r,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontFamily: 'Space Grotesk',
        ),
        displaySmall: TextStyle(
          fontSize: 24.r,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontFamily: 'Space Grotesk',
        ),
        headlineLarge: TextStyle(
          fontSize: 22.r,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          fontFamily: 'Space Grotesk',
        ),
        headlineMedium: TextStyle(
          fontSize: 20.r,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          fontFamily: 'Space Grotesk',
        ),
        headlineSmall: TextStyle(
          fontSize: 18.r,
          fontWeight: FontWeight.w600,
          color: Colors.black,
          fontFamily: 'Space Grotesk',
        ),
        titleLarge: TextStyle(
          fontSize: 16.r,
          fontWeight: FontWeight.w500,
          color: Colors.black,
          fontFamily: 'Space Grotesk',
        ),
        titleMedium: TextStyle(
          fontSize: 14.r,
          fontWeight: FontWeight.w500,
          color: Colors.black,
          fontFamily: 'Space Grotesk',
        ),
        titleSmall: TextStyle(
          fontSize: 12.r,
          fontWeight: FontWeight.w500,
          color: Colors.black,
          fontFamily: 'Space Grotesk',
        ),
        bodyLarge: TextStyle(
          fontSize: 16.r,
          fontWeight: FontWeight.normal,
          color: Colors.black87,
          fontFamily: 'Space Grotesk',
        ),
        bodyMedium: TextStyle(
          fontSize: 14.r,
          fontWeight: FontWeight.normal,
          color: Colors.black87,
          fontFamily: 'Space Grotesk',
        ),
        bodySmall: TextStyle(
          fontSize: 12.r,
          fontWeight: FontWeight.normal,
          color: Colors.black54,
          fontFamily: 'Space Grotesk',
        ),
        labelLarge: TextStyle(
          fontSize: 14.r,
          fontWeight: FontWeight.w500,
          color: Colors.black,
          fontFamily: 'Space Grotesk',
        ),
        labelMedium: TextStyle(
          fontSize: 12.r,
          fontWeight: FontWeight.w500,
          color: Colors.black,
          fontFamily: 'Space Grotesk',
        ),
        labelSmall: TextStyle(
          fontSize: 10.r,
          fontWeight: FontWeight.w500,
          color: Colors.black,
          fontFamily: 'Space Grotesk',
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      fontFamily: 'Space Grotesk',
      
      // Scaffold Background
      scaffoldBackgroundColor: const Color(0xFF121212),
      
      // Similar configurations for dark theme...
      // You can extend this as needed
    );
  }
}