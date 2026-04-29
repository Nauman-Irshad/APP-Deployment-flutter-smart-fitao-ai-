import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'user_app_order.dart';
import 'order_tracking_service.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> product;
  /// Optional customer information passed from the previous page.
  final String? userName;
  final String? address;
  final double? reducedPrice;

  const CheckoutPage({
    required this.product,
    this.userName,
    this.address,
    this.reducedPrice,
    super.key,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _quantity = 1;
  bool _isLoading = false;

  double get totalPrice =>
      (widget.product['price'] as num).toDouble() * _quantity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Color(0xFF059669),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Product Summary
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Summary',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          widget.product['image'] ?? 'assets/1.webp',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product['title'] ?? 'Product',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'PKR ${widget.product['price']}',
                              style: TextStyle(
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            // Quantity Selection
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quantity',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        icon: Icon(Icons.remove_circle),
                        color: Color(0xFF059669),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _quantity.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _quantity < 10
                            ? () => setState(() => _quantity++)
                            : null,
                        icon: Icon(Icons.add_circle),
                        color: Color(0xFF059669),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            // Price Breakdown
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPriceRow(
                    'Subtotal',
                    'PKR ${(widget.product['price'] * _quantity).toStringAsFixed(0)}',
                  ),
                  Divider(),
                  _buildPriceRow(
                    'Shipping',
                    'Free',
                    isShipping: true,
                  ),
                  Divider(),
                  _buildPriceRow(
                    'Total',
                    'PKR ${totalPrice.toStringAsFixed(0)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        color: Colors.white,
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF059669),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Place Order',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isShipping = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isShipping ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _isLoading = true);

    try {
      // Simulating user ID - in real app, get from Firebase Auth
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';

      // tell user we're attempting to send to Firebase
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sending order to Firebase...'),
          backgroundColor: Colors.blue,
        ),
      );

      try {
        final orderId = await FirebaseService.placeOrder(
          userId: userId,
          productId: widget.product['id'].toString(),
          productTitle: widget.product['title'],
          quantity: _quantity,
          price: (widget.product['price'] as num).toDouble(),
          category: widget.product['category'],
          productImage: widget.product['image'],
          status: 'sent',
          userName: widget.userName,
          address: widget.address,
          reducedPrice: widget.reducedPrice,
        );

          // Increment tracking count for 'sent' status
          try {
            await OrderTrackingService.incrementStatusCount('sent');
          } catch (e) {
            print('Error incrementing tracking count: $e');
          }
        try {
          final map = <String, dynamic>{
            'userId': userId,
            'productId': widget.product['id'].toString(),
            'productTitle': widget.product['title'],
            'quantity': _quantity,
            'unitPrice': (widget.product['price'] as num).toDouble(),
            'totalPrice': totalPrice,
            'category': widget.product['category'] ?? '',
            'productImage': widget.product['image'] ?? '',
            'status': 'sent',
          };
          if (widget.userName != null) map['userName'] = widget.userName;
          if (widget.address != null) map['address'] = widget.address;
          if (widget.reducedPrice != null) map['reducedPrice'] = widget.reducedPrice;

          await UserAppOrder.create(map);
        } catch (e) {
          print('Error writing to user_app_order: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order sent to Firebase! ID: $orderId'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back after 2 seconds
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            }
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending order to Firebase: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
