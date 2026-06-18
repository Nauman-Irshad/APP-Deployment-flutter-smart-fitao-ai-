import 'package:cloud_firestore/cloud_firestore.dart';

import '../User 3D Market Place/reel_media.dart';
import 'marketplace_badge_service.dart';

/// Firestore-backed tailor reels merged with bundled catalog.
class ReelCatalogService {
  ReelCatalogService._();

  static final _db = FirebaseFirestore.instance;

  static ReelCatalogItem _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final idHash = doc.id.hashCode.abs() % 100000;
    return ReelCatalogItem(
      id: 10000 + idHash,
      shopName: data['shopName']?.toString() ?? 'Tailor',
      videoTitle: data['videoTitle']?.toString() ?? 'New reel',
      videoPath: data['videoUrl']?.toString() ?? '',
      posterAsset: data['posterAsset']?.toString() ?? 'assets/banner 1.png',
      fallbackVideoPath: data['fallbackVideoUrl']?.toString(),
      firestoreId: doc.id,
    );
  }

  static Stream<List<ReelCatalogItem>> watchCatalog() {
    return _db.collection('marketplace_reels').snapshots().map((snap) {
      final docs = snap.docs.toList();
      docs.sort((a, b) {
        final at = a.data()['createdAt'];
        final bt = b.data()['createdAt'];
        if (at is Timestamp && bt is Timestamp) {
          return bt.compareTo(at);
        }
        return b.id.compareTo(a.id);
      });
      final uploaded =
          docs.map(_fromDoc).where((r) => r.videoPath.isNotEmpty).toList();
      return [...uploaded, ...kReelCatalog];
    });
  }

  static Future<void> addTailorReel({
    required String tailorId,
    required String tailorName,
    required String shopName,
    required String videoTitle,
    required String videoUrl,
    String posterAsset = 'assets/banner 1.png',
    String? fallbackVideoUrl,
  }) async {
    if (videoUrl.trim().isEmpty) {
      throw ArgumentError('Video URL is required');
    }
    await _db.collection('marketplace_reels').add({
      'tailorId': tailorId,
      'tailorName': tailorName,
      'shopName': shopName,
      'videoTitle': videoTitle.trim(),
      'videoUrl': videoUrl.trim(),
      'posterAsset': posterAsset,
      if (fallbackVideoUrl != null && fallbackVideoUrl.isNotEmpty)
        'fallbackVideoUrl': fallbackVideoUrl.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await MarketplaceBadgeService.instance.bumpNewReel();
  }
}
