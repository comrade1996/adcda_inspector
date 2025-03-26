import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _handleUAEPassLogin() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate login delay
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    // Navigate to home screen on successful login
    Get.off(() => HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                    'ADCDA Inspector',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 400.ms),

                  SizedBox(height: 12),

                  SizedBox(height: 80),

                  // UAE Pass button
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _handleUAEPassLogin,
                        borderRadius: BorderRadius.circular(8),
                        child:
                            _isLoading
                                ? Center(
                                  child: SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                                : Image.asset(
                                  'assets/images/AR_UAEPASS_Sign_in_Btn_Active.png',
                                  fit: BoxFit.contain,
                                ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  Center(
                    child: Text(
                      'تسجيل الدخول باستخدام الهوية الرقمية الإماراتية',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontFamily: 'NotoKufiArabic',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: 60),

                  // Help text
                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.help_outline,
                            color: Colors.white70,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'تحتاج مساعدة؟',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontFamily: 'NotoKufiArabic',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
