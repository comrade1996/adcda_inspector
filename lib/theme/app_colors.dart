import 'package:flutter/material.dart';

/// Centralized color system for the application
/// This makes it easy to modify the app's color scheme
/// by changing colors in one place
class AppColors {
  // Main theme colors
  static final Color primary = Color(0xFF000000);     // Black for primary actions
  static final Color secondary = Color(0xFF333333);   // Dark gray for secondary elements
  static final Color accent = Color(0xFF555555);      // Mid gray for accents
  
  // Background colors
  static final Color background = Color(0xFFF5F5F5); // Light gray background
  static final Color cardBackground = Colors.white;  // White for cards
  
  // Text colors
  static final Color textPrimary = Color(0xFF222222);   // Almost black for primary text
  static final Color textSecondary = Color(0xFF666666); // Dark gray for secondary text
  static final Color textDisabled = Color(0xFF999999);  // Gray for disabled text
  
  // Status colors
  static final Color success = Color(0xFF28A745);    // Green for success
  static final Color warning = Color(0xFFFFC107);    // Amber for warnings
  static final Color error = Color(0xFFDC3545);      // Red for errors
  static final Color info = Color(0xFF17A2B8);       // Cyan for information
  
  // UI element colors
  static final Color divider = Color(0xFFE0E0E0);    // Light gray for dividers
  static final Color shadow = Color(0xFF000000);     // Black for shadows
  static final Color inputBorder = Color(0xFFD0D0D0); // Light gray for input borders
  static final Color borderColor = Color(0xFFEEEEEE); // Lighter gray for borders
  
  // Button colors
  static final Color buttonPrimary = primary;
  static final Color buttonSecondary = secondary;
  static final Color buttonDisabled = Color(0xFFCCCCCC);
  
  // Progress indicator colors
  static final Color progressIndicator = primary;
  static final Color progressBackground = Color(0xFFE0E0E0);
  static final Color progressInactive = Color(0xFFE0E0E0); // Added back for compatibility
  
  // Pill indicator colors
  static final Color activePill = primary;
  static final Color inactivePill = Color(0xFFD9D9D9);
}
