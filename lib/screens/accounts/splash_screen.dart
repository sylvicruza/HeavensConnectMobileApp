import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heavens_connect/screens/accounts/login_screen.dart';
import 'package:heavens_connect/screens/accounts/reset_password_screen.dart';



class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      final uri = Uri.base;
      final path = uri.path;
      final uid = uri.queryParameters['uid'];
      final token = uri.queryParameters['token'];

      if (path == '/reset-password' && uid != null && token != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(uid: uid, token: token),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFFF8F9FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  Icons.self_improvement,
                  size: 100,
                  color: Colors.white,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud,
                    size: 100,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'HeavensConnect',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Connecting Heaven’s Help with Earth’s Needs',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.white70,
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
}
