import 'package:flutter/material.dart';

abstract final class AppColors {
  static const brandYellow = Color(0xFFFEEA29);
  static const brandYellowSoft = Color(0xFFFFF7C8);
  static const brandYellowMist = Color(0xFFFFFEF2);
  static const ink = Color(0xFF111111);
  static const body = Color(0xFF444444);
  static const muted = Color(0xFF555555);
  static const paper = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF7F6F1);
  static const borderSoft = Color(0xFFD8D2A8);
  static const success = Color(0xFF1F9D55);
  static const successSoft = Color(0xFFE8F7EE);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFFF4D6);
  static const danger = Color(0xFFE15241);
  static const dangerSoft = Color(0xFFFDEBE8);
  static const info = Color(0xFF2479FF);
  static const infoSoft = Color(0xFFEAF1FF);

  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [brandYellowMist, brandYellowSoft],
  );
}
