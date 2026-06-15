/// Maps seller/dashboard category names to landing page sections.
String normalizeLandingSection(String? raw) {
  final s = (raw ?? '').trim();
  if (s.isEmpty) return '';
  final lower = s.toLowerCase();
  if (lower == 'kurta shalwar' ||
      lower == 'kurta pajama' ||
      lower == 'kurtaz pajama' ||
      lower == 'kurtaz shalwar' ||
      lower.contains('kurta')) {
    return 'Kurta Shalwar';
  }
  if (lower == 'shalwar kameez' || lower.contains('shalwar kameez')) {
    return 'Shalwar Kameez';
  }
  if (lower == 'fabric') return 'Fabric';
  return s;
}

bool productMatchesLandingSection(Map<String, dynamic> product, String section) {
  final want = normalizeLandingSection(section);
  final sec = normalizeLandingSection(
    product['section']?.toString() ?? product['category']?.toString(),
  );
  return sec == want;
}
