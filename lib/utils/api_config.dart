/// API Configuration class for centralized management of all API endpoints
class ApiConfig {
  // Environment URLs - can be switched based on deployment environment
  static const Map<String, String> _environments = {
    'development': 'https://dev.adcd.gov.ae/AdcdaInspectorApi/api',
    'staging': 'https://dev.adcd.gov.ae/AdcdaInspectorApi/api',
    'production': 'https://api.adcda-inspector.com/api',
  };

  // Current active environment
  static const String _currentEnvironment = 'development';

  // Get the base URL for the current environment
  static String get baseUrl => _environments[_currentEnvironment]!;

  // API endpoint paths (without base URL)
  static const String _surveysPath = '/Surveys';
  static const String _surveySubmissionsPath = '/SurveySubmissions';
  static const String _alivePath = '/Alive';
  static const String _authPath = '/Auth';

  // Full endpoint URLs constructed from base URL and paths
  static String get surveysEndpoint => '$baseUrl$_surveysPath';
  static String get surveySubmissionsEndpoint =>
      '$baseUrl$_surveySubmissionsPath';
  static String get startSurveyEndpoint =>
      '$baseUrl$_surveySubmissionsPath/start';
  static String get aliveEndpoint => '$baseUrl$_alivePath';
  static String get healthEndpoint => '$baseUrl$_alivePath/health';

  // Auth endpoints
  static String get loginEndpoint => '$baseUrl$_authPath/login';
  static String get uaePassLoginEndpoint => '$baseUrl$_authPath/login/uae-pass';
  static String get refreshTokenEndpoint => '$baseUrl$_authPath/refresh-token';
  static String get revokeTokenEndpoint => '$baseUrl$_authPath/revoke-token';
  static String get registerEndpoint => '$baseUrl$_authPath/register/customer';
  static String get verifyEmailEndpoint => '$baseUrl$_authPath/verify-email';
  static String get verifyPhoneEndpoint => '$baseUrl$_authPath/verify-phone';

  // Utility method to get survey detail endpoint for a specific survey ID
  static String getSurveyDetailEndpoint(int surveyId, {int? languageId}) =>
      languageId != null
          ? '$surveysEndpoint/$surveyId?languageId=$languageId'
          : '$surveysEndpoint/$surveyId';

  // Utility method to get submission endpoint for a specific GUID
  static String getSubmissionEndpoint(String guid) =>
      '$surveySubmissionsEndpoint/$guid';

  // Utility method to get submission endpoint with submit action
  static String getSubmitEndpoint(String guid) =>
      '${getSubmissionEndpoint(guid)}/submit';

  // Utility method to check submission status
  static String get checkSubmissionEndpoint =>
      '$surveySubmissionsEndpoint/checksubmission';

  // Utility method to get submissions by survey ID
  static String getSubmissionsBySurveyEndpoint(int surveyId) =>
      '$surveySubmissionsEndpoint/bysurvey/$surveyId';

  // Utility method for general API operations
  static String get submitEndpoint => surveySubmissionsEndpoint;

  // Change the environment (could be called at app startup based on config)
  static String setEnvironment(String env) {
    if (_environments.containsKey(env)) {
      return _environments[env]!;
    }
    return baseUrl; // Return current base URL if environment is invalid
  }

  // UAE Pass Configuration - Staging Sandbox Environment
  // These staging sandbox values should be replaced with production values when going live
  static const String uaePassClientId = 'sandbox_stage';
  static const String uaePassClientSecret = 'sandbox_stage';
  static const String uaePassRedirectUri = 'adcdainspector://uaepass/callback';

  // UAE Pass environments
  static const Map<String, String> _uaePassEnvironments = {
    'development': 'stg', // staging
    'staging': 'stg', // staging
    'production': 'prod', // production
  };

  // Get the UAE Pass environment for the current app environment
  static String get uaePassEnvironment =>
      _uaePassEnvironments[_currentEnvironment]!;
}
