import 'package:flutter/foundation.dart';

import '../2d_try_on_app/try_on_config.dart';
import '../User 3D Market Place/camera_work_computer_vision/camera_cv_config.dart';
import '../User 3D Market Place/size prediction model/cloth_prediction_config.dart';
import 'media_cdn_config.dart';

/// Summary of which backends the app is using (shown on Edge / web).
class DeployedBackendStatus {
  DeployedBackendStatus._();

  static bool get showOnWeb => false;

  static bool get isDeployedMode {
    final size = ClothPredictionConfig.baseUrl.toLowerCase();
    final cam = CameraCvConfig.baseUrl.toLowerCase();
    if (size.contains('127.0.0.1') ||
        size.contains('localhost') ||
        cam.contains('127.0.0.1') ||
        cam.contains('localhost')) {
      return false;
    }
    return size.contains('onrender.com') || cam.contains('vercel.app');
  }

  static String get modeLabel =>
      isDeployedMode ? 'DEPLOYED (LIVE)' : 'LOCAL DEV';

  static String get sizeApi => ClothPredictionConfig.baseUrl;

  static String get mediaCdn => MediaCdnConfig.cdnBase;

  static String get cameraApi => CameraCvConfig.baseUrl;

  static String get tryOnApi => TryOnConfig.apiBase;

  static List<String> get lines => [
        'Mode: $modeLabel',
        'Size: $sizeApi',
        '3D + Reels: $mediaCdn',
        'Camera: $cameraApi',
        '2D Try-on: $tryOnApi',
      ];
}
