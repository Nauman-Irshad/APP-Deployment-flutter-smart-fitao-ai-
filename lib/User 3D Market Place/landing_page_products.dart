import '../../config/fabric_local_config.dart';
import '../../config/production_urls.dart';

/// Stitched = R2 GLB online. Fabric = local `App/landing page product/fabric/` only.
final List<Map<String, dynamic>> kLandingPageProducts = [
  // —— Kurta Shalwar (4) ——
  {
    'id': 'lp_kurta_black',
    'title': 'Embroidered Kurta Shalwar',
    'colorName': 'Black',
    'price': 3590,
    'originalPrice': 4490,
    'category': 'Kurta Shalwar',
    'section': 'Kurta Shalwar',
    'modelPath': ProductionUrls.glbKurtaBlack,
    'discountPercent': 20.0,
  },
  {
    'id': 'lp_kurta_brown',
    'title': 'Classic Kurta Shalwar',
    'colorName': 'Brown',
    'price': 3790,
    'originalPrice': 4690,
    'category': 'Kurta Shalwar',
    'section': 'Kurta Shalwar',
    'modelPath': ProductionUrls.glbKurtaBrown,
    'discountPercent': 19.0,
  },
  {
    'id': 'lp_kurta_sky_blue',
    'title': 'Premium Kurta Shalwar',
    'colorName': 'Sky Blue',
    'price': 3990,
    'originalPrice': 4990,
    'category': 'Kurta Shalwar',
    'section': 'Kurta Shalwar',
    'modelPath': ProductionUrls.glbKurtaSkyBlue,
    'discountPercent': 20.0,
  },
  {
    'id': 'lp_kurta_white',
    'title': 'Festive White Kurta Shalwar',
    'colorName': 'White',
    'price': 4190,
    'originalPrice': 5190,
    'category': 'Kurta Shalwar',
    'section': 'Kurta Shalwar',
    'modelPath': ProductionUrls.glbKurtaWhite,
    'discountPercent': 19.0,
  },
  // —— Shalwar Kameez (4) ——
  {
    'id': 'lp_shalwar_black',
    'title': 'Classic Black Shalwar Kameez',
    'colorName': 'Black',
    'price': 4290,
    'originalPrice': 5290,
    'category': 'Shalwar Kameez',
    'section': 'Shalwar Kameez',
    'modelPath': ProductionUrls.glbShalwarBlack,
    'discountPercent': 19.0,
  },
  {
    'id': 'lp_shalwar_brown',
    'title': 'Embroidered Brown Shalwar Kameez',
    'colorName': 'Brown',
    'price': 4490,
    'originalPrice': 5490,
    'category': 'Shalwar Kameez',
    'section': 'Shalwar Kameez',
    'modelPath': ProductionUrls.glbShalwarBrown,
    'discountPercent': 18.0,
  },
  {
    'id': 'lp_shalwar_white',
    'title': 'Festive White Shalwar Kameez',
    'colorName': 'White',
    'price': 4690,
    'originalPrice': 5790,
    'category': 'Shalwar Kameez',
    'section': 'Shalwar Kameez',
    'modelPath': ProductionUrls.glbShalwarWhite,
    'discountPercent': 19.0,
  },
  {
    'id': 'lp_shalwar_navy',
    'title': 'Premium Navy Shalwar Kameez',
    'colorName': 'Navy',
    'price': 4890,
    'originalPrice': 5990,
    'category': 'Shalwar Kameez',
    'section': 'Shalwar Kameez',
    'modelPath': ProductionUrls.glbShalwarNavy,
    'discountPercent': 18.0,
  },
  // —— Fabric (4) — image + shop fields (no AI prediction) ——
  {
    'id': 'lp_fabric_fantasy',
    'title': 'Fantasy Latha Unstitched',
    'brandName': 'Cotton King',
    'colorName': 'Fantasy Print',
    'price': 7000,
    'originalPrice': 7000,
    'category': 'Fabric',
    'section': 'Fabric',
    'imagePath': FabricLocalConfig.catalogFiles[0],
    'material': 'Cotton',
    'materials': ['Cotton', 'Latha'],
    'defaultSize': '4.5M',
    'sizes': ['4.5M', '5M', '6M'],
    'colorOptions': ['Off White', 'Sand', 'Gold'],
    'discountPercent': 0.0,
  },
  {
    'id': 'lp_fabric_gold',
    'title': 'Gold Premium Latha',
    'brandName': 'Cotton King',
    'colorName': 'Gold',
    'price': 7500,
    'originalPrice': 7500,
    'category': 'Fabric',
    'section': 'Fabric',
    'imagePath': FabricLocalConfig.catalogFiles[1],
    'material': 'Latha',
    'materials': ['Latha', 'Cotton'],
    'defaultSize': '4.5M',
    'sizes': ['4.5M', '5M'],
    'colorOptions': ['Gold', 'Sand'],
    'discountPercent': 0.0,
  },
  {
    'id': 'lp_fabric_mughal',
    'title': 'Shan e Mughal Latha',
    'brandName': 'Royal Weave',
    'colorName': 'Mughal Gold',
    'price': 8200,
    'originalPrice': 8200,
    'category': 'Fabric',
    'section': 'Fabric',
    'imagePath': FabricLocalConfig.catalogFiles[2],
    'material': 'Cotton',
    'materials': ['Cotton', 'Silk Blend'],
    'defaultSize': '5M',
    'sizes': ['4.5M', '5M', '6M'],
    'colorOptions': ['Off White', 'Sand', 'Mughal Gold'],
    'discountPercent': 0.0,
  },
  {
    'id': 'lp_fabric_sky',
    'title': 'Premium Cotton Latha',
    'brandName': 'Cotton King',
    'colorName': 'Sky Blue',
    'price': 6500,
    'originalPrice': 6500,
    'category': 'Fabric',
    'section': 'Fabric',
    'imagePath': FabricLocalConfig.catalogFiles[3],
    'material': 'Cotton',
    'materials': ['Cotton'],
    'defaultSize': '4.5M',
    'sizes': ['4.5M', '5M'],
    'colorOptions': ['Sky Blue', 'Off White'],
    'discountPercent': 0.0,
  },
];

/// Landing catalog: 4 kurta + 4 shalwar kameez (3D) + 4 fabric.
const List<String> kLandingCatalogTabs = [
  'Kurta Shalwar',
  'Shalwar Kameez',
  'Fabric',
];

/// Bundled landing only (no Firestore seller merge) — keeps app fast.
const bool kIncludeSellerListingsInMarketplace = false;

const String kDefaultLandingCatalogTab = 'Kurta Shalwar';

const int kProductsPerLandingCategory = 4;

final List<String> kLandingPageModelPaths = kLandingPageProducts
    .map((p) => p['modelPath']?.toString() ?? '')
    .where((p) => p.isNotEmpty)
    .toList(growable: false);
