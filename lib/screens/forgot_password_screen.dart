import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _identifierController = TextEditingController();
  bool _isLoading = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    final themeColor = AppTheme.themeColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password', style: GoogleFonts.montserrat(color: themeColor)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: themeColor),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Enter your username or email', style: GoogleFonts.montserrat(fontSize: 16)),
            const SizedBox(height: 20),
            TextField(
              controller: _identifierController,
              decoration: InputDecoration(
                labelText: 'Username or Email',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleForgotPassword,
              style: ElevatedButton.styleFrom(backgroundColor: themeColor),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Send Reset Link', style: GoogleFonts.montserrat(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            if (_message != null)
              Text(_message!, style: GoogleFonts.montserrat(color: Colors.green)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      setState(() {
        _message = 'Please enter your username or email.';
        _isLoading = false;
      });
      return;
    }

    final success = await _authService.forgotPassword(identifier);
    setState(() {
      _isLoading = false;
      _message = success
          ? 'Reset link sent! Please check your email.'
          : 'Failed to send reset link.';
    });
  }
}
