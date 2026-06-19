import 'package:flutter/material.dart';

import '../config/production_urls.dart';
import '../widgets/online_web_panel.dart';

/// Phone APK: 2D try-on via live Vercel shop (same as website) — no localhost.
class TryOnVercelWebView extends StatelessWidget {
  const TryOnVercelWebView({super.key, this.embeddedInNav = false});

  final bool embeddedInNav;

  static Uri get vercelTryOnUri {
    const override = String.fromEnvironment('TRYON_WEB_URL', defaultValue: '');
    final base = override.trim().isNotEmpty
        ? override.trim()
        : ProductionUrls.shop.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse(base).replace(
      queryParameters: const {
        'mobile': '1',
        'embed': '1',
        'tryon': '1',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnlineWebPanel(
      url: vercelTryOnUri,
      title: '2D Try On',
      showAppBar: !embeddedInNav,
    );
  }
}
