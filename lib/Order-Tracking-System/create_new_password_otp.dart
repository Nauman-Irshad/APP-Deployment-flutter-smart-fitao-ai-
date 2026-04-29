import 'package:flutter/material.dart';

import '../User 3D Market Place/auth-login-sign/auth_ui.dart';
import 'auth_validators.dart';
import 'auth_reset_memory.dart';

String _formatSaveError(Object e) {
  final s = e.toString();
  // Web HttpRequest often surfaces as an untyped ProgressEvent.
  if (s.contains('ProgressEvent') || s == '[object ProgressEvent]') {
    return 'Browser blocked a request or storage failed (common on Edge). '
        'Try: hot restart (R), allow site data for localhost, or use Chrome.';
  }
  return s;
}

class CreateNewPasswordOtpScreen extends StatefulWidget {
  final String email;

  const CreateNewPasswordOtpScreen({super.key, required this.email});

  @override
  State<CreateNewPasswordOtpScreen> createState() => _CreateNewPasswordOtpScreenState();
}

class _CreateNewPasswordOtpScreenState extends State<CreateNewPasswordOtpScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _obscure2 = true;
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _showPopup(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Password reset'),
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

  Future<void> _submit() async {
    final p = _passwordController.text;
    final c = _confirmController.text;
    final passErr = AuthValidators.validatePassword(p);
    final confirmErr = AuthValidators.validateConfirmPassword(p, c);
    final firstErr = passErr ?? confirmErr;
    if (firstErr != null) {
      await _showPopup(firstErr);
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthResetMemory.saveLastResetEmail(widget.email);
      await AuthResetMemory.saveLastPassword(email: widget.email, password: p);
      if (!mounted) return;
      // Avoid showDialog before navigation on web — Edge sometimes surfaces
      // ProgressEvent / odd failures when dialog + popUntil run back-to-back.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved. Log in with your new password.')),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context).popUntil((r) => r.isFirst);
      });
    } catch (e) {
      debugPrint('Unknown error in new password: $e');
      await _showPopup('Error: ${_formatSaveError(e)}');
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
                        Text('New password', style: AuthUi.titleStyle(context)),
                        const SizedBox(height: 6),
                        Text('Set a new password for ${widget.email}', style: AuthUi.subtitleStyle(context)),
                        const SizedBox(height: 26),
                        AuthTextField(
                          label: 'Password',
                          hint: 'At least 8 chars, 1 capital letter',
                          controller: _passwordController,
                          icon: Icons.lock_outline,
                          obscureText: _obscure,
                          onToggleObscure: () => setState(() => _obscure = !_obscure),
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          label: 'Confirm password',
                          hint: 'Re-enter password',
                          controller: _confirmController,
                          icon: Icons.lock_outline,
                          obscureText: _obscure2,
                          onToggleObscure: () => setState(() => _obscure2 = !_obscure2),
                        ),
                        const SizedBox(height: 18),
                        AuthPrimaryButton(
                          text: 'Save',
                          loading: _loading,
                          onPressed: _submit,
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

