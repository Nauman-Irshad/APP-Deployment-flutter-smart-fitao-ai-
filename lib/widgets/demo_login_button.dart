import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// One-tap fill + optional sign-in for demo accounts.
class DemoLoginButton extends StatelessWidget {
  const DemoLoginButton({
    super.key,
    required this.label,
    required this.email,
    required this.password,
    required this.onFill,
    this.onSignIn,
  });

  final String label;
  final String email;
  final String password;
  final void Function(String email, String password) onFill;
  final Future<void> Function()? onSignIn;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        onFill(email, password);
        if (onSignIn != null) {
          try {
            await onSignIn!();
          } catch (e) {
            if (context.mounted) {
              final msg = e is FirebaseAuthException
                  ? (e.message ?? e.code)
                  : e.toString();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Demo login failed: $msg'),
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        }
      },
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
