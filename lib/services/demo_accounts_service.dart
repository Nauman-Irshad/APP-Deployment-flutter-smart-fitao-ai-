import 'package:firebase_auth/firebase_auth.dart';

import '../Order-Tracking-System/services/app_backend.dart';
import '../config/demo_accounts.dart';

/// Demo sign-in: logs in or creates Firebase Auth + Firestore profile with the right role.
class DemoAccountsService {
  DemoAccountsService._();

  static final DemoAccountsService instance = DemoAccountsService._();

  final _backend = AppBackend.instance;

  AppUserProfile? _tailor;
  AppUserProfile? _seller;

  AppUserProfile? get cachedTailor => _tailor;
  AppUserProfile? get cachedSeller => _seller;

  Future<AppUserProfile?> loadTailor() async {
    if (_tailor != null) return _tailor;
    _tailor = await _backend.findUserByEmail(DemoAccounts.tailorEmail);
    return _tailor;
  }

  Future<AppUserProfile?> loadSeller() async {
    if (_seller != null) return _seller;
    _seller = await _backend.findUserByEmail(DemoAccounts.sellerEmail);
    return _seller;
  }

  Future<void> preload() async {
    await Future.wait([loadTailor(), loadSeller()]);
  }

  static Future<void> signInDemoCustomer() => _signInOrEnsureDemo(
        email: DemoAccounts.customerEmail,
        password: DemoAccounts.customerPassword,
        role: 'user',
        name: DemoAccounts.customerName,
      );

  static Future<void> signInDemoTailor() => _signInOrEnsureDemo(
        email: DemoAccounts.tailorEmail,
        password: DemoAccounts.tailorPassword,
        role: 'tailor',
        name: DemoAccounts.tailorName,
        shopName: DemoAccounts.tailorShop,
        available: true,
        stitchingRate: 500,
        tailorProfitPerUnit: 500,
      );

  static Future<void> signInDemoSeller() => _signInOrEnsureDemo(
        email: DemoAccounts.sellerEmail,
        password: DemoAccounts.sellerPassword,
        role: 'seller',
        name: DemoAccounts.sellerName,
        shopName: DemoAccounts.sellerShop,
      );

  static Future<void> _signInOrEnsureDemo({
    required String email,
    required String password,
    required String role,
    required String name,
    String shopName = '',
    String address = '',
    bool available = false,
    double stitchingRate = 0,
    double tailorProfitPerUnit = 0,
  }) async {
    final auth = FirebaseAuth.instance;
    final normalizedEmail = email.trim();

    UserCredential cred;
    try {
      cred = await auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
    } on FirebaseAuthException catch (signInErr) {
      final canRegister = signInErr.code == 'user-not-found' ||
          signInErr.code == 'invalid-credential' ||
          signInErr.code == 'invalid-login-credentials' ||
          signInErr.code == 'wrong-password';
      if (!canRegister) rethrow;

      try {
        cred = await auth.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
      } on FirebaseAuthException catch (createErr) {
        if (createErr.code == 'email-already-in-use') {
          throw FirebaseAuthException(
            code: 'wrong-password',
            message:
                'This demo email is already registered with a different password. '
                'Use Register or reset the password in Firebase.',
          );
        }
        rethrow;
      }
    }

    final uid = cred.user!.uid;
    await _ensureFirestoreProfile(
      uid: uid,
      email: normalizedEmail,
      role: role,
      name: name,
      shopName: shopName,
      address: address,
      available: available,
      stitchingRate: stitchingRate,
      tailorProfitPerUnit: tailorProfitPerUnit,
    );
  }

  static Future<void> _ensureFirestoreProfile({
    required String uid,
    required String email,
    required String role,
    required String name,
    String shopName = '',
    String address = '',
    bool available = false,
    double stitchingRate = 0,
    double tailorProfitPerUnit = 0,
  }) async {
    final backend = AppBackend.instance;
    try {
      final profile = await backend.getUserProfile(uid);
      if (profile.role != role) {
        await backend.createUserProfile(
          uid: uid,
          email: email,
          role: role,
          name: name.isNotEmpty ? name : profile.name,
          shopName: shopName.isNotEmpty ? shopName : profile.shopName,
          address: address.isNotEmpty ? address : profile.address,
          available: available || profile.available,
          stitchingRate: stitchingRate > 0 ? stitchingRate : profile.stitchingRate,
          tailorProfitPerUnit: tailorProfitPerUnit > 0
              ? tailorProfitPerUnit
              : profile.tailorProfitPerUnit,
        );
      }
    } catch (_) {
      await backend.createUserProfile(
        uid: uid,
        email: email,
        role: role,
        name: name,
        shopName: shopName,
        address: address.isNotEmpty ? address : 'Demo address',
        available: available,
        stitchingRate: stitchingRate,
        tailorProfitPerUnit: tailorProfitPerUnit,
      );
    }
  }
}
