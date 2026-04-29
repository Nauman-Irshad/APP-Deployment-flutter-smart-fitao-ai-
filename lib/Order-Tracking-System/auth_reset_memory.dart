import 'package:shared_preferences/shared_preferences.dart';

class AuthResetMemory {
  AuthResetMemory._();

  static const _kLastResetEmail = 'last_reset_email';
  static const _kLastRole = 'last_user_role';
  static const _kLastOtpPrefix = 'last_reset_otp_';
  static const _kLastPasswordPrefix = 'last_reset_password_';

  static Future<void> saveLastResetEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastResetEmail, email.trim());
  }

  static Future<String?> loadLastResetEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kLastResetEmail);
    if (v == null) return null;
    final s = v.trim();
    return s.isEmpty ? null : s;
  }

  static Future<void> saveLastOtp({required String email, required String otp}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kLastOtpPrefix${email.trim().toLowerCase()}', otp.trim());
  }

  static Future<String?> loadLastOtp(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString('$_kLastOtpPrefix${email.trim().toLowerCase()}');
    if (v == null) return null;
    final s = v.trim();
    return s.isEmpty ? null : s;
  }

  /// WARNING: storing passwords locally is insecure. Use only if you accept the risk.
  static Future<void> saveLastPassword({required String email, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    // Always store as String to avoid "unsupported int" / type issues.
    await prefs.setString('$_kLastPasswordPrefix${email.trim().toLowerCase()}', password);
  }

  static Future<String?> loadLastPassword(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString('$_kLastPasswordPrefix${email.trim().toLowerCase()}');
    if (v == null) return null;
    return v;
  }

  static Future<void> saveLastRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastRole, role.trim());
  }

  static Future<String?> loadLastRole() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kLastRole);
    if (v == null) return null;
    final s = v.trim();
    return s.isEmpty ? null : s;
  }
}

