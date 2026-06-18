import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/navigation/app_navigation.dart';
import '../Order-Tracking-System/services/app_backend.dart';
import '../Order-Tracking-System/tracking.dart' show OrderType;
import '../User 3D Market Place/database/order_tracking_service.dart';
import '../User 3D Market Place/shopping_cart.dart';
import '../services/marketplace_demo_seller.dart';

/// Places a real Firestore order (seller profit + tracking) without Stripe — for demos.
class DemoOrderPlacement {
  DemoOrderPlacement._();

  static Future<String?> placeAndGoHome({
    required BuildContext context,
    required Map<String, dynamic> product,
    required OrderType orderType,
    required Map<String, dynamic> details,
    int quantity = 1,
    double? unitPrice,
    AppUserProfile? tailor,
    String? deliveryAddress,
    String? customerName,
    double tailorStitchingTotal = 0,
    double precomputedTailorProfitTotal = 0,
    bool clearCart = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to place a demo order')),
        );
      }
      return null;
    }

    final seller = await MarketplaceDemoSeller.resolve();
    final enriched = MarketplaceDemoSeller.attach(product, seller);
    final productId = enriched['firebaseProductId']?.toString() ?? '';

    if (enriched['outOfStock'] == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This product is out of stock')),
        );
      }
      return null;
    }

    final backend = AppBackend.instance;
    AppUserProfile profile;
    try {
      profile = await backend.getUserProfile(user.uid);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load profile: $e')),
        );
      }
      return null;
    }

    final resolvedName = (customerName?.trim().isNotEmpty == true)
        ? customerName!.trim()
        : (profile.name.isNotEmpty ? profile.name : (user.displayName ?? 'Customer'));
    final resolvedAddress = (deliveryAddress?.trim().isNotEmpty == true)
        ? deliveryAddress!.trim()
        : profile.address;

    final price = unitPrice ??
        (enriched['price'] is num
            ? (enriched['price'] as num).toDouble()
            : double.tryParse(enriched['price']?.toString() ?? '0') ?? 0.0);

    final productName = enriched['title']?.toString() ?? 'Product';
    final safeDetails = Map<String, dynamic>.from(details)
      ..['paymentMethod'] = 'demo'
      ..['demoOrder'] = true;

    String? tailorId;
    String? tailorName;
    String tailorAddress = '';
    if (tailor != null) {
      tailorId = tailor.uid;
      tailorName = tailor.shopName.isNotEmpty
          ? '${tailor.shopName} (${tailor.name})'
          : tailor.name;
      tailorAddress = tailor.address;
    }

    try {
      final customerEmail =
          user.email?.trim() ?? profile.email.trim();
      final orderId = await backend.createOrder(
        customerId: profile.uid,
        customerName: resolvedName,
        customerEmail: customerEmail.isNotEmpty ? customerEmail : null,
        productId: productId.isNotEmpty ? productId : 'marketplace_item',
        productName: productName,
        totalAmount: price,
        quantity: quantity,
        type: orderType,
        details: safeDetails,
        sellerId: seller.uid,
        sellerName: enriched['sellerName']?.toString() ?? seller.shopName,
        sellerAddress: enriched['sellerAddress']?.toString() ?? seller.address,
        tailorId: tailorId,
        tailorName: tailorName,
        tailorAddress: tailorAddress,
        deliveryAddress: resolvedAddress,
        tailorStitchingTotal: tailorStitchingTotal,
        precomputedTailorProfitTotal: precomputedTailorProfitTotal,
      );

      try {
        await OrderTrackingService.incrementStatusCount('seller_to_tailor');
      } catch (e) {
        debugPrint('demo order tracking count: $e');
      }

      if (clearCart) {
        ShoppingCart.instance.clear();
      }

      if (!context.mounted) return orderId;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demo order placed · ID $orderId'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
      AppNavigation.popToMarketplaceHome(context);
      return orderId;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demo order failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }
}
