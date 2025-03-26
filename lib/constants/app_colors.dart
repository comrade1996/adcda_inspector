import 'package:flutter/material.dart';

/// A centralized color system for the application
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF000000); // Black primary color
  static const Color secondary = Color(0xFF757575);
  static const Color accent = Color(0xFF0288D1);
  
  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  
  // Backgrounds
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // UI elements
  static const Color divider = Color(0xFFE0E0E0);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x80000000);
  static const Color disabled = Color(0xFFBDBDBD);
  
  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF000000),
    Color(0xFF212121),
  ];
}
