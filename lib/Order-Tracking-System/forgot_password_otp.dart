import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../User 3D Market Place/auth-login-sign/auth_ui.dart';
import 'auth_validators.dart';
import 'auth_reset_memory.dart';
import 'otp_verification.dart';
import 'login_as_user.dart';
import 'login_as_seller.dart';
import 'login_as_tailor.dart';

class ForgotPasswordOtpScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ForgotPasswordOtpScreen({super.key, this.onBack});

  @override
  State<ForgotPasswordOtpScreen> createState() => _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _generateOtp() {
    final r = Random.secure();
    final n = 100000 + r.nextInt(900000);
    return n.toString();
  }

  Future<void> _showPopup(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Notification'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    final err = AuthValidators.validateEmail(email);
    if (err != null) {
      await _showPopup(err);
      return;
    }

    // Check if account exists (in Firestore users collection).
    try {
      final exists = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (exists.docs.isEmpty) {
        await _showPopup('Account not exists. Please register first.');
        return;
      }
    } catch (_) {
      // If user docs are not readable (rules), allow OTP flow to proceed.
    }

    await AuthResetMemory.saveLastResetEmail(email);

    setState(() => _loading = true);
    try {
      final otp = _generateOtp();
      final now = DateTime.now();
      final expires = now.add(const Duration(minutes: 10));

      await FirebaseFirestore.instance.collection('login_app_otp_codes').add({
        'email': email,
        'code': otp,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtClient': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expires),
      });

      if (!mounted) return;
      await AuthResetMemory.saveLastOtp(email: email, otp: otp);
      await _showPopup('OTP for $email is: $otp');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OTPVerificationScreen(
            email: email,
            otpMessage: 'OTP is: $otp',
            onVerified: () {},
            onBack: () => Navigator.pop(context),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await _showPopup('Failed to send OTP. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AuthUi.background(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: widget.onBack ?? () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, size: 18, color: Colors.white.withOpacity(0.95)),
                      label: Text('Back', style: TextStyle(color: Colors.white.withOpacity(0.95))),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AuthCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Reset password', style: AuthUi.titleStyle(context)),
                        const SizedBox(height: 6),
                        Text('Enter your email to receive OTP.', style: AuthUi.subtitleStyle(context)),
                        const SizedBox(height: 26),
                        AuthTextField(
                          label: 'Email',
                          hint: 'Enter your email',
                          controller: _emailController,
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 18),
                        AuthPrimaryButton(
                          text: 'Send OTP',
                          loading: _loading,
                          onPressed: _sendOtp,
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            AuthResetMemory.loadLastRole().then((role) {
                              if (!mounted) return;
                              if (role == 'seller') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RegisterAsSellerScreen()),
                                );
                                return;
                              }
                              if (role == 'tailor') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RegisterAsTailorScreen()),
                                );
                                return;
                              }
                              if (role == 'user') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RegisterAsUserScreen()),
                                );
                                return;
                              }
                              showModalBottomSheet<void>(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                                ),
                                builder: (_) {
                                  return SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          const Text(
                                            'Register as',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 12),
                                          ListTile(
                                            leading: const Icon(Icons.person_outline),
                                            title: const Text('User'),
                                            onTap: () async {
                                              await AuthResetMemory.saveLastRole('user');
                                              if (!context.mounted) return;
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (_) => const RegisterAsUserScreen()),
                                              );
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.store_outlined),
                                            title: const Text('Seller'),
                                            onTap: () async {
                                              await AuthResetMemory.saveLastRole('seller');
                                              if (!context.mounted) return;
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (_) => const RegisterAsSellerScreen()),
                                              );
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.content_cut),
                                            title: const Text('Tailor'),
                                            onTap: () async {
                                              await AuthResetMemory.saveLastRole('tailor');
                                              if (!context.mounted) return;
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (_) => const RegisterAsTailorScreen()),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            });
                          },
                          child: Text(
                            'Create new account (Register)',
                            style: AuthUi.linkStyle(color: AuthUi.emerald900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

