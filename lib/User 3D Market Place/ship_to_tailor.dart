import 'package:flutter/material.dart';

class ShipToTailorScreen extends StatelessWidget {
  final List<Map<String, dynamic>> shipments = [
    {'orderId': '12345', 'product': 'Designer Suit 1', 'status': 'delivered'},
    {'orderId': '12346', 'product': 'Designer Suit 2', 'status': 'in_transit'},
    {'orderId': '12347', 'product': 'Designer Suit 3', 'status': 'delivered'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ship to Tailor',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: shipments.isEmpty
          ? const Center(
              child: Text(
                'No shipments yet',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: shipments.length,
              itemBuilder: (context, index) {
                final shipment = shipments[index];
                final status = shipment['status'] as String;
                final isDelivered = status == 'delivered';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      isDelivered ? Icons.check_circle : Icons.local_shipping,
                      color: isDelivered ? Colors.green : Colors.orange,
                      size: 30,
                    ),
                    title: Text('Order ID: ${shipment['orderId']}'),
                    subtitle: Text('Product: ${shipment['product']}'),
                    trailing: Text(
                      isDelivered ? 'Delivered' : 'In Transit',
                      style: TextStyle(
                        color: isDelivered ? Colors.green : Colors.orange,
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