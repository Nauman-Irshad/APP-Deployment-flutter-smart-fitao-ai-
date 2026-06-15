/// Port of `frontend/src/lib/measurementAccuracyDisplay.ts`.

/// Single overall estimate (~70–80%) that shifts when profile or merged
/// measurements change; optionally blends server mean R² when the model is ready.
int clothOverallAccuracyPercent({
  required String profileSeed,
  required Map<String, double> measurementsCm,
  double? meanR2,
  required bool modelLoaded,
}) {
  int mix(String s) {
    var h = 0;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }

  final keys = measurementsCm.keys.toList()..sort();
  final buf = StringBuffer('${profileSeed.trim()}|');
  for (final k in keys) {
    final v = measurementsCm[k];
    if (v != null && !v.isNaN) buf.write('$k:${v.toStringAsFixed(2)}|');
  }
  final h = mix(buf.toString());

  var pct = 70 + (h.abs() % 11);

  if (modelLoaded && meanR2 != null && meanR2 >= 0 && meanR2 <= 1) {
    final modelPart = (68 + meanR2 * 12).round();
    pct = ((pct * 0.45) + (modelPart * 0.55)).round();
  }

  return pct.clamp(70, 80);
}

String clothSourceBadgeTitle(bool isDerived) {
  return isDerived
      ? 'AI geometry — proportional estimate from hip / height (not a separate neural output)'
      : 'AI model — neural net prediction';
}
