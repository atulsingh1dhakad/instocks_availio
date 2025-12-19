import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.indigo,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(centerTitle: true),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}