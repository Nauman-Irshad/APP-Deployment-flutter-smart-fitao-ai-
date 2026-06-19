import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'try_on_config.dart';
import 'try_on_image_prep.dart';

class TryOnApiException implements Exception {
  TryOnApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class TryOnHealthInfo {
  const TryOnHealthInfo({
    required this.ok,
    required this.vtonMode,
    required this.etaLabel,
    required this.message,
  });

  final bool ok;
  final String vtonMode;
  final String etaLabel;
  final String message;

  bool get isRealAi => vtonMode == 'real';
}

class TryOnResult {
  const TryOnResult({this.url, this.base64, this.bytes});
  final String? url;
  final String? base64;
  final List<int>? bytes;
}

class TryOnApiClient {
  TryOnApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  void dispose() => _client.close();

  Future<TryOnHealthInfo> fetchHealth() async {
    try {
      final uri = Uri.parse(TryOnConfig.apiUrl('/health'));
      final res = await _client.get(uri).timeout(const Duration(seconds: 45));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        return TryOnHealthInfo(
          ok: false,
          vtonMode: 'offline',
          etaLabel: '',
          message:
              'Try-on API returned ${res.statusCode}. Run npm run api in id-2d-try-on',
        );
      }
      Map<String, dynamic>? data;
      try {
        final parsed = jsonDecode(res.body);
        if (parsed is Map<String, dynamic>) data = parsed;
      } catch (_) {}

      final mode = (data?['vton_mode'] as String?) ?? 'real';
      final etaMin = data?['eta_minutes']?.toString();
      final etaSec = data?['eta_seconds'];
      var etaLabel = '';
      if (mode == 'preview') {
        etaLabel = 'Preview mode';
      } else if (etaMin != null && etaMin.isNotEmpty) {
        etaLabel = 'Real AI · $etaMin';
      } else if (etaSec is num) {
        etaLabel = 'Real AI · ~${etaSec.round()} sec';
      } else {
        etaLabel = 'Real AI · IDM-VTON';
      }

      return TryOnHealthInfo(
        ok: true,
        vtonMode: mode,
        etaLabel: etaLabel,
        message: '',
      );
    } catch (_) {
      return TryOnHealthInfo(
        ok: false,
        vtonMode: 'offline',
        etaLabel: '',
        message:
            'Try-on API offline. Start: cd id-2d-try-on && npm run api (port 8765)',
      );
    }
  }

  Future<({bool ok, String message})?> checkHealth() async {
    final h = await fetchHealth();
    if (h.ok) return (ok: true, message: '');
    return (ok: false, message: h.message);
  }

  Future<TryOnResult> runTryOn({
    required List<int> humanJpeg,
    required List<int> garmentJpeg,
    String garmentDescription = TryOnConfig.kurtaDescription,
    String tryonMode = 'upper',
  }) async {
    final person = TryOnImagePrep.person(Uint8List.fromList(humanJpeg));
    final garment = TryOnImagePrep.garment(Uint8List.fromList(garmentJpeg));

    final uri = Uri.parse(TryOnConfig.apiUrl('/api/tryon'));
    final req = http.MultipartRequest('POST', uri)
      ..fields['garment_des'] = garmentDescription
      ..fields['tryon_mode'] = tryonMode
      ..files.add(
        http.MultipartFile.fromBytes(
          'human_img',
          person,
          filename: 'person.jpg',
        ),
      )
      ..files.add(
        http.MultipartFile.fromBytes(
          'garm_img',
          garment,
          filename: 'garment.jpg',
        ),
      );

    final streamed = await _client
        .send(req)
        .timeout(const Duration(minutes: 10));
    final body = await streamed.stream.bytesToString();
    Map<String, dynamic>? data;
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) data = parsed;
    } catch (_) {}

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final detail = data?['detail'];
      throw TryOnApiException(
        _formatDetail(streamed.statusCode, detail),
        statusCode: streamed.statusCode,
      );
    }

    final url = data?['url'] as String?;
    final b64 = data?['image_base64'] as String?;
    if (url != null && url.isNotEmpty) {
      final imgRes = await _client.get(Uri.parse(url));
      if (imgRes.statusCode >= 200 && imgRes.statusCode < 300) {
        return TryOnResult(url: url, bytes: imgRes.bodyBytes);
      }
      return TryOnResult(url: url);
    }
    if (b64 != null && b64.isNotEmpty) {
      final bytes = base64Decode(b64);
      return TryOnResult(base64: b64, bytes: bytes);
    }
    throw TryOnApiException('Try-on finished but no image was returned.');
  }

  static String _formatDetail(int status, Object? detail) {
    if (detail is String && detail.isNotEmpty) return detail;
    if (detail is List) {
      return detail
          .map((e) => e is Map ? e['msg'] : e)
          .whereType<String>()
          .join('; ');
    }
    if (status == 404) {
      return 'Try-on API not found. Start id-2d-try-on: npm run api (port 8765).';
    }
    return 'Try-on request failed ($status).';
  }
}
