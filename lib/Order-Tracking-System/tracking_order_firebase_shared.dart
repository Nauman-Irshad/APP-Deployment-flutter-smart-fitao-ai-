import 'package:flutter/material.dart';

import 'services/app_backend.dart';
import 'tracking.dart'
    show Order, OrderCard, OrderDetailsWidget, OrderStatus, OrderType;

/// Shared Firebase order list + detail dialog; used by [UserOrdersPageFirebase],
/// [SellerOrdersPageFirebase], and [TailorOrdersPageFirebase].
class TrackOrdersPageFirebase extends StatelessWidget {
  final String role; // user/seller/tailor
  final Color themeColor;
  final Stream<List<Order>> ordersStream;
  final String? appBarTitle;
  final List<Widget>? extraAppBarActions;

  const TrackOrdersPageFirebase({
    super.key,
    required this.role,
    required this.themeColor,
    required this.ordersStream,
    this.appBarTitle,
    this.extraAppBarActions,
  });

  Future<void> _showOrderDetails(BuildContext context, Order order) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order.id} Details'),
        content: OrderDetailsWidget(order: order, role: role),
        actions: [
          if ((order.status == OrderStatus.tailorToShip || order.status == OrderStatus.shipped) &&
              role == 'user')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await AppBackend.instance.updateOrderStatus(order.id, OrderStatus.delivered);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order marked as delivered!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Delivered'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Delivery not confirmed.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Not Delivered'),
                  ),
                ),
              ],
            ),

          if (role == 'seller') ...[
            if (order.type == OrderType.custom && order.status == OrderStatus.withSeller)
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await AppBackend.instance.updateOrderStatus(order.id, OrderStatus.shippedToTailor);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order shipped to tailor!')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Ship to Tailor'),
              ),
            if (order.type == OrderType.standard && order.status == OrderStatus.withSeller)
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await AppBackend.instance.updateOrderStatus(order.id, OrderStatus.shipped);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order shipped to customer!')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Ship to Customer'),
              ),
            if ((order.status == OrderStatus.delivered || order.status == OrderStatus.paymentReceived) &&
                !order.hasLegacyCombinedPaymentConfirm &&
                order.sellerPaymentReleasedAt == null)
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await AppBackend.instance.confirmSellerPaymentRelease(order.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Product payment confirmed. User will see product line as released.',
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not confirm: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Confirm Payment'),
              ),
          ],

          if (role == 'tailor') ...[
            if (order.status == OrderStatus.shippedToTailor)
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await AppBackend.instance.updateOrderStatus(order.id, OrderStatus.tailorDelivered);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order marked delivered to tailor!')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: const Text('Tailor Delivered'),
              ),
            if (order.status == OrderStatus.tailorDelivered)
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await AppBackend.instance.updateOrderStatus(order.id, OrderStatus.tailorStitched);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order marked as stitched!')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                child: const Text('Tailor Stitched'),
              ),
            if (order.status == OrderStatus.tailorStitched)
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await AppBackend.instance.updateOrderStatus(order.id, OrderStatus.tailorToShip);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order ready for shipping!')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Tailor to Ship'),
              ),
            if ((order.status == OrderStatus.delivered || order.status == OrderStatus.paymentReceived) &&
                order.type == OrderType.custom &&
                order.tailorStitchingTotal > 0 &&
                !order.hasLegacyCombinedPaymentConfirm &&
                order.tailorPaymentReleasedAt == null)
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await AppBackend.instance.confirmTailorPaymentRelease(order.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Tailoring payment confirmed. User will see tailoring line as released.',
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not confirm: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Confirm Payment'),
              ),
          ],

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle ?? 'Track Orders'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        actions: [
          ...?extraAppBarActions,
        ],
      ),
      body: StreamBuilder<List<Order>>(
        stream: ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Stream error: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(
              child: Text('No orders yet'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return OrderCard(
                order: order,
                onTap: () => _showOrderDetails(context, order),
                onMoreDetails: () => _showOrderDetails(context, order),
                role: role,
              );
            },
          );
        },
      ),
    );
  }
}
