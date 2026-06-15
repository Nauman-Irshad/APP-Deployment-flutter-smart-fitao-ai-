/// Port of `frontend/src/lib/derivedLowerBody.ts`.

class ClothLowerBodyDerivedCm {
  final double thigh;
  final double calf;
  final double insideLeg;

  ClothLowerBodyDerivedCm({
    required this.thigh,
    required this.calf,
    required this.insideLeg,
  });
}

ClothLowerBodyDerivedCm? clothDeriveLowerBodyCm(double? hipCm, double? heightCm) {
  if (hipCm == null || hipCm.isNaN || hipCm <= 0) return null;
  final thigh = hipCm * 0.56;
  final calf = thigh * 0.63;
  final insideLeg = (heightCm != null && !heightCm.isNaN && heightCm > 0)
      ? heightCm * 0.453
      : hipCm * 0.52;
  double r(double x) => (x * 10).round() / 10;
  return ClothLowerBodyDerivedCm(
    thigh: r(thigh),
    calf: r(calf),
    insideLeg: r(insideLeg),
  );
}

const Set<String> clothDerivedLowerBodyFields = {'thigh', 'calf', 'insideLeg'};

Map<String, double> clothMergeDerivedLowerBody(
  Map<String, double> apiCm,
  double? heightCm,
) {
  final d = clothDeriveLowerBodyCm(apiCm['hip'], heightCm);
  if (d == null) return Map<String, double>.from(apiCm);
  final out = Map<String, double>.from(apiCm);
  if (!_validNum(out['thigh'])) out['thigh'] = d.thigh;
  if (!_validNum(out['calf'])) out['calf'] = d.calf;
  if (!_validNum(out['insideLeg'])) out['insideLeg'] = d.insideLeg;
  return out;
}

bool _validNum(double? v) => v != null && !v.isNaN;
