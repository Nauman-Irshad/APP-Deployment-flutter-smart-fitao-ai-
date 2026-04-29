import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'services/app_backend.dart';
import 'tracking.dart' as tracking;
import '../../User 3D Market Place/3d_marketplace.dart';
import '../User 3D Market Place/auth-login-sign/auth_ui.dart';
import 'forgot_password_otp.dart';
import 'auth_validators.dart';
import 'auth_reset_memory.dart';

class LoginAsUserScreen extends StatefulWidget {
  /// When non-null (e.g. inside main app [AuthFlow]), back returns to the green role picker.
  final VoidCallback? onBackToRolePicker;

  const LoginAsUserScreen({super.key, this.onBackToRolePicker});

  @override
  State<LoginAsUserScreen> createState() => _LoginAsUserScreenState();
}

class _LoginAsUserScreenState extends State<LoginAsUserScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // SIMPLE MODE: allow local password saved from reset flow.
    final savedEmail = await AuthResetMemory.loadLastResetEmail();
    if (savedEmail != null && savedEmail.trim().toLowerCase() == email.toLowerCase()) {
      final savedPw = await AuthResetMemory.loadLastPassword(savedEmail);
      if (savedPw != null && savedPw == password) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MarketPlace3D()),
        );
        return;
      }
    }

    final emailErr = AuthValidators.validateEmail(email);
    final passErr = AuthValidators.validatePassword(password);
    if (emailErr != null || passErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emailErr ?? passErr!)),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = AppBackend.instance.currentUid;
      final profile = await AppBackend.instance.getUserProfile(uid);

      if (profile.role != 'user') {
        await FirebaseAuth.instance.signOut();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This account is not a user account.')),
        );
        return;
      }

      if (!context.mounted) return;
      await AuthResetMemory.saveLastRole('user');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MarketPlace3D()),
      );
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.message ?? e.code}')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _onBackFromLogin() {
    if (widget.onBackToRolePicker != null) {
      widget.onBackToRolePicker!();
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const tracking.RoleSelectionScreen()),
    );
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
                      onPressed: _onBackFromLogin,
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
                        Text('Login as User', style: AuthUi.subtitleStyle(context)),
                        const SizedBox(height: 26),
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
                                MaterialPageRoute(builder: (_) => const ForgotPasswordOtpScreen()),
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
                                  MaterialPageRoute(builder: (_) => const RegisterAsUserScreen()),
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

  Widget _buildTextField({
    String? label,
    required String hintText,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    final field = Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.emailAddress,
        obscureText: isPassword ? obscurePassword : false,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() => obscurePassword = !obscurePassword);
                  },
                )
              : null,
        ),
      ),
    );
    if (label == null) return field;
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 6),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          field,
        ],
      ),
    );
  }
}

class RegisterAsUserScreen extends StatefulWidget {
  const RegisterAsUserScreen({super.key});

  @override
  State<RegisterAsUserScreen> createState() => _RegisterAsUserScreenState();
}

class _RegisterAsUserScreenState extends State<RegisterAsUserScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final address = addressController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    final nameErr = AuthValidators.validateName(name, fieldName: 'Full name');
    final emailErr = AuthValidators.validateEmail(email);
    final addrErr = AuthValidators.validateAddress(address);
    final passErr = AuthValidators.validatePassword(password);
    final confirmErr = AuthValidators.validateConfirmPassword(password, confirmPassword);
    final firstErr = nameErr ?? emailErr ?? addrErr ?? passErr ?? confirmErr;
    if (firstErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(firstErr)));
      return;
    }

    setState(() => isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await AuthResetMemory.saveLastRole('user');
      await AppBackend.instance.createUserProfile(
        uid: cred.user!.uid,
        email: email,
        role: 'user',
        name: name,
        shopName: '',
        address: address,
        available: false,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please login.')),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Register failed: ${e.message ?? e.code}')),
      );
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
                        Text('Create account', style: AuthUi.titleStyle(context)),
                        const SizedBox(height: 6),
                        Text('Register as User', style: AuthUi.subtitleStyle(context)),
                        const SizedBox(height: 26),
                        AuthTextField(
                          label: 'Full name',
                          hint: 'Enter your name',
                          controller: nameController,
                          icon: Icons.person_outline,
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
                          label: 'Delivery address',
                          hint: 'Enter your address',
                          controller: addressController,
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          label: 'Password',
                          hint: 'Create a password',
                          controller: passwordController,
                          icon: Icons.lock_outline,
                          obscureText: obscurePassword,
                          onToggleObscure: () => setState(() => obscurePassword = !obscurePassword),
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          label: 'Confirm password',
                          hint: 'Confirm your password',
                          controller: confirmPasswordController,
                          icon: Icons.lock_outline,
                          obscureText: obscureConfirmPassword,
                          onToggleObscure: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                        ),
                        const SizedBox(height: 18),
                        AuthPrimaryButton(
                          text: 'Register',
                          loading: isLoading,
                          onPressed: _handleRegister,
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

  Widget _buildTextField({
    String? label,
    required String hintText,
    required TextEditingController controller,
    bool isPassword = false,
    bool obscureAlt = true,
    VoidCallback? onToggle,
  }) {
    final field = Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.text,
        obscureText: isPassword ? obscureAlt : false,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureAlt ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: onToggle,
                )
              : null,
        ),
      ),
    );
    if (label == null) return field;
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 6),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          field,
        ],
      ),
    );
  }
}

