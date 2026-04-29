class AuthValidators {
  AuthValidators._();

  // Gmail-only rule (requested):
  // - only a-z A-Z 0-9 before @
  // - must end with @gmail.com
  static final RegExp _email = RegExp(r'^[A-Za-z0-9]+@gmail\.com$');
  static final RegExp _name = RegExp(r"^[A-Za-z][A-Za-z\s]{1,49}$");
  static final RegExp _shopName = RegExp(r"^[A-Za-z][A-Za-z0-9\s]{1,49}$");
  static final RegExp _address = RegExp(r"^[A-Za-z0-9][A-Za-z0-9\s#]{2,79}$");

  static String? validateEmail(String v) {
    final s = v.trim();
    if (s.isEmpty) return 'Email is required';
    if (!_email.hasMatch(s)) return 'Email must be like abc123@gmail.com';
    return null;
  }

  /// Human name: letters + spaces only, 2..50 chars, no numbers.
  static String? validateName(String v, {String fieldName = 'Name'}) {
    final s = v.trim();
    if (s.isEmpty) return '$fieldName is required';
    if (!_name.hasMatch(s)) return '$fieldName must be letters only (no numbers)';
    return null;
  }

  /// Shop name: must not look like an email; allow letters/numbers/spaces.
  static String? validateShopName(String v) {
    final s = v.trim();
    if (s.isEmpty) return 'Shop name is required';
    if (s.contains('@')) return 'Shop name cannot contain @';
    if (!_shopName.hasMatch(s)) return 'Shop name must start with a letter';
    return null;
  }

  /// Address: must not be an email; allow alphanumerics/spaces/#.
  static String? validateAddress(String v) {
    final s = v.trim();
    if (s.isEmpty) return 'Address is required';
    if (s.contains('@')) return 'Address cannot contain @';
    if (!_address.hasMatch(s)) return 'Enter a valid address';
    return null;
  }

  /// Password rules requested:
  /// - min 8 chars
  /// - at least 1 uppercase
  /// - must include: letters + numbers + special character
  static String? validatePassword(String v) {
    final s = v;
    if (s.isEmpty) return 'Password is required';
    if (s.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(s)) return 'Password must contain 1 capital letter';
    if (!RegExp(r'[a-z]').hasMatch(s)) return 'Password must contain 1 small letter';
    if (!RegExp(r'\d').hasMatch(s)) return 'Password must contain 1 number';
    if (RegExp(r'\s').hasMatch(s)) return 'Password cannot contain spaces';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(s)) {
      return 'Password must contain 1 special character';
    }
    return null;
  }

  static String? validateConfirmPassword(String password, String confirm) {
    final a = password;
    final b = confirm;
    if (b.isEmpty) return 'Confirm password is required';
    if (a != b) return 'Passwords do not match';
    return null;
  }
}

