import 'package:flutter/foundation.dart';

import 'mobile_media_config_stub.dart'
    if (dart.library.html) 'mobile_media_config_web.dart' as platform;

/// True on phones / narrow viewports — use lighter media (720p reels, fewer preloads).
bool get preferLightMedia => platform.preferLightMedia;

/// How many marketplace GLBs to prefetch at app start (rest load on demand).
int get glbPreloadCount => preferLightMedia ? 2 : 4;

/// Prefetch adjacent reel videos while scrolling (uses extra bandwidth on mobile).
bool get prefetchAdjacentReels => !preferLightMedia;
