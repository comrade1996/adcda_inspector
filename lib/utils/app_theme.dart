import 'package:flutter/material.dart';
import 'package:adcda_inspector/constants/app_colors.dart';

/// AppTheme provides custom theme with centralized styling for the application
class AppTheme {
  // Font sizes
  static const double fontSizeXSmall = 12.0;
  static const double fontSizeSmall = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 20.0;
  static const double fontSizeXXLarge = 24.0;
  
  // Font weights
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  
  // Font family
  static const String arabicFontFamily = 'NotoKufiArabic';
  static const String defaultFontFamily = 'Roboto';
  
  // Spacing and sizing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXLarge = 16.0;
  static const double borderRadiusCircular = 50.0;
  
  // Elevation
  static const double elevationNone = 0.0;
  static const double elevationSmall = 1.0;
  static const double elevationMedium = 2.0;
  static const double elevationLarge = 4.0;
  static const double elevationXLarge = 8.0;
  
  // Text styles
  static TextStyle get headingLarge => TextStyle(
    fontSize: fontSizeXXLarge,
    fontWeight: fontWeightBold,
    color: AppColors.textPrimaryColor,
    fontFamily: arabicFontFamily,
  );
  
  static TextStyle get headingMedium => TextStyle(
    fontSize: fontSizeXLarge,
    fontWeight: fontWeightBold,
    color: AppColors.textPrimaryColor,
    fontFamily: arabicFontFamily,
  );
  
  static TextStyle get headingSmall => TextStyle(
    fontSize: fontSizeLarge,
    fontWeight: fontWeightSemiBold,
    color: AppColors.textPrimaryColor,
    fontFamily: arabicFontFamily,
  );
  
  static TextStyle get bodyLarge => TextStyle(
    fontSize: fontSizeMedium,
    fontWeight: fontWeightRegular,
    color: AppColors.textPrimaryColor,
    fontFamily: arabicFontFamily,
  );
  
  static TextStyle get bodyMedium => TextStyle(
    fontSize: fontSizeSmall,
    fontWeight: fontWeightRegular,
    color: AppColors.textPrimaryColor,
    fontFamily: arabicFontFamily,
  );
  
  static TextStyle get bodySmall => TextStyle(
    fontSize: fontSizeXSmall,
    fontWeight: fontWeightRegular,
    color: AppColors.textSecondaryColor,
    fontFamily: arabicFontFamily,
  );

  // Light text styles (for dark backgrounds)
  static TextStyle get headingLargeLight => headingLarge.copyWith(
    color: AppColors.whiteTextColor,
  );
  
  static TextStyle get headingMediumLight => headingMedium.copyWith(
    color: AppColors.whiteTextColor,
  );
  
  static TextStyle get headingSmallLight => headingSmall.copyWith(
    color: AppColors.whiteTextColor,
  );
  
  static TextStyle get bodyLargeLight => bodyLarge.copyWith(
    color: AppColors.whiteTextColor,
  );
  
  static TextStyle get bodyMediumLight => bodyMedium.copyWith(
    color: AppColors.whiteTextColor,
  );
  
  static TextStyle get bodySmallLight => bodySmall.copyWith(
    color: AppColors.whiteMutedColor,
  );
  
  // Button text styles
  static TextStyle get buttonTextStyle => TextStyle(
    fontFamily: arabicFontFamily,
    fontWeight: fontWeightMedium,
    fontSize: fontSizeSmall,
    color: AppColors.whiteTextColor,
  );
  
  // Error text style
  static TextStyle get errorTextStyle => TextStyle(
    color: AppColors.whiteTextColor,
    fontFamily: arabicFontFamily,
    fontSize: fontSizeMedium,
    fontWeight: fontWeightSemiBold,
  );
  
  // Body text style
  static TextStyle get bodyTextStyle => TextStyle(
    fontSize: fontSizeMedium,
    fontFamily: arabicFontFamily,
    color: AppColors.whiteMutedColor,
  );
  
