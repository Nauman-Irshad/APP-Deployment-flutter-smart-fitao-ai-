import 'package:shared_preferences/shared_preferences.dart';

class OrderTrackingService {
  static const String _prefixKey = 'order_tracking_';

  static Future<int> getStatusCount(String status) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_prefixKey$status') ?? 0;
  }

  static Future<void> setStatusCount(String status, int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefixKey$status', count);
  }

  static Future<Map<String, int>> getAllCounts() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'seller_to_tailor': prefs.getInt('${_prefixKey}seller_to_tailor') ?? 0,
      'tailor_delivered': prefs.getInt('${_prefixKey}tailor_delivered') ?? 0,
      'tailor_ready': prefs.getInt('${_prefixKey}tailor_ready') ?? 0,
      'tailor_to_ship': prefs.getInt('${_prefixKey}tailor_to_ship') ?? 0,
      'delivered': prefs.getInt('${_prefixKey}delivered') ?? 0,
      'cancelled': prefs.getInt('${_prefixKey}cancelled') ?? 0,
    };
  }

  static Future<void> syncCountsFromFirebase(
    Map<String, int> firebaseStatusCounts,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    for (var entry in firebaseStatusCounts.entries) {
      await prefs.setInt('$_prefixKey${entry.key}', entry.value);
    }
  }

  static Future<void> incrementStatusCount(String status) async {
    final current = await getStatusCount(status);
    await setStatusCount(status, current + 1);
  }

  static Future<void> clearCounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_prefixKey}seller_to_tailor');
    await prefs.remove('${_prefixKey}tailor_delivered');
    await prefs.remove('${_prefixKey}tailor_ready');
    await prefs.remove('${_prefixKey}tailor_to_ship');
    await prefs.remove('${_prefixKey}delivered');
    await prefs.remove('${_prefixKey}cancelled');
  }
}
