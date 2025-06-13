import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../utils/app_dialog.dart';
import '../../utils/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? uid;
  final String? token;

  const ResetPasswordScreen({super.key, this.uid, this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final Color themeColor = AppTheme.themeColor;

  late String uid;
  late String token;

  @override
  void initState() {
    super.initState();
    final uri = Uri.base;
    uid = widget.uid ?? uri.queryParameters['uid'] ?? '';
    token = widget.token ?? uri.queryParameters['token'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: themeColor),
        title: Text(
          'Reset Password',
          style: GoogleFonts.montserrat(
            color: themeColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildGlassHeader(),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _passwordField('New Password', _newPasswordController, Icons.lock_reset),
                  _passwordField('Confirm New Password', _confirmPasswordController, Icons.check_circle_outline),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Reset Password',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(Icons.vpn_key, size: 50, color: themeColor.withOpacity(0.8)),
              const SizedBox(height: 12),
              Text(
                'Set your new password',
                style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: themeColor),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your new password to complete the reset process.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: themeColor),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: themeColor, width: 1.5),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        validator: (value) => value == null || value.isEmpty ? 'This field is required' : null,
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        AppDialog.showWarningDialog(context, title: 'Mismatch', message: 'Passwords do not match.');
        return;
      }

      if (uid.isEmpty || token.isEmpty) {
        AppDialog.showWarningDialog(context, title: 'Invalid Link', message: 'Reset link is invalid or expired.');
        return;
      }

      AppDialog.showLoadingDialog(context);

      final success = await _authService.resetPassword(
        uid,
        token,
        _newPasswordController.text.trim(),
      );

      Navigator.pop(context); // Close loading

      if (success) {
        await AppDialog.showSuccessDialog(context, title: 'Success', message: 'Your password has been reset.');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        await AppDialog.showWarningDialog(context, title: 'Error', message: 'Password reset failed. Try again.');
      }
    }
  }
}
