import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_ui.dart';

class ForgetPasswordScreen extends StatefulWidget {
  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
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
                        Text('Reset password', style: AuthUi.titleStyle(context)),
                        const SizedBox(height: 6),
                        Text('We will send a reset link to your email.', style: AuthUi.subtitleStyle(context)),
                        const SizedBox(height: 26),
                        AuthTextField(
                          label: 'Email',
                          hint: 'Enter your email',
                          controller: emailController,
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 18),
                        AuthPrimaryButton(
                          text: 'Send reset link',
                          loading: isLoading,
                          onPressed: () async {
                            final email = emailController.text.trim();
                            if (email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please enter your email")),
                              );
                              return;
                            }
                            setState(() => isLoading = true);
                            try {
                              await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                              await FirebaseFirestore.instance.collection('login_app_forgot_password').add({
                                'email': email,
                                'requestedAt': FieldValue.serverTimestamp(),
                                'expiresAt': null,
                              });
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Reset link sent. Check your email.")),
                              );
                              Navigator.pop(context);
                            } on FirebaseAuthException catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.message ?? "Failed to send reset link")),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("An error occurred. Please try again.")),
                              );
                            } finally {
                              if (mounted) setState(() => isLoading = false);
                            }
                          },
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