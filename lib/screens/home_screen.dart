import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/constants/app_colors.dart';
import 'package:adcda_inspector/screens/survey_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class SurveyItem {
  final int id;
  final String title;
  final String description;
  final String date;
  final String status;
  final Color statusColor;

  SurveyItem({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.status,
    required this.statusColor,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  
  // Dummy survey data
  final List<SurveyItem> _surveys = [
    SurveyItem(
      id: 1,
      title: 'مركز الدفاع المدني - أبو ظبي العاصمة',
      description: 'فحص مستوى الجاهزية والاستجابة للطوارئ في مركز الدفاع المدني الرئيسي بأبو ظبي',
      date: '20 مارس 2025',
      status: 'جديد',
      statusColor: Colors.green,
    ),
    SurveyItem(
      id: 2,
      title: 'مركز الدفاع المدني - أبو ظبي الغربية',
      description: 'تقييم شامل لأنظمة الإنذار المبكر وبروتوكولات الإخلاء في مركز الدفاع المدني بمنطقة أبو ظبي الغربية',
      date: '22 مارس 2025',
      status: 'مجدول',
      statusColor: Colors.blue,
    ),
    SurveyItem(
      id: 3,
      title: 'مركز الدفاع المدني - مصفح أبو ظبي',
      description: 'مراجعة معدات السلامة من الحرائق وجاهزية المستجيبين الأوائل في المنطقة الصناعية بمصفح أبو ظبي',
      date: '25 مارس 2025',
      status: 'معلق',
      statusColor: Colors.orange,
    ),
    SurveyItem(
      id: 4,
      title: 'مركز الدفاع المدني - مدينة خليفة أبو ظبي',
      description: 'تقييم استعداد وتأهب فرق الإنقاذ والإسعافات الأولية في مركز الدفاع المدني بمدينة خليفة في أبو ظبي',
      date: '28 مارس 2025',
      status: 'جديد',
      statusColor: Colors.green,
    ),
    SurveyItem(
      id: 5,
      title: 'مركز الدفاع المدني - جزيرة ياس أبو ظبي',
      description: 'فحص دوري للأنظمة الأمنية وخطط الطوارئ في المنشآت السياحية والترفيهية في جزيرة ياس بأبو ظبي',
      date: '30 مارس 2025',
      status: 'مجدول',
      statusColor: Colors.blue,
    ),
  ];

  void _startSurvey(int surveyId) {
    setState(() {
      _isLoading = true;
    });

    // Show loader for 2 seconds - more elegant loader
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Center(
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Lottie.asset(
            'assets/images/loader.json',
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );

    // Simulate loading with delay
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop(); // Close dialog
      setState(() {
        _isLoading = false;
      });

      // Navigate to survey screen
      Get.to(() => SurveyScreen(
        surveyId: surveyId,
        incidentId: surveyId,
        respondentEmail: "inspector@adcda.gov.ae",
        languageId: AppConstants.defaultLanguageId,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF101010),
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Subtle pattern overlay
              Opacity(
                opacity: 0.05,
                child: Image.asset(
                  'assets/images/pattern.png',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              
              // Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        // Logo
                        Image.asset(
                          'assets/images/adcda_logo.png',
                          height: 36,
                          width: 36,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'النماذج الإلكترونية',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NotoKufiArabic',
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.refresh, color: Colors.white),
                          onPressed: () {
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Title
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'نماذج التقييم',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'NotoKufiArabic',
                      ),
                    ).animate().fadeIn(duration: 600.ms),
                  ),
                  
                  SizedBox(height: 8),
                  
                  // Subtitle
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'قائمة نماذج تقييم جاهزية مراكز الدفاع المدني',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                        fontFamily: 'NotoKufiArabic',
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Survey List
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _surveys.length,
                      itemBuilder: (context, index) {
                        final survey = _surveys[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: Colors.grey[900],
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.4),
                          child: InkWell(
                            onTap: () => _startSurvey(survey.id),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.assignment,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          survey.title,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontFamily: 'NotoKufiArabic',
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: survey.statusColor.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          survey.status,
                                          style: TextStyle(
                                            color: survey.statusColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'NotoKufiArabic',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    survey.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.7),
                                      fontFamily: 'NotoKufiArabic',
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        survey.date,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.6),
                                          fontFamily: 'NotoKufiArabic',
                                        ),
                                      ),
                                      Spacer(),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(
                          delay: Duration(milliseconds: 100 * index),
                          duration: 600.ms,
                        ).slideX(
                          begin: 0.1, 
                          end: 0, 
                          delay: Duration(milliseconds: 100 * index),
                          duration: 600.ms,
                          curve: Curves.easeOutQuint,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
