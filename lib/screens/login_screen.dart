import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../screens/home_screen.dart';
import '../services/auth_service.dart';
import '../services/uae_pass_service.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/user_profile.dart';

import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;

  late AuthService _authService;
  late UAEPassService _uaePassService;

  String? _storedUsername;
  RxInt _currentLanguageId = 1.obs;

  @override
  void initState() {
    super.initState();
    _authService = Get.put(AuthService());
    _uaePassService = Get.put(UAEPassService());

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Check for biometrics on startup and load user info
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _authService.checkBiometricAvailability();
      await _loadUserInfo();
      await _loadCurrentLanguage();

      // Automatically trigger fingerprint authentication if credentials are available
      if (_authService.canUseBiometrics.value) {
        if (await _authService.hasStoredCredentials()) {
          _handleBiometricLogin();
        } else {
          // First time users won't have stored credentials
          // We don't show error here as it would be confusing for first time users
          print('No stored credentials for automatic biometric login');
        }
      }
    });
  }

  Future<void> _loadUserInfo() async {
    if (_authService.canUseBiometrics.value) {
      if (await _authService.hasStoredCredentials()) {
        // Retrieve stored username for the welcome message
        final secureStorage = Get.find<AuthService>();
        // Get username from the auth service's secured storage
        _storedUsername = await _authService.getSecureValue('auth_email');
      }
    }
  }

  Future<void> _loadCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguageId.value =
        prefs.getInt('languageId') ?? 1; // Default to Arabic (1)
  }

  String _getWelcomeMessage(AppLocalizations localizations) {
    // Return welcome message based on the current language
    switch (_currentLanguageId.value) {
      case 2: // English
        return 'Welcome back';
      case 3: // Urdu
        return 'واپس خوش آمدید';
      case 1: // Arabic
      default:
        return 'مرحبا بعودتك';
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text,
      rememberMe: true, // Always true as per requirements
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Navigate to home screen on successful login
      Get.off(() => HomeScreen());
    } else {
      // Show error message
      Get.snackbar(
        AppLocalizations.of(context).translate('loginFailed'),
        _authService.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: EdgeInsets.all(8),
      );
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() {
      _isLoading = true;
    });

    final success = await _authService.loginWithBiometrics();

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Save user profile data after successful login
      await _saveUserProfileData();
      // Navigate to home screen on successful login
      Get.off(() => HomeScreen());
    } else {
      // Show error message
      Get.snackbar(
        AppLocalizations.of(context).translate('biometricLoginFailed'),
        _authService.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: EdgeInsets.all(8),
      );
    }
  }

  // Handle UAE Pass login
  Future<void> _handleUAEPassLogin() async {
    setState(() {
      _isLoading = true;
    });

    final success = await _uaePassService.signInWithUAEPass(context);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      // Save user profile data after successful UAE Pass login
      await _saveUAEPassUserProfileData();
      
      // Get the UAE Pass unique_name directly from secure storage
      final uaePassUniqueName = await _authService.getSecureStorage().read(key: 'uae_pass_unique_name');
      print('UAE Pass unique_name before navigation: $uaePassUniqueName');
      
      // Get the current user profile and update it if necessary
      final userProfile = _authService.getUserProfile();
      if (userProfile != null && uaePassUniqueName != null && uaePassUniqueName.isNotEmpty) {
        if (userProfile.uniqueName != uaePassUniqueName) {
          // Create updated profile with the unique_name
          final updatedProfile = UserProfile(
            id: userProfile.id,
            userName: userProfile.userName,
            name: userProfile.name,
            email: userProfile.email,
            phone: userProfile.phone,
            roles: userProfile.roles,
            isUaePassUser: true,
            uniqueName: uaePassUniqueName,
          );
          
          // Save the updated profile
          await _authService.saveUserProfile(updatedProfile);
          print('Updated user profile with unique_name before navigation');
        }
      }
      
      // Force a complete rebuild by using offAll instead of off
      Get.offAll(() => HomeScreen());
    } else {
      // Show error message
      Get.snackbar(
        AppLocalizations.of(context).translate('loginFailed') ?? 'Login Failed',
        _uaePassService.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: EdgeInsets.all(8),
      );
    }
  }

  // Save user profile data from regular login
  Future<void> _saveUserProfileData() async {
    try {
      // Get JWT token data
      final accessToken = await _authService.getAccessToken();
      if (accessToken == null) return;
      
      // Create user profile
      final userProfile = await _extractUserProfileFromToken(accessToken);
      
      // Save to AuthService
      await _authService.saveUserProfile(userProfile);
    } catch (e) {
      print('Error saving user profile data: $e');
    }
  }

  // Save user profile data from UAE Pass login
  Future<void> _saveUAEPassUserProfileData() async {
    try {
      // Get UAE Pass user info
      final uaePassUserInfo = await _uaePassService.getUAEPassUserInfo();
      
      // Get JWT token data for additional info
      final accessToken = await _authService.getAccessToken();
      if (accessToken == null) return;
      
      // Create user profile from UAE Pass data
      final userProfile = await _createUserProfileFromUAEPass(uaePassUserInfo, accessToken);
      
      // Save to AuthService
      await _authService.saveUserProfile(userProfile);
    } catch (e) {
      print('Error saving UAE Pass user profile data: $e');
    }
  }

  // Extract user profile data from JWT token
  Future<UserProfile> _extractUserProfileFromToken(String token) async {
    try {
      // Split the token and decode the payload
      final parts = token.split('.');
      if (parts.length != 3) throw Exception('Invalid token format');
      
      String payload = parts[1];
      final padding = '=' * ((4 - payload.length % 4) % 4);
      payload = payload + padding;
      
      final decoded = base64Url.decode(payload);
      final decodedString = utf8.decode(decoded);
      final Map<String, dynamic> data = jsonDecode(decodedString);
      
      // Create a UserProfile from the token data
      return UserProfile(
        id: data['sub'] ?? data['id'] ?? '',
        userName: data['username'] ?? data['email'] ?? _emailController.text.trim(),
        name: data['name'] ?? data['username'] ?? _emailController.text.trim(),
        email: data['email'] ?? _emailController.text.trim(),
        isUaePassUser: false
      );
    } catch (e) {
      print('Error extracting user profile from token: $e');
      // Fallback to basic profile with username
      return UserProfile(
        userName: _emailController.text.trim(),
        name: _emailController.text.trim(),
        isUaePassUser: false
      );
    }
  }

  // Create user profile from UAE Pass data
  Future<UserProfile> _createUserProfileFromUAEPass(Map<String, String?> uaePassData, String token) async {
    try {
      // Get the unique_name directly from secure storage, as it should have been saved during the UAE Pass login flow
      final uniqueName = await _authService.getSecureStorage().read(key: 'uae_pass_unique_name') ?? '';
      print('Using unique_name in profile creation: $uniqueName');
      
      return UserProfile(
        id: uaePassData['idn'] ?? '',
        userName: uaePassData['email'] ?? 'UAE Pass User',
        name: uaePassData['name_en'] ?? uaePassData['name_ar'] ?? 'UAE Pass User',
        email: uaePassData['email'] ?? '',
        phone: uaePassData['mobile'] ?? '',
        uniqueName: uniqueName, // Use the unique_name from UAE Pass token
        isUaePassUser: true
      );
    } catch (e) {
      print('Error creating user profile from UAE Pass data: $e');
      // Fallback to basic profile
      return UserProfile(
        userName: 'UAE Pass User',
        name: 'UAE Pass User',
        isUaePassUser: true
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Logo
                    Container(
                      alignment: Alignment.center,
                      margin: EdgeInsets.only(bottom: 20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),

                    // App Name
                    Text(
                      localizations.translate('appTitle'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 400.ms),

                    SizedBox(height: 16),

                    // Welcome message when biometrics are available and username is stored
                    Obx(
                      () =>
                          _authService.canUseBiometrics.value &&
                                  _storedUsername != null
                              ? Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 20,
                                ),
                                margin: EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                          _getWelcomeMessage(localizations),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        )
                                        .animate()
                                        .fadeIn(duration: 400.ms)
                                        .slideY(begin: -0.2, end: 0),
                                    SizedBox(height: 4),
                                    Text(
                                      _storedUsername!,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ).animate().fadeIn(
                                      duration: 500.ms,
                                      delay: 200.ms,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      localizations.translate(
                                        'useBiometricsToLogin',
                                      ),
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ).animate().fadeIn(
                                      duration: 400.ms,
                                      delay: 300.ms,
                                    ),
                                  ],
                                ),
                              )
                              : SizedBox.shrink(),
                    ),

                    SizedBox(height: 30),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: localizations.translate('usernameOrEmail'),
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Colors.white70,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.redAccent),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.redAccent),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('requiredField');
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: localizations.translate('password'),
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Colors.white70,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.redAccent),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.redAccent),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.translate('requiredField');
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 24),

                    // Login button
                    OutlinedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white, width: 1.5),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isLoading
                              ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                localizations.translate('login'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),

                    SizedBox(height: 20),

                    // Or divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white38)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            localizations.translate('or') ?? 'OR',
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white38)),
                      ],
                    ),

                    SizedBox(height: 20),

                    // UAE Pass login using language-specific buttons, sized to match the regular login button
                    Obx(
                      () => OutlinedButton(
                        onPressed: _isLoading ? null : _handleUAEPassLogin,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: 14,
                          ), // Match the regular login button padding
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide.none, // No border for image button
                        ),
                        child:
                            _isLoading
                                ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Image.asset(
                                  // Use English button for English language (2), Arabic button for others
                                  _currentLanguageId.value == 2
                                      ? 'assets/images/UAEPASS_Login_Btn_Outline_Active-English.png'
                                      : 'assets/images/AR_UAEPASS_Sign_in_Btn_Active-Arabic.png',
                                  width: double.infinity,
                                  height:
                                      78, // Slightly smaller than container to avoid stretching
                                  fit:
                                      BoxFit
                                          .contain, // Use contain to maintain aspect ratio
                                  errorBuilder:
                                      (context, error, stackTrace) => Icon(
                                        Icons.login,
                                        size: 30,
                                        color: Colors.white,
                                      ),
                                ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Authentication options
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Fingerprint login button (icon only) - only show if biometrics available AND credentials stored
                        FutureBuilder<bool>(
                          future: _authService.hasStoredCredentials(),
                          builder: (context, snapshot) {
                            final hasCredentials = snapshot.data ?? false;
                            // Use GetX value but wrap it properly in an Obx for just the value access
                            return Obx(() {
                              return (_authService.canUseBiometrics.value &&
                                      hasCredentials)
                                  ? Container(
                                    height: 56,
                                    width: 56,
                                    margin: EdgeInsets.symmetric(horizontal: 4),
                                    child: ElevatedButton(
                                      onPressed:
                                          _isLoading
                                              ? null
                                              : _handleBiometricLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        side: BorderSide(color: Colors.white70),
                                        shape: CircleBorder(),
                                        padding: EdgeInsets.zero,
                                        elevation: 0,
                                      ),
                                      child: Icon(Icons.fingerprint, size: 30),
                                    ),
                                  )
                                  : SizedBox.shrink();
                            });
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
