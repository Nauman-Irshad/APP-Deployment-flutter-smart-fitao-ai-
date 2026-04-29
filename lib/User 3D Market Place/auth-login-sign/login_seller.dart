import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'forget_password.dart';
import '../../seller_dashboard/bottom_navi.dart';
import 'register_form.dart';
import '../../../core/constants/auth_types.dart';
import 'auth_ui.dart';

class LoginSellerScreen extends StatefulWidget {
  @override
  _LoginSellerScreenState createState() => _LoginSellerScreenState();
}

class _LoginSellerScreenState extends State<LoginSellerScreen> {
  TextEditingController shopNameController = TextEditingController();
  TextEditingController ownerNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    shopNameController.dispose();
    ownerNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final shopName = shopNameController.text.trim();
    final ownerName = ownerNameController.text.trim();

    if (email.isEmpty || password.isEmpty || shopName.isEmpty || ownerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store seller login data in Firestore
      await FirebaseFirestore.instance.collection('login_app_seller_login').add({
        'uid': userCredential.user?.uid,
        'email': email,
        'shopName': shopName,
        'ownerName': ownerName,
        'timestamp': FieldValue.serverTimestamp(),
        'action': 'login_seller',
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BottomNavScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Login failed")),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An error occurred. Please try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
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
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, size: 18, color: Colors.white.withOpacity(0.95)),
                      label: Text('Back', style: TextStyle(color: Colors.white.withOpacity(0.95))),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AuthCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Welcome back', style: AuthUi.titleStyle(context)),
                        const SizedBox(height: 6),
                        Text('Login as Seller', style: AuthUi.subtitleStyle(context)),
                        const SizedBox(height: 26),
                        AuthTextField(
                          label: 'Shop name',
                          hint: 'Enter shop name',
                          controller: shopNameController,
                          icon: Icons.store_outlined,
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          label: 'Owner name',
                          hint: 'Enter owner name',
                          controller: ownerNameController,
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          label: 'Email',
                          hint: 'Enter your email',
                          controller: emailController,
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          label: 'Password',
                          hint: 'Enter your password',
                          controller: passwordController,
                          icon: Icons.lock_outline,
                          obscureText: obscurePassword,
                          onToggleObscure: () => setState(() => obscurePassword = !obscurePassword),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ForgetPasswordScreen()),
                              );
                            },
                            child: Text('Forget Password?', style: AuthUi.linkStyle(color: AuthUi.emerald900)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        AuthPrimaryButton(
                          text: 'Login',
                          loading: isLoading,
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ", style: TextStyle(color: Colors.grey.shade600)),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RegisterFormScreen(
                                      userType: UserType.seller,
                                      onSuccess: () => Navigator.pop(context),
                                      onBack: () => Navigator.pop(context),
                                    ),
                                  ),
                                );
                              },
                              child: Text('Register now', style: AuthUi.linkStyle(color: AuthUi.emerald900)),
                            ),
                          ],
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