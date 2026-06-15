import 'dart:convert';

/// Port of `frontend/src/lib/clothSizes.ts` (storage key + payload shape).

const String clothStorageKeyLastFit = 'snapmeasure_last_fit';

double clothCmToInches(double cm) => cm / 2.54;

double clothInchesToCm(double inches) => inches * 2.54;

Map<String, double>? clothSanitizeR2Map(Map<String, dynamic>? raw) {
  if (raw == null) return null;
  final out = <String, double>{};
  for (final e in raw.entries) {
    final v = e.value;
    if (v is num) {
      final d = v.toDouble();
      if (!d.isNaN && d >= 0 && d <= 1) out[e.key] = d;
    }
  }
  return out.isEmpty ? null : out;
}

/// Mirrors `buildStoredFitPayload` from React.
Map<String, dynamic> clothBuildStoredFitPayload(
  Map<String, double> measurementsCm,
  String fitPreference, {
  Map<String, dynamic>? perTargetR2,
  double? meanR2,
}) {
  final chestCm = measurementsCm['chest'];
  final waistCm = measurementsCm['waist'];
  final chestIn =
      chestCm != null && !chestCm.isNaN ? clothCmToInches(chestCm) : 0.0;
  final waistIn =
      waistCm != null && !waistCm.isNaN ? clothCmToInches(waistCm) : 0.0;
  final chestRounded = (chestIn * 10).round() / 10;
  final waistRounded = (waistIn * 10).round() / 10;

  final accuracy = clothSanitizeR2Map(perTargetR2);

  final payload = <String, dynamic>{
    'shirt': chestRounded > 0 ? '$chestRounded' : '—',
    'pantWaist': waistRounded,
    'chestIn': chestRounded,
    'waistIn': waistRounded,
    'fitPreference': fitPreference,
    'updatedAt': DateTime.now().toUtc().toIso8601String(),
    'measurementsCm': measurementsCm.map((k, v) => MapEntry(k, v)),
  };
  if (accuracy != null) payload['accuracyR2ByField'] = accuracy;
  if (meanR2 != null && !meanR2.isNaN && meanR2 >= 0 && meanR2 <= 1) {
    payload['meanR2'] = meanR2;
  }
  return payload;
}

/// Base64url for `?snapmeasure=` (matches TS).
String clothEncodeFitForStudioQuery(Map<String, dynamic> payload) {
  final jsonStr = jsonEncode(payload);
  final bytes = utf8.encode(jsonStr);
  var s = base64UrlEncode(bytes).replaceAll('=', '');
  return s;
}
