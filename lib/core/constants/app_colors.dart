import 'package:flutter/material.dart';

/// ألوان التطبيق الأساسية - Tamenny Design System
/// المستوحاة من الهوية البصرية الجديدة (Blue & Green)
class AppColors {
  AppColors._();

  // الألوان الأساسية من الهوية
  static const Color primary = Color(0xFF4A90E2); // Sky Blue (#4A90E2)
  static const Color primaryGreen = Color(0xFF2ECC71); // Emerald Green (#2ecc71)
  static const Color primaryLight = Color(0xFFEBF1FC); // Icy Blue Background (#EBF1FC)
  static const Color primaryMint = Color(0xFFEAF8F0); // Mint Green Accent (#EAF8F0)
  
  // ألوان إضافية
  static const Color primaryDark = Color(0xFF2D5C91);
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFFF4757);
  static const Color warning = Color(0xFFFFBE21);

  // ألوان الخلفية والقواعد
  static const Color background = Color(0xFFEBF1FC);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFE2E8F0);

  // ألوان النصوص
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Gradients (Premium Icy Look)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF357ABD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0xCCFFFFFF),
      Color(0x99FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient meshBlue = LinearGradient(
    colors: [Color(0xFF4A90E2), Color(0xFFEBF1FC)],
  );
}

