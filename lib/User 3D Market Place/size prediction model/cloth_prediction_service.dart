import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'cloth_measurement_models.dart';
import 'cloth_prediction_config.dart';

/// Calls Flask `/predict`, `/api/health` — Render live or local Flask.

class ClothPredictionService {
  ClothPredictionService._();
  static final ClothPredictionService instance = ClothPredictionService._();

  static const Duration _predictTimeout = Duration(seconds: 90);
  static const Duration _wakeTimeout = Duration(seconds: 120);

  /// Wake Render free tier (cold start) before POST /predict.
  Future<void> ensureApiReady() async {
    final health = ClothPredictionConfig.uri('/api/health');
    Object? lastError;
    for (var attempt = 1; attempt <= 5; attempt++) {
      try {
        final res = await http.get(health).timeout(_wakeTimeout);
        if (res.ok) {
          final m = jsonDecode(res.body.isEmpty ? '{}' : res.body);
          if (m is Map && m['model_loaded'] == true) return;
        }
      } catch (e) {
        lastError = e;
      }
      if (attempt < 5) {
        await Future<void>.delayed(Duration(seconds: attempt * 3));
      }
    }
    if (ClothPredictionConfig.usesLiveRender) {
      throw ClothPredictionException(
        'Size API on Render is still waking up. Wait ~1 minute, then tap Predict again.'
        '${lastError != null ? ' ($lastError)' : ''}',
      );
    }
  }

  /// Fire-and-forget ping while user browses marketplace (no error if cold).
  void warmApiInBackground() {
    if (!ClothPredictionConfig.usesLiveRender) return;
    ensureApiReady().then((_) {}, onError: (_) {});
  }

  Future<Map<String, double>> predict({
    required ClothWizardStep1Data step1,
    required ClothWizardBodyPrefs prefs,
  }) async {
    if (ClothPredictionConfig.usesLiveRender) {
      await ensureApiReady();
    }
    final uri = ClothPredictionConfig.uri('/predict');
    try {
      return await _predictAt(uri, step1, prefs);
    } on Exception catch (e) {
      if (e is ClothPredictionException) rethrow;
      throw ClothPredictionException(_connectionMessage(uri, e));
    }
  }

  String _connectionMessage(Uri uri, Object e) {
    if (ClothPredictionConfig.usesLiveRender) {
      return 'Cannot reach live size API ($uri). '
          'Render may be cold — wait 1 minute and try again. ($e)';
    }
    return 'Cannot connect to $uri — start Flask: '
        'pifuhd-main\\Ai Cloth Size Prediction\\start-flask.ps1 ($e)';
  }

  Future<Map<String, double>> _predictAt(
    Uri uri,
    ClothWizardStep1Data step1,
    ClothWizardBodyPrefs prefs,
  ) async {
    final body = <String, dynamic>{
      'age': step1.ageInt,
      'height': step1.heightCm,
      'weight': step1.weightKg,
      'bodyType': prefs.bodyType,
      'collarFit': prefs.collarFit,
      'shoulderType': prefs.shoulderType,
      'fitPreference': prefs.fitPreference,
      'activityLevel': 'Moderate',
      'sleeveStyle': 'Medium',
      'kameezLengthPref': 'Medium',
    };

    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(_predictTimeout);

    final payload =
        jsonDecode(res.body.isEmpty ? '{}' : res.body) as Map<String, dynamic>;

    if (!res.ok) {
      final msg = payload['error'];
      throw ClothPredictionException(
        msg is String
            ? msg
            : 'Prediction failed (${res.statusCode}).',
      );
    }
    if (payload['error'] is String) {
      throw ClothPredictionException(payload['error'] as String);
    }

    final out = <String, double>{};
    for (final e in payload.entries) {
      final v = e.value;
      if (v is num) out[e.key] = v.toDouble();
    }
    return out;
  }

  Future<bool> fetchModelLoaded() async {
    try {
      final res =
          await http.get(ClothPredictionConfig.uri('/api/health')).timeout(
                const Duration(seconds: 30),
              );
      if (!res.ok) return false;
      final m = jsonDecode(res.body) as Map<String, dynamic>;
      return m['model_loaded'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchModelMetrics() async {
    try {
      final res =
          await http.get(ClothPredictionConfig.uri('/api/model-metrics')).timeout(
                const Duration(seconds: 30),
              );
      if (!res.ok) return null;
      final m = jsonDecode(res.body);
      if (m is Map<String, dynamic> &&
          m['per_target'] is Map<String, dynamic>) {
        return m;
      }
    } catch (_) {}
    return null;
  }
}

class ClothPredictionException implements Exception {
  final String message;
  ClothPredictionException(this.message);

  @override
  String toString() => message;
}

extension _Ok on http.Response {
  bool get ok => statusCode >= 200 && statusCode < 300;
}
