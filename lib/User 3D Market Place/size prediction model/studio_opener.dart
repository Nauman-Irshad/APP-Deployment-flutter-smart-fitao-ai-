import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/customer_fitting_store.dart';
import 'cloth_studio_bridge.dart';
import 'studio_3d_screen.dart';
import 'studio_config.dart';

/// Opens **remote** 3D Studio (Vercel). No studio assets in the APK.
class StudioOpener {
  StudioOpener._();

  static Future<void> openFromMeasurements(
    BuildContext context, {
    required Map<String, double> measurementsCm,
    required String fitPreference,
    Map<String, dynamic>? perTargetR2,
    double? meanR2,
  }) async {
    if (!kIsWeb && StudioConfig.isLocalHost) {
      if (!context.mounted) return;
      await _showLocalhostBlocked(context);
      return;
    }

    final payload = clothBuildStoredFitPayload(
      measurementsCm,
      fitPreference,
      perTargetR2: perTargetR2,
      meanR2: meanR2,
    );
    final prefs = await SharedPreferences.getInstance();
    final fitJson = jsonEncode(payload);
    await prefs.setString(clothStorageKeyLastFit, fitJson);
    CustomerFittingStore.webPersistLastFitJson(fitJson);
    if (!context.mounted) return;

    final token = clothEncodeFitForStudioQuery(payload);
    final uri = StudioConfig.embedUri(snapmeasureToken: token);

    // Mobile APK: external browser = reliable WebGL, zero studio weight in APK.
    if (!kIsWeb) {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!context.mounted) return;
      if (ok) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('3D Studio opened in browser with your sizes'),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await _showOpenFailed(context, uri);
      }
      return;
    }

    // Flutter web: in-app iframe on same Vercel origin.
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Studio3dScreen(snapmeasureToken: token),
        fullscreenDialog: true,
      ),
    );
  }

  static Future<void> _showLocalhostBlocked(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('3D Studio needs deploy URL'),
        content: Text(
          'On a phone, studio runs from your Vercel host — not localhost.\n\n'
          'Build with:\n'
          '--dart-define=CLOTH_STUDIO_URL=${StudioConfig.studioBaseUrl}\n\n'
          'Or deploy pifuhd-main to Vercel (default: ${StudioConfig.apiOrigin}).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  static Future<void> _showOpenFailed(BuildContext context, Uri uri) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Could not open 3D Studio'),
        content: Text('Check internet and studio deploy:\n$uri'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }
}
