import 'package:flutter/material.dart';
import 'package:adcda_inspector/utils/api_config.dart';

/// Application-wide constants to avoid magic strings
class AppConstants {
  // API constants - use ApiConfig class instead of direct URLs
  static String get baseApiUrl => ApiConfig.baseUrl;
  
  // API Endpoints - using the centralized ApiConfig
  static String get surveyEndpoint => ApiConfig.surveysEndpoint;
  static String get surveyDetailEndpoint => ApiConfig.surveysEndpoint;
  static String get submitEndpoint => ApiConfig.surveySubmissionsEndpoint;
  static String get startSurveyEndpoint => ApiConfig.startSurveyEndpoint;
  static String get aliveEndpoint => ApiConfig.aliveEndpoint;
  static String get healthEndpoint => ApiConfig.healthEndpoint;
  
  // Auth endpoints
  static String get loginEndpoint => ApiConfig.loginEndpoint;
  static String get refreshTokenEndpoint => ApiConfig.refreshTokenEndpoint;

  // Language IDs
  static const int arabicLanguageId = 1;
  static const int englishLanguageId = 2;
  static const int urduLanguageId = 3;
  static const int defaultLanguageId = arabicLanguageId;

  // Error messages
  static const String networkError =
      'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String validationError =
      'Please check your input and try again.';
  static const String submittingText = 'Submitting...';
  static const String backButton = 'Back';
  static const String requiredField = 'هذا الحقل مطلوب';
  
  // Default values
  static const int defaultSurveyId = 6;   // Default survey ID

  // Validation messages
  static const String invalidEmail = 'Please enter a valid email address';
  static const String invalidNumber = 'Please enter a valid number';
  static const String invalidDate = 'Please enter a valid date';

  // Labels
  static const String submitButton = 'Submit';
  static const String cancelButton = 'Cancel';
  static const String nextButton = 'Next';
  static const String previousButton = 'Previous';
  static const String loadingText = 'Loading...';
  static const String surveyCompleteText = 'Survey completed successfully!';
  static const String backToHomeButton = 'Back to Home';
  static const String surveyScreenTitle = 'نموذج تقييم جاهزية مراكز الدفاع المدني';

  // Form field identifiers
  static const String respondentEmailField = 'respondentEmail';
  static const String respondentIdField = 'respondentId';
  static const String commentsField = 'comments';

  // Local storage keys
  static const String surveyDataKey = 'survey_data';
  static const String languageKey = 'selected_language';
  static const String userDataKey = 'user_data';
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';

  // Animation durations
  static const int shortAnimationDuration = 200; // milliseconds
  static const int mediumAnimationDuration = 500; // milliseconds
  static const int longAnimationDuration = 800; // milliseconds

  // Text direction for RTL support
  static const appTextDirection = TextDirection.rtl;
}
