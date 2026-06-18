import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Red badges on 3D marketplace Home (new products) and Reel (new videos).
class MarketplaceBadgeService extends ChangeNotifier {
  MarketplaceBadgeService._();

  static final MarketplaceBadgeService instance = MarketplaceBadgeService._();

  static const _productsKey = 'mb_new_products';
  static const _reelsKey = 'mb_new_reels';

  int newProducts = 0;
  int newReels = 0;
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    newProducts = prefs.getInt(_productsKey) ?? 0;
    newReels = prefs.getInt(_reelsKey) ?? 0;
    _loaded = true;
    notifyListeners();
  }

  Future<void> bumpNewProduct() async {
    await ensureLoaded();
    newProducts++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_productsKey, newProducts);
    notifyListeners();
  }

  Future<void> bumpNewReel() async {
    await ensureLoaded();
    newReels++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reelsKey, newReels);
    notifyListeners();
  }

  Future<void> clearNewProducts() async {
    await ensureLoaded();
    if (newProducts == 0) return;
    newProducts = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_productsKey, 0);
    notifyListeners();
  }

  Future<void> clearNewReels() async {
    await ensureLoaded();
    if (newReels == 0) return;
    newReels = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reelsKey, 0);
    notifyListeners();
  }
}
