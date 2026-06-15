import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../tracking.dart' as tracking;

class AppUserProfile {
  final String uid;
  final String name;
  final String email;
  final String role; // user / seller / tailor
  final String shopName; // for seller/tailor
  final String address; // for user/seller/tailor
  final bool available; // for tailor
  /// PKR per unit (per quantity) for stitching; tailors must set > 0 to appear for custom orders.
  final double stitchingRate;
  /// PKR profit per unit for tailor dashboard only (not shown to customers).
  final double tailorProfitPerUnit;

  AppUserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.shopName,
    required this.address,
    required this.available,
    this.stitchingRate = 0,
    this.tailorProfitPerUnit = 0,
  });
}

class ProductModel {
  final String id;
  final String name;
  final double price;
  final double discountPercent;
  final tracking.OrderType type;
  final String sellerId;
  final String sellerName;
  final String sellerAddress;
  final Map<String, dynamic> details;
  /// Units in stock. Legacy docs without this field are treated as high stock.
  final int stockQuantity;
  /// When true, listing is inactive (seller “Out of stock”); not purchasable.
  final bool isOutOfStock;
  /// PKR profit per unit for seller analytics only (not exposed on marketplace).
  final double profitPerUnit;
  /// Listed on user 3D landing / marketplace grid.
  final bool showOnLanding;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.discountPercent,
    required this.type,
    required this.sellerId,
    required this.sellerName,
    required this.sellerAddress,
    required this.details,
    this.stockQuantity = 999999,
    this.isOutOfStock = false,
    this.profitPerUnit = 0,
    this.showOnLanding = true,
  });

  bool get isPurchasable => !isOutOfStock && stockQuantity > 0;
}

/// One row for "Product wise sales" on the seller dashboard.
class SellerProductSalesRow {
  final String productId;
  final String productName;
  final int orderCount;
  final double totalSalesPkr;

  const SellerProductSalesRow({
    required this.productId,
    required this.productName,
    required this.orderCount,
    required this.totalSalesPkr,
  });
}

/// Real-time aggregates for seller Business Advisor + product table.
class SellerAnalyticsSnapshot {
  /// Period totals: keys `Day`, `Week`, `Month` — sum of line sales / profit in that window.
  final Map<String, double> totalSalesByPeriod;
  final Map<String, double> totalProfitByPeriod;
  /// Seven bucket values for charts (x = 0..6).
  final Map<String, List<double>> salesBucketsByPeriod;
  final Map<String, List<double>> profitBucketsByPeriod;
  final List<SellerProductSalesRow> productSales;
  final Map<String, int> orderStatusCounts;

  const SellerAnalyticsSnapshot({
    required this.totalSalesByPeriod,
    required this.totalProfitByPeriod,
    required this.salesBucketsByPeriod,
    required this.profitBucketsByPeriod,
    required this.productSales,
    required this.orderStatusCounts,
  });

  static SellerAnalyticsSnapshot empty() {
    const z = ['Day', 'Week', 'Month'];
    final zeroBuckets = List<double>.filled(7, 0);
    return SellerAnalyticsSnapshot(
      totalSalesByPeriod: {for (final k in z) k: 0},
      totalProfitByPeriod: {for (final k in z) k: 0},
      salesBucketsByPeriod: {for (final k in z) k: List<double>.from(zeroBuckets)},
      profitBucketsByPeriod: {for (final k in z) k: List<double>.from(zeroBuckets)},
      productSales: const [],
      orderStatusCounts: const {
        'pending': 0,
        'shipped': 0,
        'completed': 0,
        'cancelled': 0,
        'other': 0,
      },
    );
  }
}

/// Live tailor dashboard: earnings when `tailorPaymentReleasedAt` is set; order counts by `createdAt` vs release.
class TailorDashboardSnapshot {
  final Map<String, double> totalSalesByPeriod;
  final Map<String, double> totalProfitByPeriod;
  final Map<String, List<double>> earningsSalesBuckets;
  final Map<String, List<double>> earningsProfitBuckets;
  final List<SellerProductSalesRow> productSales;
  final Map<String, List<double>> ordersTotalBuckets;
  final Map<String, List<double>> ordersCompletedBuckets;

  const TailorDashboardSnapshot({
    required this.totalSalesByPeriod,
    required this.totalProfitByPeriod,
    required this.earningsSalesBuckets,
    required this.earningsProfitBuckets,
    required this.productSales,
    required this.ordersTotalBuckets,
    required this.ordersCompletedBuckets,
  });

  static TailorDashboardSnapshot empty() {
    const z = ['Day', 'Week', 'Month'];
    final zb = List<double>.filled(7, 0);
    return TailorDashboardSnapshot(
      totalSalesByPeriod: {for (final k in z) k: 0},
      totalProfitByPeriod: {for (final k in z) k: 0},
      earningsSalesBuckets: {for (final k in z) k: List<double>.from(zb)},
      earningsProfitBuckets: {for (final k in z) k: List<double>.from(zb)},
      productSales: const [],
      ordersTotalBuckets: {for (final k in z) k: List<double>.from(zb)},
      ordersCompletedBuckets: {for (final k in z) k: List<double>.from(zb)},
    );
  }
}

class AppBackend {
  AppBackend._();
  static final AppBackend instance = AppBackend._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _asString(dynamic v) => v?.toString() ?? '';

