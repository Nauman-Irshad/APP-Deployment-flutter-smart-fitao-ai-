import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/demo_accounts.dart';
import '../2d_try_on_app/try_on_order_session.dart';
import '../User 3D Market Place/size prediction model/cloth_studio_bridge.dart';
import 'customer_fitting_store_stub.dart'
    if (dart.library.html) 'customer_fitting_store_web.dart';

const _keyGuestId = 'smartfitao_guest_customer_id';
const _keyDisplayName = 'smartfitao_customer_display_name';
const _keySelectedProduct = 'smartfitao_selected_marketplace_product';

/// Remembers 3D marketplace product + AI size for tailor chat (local + session).
class CustomerFittingStore {
  CustomerFittingStore._();

  static Future<String> guestOrUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) return user.uid;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_keyGuestId);
    if (id == null || id.isEmpty) {
      id = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString(_keyGuestId, id);
    }
    return id;
  }

  static Future<String> customerDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final email = user.email?.trim().toLowerCase() ?? '';
      if (email == DemoAccounts.customerEmail) {
        return DemoAccounts.customerName;
      }
      return user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : (user.email?.split('@').first ?? DemoAccounts.customerName);
    }
    final prefs = await SharedPreferences.getInstance();
    var name = prefs.getString(_keyDisplayName);
    if (name == null || name.trim().isEmpty) {
      name = DemoAccounts.customerName;
      await prefs.setString(_keyDisplayName, name);
    }
    return name;
  }

  /// Call when user opens a product on 3D marketplace (e.g. Black kurta).
  static Future<void> saveSelectedProduct(Map<String, dynamic> product) async {
    final map = <String, dynamic>{
      'id': product['id']?.toString() ?? '',
      'title': product['title']?.toString() ?? 'Product',
      'colorName': product['colorName']?.toString() ?? '',
      'price': (product['price'] as num?)?.toInt() ??
          int.tryParse('${product['price']}') ??
          0,
      'category': product['category']?.toString() ?? '',
      'imagePath': product['imagePath']?.toString() ?? '',
      'modelPath': product['modelPath']?.toString() ?? '',
      'section': product['section']?.toString() ?? '',
      'savedAt': DateTime.now().toIso8601String(),
    };
    final encoded = jsonEncode(map);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedProduct, encoded);
    if (kIsWeb) webWriteProductJson(encoded);

    TryOnOrderSession.instance.applyMarketplaceProduct(
      productId: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Product',
      colorName: map['colorName']?.toString() ?? '',
      pricePkr: (map['price'] as num?)?.toInt() ?? 3590,
      imagePath: map['imagePath']?.toString() ?? '',
      modelPath: map['modelPath']?.toString() ?? '',
    );
  }

  static Future<Map<String, dynamic>?> loadSelectedProduct() async {
    if (kIsWeb) {
      final webRaw = webReadProductJson();
      if (webRaw != null && webRaw.isNotEmpty) {
        try {
          final m = jsonDecode(webRaw);
          if (m is Map<String, dynamic>) return m;
          if (m is Map) return Map<String, dynamic>.from(m);
        } catch (_) {}
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySelectedProduct);
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw);
      if (m is Map<String, dynamic>) return m;
      if (m is Map) return Map<String, dynamic>.from(m);
    } catch (_) {}
    return null;
  }

  /// Loads `snapmeasure_last_fit` + sessionStorage measurements into session.
  static void webPersistLastFitJson(String json) {
    if (kIsWeb) webWriteLastFitJson(json);
  }

  static void webPersistMeasurementsJson(String json) {
    if (kIsWeb) webWriteMeasurementsJson(json);
  }

  static Future<void> applySavedSizeToSession() async {
    String? raw;
    if (kIsWeb) {
      raw = webReadLastFitJson();
    }
    raw ??= (await SharedPreferences.getInstance()).getString(clothStorageKeyLastFit);
    if (raw != null && raw.isNotEmpty) {
      try {
        final m = jsonDecode(raw);
        if (m is Map) {
          final cmRaw = m['measurementsCm'];
          if (cmRaw is Map) {
            final cm = <String, double>{};
            cmRaw.forEach((k, v) {
              if (v is num) {
                final key = _normalizeMeasureKey(k.toString());
                cm[key] = v.toDouble();
              }
            });
            if (cm.isNotEmpty) {
              TryOnOrderSession.instance.applyMeasurements(cm);
            }
          }
        }
      } catch (_) {}
    }
  }

  static Future<void> syncSessionFromLocal() async {
    await applySavedSizeToSession();
    final product = await loadSelectedProduct();
    if (product != null) {
      TryOnOrderSession.instance.applyMarketplaceProduct(
        productId: product['id']?.toString() ?? '',
        title: product['title']?.toString() ?? 'Product',
        colorName: product['colorName']?.toString() ?? '',
        pricePkr: (product['price'] as num?)?.toInt() ?? 3590,
        imagePath: product['imagePath']?.toString() ?? '',
        modelPath: product['modelPath']?.toString() ?? '',
      );
    }
  }

  static String _normalizeMeasureKey(String k) {
    final lower = k.toLowerCase();
    if (lower == 'chest') return 'Chest';
    if (lower == 'waist') return 'Waist';
    if (lower.contains('kurta') && lower.contains('length')) {
      return 'Kurta length';
    }
    return k;
  }

  static String productLineForChat(Map<String, dynamic> product) {
    final title = product['title']?.toString() ?? 'Product';
    final color = product['colorName']?.toString() ?? '';
    final price = (product['price'] as num?)?.toInt() ?? 0;
    final size = TryOnOrderSession.instance.predictedSizeLabel;
    final colorPart = color.isNotEmpty ? ' · $color' : '';
    return '$title$colorPart — PKR $price · Size $size';
  }

  /// 3D marketplace pick (SharedPreferences) first; never the 2D try-on file name "12".
  static Future<Map<String, dynamic>> resolvedProductForChat() async {
    await applySavedSizeToSession();
    final saved = await loadSelectedProduct();
    if (saved != null) {
      final title = saved['title']?.toString() ?? '';
      if (title.isNotEmpty && !looksLikeTryOnFileName(title)) {
        TryOnOrderSession.instance.applyMarketplaceProduct(
          productId: saved['id']?.toString() ?? '',
          title: title,
          colorName: saved['colorName']?.toString() ?? '',
          pricePkr: (saved['price'] as num?)?.toInt() ?? 3590,
          imagePath: saved['imagePath']?.toString() ?? '',
          modelPath: saved['modelPath']?.toString() ?? '',
        );
        return saved;
      }
    }
    final fromSession = TryOnOrderSession.instance.marketplaceProductMap();
    if (fromSession.isNotEmpty) {
      final title = fromSession['title']?.toString() ?? '';
      if (title.isNotEmpty && !looksLikeTryOnFileName(title)) {
        return fromSession;
      }
    }
    return saved ?? fromSession;
  }

  static bool looksLikeTryOnFileName(String title) {
    final t = title.trim();
    if (RegExp(r'^\d+$').hasMatch(t)) return true;
    if (RegExp(r'^\d+\.(png|jpg|jpeg|webp)$', caseSensitive: false).hasMatch(t)) {
      return true;
    }
    return false;
  }
}
