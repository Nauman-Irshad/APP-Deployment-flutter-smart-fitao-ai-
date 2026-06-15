import 'cloth_prediction_keys.dart';
import 'cloth_studio_bridge.dart';

/// Port of `mergeMeasurementsFromInputs` in `Result3DAndChart.tsx`.

Map<String, double> clothMergeMeasurementsFromInputs(
  Map<String, double> baseCm,
  Map<String, String> inchInputs,
) {
  final out = Map<String, double>.from(baseCm);
  for (final row in clothTwelveSummaryRows) {
    final apiField = row['apiField']!;
    final raw = inchInputs[apiField]?.trim() ?? '';
    if (raw.isEmpty || raw == '—') {
      out.remove(apiField);
      continue;
    }
    final inches = double.tryParse(raw);
    if (inches != null && !inches.isNaN && inches >= 0 && inches < 500) {
      out[apiField] = clothInchesToCm(inches);
    }
  }
  return out;
}
