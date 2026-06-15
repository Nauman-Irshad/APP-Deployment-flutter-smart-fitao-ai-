import 'package:flutter/material.dart';

import '../User 3D Market Place/database/firebase_service.dart';
import '../User 3D Market Place/database/order_tracking_service.dart';
import '../User 3D Market Place/database/user_app_order.dart';
import '../User 3D Market Place/marketplace_bottom_nav.dart';
import '../User 3D Market Place/shopping_cart.dart';
import 'stripe_pending_checkout.dart';

/// After Stripe payment, place the order in Firebase (same as checkout page).
class CheckoutOrderCompletion {
  CheckoutOrderCompletion._();

  static Future<String?> completeFromPending(
    BuildContext context,
    StripePendingCheckout pending,
  ) async {
    try {
      final orderId = await FirebaseService.placeOrder(
        userId: pending.userId,
        productId: pending.productId,
        productTitle: pending.productTitle,
        quantity: pending.quantity,
        price: pending.unitPrice,
        category: pending.category,
        productImage: pending.productImage,
        status: 'sent',
        userName: pending.userName,
        address: pending.address,
        reducedPrice: pending.reducedPrice ?? pending.totalPkr.toDouble(),
      );

      try {
        await OrderTrackingService.incrementStatusCount('sent');
      } catch (e) {
        debugPrint('Error incrementing tracking count: $e');
      }

      try {
        final map = <String, dynamic>{
          'userId': pending.userId,
          'productId': pending.productId,
          'productTitle': pending.productTitle,
          'quantity': pending.quantity,
          'unitPrice': pending.unitPrice,
          'totalPrice': pending.totalPkr.toDouble(),
          'category': pending.category,
          'productImage': pending.productImage,
          'status': 'sent',
          'paymentMethod': 'stripe',
        };
        if (pending.userName != null) map['userName'] = pending.userName;
        if (pending.address != null) map['address'] = pending.address;
        map['reducedPrice'] =
            pending.reducedPrice ?? pending.totalPkr.toDouble();

        await UserAppOrder.create(map);
      } catch (e) {
        debugPrint('Error writing to user_app_order: $e');
      }

      await StripePendingCheckout.clear();
      ShoppingCart.instance.clear();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment received. Order placed! ID: $orderId'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            MarketplaceBottomNav.goToTab(context, 0);
          }
        });
      }
      return orderId;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment OK but order failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }
}
