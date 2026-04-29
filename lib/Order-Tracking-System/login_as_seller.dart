import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'services/app_backend.dart';
import 'tracking.dart' as tracking;
import '../../seller_dashboard/bottom_navi.dart';
import '../User 3D Market Place/auth-login-sign/auth_ui.dart';
import 'forgot_password_otp.dart';
import 'auth_validators.dart';
import 'auth_reset_memory.dart';

class LoginAsSellerScreen extends StatefulWidget {
  final VoidCallback? onBackToRolePicker;

  const LoginAsSellerScreen({super.key, this.onBackToRolePicker});

  @override
  State<LoginAsSellerScreen> createState() => _LoginAsSellerScreenState();
}

class _LoginAsSellerScreenState extends State<LoginAsSellerScreen> {
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
          MaterialPageRoute(builder: (_) => const BottomNavScreen()),
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

      if (profile.role != 'seller') {
        await FirebaseAuth.instance.signOut();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This account is not a seller account.')),
        );
        return;
      }

      if (!context.mounted) return;
      await AuthResetMemory.saveLastRole('seller');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavScreen()),
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
                        Text('Login as Seller', style: AuthUi.subtitleStyle(context)),
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
                                  MaterialPageRoute(builder: (_) => const RegisterAsSellerScreen()),
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

class RegisterAsSellerScreen extends StatefulWidget {
  const RegisterAsSellerScreen({super.key});

  @override
  State<RegisterAsSellerScreen> createState() => _RegisterAsSellerScreenState();
}

class _RegisterAsSellerScreenState extends State<RegisterAsSellerScreen> {
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    shopNameController.dispose();
    ownerNameController.dispose();
    addressController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final shopName = shopNameController.text.trim();
    final ownerName = ownerNameController.text.trim();
    final address = addressController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    final shopErr = AuthValidators.validateShopName(shopName);
    final ownerErr = AuthValidators.validateName(ownerName, fieldName: 'Owner name');
    final addrErr = AuthValidators.validateAddress(address);
    final emailErr = AuthValidators.validateEmail(email);
    final passErr = AuthValidators.validatePassword(password);
    final confirmErr = AuthValidators.validateConfirmPassword(password, confirmPassword);
    final firstErr = shopErr ?? ownerErr ?? addrErr ?? emailErr ?? passErr ?? confirmErr;
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

      await AuthResetMemory.saveLastRole('seller');
      await AppBackend.instance.createUserProfile(
        uid: cred.user!.uid,
        email: email,
        role: 'seller',
        name: ownerName,
        shopName: shopName,
        address: address,
        available: false,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful! Please login.")),
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
                        Text('Register as Seller', style: AuthUi.subtitleStyle(context)),
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
                          label: 'Shop address',
                          hint: 'Enter address',
                          controller: addressController,
                          icon: Icons.location_on_outlined,
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
                          hint: 'Create a password',
                          controller: passwordController,
                          icon: Icons.lock_outline,
                          obscureText: obscurePassword,
                          onToggleObscure: () => setState(() => obscurePassword = !obscurePassword),
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          label: 'Confirm password',
                          hint: 'Confirm password',
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

