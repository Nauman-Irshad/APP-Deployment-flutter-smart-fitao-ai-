import '../Order-Tracking-System/services/app_backend.dart';
import '../config/demo_accounts.dart';
import 'demo_accounts_service.dart';

/// Every 3D marketplace product belongs to the demo seller (Fashion Store Premium).
class MarketplaceDemoSeller {
  MarketplaceDemoSeller._();

  static AppUserProfile? _cached;

  /// Demo seller from Firestore (`sellerpremiumsmartfitao@gmail.com`).
  static Future<AppUserProfile> resolve() async {
    if (_cached != null) return _cached!;
    await DemoAccountsService.instance.preload();
    final fromService = DemoAccountsService.instance.cachedSeller;
    if (fromService != null) {
      _cached = fromService;
      return fromService;
    }
    final found =
        await AppBackend.instance.findUserByEmail(DemoAccounts.sellerEmail);
    if (found != null) {
      _cached = found;
      return found;
    }
    // Fallback so UI never blocks — register demo seller once in Firebase for live orders.
    _cached = AppUserProfile(
      uid: 'demo_seller_smartfitao',
      name: DemoAccounts.sellerName,
      email: DemoAccounts.sellerEmail,
      role: 'seller',
      shopName: DemoAccounts.sellerShop,
      address: 'SmartFitao 3D Marketplace',
      available: true,
    );
    return _cached!;
  }

  static void cache(AppUserProfile seller) {
    _cached = seller;
  }

  /// Stamp demo seller + stable product id on any marketplace product map.
  static Map<String, dynamic> attach(
    Map<String, dynamic> product,
    AppUserProfile seller,
  ) {
    final out = Map<String, dynamic>.from(product);
    final id = out['firebaseProductId']?.toString() ??
        out['id']?.toString() ??
        out['title']?.toString() ??
        'product';
    out['id'] ??= id;
    out['firebaseProductId'] = id;
    out['sellerId'] = seller.uid;
    out['sellerName'] =
        seller.shopName.isNotEmpty ? seller.shopName : seller.name;
    out['sellerAddress'] = seller.address.isNotEmpty
        ? seller.address
        : 'SmartFitao 3D Marketplace';
    return out;
  }

  static Future<Map<String, dynamic>> attachAsync(
    Map<String, dynamic> product,
  ) async {
    final seller = await resolve();
    return attach(product, seller);
  }

  static Future<List<Map<String, dynamic>>> attachAll(
    List<Map<String, dynamic>> products,
  ) async {
    final seller = await resolve();
    return products.map((p) => attach(p, seller)).toList();
  }
}
