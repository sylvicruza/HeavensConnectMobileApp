/*
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class AppConfig {
  static String get apiBaseUrl {
    if (kIsWeb) {
      if (kReleaseMode) {
        return "https://api.yourdomain.com";
      } else {
        return "http://localhost:8085";
      }
    }

    if (kReleaseMode) {
      return "https://api.yourdomain.com";
    } else {
      // 👇 Mobile debug
      if (Platform.isAndroid) {
        return "http://10.0.2.2:8085"; // Android emulator
      } else {
        return "http://192.168.1.174:8085"; // Real devices
      }
    }
  }
}
*/
