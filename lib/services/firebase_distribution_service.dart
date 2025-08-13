import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseDistributionService {
  static FirebaseDistributionService? _instance;
  static FirebaseDistributionService get instance {
    _instance ??= FirebaseDistributionService._();
    return _instance!;
  }

  FirebaseDistributionService._();

  /// Initialize Firebase with environment-specific configuration
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      print('Firebase initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
      rethrow;
    }
  }

  /// Get current build environment
  String get buildEnvironment {
    return dotenv.env['BUILD_ENVIRONMENT'] ?? 'production';
  }

  /// Get Firebase project ID
  String get projectId {
    return dotenv.env['FIREBASE_PROJECT_ID'] ?? 'adcda-inspector-prod';
  }

  /// Get Android App ID
  String get androidAppId {
    return dotenv.env['FIREBASE_ANDROID_APP_ID'] ?? '';
  }

  /// Get iOS App ID
  String get iosAppId {
    return dotenv.env['FIREBASE_IOS_APP_ID'] ?? '';
  }

  /// Get tester groups
  String get testerGroups {
    return dotenv.env['FIREBASE_TESTER_GROUPS'] ?? 'adcda-internal';
  }

  /// Get app version
  String get appVersion {
    return dotenv.env['APP_VERSION'] ?? '1.0.0';
  }

  /// Check if Firebase is properly configured
  bool get isConfigured {
    return androidAppId.isNotEmpty && iosAppId.isNotEmpty;
  }

  /// Get configuration summary
  Map<String, String> get configSummary {
    return {
      'environment': buildEnvironment,
      'projectId': projectId,
      'androidAppId':
          androidAppId.isNotEmpty
              ? '${androidAppId.substring(0, 10)}...'
              : 'Not configured',
      'iosAppId':
          iosAppId.isNotEmpty
              ? '${iosAppId.substring(0, 10)}...'
              : 'Not configured',
      'testerGroups': testerGroups,
      'appVersion': appVersion,
    };
  }
}
