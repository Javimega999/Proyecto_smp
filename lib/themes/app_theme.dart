import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0xFFBB86FC); // Morado neón
  static const secondaryColor = Color(0xFF03DAC5); // Verde azulado neón
  static const backgroundColor = Color(0xFF121212); // Gris oscuro
  static const appBarColor =
      Color(0xFF1E1E1E); // Gris oscuro más claro para AppBar

  static final darkAestheticTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: appBarColor,
      elevation: 4,
      shadowColor: primaryColor.withOpacity(0.5),
      titleTextStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontFamily: 'Playfair Display',
        color: primaryColor,
      ),
      iconTheme: const IconThemeData(
        color: primaryColor,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        fontSize: 16,
        fontFamily: 'Raleway',
        color: Colors.white70,
      ),
      displayLarge: TextStyle(
        fontSize: 32,
        fontFamily: 'Dancing Script',
        fontWeight: FontWeight.bold,
        color: secondaryColor,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontFamily: 'Raleway',
        color: Colors.white60,
      ),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: secondaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontFamily: 'Raleway',
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF1E1E1E), // Gris oscuro más claro
      elevation: 5,
      shadowColor: primaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    iconTheme: const IconThemeData(
      color: secondaryColor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF272727), // Gris más claro para inputs
      border: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(15),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor),
        borderRadius: BorderRadius.circular(15),
      ),
      hintStyle: const TextStyle(fontFamily: 'Raleway', color: Colors.grey),
    ),
    floatingActionButtonTheme:
        const FloatingActionButtonThemeData(backgroundColor: primaryColor),
  );
}
