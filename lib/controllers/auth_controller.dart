import 'package:adcda_inspector/services/auth_service.dart';
import 'package:adcda_inspector/screens/login_screen.dart';
import 'package:adcda_inspector/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Global authentication controller to handle app-wide authentication state
class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  
  // Observable user state
  final RxBool isAuthenticated = false.obs;
  final RxBool isInitialized = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    // Listen to changes in the AuthService's login state
    ever(_authService.isLoggedIn, _handleAuthStateChange);
  }
  
  /// Respond to auth state changes from the service
  void _handleAuthStateChange(bool loggedIn) {
    isAuthenticated.value = loggedIn;
    if (!loggedIn && isInitialized.value) {
      // If we're already initialized and logged out, redirect to login
      Get.offAll(() => LoginScreen());
    }
  }
  
  /// Initialize authentication state on app startup - called from main.dart
  Future<void> initAuth() async {
    try {
      final token = await _authService.getAccessToken();
      if (token != null) {
        // Try to refresh the token on app start to ensure it's valid
        final refreshSuccess = await _authService.refreshToken();
        isAuthenticated.value = refreshSuccess && _authService.isLoggedIn.value;
      } else {
        isAuthenticated.value = false;
      }
    } catch (e) {
      print('Auth initialization error: $e');
      isAuthenticated.value = false;
    } finally {
      isInitialized.value = true;
    }
  }
  
  /// Handle login with username and password
  Future<bool> login(String username, String password, {bool rememberMe = false}) async {
    final result = await _authService.login(username, password, rememberMe: rememberMe);
    isAuthenticated.value = result;
    return result;
  }
  
  /// Handle login with biometrics
  Future<bool> loginWithBiometrics() async {
    final result = await _authService.loginWithBiometrics();
    isAuthenticated.value = result;
    return result;
  }
  
  /// Handle logout
  Future<void> logout() async {
    await _authService.logout();
    isAuthenticated.value = false;
    Get.offAll(() => LoginScreen());
  }
  
  /// Check if biometrics are available on the device
  bool get canUseBiometrics => _authService.canUseBiometrics.value;
  
  /// Check if biometrics are linked to stored credentials
  Future<bool> get isBiometricsLinked => _authService.isBiometricsLinked();
  
  /// Link biometrics with user credentials
  Future<bool> linkBiometrics(String userName, String password) async {
    return await _authService.linkBiometrics(userName, password);
  }
  
  /// Remove biometric link
  Future<void> removeBiometricLink() async {
    await _authService.removeLinkedBiometrics();
  }
  
  /// Middleware for checking authentication
  Route? onGenerateRoute(RouteSettings settings) {
    if (!isAuthenticated.value) {
      return GetPageRoute(
        settings: settings,
        page: () => LoginScreen(),
      );
    }
    return null; // Let normal routing continue
  }
}
