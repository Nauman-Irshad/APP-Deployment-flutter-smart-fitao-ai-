import 'package:flutter/material.dart';

class ToPayScreen extends StatelessWidget {
  final List<Map<String, dynamic>> orders = [
    {'orderId': '12345', 'product': 'Designer Suit 1', 'status': 'pending_payment'},
    {'orderId': '12346', 'product': 'Designer Suit 2', 'status': 'paid'},
    {'orderId': '12347', 'product': 'Designer Suit 3', 'status': 'pending_payment'},
  ];

  @override
  Widget build(BuildContext context) {
    final pendingPayments = orders.where((order) => order['status'] == 'pending_payment').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'To Pay',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: pendingPayments.isEmpty
          ? const Center(
              child: Text(
                'Your order list is empty',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: pendingPayments.length,
              itemBuilder: (context, index) {
                final order = pendingPayments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.payment, color: Colors.deepPurple),
                    title: Text('Order ID: ${order['orderId']}'),
                    subtitle: Text('Product: ${order['product']}'),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payment functionality coming soon!')),
                        );
                      },
                      child: const Text('Pay Now'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}