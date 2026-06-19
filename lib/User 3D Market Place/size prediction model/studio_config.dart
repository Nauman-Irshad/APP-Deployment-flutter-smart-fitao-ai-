import 'package:flutter/foundation.dart';

import '../../config/live_backend_config.dart';

/// Remote 3D Studio — hosted on Vercel; **nothing bundled in the APK**.
///
/// Local website + NLP chat (Vite, port 5177):
/// `--dart-define=STUDIO_LOCAL_DEV=true`
///
/// Local studio only (port 5174):
/// `--dart-define=CLOTH_STUDIO_URL=http://127.0.0.1:5174/studio/`
///
/// Production (default): deployed studio root on Vercel.
class StudioConfig {
  StudioConfig._();

  /// Deployed studio (pifuhd-main Vercel). Change after you deploy your own project.
  static const String _productionStudioUrl =
      'https://fyp-web-code-deployment-flea.vercel.app/';

  /// Vite dev server for website + smart-fitao-chat + GLBs (`npm run dev` in Figma frontend).
  static const int localWebsitePort = 5177;

  static const String _studioUrlOverride = String.fromEnvironment(
    'CLOTH_STUDIO_URL',
    defaultValue: '',
  );

  static const String _apiBaseOverride = String.fromEnvironment(
    'STUDIO_API_BASE',
    defaultValue: '',
  );

  /// Physical phone on Wi‑Fi: `--dart-define=LOCAL_DEV_HOST=192.168.1.5`
  static const String _localDevHostOverride = String.fromEnvironment(
    'LOCAL_DEV_HOST',
    defaultValue: '',
  );

  /// `true` → chat + GLBs from local Vite (port [localWebsitePort]). Run `App/scripts/start-local-website-for-app.ps1` first.
  static const bool useLocalWebsite = bool.fromEnvironment(
    'STUDIO_LOCAL_DEV',
    defaultValue: false,
  );

  /// Host reachable from the current device (emulator uses 10.0.2.2 for PC localhost).
  static String get localDevHost {
    final override = _localDevHostOverride.trim();
    if (override.isNotEmpty) return override;
    if (kIsWeb) return '127.0.0.1';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '10.0.2.2';
      default:
        return '127.0.0.1';
    }
  }

  static String get _localWebsiteOrigin =>
      'http://$localDevHost:$localWebsitePort';

  static String get studioBaseUrl {
    var s = _studioUrlOverride.trim();
    if (s.isEmpty) {
      if (useLocalWebsite) return '$_localWebsiteOrigin/';
      s = _productionStudioUrl;
    }
    if (!s.endsWith('/')) s = '$s/';
    return s;
  }

  static String get apiOrigin {
    final override = _apiBaseOverride.trim();
    if (override.isNotEmpty) {
      return override.endsWith('/')
          ? override.substring(0, override.length - 1)
          : override;
    }
    if (useLocalWebsite) return _localWebsiteOrigin;
    final uri = Uri.parse(studioBaseUrl);
    if (uri.hasScheme && uri.host.isNotEmpty) {
      final defaultPort = uri.scheme == 'https' ? 443 : 80;
      final port = uri.hasPort && uri.port != defaultPort ? ':${uri.port}' : '';
      return '${uri.scheme}://${uri.host}$port';
    }
    return _productionStudioUrl.replaceAll(RegExp(r'/$'), '');
  }

  static bool get isLocalHost {
    final host = Uri.tryParse(studioBaseUrl)?.host.toLowerCase() ?? '';
    return host == '127.0.0.1' ||
        host == 'localhost' ||
        host == '10.0.2.2';
  }

  static Uri get catalogApiUri => Uri.parse('$apiOrigin/api/catalog');

  static Uri get catalogStaticUri => Uri.parse('$apiOrigin/catalog.json');

  static Uri get healthUri => Uri.parse('$apiOrigin/api/health');

  static Uri get appModelsCatalogUri =>
      Uri.parse('$apiOrigin/api/app-models-catalog');

  /// NLP chat UI — Vercel `/smart-fitao-chat/` or local Vite when [useLocalWebsite].
  /// Override: `--dart-define=SMARTFITAO_CHAT_URL=http://127.0.0.1:5177/smart-fitao-chat/`
  static Uri get smartFitaoChatUri {
    const override = String.fromEnvironment(
      'SMARTFITAO_CHAT_URL',
      defaultValue: '',
    );
    if (override.trim().isNotEmpty) {
      var u = override.trim();
      if (!u.endsWith('/')) u = '$u/';
      return Uri.parse(u);
    }
    if (useLocalNlpOnWeb) {
      return Uri.parse('http://127.0.0.1:5002/');
    }
    if (useLocalWebsite) {
      return Uri.parse('$_localWebsiteOrigin/smart-fitao-chat/');
    }
    return Uri.parse('$apiOrigin/smart-fitao-chat/');
  }

  /// Flutter web on PC (e.g. :65106) — NLP Flask on :5002.
  static bool get useLocalNlpOnWeb {
    if (!kIsWeb || useLocalWebsite) return false;
    final h = Uri.base.host.toLowerCase();
    return h == '127.0.0.1' || h == 'localhost';
  }

  static bool get isLocalChat =>
      useLocalWebsite || isLocalHost || useLocalNlpOnWeb;

  /// Phone APK always loads hosted chat (Vercel WebView). Bundled asset is dev-only.
  static bool get useBundledChatInApp {
    if (kIsWeb || useLocalWebsite) return false;
    if (LiveBackendConfig.isPhoneOrTabletApp) return false;
    const forceRemote = bool.fromEnvironment(
      'FORCE_REMOTE_CHAT',
      defaultValue: false,
    );
    if (forceRemote) return false;
    const chatOverride = String.fromEnvironment(
      'SMARTFITAO_CHAT_URL',
      defaultValue: '',
    );
    return chatOverride.trim().isEmpty;
  }

  static const String bundledChatAsset = 'assets/smart-fitao-chat/index.html';

  static Uri get chatApiUri => Uri.parse('$apiOrigin/api/chat');

  /// CDN URL for GLB/GLTF/images under studio `public/` (keeps APK small).
  static String remotePublicUrl(String publicPath) {
    var p = publicPath.trim();
    if (p.isEmpty) return '';
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    if (!p.startsWith('/')) p = '/$p';
    final encoded =
        p.split('/').map((s) => s.isEmpty ? '' : Uri.encodeComponent(s)).join('/');
    return '$apiOrigin$encoded';
  }

  /// Studio embed / deep-link with measurements + mobile landscape layout.
  static Uri embedUri({String? snapmeasureToken}) {
    final base = studioBaseUrl.endsWith('/')
        ? studioBaseUrl.substring(0, studioBaseUrl.length - 1)
        : studioBaseUrl;
    final params = <String, String>{
      'mobile': '1',
      'embed': '1',
    };
    if (snapmeasureToken != null && snapmeasureToken.isNotEmpty) {
      params['snapmeasure'] = snapmeasureToken;
    }
    return Uri.parse(base).replace(queryParameters: params);
  }
}
