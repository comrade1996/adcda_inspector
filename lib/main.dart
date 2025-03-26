import 'package:adcda_inspector/screens/home_screen.dart';
import 'package:adcda_inspector/screens/login_screen.dart';
import 'package:adcda_inspector/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:adcda_inspector/controllers/survey_controller.dart';
import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

void main() {
  // Initialize controllers
  Get.put(SurveyController());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ADCDA Inspector',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18, 
            fontWeight: FontWeight.w600,
            fontFamily: 'NotoKufiArabic',
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
          onPrimary: Colors.black,
          secondary: Colors.white,
          surface: Colors.black,
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(
            fontFamily: 'NotoKufiArabic',
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FormBuilderLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', 'AE'), // Arabic
        Locale('en', 'US'), // English
      ],
      locale: const Locale('ar', 'AE'), // Default to Arabic
      fallbackLocale: const Locale('en', 'US'),
      textDirection: AppConstants.appTextDirection,
      home: Directionality(
        textDirection: AppConstants.appTextDirection,
        child: const LoginScreen(),
      ),
    );
  }
}
