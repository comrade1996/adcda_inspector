import 'package:adcda_inspector/screens/home_screen.dart';
import 'package:adcda_inspector/screens/login_screen.dart';
import 'package:adcda_inspector/screens/survey_list_screen.dart';
import 'package:adcda_inspector/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:adcda_inspector/controllers/survey_controller.dart';
import 'package:adcda_inspector/controllers/auth_controller.dart';
import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/constants/app_colors.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:adcda_inspector/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adcda_inspector/services/api_service.dart';
import 'package:adcda_inspector/services/survey_service.dart';
import 'package:adcda_inspector/services/auth_service.dart';
import 'package:adcda_inspector/services/uae_pass_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: "assets/env/.env.prod");
  } catch (e) {
    print("Warning: Could not load environment file: $e");
  }

  // Create a fresh instance of the API service for each query to avoid caching issues
  Get.lazyPut(() => ApiService(), fenix: true);
  Get.lazyPut(() => SurveyService(), fenix: true);
  Get.lazyPut(() => AuthService(), fenix: true);
  Get.lazyPut(() => UAEPassService(), fenix: true);

  // Initialize controllers
  Get.put(SurveyController());
  
  // Initialize auth controller
  final authController = Get.put(AuthController());
  await authController.initAuth();

  // Load default language from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final defaultLanguageId =
      prefs.getInt('languageId') ?? 1; // Default to Arabic (1)

  runApp(MyApp(defaultLanguageId: defaultLanguageId));
}

class MyApp extends StatelessWidget {
  final int defaultLanguageId;

  const MyApp({super.key, required this.defaultLanguageId});

  @override
  Widget build(BuildContext context) {
    // Get the auth controller
    final authController = Get.find<AuthController>();
    
    // Set initial locale based on language ID
    Locale initialLocale;
    switch (defaultLanguageId) {
      case 2:
        initialLocale = const Locale('en');
        break;
      case 3:
        initialLocale = const Locale('ur');
        break;
      case 1:
      default:
        initialLocale = const Locale('ar');
        break;
    }

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ADCDA Inspector',

      // Localization settings
      locale: initialLocale,
      supportedLocales: const [
        Locale('ar'), // Arabic
        Locale('en'), // English
        Locale('ur'), // Urdu - We include it here to allow UI to show the option
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FormBuilderLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        // For FormBuilderValidators, we'll always use Arabic for Urdu locale
        // This prevents the warning message about missing Urdu support
        if (locale?.languageCode == 'ur') {
          // Use Arabic localization for form validation
          // but keep Urdu for the rest of the app
          return const Locale('ar');
        }
        return locale;
      },
      fallbackLocale: const Locale('ar'), // Arabic as fallback
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.whiteColor),
          titleTextStyle: TextStyle(
            color: AppColors.whiteColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'NotoKufiArabic',
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonColor,
            foregroundColor: AppColors.buttonTextColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.whiteColor),
        ),
        colorScheme: ColorScheme.dark(
          primary: AppColors.primaryColor,
          onPrimary: AppColors.whiteColor,
          secondary: AppColors.secondaryColor,
          surface: AppColors.surfaceColor,
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontFamily: 'NotoKufiArabic'),
        ),
      ),
      textDirection: AppConstants.appTextDirection,
      
      // Auth-aware home page
      home: Obx(() {
        return authController.isInitialized.value
            ? authController.isAuthenticated.value
                ? Directionality(
                    textDirection: AppConstants.appTextDirection,
                    child: const HomeScreen(),
                  )
                : Directionality(
                    textDirection: AppConstants.appTextDirection,
                    child: const LoginScreen(),
                  )
            : Directionality(
                textDirection: AppConstants.appTextDirection,
                child: const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
      }),
      
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(
          name: '/home', 
          page: () => const HomeScreen(),
          middlewares: [
            RouteGuard(),
          ],
        ),
        GetPage(
          name: '/surveys',
          page: () => SurveyListScreen(defaultLanguageId: defaultLanguageId),
          middlewares: [
            RouteGuard(),
          ],
        ),
      ],
    );
  }
}

// Route guard middleware to check authentication
class RouteGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();
    return authController.isAuthenticated.value 
        ? null 
        : const RouteSettings(name: '/login');
  }
}
