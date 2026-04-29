-- Auth database tables for login/forget/sign flow
-- Source: lib/User 3D Market Place/loginforgetsign (register, login_user, login_tailor, login_seller, forgot_password, otp_verification)
-- Not linked to app – run this in your SQL DB to create tables.

-- -----------------------------------------------------------------------------
-- User registration (register.dart: fullName, email, uid)
-- -----------------------------------------------------------------------------
CREATE TABLE login_app_user_register (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fullName TEXT NOT NULL,
  email TEXT NOT NULL,
  uid TEXT,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  action TEXT DEFAULT 'register'
);

-- -----------------------------------------------------------------------------
-- User login (login_user.dart: email, uid)
-- -----------------------------------------------------------------------------
CREATE TABLE login_app_user_login (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uid TEXT,
  email TEXT NOT NULL,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  action TEXT DEFAULT 'login'
);

-- -----------------------------------------------------------------------------
-- Tailor login (login_tailor.dart: email, shopName, ownerName, uid)
-- -----------------------------------------------------------------------------
CREATE TABLE login_app_tailor_login (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uid TEXT,
  email TEXT NOT NULL,
  shopName TEXT NOT NULL,
  ownerName TEXT NOT NULL,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  action TEXT DEFAULT 'login_tailor'
);

-- -----------------------------------------------------------------------------
-- Seller login (login_seller.dart: email, shopName, ownerName, uid)
-- -----------------------------------------------------------------------------
CREATE TABLE login_app_seller_login (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uid TEXT,
  email TEXT NOT NULL,
  shopName TEXT NOT NULL,
  ownerName TEXT NOT NULL,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
  action TEXT DEFAULT 'login_seller'
);

-- -----------------------------------------------------------------------------
-- Forgot password (forgot_password.dart: email)
-- -----------------------------------------------------------------------------
CREATE TABLE login_app_forgot_password (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL,
  requestedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  expiresAt DATETIME
);

-- -----------------------------------------------------------------------------
-- OTP verification (otp_verification.dart: email, code)
-- -----------------------------------------------------------------------------
CREATE TABLE login_app_otp_codes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL,
  code TEXT NOT NULL,
  expiresAt DATETIME NOT NULL,
  createdAt DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- -----------------------------------------------------------------------------
-- Users profile (profile.dart: fullName, email, phone, address, imagePath, userType)
-- -----------------------------------------------------------------------------
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
