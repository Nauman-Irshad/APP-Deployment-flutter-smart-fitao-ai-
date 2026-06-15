import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Matches [id-2d-try-on/src/App.css] CSS variables.
class TryOnTheme {
  TryOnTheme._();

  static const white = Color(0xFFFFFFFF);
  static const cream = Color(0xFFE8DCC8);
  static const brown = Color(0xFF6B4F3F);
  static const gray = Color(0xFFEBEBEB);
  static const brownLight = Color(0xFF8A6F5C);
  static const brownMuted = Color(0xA66B4F3F);
  static const surfaceAlt = Color(0xFFFAFAFA);
  static const errBg = Color(0xFFFEF2F2);
  static const errBorder = Color(0xFFFECACA);
  static const errText = Color(0xFF991B1B);

  static TextStyle heading({double size = 24}) => GoogleFonts.poppins(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: brown,
        height: 1.15,
      );

  static TextStyle body({double size = 14, FontWeight weight = FontWeight.w400, Color? color}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color ?? brown,
      );
}
