import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../User 3D Market Place/camera_work_computer_vision/camera_cv_web_launcher.dart';
import '../services/customer_fitting_store.dart';
import '../services/customer_fitting_store_stub.dart'
    if (dart.library.html) '../services/customer_fitting_store_web.dart';
import 'captured_photo_session.dart';
import 'try_on_handoff.dart';
import 'try_on_measurements_store.dart';
import 'try_on_order_session.dart';
import 'try_on_screen.dart';

/// Entry for standalone try-on app (:65109). Loads camera photo when opened via **2D Try On**.
class TryOnAppRoot extends StatefulWidget {
  const TryOnAppRoot({super.key});

  @override
  State<TryOnAppRoot> createState() => _TryOnAppRootState();
}

class _TryOnAppRootState extends State<TryOnAppRoot> {
  String? _photoUrl;
  int _landmarkCount = 0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadCameraReturn());
    } else {
      _ready = true;
    }
  }

  Future<void> _loadCameraReturn() async {
    final handoff = Uri.base.queryParameters['handoff'];
    if (handoff != null && handoff.isNotEmpty) {
      await TryOnHandoff.applyFromQueryParam(handoff);
      webClearHandoffQuery();
    } else {
      await CustomerFittingStore.syncSessionFromLocal();
      final cm = loadTryOnMeasurementsCm();
      if (cm != null && cm.isNotEmpty) {
        TryOnOrderSession.instance.applyMeasurements(cm);
      }
      final payload = CameraCvWebLauncher.consumeTryOnPayload();
      if (payload != null) {
        final imageUrl = payload['image_url'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          final lmRaw = payload['landmarks_count'];
          final lm = lmRaw is int ? lmRaw : int.tryParse('$lmRaw') ?? 0;
          CapturedPhotoSession.apply(url: imageUrl, landmarks: lm);
        }
      }
    }

    final photoUrl = CapturedPhotoSession.imageUrl;
    final lm = CapturedPhotoSession.landmarkCount;
    setState(() {
      _photoUrl = photoUrl;
      _landmarkCount = lm;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return TryOn2dScreen(
      initialPersonImageUrl: _photoUrl ?? CapturedPhotoSession.imageUrl,
      initialPersonBytes: CapturedPhotoSession.personBytes,
      landmarkCount: _landmarkCount > 0
          ? _landmarkCount
          : CapturedPhotoSession.landmarkCount,
    );
  }
}
