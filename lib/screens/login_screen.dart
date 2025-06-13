import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heavens_connect/services/auth_service.dart';
import 'package:heavens_connect/utils/app_dialog.dart';
import '../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final Color primaryColor = AppTheme.themeColor;
  final Color secondaryColor = const Color(0xFFECEBF1);

  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _buttonPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      await AppDialog.showWarningDialog(
        context,
        title: 'Missing Fields',
        message: 'Username and password are required.',
      );
      return;
    }

    AppDialog.showLoadingDialog(context);

    final success = await _authService.login(username, password);
    Navigator.pop(context);

    if (success) {
      final userType = await _authService.getUserType();

      if (userType == 'admin' || userType == 'superuser' || userType == 'finance') {
        Navigator.pushReplacementNamed(context, '/adminDashboard');
      } else if (userType == 'member') {
        Navigator.pushReplacementNamed(context, '/memberDashboard');
      } else {
        await AppDialog.showWarningDialog(
          context,
          title: 'Error',
          message: 'Unknown user type.',
        );
      }
    } else {
      await AppDialog.showWarningDialog(
        context,
        title: 'Login Failed',
        message: 'Invalid username or password.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // LOGO WITH TEXT
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 100, bottom: 16),
              child: ScaleTransition(
                scale: _fadeAnimation,
                child: Column(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/volunteer_heart_icon.svg',
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      width: 90,
                      height: 90,
                    ),
                    Text(
                      'Heavens Connect',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'The Welfare App',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.5)
                    : Colors.white.withOpacity(0.9),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: Column(
                  children: [
                    Text(
                      'Welcome back',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Login to continue',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(_usernameController, 'Username', Icons.person),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/forgotPassword'),
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.montserrat(
                            color: primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTapDown: (_) => setState(() => _buttonPressed = true),
                      onTapUp: (_) {
                        setState(() => _buttonPressed = false);
                        _login();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        transform: Matrix4.identity()
                          ..scale(_buttonPressed ? 0.98 : 1.0),
                        height: 50,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, primaryColor.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Login',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/requestMembership'),
                        child: Text(
                          "Don't have an account? Request Membership",
                          style: GoogleFonts.montserrat(
                            color: primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(Icons.lock, color: primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: primaryColor,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
