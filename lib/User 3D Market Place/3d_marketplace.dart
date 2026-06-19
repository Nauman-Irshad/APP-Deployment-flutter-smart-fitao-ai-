import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../Order-Tracking-System/firebase_pages.dart';
import '../Order-Tracking-System/services/app_backend.dart';
import 'product_viewer.dart';
import 'profile.dart';
import 'reel.dart';
import 'auth-login-sign/auth_flow.dart';
import 'chat.dart';
import 'auth-login-sign/login_form.dart';
import '../Order-Tracking-System/login_as_tailor.dart';
import 'database/debug_orders.dart';
import 'database/connectivity_check.dart';
import 'database/order_tracking_service.dart';
import 'database/firebase_service.dart';
import 'viewer_asset_src.dart';
import 'landing_page_products.dart';
import 'landing_catalog_store.dart';
import 'landing_category_catalog.dart';
import 'marketplace_firebase_catalog.dart';
import 'cart_screen.dart';
import 'shopping_cart.dart';
import 'marketplace_bottom_nav.dart';
import 'marketplace_theme.dart';
import 'tailor_portfolio.dart';
import '../../services/marketplace_demo_seller.dart';
import '../../services/marketplace_badge_service.dart';
import '../../services/customer_chat_badges.dart';
import '../../services/seller_chat_service.dart';
import '../../services/tailor_chat_service.dart';
import '../../2d_try_on_app/try_on_handoff.dart';
import '../../2d_try_on_app/try_on_nav_bridge.dart';
import '../../2d_try_on_app/try_on_marketplace_tab.dart';
import '../../config/deployed_backend_banner.dart';
import '../services/customer_fitting_store_stub.dart'
    if (dart.library.html) '../services/customer_fitting_store_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Marketplace catalog — all GLBs from `landing page product/`.
final List<Map<String, dynamic>> _bundledMarketplaceProducts = [
  for (final p in kLandingPageProducts) Map<String, dynamic>.from(p),
];

String _bannerOverlayLine(Map<String, dynamic> banner, String key) {
  final v = banner[key];
  if (v == null) return '';
  final s = v.toString().trim();
  if (s.isEmpty || s == 'null') return '';
  return s;
}

class MarketPlace3D extends StatefulWidget {
  const MarketPlace3D({super.key});

  @override
  _MarketPlace3DState createState() => _MarketPlace3DState();
}

