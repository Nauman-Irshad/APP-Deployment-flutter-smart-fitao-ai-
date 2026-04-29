import 'package:shared_preferences/shared_preferences.dart';

import '../constants/auth_types.dart';

class AuthStorage {
  static const String _userTypeKey = 'user_type';

  static Future<void> saveUserRegistration({
    required String email,
    required String password,
    required UserType userType,
  }) async {
    final userTypeStr = userType.toString().split('.').last;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTypeKey, userTypeStr);
  }

  static Future<bool> verifyLogin({
    required String email,
    required String password,
    required UserType userType,
  }) async {
    final userTypeStr = userType.toString().split('.').last;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTypeKey, userTypeStr);
    return true;
  }

  static Future<UserType?> getStoredUserType() async {
    final prefs = await SharedPreferences.getInstance();
    final userTypeString = prefs.getString(_userTypeKey);
    switch (userTypeString) {
      case 'user':
        return UserType.user;
      case 'tailor':
        return UserType.tailor;
      case 'seller':
        return UserType.seller;
      default:
        return null;
    }
  }

  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
