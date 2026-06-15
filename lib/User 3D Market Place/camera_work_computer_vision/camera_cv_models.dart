/// Payload from Computer Vision (`/analyze` or iframe `postMessage`).
class CameraCvHumanEvent {
  const CameraCvHumanEvent({
    required this.phase,
    required this.humanDetected,
    required this.humanProbability,
    this.landmarksCount = 0,
    this.message,
    this.poseRecord,
    this.imageUrl,
    this.personJpegBase64,
    this.handoff,
  });

  /// `live` = throttled estimate from MediaPipe in-page; `capture` = after `/analyze`.
  final String phase;
  final bool humanDetected;
  final double humanProbability;
  final int landmarksCount;
  final String? message;

  /// Full strict pose JSON from the embedded page (capture phase only), if present.
  final Map<String, dynamic>? poseRecord;

  /// Saved body photo from `/analyze` (absolute URL) for 2D try-on.
  final String? imageUrl;

  /// Client-side JPEG when CV server did not return a URL.
  final String? personJpegBase64;

  /// Product / measurements handoff from marketplace.
  final Map<String, dynamic>? handoff;

  static CameraCvHumanEvent? fromJsonMap(Map<String, dynamic> m) {
    final type = m['type'];
    if (type != 'smartfitao_cv') return null;
    final phase = m['phase'] as String? ?? 'capture';
    final hp = m['human_probability'];
    final prob = hp is num ? hp.toDouble() : double.tryParse('$hp') ?? 0.0;
    final hd = m['human_detected'];
    final detected = hd is bool ? hd : hd == true || hd == 'true';
    final lc = m['landmarks_count'];
    final count = lc is int ? lc : (lc is num ? lc.toInt() : 0);
    final msg = m['message'] as String?;
    final img = m['image_url'] as String?;
    final b64 = m['person_jpeg_base64'] as String?;
    final pr = m['pose_record'];
    Map<String, dynamic>? poseRecord;
    if (pr is Map<String, dynamic>) {
      poseRecord = pr;
    } else if (pr is Map) {
      poseRecord = Map<String, dynamic>.from(pr);
    }
    Map<String, dynamic>? handoff;
    final h = m['handoff'];
    if (h is Map<String, dynamic>) {
      handoff = h;
    } else if (h is Map) {
      handoff = Map<String, dynamic>.from(h);
    }
    return CameraCvHumanEvent(
      phase: phase,
      humanDetected: detected,
      humanProbability: prob.clamp(0.0, 1.0),
      landmarksCount: count,
      message: msg,
      poseRecord: poseRecord,
      imageUrl: (img != null && img.isNotEmpty) ? img : null,
      personJpegBase64: (b64 != null && b64.isNotEmpty) ? b64 : null,
      handoff: handoff,
    );
  }
}