class _MarketPlace3DState extends State<MarketPlace3D> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  int _tryOnPanelKey = 0;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  int _currentBanner = 0;
  Map<String, int> _trackingCounts = {};
  late PageController _bannerController;
  Timer? _bannerTimer;
  late AnimationController _animationController;
  late ScrollController _scrollController;

  final List<Map<String, dynamic>> banners = const [
    {
      'image': 'assets/banner 1.png',
      'badge': 'Ready-made',
      'title': 'Shalwar Kameez',
      'subtitle': 'Festive & formal fits',
    },
    {
      'image': 'assets/banner 2.png',
      'badge': 'Kurta Sets',
      'title': 'Kurta & Pajama',
      'subtitle': 'Tailored comfort',
    },
    {
      'image': 'assets/banner 33.png',
      'badge': 'Unstitched',
      'title': 'Premium Fabric',
      'subtitle': 'Luxury unstitched rolls',
    },
  ];

  final List<String> categories = ['All', 'Kurta Shalwar', 'Shalwar Kameez', 'Fabric'];

  /// Demo list used only by the debug “Upload All Products” menu action (paths match bundled GLTF).
  late final List<Map<String, dynamic>> _demoProductsForUpload = [
    for (var i = 0; i < _bundledMarketplaceProducts.length; i++)
      {
        'id': i + 1,
        'title': _bundledMarketplaceProducts[i]['title']?.toString() ?? 'Product',
        'price': _bundledMarketplaceProducts[i]['price'],
        'originalPrice': _bundledMarketplaceProducts[i]['originalPrice'],
        'category': _bundledMarketplaceProducts[i]['category'],
        'modelPath': _bundledMarketplaceProducts[i]['modelPath'],
        'rating': _bundledMarketplaceProducts[i]['rating'],
        'reviews': _bundledMarketplaceProducts[i]['reviews'],
      },
  ];

  AppBackend get _backend => AppBackend.instance;
  StreamSubscription<User?>? _authProfileSub;
  List<Map<String, dynamic>> _sellerFirebaseProducts = [];
  AppUserProfile? _marketplaceUserProfile;

  @override
  void initState() {
    super.initState();
    TryOnNavBridge.openTryOnTab = _openTryOnTab;
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _applyHandoffFromUrl());
    }
    _bannerController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scrollController = ScrollController();

    _startBannerAutoScroll();
    _loadTrackingCounts();
    MarketplaceBadgeService.instance.ensureLoaded();
    MarketplaceBadgeService.instance.startFirebaseSync();
    LandingCatalogStore.instance.addListener(_onLandingCatalogChanged);
    if (kIncludeSellerListingsInMarketplace) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        LandingCatalogStore.instance.startFirebaseSync();
      });
    }
    LandingCatalogStore.instance.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
    MarketplaceDemoSeller.resolve().then((s) => MarketplaceDemoSeller.cache(s));

    _onLandingCatalogChanged();

    if (Firebase.apps.isNotEmpty) {
      _authProfileSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (!mounted) return;
        if (user == null) {
          setState(() => _marketplaceUserProfile = null);
          return;
        }
        try {
          final p = await _backend.getUserProfile(user.uid);
          if (mounted) setState(() => _marketplaceUserProfile = p);
        } catch (_) {
          if (mounted) setState(() => _marketplaceUserProfile = null);
        }
      });
    }

    ShoppingCart.instance.onNavigateToCart = () {
      if (mounted) setState(() => _selectedIndex = 3);
    };
    ShoppingCart.instance.onNavigateToTab = (index) {
      if (mounted) setState(() => _selectedIndex = index);
    };
    ShoppingCart.instance.addListener(_onCartChanged);
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  void _onLandingCatalogChanged() {
    if (!mounted) return;
    try {
      setState(() {
        _sellerFirebaseProducts =
            List<Map<String, dynamic>>.from(MarketplaceFirebaseCatalog.products);
      });
    } catch (e, st) {
      debugPrint('Marketplace catalog refresh: $e\n$st');
      if (mounted) {
        setState(() => _sellerFirebaseProducts = []);
      }
    }
  }

  Future<void> _loadTrackingCounts() async {
    try {
      final counts = await OrderTrackingService.getAllCounts();
      if (mounted) {
        setState(() => _trackingCounts = counts);
      }
    } catch (e, st) {
      debugPrint('Tracking counts load failed: $e\n$st');
    }
  }

  Future<void> _uploadAllProducts() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Uploading products to Firebase...')),
    );
    try {
      final count = await FirebaseService.uploadProductsFromList(_demoProductsForUpload);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully uploaded $count products!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading products: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_bannerController.hasClients) return;
      final next = (_currentBanner + 1) % banners.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  Widget _buildCompactBanner(int index) {
    final banner = banners[index];
    final badge = _bannerOverlayLine(banner, 'badge');
    final title = _bannerOverlayLine(banner, 'title');
    final subtitle = _bannerOverlayLine(banner, 'subtitle');
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            banner['image'] as String,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              color: MarketplaceTheme.primaryDark,
              child: const Icon(Icons.image_outlined, color: Colors.white54),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (badge.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: MarketplaceTheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                if (badge.isNotEmpty && title.isNotEmpty) const SizedBox(height: 6),
                if (title.isNotEmpty)
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openTryOnTab() {
    if (!mounted) return;
    setState(() {
      _selectedIndex = 2;
      _tryOnPanelKey++;
    });
  }

  Future<void> _applyHandoffFromUrl() async {
    try {
      final openTryOn = Uri.base.queryParameters['open_tryon'] == '1';
      final handoffParam = Uri.base.queryParameters['handoff'];
      var applied = false;

      if (openTryOn) {
        if (handoffParam != null && handoffParam.isNotEmpty) {
          applied = await TryOnHandoff.applyFromQueryParam(handoffParam);
        }
        if (!applied) {
          final sessionJson = webReadTryonHandoffJson();
          if (sessionJson != null && sessionJson.isNotEmpty) {
            applied = await TryOnHandoff.applyFromSessionJson(sessionJson);
            webClearTryonHandoff();
          }
        }
      } else if (handoffParam != null && handoffParam.isNotEmpty) {
        applied = await TryOnHandoff.applyFromQueryParam(handoffParam);
      }
      if (applied || openTryOn) {
        webClearHandoffQuery();
        _openTryOnTab();
      }
    } catch (e, st) {
      debugPrint('Handoff apply failed: $e\n$st');
    }
  }

  @override
  void dispose() {
    if (TryOnNavBridge.openTryOnTab == _openTryOnTab) {
      TryOnNavBridge.openTryOnTab = null;
    }
    ShoppingCart.instance.removeListener(_onCartChanged);
    ShoppingCart.instance.onNavigateToCart = null;
    ShoppingCart.instance.onNavigateToTab = null;
    _authProfileSub?.cancel();
    LandingCatalogStore.instance.removeListener(_onLandingCatalogChanged);
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Bundled landing GLBs + seller products from Firestore (`showOnLanding` != false).
  List<Map<String, dynamic>> get _filteredProducts {
    bool matches(Map<String, dynamic> product) {
      final cat = '${product['category'] ?? ''}'.trim();
      final matchesCategory =
          _selectedCategory == 'All' || cat == _selectedCategory;
      final titleLower = '${product['title'] ?? ''}'.toLowerCase();
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty || titleLower.contains(q);
      return matchesCategory && matchesSearch;
    }

    final out = <Map<String, dynamic>>[];
    final seen = <String>{};

    void tryAdd(Map<String, dynamic> product) {
      if (!matches(product)) return;
      final mp = product['modelPath']?.toString() ?? '';
      final id = product['firebaseProductId']?.toString() ?? product['id']?.toString() ?? '';
      final title = '${product['title'] ?? ''}';
      final key = '$mp|$id|$title';
      if (seen.contains(key)) return;
      seen.add(key);
      out.add(product);
    }

    try {
      for (final p in _bundledMarketplaceProducts) {
        tryAdd(Map<String, dynamic>.from(p));
      }
      if (kIncludeSellerListingsInMarketplace) {
        for (final p in _sellerFirebaseProducts) {
          tryAdd(Map<String, dynamic>.from(p));
        }
      }
    } catch (e, st) {
      debugPrint('Marketplace _filteredProducts: $e\n$st');
      return List<Map<String, dynamic>>.from(
        _bundledMarketplaceProducts.map((m) => Map<String, dynamic>.from(m)),
      );
    }
    return out;
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      MarketplaceBadgeService.instance.clearNewProducts();
    } else if (index == 1) {
      MarketplaceBadgeService.instance.clearNewReels();
    } else if (index == 4) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        TailorChatService.markAllReadForCustomer(uid);
        SellerChatService.markAllReadForCustomer(uid);
      }
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _open2dTryOn(BuildContext context) {
    setState(() => _selectedIndex = 2);
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final bannerHeight = (screenW * 0.78).clamp(300.0, 420.0);

    return Scaffold(
      floatingActionButton: null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ColoredBox(
        color: MarketplaceTheme.canvas,
        child: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
                const SliverToBoxAdapter(child: DeployedBackendBanner()),
                SliverToBoxAdapter(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: MarketplaceTheme.surface,
                      border: Border(bottom: BorderSide(color: MarketplaceTheme.border)),
                    ),
                    child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TailorPortfolioScreen(
                                  tailor: kFeaturedTailorProfile,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: MarketplaceTheme.canvas,
                                child: Icon(
                                  Icons.storefront,
                                  size: 22,
                                  color: MarketplaceTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '3D Marketplace',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: MarketplaceTheme.primary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  Text(
                                    _marketplaceUserProfile?.name ?? 'Sign in',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: MarketplaceTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        TextButton.icon(
                          onPressed: () => _open2dTryOn(context),
                          icon: const Icon(Icons.checkroom, size: 18),
                          label: const Text('2D Try On'),
                          style: TextButton.styleFrom(
                            foregroundColor: MarketplaceTheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz, color: MarketplaceTheme.textSecondary),
                          onSelected: (value) {
                            if (value == 'tryon_2d') {
                              _open2dTryOn(context);
                            } else if (value == 'debug_orders') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => DebugOrdersPage()),
                              );
                            } else if (value == 'connectivity') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => FirebaseConnectivityCheckPage()),
                              );
                            } else if (value == 'upload_products') {
                              _uploadAllProducts();
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'tryon_2d',
                              child: Row(
                                children: [
                                  Icon(Icons.checkroom, color: Color(0xFF059669), size: 20),
                                  SizedBox(width: 10),
                                  Text('2D Virtual Try-On'),
                                ],
                              ),
                            ),
                            PopupMenuDivider(),
                            PopupMenuItem(value: 'debug_orders', child: Text('Debug Orders')),
                            PopupMenuItem(value: 'connectivity', child: Text('Firebase Check')),
                            PopupMenuDivider(),
                            PopupMenuItem(value: 'upload_products', child: Text('Upload All Products')),
                          ],
                        ),

                      ],
                    ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Container(
                    color: MarketplaceTheme.surface,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: MarketplaceTheme.canvas,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: MarketplaceTheme.border),
                            ),
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Icon(Icons.search, color: MarketplaceTheme.textSecondary, size: 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    onChanged: (value) => setState(() => _searchQuery = value),
                                    decoration: const InputDecoration(
                                      hintText: 'Search products...',
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: MarketplaceTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.tune, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                    child: Column(
                      children: [
                        SizedBox(
                          height: bannerHeight,
                          child: PageView.builder(
                            controller: _bannerController,
                            onPageChanged: (index) {
                              setState(() => _currentBanner = index);
                              _startBannerAutoScroll();
                            },
                            itemCount: banners.length,
                            itemBuilder: (_, index) => _buildCompactBanner(index),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            banners.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: _currentBanner == index ? 18 : 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: _currentBanner == index
                                    ? MarketplaceTheme.primary
                                    : MarketplaceTheme.border,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Container(
                    color: MarketplaceTheme.surface,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (FirebaseAuth.instance.currentUser == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sign in as a user to track orders')),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(builder: (_) => const UserOrdersPageFirebase()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                              decoration: BoxDecoration(
                                color: MarketplaceTheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: MarketplaceTheme.primary.withValues(alpha: 0.22),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.local_shipping_outlined,
                                      color: MarketplaceTheme.primary, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'Track orders',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: MarketplaceTheme.primary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Container(
                      width: double.infinity,
                      color: MarketplaceTheme.surface,
                      padding: const EdgeInsets.fromLTRB(12, 2, 12, 14),
                      child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          {'icon': Icons.inventory_2_outlined, 'label': 'Seller to\nTailor', 'key': 'seller_to_tailor'},
                          {'icon': Icons.local_shipping_outlined, 'label': 'Tailor\nDelivered', 'key': 'tailor_delivered'},
                          {'icon': Icons.check_circle_outline, 'label': 'Tailor Ready', 'key': 'tailor_ready'},
                          {'icon': Icons.outbound_outlined, 'label': 'Tailor to\nShip', 'key': 'tailor_to_ship'},
                          {'icon': Icons.markunread_mailbox_outlined, 'label': 'Delivered', 'key': 'delivered'},
                          {'icon': Icons.cancel_presentation, 'label': 'Cancelled', 'key': 'cancelled'},
                        ].map((item) {
                          final count = _trackingCounts[item['key']] ?? 0;
                          return GestureDetector(
                            onTap: () {
                              String title = (item['label'] as String).replaceAll('\n', ' ');
                              _showOrderDetails(context, title);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: SizedBox(
                                width: 82,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: MarketplaceTheme.surface,
                                            border: Border.all(
                                              color: MarketplaceTheme.primary.withValues(alpha: 0.35),
                                              width: 1.5,
                                            ),
                                            boxShadow: [MarketplaceTheme.cardShadow],
                                          ),
                                          child: Icon(
                                            item['icon'] as IconData,
                                            color: MarketplaceTheme.primary,
                                            size: 36,
                                          ),
                                        ),
                                        Positioned(
                                          right: -2,
                                          top: -2,
                                          child: Container(
                                            padding: const EdgeInsets.all(5),
                                            constraints: const BoxConstraints(
                                              minWidth: 22,
                                              minHeight: 22,
                                            ),
                                            decoration: BoxDecoration(
                                              color: MarketplaceTheme.badge,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 1.5),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              count.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                height: 1,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item['label'] as String,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: MarketplaceTheme.textPrimary,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),


            SliverToBoxAdapter(
              child: LandingCategoryCatalog(
                screenWidth: screenW,
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      ),
      ReelScreen(active: _selectedIndex == 1),
      TryOnMarketplaceTab(
        key: ValueKey<int>(_tryOnPanelKey),
        embeddedInNav: true,
      ),
      CartScreen(
        onBackToShopping: () => setState(() => _selectedIndex = 0),
      ),
      ChatScreen(),
      ProfileScreen(),
        ],
      ),
      bottomNavigationBar: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnap) {
          final uid = authSnap.data?.uid ?? '';
          return StreamBuilder<int>(
            stream: CustomerChatBadges.unreadTotal(uid),
            initialData: 0,
            builder: (context, chatSnap) {
              return MarketplaceBottomNav(
                selectedIndex: _selectedIndex,
                onTap: _onItemTapped,
                chatUnread: chatSnap.data ?? 0,
              );
            },
          );
        },
      ),
    );
  }
  void _showOrderDetails(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$title Orders",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
              ),
              SizedBox(height: 15),
              _buildOrderListItem("Custom Suit - Order #4821", title, "PKR 4,500", Icons.shopping_bag),
              SizedBox(height: 15),
              _buildOrderListItem("Kurtas - Order #4825", title, "PKR 2,200", Icons.checkroom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderListItem(String orderName, String status, String price, IconData icon) {
     return Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Color(0xFF059669).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Color(0xFF059669).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Color(0xFF5D4037).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: Color(0xFF5D4037), size: 30),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(orderName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 5),
                          Text("Status: $status", style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w500)),
                          SizedBox(height: 5),
                          Text(price, style: TextStyle(color: Color(0xFF5D4037), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ),
              );
  }
}