  String _normalizeMarketplaceSection(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return s;
    final lower = s.toLowerCase();
    if (lower == 'kurta shalwar' ||
        lower == 'kurta pajama' ||
        lower == 'kurtaz pajama' ||
        lower == 'kurtaz shalwar' ||
        lower.contains('kurta')) {
      return 'Kurta Shalwar';
    }
    if (lower == 'shalwar kameez' || lower.contains('shalwar kameez')) {
      return 'Shalwar Kameez';
    }
    if (lower == 'fabric') return 'Fabric';
    return s;
  }

  bool _asBool(dynamic v) => v is bool ? v : (v?.toString().toLowerCase() == 'true');

  Map<String, dynamic> _asStringMap(dynamic v) {
    if (v is Map) {
      return v.map((key, value) => MapEntry(key.toString(), value));
    }
    return const <String, dynamic>{};
  }

  /// Web-safe nested maps for `orders.details` (marketplace maps may contain types JS cannot encode).
  Map<String, dynamic> _sanitizeOrderDetails(Map<String, dynamic> raw) {
    dynamic walk(dynamic v) {
      if (v == null) return null;
      if (v is String || v is num || v is bool) return v;
      if (v is DateTime) return Timestamp.fromDate(v);
      if (v is Timestamp) return v;
      if (v is Map) {
        final m = <String, dynamic>{};
        v.forEach((key, val) {
          m[key.toString()] = walk(val);
        });
        return m;
      }
      if (v is Iterable) {
        return v.map(walk).toList();
      }
      return v.toString();
    }

    final out = walk(raw);
    if (out is Map<String, dynamic>) return out;
    return <String, dynamic>{'value': out.toString()};
  }

