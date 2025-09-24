// lib/theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color blue = Color(0xFF1E88E5);
  static const Color lightBlue = Color(0xFFE8F3FF);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color background = Colors.white;
}

final ThemeData appTheme = ThemeData(
  primaryColor: AppColors.blue,
  scaffoldBackgroundColor: AppColors.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColors.blue),
    // titleTextStyle cannot be const when referencing AppColors.blue inside TextStyle
    // so we construct it without const but with const-friendly fields where possible.
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(primary: AppColors.blue),
  textTheme: const TextTheme(
    // bodyMedium is the modern equivalent for body text
    bodyMedium: TextStyle(color: Colors.black87),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightBlue,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide.none,
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.blue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
);

// If you want a const AppBar title style using AppColors.blue, define it separately:
const TextStyle appBarTitleStyle = TextStyle(
  color: AppColors.blue,
  fontSize: 18,
  fontWeight: FontWeight.w600,
);
