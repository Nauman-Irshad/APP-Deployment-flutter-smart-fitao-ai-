import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'seller_service.dart';

class OrdersPage extends StatefulWidget {
  final String? initialFilter;

  const OrdersPage({super.key, this.initialFilter});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter ?? 'All';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: Color(0xFF059669),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter buttons
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                _buildFilterButton('All', 'All'),
                SizedBox(width: 8),
                _buildFilterButton('Pending', 'Pending'),
                SizedBox(width: 8),
                _buildFilterButton('Shipped', 'Shipped'),
                SizedBox(width: 8),
                _buildFilterButton('Delivered', 'Delivered'),
              ],
            ),
          ),
          // Orders list
          Expanded(
            child: _getOrdersStream(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Color(0xFF059669),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _getOrdersStream() {
    Stream<QuerySnapshot> stream;

    switch (_selectedFilter) {
      case 'Pending':
        stream = SellerService.getPendingOrders();
        break;
      case 'Shipped':
        stream = SellerService.getShippedOrders();
        break;
      case 'Delivered':
        stream = SellerService.getDeliveredOrders();
        break;
      default:
        stream = SellerService.getSellerOrders();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined,
                    size: 48, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text('No orders yet',
                    style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(12),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final order = snapshot.data!.docs[index];
            final orderData = order.data() as Map<String, dynamic>;
            final orderId = order.id;

            return GestureDetector(
              onTap: () => _showOrderDetails(context, orderData, orderId),
              child: _buildOrderCard(orderData, orderId),
            );
          },
        );
      },
    );
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> orderData, String orderId) {
    final productTitle = orderData['productTitle'] ?? orderData['productName'] ?? 'Product';
    final sellerName = orderData['sellerName'] ?? '–';
    final customerName = orderData['customerName'] ?? '–';
    final deliveryAddress = orderData['deliveryAddress'] ?? orderData['customerAddress'] ?? '–';
    final totalPrice = (orderData['totalPrice'] ?? 0) is int
        ? (orderData['totalPrice'] as int).toDouble()
        : (orderData['totalPrice'] as num?)?.toDouble() ?? 0.0;
    final kurtaSize = orderData['kurtaSize'] ?? '–';
    final pyjamaSize = orderData['pyjamaSize'] ?? '–';
    final pyjamaLength = orderData['pyjamaLength'] ?? '–';
    final kurtaMeasurements = orderData['kurtaMeasurements'] is Map
        ? Map<String, String>.from(orderData['kurtaMeasurements'] as Map)
        : <String, String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Order #${orderId.length >= 8 ? orderId.substring(0, 8) : orderId}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _detailRow('Product name', productTitle),
                    _detailRow('Seller name', sellerName),
                    _detailRow('Customer name', customerName),
                    _detailRow('Delivery address', deliveryAddress),
                    _detailRow('Total amount', 'PKR ${totalPrice.toStringAsFixed(0)}'),
                    SizedBox(height: 12),
                    Text('Cloth size chart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    _detailRow('Kurta size', kurtaSize),
                    _detailRow('Pyjama size', pyjamaSize),
                    _detailRow('Pyjama length', pyjamaLength),
                    ...kurtaMeasurements.entries.map((e) => _detailRow(e.key, e.value)),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text('$label:', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> orderData, String orderId) {
    final status = orderData['status'] ?? 'pending';
    final timestamp = orderData['createdAt'] as Timestamp?;
    final date = timestamp?.toDate() ?? DateTime.now();

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Order ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${orderId.substring(0, 8)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                _buildStatusBadge(status),
              ],
            ),
            SizedBox(height: 8),
            Divider(height: 1),
            SizedBox(height: 8),
            // Product info
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    orderData['productImage'] ?? 'assets/1.webp',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderData['productTitle'] ?? 'Product',
                        style: TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Qty: ${orderData['quantity'] ?? 1}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Divider(height: 1),
            SizedBox(height: 8),
            // Price and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Price',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text(
                      'PKR ${(orderData['totalPrice'] ?? 0).toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Order Date',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            // Action buttons
            if (status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _updateOrderStatus(orderId, 'shipped'),
                      child: Text('Mark Shipped'),
                    ),
                  ),
                ],
              )
            else if (status == 'shipped')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _updateOrderStatus(orderId, 'delivered'),
                      child: Text('Mark Delivered'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor = Colors.white;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = Colors.orange;
        label = 'Pending';
        break;
      case 'shipped':
        bgColor = Colors.blue;
        label = 'Shipped';
        break;
      case 'delivered':
        bgColor = Colors.green;
        label = 'Delivered';
        break;
      case 'cancelled':
        bgColor = Colors.red;
        label = 'Cancelled';
        break;
      default:
        bgColor = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
