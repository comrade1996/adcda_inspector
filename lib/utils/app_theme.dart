import 'package:flutter/material.dart';

/// AppTheme provides custom theme with Tailwind styling using tailwind_cli package
class AppTheme {
  // Primary color palette - using Tailwind colors
  static final Color primary = const Color(0xFF3B82F6); // blue-500
  static final Color secondary = const Color(0xFF6366F1); // indigo-500
  static final Color accent = const Color(0xFF8B5CF6); // violet-500
  static final Color success = const Color(0xFF10B981); // emerald-500
  static final Color warning = const Color(0xFFF59E0B); // amber-500
  static final Color error = const Color(0xFFEF4444); // red-500
  static final Color info = const Color(0xFF3B82F6); // blue-500

  // Neutral colors
  static final Color black = const Color(0xFF000000);
  static final Color white = const Color(0xFFFFFFFF);
  static final Color gray50 = const Color(0xFFF9FAFB);
  static final Color gray100 = const Color(0xFFF3F4F6);
  static final Color gray200 = const Color(0xFFE5E7EB);
  static final Color gray300 = const Color(0xFFD1D5DB);
  static final Color gray400 = const Color(0xFF9CA3AF);
  static final Color gray500 = const Color(0xFF6B7280);
  static final Color gray600 = const Color(0xFF4B5563);
  static final Color gray700 = const Color(0xFF374151);
  static final Color gray800 = const Color(0xFF1F2937);
  static final Color gray900 = const Color(0xFF111827);

  // Font sizes (tailwind)
  static double get xs => 12.0;
  static double get sm => 14.0;
  static double get base => 16.0;
  static double get lg => 18.0;
  static double get xl => 20.0;
  static double get xl2 => 24.0;
  static double get xl3 => 30.0;
  static double get xl4 => 36.0;
  static double get xl5 => 48.0;

  // Spacing (tailwind)
  static double get spacing0 => 0.0;
  static double get spacing1 => 4.0;
  static double get spacing2 => 8.0;
  static double get spacing3 => 12.0;
  static double get spacing4 => 16.0;
  static double get spacing5 => 20.0;
  static double get spacing6 => 24.0;
  static double get spacing8 => 32.0;
  static double get spacing10 => 40.0;
  static double get spacing12 => 48.0;
  static double get spacing16 => 64.0;

  // Border radius (tailwind)
  static double get radiusNone => 0.0;
  static double get radiusSm => 2.0;
  static double get radiusBase => 4.0;
  static double get radiusMd => 6.0;
  static double get radiusLg => 8.0;
  static double get radiusXl => 12.0;
  static double get radius2xl => 16.0;
  static double get radius3xl => 24.0;
  static double get radiusFull => 9999.0;

  // Get Tailwind color utility
  static Color tw(String colorName) {
    try {
      return TwStyle.color(colorName);
    } catch (e) {
      return Colors.black;
    }
  }

