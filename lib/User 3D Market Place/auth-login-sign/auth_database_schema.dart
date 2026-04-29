/// Auth database schema for login/forget/sign flow.
/// Not linked to any service – use for reference or to create real tables.
/// Covers: User register, User login, Tailor login, Seller login, Forgot password, OTP.

// =============================================================================
// COLLECTION / TABLE NAMES (used in app with Firestore)
// =============================================================================

class AuthTableNames {
  AuthTableNames._();

  /// User registration (register.dart)
  static const String userRegister = 'login_app_user_register';

  /// User login (login_user.dart)
  static const String userLogin = 'login_app_user_login';

  /// Tailor login (login_tailor.dart)
  static const String tailorLogin = 'login_app_tailor_login';

  /// Seller login (login_seller.dart)
  static const String sellerLogin = 'login_app_seller_login';

  /// Forgot password requests (forgot_password.dart flow)
  static const String forgotPasswordRequests = 'login_app_forgot_password';

  /// OTP verification (otp_verification.dart)
  static const String otpCodes = 'login_app_otp_codes';

  /// Optional: single users table (profile: name, email, phone, address, etc.)
  static const String users = 'login_app_users';
}

// =============================================================================
// COLUMN / FIELD NAMES (for each table)
// =============================================================================

class UserRegisterFields {
  UserRegisterFields._();
  static const String fullName = 'fullName';
  static const String email = 'email';
  static const String uid = 'uid';
  static const String timestamp = 'timestamp';
  static const String action = 'action';
}

class UserLoginFields {
  UserLoginFields._();
  static const String uid = 'uid';
  static const String email = 'email';
  static const String timestamp = 'timestamp';
  static const String action = 'action';
}

class TailorLoginFields {
  TailorLoginFields._();
  static const String uid = 'uid';
  static const String email = 'email';
  static const String shopName = 'shopName';
  static const String ownerName = 'ownerName';
  static const String timestamp = 'timestamp';
  static const String action = 'action';
}

class SellerLoginFields {
  SellerLoginFields._();
  static const String uid = 'uid';
  static const String email = 'email';
  static const String shopName = 'shopName';
  static const String ownerName = 'ownerName';
  static const String timestamp = 'timestamp';
  static const String action = 'action';
}

class ForgotPasswordFields {
  ForgotPasswordFields._();
  static const String email = 'email';
  static const String requestedAt = 'requestedAt';
  static const String expiresAt = 'expiresAt';
}

class OtpCodeFields {
  OtpCodeFields._();
  static const String email = 'email';
  static const String code = 'code';
  static const String expiresAt = 'expiresAt';
  static const String createdAt = 'createdAt';
}

class UsersProfileFields {
  UsersProfileFields._();
  static const String uid = 'uid';
  static const String fullName = 'fullName';
  static const String email = 'email';
  static const String phone = 'phone';
  static const String address = 'address';
  static const String imagePath = 'imagePath';
  static const String userType = 'userType'; // 'user' | 'tailor' | 'seller'
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

// =============================================================================
// SQL CREATE TABLE (for SQL databases – copy/paste as needed)
// =============================================================================

class AuthDatabaseSql {
  AuthDatabaseSql._();

  static const String createUserRegister = '''
CREATE TABLE login_app_user_register (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fullName TEXT NOT NULL,
  email TEXT NOT NULL,
  uid TEXT,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  action TEXT DEFAULT 'register'
);
''';

  static const String createUserLogin = '''
CREATE TABLE login_app_user_login (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uid TEXT,
  email TEXT NOT NULL,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  action TEXT DEFAULT 'login'
);
''';

  static const String createTailorLogin = '''
CREATE TABLE login_app_tailor_login (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uid TEXT,
  email TEXT NOT NULL,
  shopName TEXT NOT NULL,
  ownerName TEXT NOT NULL,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  action TEXT DEFAULT 'login_tailor'
);
''';

  static const String createSellerLogin = '''
CREATE TABLE login_app_seller_login (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uid TEXT,
  email TEXT NOT NULL,
  shopName TEXT NOT NULL,
  ownerName TEXT NOT NULL,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  action TEXT DEFAULT 'login_seller'
);
''';

  static const String createForgotPassword = '''
CREATE TABLE login_app_forgot_password (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL,
  requestedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  expiresAt DATETIME
);
''';

  static const String createOtpCodes = '''
CREATE TABLE login_app_otp_codes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL,
  code TEXT NOT NULL,
  expiresAt DATETIME NOT NULL,
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
);
''';

  static const String createUsersProfile = '''
CREATE TABLE login_app_users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uid TEXT UNIQUE,
  fullName TEXT,
  email TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  imagePath TEXT,
  userType TEXT DEFAULT 'user',
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
);
''';

  /// All CREATE TABLE statements in order (for running migrations).
  static List<String> get allCreateStatements => [
        createUserRegister,
        createUserLogin,
        createTailorLogin,
        createSellerLogin,
        createForgotPassword,
        createOtpCodes,
        createUsersProfile,
      ];
}
