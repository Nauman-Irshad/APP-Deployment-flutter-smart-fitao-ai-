/// Validate pasted HTTPS links (Cloudflare R2, Firebase, CDN) for marketplace media.
class CloudMediaUrl {
  CloudMediaUrl._();

  static String normalize(String raw) => raw.trim();

  static bool isHttpsUrl(String raw) {
    final u = Uri.tryParse(normalize(raw));
    return u != null &&
        u.hasScheme &&
        u.scheme == 'https' &&
        u.host.isNotEmpty;
  }

  static bool looksLikeCdnHost(String url) {
    final lower = normalize(url).toLowerCase();
    return lower.contains('r2.dev') ||
        lower.contains('cloudflare') ||
        lower.contains('firebasestorage.googleapis.com') ||
        lower.contains('firebasestorage.app') ||
        lower.contains('vercel.app') ||
        lower.contains('amazonaws.com');
  }

  /// Returns error message, or null if OK.
  static String? validateGlbUrl(String raw) {
    final url = normalize(raw);
    if (url.isEmpty) return 'Paste your Cloudflare / online GLB link';
    if (!isHttpsUrl(url)) {
      return '3D link must be https:// (e.g. Cloudflare R2 pub-….r2.dev/…/model.glb)';
    }
    final lower = url.toLowerCase();
    if (!lower.contains('.glb') && !lower.split('?').first.endsWith('.glb')) {
      return 'Link should end with .glb (3D model file)';
    }
    return null;
  }

  /// Returns error message, or null if OK.
  static String? validateVideoUrl(String raw) {
    final url = normalize(raw);
    if (url.isEmpty) return 'Paste your Cloudflare / online video link';
    if (!isHttpsUrl(url)) {
      return 'Video link must be https:// (e.g. …r2.dev/reels/your-video.mp4)';
    }
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    if (!path.contains('.mp4') &&
        !path.contains('.webm') &&
        !path.contains('.mov') &&
        !path.contains('reel')) {
      return 'Use a direct .mp4 / .webm link (or a reel path on your CDN)';
    }
    return null;
  }

  static String? validateImageUrl(String raw) {
    final url = normalize(raw);
    if (url.isEmpty) return null;
    if (!isHttpsUrl(url)) return 'Image link must be https://';
    return null;
  }
}
