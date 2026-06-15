import 'dart:typed_data';

import '../Order-Tracking-System/services/app_backend.dart';
import 'try_on_garment_service.dart';

/// Holds step-1 size prediction + try-on product + selected tailor for chat & checkout.
class TryOnOrderSession {
  TryOnOrderSession._();

  static final TryOnOrderSession instance = TryOnOrderSession._();

  Map<String, double> measurementsCm = {};
  Map<String, String> measurementsInches = {};
  String predictedSizeLabel = 'L/40';
  /// 2D try-on overlay image file (e.g. `12.png`) — not the 3D shop product name.
  String tryOnGarmentFile = '';
  String garmentFileName = '';
  String garmentTitle = 'Kurta Shalwar';
  String marketplaceProductId = '';
  String marketplaceTitle = '';
  String marketplaceColorName = '';
  String productImagePath = '';
  String productModelPath = '';
  int productPricePkr = 3590;
  bool _hasMarketplaceProduct = false;
  int shippingPkr = 1500;
  Uint8List? tryOnResultBytes;
  AppUserProfile? selectedTailor;
  bool paymentVerified = false;
  /// True when last success was demo mock (no row in Stripe Dashboard).
  bool lastPaymentWasDemoMock = false;
  String? lastPaymentSessionId;

  void applyMeasurements(Map<String, double> cm) {
    measurementsCm = Map<String, double>.from(cm);
    measurementsInches = {};
    for (final e in cm.entries) {
      measurementsInches[e.key] = '${(e.value / 2.54).toStringAsFixed(1)}"';
    }
    predictedSizeLabel = _deriveSizeLabel(cm);
  }

  void applyGarment(String fileName, {int? pricePkr}) {
    tryOnGarmentFile = fileName;
    garmentFileName = fileName;
    if (!_hasMarketplaceProduct) {
      garmentTitle = TryOnGarmentService.displayName(fileName);
    }
    if (pricePkr != null) productPricePkr = pricePkr;
  }

  /// 3D marketplace product (e.g. Black kurta) — remembered for tailor chat.
  void applyMarketplaceProduct({
    required String productId,
    required String title,
    required String colorName,
    required int pricePkr,
    String imagePath = '',
    String modelPath = '',
  }) {
    _hasMarketplaceProduct = true;
    marketplaceProductId = productId;
    marketplaceTitle = title;
    marketplaceColorName = colorName;
    garmentFileName = productId;
    garmentTitle =
        colorName.isNotEmpty ? '$title · $colorName' : title;
    productPricePkr = pricePkr;
    if (imagePath.isNotEmpty) productImagePath = imagePath;
    if (modelPath.isNotEmpty) productModelPath = modelPath;
  }

  /// Title/color/price for tailor chat (+ button), not the 2D overlay filename.
  Map<String, dynamic> marketplaceProductMap() {
    if (!_hasMarketplaceProduct && marketplaceTitle.isEmpty) {
      return {};
    }
    return {
      'id': marketplaceProductId,
      'title': marketplaceTitle.isNotEmpty ? marketplaceTitle : garmentTitle,
      'colorName': marketplaceColorName,
      'price': productPricePkr,
      'imagePath': productImagePath,
      'modelPath': productModelPath,
    };
  }

  void selectTailor(AppUserProfile tailor) {
    selectedTailor = tailor;
  }

  /// Clear demo/real Stripe success so Final cart can charge again.
  void resetPayment() {
    paymentVerified = false;
    lastPaymentWasDemoMock = false;
    lastPaymentSessionId = null;
  }

  int get stitchingPkr => selectedTailor?.stitchingRate.round() ?? 0;

  int get subtotalPkr => productPricePkr + stitchingPkr;

  int get totalPkr => subtotalPkr + shippingPkr;

  String get sizeSummary {
    if (measurementsInches.isEmpty) {
      return 'Predicted size: $predictedSizeLabel (from try-on flow)';
    }
    final chest =
        measurementsInches['Chest'] ?? measurementsInches['chest'];
    return 'Predicted size: $predictedSizeLabel${chest != null ? ' · Chest $chest' : ''}';
  }

  static String _deriveSizeLabel(Map<String, double> cm) {
    final chestCm = cm['Chest'] ?? cm['chest'] ?? cm['Chest (cm)'];
    if (chestCm == null) return 'L/40';
    final chestIn = chestCm / 2.54;
    if (chestIn < 41) return 'S/36';
    if (chestIn < 43) return 'M/38';
    if (chestIn < 45) return 'L/40';
    if (chestIn < 47) return 'XL/42';
    return 'XXL/44';
  }
}
