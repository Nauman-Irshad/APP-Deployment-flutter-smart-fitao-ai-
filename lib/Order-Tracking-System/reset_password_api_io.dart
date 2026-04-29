import 'package:cloud_functions/cloud_functions.dart';

Future<void> resetPasswordWithOtp({
  required String email,
  required String otp,
  required String newPassword,
}) async {
  final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  await functions.httpsCallable('resetPasswordWithOtp').call({
    'email': email,
    'otp': otp,
    'newPassword': newPassword,
  });
}

