import 'dart:async';
import 'dart:convert';
import 'package:adcda_inspector/services/auth_service.dart';
import 'package:adcda_inspector/utils/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:uaepass_api/uaepass_api.dart';
import 'package:uaepass_api/uaepass/uaepass_user_profile_model.dart';
import 'package:adcda_inspector/l10n/app_localizations.dart';

class UAEPassService extends GetxService {
  final AuthService _authService = Get.find<AuthService>();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late UaePassAPI _uaePassAPI;

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // UAE Pass configuration - Using staging sandbox environment
  final String _clientId = ApiConfig.uaePassClientId;
  final String _clientSecret = ApiConfig.uaePassClientSecret;
  final String _redirectUri = ApiConfig.uaePassRedirectUri;
  final String _appScheme = "adcdainspector";
  final bool _isProduction = false; // Using staging environment (false = staging, true = production)
  
  @override
  void onInit() {
    super.onInit();
    _initUAEPass();
  }

  // Initialize UAE Pass SDK
  void _initUAEPass() {
    _uaePassAPI = UaePassAPI(
      clientId: _clientId,
      clientSecrete: _clientSecret,
      redirectUri: _redirectUri,
      appScheme: _appScheme,
      language: Get.locale?.languageCode ?? 'en',
      isProduction: _isProduction,
    );
  }
  
  // Check if UAE Pass app is installed and use appropriate authentication method
  Future<String?> _getUAEPassAuthCode(BuildContext context) async {
    try {
      // First try with UAE Pass app
      return await _uaePassAPI.signIn(context);
    } catch (e) {
      // If app is not found or other error occurs, show a dialog to the user
      bool useBrowser = await _showAppNotFoundDialog(context);
      
      if (useBrowser) {
        // Use browser-based authentication
        // Here we're still using the same SDK but informing the user
        // that we're using browser-based authentication
        return await _uaePassAPI.signIn(context);
      } else {
        // User cancelled
        return null;
      }
    }
  }
  
  // Show dialog when UAE Pass app is not found
  Future<bool> _showAppNotFoundDialog(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.translate('uaePassAppNotFound') ?? 'UAE Pass App Not Found'),
          content: Text(
            localizations.translate('uaePassAppNotFoundMessage') ?? 
            'The UAE Pass app is not installed on this device. '
            'Would you like to continue with browser-based authentication?'
          ),
          actions: <Widget>[
            TextButton(
              child: Text(localizations.translate('cancel') ?? 'Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text(localizations.translate('continueWithBrowser') ?? 'Continue with Browser'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false; // Default to false if dialog is dismissed
  }

  // Update language
  void updateLanguage(String langCode) {
    _uaePassAPI = UaePassAPI(
      clientId: _clientId,
      clientSecrete: _clientSecret,
      redirectUri: _redirectUri,
      appScheme: _appScheme,
      language: langCode,
      isProduction: _isProduction,
    );
  }

  // Sign in with UAE Pass
  Future<bool> signInWithUAEPass(BuildContext context) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Get authorization code from UAE Pass with fallback to browser if app not found
      final String? code = await _getUAEPassAuthCode(context);
      
      // If code is null, the user cancelled the login or an error occurred
      if (code == null) {
        errorMessage.value = 'UAE Pass login cancelled or failed';
        return false;
      }

      // Exchange code for access token
      final String? accessToken = await _uaePassAPI.getAccessToken(code);
      
      if (accessToken == null) {
        errorMessage.value = 'Failed to get access token from UAE Pass';
        return false;
      }

      // Get user profile
      final userProfile = await _uaePassAPI.getUserProfile(accessToken);
      
      if (userProfile == null) {
        errorMessage.value = 'Failed to get user profile from UAE Pass';
        return false;
      }

      // Store UAE Pass user info securely
      await _storeUAEPassUserInfo(userProfile, accessToken);

      // Notify the auth service about successful login
      // This would typically involve a backend API call to authenticate with your system
      // For now, we'll just set the isLoggedIn state
      _authService.isLoggedIn.value = true;
      
      return true;
    } catch (e) {
      print('UAE Pass sign-in error: $e');
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Store UAE Pass user information securely
  Future<void> _storeUAEPassUserInfo(UAEPASSUserProfile userProfile, String accessToken) async {
    await _secureStorage.write(key: 'uae_pass_access_token', value: accessToken);
    
    // Store the profile as a string representation
    await _secureStorage.write(key: 'uae_pass_user_profile', value: userProfile.toString());
    
    // Store individual profile fields for easier access
    if (userProfile.idn != null) {
      await _secureStorage.write(key: 'uae_pass_idn', value: userProfile.idn.toString());
    }
    
    if (userProfile.firstnameEN != null) {
      await _secureStorage.write(
          key: 'uae_pass_name_en', 
          value: '${userProfile.firstnameEN} ${userProfile.lastnameEN ?? ''}');
    }
    
    if (userProfile.firstnameAR != null) {
      await _secureStorage.write(
          key: 'uae_pass_name_ar', 
          value: '${userProfile.firstnameAR} ${userProfile.lastnameAR ?? ''}');
    }
    
    if (userProfile.email != null) {
      await _secureStorage.write(key: 'uae_pass_email', value: userProfile.email.toString());
    }
    
    if (userProfile.mobile != null) {
      await _secureStorage.write(key: 'uae_pass_mobile', value: userProfile.mobile.toString());
    }
    
    // For quick identification of UAE Pass login method
    await _secureStorage.write(key: 'auth_method', value: 'uae_pass');
  }

  // Get UAE Pass user information
  Future<Map<String, String?>> getUAEPassUserInfo() async {
    final Map<String, String?> userInfo = {};
    
    userInfo['idn'] = await _secureStorage.read(key: 'uae_pass_idn');
    userInfo['name_en'] = await _secureStorage.read(key: 'uae_pass_name_en');
    userInfo['name_ar'] = await _secureStorage.read(key: 'uae_pass_name_ar');
    userInfo['email'] = await _secureStorage.read(key: 'uae_pass_email');
    userInfo['mobile'] = await _secureStorage.read(key: 'uae_pass_mobile');
    
    return userInfo;
  }

  // Check if user is signed in with UAE Pass
  Future<bool> isSignedInWithUAEPass() async {
    final authMethod = await _secureStorage.read(key: 'auth_method');
    return authMethod == 'uae_pass';
  }

  // Logout from UAE Pass
  Future<void> logout(BuildContext context) async {
    try {
      isLoading.value = true;
      
      // Call UAE Pass logout
      await _uaePassAPI.logout(context);
      
      // Clear UAE Pass data
      await _secureStorage.delete(key: 'uae_pass_access_token');
      await _secureStorage.delete(key: 'uae_pass_user_profile');
      await _secureStorage.delete(key: 'uae_pass_idn');
      await _secureStorage.delete(key: 'uae_pass_name_en');
      await _secureStorage.delete(key: 'uae_pass_name_ar');
      await _secureStorage.delete(key: 'uae_pass_email');
      await _secureStorage.delete(key: 'uae_pass_mobile');
      await _secureStorage.delete(key: 'auth_method');
      
      // Call the app's main logout method to clear app session
      await _authService.logout();
    } catch (e) {
      print('UAE Pass logout error: $e');
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
