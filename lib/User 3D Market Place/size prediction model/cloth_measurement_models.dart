/// Mirrors React `MeasurementWizardStep1.tsx` / `MeasurementWizardStepBodyPrefs.tsx` payloads.

class ClothWizardStep1Data {
  final String age;
  final String heightFeet;
  final String heightInches;
  final String weight;

  const ClothWizardStep1Data({
    required this.age,
    required this.heightFeet,
    required this.heightInches,
    required this.weight,
  });

  /// Same conversion as React `App.tsx` before `/predict`.
  double get heightCm {
    final feet = int.tryParse(heightFeet) ?? 0;
    final inches = int.tryParse(heightInches) ?? 0;
    final totalInches = feet * 12 + inches;
    return totalInches * 2.54;
  }

  double get weightKg => (double.tryParse(weight) ?? 0) / 2.20462;

  int get ageInt => int.tryParse(age) ?? 30;
}

class ClothWizardBodyPrefs {
  final String bodyType;
  final String collarFit;
  final String shoulderType;
  final String fitPreference;

  const ClothWizardBodyPrefs({
    required this.bodyType,
    required this.collarFit,
    required this.shoulderType,
    required this.fitPreference,
  });
}

/// Stable string for UI signals (e.g. overall accuracy %) from full wizard input.
String clothWizardAccuracySeed(
    ClothWizardStep1Data s1, ClothWizardBodyPrefs p) {
  return '${s1.age.trim()}|${s1.weight.trim()}|${s1.heightFeet.trim()}|'
      '${s1.heightInches.trim()}|${p.bodyType.trim()}|${p.collarFit.trim()}|'
      '${p.shoulderType.trim()}|${p.fitPreference.trim()}';
}
