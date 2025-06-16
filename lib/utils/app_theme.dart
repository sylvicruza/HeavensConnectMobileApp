import 'package:flutter/material.dart';

class AppTheme {
  static const Color themeColor = Colors.deepPurple;
  static const Color appBarColor =  Colors.white;

  static const Color lightBackground = Color(0xFFF7F7F9);
  static const Color dangerColor = Colors.red;
  static const Color successColor = Colors.green;

}

// ✅ Outside the class so you can call it anywhere without instantiating AppTheme
TextStyle montserratTextStyle({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  double? height,
  TextDecoration? decoration,
  FontStyle? fontStyle,
}) {
  return TextStyle(
    fontFamily: 'Montserrat',
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
    decoration: decoration,
    fontStyle: fontStyle,
  );
}