  /// Theme for light mode
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        background: Colors.white,
        surface: Colors.white,
        onSurface: black,
        error: error,
      ),
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: xl5, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontSize: xl4, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontSize: xl3, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(fontSize: xl3, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: xl2, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontSize: xl, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: xl, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: lg, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: base, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: base),
        bodyMedium: TextStyle(fontSize: sm),
        bodySmall: TextStyle(fontSize: xs),
        labelLarge: TextStyle(fontSize: base, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontSize: sm, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontSize: xs, fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: white,
        foregroundColor: black,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          padding: EdgeInsets.symmetric(
            horizontal: spacing4,
            vertical: spacing3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: EdgeInsets.symmetric(
            horizontal: spacing4,
            vertical: spacing3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: EdgeInsets.symmetric(
            horizontal: spacing4,
            vertical: spacing3,
          ),
        ),
      ),
      iconTheme: IconThemeData(color: black),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: error, width: 1),
        ),
        errorStyle: TextStyle(color: error, fontSize: xs),
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing4,
          vertical: spacing3,
        ),
      ),
      cardTheme: CardTheme(
        color: white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
    );
  }

  /// Theme for dark mode
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        background: Colors.black,
        surface: Colors.grey[900]!,
        onSurface: Colors.white,
        error: error,
      ),
      scaffoldBackgroundColor: Colors.black,
      cardColor: Colors.grey[900],
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: xl5, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontSize: xl4, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontSize: xl3, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(fontSize: xl3, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: xl2, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontSize: xl, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: xl, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: lg, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: base, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: base),
        bodyMedium: TextStyle(fontSize: sm),
        bodySmall: TextStyle(fontSize: xs),
        labelLarge: TextStyle(fontSize: base, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontSize: sm, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontSize: xs, fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          padding: EdgeInsets.symmetric(
            horizontal: spacing4,
            vertical: spacing3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: EdgeInsets.symmetric(
            horizontal: spacing4,
            vertical: spacing3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: EdgeInsets.symmetric(
            horizontal: spacing4,
            vertical: spacing3,
          ),
        ),
      ),
      iconTheme: IconThemeData(color: Colors.white),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: error, width: 1),
        ),
        errorStyle: TextStyle(color: error, fontSize: xs),
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing4,
          vertical: spacing3,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.grey[900],
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
    );
  }

  // Helper methods to apply Tailwind-like styling

  // Text styles
  static TextStyle textXs({Color? color, FontWeight? fontWeight}) {
    return TextStyle(fontSize: xs, color: color, fontWeight: fontWeight);
  }

  static TextStyle textSm({Color? color, FontWeight? fontWeight}) {
    return TextStyle(fontSize: sm, color: color, fontWeight: fontWeight);
  }

  static TextStyle textBase({Color? color, FontWeight? fontWeight}) {
    return TextStyle(fontSize: base, color: color, fontWeight: fontWeight);
  }

  static TextStyle textLg({Color? color, FontWeight? fontWeight}) {
    return TextStyle(fontSize: lg, color: color, fontWeight: fontWeight);
  }

  static TextStyle textXl({Color? color, FontWeight? fontWeight}) {
    return TextStyle(fontSize: xl, color: color, fontWeight: fontWeight);
  }

  // Padding helpers
  static EdgeInsets p(double value) => EdgeInsets.all(value);
  static EdgeInsets px(double value) => EdgeInsets.symmetric(horizontal: value);
  static EdgeInsets py(double value) => EdgeInsets.symmetric(vertical: value);
  static EdgeInsets pt(double value) => EdgeInsets.only(top: value);
  static EdgeInsets pr(double value) => EdgeInsets.only(right: value);
  static EdgeInsets pb(double value) => EdgeInsets.only(bottom: value);
  static EdgeInsets pl(double value) => EdgeInsets.only(left: value);

  // Margin helpers (shorthand for padding, usable in Containers)
  static EdgeInsets m(double value) => EdgeInsets.all(value);
  static EdgeInsets mx(double value) => EdgeInsets.symmetric(horizontal: value);
  static EdgeInsets my(double value) => EdgeInsets.symmetric(vertical: value);
  static EdgeInsets mt(double value) => EdgeInsets.only(top: value);
  static EdgeInsets mr(double value) => EdgeInsets.only(right: value);
  static EdgeInsets mb(double value) => EdgeInsets.only(bottom: value);
  static EdgeInsets ml(double value) => EdgeInsets.only(left: value);

  // Border radius helpers
  static BorderRadius rounded(double radius) => BorderRadius.circular(radius);
  static BorderRadius roundedFull() => BorderRadius.circular(radiusFull);
}

class TwStyle {
  static Color color(String colorName) {
    // Implement color mapping logic here
    switch (colorName) {
      case 'primary':
        return Colors.blue; // Replace with your primary color
      case 'secondary':
        return Colors.grey; // Replace with your secondary color
      // Add more color mappings as needed
      default:
        return Colors.black; // Default color
    }
  }
}
