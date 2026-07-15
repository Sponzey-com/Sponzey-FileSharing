import 'package:flutter/material.dart';

abstract final class AppColors {
  static const techDark = Color(0xFF1E1E1E);
  static const techDarkRaised = Color(0xFF2A2A2A);
  static const techNavy = Color(0xFF182033);
  static const techBlue = Color(0xFF0066FF);
  static const techCyan = Color(0xFF00FFFF);
  static const techGreen = Color(0xFF19A974);
  static const techBackground = Color(0xFFF3F7FB);
  static const techInput = Color(0xFFF7FAFD);
  static const techBorder = Color(0xFFD9E2EC);
  static const techBorderStrong = Color(0xFFC8D6E5);
  static const techTextMuted = Color(0xFF667085);
  static const techTextOnDark = Color(0xFFD5E3F5);

  static const brandYellow = techBlue;
  static const brandYellowSoft = Color(0xFFF0F7FF);
  static const brandYellowMist = techBackground;
  static const ink = techNavy;
  static const body = Color(0xFF344054);
  static const muted = techTextMuted;
  static const paper = Color(0xFFFFFFFF);
  static const surfaceAlt = techInput;
  static const borderSoft = techBorder;
  static const success = techGreen;
  static const successSoft = Color(0xFFEAF8F2);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFFF4D6);
  static const danger = Color(0xFFE15241);
  static const dangerSoft = Color(0xFFFDEBE8);
  static const info = techBlue;
  static const infoSoft = Color(0xFFEAF2FF);

  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [techBackground, Color(0xFFEAF1F8)],
  );
}