  String get currentUid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No logged-in user found.');
    }
    return user.uid;
  }

  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String role, // user/seller/tailor
    required String name,
    String shopName = '',
    String address = '',
    bool available = false,
    double stitchingRate = 0,
  }) async {
    await _db.collection('users').doc(uid).set({
      'email': email.trim().toLowerCase(),
      'name': name,
      'role': role,
      'shopName': shopName,
      'address': address,
      'available': available,
      if (role == 'tailor') 'stitchingRate': stitchingRate,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Find registered user by email (demo tailor / seller lookup).
  Future<AppUserProfile?> findUserByEmail(String email) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty) return null;
    final snap = await _db
        .collection('users')
        .where('email', isEqualTo: e)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first;
    final data = d.data();
    final rateRaw = data['stitchingRate'];
    final stitchingRate = rateRaw is num
        ? rateRaw.toDouble()
        : (double.tryParse(rateRaw?.toString() ?? '') ?? 0.0);
    return AppUserProfile(
      uid: d.id,
      name: _asString(data['name']),
      email: _asString(data['email']),
      role: _asString(data['role']).isEmpty ? 'user' : _asString(data['role']),
      shopName: _asString(data['shopName']),
      address: _asString(data['address']),
      available: _asBool(data['available']),
      stitchingRate: stitchingRate,
      tailorProfitPerUnit: _tailorProfitPerUnitFromData(data),
    );
  }

  Future<AppUserProfile> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) {
      throw StateError('User profile not found for uid=$uid');
    }

    final rateRaw = data['stitchingRate'];
    final stitchingRate = rateRaw is num
        ? rateRaw.toDouble()
        : (double.tryParse(rateRaw?.toString() ?? '') ?? 0.0);

    return AppUserProfile(
      uid: uid,
      name: _asString(data['name']),
      email: _asString(data['email']),
      role: _asString(data['role']).isEmpty ? 'user' : _asString(data['role']),
      shopName: _asString(data['shopName']),
      address: _asString(data['address']),
      available: _asBool(data['available']),
      stitchingRate: stitchingRate,
      tailorProfitPerUnit: _tailorProfitPerUnitFromData(data),
    );
  }

  /// Updates name and address for marketplace user profile (merge).
  Future<void> updateUserProfileFields({
    required String uid,
    required String name,
    required String address,
  }) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'address': address,
    }, SetOptions(merge: true));
  }

  Future<void> updateTailorStitchingRate(String uid, double ratePkrPerUnit) async {
    if (ratePkrPerUnit <= 0) {
      throw ArgumentError('Stitching rate must be greater than 0.');
    }
    await _db.collection('users').doc(uid).set({
      'stitchingRate': ratePkrPerUnit,
    }, SetOptions(merge: true));
  }

  tracking.OrderType _parseOrderType(String type) {
    switch (type) {
      case 'standard':
        return tracking.OrderType.standard;
      case 'custom':
        return tracking.OrderType.custom;
      default:
        return tracking.OrderType.standard;
    }
  }

  String _orderTypeToString(tracking.OrderType type) {
    return type == tracking.OrderType.standard ? 'standard' : 'custom';
  }

  tracking.OrderStatus _parseOrderStatus(String status) {
    switch (status) {
      case 'pending':
        return tracking.OrderStatus.pending;
      case 'withSeller':
        return tracking.OrderStatus.withSeller;
      case 'shippedToTailor':
        return tracking.OrderStatus.shippedToTailor;
      case 'tailorDelivered':
        return tracking.OrderStatus.tailorDelivered;
      case 'tailorStitched':
        return tracking.OrderStatus.tailorStitched;
      case 'tailorToShip':
        return tracking.OrderStatus.tailorToShip;
      case 'shipped':
        return tracking.OrderStatus.shipped;
      case 'delivered':
        return tracking.OrderStatus.delivered;
      case 'paymentReceived':
        return tracking.OrderStatus.paymentReceived;
      default:
        return tracking.OrderStatus.withSeller;
    }
  }

  String _orderStatusToString(tracking.OrderStatus status) {
    switch (status) {
      case tracking.OrderStatus.pending:
        return 'pending';
      case tracking.OrderStatus.withSeller:
        return 'withSeller';
      case tracking.OrderStatus.shippedToTailor:
        return 'shippedToTailor';
      case tracking.OrderStatus.tailorDelivered:
        return 'tailorDelivered';
      case tracking.OrderStatus.tailorStitched:
        return 'tailorStitched';
      case tracking.OrderStatus.tailorToShip:
        return 'tailorToShip';
      case tracking.OrderStatus.shipped:
        return 'shipped';
      case tracking.OrderStatus.delivered:
        return 'delivered';
      case tracking.OrderStatus.paymentReceived:
        return 'paymentReceived';
    }
  }

  DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  tracking.Order _orderFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Order doc has no data: ${doc.id}');
    }

    final type = _parseOrderType(_asString(data['type']).isEmpty ? 'standard' : _asString(data['type']));
    final status = _parseOrderStatus(
      _asString(data['status']).isEmpty ? 'withSeller' : _asString(data['status']),
    );
    final details = _asStringMap(data['details']);

    final totalAmountNum = data['totalAmount'] as num? ?? 0;
    final totalAmount = totalAmountNum.toDouble();
    final quantityNum = data['quantity'] as num? ?? 1;
    final quantity = quantityNum.toInt();
    final stitchRaw = data['tailorStitchingTotal'];
    final tailorStitchingTotal = stitchRaw is num
        ? stitchRaw.toDouble()
        : (double.tryParse(stitchRaw?.toString() ?? '') ?? 0.0);

    return tracking.Order(
      id: doc.id,
      customerName: _asString(data['customerName']),
      customerId: _asString(data['customerId']),
      productName: _asString(data['productName']),
      sellerName: _asString(data['sellerName']),
      sellerAddress: _asString(data['sellerAddress']),
      tailorName: _asString(data['tailorName']),
      tailorAddress: _asString(data['tailorAddress']),
      deliveryAddress: _asString(data['deliveryAddress']),
      totalAmount: totalAmount,
      tailorStitchingTotal: tailorStitchingTotal,
      type: type,
      status: status,
      quantity: quantity,
      details: details,
      sellerReceivedDate: _toDateTime(data['sellerReceivedDate']),
      tailorReceivedDate: _toDateTime(data['tailorReceivedDate']),
      stitchedDate: _toDateTime(data['stitchedDate']),
      shippedDate: _toDateTime(data['shippedDate']),
      deliveredDate: _toDateTime(data['deliveredDate']),
      paymentReceivedDate: _toDateTime(data['paymentReceivedDate']),
      sellerPaymentReleasedAt: _toDateTime(data['sellerPaymentReleasedAt']),
      tailorPaymentReleasedAt: _toDateTime(data['tailorPaymentReleasedAt']),
      createdAt: _toDateTime(data['createdAt']),
      notifications: const [],
    );
  }

  Future<void> confirmSellerPaymentRelease(String orderId) async {
    final ref = _db.collection('orders').doc(orderId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) throw StateError('Order not found');

    final status = _parseOrderStatus(
      _asString(data['status']).isEmpty ? 'withSeller' : _asString(data['status']),
    );
    if (status != tracking.OrderStatus.delivered && status != tracking.OrderStatus.paymentReceived) {
      throw StateError('Order must be delivered before confirming product payment.');
    }
    if (data['sellerPaymentReleasedAt'] != null) return;

    await ref.update({'sellerPaymentReleasedAt': FieldValue.serverTimestamp()});
    await _finalizePaymentStatusIfComplete(ref);
  }

  Future<void> confirmTailorPaymentRelease(String orderId) async {
    final ref = _db.collection('orders').doc(orderId);
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) throw StateError('Order not found');

    final type = _parseOrderType(_asString(data['type']).isEmpty ? 'standard' : _asString(data['type']));
    final stitchRaw = data['tailorStitchingTotal'];
    final stitch = stitchRaw is num
        ? stitchRaw.toDouble()
        : (double.tryParse(stitchRaw?.toString() ?? '') ?? 0.0);
    if (type != tracking.OrderType.custom || stitch <= 0) {
      throw StateError('Tailor payment confirmation applies only to custom orders with a tailoring total.');
    }

    final status = _parseOrderStatus(
      _asString(data['status']).isEmpty ? 'withSeller' : _asString(data['status']),
    );
    if (status != tracking.OrderStatus.delivered && status != tracking.OrderStatus.paymentReceived) {
      throw StateError('Order must be delivered before confirming tailoring payment.');
    }
    if (data['tailorPaymentReleasedAt'] != null) return;

    await ref.update({'tailorPaymentReleasedAt': FieldValue.serverTimestamp()});
    await _finalizePaymentStatusIfComplete(ref);
  }

  Future<void> _finalizePaymentStatusIfComplete(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) return;

    final type = _parseOrderType(_asString(data['type']).isEmpty ? 'standard' : _asString(data['type']));
    final stitchRaw = data['tailorStitchingTotal'];
    final stitch = stitchRaw is num
        ? stitchRaw.toDouble()
        : (double.tryParse(stitchRaw?.toString() ?? '') ?? 0.0);

    final sellerDone = data['sellerPaymentReleasedAt'] != null;
    final tailorDone =
        type != tracking.OrderType.custom || stitch <= 0 || data['tailorPaymentReleasedAt'] != null;

    final current = _parseOrderStatus(
      _asString(data['status']).isEmpty ? 'withSeller' : _asString(data['status']),
    );

    if (sellerDone && tailorDone && current != tracking.OrderStatus.paymentReceived) {
      await ref.update({
        'status': _orderStatusToString(tracking.OrderStatus.paymentReceived),
        'paymentReceivedDate': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<String> addProduct({
    required String sellerId,
    required String sellerName,
    required String sellerAddress,
    required String name,
    required double price,
    required double discountPercent,
    Map<String, dynamic> details = const {},
    int stockQuantity = 1,
    double profitPerUnit = 0,
    String category = 'Kurta Shalwar',
    String section = '',
    String colorName = '',
    String imageUrl = '',
    String modelPath = '',
    bool showOnLanding = true,
  }) async {
    final doc = _db.collection('products').doc();
    final stock = stockQuantity < 0 ? 0 : stockQuantity;
    final profit = profitPerUnit < 0 ? 0.0 : profitPerUnit;
    final sec = section.trim().isNotEmpty ? section.trim() : category.trim();
    final mergedDetails = <String, dynamic>{
      ...details,
      'category': category.trim().isNotEmpty ? category.trim() : 'Other',
      'section': sec,
      if (colorName.trim().isNotEmpty) 'colorName': colorName.trim(),
      if (imageUrl.trim().isNotEmpty) 'imageUrl': imageUrl.trim(),
      if (modelPath.trim().isNotEmpty) 'modelPath': modelPath.trim(),
    };
    await doc.set({
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerAddress': sellerAddress,
      'name': name,
      'price': price,
      'discountPercent': discountPercent,
      'profitPerUnit': profit,
      'stockQuantity': stock,
      'isOutOfStock': stock <= 0,
      'showOnLanding': showOnLanding,
      'type': 'standard',
      'details': mergedDetails,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateProductPrice(String productId, double price) async {
    if (price <= 0) throw ArgumentError.value(price, 'price', 'must be > 0');
    await _db.collection('products').doc(productId).update({'price': price});
  }

  Future<void> updateProductStock(String productId, int stock) async {
    if (stock < 0) throw ArgumentError.value(stock, 'stock', 'must be >= 0');
    await _db.collection('products').doc(productId).update({
      'stockQuantity': stock,
      'isOutOfStock': stock <= 0,
    });
  }

  Future<void> markProductOutOfStock(String productId) async {
    await _db.collection('products').doc(productId).update({
      'isOutOfStock': true,
      'stockQuantity': 0,
    });
  }

  Future<void> restockProduct(String productId, int newStock) async {
    if (newStock <= 0) {
      throw ArgumentError.value(newStock, 'newStock', 'must be > 0');
    }
    await _db.collection('products').doc(productId).update({
      'isOutOfStock': false,
      'stockQuantity': newStock,
    });
  }

  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).delete();
  }

  /// Maps a Firestore [ProductModel] to the marketplace / product viewer map shape.
  Map<String, dynamic> marketplaceProductMap(ProductModel p) {
    final d = p.details;
    final imageUrl = _asString(d['imageUrl']);
    var modelPath = _asString(d['modelPath']);
    if (modelPath.startsWith('/local-products/')) {
      const base = String.fromEnvironment(
        'LOCAL_PRODUCT_API_BASE',
        defaultValue: 'http://127.0.0.1:5190',
      );
      modelPath = '${base.replaceAll(RegExp(r'/+$'), '')}$modelPath';
    }
    var category = _asString(d['category']);
    if (category.isEmpty) category = 'Other';
    var section = _asString(d['section']);
    if (section.isEmpty) section = category;
    category = _normalizeMarketplaceSection(category);
    section = _normalizeMarketplaceSection(section);
    final colorName = _asString(d['colorName']);
    final disc = p.discountPercent.clamp(0.0, 100.0);
    final unitAfter = p.price * (1 - disc / 100);
    final orig = p.price.round();
    final unavailable = !p.isPurchasable;
    return <String, dynamic>{
      'id': p.id,
      'firebaseProductId': p.id,
      'title': p.name.trim().isEmpty ? 'Product' : p.name,
      'price': unitAfter.round(),
      if (disc > 0) 'originalPrice': orig,
      'category': category,
      if (section.isNotEmpty) 'section': section,
      if (colorName.isNotEmpty) 'colorName': colorName,
      if (modelPath.isNotEmpty) 'modelPath': modelPath,
      if (imageUrl.isNotEmpty) 'imagePath': imageUrl,
      if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      'sellerId': p.sellerId,
      'sellerName': p.sellerName,
      'sellerAddress': p.sellerAddress,
      'discountPercent': p.discountPercent,
      'details': _sanitizeOrderDetails(Map<String, dynamic>.from(p.details)),
      'stockQuantity': p.stockQuantity,
      'outOfStock': unavailable,
      'showOnLanding': p.showOnLanding,
      'isSellerListing': true,
    };
  }

  ProductModel _productFromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data();
    if (data == null) {
      throw StateError('Product doc missing data: ${d.id}');
    }
    final stockRaw = data['stockQuantity'];
    final parsedStock = stockRaw == null
        ? 999999
        : (stockRaw is num
            ? stockRaw.toInt()
            : int.tryParse(stockRaw.toString()) ?? 0);

    return ProductModel(
      id: d.id,
      name: _asString(data['name']),
      price: (data['price'] as num? ?? 0).toDouble(),
      discountPercent: (data['discountPercent'] is num
              ? (data['discountPercent'] as num).toDouble()
              : double.tryParse(data['discountPercent']?.toString() ?? '') ?? 0.0)
          .toDouble(),
      type: _parseOrderType(_asString(data['type']).isEmpty ? 'standard' : _asString(data['type'])),
      sellerId: _asString(data['sellerId']),
      sellerName: _asString(data['sellerName']),
      sellerAddress: _asString(data['sellerAddress']),
      details: _asStringMap(data['details']),
      stockQuantity: parsedStock < 0 ? 0 : parsedStock,
      isOutOfStock: _asBool(data['isOutOfStock']),
      profitPerUnit: _profitPerUnitFromData(data),
      showOnLanding: data['showOnLanding'] != false,
    );
  }

  double _profitPerUnitFromData(Map<String, dynamic> data) {
    final p = data['profitPerUnit'];
    if (p is num) return p.toDouble().clamp(0, 1e12);
    return (double.tryParse(p?.toString() ?? '') ?? 0).clamp(0, 1e12);
  }

  double _orderLineSales(Map<String, dynamic> data) {
    final ls = data['lineSalesTotal'];
    if (ls is num) return ls.toDouble();
    final ta = data['totalAmount'];
    final q = data['quantity'] as num? ?? 1;
    return (ta is num ? ta.toDouble() : 0.0) * q.toInt();
  }

  double _orderLineProfit(Map<String, dynamic> data) {
    final sp = data['sellerProfitTotal'];
    if (sp is num) return sp.toDouble();
    return 0;
  }

  double _tailorProfitPerUnitFromData(Map<String, dynamic> data) {
    final p = data['tailorProfitPerUnit'];
    if (p is num) return p.toDouble().clamp(0, 1e12);
    return (double.tryParse(p?.toString() ?? '') ?? 0).clamp(0, 1e12);
  }

  double _tailorLineSales(Map<String, dynamic> data) {
    final s = data['tailorStitchingTotal'];
    if (s is num) return s.toDouble();
    return 0.0;
  }

  double _tailorLineProfit(Map<String, dynamic> data) {
    final p = data['tailorProfitTotal'];
    if (p is num) return p.toDouble();
    return 0.0;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _mondayOf(DateTime d) {
    final day = _dateOnly(d);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  SellerAnalyticsSnapshot _computeSellerAnalytics(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    const periods = ['Day', 'Week', 'Month'];
    final salesBuckets = {
      for (final p in periods) p: List<double>.filled(7, 0),
    };
    final profitBuckets = {
      for (final p in periods) p: List<double>.filled(7, 0),
    };

    final now = DateTime.now();
    final today = _dateOnly(now);

    // Day: buckets 0..6 = consecutive days from (today-6) .. today
    final dayStart = today.subtract(const Duration(days: 6));

    // Week: 7 weeks ending current week (Monday-aligned)
    final anchorMonday = _mondayOf(now);

    // Month: 7 calendar months ending current month
    final monthStarts = List.generate(7, (k) {
      return DateTime(now.year, now.month - (6 - k), 1);
    });

    int? dayBucket(DateTime od) {
      final d = _dateOnly(od);
      if (d.isBefore(dayStart) || d.isAfter(today)) return null;
      return d.difference(dayStart).inDays;
    }

    int? weekBucket(DateTime od) {
      final om = _mondayOf(od);
      if (om.isAfter(anchorMonday)) return 6;
      final diff = anchorMonday.difference(om).inDays ~/ 7;
      if (diff < 0 || diff > 6) return null;
      return 6 - diff;
    }

    int? monthBucket(DateTime od) {
      final om = DateTime(od.year, od.month, 1);
      for (var k = 0; k < 7; k++) {
        final ms = monthStarts[k];
        if (om.year == ms.year && om.month == ms.month) return k;
      }
      return null;
    }

    final productAgg = <String, _ProductAgg>{};
    final statusCounts = <String, int>{
      'pending': 0,
      'shipped': 0,
      'completed': 0,
      'cancelled': 0,
      'other': 0,
    };

    for (final doc in docs) {
      final data = doc.data();
      final created = _toDateTime(data['createdAt']);
      if (created == null) continue;

      final sales = _orderLineSales(data);
      final profit = _orderLineProfit(data);

      final di = dayBucket(created);
      if (di != null && di >= 0 && di < 7) {
        salesBuckets['Day']![di] += sales;
        profitBuckets['Day']![di] += profit;
      }

      final wi = weekBucket(created);
      if (wi != null && wi >= 0 && wi < 7) {
        salesBuckets['Week']![wi] += sales;
        profitBuckets['Week']![wi] += profit;
      }

      final mi = monthBucket(created);
      if (mi != null && mi >= 0 && mi < 7) {
        salesBuckets['Month']![mi] += sales;
        profitBuckets['Month']![mi] += profit;
      }

      final pid = _asString(data['productId']);
      if (pid.isNotEmpty) {
        final name = _asString(data['productName']).isEmpty ? 'Product' : _asString(data['productName']);
        productAgg.putIfAbsent(pid, () => _ProductAgg(name));
        productAgg[pid]!.orderCount += 1;
        productAgg[pid]!.sales += sales;
      }

      final st = _asString(data['status']).isEmpty ? 'withSeller' : _asString(data['status']);
      final stLower = st.toLowerCase();
      if (stLower == 'cancelled') {
        statusCounts['cancelled'] = (statusCounts['cancelled'] ?? 0) + 1;
      } else if (st == 'pending' || st == 'withSeller') {
        statusCounts['pending'] = (statusCounts['pending'] ?? 0) + 1;
      } else if (st == 'delivered' || st == 'paymentReceived') {
        statusCounts['completed'] = (statusCounts['completed'] ?? 0) + 1;
      } else if (st == 'shipped' ||
          st == 'shippedToTailor' ||
          st == 'tailorDelivered' ||
          st == 'tailorStitched' ||
          st == 'tailorToShip') {
        statusCounts['shipped'] = (statusCounts['shipped'] ?? 0) + 1;
      } else {
        statusCounts['other'] = (statusCounts['other'] ?? 0) + 1;
      }
    }

    double sumList(List<double> l) => l.fold(0.0, (a, b) => a + b);

    final totalSales = <String, double>{};
    final totalProfit = <String, double>{};
    for (final p in periods) {
      totalSales[p] = sumList(salesBuckets[p]!);
      totalProfit[p] = sumList(profitBuckets[p]!);
    }

    final products = productAgg.entries
        .map(
          (e) => SellerProductSalesRow(
            productId: e.key,
            productName: e.value.name,
            orderCount: e.value.orderCount,
            totalSalesPkr: e.value.sales,
          ),
        )
        .toList()
      ..sort((a, b) => b.totalSalesPkr.compareTo(a.totalSalesPkr));

    return SellerAnalyticsSnapshot(
      totalSalesByPeriod: totalSales,
      totalProfitByPeriod: totalProfit,
      salesBucketsByPeriod: salesBuckets,
      profitBucketsByPeriod: profitBuckets,
      productSales: products,
      orderStatusCounts: statusCounts,
    );
  }

  TailorDashboardSnapshot _computeTailorDashboard(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    const periods = ['Day', 'Week', 'Month'];
    final earnSales = {for (final p in periods) p: List<double>.filled(7, 0)};
    final earnProfit = {for (final p in periods) p: List<double>.filled(7, 0)};
    final ordTotal = {for (final p in periods) p: List<double>.filled(7, 0)};
    final ordDone = {for (final p in periods) p: List<double>.filled(7, 0)};

    final now = DateTime.now();
    final today = _dateOnly(now);
    final dayStart = today.subtract(const Duration(days: 6));
    final anchorMonday = _mondayOf(now);
    final monthStarts = List.generate(7, (k) {
      return DateTime(now.year, now.month - (6 - k), 1);
    });

    int? dayBucket(DateTime od) {
      final d = _dateOnly(od);
      if (d.isBefore(dayStart) || d.isAfter(today)) return null;
      return d.difference(dayStart).inDays;
    }

    int? weekBucket(DateTime od) {
      final om = _mondayOf(od);
      if (om.isAfter(anchorMonday)) return 6;
      final diff = anchorMonday.difference(om).inDays ~/ 7;
      if (diff < 0 || diff > 6) return null;
      return 6 - diff;
    }

    int? monthBucket(DateTime od) {
      final om = DateTime(od.year, od.month, 1);
      for (var k = 0; k < 7; k++) {
        final ms = monthStarts[k];
        if (om.year == ms.year && om.month == ms.month) return k;
      }
      return null;
    }

    void addCount(Map<String, List<double>> target, DateTime t, double delta) {
      for (final per in periods) {
        int? idx;
        if (per == 'Day') {
          idx = dayBucket(t);
        } else if (per == 'Week') {
          idx = weekBucket(t);
        } else {
          idx = monthBucket(t);
        }
        if (idx != null && idx >= 0 && idx < 7) {
          target[per]![idx] += delta;
        }
      }
    }

    final productAgg = <String, _ProductAgg>{};

    for (final doc in docs) {
      final data = doc.data();
      final created = _toDateTime(data['createdAt']);
      if (created != null) {
        addCount(ordTotal, created, 1);
      }

      final released = _toDateTime(data['tailorPaymentReleasedAt']);
      if (released != null) {
        addCount(ordDone, released, 1);

        final sales = _tailorLineSales(data);
        final profit = _tailorLineProfit(data);
        for (final per in periods) {
          int? idx;
          if (per == 'Day') {
            idx = dayBucket(released);
          } else if (per == 'Week') {
            idx = weekBucket(released);
          } else {
            idx = monthBucket(released);
          }
          if (idx != null && idx >= 0 && idx < 7) {
            earnSales[per]![idx] += sales;
            earnProfit[per]![idx] += profit;
          }
        }

        final pid = _asString(data['productId']);
        final name = _asString(data['productName']).isEmpty ? 'Product' : _asString(data['productName']);
        final aggKey = pid.isNotEmpty ? pid : name;
        productAgg.putIfAbsent(aggKey, () => _ProductAgg(name));
        productAgg[aggKey]!.orderCount += 1;
        productAgg[aggKey]!.sales += sales;
      }
    }

    double sumList(List<double> l) => l.fold(0.0, (a, b) => a + b);

    final totalSales = <String, double>{};
    final totalProfit = <String, double>{};
    for (final p in periods) {
      totalSales[p] = sumList(earnSales[p]!);
      totalProfit[p] = sumList(earnProfit[p]!);
    }

    final products = productAgg.entries
        .map(
          (e) => SellerProductSalesRow(
            productId: e.key,
            productName: e.value.name,
            orderCount: e.value.orderCount,
            totalSalesPkr: e.value.sales,
          ),
        )
        .toList()
      ..sort((a, b) => b.totalSalesPkr.compareTo(a.totalSalesPkr));

    return TailorDashboardSnapshot(
      totalSalesByPeriod: totalSales,
      totalProfitByPeriod: totalProfit,
      earningsSalesBuckets: earnSales,
      earningsProfitBuckets: earnProfit,
      productSales: products,
      ordersTotalBuckets: ordTotal,
      ordersCompletedBuckets: ordDone,
    );
  }

  /// Live seller dashboard metrics (orders where `sellerId` matches).
  Stream<SellerAnalyticsSnapshot> streamSellerAnalytics(String sellerId) {
    if (sellerId.isEmpty) {
      return Stream.value(SellerAnalyticsSnapshot.empty());
    }
    return _db.collection('orders').where('sellerId', isEqualTo: sellerId).snapshots().map(
          (snap) => _computeSellerAnalytics(snap.docs),
        );
  }

  /// Live tailor dashboard (`tailorId` orders). Earnings use `tailorPaymentReleasedAt`.
  Stream<TailorDashboardSnapshot> streamTailorDashboard(String tailorId) {
    if (tailorId.isEmpty) {
      return Stream.value(TailorDashboardSnapshot.empty());
    }
    return _db.collection('orders').where('tailorId', isEqualTo: tailorId).snapshots().map(
          (snap) => _computeTailorDashboard(snap.docs),
        );
  }

  List<ProductModel> _productsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    final list = <ProductModel>[];
    for (final doc in snap.docs) {
      try {
        list.add(_productFromDoc(doc));
      } catch (e, st) {
        debugPrint('Skip product doc ${doc.id}: $e\n$st');
      }
    }
    list.sort((a, b) => b.name.compareTo(a.name));
    return list;
  }

  Stream<List<ProductModel>> streamAllProducts() {
    // Avoid orderBy('createdAt'): legacy docs may lack it and composite indexes often bite FYP demos.
    return _db.collection('products').snapshots().map(_productsFromSnapshot);
  }

  /// Products listed by one seller (for storefront / marketplace filtering).
  Stream<List<ProductModel>> streamProductsForSeller(String sellerId) {
    return _db
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map(_productsFromSnapshot);
  }

  Future<void> setTailorAvailableAndRate({
    required String uid,
    required double stitchingRatePkrPerUnit,
    double tailorProfitPerUnit = 0,
    bool available = true,
  }) async {
    if (stitchingRatePkrPerUnit <= 0) {
      throw ArgumentError('Rate must be > 0');
    }
    final profit = tailorProfitPerUnit < 0 ? 0.0 : tailorProfitPerUnit;
    await _db.collection('users').doc(uid).set({
      'stitchingRate': stitchingRatePkrPerUnit,
      'tailorProfitPerUnit': profit,
      'available': available,
    }, SetOptions(merge: true));
  }

  Stream<List<tracking.Order>> streamOrdersForUser(String uid) {
    return _db.collection('orders').where('customerId', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(_orderFromDoc).toList();
      list.sort((a, b) {
        final aT = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bT = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bT.compareTo(aT);
      });
      return list;
    });
  }

  Stream<List<tracking.Order>> streamOrdersForSeller(String uid) {
    return _db.collection('orders').where('sellerId', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(_orderFromDoc).toList();
      list.sort((a, b) {
        final aT = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bT = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bT.compareTo(aT);
      });
      return list;
    });
  }

  Stream<List<tracking.Order>> streamOrdersForTailor(String uid) {
    return _db.collection('orders').where('tailorId', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(_orderFromDoc).toList();
      list.sort((a, b) {
        final aT = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bT = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bT.compareTo(aT);
      });
      return list;
    });
  }

  List<AppUserProfile> _tailorsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    return snap.docs
        .map((d) {
          final data = d.data();
          final rateRaw = data['stitchingRate'];
          final rate = rateRaw is num
              ? rateRaw.toDouble()
              : (double.tryParse(rateRaw?.toString() ?? '') ?? 0.0);
          return AppUserProfile(
            uid: d.id,
            name: _asString(data['name']),
            email: _asString(data['email']),
            role: _asString(data['role']).isEmpty ? 'tailor' : _asString(data['role']),
            shopName: _asString(data['shopName']),
            address: _asString(data['address']),
            available: _asBool(data['available']),
            stitchingRate: rate,
            tailorProfitPerUnit: _tailorProfitPerUnitFromData(data),
          );
        })
        .where((t) => t.stitchingRate > 0)
        .toList();
  }

  Future<List<AppUserProfile>> fetchAvailableTailors() async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'tailor')
        .where('available', isEqualTo: true)
        .get();
    return _tailorsFromSnapshot(snap);
  }

  /// Find tailor / chat: any registered tailor with a stitching rate (not only `available`).
  Future<List<AppUserProfile>> fetchTailorsForCustomerChat() async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'tailor')
        .get();
    final list = await _tailorsFromSnapshot(snap);
    list.sort((a, b) {
      final aLabel = a.shopName.isNotEmpty ? a.shopName : a.name;
      final bLabel = b.shopName.isNotEmpty ? b.shopName : b.name;
      return aLabel.compareTo(bLabel);
    });
    return list;
  }

  Future<String> createOrder({
    required String customerId,
    required String customerName,
    required String productId,
    required String productName,
    required double totalAmount,
    required int quantity,
    required tracking.OrderType type,
    required Map<String, dynamic> details,
    required String sellerId,
    required String sellerName,
    required String sellerAddress,
    String? tailorId,
    String? tailorName,
    String tailorAddress = '',
    String deliveryAddress = '',
    double tailorStitchingTotal = 0,
    /// Set from [AppUserProfile.tailorProfitPerUnit] * quantity — do not read `users/{tailorId}` in a transaction (often denied for buyers on web).
    double precomputedTailorProfitTotal = 0,
  }) async {
    if (quantity < 1) {
      throw ArgumentError.value(quantity, 'quantity', 'must be >= 1');
    }

    final status = tracking.OrderStatus.withSeller;
    final orderRef = _db.collection('orders').doc();
    final safeDetails = _sanitizeOrderDetails(details);
    final payload = <String, dynamic>{
      'customerId': customerId,
      'customerName': customerName,
      'productId': productId,
      'productName': productName,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerAddress': sellerAddress,
      'tailorId': tailorId,
      'tailorName': tailorName ?? '',
      'tailorAddress': tailorAddress,
      'deliveryAddress': deliveryAddress,
      'type': _orderTypeToString(type),
      'status': _orderStatusToString(status),
      'totalAmount': totalAmount,
      'tailorStitchingTotal': tailorStitchingTotal,
      'currency': 'PKR',
      'quantity': quantity,
      'details': safeDetails,
      'createdAt': FieldValue.serverTimestamp(),
      'sellerReceivedDate': FieldValue.serverTimestamp(),
    };

    final prodRef = _db.collection('products').doc(productId);
    final prodSnap = await prodRef.get();

    var profitPerUnit = 0.0;
    final batch = _db.batch();
    if (prodSnap.exists) {
      final data = prodSnap.data()!;
      profitPerUnit = _profitPerUnitFromData(data);
      if (_asBool(data['isOutOfStock'])) {
        throw StateError('This product is out of stock.');
      }
      final stockRaw = data['stockQuantity'];
      final stock = stockRaw == null
          ? 999999
          : (stockRaw is num
              ? stockRaw.toInt()
              : int.tryParse(stockRaw.toString()) ?? 0);
      if (stock < quantity) {
        throw StateError('Not enough stock available for this product.');
      }
      final newStock = stock - quantity;
      batch.update(prodRef, {
        'stockQuantity': newStock,
        if (newStock <= 0) 'isOutOfStock': true,
      });
    }

    final tailorProfitTotal = precomputedTailorProfitTotal.clamp(0.0, 1e12);
    final productLineTotal = totalAmount * quantity;
    final sellerProfitTotal = profitPerUnit * quantity;
    final customerGrandTotal = productLineTotal + tailorStitchingTotal;
    final fullPayload = Map<String, dynamic>.from(payload)
      ..['productLineTotal'] = productLineTotal
      ..['lineSalesTotal'] = productLineTotal
      ..['sellerProfitTotal'] = sellerProfitTotal
      ..['tailorProfitTotal'] = tailorProfitTotal
      ..['customerGrandTotal'] = customerGrandTotal;

    batch.set(orderRef, fullPayload);
    await batch.commit();

    return orderRef.id;
  }

  Future<void> updateOrderStatus(String orderId, tracking.OrderStatus newStatus) async {
    final updates = <String, dynamic>{
      'status': _orderStatusToString(newStatus),
    };

    switch (newStatus) {
      case tracking.OrderStatus.withSeller:
        updates['sellerReceivedDate'] = FieldValue.serverTimestamp();
        break;
      case tracking.OrderStatus.shippedToTailor:
        updates['shippedDate'] = FieldValue.serverTimestamp();
        break;
      case tracking.OrderStatus.shipped:
        updates['shippedDate'] = FieldValue.serverTimestamp();
        break;
      case tracking.OrderStatus.tailorDelivered:
        updates['tailorReceivedDate'] = FieldValue.serverTimestamp();
        break;
      case tracking.OrderStatus.tailorStitched:
        updates['stitchedDate'] = FieldValue.serverTimestamp();
        break;
      case tracking.OrderStatus.delivered:
        updates['deliveredDate'] = FieldValue.serverTimestamp();
        break;
      case tracking.OrderStatus.paymentReceived:
        updates['paymentReceivedDate'] = FieldValue.serverTimestamp();
        break;
      case tracking.OrderStatus.tailorToShip:
        // No additional date in your original mock logic.
        break;
      case tracking.OrderStatus.pending:
        break;
    }

    await _db.collection('orders').doc(orderId).update(updates);
  }
}

class _ProductAgg {
  final String name;
  int orderCount = 0;
  double sales = 0;
  _ProductAgg(this.name);
}
