import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'studio_3d_embed.dart';
import 'studio_catalog_service.dart';
import 'studio_config.dart';

/// Flutter **web only** — iframe to remote Vercel studio (APK uses browser via [StudioOpener]).
class Studio3dScreen extends StatefulWidget {
  const Studio3dScreen({super.key, this.snapmeasureToken});

  final String? snapmeasureToken;

  @override
  State<Studio3dScreen> createState() => _Studio3dScreenState();
}

class _Studio3dScreenState extends State<Studio3dScreen> {
  int? _productCount;
  String? _catalogError;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final catalog = await StudioCatalogService.instance.fetchCatalog();
    if (!mounted) return;
    setState(() {
      if (catalog != null && catalog.products.isNotEmpty) {
        _productCount = catalog.products.length;
        _catalogError = null;
      } else {
        _productCount = null;
        _catalogError =
            'Catalog API unavailable — loading studio from ${StudioConfig.studioBaseUrl}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final embedUri = StudioConfig.embedUri(
      snapmeasureToken: widget.snapmeasureToken,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '3D Studio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _productCount != null
                  ? '$_productCount products · remote API'
                  : 'Hosted on ${StudioConfig.apiOrigin}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh catalog',
            onPressed: _loadCatalog,
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
      body: kIsWeb
          ? Studio3dEmbedPanel(embedUrl: embedUri)
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _catalogError ?? 'Open 3D Studio uses your browser on mobile.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }
}
