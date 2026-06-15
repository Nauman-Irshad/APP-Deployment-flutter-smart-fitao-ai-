import 'package:flutter/material.dart';

import 'category_products_page.dart';
import 'landing_catalog_store.dart';
import 'landing_hero_3d.dart';
import 'marketplace_theme.dart';
import 'viewer_asset_src.dart';

/// Landing preview: category slider + 3 sections (4 each) + action buttons.
class LandingCategoryCatalog extends StatefulWidget {
  const LandingCategoryCatalog({
    super.key,
    required this.onFindTailor,
    required this.onBecomeSeller,
    required this.screenWidth,
  });

  final VoidCallback onFindTailor;
  final VoidCallback onBecomeSeller;
  final double screenWidth;

  @override
  State<LandingCategoryCatalog> createState() => _LandingCategoryCatalogState();
}

class _LandingCategoryCatalogState extends State<LandingCategoryCatalog> {
  @override
  void initState() {
    super.initState();
    LandingCatalogStore.instance.startFirebaseSync();
    LandingCatalogStore.instance.addListener(_rebuild);
    LandingCatalogStore.instance.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    LandingCatalogStore.instance.removeListener(_rebuild);
    super.dispose();
  }

  int get _gridColumns {
    if (widget.screenWidth > 1000) return 4;
    if (widget.screenWidth > 600) return 2;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LandingCategorySlider(),
        Container(
          color: MarketplaceTheme.canvas,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CategorySection(
                title: 'Kurta Shalwar',
                products: landingProductsForSection('Kurta Shalwar'),
                columns: _gridColumns,
              ),
              const SizedBox(height: 28),
              _CategorySection(
                title: 'Shalwar Kameez',
                products: landingProductsForSection('Shalwar Kameez'),
                columns: _gridColumns,
              ),
              const SizedBox(height: 28),
              _CategorySection(
                title: 'Fabric',
                products: landingProductsForSection('Fabric'),
                columns: _gridColumns,
              ),
              const SizedBox(height: 28),
              _ActionBanner(
                title: 'Find Your Perfect Tailor',
                subtitle:
                    'Connect with expert tailors for custom stitching & perfect fit.',
                gradient: const [MarketplaceTheme.primaryDark, MarketplaceTheme.primary],
                icon: Icons.arrow_forward,
                iconBg: Colors.white,
                iconColor: MarketplaceTheme.primaryDark,
                onTap: widget.onFindTailor,
              ),
              const SizedBox(height: 12),
              _ActionBanner(
                title: 'Become a Seller',
                subtitle: 'Login as a seller to manage products and sales.',
                gradient: const [Color(0xFF1F2937), Color(0xFF374151)],
                icon: Icons.store,
                iconBg: Colors.white,
                iconColor: Color(0xFF1F2937),
                onTap: widget.onBecomeSeller,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.products,
    required this.columns,
  });

  final String title;
  final List<Map<String, dynamic>> products;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _SectionHeading(title: title)),
            TextButton(
              onPressed: () => openCategoryPage(context, title),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('See more', style: TextStyle(color: MarketplaceTheme.primary)),
                  Icon(Icons.chevron_right, color: MarketplaceTheme.primary, size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final spacing = 14.0;
            final itemWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            final items = products;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: items
                  .asMap()
                  .entries
                  .map((e) => SizedBox(
                        width: itemWidth,
                        child: CategoryProductCard(
                          product: e.value,
                          show3dPreview: productHasRemoteGlbUrl(e.value),
                          staggerIndex: e.key,
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ActionBanner extends StatelessWidget {
  const _ActionBanner({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final List<Color> gradient;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: MarketplaceTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: MarketplaceTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
