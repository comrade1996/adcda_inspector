import 'dart:async';
import 'dart:convert';
import 'package:adcda_inspector/services/auth_service.dart';
import 'package:adcda_inspector/utils/api_config.dart';
import 'package:adcda_inspector/services/api_service.dart';
import 'package:adcda_inspector/models/auth_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:uaepass_api/uaepass_api.dart';
import 'package:uaepass_api/uaepass/uaepass_user_profile_model.dart';
import 'package:adcda_inspector/l10n/app_localizations.dart';

class UAEPassService extends GetxService {
  final AuthService _authService = Get.find<AuthService>();
  final ApiService _apiService = Get.find<ApiService>();
  final Dio _dio = Dio(); // For direct API calls
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
      print('🔑 UAE Pass: Starting authentication flow');
      final String? code = await _getUAEPassAuthCode(context);
      
      // If code is null, the user cancelled the login or an error occurred
      if (code == null) {
        print('❌ UAE Pass: Authentication cancelled or failed - no auth code received');
        errorMessage.value = 'UAE Pass login cancelled or failed';
        return false;
      }
      
      print('✅ UAE Pass: Received authorization code');

      // Exchange code for access token
      print('🔄 UAE Pass: Exchanging code for access token');
      final String? accessToken = await _uaePassAPI.getAccessToken(code);
      
      if (accessToken == null) {
        print('❌ UAE Pass: Failed to get access token');
        errorMessage.value = 'Failed to get access token from UAE Pass';
        return false;
      }
      
      print('✅ UAE Pass: Received access token - $accessToken');

      // Store the UAE Pass access token securely
      await _secureStorage.write(key: 'uae_pass_access_token', value: accessToken);
      await _secureStorage.write(key: 'auth_method', value: 'uae_pass');
      
      // Authenticate with our backend API using the UAE Pass token
      print('🔄 Backend API: Authenticating with UAE Pass token');
      final bool backendAuthSuccess = await _authenticateWithBackendSimple(accessToken);
      
      if (!backendAuthSuccess) {
        print('❌ Backend API: Authentication failed');
        return false;
      }
      
      print('✅ Backend API: Authentication successful');
      
      return true;
    } catch (e) {
      print('❌ UAE Pass sign-in error: $e');
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Store UAE Pass user information securely
  Future<void> _storeUAEPassUserInfo(UAEPASSUserProfile userProfile, String accessToken) async {
    print('💾 Storing UAE Pass user info');
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
    print('✅ UAE Pass user info stored');
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
  
  // Authenticate with backend using UAE Pass token (simplified version without user profile)
  Future<bool> _authenticateWithBackendSimple(String uaePassToken) async {
    try {
      // Based on the error message, the API actually expects a JSON object with 'uaePassToken' field
      final Map<String, dynamic> requestBody = {
        'uaePassToken': uaePassToken
      };
      
      print('🔄 Backend API Request to: ${ApiConfig.uaePassLoginEndpoint}');
      print('🔄 Request Body: ${jsonEncode(requestBody)}');
      
      final response = await _dio.post(
        ApiConfig.uaePassLoginEndpoint,
        data: jsonEncode(requestBody),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => true,
        ),
      );
      
      print('📥 Backend API Response Status: ${response.statusCode}');
      print('📥 Backend API Response Body: ${response.data}');
      
      // Use the same response handling as in AuthService.login method
      if (response.data is Map<String, dynamic>) {
        if (response.data['success'] == true && response.data['data'] != null) {
          // Parse auth response to get tokens
          final authData = AuthResponse.fromJson(response.data['data']);
          
          // Save auth tokens
          await _secureStorage.write(key: 'access_token', value: authData.accessToken);
          await _secureStorage.write(key: 'refresh_token', value: authData.refreshToken);
          
          // Store authentication method
          await _secureStorage.write(key: 'auth_method', value: 'uae_pass');
          
          // Extract and store username from access token for display purposes
          try {
            final String displayName = _extractUsernameFromToken(authData.accessToken);
            await _secureStorage.write(key: 'auth_email', value: displayName);
            print('💾 Stored display name from token: $displayName');
          } catch (e) {
            print('⚠️ Failed to extract username from token: $e');
          }
          
          // Update auth state
          _authService.isLoggedIn.value = true;
          
          // We can't directly call the private _startRefreshTimer method
          // Instead, the session validity check in AuthService will handle the refresh timer
          
          return true;
        } else {
          // Server returned success: false or null data
          print('🔍 LOGIN DEBUG: Login failed with message: ${response.data['message']}');
          errorMessage.value = response.data['message'] ?? 'Authentication failed';
          return false;
        }
      } else {
        // Response is not a Map
        print('🔍 LOGIN DEBUG: Response is not a Map, type: ${response.data.runtimeType}');
        errorMessage.value = 'Invalid response format from server';
        return false;
      }
    } catch (e) {
      print('❌ UAE PASS LOGIN ERROR: $e');
      errorMessage.value = e.toString();
      return false;
    }
  }
  
  // Extract username from JWT token
  String _extractUsernameFromToken(String token) {
    try {
      // Split the token into its parts
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token format');
      }
      
      // Decode the payload (middle part)
      String payload = parts[1];
      
      // Add padding if needed
      final padding = '=' * ((4 - payload.length % 4) % 4);
      payload = payload + padding;
      
      // Base64 decode
      final decoded = base64Url.decode(payload);
      final decodedString = utf8.decode(decoded);
      
      // Parse as JSON
      final Map<String, dynamic> data = jsonDecode(decodedString);
      
      // Extract username - try different common JWT claims
      // The actual field depends on how your backend structures the token
      String? username;
      
      // Try various common JWT claim fields
      if (data.containsKey('sub')) {
        username = data['sub']; // Subject claim
      } else if (data.containsKey('username')) {
        username = data['username'];
      } else if (data.containsKey('name')) {
        username = data['name'];
      } else if (data.containsKey('email')) {
        username = data['email'];
      } else if (data.containsKey('preferred_username')) {
        username = data['preferred_username'];
      } else if (data.containsKey('unique_name')) {
        username = data['unique_name'];
      }
      
      // If no username field found, use a generic name
      return username ?? 'UAE Pass User';
    } catch (e) {
      print('⚠️ Error decoding token: $e');
      return 'UAE Pass User'; // Fallback
    }
  }
  
  // Test backend connection by calling the Alive endpoint
  Future<bool> testBackendConnection() async {
    try {
      print('🔄 Testing backend connection to: ${ApiConfig.aliveEndpoint}');
      final response = await _dio.get(
        ApiConfig.aliveEndpoint,
        options: Options(validateStatus: (status) => true),
      );
      
      print('📥 Backend Alive Status: ${response.statusCode}');
      print('📥 Backend Alive Response: ${response.data}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Backend connection test failed: $e');
      return false;
    }
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
