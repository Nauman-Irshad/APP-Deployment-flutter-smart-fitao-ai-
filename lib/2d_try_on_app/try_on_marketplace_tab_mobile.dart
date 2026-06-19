import 'package:flutter/material.dart';

import 'try_on_vercel_webview.dart';

/// Phone APK: WebView → live Vercel 2D try-on shop.
class TryOnMarketplaceTab extends StatelessWidget {
  const TryOnMarketplaceTab({
    super.key,
    this.embeddedInNav = false,
  });

  final bool embeddedInNav;

  @override
  Widget build(BuildContext context) {
    return TryOnVercelWebView(embeddedInNav: embeddedInNav);
  }
}
