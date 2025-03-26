import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/constants/app_colors.dart';
import 'package:adcda_inspector/controllers/survey_controller.dart';
import 'package:adcda_inspector/widgets/question_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:adcda_inspector/utils/background_decorator.dart';
import 'package:lottie/lottie.dart';

class SurveyScreen extends StatefulWidget {
  final int surveyId;
  final int incidentId;
  final int? respondentId;
  final String? respondentEmail;
  final int languageId;

  const SurveyScreen({
    Key? key,
    required this.surveyId,
    required this.incidentId,
    this.respondentId,
    this.respondentEmail,
    this.languageId = AppConstants.defaultLanguageId,
  }) : super(key: key);

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  late final SurveyController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(SurveyController());
    _loadSurvey();
  }

  Future<void> _loadSurvey() async {
    await _controller.loadSurvey(widget.surveyId, languageId: widget.languageId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'استبيان',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'NotoKufiArabic',
          ),
        ),
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return Container(
            color: Colors.black,
            child: Center(
              child: SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }
          
        if (_controller.survey.value == null) {
          return _buildErrorState();
        }
          
        if (_controller.isCompleted.value) {
          return _buildCompletionScreen();
        }

        return _buildSurveyContent();
      }),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.white70, size: 48),
            SizedBox(height: 24),
            Text(
              'فشل تحميل الاستبيان',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'NotoKufiArabic',
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'الرجوع',
                style: TextStyle(
                  fontFamily: 'NotoKufiArabic',
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyContent() {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Progress indicator
          Container(
            width: double.infinity,
            height: 2,
            color: Colors.white12,
            child: Row(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 
                    ((_controller.currentQuestionIndex.value + 1) / _controller.totalQuestions),
                  color: Colors.white,
                ),
              ],
            ),
          ),

          // Survey name
          if (_controller.survey.value?.name != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _controller.survey.value!.name!,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'NotoKufiArabic',
                    ),
                  ),
                  SizedBox(height: 8),
                  if (_controller.survey.value?.description != null)
                    Text(
                      _controller.survey.value!.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white54,
                        fontFamily: 'NotoKufiArabic',
                        height: 1.5,
                      ),
                    ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24, width: 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'السؤال ${_controller.currentQuestionIndex.value + 1} من ${_controller.totalQuestions}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontFamily: 'NotoKufiArabic',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Survey questions
          Expanded(
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 90),
              child: FormBuilder(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: _buildQuestionCard(),
                ),
              ),
            ),
          ),

          // Bottom navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildNavigationBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    if (_controller.currentQuestion == null) {
      return Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'لا توجد أسئلة متاحة',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'NotoKufiArabic',
              color: Colors.white70,
            ),
          ),
        ),
      );
    }
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: QuestionWidget(
          question: _controller.currentQuestion!,
          controller: _controller,
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_controller.currentQuestionIndex.value > 0)
              ElevatedButton(
                onPressed: _controller.previousQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'السابق',
                  style: TextStyle(
                    fontFamily: 'NotoKufiArabic',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              SizedBox(width: 80),
            
            ElevatedButton(
              onPressed: () {
                if (_controller.currentQuestionIndex.value < _controller.totalQuestions - 1) {
                  _controller.nextQuestion();
                } else {
                  _submitSurvey();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _controller.currentQuestionIndex.value < _controller.totalQuestions - 1 ? 'التالي' : 'إنهاء',
                style: TextStyle(
                  fontFamily: 'NotoKufiArabic',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.black,
                size: 48,
              ),
            ),
            SizedBox(height: 32),
            Text(
              'تم إرسال إجاباتك بنجاح',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'NotoKufiArabic',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'شكراً لمشاركتك في الاستبيان',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white54,
                fontFamily: 'NotoKufiArabic',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'العودة إلى الرئيسية',
                style: TextStyle(
                  fontFamily: 'NotoKufiArabic',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final answers = _controller.getAnswers();

    if (answers != null) {
      final confirmSubmit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'تأكيد إرسال',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoKufiArabic',
            ),
            textAlign: TextAlign.right,
          ),
          content: Text(
            'هل أنت متأكد من أنك تريد إرسال إجاباتك؟',
            style: TextStyle(fontFamily: 'NotoKufiArabic'),
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontFamily: 'NotoKufiArabic',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'إرسال',
                style: TextStyle(fontFamily: 'NotoKufiArabic'),
              ),
            ),
          ],
        ),
      );

      if (confirmSubmit == true) {
        _controller.submitSurvey();
      }
    }
  }

  void _submitSurvey() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      _controller.submitSurvey(
        incidentId: widget.incidentId,
        respondentId: widget.respondentId,
        respondentEmail: widget.respondentEmail,
      );
    } else {
      // Show validation error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'تحقق من الإجابات',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'NotoKufiArabic',
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'يرجى التأكد من ملء جميع الحقول المطلوبة قبل الإرسال.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontFamily: 'NotoKufiArabic',
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'حسناً',
                style: TextStyle(
                  color: Color(0xFF004D90),
                  fontFamily: 'NotoKufiArabic',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
