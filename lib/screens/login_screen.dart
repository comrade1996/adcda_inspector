import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../screens/home_screen.dart';
import '../services/auth_service.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../services/deep_link_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
  late DeepLinkService _deepLinkService;

  @override
  void initState() {
    super.initState();
    _authService = Get.put(AuthService());
    _deepLinkService = Get.put(DeepLinkService());
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    
    // Check for biometrics on startup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _authService.checkBiometricAvailability();
      _initDeepLinks();
      
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
  
  Future<void> _initDeepLinks() async {
    // Register callback for UAE PASS authorization code
    _deepLinkService.registerUaePassCallback(_handleUaePassCallback);
    
    // Initialize deep links
    await _deepLinkService.initDeepLinks();
  }
  
  void _handleUaePassCallback(String code) {
    print('Received UAE PASS code: $code');
    _completeUaePassLogin(code);
  }
  
  Future<void> _completeUaePassLogin(String code) async {
    setState(() {
      _isLoading = true;
    });
    
    final success = await _authService.completeUaePassLogin(code);
    
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
  
  Future<void> _handleUaePassLogin() async {
    final success = await _authService.initiateUaePassLogin();
    
    if (success) {
      // Typically, you would launch the UAE PASS login URL here
      // For demonstration, we're showing how to do this with url_launcher
      final uaePassAuthUrl = "https://stg-id.uaepass.ae/idshub/authorize"
          "?redirect_uri=${Uri.encodeComponent('adcdainspector://uaepass/callback')}"
          "&client_id=YOUR_CLIENT_ID"
          "&response_type=code"
          "&scope=urn:uae:digitalid:profile:general"
          "&state=${DateTime.now().millisecondsSinceEpoch}"
          "&acr_values=urn:safelayer:tws:policies:authentication:level:low";
          
      try {
        if (!await launchUrl(Uri.parse(uaePassAuthUrl), mode: LaunchMode.externalApplication)) {
          Get.snackbar(
            AppLocalizations.of(context).translate('error'),
            'Could not launch UAE PASS login page',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            margin: EdgeInsets.all(8),
          );
        }
      } catch (e) {
        print('Error launching UAE PASS URL: $e');
        Get.snackbar(
          AppLocalizations.of(context).translate('error'),
          'Error launching UAE PASS: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          margin: EdgeInsets.all(8),
        );
      }
    } else {
      // Show error message
      Get.snackbar(
        AppLocalizations.of(context).translate('error'),
        _authService.errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: EdgeInsets.all(8),
      );
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
                      margin: EdgeInsets.only(bottom: 40),
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

                    SizedBox(height: 30),
                    
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: localizations.translate('usernameOrEmail'),
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.email_outlined, color: Colors.white70),
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
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
                      child: _isLoading
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
                    
                    // UAE PASS login button (disabled)
                    Opacity(
                      opacity: 0.5,
                      child: AbsorbPointer(
                        absorbing: true, // This makes it unclickable
                        child: Image.asset(
                          'assets/images/AR_UAEPASS_Sign_in_Btn_Active.png',
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Fingerprint login button (icon only)
                    Obx(() => _authService.canUseBiometrics.value
                        ? Container(
                            height: 56,
                            width: 56,
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleBiometricLogin,
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
                        : SizedBox.shrink()),
                    
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
