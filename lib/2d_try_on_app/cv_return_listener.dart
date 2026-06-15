import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../User 3D Market Place/camera_work_computer_vision/camera_cv_web_launcher.dart';
import 'captured_photo_session.dart';
import 'try_on_nav_bridge.dart';
import 'try_on_screen.dart';

/// After camera cv_return session, opens try-on tab or screen.
class CvReturnListener extends StatefulWidget {
  const CvReturnListener({
    super.key,
    required this.child,
    this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<CvReturnListener> createState() => _CvReturnListenerState();
}

class _CvReturnListenerState extends State<CvReturnListener> {
  static bool _handledThisSession = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleCameraReturn());
    }
  }

  Future<void> _handleCameraReturn() async {
    if (_handledThisSession) return;
    if (Uri.base.queryParameters.containsKey('handoff')) return;

    final payload = CameraCvWebLauncher.consumeReturnPayload();
    if (payload == null) return;
    _handledThisSession = true;

    final openTryOn = CameraCvWebLauncher.consumeOpenTryOnFlag() ||
        payload['open_tryon'] == true;
    if (!openTryOn) return;

    final imageUrl = payload['image_url'] as String?;
    final lmRaw = payload['landmarks_count'];
    final lm = lmRaw is int ? lmRaw : int.tryParse('$lmRaw') ?? 0;
    CapturedPhotoSession.apply(url: imageUrl, landmarks: lm);
    await _openTryOnFromCapture();
  }

  Future<void> _openTryOnFromCapture() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    if (TryOnNavBridge.openTryOnTab != null) {
      TryOnNavBridge.openTryOnTab!();
      return;
    }

    final navContext = widget.navigatorKey?.currentContext;
    final ctx = (navContext != null && navContext.mounted) ? navContext : context;
    if (!ctx.mounted) return;

    await TryOn2dScreen.open(
      ctx,
      personImageUrl: CapturedPhotoSession.imageUrl,
      landmarkCount: CapturedPhotoSession.landmarkCount,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
