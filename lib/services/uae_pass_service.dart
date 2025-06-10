import 'dart:async';
import 'dart:convert';
import 'package:adcda_inspector/services/auth_service.dart';
import 'package:adcda_inspector/utils/api_config.dart';
import 'package:adcda_inspector/models/user_profile.dart';
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

      // Immediately decode the UAE Pass token and extract user information
      print('🔍 Decoding UAE Pass token directly');
      try {
        // Extract user data from the UAE Pass token
        Map<String, dynamic>? uaePassTokenData = _decodeUAEPassToken(accessToken);
        if (uaePassTokenData != null) {
          // Store the raw token data for debugging
          await _secureStorage.write(key: 'uae_pass_raw_token_data', value: jsonEncode(uaePassTokenData));
          
          // Extract and store the unique_name specifically
          final String uniqueName = uaePassTokenData['unique_name'] ?? '';
          await _secureStorage.write(key: 'uae_pass_unique_name', value: uniqueName);
          print('Extracted unique_name from UAE Pass token: $uniqueName');
        }
      } catch (e) {
        print('Error decoding UAE Pass token: $e');
        // Continue with the authentication flow despite token decode errors
      }
      
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
      
      // After successful authentication, make sure the profile contains the unique_name
      try {
        final uniqueName = await _secureStorage.read(key: 'uae_pass_unique_name');
        if (uniqueName != null && uniqueName.isNotEmpty) {
          // Get the current user profile and update it with the unique_name
          final userProfile = _authService.getUserProfile();
          if (userProfile != null) {
            // Create a new profile with the unique_name and update it
            final updatedProfile = UserProfile(
              id: userProfile.id,
              userName: userProfile.userName,
              name: userProfile.name,
              email: userProfile.email,
              phone: userProfile.phone,
              roles: userProfile.roles,
              isUaePassUser: true,
              uniqueName: uniqueName,
            );
            
            // Update the user profile in the auth service
            await _authService.saveUserProfile(updatedProfile);
            print('Updated user profile with unique_name: $uniqueName');
          }
        }
      } catch (e) {
        print('Error updating profile with unique_name: $e');
        // Continue despite errors here
      }
      
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
      
      // Decode and analyze the response body immediately
      print('\n🔍 DECODING BACKEND RESPONSE:\n');
      if (response.data is Map<String, dynamic>) {
        if (response.data['data'] != null) {
          // Decode the access token if available
          try {
            final responseData = response.data['data'];
            if (responseData['accessToken'] != null) {
              final accessToken = responseData['accessToken'];
              print('📝 Found accessToken in response');
              
              // Decode the token
              final decodedToken = _decodeUAEPassToken(accessToken);
              print('🔑 Decoded accessToken payload: ${jsonEncode(decodedToken)}');
              
              // Extract and display key claims
              if (decodedToken != null) {
                final uniqueName = decodedToken['unique_name'];
                final sub = decodedToken['sub'];
                final email = decodedToken['email'];
                final name = decodedToken['name'];
                
                print('👤 unique_name: $uniqueName');
                print('🆔 sub: $sub');
                print('📧 email: $email');
                print('📝 name: $name');
                
                // Store unique_name immediately if found
                if (uniqueName != null) {
                  await _secureStorage.write(key: 'uae_pass_unique_name', value: uniqueName.toString());
                  print('💾 Stored unique_name: $uniqueName');
                }
              }
            }
          } catch (e) {
            print('⚠️ Error decoding token from response: $e');
          }
        }
      }
      print('\n🔄 Continuing with response processing...\n');
      
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
          
          // Extract and save user profile data from token
          try {
            await _extractAndSaveProfileFromToken(authData.accessToken);
          } catch (e) {
            print('⚠️ Failed to extract user profile from token: $e');
            
            // Fallback to just extracting the username
            try {
              final String displayName = _extractUsernameFromToken(authData.accessToken);
              await _secureStorage.write(key: 'auth_email', value: displayName);
              print('💾 Stored display name from token: $displayName');
            } catch (e) {
              print('⚠️ Failed to extract username from token: $e');
            }
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
  
  // Extract user profile data from JWT token
  Future<void> _extractAndSaveProfileFromToken(String token) async {
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
      print('UAE Pass token payload data: ${data.keys}');
      
      // Log full token data for debugging
      print('Full token data: $data');

      // Extract user information from token - try multiple possible fields
      // First check if there's a nested "accessToken" in the response
      Map<String, dynamic> tokenData = data;
      if (data.containsKey('accessToken')) {
        print('Found nested accessToken field in the token');
        // Try to parse the nested access token
        try {
          final nestedToken = data['accessToken'] as String;
          final nestedParts = nestedToken.split('.');
          if (nestedParts.length == 3) {
            String nestedPayload = nestedParts[1];
            final nestedPadding = '=' * ((4 - nestedPayload.length % 4) % 4);
            nestedPayload = nestedPayload + nestedPadding;
            final nestedDecoded = base64Url.decode(nestedPayload);
            final nestedDecodedString = utf8.decode(nestedDecoded);
            final Map<String, dynamic> nestedData = jsonDecode(nestedDecodedString);
            print('Nested token data: $nestedData');
            tokenData = nestedData; // Use the nested token data instead
          }
        } catch (e) {
          print('Error parsing nested token: $e');
          // Continue with the original token data
        }
      }
      
      // Try to extract data from multiple possible field names
      final String userId = tokenData['sub'] ?? 
                           tokenData['id'] ?? 
                           tokenData['userId'] ?? 
                           '';
      
      final String userName = tokenData['unique_name'] ?? 
                             tokenData['name'] ?? 
                             tokenData['displayName'] ?? 
                             tokenData['preferred_username'] ?? 
                             tokenData['username'] ?? 
                             '';
      
      final String email = tokenData['email'] ?? 
                          tokenData['mail'] ?? 
                          '';

      final String fullName = tokenData['name'] ?? 
                            tokenData['fullName'] ?? 
                            tokenData['full_name'] ?? 
                            userName ?? 
                            email ?? 
                            'UAE Pass User';
      
      // Extract the unique_name specifically
      final String uniqueName = tokenData['unique_name'] ?? '';
      
      // Create user profile from token data
      final userProfile = UserProfile(
        id: userId,
        userName: userName.isNotEmpty ? userName : (email.isNotEmpty ? email : 'UAE Pass User'),
        name: fullName,
        email: email,
        uniqueName: uniqueName,
        isUaePassUser: true
      );
      
      // Save user profile using auth service
      await _authService.saveUserProfile(userProfile);
      print('✅ UAE Pass user profile saved from token');
      
      // Store all extracted data for debugging and future use
      await _secureStorage.write(key: 'uae_pass_token_data', value: jsonEncode(data));
      
    } catch (e) {
      print('⚠️ Error extracting profile from token: $e');
    }
  }
  
  // Extract username from JWT token (legacy method)
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
      
      // We now specifically look for unique_name as mentioned by the user
      if (data.containsKey('unique_name')) {
        return data['unique_name'];
      } else if (data.containsKey('email')) {
        return data['email'];
      }
      
      // Fallback to other fields
      return data['sub'] ?? 
             data['username'] ?? 
             data['name'] ?? 
             data['preferred_username'] ?? 
             'UAE Pass User';
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
      await _secureStorage.delete(key: 'uae_pass_unique_name');
      await _secureStorage.delete(key: 'uae_pass_raw_token_data');
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

  // Helper method to decode UAE Pass token
  Map<String, dynamic>? _decodeUAEPassToken(String token) {
    try {
      // Split the token into its parts
      final parts = token.split('.');
      if (parts.length != 3) {
        print('Invalid token format');
        return null;
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
      print('UAE Pass token payload data: ${data.keys}');
      
      return data;
    } catch (e) {
      print('Error decoding UAE Pass token: $e');
      return null;
    }
  }
}
