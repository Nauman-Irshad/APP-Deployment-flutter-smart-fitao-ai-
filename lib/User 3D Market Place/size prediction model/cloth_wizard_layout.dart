import 'dart:math' show max, min;

import 'package:flutter/material.dart';

/// Shared spacing for cloth wizard screens (steps 1–3).
class ClothWizardLayout {
  ClothWizardLayout._();

  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 340) return 10;
    if (w < 400) return 12;
    if (w < 600) return 16;
    return 24;
  }

  /// Readable column width on tablets/desktop.
  static double contentMaxWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final pad = horizontalPadding(context);
    return min(560.0, max(0.0, w - pad * 2));
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final h = horizontalPadding(context);
    return EdgeInsets.fromLTRB(h, 8, h, 24);
  }

  /// Title sizes scale slightly on very small phones.
  static double stepTitleSize(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 340) return 22;
    if (w < 400) return 24;
    return 26;
  }
}
