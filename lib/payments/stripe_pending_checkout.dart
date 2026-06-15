import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'stripe_pending_checkout_stub.dart'
    if (dart.library.html) 'stripe_pending_checkout_web.dart' as web_store;

const _storageKey = 'smartfitao_pending_stripe_checkout';

/// Persists order fields between Stripe redirect and app return.
class StripePendingCheckout {
  StripePendingCheckout({
    required this.userId,
    required this.productId,
    required this.productTitle,
    required this.quantity,
    required this.unitPrice,
    required this.totalPkr,
    required this.category,
    required this.productImage,
    this.userName,
    this.address,
    this.reducedPrice,
  });

  final String userId;
  final String productId;
  final String productTitle;
  final int quantity;
  final double unitPrice;
  final int totalPkr;
  final String category;
  final String productImage;
  final String? userName;
  final String? address;
  final double? reducedPrice;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'productId': productId,
        'productTitle': productTitle,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalPkr': totalPkr,
        'category': category,
        'productImage': productImage,
        if (userName != null) 'userName': userName,
        if (address != null) 'address': address,
        if (reducedPrice != null) 'reducedPrice': reducedPrice,
      };

  static StripePendingCheckout? fromJson(Map<String, dynamic> json) {
    try {
      return StripePendingCheckout(
        userId: json['userId']?.toString() ?? '',
        productId: json['productId']?.toString() ?? '',
        productTitle: json['productTitle']?.toString() ?? 'Order',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        totalPkr: (json['totalPkr'] as num?)?.toInt() ?? 0,
        category: json['category']?.toString() ?? 'General',
        productImage: json['productImage']?.toString() ?? '',
        userName: json['userName']?.toString(),
        address: json['address']?.toString(),
        reducedPrice: (json['reducedPrice'] as num?)?.toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(StripePendingCheckout pending) async {
    final json = jsonEncode(pending.toJson());
    if (kIsWeb) web_store.webSavePendingCheckout(json);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json);
  }

  static Future<StripePendingCheckout?> load() async {
    String? raw;
    if (kIsWeb) raw = web_store.webLoadPendingCheckout();
    if (raw == null || raw.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      raw = prefs.getString(_storageKey);
    }
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    if (kIsWeb) web_store.webClearPendingCheckout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
