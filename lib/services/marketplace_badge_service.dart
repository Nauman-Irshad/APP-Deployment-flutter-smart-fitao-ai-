import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Red badges on 3D marketplace Home (new products) and Reel (new videos).
/// Uses Firestore counters so every customer device sees new uploads.
class MarketplaceBadgeService extends ChangeNotifier {
  MarketplaceBadgeService._();

  static final MarketplaceBadgeService instance = MarketplaceBadgeService._();
  static final _db = FirebaseFirestore.instance;

  static const _seenProductsKey = 'mb_seen_product_seq';
  static const _seenReelsKey = 'mb_seen_reel_seq';

  int newProducts = 0;
  int newReels = 0;

  int _remoteProductSeq = 0;
  int _remoteReelSeq = 0;
  int _seenProductSeq = 0;
  int _seenReelSeq = 0;
  bool _loaded = false;
  bool _firebaseStarted = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _seenProductSeq = prefs.getInt(_seenProductsKey) ?? 0;
    _seenReelSeq = prefs.getInt(_seenReelsKey) ?? 0;
    _loaded = true;
    _recompute();
  }

  void startFirebaseSync() {
    if (_firebaseStarted) return;
    _firebaseStarted = true;
    ensureLoaded();
    _db.collection('marketplace_stats').doc('global').snapshots().listen(
      (snap) {
        final data = snap.data();
        if (data == null) return;
        _remoteProductSeq = (data['productSeq'] as num?)?.toInt() ?? 0;
        _remoteReelSeq = (data['reelSeq'] as num?)?.toInt() ?? 0;
        _recompute();
      },
      onError: (Object e) {
        debugPrint('MarketplaceBadgeService sync: $e');
      },
    );
  }

  void _recompute() {
    newProducts = (_remoteProductSeq - _seenProductSeq).clamp(0, 99);
    newReels = (_remoteReelSeq - _seenReelSeq).clamp(0, 99);
    notifyListeners();
  }

  Future<void> bumpNewProduct() async {
    await _db.collection('marketplace_stats').doc('global').set({
      'productSeq': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> bumpNewReel() async {
    await _db.collection('marketplace_stats').doc('global').set({
      'reelSeq': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> clearNewProducts() async {
    await ensureLoaded();
    _seenProductSeq = _remoteProductSeq;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seenProductsKey, _seenProductSeq);
    _recompute();
  }

  Future<void> clearNewReels() async {
    await ensureLoaded();
    _seenReelSeq = _remoteReelSeq;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seenReelsKey, _seenReelSeq);
    _recompute();
  }
}
