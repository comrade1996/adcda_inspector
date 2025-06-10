import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/models/auth_models.dart';
import 'package:adcda_inspector/models/user_profile.dart';
import 'package:adcda_inspector/services/api_service.dart';
import 'package:adcda_inspector/utils/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

class AuthService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Observable variables
  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool canUseBiometrics = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<UserProfile?> currentUser = Rx<UserProfile?>(null);

  
  // Credentials for auto-login with biometrics
  String? _cachedEmail;
  String? _cachedPassword;
  
  // Token refresh timer
  Timer? _refreshTimer;
  
  // Stored token data
  AuthResponse? _authData;
  
  @override
  void onInit() {
    super.onInit();
    checkBiometricAvailability();
    checkSessionValidity();
  }
  
  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }
  
  // Check if device supports biometric authentication
  Future<void> checkBiometricAvailability() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final hasHardware = await _localAuth.isDeviceSupported();
      canUseBiometrics.value = canAuthenticate && hasHardware;
      
      if (canUseBiometrics.value) {
        // Check if we have stored credentials
        final hasCredentials = await _secureStorage.containsKey(key: 'auth_email') &&
                               await _secureStorage.containsKey(key: 'auth_password');
        if (hasCredentials) {
          // Load stored credentials into memory (but not directly accessible)
          _cachedEmail = await _secureStorage.read(key: 'auth_email');
          _cachedPassword = await _secureStorage.read(key: 'auth_password');
        }
      }
    } catch (e) {
      print('Error checking biometrics: $e');
      canUseBiometrics.value = false;
    }
  }
  
  // Check if credentials are stored for biometric login
  Future<bool> hasStoredCredentials() async {
    try {
      // Check which authentication method was used
      final authMethod = await _secureStorage.read(key: 'auth_method');
      
      // For UAE Pass authentication
      if (authMethod == 'uae_pass') {
        print('Checking UAE Pass credentials for biometric login');
        // Check if we have the tokens needed for UAE Pass authentication
        final hasAccessToken = await _secureStorage.containsKey(key: 'access_token');
        final hasRefreshToken = await _secureStorage.containsKey(key: 'refresh_token');
        final hasUAEPassToken = await _secureStorage.containsKey(key: 'uae_pass_access_token');
        
        final result = hasAccessToken && hasRefreshToken && hasUAEPassToken;
        print('UAE Pass credentials available: $result');
        return result;
      }
      // For username/password authentication
      else {
        final hasCredentials = await _secureStorage.containsKey(key: 'auth_email') &&
               await _secureStorage.containsKey(key: 'auth_password') &&
               _cachedEmail != null && _cachedPassword != null;
        print('Username/password credentials available: $hasCredentials');
        return hasCredentials;
      }
    } catch (e) {
      print('Error checking stored credentials: $e');
      return false;
    }
  }
  
  // Get a value from secure storage
  Future<String?> getSecureValue(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      print('Error reading from secure storage: $e');
      return null;
    }
  }
  
  // Login with username and password
  Future<bool> login(String userName, String password, {bool rememberMe = false}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final request = LoginRequest(
        userName: userName,
        password: password,
        rememberMe: rememberMe
      );
      
      final response = await _apiService.post(
        ApiConfig.loginEndpoint,
        data: request.toJson(),
      );
      
      // Handle wrapped response structure
      if (response is Map<String, dynamic>) {
        if (response['success'] == true && response['data'] != null) {
          _authData = AuthResponse.fromJson(response['data']);
          
          // Save auth tokens
          await _secureStorage.write(key: 'access_token', value: _authData!.accessToken);
          await _secureStorage.write(key: 'refresh_token', value: _authData!.refreshToken);
          
          // If remember me is checked, store credentials for biometric login
          if (rememberMe && canUseBiometrics.value) {
            await _secureStorage.write(key: 'auth_email', value: userName);
            await _secureStorage.write(key: 'auth_password', value: password);
            _cachedEmail = userName;
            _cachedPassword = password;
          }
          
          isLoggedIn.value = true;
          
          // Start refresh token timer
          _startRefreshTimer();
          
          return true;
        } else {
          print('🔍 LOGIN DEBUG: Login failed with message: ${response['message']}');
          errorMessage.value = response['message'] ?? 'Login failed';
          return false;
        }
      } else {
        print('🔍 LOGIN DEBUG: Response is not a Map, type: ${response.runtimeType}');
        errorMessage.value = 'Invalid response format from server';
        return false;
      }
    } catch (e) {
      print('🚨 LOGIN ERROR: $e');
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Login with biometrics
  Future<bool> loginWithBiometrics() async {
    try {
      if (!canUseBiometrics.value) {
        errorMessage.value = 'Biometric authentication not available';
        return false;
      }
      
      // Check which type of authentication method was used last
      final authMethod = await _secureStorage.read(key: 'auth_method');
      
      // If using UAE Pass authentication
      if (authMethod == 'uae_pass') {
        // Check if we have a stored UAE Pass token
        final hasUAEPassToken = await _secureStorage.containsKey(key: 'uae_pass_access_token');
        if (!hasUAEPassToken) {
          errorMessage.value = 'No UAE Pass token found. Please login with UAE Pass first.';
          return false;
        }
        
        isLoading.value = true;
        errorMessage.value = '';
        
        // Authenticate with biometrics
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to access the app',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
        
        if (authenticated) {
          // Check if session is valid
          await checkSessionValidity();
          
          // Restore access tokens from secure storage and set login state
          final accessToken = await _secureStorage.read(key: 'access_token');
          final refreshToken = await _secureStorage.read(key: 'refresh_token');
          
          if (accessToken != null && refreshToken != null) {
            // Set login state
            isLoggedIn.value = true;
            
            // Start refresh token timer
            _startRefreshTimer();
            
            return true;
          } else {
            errorMessage.value = 'Missing authentication tokens. Please login with UAE Pass again.';
            return false;
          }
        } else {
          errorMessage.value = 'Biometric authentication failed';
          return false;
        }
      } 
      // If using username/password authentication
      else {
        if (_cachedEmail == null || _cachedPassword == null) {
          errorMessage.value = 'No stored credentials found. First time users need to login with username and password before using fingerprint authentication.';
          return false;
        }
        
        isLoading.value = true;
        errorMessage.value = '';
        
        // Authenticate with biometrics
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to access the app',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
        
        if (authenticated) {
          // Use stored credentials to login
          return await login(_cachedEmail!, _cachedPassword!, rememberMe: true);
        } else {
          errorMessage.value = 'Biometric authentication failed';
          return false;
        }
      }
    } catch (e) {
      if (e is PlatformException) {
        if (e.code == auth_error.notAvailable) {
          errorMessage.value = 'Biometric authentication not available';
        } else if (e.code == auth_error.notEnrolled) {
          errorMessage.value = 'No biometrics enrolled on this device';
        } else {
          errorMessage.value = 'Authentication error: ${e.message}';
        }
      } else {
        errorMessage.value = e.toString();
      }
      print('Biometric login error: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Logout user
  Future<void> logout() async {
    try {
      isLoading.value = true;
      
      // Revoke the token on server side
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken != null) {
        try {
          await _apiService.post(
            ApiConfig.revokeTokenEndpoint,
            queryParams: {'refreshToken': refreshToken},
          );
        } catch (e) {
          print('Error revoking token: $e');
          // Continue with logout even if token revocation fails
        }
      }
      
      // Clear local auth data
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      await _secureStorage.delete(key: 'user_profile');
      
      // Keep credentials for biometric login if they exist
      
      // Reset state
      isLoggedIn.value = false;
      _authData = null;
      currentUser.value = null;
      
      // Cancel refresh timer
      _refreshTimer?.cancel();
      _refreshTimer = null;
      
    } catch (e) {
      print('Logout error: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Get the access token for API requests
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }
  
  // Refresh the access token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) {
        return false;
      }
      
      final request = RefreshTokenDTO(refreshToken: refreshToken);
      
      final response = await _apiService.post(
        ApiConfig.refreshTokenEndpoint,
        data: request.toJson(),
      );
      
      // Handle wrapped response structure
      if (response is Map<String, dynamic>) {
        if (response['success'] == true && response['data'] != null) {
          _authData = AuthResponse.fromJson(response['data']);
          
          // Update stored tokens
          await _secureStorage.write(key: 'access_token', value: _authData!.accessToken);
          await _secureStorage.write(key: 'refresh_token', value: _authData!.refreshToken);
          
          return true;
        } else {
          // If refresh fails, logout user
          await logout();
          return false;
        }
      } else {
        // Invalid response format
        await logout();
        return false;
      }
    } catch (e) {
      print('Token refresh error: $e');
      await logout();
      return false;
    }
  }
  
  // Start token refresh timer
  void _startRefreshTimer() {
    // Cancel any existing timer
    _refreshTimer?.cancel();
    
    // Set timer to refresh token every 45 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 45), (timer) async {
      print('Refreshing access token');
      await refreshToken();
    });
  }
  
  // Link biometrics with current credentials
  Future<bool> linkBiometrics(String userName, String password) async {
    try {
      if (!canUseBiometrics.value) {
        errorMessage.value = 'Biometric authentication not available';
        return false;
      }
      
      // Authenticate with biometrics
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to link your credentials',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      if (authenticated) {
        // Store credentials securely
        await _secureStorage.write(key: 'auth_email', value: userName);
        await _secureStorage.write(key: 'auth_password', value: password);
        _cachedEmail = userName;
        _cachedPassword = password;
        return true;
      } else {
        errorMessage.value = 'Biometric authentication failed';
        return false;
      }
    } catch (e) {
      print('Error linking biometrics: $e');
      errorMessage.value = e.toString();
      return false;
    }
  }
  
  // Check if biometrics are linked (credentials are stored)
  Future<bool> isBiometricsLinked() async {
    return await _secureStorage.containsKey(key: 'auth_email') &&
           await _secureStorage.containsKey(key: 'auth_password');
  }
  
  // Remove linked biometrics
  Future<void> removeLinkedBiometrics() async {
    await _secureStorage.delete(key: 'auth_email');
    await _secureStorage.delete(key: 'auth_password');
    _cachedEmail = null;
    _cachedPassword = null;
  }
  
  // Check if the session is valid or if app needs re-authentication
  Future<void> checkSessionValidity() async {
    try {
      final accessToken = await _secureStorage.read(key: 'access_token');
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      
      if (accessToken != null && refreshToken != null) {
        // Session is valid
        isLoggedIn.value = true;
        
        // Start refresh token timer
        _startRefreshTimer();
        
        // Load user profile
        await loadUserProfile();
      } else {
        // No valid session
        isLoggedIn.value = false;
      }
    } catch (e) {
      print('Error checking session validity: $e');
      isLoggedIn.value = false;
    }
  }
  
  // Save user profile to secure storage
  Future<void> saveUserProfile(UserProfile userProfile) async {
    try {
      final userJson = jsonEncode(userProfile.toJson());
      await _secureStorage.write(key: 'user_profile', value: userJson);
      currentUser.value = userProfile;
    } catch (e) {
      print('Error saving user profile: $e');
    }
  }
  
  // Load user profile from secure storage
  Future<void> loadUserProfile() async {
    try {
      // For now, extract profile from token, later will call API
      final accessToken = await getAccessToken();
      if (accessToken != null) {
        // Extract profile info from token
        final userProfile = await _extractProfileFromToken(accessToken);
        if (userProfile != null) {
          currentUser.value = userProfile;
          await saveUserProfile(userProfile);
          return;
        }
      }
      
      // If we couldn't extract from token, try from secure storage
      final userJson = await _secureStorage.read(key: 'user_profile');
      if (userJson != null) {
        final Map<String, dynamic> userData = jsonDecode(userJson);
        currentUser.value = UserProfile.fromJson(userData);
      }
    } catch (e) {
      print('Error loading user profile: $e');
      currentUser.value = null;
    }
  }
  
  // Extract user profile from JWT token
  Future<UserProfile?> _extractProfileFromToken(String token) async {
    try {
      // Split the token and decode the payload
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
      print('Token payload data: ${data.keys}');
      
      // Extract username from unique_name and email as specified
      final userName = data['unique_name'];
      final email = data['email'];
      
      if (userName == null && email == null) {
        print('No user info found in token');
        return null;
      }
      
      // Store the unique_name claim specifically
      final String uniqueNameValue = data['unique_name'] ?? '';
      
      // Create profile from token data
      return UserProfile(
        id: data['sub'] ?? '',
        userName: userName ?? email ?? 'User',
        name: userName ?? email ?? 'User',
        email: email,
        uniqueName: uniqueNameValue,
        isUaePassUser: false
      );
    } catch (e) {
      print('Error extracting profile from token: $e');
      return null;
    }
  }
  
  // For future use - fetch user profile from API
  Future<void> fetchUserProfileFromApi() async {
    // This will be implemented in the future
    // Currently using token extraction instead
    print('API profile fetching will be implemented in the future');
  }
  
  // Get user profile
  UserProfile? getUserProfile() {
    return currentUser.value;
  }
  
  // Expose the secure storage for use in other classes
  FlutterSecureStorage getSecureStorage() {
    return _secureStorage;
  }
}
