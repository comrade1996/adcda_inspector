import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/screens/survey_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _startSurvey() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call with a delay
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _isLoading = false;
        });
        
        // Navigate to survey screen
        Get.to(() => SurveyScreen(
          surveyId: 1,
          incidentId: 1,
          respondentEmail: _emailController.text,
          languageId: AppConstants.defaultLanguageId,
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نموذج تقييم جاهزية مراكز الدفاع المدني'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Survey logo or image
                  Icon(
                    Icons.assessment_outlined,
                    size: 72,
                    color: Theme.of(context).primaryColor,
                  )
                      .animate()
                      .fadeIn(
                        duration: const Duration(milliseconds: 500),
                      )
                      .then()
                      .scale(
                        duration: const Duration(milliseconds: 300),
                      ),
                  const SizedBox(height: 24),
                  
                  // Survey title and description with patterned background
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      image: const DecorationImage(
                        image: AssetImage('assets/images/pattern.png'),
                        fit: BoxFit.cover,
                        opacity: 0.05, // Subtle pattern
                      ),
                    ),
                    child: Column(
                      children: [
                        // Survey title
                        Text(
                          'نموذج تقييم جاهزية مراكز الدفاع المدني',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(
                          delay: const Duration(milliseconds: 300),
                          duration: const Duration(milliseconds: 500),
                        ),
                        const SizedBox(height: 16),
                        
                        // Survey description
                        Text(
                          'يرجى إكمال هذا الاستبيان لتقييم مستوى جاهزية مراكز الدفاع المدني والاستجابة للطوارئ.',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(
                          delay: const Duration(milliseconds: 500),
                          duration: const Duration(milliseconds: 500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Email form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            hintText: 'أدخل بريدك الإلكتروني',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'يرجى إدخال البريد الإلكتروني';
                            }
                            if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                .hasMatch(value)) {
                              return 'يرجى إدخال بريد إلكتروني صحيح';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _startSurvey,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                )
                              : Text(
                                  'ابدأ الاستبيان',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                      ),
                                ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(
                    delay: const Duration(milliseconds: 700),
                    duration: const Duration(milliseconds: 500),
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