  // Dropdown style
  static TextStyle get dropdownStyle => TextStyle(
    color: AppColors.whiteTextColor,
    fontFamily: arabicFontFamily,
    fontSize: fontSizeSmall,
  );
  
  // Question text style
  static TextStyle get questionTextStyle => TextStyle(
    color: AppColors.whiteTextColor,
    fontFamily: arabicFontFamily,
    fontSize: fontSizeMedium,
    fontWeight: fontWeightSemiBold,
  );
  
  // Question option style
  static TextStyle get questionOptionStyle => TextStyle(
    color: AppColors.whiteTextColor,
    fontFamily: arabicFontFamily,
    fontSize: fontSizeSmall,
    fontWeight: fontWeightRegular,
  );
  
  // Preview styles
  static TextStyle get previewQuestionStyle => TextStyle(
    fontSize: fontSizeSmall,
    fontWeight: fontWeightSemiBold,
    color: AppColors.whiteTextColor,
    fontFamily: arabicFontFamily,
  );
  
  static TextStyle get previewAnswerStyle => TextStyle(
    fontSize: fontSizeXSmall,
    color: AppColors.whiteMutedColor,
    fontFamily: arabicFontFamily,
  );
  
  static TextStyle get previewUnansweredStyle => TextStyle(
    fontSize: fontSizeXSmall,
    color: AppColors.warningColor,
    fontFamily: arabicFontFamily,
  );
  
  static TextStyle get stepperTextStyle => TextStyle(
    color: AppColors.whiteTextColor,
    fontSize: fontSizeSmall,
    fontWeight: fontWeightBold,
    fontFamily: arabicFontFamily,
  );
  
  // Button styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryColor,
    foregroundColor: AppColors.whiteTextColor,
    elevation: elevationMedium,
    padding: EdgeInsets.symmetric(horizontal: spacingLarge, vertical: spacingMedium),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
    ),
    textStyle: bodyMedium.copyWith(
      fontWeight: fontWeightMedium,
      color: AppColors.whiteTextColor,
    ),
  );
  
  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.primaryColor,
    elevation: elevationNone,
    padding: EdgeInsets.symmetric(horizontal: spacingLarge, vertical: spacingMedium),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
      side: BorderSide(color: AppColors.primaryColor),
    ),
    textStyle: bodyMedium.copyWith(
      fontWeight: fontWeightMedium,
      color: AppColors.primaryColor,
    ),
  );
  
  static ButtonStyle get whiteButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AppColors.whiteColor,
    foregroundColor: AppColors.primaryColor,
    elevation: elevationMedium,
    padding: EdgeInsets.symmetric(horizontal: spacingLarge, vertical: spacingMedium),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
    ),
    textStyle: bodyMedium.copyWith(
      fontWeight: fontWeightMedium,
      color: AppColors.primaryColor,
    ),
  );
  
  // Container styles
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AppColors.cardColor,
    borderRadius: BorderRadius.circular(borderRadiusLarge),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowColor.withOpacity(0.1),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration get darkCardDecoration => BoxDecoration(
    color: AppColors.darkSurfaceColor,
    borderRadius: BorderRadius.circular(borderRadiusLarge),
  );

  // Survey specific styles
  static TextStyle get questionStyle => bodyLargeLight.copyWith(
    fontWeight: fontWeightMedium,
  );
  
  static TextStyle get answerStyle => bodyMediumLight;
  
  static BoxDecoration get radioButtonDecoration => BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(
      color: AppColors.radioUnselectedColor,
      width: 2.0,
    ),
    color: Colors.transparent,
  );
  
  static BoxDecoration get radioButtonSelectedDecoration => radioButtonDecoration.copyWith(
    border: Border.all(
      color: AppColors.radioSelectedColor,
      width: 2.0,
    ),
    color: AppColors.radioSelectedColor,
  );
  
  // Preview specific styles
  static BoxDecoration get previewCardDecoration => BoxDecoration(
    color: AppColors.previewCardColor,
    borderRadius: BorderRadius.circular(borderRadiusMedium),
  );
}
