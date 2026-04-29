import 'package:flutter/material.dart';
import '../../../core/constants/auth_types.dart';
export '../../../core/constants/auth_types.dart';
import '../../../Order-Tracking-System/login_as_seller.dart';
import '../../../Order-Tracking-System/login_as_tailor.dart';
import '../../../Order-Tracking-System/login_as_user.dart';
import 'select_login.dart';
import 'register_form.dart';
import 'forgot_password.dart';
import '../../../Order-Tracking-System/otp_verification.dart';
import '../create_new_password.dart';
import 'register.dart';

class AuthFlow extends StatefulWidget {
  final Function(UserType)? onLogin;

  AuthFlow({this.onLogin});

  @override
  _AuthFlowState createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  AuthScreen _currentScreen = AuthScreen.selection;
  UserType? _selectedUserType;
  String _email = '';

  void _handleUserTypeSelect(UserType type) {
    setState(() {
      _selectedUserType = type;
      _currentScreen = AuthScreen.login;
    });
  }

  void _handleOTPSent() {
    setState(() {
      _currentScreen = AuthScreen.otp;
    });
  }

  void _handleOTPVerified() {
    setState(() {
      _currentScreen = AuthScreen.newPassword;
    });
  }

  void _handlePasswordReset() {
    setState(() {
      _currentScreen = AuthScreen.login;
    });
  }

  Widget _buildGreenBackground(Widget child) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF065f46),
            Color(0xFF047857),
            Color(0xFF059669),
            Colors.white,
          ],
          stops: [0.0, 0.3, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [

          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF065f46).withOpacity(0.3),
                    Color(0xFF047857).withOpacity(0.2),
                    Color(0xFF059669).withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF065f46).withOpacity(0.25),
                    Color(0xFF047857).withOpacity(0.15),
                    Color(0xFF059669).withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF047857).withOpacity(0.2),
                    Color(0xFF059669).withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF065f46).withOpacity(0.2),
                    Color(0xFF047857).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  void _backFromOtsLoginToSelection() {
    setState(() {
      _currentScreen = AuthScreen.selection;
      _selectedUserType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentScreen == AuthScreen.login && _selectedUserType != null) {
      return _buildOtsFirebaseLogin();
    }
    return _buildGreenBackground(_buildCurrentScreen());
  }

  /// Order Tracking System Firebase email/password login (same as `/auth` role flow).
  Widget _buildOtsFirebaseLogin() {
    switch (_selectedUserType!) {
      case UserType.user:
        return LoginAsUserScreen(onBackToRolePicker: _backFromOtsLoginToSelection);
      case UserType.seller:
        return LoginAsSellerScreen(onBackToRolePicker: _backFromOtsLoginToSelection);
      case UserType.tailor:
        return LoginAsTailorScreen(onBackToRolePicker: _backFromOtsLoginToSelection);
    }
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case AuthScreen.selection:
        return SelectLoginScreen(
          onSelect: _handleUserTypeSelect,
        );
      case AuthScreen.login:
        return const SizedBox.shrink();
      case AuthScreen.register:
        if (_selectedUserType == UserType.user) {
          return RegisterScreen();
        }
        return RegisterFormScreen(
          userType: _selectedUserType!,
          onSuccess: () => setState(() => _currentScreen = AuthScreen.login),
          onBack: () => setState(() => _currentScreen = AuthScreen.login),
        );
      case AuthScreen.forgot:
        return ForgotPasswordScreen(
          email: _email,
          onContinue: _handleOTPSent,
          onBack: () => setState(() => _currentScreen = AuthScreen.login),
        );
      case AuthScreen.otp:
        return OTPVerificationScreen(
          email: _email,
          onVerified: _handleOTPVerified,
          onBack: () => setState(() => _currentScreen = AuthScreen.forgot),
        );
      case AuthScreen.newPassword:
        return CreateNewPasswordScreen(
          onSuccess: _handlePasswordReset,
        );
    }
  }
}
