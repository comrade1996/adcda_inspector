import 'package:adcda_inspector/screens/home_screen.dart';
import 'package:adcda_inspector/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:adcda_inspector/controllers/survey_controller.dart';

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
      title: 'ADCDA Inspector',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Always use light theme for white background
      debugShowCheckedModeBanner: false,
      textDirection: TextDirection.rtl, // Add RTL support
      home: Directionality(
        textDirection: TextDirection.rtl, // Ensure RTL applies to all screens
        child: const HomeScreen(),
      ),
    );
  }
}
