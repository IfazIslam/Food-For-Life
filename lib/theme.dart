import 'package:flutter/material.dart';

class AppTheme {
  // 3-tone Color Palette
  static const Color offWhite = Color(0xFFF9FFF9);
  static const Color offGreen = Color(0xFF006940);
  static const Color offOrange = Color(0xFF006940);
  static const Color offGray = Color(0xFF595959);

  // App Theme
  static ThemeData get themeData {
    return ThemeData(
      scaffoldBackgroundColor: offWhite,
      primaryColor: offGreen,
      colorScheme: ColorScheme.fromSeed(
        seedColor: offGreen,
        primary: offGreen,
        secondary: offOrange,
        background: offWhite,
        surface: offWhite,
      ),
      fontFamily: 'PlaypenSansDeva', // Modern system font fallback
      useMaterial3: true,
      
      // Global App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: offWhite,
        foregroundColor: offGreen,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: offGreen),
      ),

      // Global Card Theme - strictly rounded edges
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Global Button Theme - strictly rounded edges
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: offGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: offOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      
      // Global Input Decoration (Text Fields) - strictly rounded edges
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: offGreen, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: offOrange, width: 2),
        ),
        hintStyle: const TextStyle(color: Colors.black38),
      ),

      // Bottom Nav Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFBFBFB),
        selectedItemColor: offOrange,
        unselectedItemColor: offGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,

      ),
    );
  }
}
