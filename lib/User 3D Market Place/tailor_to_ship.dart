import 'package:flutter/material.dart';

class TailorToShipScreen extends StatelessWidget {
  final List<Map<String, dynamic>> shippingOrders = [
    {'orderId': '12345', 'product': 'Designer Suit 1', 'courier': 'TCS', 'trackingId': 'TCS987654321', 'status': 'in_transit'},
    {'orderId': '12346', 'product': 'Designer Suit 2', 'courier': 'FedEx', 'trackingId': 'FDX123456789', 'status': 'delivered'},
    {'orderId': '12347', 'product': 'Designer Suit 3', 'courier': 'DHL', 'trackingId': 'DHL112233445', 'status': 'pending_pickup'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tailor To Ship',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: shippingOrders.isEmpty
          ? const Center(
              child: Text(
                'No shipping orders yet',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: shippingOrders.length,
              itemBuilder: (context, index) {
                final order = shippingOrders[index];
                final status = order['status'] as String;

                Color statusColor;
                String statusText;

                switch (status) {
                  case 'pending_pickup':
                    statusText = 'Pending Pickup';
                    statusColor = Colors.orange;
                    break;
                  case 'in_transit':
                    statusText = 'In Transit';
                    statusColor = Colors.blue;
                    break;
                  case 'delivered':
                    statusText = 'Delivered';
                    statusColor = Colors.green;
                    break;
                  default:
                    statusText = 'Unknown';
                    statusColor = Colors.grey;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      status == 'delivered' ? Icons.check_circle : Icons.local_shipping,
                      color: statusColor,
                      size: 30,
                    ),
                    title: Text('Order ID: ${order['orderId']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Product: ${order['product']}'),
                        Text('Courier: ${order['courier']}'),
                        Text('Tracking ID: ${order['trackingId']}'),
                      ],
                    ),
                    trailing: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}