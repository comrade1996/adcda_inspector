/// Application-wide constants to avoid magic strings
class AppConstants {
  // API endpoints
  static const String baseUrl = 'https://api.adcda.gov.ae';
  static const String surveyEndpoint = '/surveys';
  static const String submitEndpoint = '/submit';

  // Error messages
  static const String networkError =
      'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String validationError =
      'Please check your input and try again.';
  static const String submittingText = 'Submitting...';
  static const String backButton = 'Back';
  
  // Default values
  static const int defaultLanguageId = 2; // English
  static const int arabicLanguageId = 1;
  static const int urduLanguageId = 3;

  // Validation messages
  static const String requiredField = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email address';
  static const String invalidNumber = 'Please enter a valid number';
  static const String invalidDate = 'Please enter a valid date';

  // Labels
  static const String submitButton = 'Submit';
  static const String cancelButton = 'Cancel';
  static const String nextButton = 'Next';
  static const String previousButton = 'Previous';
  static const String loadingText = 'Loading...';
  static const String surveyCompleteText =
      'Thank you for completing the survey!';
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

  // Animation durations
  static const int shortAnimationDuration = 200; // milliseconds
  static const int mediumAnimationDuration = 500; // milliseconds
  static const int longAnimationDuration = 800; // milliseconds
}
