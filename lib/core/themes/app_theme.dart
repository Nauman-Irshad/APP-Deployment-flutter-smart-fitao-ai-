import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        scaffoldBackgroundColor: const Color(0xFFE6F4EF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F9D6E),
          primary: const Color(0xFF1F9D6E),
          secondary: const Color(0xFFDFF3EA),
        ),
        useMaterial3: true,
      );
}
