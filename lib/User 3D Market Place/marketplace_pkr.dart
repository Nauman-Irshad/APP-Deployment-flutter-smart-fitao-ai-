/// PKR price labels for 3D marketplace UI.
String formatPkr(num? value, {bool includeDecimals = false}) {
  final n = (value is int ? value.toDouble() : (value as num?)?.toDouble()) ?? 0;
  final rounded = includeDecimals ? n : n.roundToDouble();
  final text = includeDecimals
      ? rounded.toStringAsFixed(0)
      : rounded.round().toString();
  final withCommas = text.replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return 'PKR $withCommas';
}
