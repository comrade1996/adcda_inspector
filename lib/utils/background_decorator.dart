import 'package:flutter/material.dart';
import 'package:adcda_inspector/constants/app_colors.dart';

/// A utility class to apply consistent background patterns across the app
class BackgroundDecorator {
  /// Pattern background decoration for containers
  static BoxDecoration patternDecoration({
    Color backgroundColor = Colors.white,
    double opacity = 0.1,
    double borderRadius = 8.0,
    Color? borderColor,
    double borderWidth = 1.0,
    BoxShadow? shadow,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: borderColor != null
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
      boxShadow: shadow != null ? [shadow] : null,
      image: DecorationImage(
        image: AssetImage("assets/images/pattern.png"),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(
          backgroundColor.withOpacity(opacity),
          BlendMode.dstATop,
        ),
      ),
    );
  }

  /// Light pattern background with white base
  static BoxDecoration get lightPatternDecoration => patternDecoration(
        backgroundColor: Colors.white,
        opacity: 0.07,
        borderColor: AppColors.borderColor,
        shadow: BoxShadow(
          color: Colors.black.withOpacity(0.05),
          spreadRadius: 1,
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
      );

  /// Dark pattern background with primary color base
  static BoxDecoration get primaryPatternDecoration => patternDecoration(
        backgroundColor: AppColors.primary,
        opacity: 0.15,
        borderRadius: 12.0,
      );

  /// Subtle pattern for card backgrounds
  static BoxDecoration get cardPatternDecoration => patternDecoration(
        backgroundColor: Colors.white,
        opacity: 0.05,
        borderColor: AppColors.borderColor.withOpacity(0.5),
        borderWidth: 0.5,
        shadow: BoxShadow(
          color: Colors.black.withOpacity(0.03),
          spreadRadius: 0,
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      );
}
