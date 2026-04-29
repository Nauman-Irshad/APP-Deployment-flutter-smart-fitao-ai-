import 'package:flutter/material.dart';

class TailorDeliveredScreen extends StatelessWidget {
  final List<Map<String, dynamic>> tailorOrders = [
    {'orderId': '12345', 'product': 'Designer Suit 1', 'status': 'stitched'},
    {'orderId': '12346', 'product': 'Designer Suit 2', 'status': 'in_progress'},
    {'orderId': '12347', 'product': 'Designer Suit 3', 'status': 'stitched'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tailor Delivered',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: tailorOrders.isEmpty
          ? const Center(
              child: Text(
                'No tailoring orders yet',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: tailorOrders.length,
              itemBuilder: (context, index) {
                final order = tailorOrders[index];
                final status = order['status'] as String;
                final isStitched = status == 'stitched';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(
                      isStitched ? Icons.check_circle : Icons.hourglass_top,
                      color: isStitched ? Colors.green : Colors.orange,
                      size: 30,
                    ),
                    title: Text('Order ID: ${order['orderId']}'),
                    subtitle: Text('Product: ${order['product']}'),
                    trailing: Text(
                      isStitched ? 'Stitched' : 'In Progress',
                      style: TextStyle(
                        color: isStitched ? Colors.green : Colors.orange,
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