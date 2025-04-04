import 'package:flutter/material.dart';

/// A centralized color system for the application
class AppColors {
  // Primary colors
  static const Color primaryColor = Color(0xFF000000); // Black primary color
  static const Color secondaryColor = Color(0xFF757575);
  static const Color accentColor = Color(0xFF0288D1);
  
  // Text colors
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color whiteColor = Colors.white;
  static const Color whiteTextColor = Colors.white;
  static const Color whiteMutedColor = Color(0xCCFFFFFF); // Slightly transparent white
  static const Color whiteDimmedColor = Color(0xAAFFFFFF); // More transparent white
  
  // Backgrounds
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color darkBackgroundColor = Colors.black;
  static const Color cardBackgroundColor = Colors.white;
  static const Color inactiveCardColor = Color(0xFFE0E0E0);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color darkSurfaceColor = Color(0xFF1A1A1A);
  
  // Button colors
  static const Color buttonColor = Colors.white;
  static const Color buttonTextColor = Colors.black;
  static const Color disabledButtonColor = Color(0xFF9E9E9E);
  
  // Rating colors
  static const Color ratingActiveColor = primaryColor;
  static const Color ratingInactiveColor = Color(0x80000000); // Semi-transparent black
  static const Color starActiveColor = Color(0xFFFFD700); // Gold color
  static const Color starInactiveColor = Color(0xFFAAAAAA); // Light gray
  
  // Question colors
  static const Color questionCardColor = Color(0xFF1E1E1E); // Slightly lighter black
  static const Color checkboxActiveColor = primaryColor;
  static const Color checkboxInactiveColor = Color(0xFF505050);
  static const Color radioButtonActiveColor = primaryColor;
  static const Color radioButtonInactiveColor = Color(0xFF505050);
  static const Color dropdownBackgroundColor = Color(0xFF333333);
  static const Color textInputBackgroundColor = Color(0xFF282828);
  static const Color textInputBorderColor = Color(0xFF444444);
  static const Color requiredFieldColor = Color(0xFFFF5252);
  
  // Status colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFFA726); // Orange
  static const Color infoColor = Color(0xFF2196F3);
  static const Color activeColor = Color(0xFF4CAF50); // Green for active status
  static const Color inactiveColor = Color(0xFF9E9E9E); // Gray for inactive status
  
  // Preview colors
  static const Color previewBackgroundColor = Color(0xFF1A1A1A);
  static const Color previewCardColor = Color(0x0DFFFFFF);
  static const Color previewUnansweredColor = Color(0xFFDD6666);
  static const Color previewItemColor = Color(0xFF222222);
  static const Color previewButtonColor = Color(0xFF333333);
  static const Color fileBackgroundColor = Color(0xFF333333);
  
  // Stepper colors
  static const Color stepperCompletedColor = Color(0x80000000);
  static const Color stepperCurrentColor = primaryColor;
  static const Color stepperInactiveColor = Color(0xFF444444);
  static const Color stepperTextColor = Color(0xFFFFFFFF); // White text for stepper
  static const Color stepperCompletionColor = Color(0xFF4CAF50); // Green for completed steps
  
  // UI elements
  static const Color dividerColor = Color(0xFF333333);
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color shadowColor = Color(0x40000000);
  static const Color disabledColor = Color(0xFFBDBDBD);
  
  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF000000),
    Color(0xFF212121),
  ];
  
  // Survey component colors
  static const Color radioSelectedColor = primaryColor;
  static const Color radioUnselectedColor = Color(0xFF9E9E9E);
  static const Color checkboxSelectedColor = primaryColor;
  static const Color checkboxUnselectedColor = Color(0xFF9E9E9E);
}
