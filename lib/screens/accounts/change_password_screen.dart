import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/services/auth_service.dart';
import 'package:heavens_connect/utils/app_theme.dart';
import '../../utils/app_dialog.dart';


class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final Color themeColor = AppTheme.themeColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: themeColor),
        title: Text(
          'Change Password',
          style: montserratTextStyle(color: themeColor,
            fontWeight: FontWeight.bold,),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGlassHeader(),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _passwordField(
                      'Current Password', _currentPasswordController, Icons.lock_outline),
                  _passwordField(
                      'New Password', _newPasswordController, Icons.lock_reset),
                  _passwordField(
                      'Confirm New Password', _confirmPasswordController, Icons.check_circle_outline),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Update Password',
                      style: montserratTextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              Icon(Icons.lock_person_outlined,
                  size: 50, color: themeColor.withOpacity(0.8)),
              const SizedBox(height: 12),
              Text(
                'Secure your account',
                style: montserratTextStyle(fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeColor),
              ),
              const SizedBox(height: 6),
              Text(
                'Change your password regularly to protect your account.',
                textAlign: TextAlign.center,
                style: montserratTextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordField(
      String label, TextEditingController controller, IconData icon) {
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
        validator: (value) =>
        value == null || value.isEmpty ? 'This field is required' : null,
      ),
    );
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        AppDialog.showWarningDialog(
          context,
          title: 'Mismatch',
          message: 'New passwords do not match.',
        );
        return;
      }

      AppDialog.showLoadingDialog(context);

      final success = await _authService.changePassword(
        _currentPasswordController.text.trim(),
        _newPasswordController.text.trim(),
      );

      Navigator.pop(context); // Close loading

      if (success) {
        await AppDialog.showSuccessDialog(
          context,
          title: 'Success',
          message: 'Your password has been updated.\nPlease log in again with the new password.',
        );

        // Log user out and navigate to login screen
        await _authService.logout();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      else {
        await AppDialog.showWarningDialog(
          context,
          title: 'Failed',
          message:
          'Could not change password. Please check your current password.',
        );
      }
    }
  }
}
