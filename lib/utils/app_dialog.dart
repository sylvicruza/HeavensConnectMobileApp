// lib/widgets/dialogs/app_dialog.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'app_theme.dart';

class AppDialog extends StatelessWidget {
  final String animationPath;
  final String title;
  final String? message;
  final List<Widget> actions;

  const AppDialog({
    super.key,
    required this.animationPath,
    required this.title,
    this.message,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(animationPath, height: 120),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (message != null) ...[
              const SizedBox(height: 10),
              Text(message!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),
            ...actions,
          ],
        ),
      ),
    );
  }

  static Future<void> showLoadingDialog(BuildContext context, {String message = 'Please wait...'}) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppDialog(
        animationPath: 'assets/animations/loading.json',
        title: message,
      ),
    );
  }

  static Future<void> showSuccessDialog(BuildContext context, {String title = 'Success', String? message}) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppDialog(
        animationPath: 'assets/animations/success.json',
        title: title,
        message: message,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.themeColor),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  static Future<void> showWarningDialog(BuildContext context, {required String title, String? message}) async {
    return showDialog(
      context: context,
      builder: (_) => AppDialog(
        animationPath: 'assets/animations/warning1.json',
        title: title,
        message: message,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}
