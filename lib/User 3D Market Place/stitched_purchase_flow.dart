import 'package:flutter/material.dart';

import '../../services/marketplace_demo_seller.dart';
import 'product_viewer.dart';
import 'size prediction model/live_measurement.dart';
import 'standard_sizes.dart';

bool isStitchedOutfit(Map<String, dynamic> product) {
  final cat = (product['category'] ?? '').toString();
  final section = (product['section'] ?? '').toString();
  if (cat == 'Fabric' || section == 'Fabric') return false;
  return cat.contains('Kurta') ||
      cat.contains('Shalwar') ||
      section.contains('Kurta') ||
      section.contains('Shalwar');
}

Future<void> showStitchedPurchaseSheet(
  BuildContext context,
  Map<String, dynamic> product, {
  required bool openCartAfter,
}) async {
  final stamped = await MarketplaceDemoSeller.attachAsync(product);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                stamped['title']?.toString() ?? 'Choose sizing',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pick standard chart or live AI measurement',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              _sheetOption(
                icon: Icons.straighten,
                title: 'Standard size',
                subtitle: 'Size chart — Kurta & Pyjama',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => StandardSizesScreen(
                        product: stamped,
                        openCartOnComplete: openCartAfter,
                        onBack: () => Navigator.pop(context),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _sheetOption(
                icon: Icons.camera_alt,
                title: 'Live measurement',
                subtitle: 'AI camera fitting flow',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => LiveMeasurementScreen(
                        product: stamped,
                        onBack: () => Navigator.pop(context),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _sheetOption({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return Material(
    color: const Color(0xFFF8FAF9),
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF059669)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade500),
          ],
        ),
      ),
    ),
  );
}

void openProductOrPurchase(
  BuildContext context,
  Map<String, dynamic> product, {
  required bool openCartAfter,
}) async {
  final stamped = await MarketplaceDemoSeller.attachAsync(product);
  if (!context.mounted) return;
  if (isStitchedOutfit(stamped)) {
    showStitchedPurchaseSheet(context, stamped, openCartAfter: openCartAfter);
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ProductViewerScreen(product: stamped),
    ),
  );
}
