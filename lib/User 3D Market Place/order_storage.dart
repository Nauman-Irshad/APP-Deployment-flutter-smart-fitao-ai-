/// Simple in-memory order storage. Orders added at checkout show on marketplace.
class OrderStorage {
  OrderStorage._();
  static final List<Map<String, dynamic>> _orders = [];

  static List<Map<String, dynamic>> get orders => List.unmodifiable(_orders);

  static int get count => _orders.length;

  static void addOrder(Map<String, dynamic> order) {
    _orders.add({
      ...order,
      'id': 'ORD${DateTime.now().millisecondsSinceEpoch}',
      'date': DateTime.now().toIso8601String(),
    });
  }

  static void clear() {
    _orders.clear();
  }
}
