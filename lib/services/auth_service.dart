import 'dart:async';
import 'dart:convert';
import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/models/auth_models.dart';
import 'package:adcda_inspector/services/api_service.dart';
import 'package:adcda_inspector/utils/api_config.dart';
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
      return await _secureStorage.containsKey(key: 'auth_email') &&
             await _secureStorage.containsKey(key: 'auth_password') &&
             _cachedEmail != null && _cachedPassword != null;
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
      
      // Keep credentials for biometric login if they exist
      
      // Reset state
      isLoggedIn.value = false;
      _authData = null;
      
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
      // Get the last app session ID from secure storage
      final lastSessionId = await _secureStorage.read(key: 'last_session_id');
      
      // Generate a new session ID for the current app launch
      final currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // If the session IDs don't match or no previous session exists,
      // the app was terminated and restarted - clear auth state
      if (lastSessionId == null) {
        // First time app launch, just save the session ID
        await _secureStorage.write(key: 'last_session_id', value: currentSessionId);
      } else {
        // App was terminated and restarted - require login again
        // Only clear the isLoggedIn state, but keep credentials for biometric login
        isLoggedIn.value = false;
        _authData = null;
        
        // Update the session ID for this launch
        await _secureStorage.write(key: 'last_session_id', value: currentSessionId);
      }
    } catch (e) {
      print('Error checking session validity: $e');
      // In case of error, force re-login for security
      isLoggedIn.value = false;
      _authData = null;
    }
  }
  

}
