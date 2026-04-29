import 'dart:convert';
import 'dart:html' as html;

import 'package:firebase_core/firebase_core.dart';

Future<void> resetPasswordWithOtp({
  required String email,
  required String otp,
  required String newPassword,
}) async {
  final projectId = Firebase.app().options.projectId;
  if (projectId == null || projectId.isEmpty) {
    throw StateError('Missing Firebase projectId');
  }

  final url = 'https://us-central1-$projectId.cloudfunctions.net/resetPasswordWithOtpHttp';
  html.HttpRequest req;
  try {
    req = await html.HttpRequest.request(
      url,
      method: 'POST',
      sendData: jsonEncode({'email': email, 'otp': otp, 'newPassword': newPassword}),
      requestHeaders: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    // On web, failed requests often throw a ProgressEvent. Surface a helpful message.
    if (e is html.ProgressEvent) {
      final target = e.target;
      if (target is html.HttpRequest) {
        throw StateError('Network/CORS error (status: ${target.status}). '
            'Make sure Functions are deployed and reachable. '
            'Response: ${target.responseText}');
      }
      throw StateError('Network/CORS error while calling password reset function. '
          'Make sure Functions are deployed and reachable.');
    }
    rethrow;
  }

  if (req.status != 200) {
    throw StateError('HTTP ${req.status}: ${req.responseText}');
  }

  final text = (req.responseText ?? '').trim();
  if (text.isEmpty) return;
  final decoded = jsonDecode(text);
  if (decoded is Map && decoded['ok'] == true) return;
  throw StateError('Unexpected response: $text');
}

