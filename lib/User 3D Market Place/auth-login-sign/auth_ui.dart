import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthUi {
  AuthUi._();

  static const Color emerald900 = Color(0xFF065F46);
  static const Color emerald800 = Color(0xFF047857);
  static const Color emerald600 = Color(0xFF059669);
  static const Color surface = Colors.white;

  static LinearGradient get backgroundGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          emerald900,
          emerald800,
          emerald600,
          Colors.white,
        ],
        stops: [0.0, 0.32, 0.65, 1.0],
      );

  static TextStyle titleStyle(BuildContext context) => GoogleFonts.poppins(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: Colors.grey.shade900,
      );

  static TextStyle subtitleStyle(BuildContext context) => GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade600,
      );

  static TextStyle fieldLabelStyle(BuildContext context) => GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      );

  static TextStyle linkStyle({Color? color}) => GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline,
        color: color ?? Colors.white.withOpacity(0.92),
      );

  static Widget background({required Widget child}) {
    return Container(
      decoration: BoxDecoration(gradient: backgroundGradient),
      child: Stack(
        children: [
          const _RadialBlob(
            alignment: Alignment(-1.15, 0.25),
            size: 320,
            opacity: 0.16,
          ),
          const _RadialBlob(
            alignment: Alignment(1.2, -1.15),
            size: 420,
            opacity: 0.22,
          ),
          const _RadialBlob(
            alignment: Alignment(1.1, 0.85),
            size: 360,
            opacity: 0.14,
          ),
          child,
        ],
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AuthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(28),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 430),
      padding: padding,
      decoration: BoxDecoration(
        color: AuthUi.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      child: child,
    );
  }
}

class AuthTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final TextInputType keyboardType;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.onToggleObscure,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AuthUi.fieldLabelStyle(context)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            color: Colors.white,
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
              suffixIcon: onToggleObscure == null
                  ? null
                  : IconButton(
                      onPressed: onToggleObscure,
                      icon: Icon(
                        obscureText ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback? onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.text,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthUi.emerald900,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 6,
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                text,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

class AuthOutlinedButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool loading;
  final VoidCallback? onPressed;

  const AuthOutlinedButton({
    super.key,
    required this.text,
    required this.icon,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey.shade900,
          side: BorderSide(color: Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: Colors.white,
        ),
        icon: Icon(icon, size: 18, color: AuthUi.emerald900),
        label: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                text,
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

class _RadialBlob extends StatelessWidget {
  final Alignment alignment;
  final double size;
  final double opacity;

  const _RadialBlob({
    required this.alignment,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AuthUi.emerald900.withOpacity(opacity),
              AuthUi.emerald800.withOpacity(opacity * 0.7),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

