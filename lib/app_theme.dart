import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color.fromARGB(255, 23, 104, 170);
  static const Color red = Color(0xFFB22222);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color green = Color(0xFF228B22);
  static const Color yellow = Colors.yellow;
  static const Color grey = Color(0xFF7B7B7B);
  static const Color blue = Colors.blue;

  static ThemeData lightTheme = ThemeData(
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    splashFactory: NoSplash.splashFactory,
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: white.withValues(alpha: .8),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(0),
      ),
    ),
    dividerColor: grey,
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(fontSize: 14, color: white.withValues(alpha: .5)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: white),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: red),
      ),
      isDense: true,
    ),
    textTheme: TextTheme(
      labelSmall: TextStyle(
        color: white.withValues(alpha: .7),
        fontSize: 30,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        wordSpacing: 4,
      ),
      titleLarge: TextStyle(color: black),
      titleMedium: TextStyle(
        color: white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: white,
      ),
    ),
  );
  static ThemeData darkTheme = ThemeData();
}
