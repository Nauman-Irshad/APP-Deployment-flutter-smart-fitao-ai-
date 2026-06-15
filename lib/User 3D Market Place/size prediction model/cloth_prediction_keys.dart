/// Port of `frontend/src/predictionKeys.ts` (strings unchanged).

const List<String> clothCorePredictionKeys = [
  'neck',
  'shoulder',
  'chest',
  'waist',
  'hip',
  'arm',
  'bicep',
  'forearm',
  'wrist',
];

bool clothIsCorePredictionComplete(Map<String, dynamic> payload) {
  for (final k in clothCorePredictionKeys) {
    final v = payload[k];
    if (v is! num) return false;
    final d = v.toDouble();
    if (d.isNaN) return false;
  }
  return true;
}

/// First nine rows API; last three geometry-filled on step 3 (same labels as web).
const List<Map<String, String>> clothTwelveSummaryRows = [
  {'apiField': 'neck', 'label': 'Neck'},
  {'apiField': 'shoulder', 'label': 'Shoulder'},
  {'apiField': 'chest', 'label': 'Chest'},
  {'apiField': 'waist', 'label': 'Waist'},
  {'apiField': 'hip', 'label': 'Hip'},
  {'apiField': 'arm', 'label': 'Arm Length'},
  {'apiField': 'bicep', 'label': 'Bicep'},
  {'apiField': 'forearm', 'label': 'Forearm'},
  {'apiField': 'wrist', 'label': 'Wrist'},
  {'apiField': 'thigh', 'label': 'Thigh'},
  {'apiField': 'calf', 'label': 'Calf'},
  {'apiField': 'insideLeg', 'label': 'Inside Leg'},
];
