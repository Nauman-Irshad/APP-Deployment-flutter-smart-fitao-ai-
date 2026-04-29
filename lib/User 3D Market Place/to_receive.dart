import 'package:flutter/material.dart';

class ToReceiveScreen extends StatefulWidget {
  @override
  _ToReceiveScreenState createState() => _ToReceiveScreenState();
}

class _ToReceiveScreenState extends State<ToReceiveScreen> {
  final List<Map<String, dynamic>> orders = [
    {'orderId': '12345', 'product': 'Designer Suit 1', 'status': 'delivered', 'canReturn': true},
    {'orderId': '12346', 'product': 'Designer Suit 2', 'status': 'in_transit', 'canReturn': false},
    {'orderId': '12347', 'product': 'Designer Suit 3', 'status': 'failed_delivery', 'canReturn': false},
  ];

  final Map<String, TextEditingController> returnControllers = {};

  @override
  void initState() {
    super.initState();

    for (var order in orders) {
      returnControllers[order['orderId']] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in returnControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingOrders = orders.where((o) => o['status'] != 'delivered').toList();
    final deliveredOrders = orders.where((o) => o['status'] == 'delivered').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('To Receive', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
      ),
      body: orders.isEmpty
          ? const Center(
              child: Text(
                'Your order list is empty',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...pendingOrders.map((order) {
                  String statusText;
                  Color statusColor;

                  switch (order['status']) {
                    case 'in_transit':
                      statusText = 'In Transit';
                      statusColor = Colors.blue;
                      break;
                    case 'failed_delivery':
                      statusText = 'Delivery Failed';
                      statusColor = Colors.red;
                      break;
                    default:
                      statusText = 'Pending';
                      statusColor = Colors.orange;
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(Icons.local_shipping, color: statusColor, size: 30),
                      title: Text('Order ID: ${order['orderId']}'),
                      subtitle: Text('Product: ${order['product']}'),
                      trailing: Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }),
                ...deliveredOrders.map((order) {
                  final controller = returnControllers[order['orderId']]!;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order ID: ${order['orderId']}', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Product: ${order['product']}'),
                          const SizedBox(height: 8),
                          Text('Status: Delivered', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          if (order['canReturn']) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                labelText: 'Reason for Return',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                final reason = controller.text.trim();
                                if (reason.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a reason')));
                                  return;
                                }

                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Return submitted for Order ${order['orderId']}')));
                                controller.clear();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                              ),
                              child: const Text('Submit Return'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}