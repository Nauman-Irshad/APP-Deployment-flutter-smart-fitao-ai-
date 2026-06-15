import 'package:flutter/material.dart';

/// Shared palette for the 3D marketplace landing experience.
abstract final class MarketplaceTheme {
  static const primary = Color(0xFF0F766E);
  static const primaryDark = Color(0xFF115E59);
  static const accent = Color(0xFF14B8A6);
  static const canvas = Color(0xFFF3F4F6);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5E7EB);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const badge = Color(0xFF134E4A);

  static BoxShadow get cardShadow => BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      );
}
