import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/constants/app_colors.dart';
import 'package:adcda_inspector/controllers/survey_controller.dart';
import 'package:adcda_inspector/utils/app_theme.dart';
import 'package:adcda_inspector/models/survey.dart' as app_models;
import 'dart:convert';
import 'package:adcda_inspector/models/question_type.dart';
import 'package:adcda_inspector/widgets/question_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';
import 'package:adcda_inspector/utils/background_decorator.dart';
import 'package:lottie/lottie.dart';
import 'package:adcda_inspector/utils/formatter_helper.dart';
import 'package:adcda_inspector/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SurveyScreen extends StatefulWidget {
  final int surveyId;
  final int languageId;

  const SurveyScreen({
    Key? key,
    required this.surveyId,
    required this.languageId,
  }) : super(key: key);

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final SurveyController _controller = Get.find<SurveyController>();
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSubmitting = false;
  bool _isCompleted = false;
  int _currentLanguageId = 1;

  @override
  void initState() {
    super.initState();
    _currentLanguageId = widget.languageId;
    _loadSurvey();
  }

  Future<void> _loadSurvey() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      print(
        'Loading survey ID: ${widget.surveyId} with language ID: $_currentLanguageId',
      );
      await _controller.loadSurvey(widget.surveyId, _currentLanguageId);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      print('Error loading survey: $e');
    }
  }

  Future<void> _changeLanguage(int languageId) async {
    print(
      'SurveyScreen: Changing language to ID: $languageId from $_currentLanguageId',
    );

    // Only proceed if the language is actually changing
    if (languageId == _currentLanguageId) {
      print('Language ID is the same, no change needed');
      return;
    }

    // Update UI immediately
    setState(() {
      _currentLanguageId = languageId;
      _isLoading = true; // Show loading indicator right away
    });

    // Save the selected language as default
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('languageId', languageId);
    print('Saved language ID $languageId to preferences');

    // Set the appropriate locale
    Locale newLocale;
    switch (languageId) {
      case 2:
        newLocale = const Locale('en');
        break;
      case 3:
        // Don't use country code for Urdu to avoid locale-related issues
        newLocale = const Locale('ur');
        break;
      case 1:
      default:
        newLocale = const Locale('ar');
        break;
    }

    print('Updating app locale to $newLocale');
    // Update app locale
    Get.updateLocale(newLocale);

    // Reset form and answers before loading new survey
    _formKey.currentState?.reset();
    _controller.resetSurveyState();

    // Add a small delay to ensure locale changes take effect
    await Future.delayed(Duration(milliseconds: 500));

    try {
      print(
        'Loading survey ID: ${widget.surveyId} with language ID: $_currentLanguageId',
      );
      await _controller.loadSurvey(widget.surveyId, _currentLanguageId);
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
      print('Successfully loaded survey with language ID: $_currentLanguageId');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      print('Error loading survey after language change: $e');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء تحميل الاستبيان. يرجى المحاولة مرة أخرى',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56), // Standard app bar height
        child: AppBar(
          backgroundColor: AppColors.darkBackgroundColor,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: AppColors.primaryColor,
              size: 22,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Obx(
            () => Text(
              _controller.survey.value?.name ??
                  AppLocalizations.of(context).translate('surveyTitle') ??
                  'Survey',
              style: AppTheme.headingMedium,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(color: AppColors.darkBackgroundColor),
          ),
          actions: [
            // Use a smaller, more compact language selector
            Container(
              padding: const EdgeInsets.only(right: 8.0),
              width: 100, // Fixed width to prevent overflow
              child: DropdownButton<int>(
                value: _currentLanguageId,
                dropdownColor: AppColors.darkBackgroundColor,
                iconEnabledColor: AppColors.primaryColor,
                style: AppTheme.dropdownStyle.copyWith(fontSize: 14),
                underline: Container(height: 0, color: Colors.transparent),
                isExpanded: true, // Take available width
                icon: Icon(Icons.language, size: 18),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    _changeLanguage(newValue);
                  }
                },
                items: [
                  DropdownMenuItem<int>(
                    value: 1,
                    child: Text(
                      'العربية',
                      style: AppTheme.dropdownStyle.copyWith(fontSize: 14),
                    ),
                  ),
                  DropdownMenuItem<int>(
                    value: 2,
                    child: Text(
                      'English',
                      style: AppTheme.dropdownStyle.copyWith(fontSize: 14),
                    ),
                  ),
                  DropdownMenuItem<int>(
                    value: 3,
                    child: Text(
                      'اردو',
                      style: AppTheme.dropdownStyle.copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        // Show loading indicator
        if (_controller.isLoading.value) {
          return Container(
            color: AppColors.darkBackgroundColor,
            child: Center(
              child: SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        // Show error message
        if (_hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'حدث خطأ أثناء تحميل الاستبيان',
                  style: AppTheme.bodyLarge.copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadSurvey,
                  child: Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        // Show location permission request
        if (!_controller.hasLocationPermission.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, color: Colors.orange, size: 48),
                SizedBox(height: 16),
                Text(
                  'يحتاج التطبيق إلى إذن الوصول إلى الموقع',
                  style: AppTheme.bodyLarge.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'لا يمكن البدء في الاستبيان بدون إذن الوصول إلى الموقع',
                  style: AppTheme.bodyMedium.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _controller.requestLocationPermission,
                  child: Text('السماح بالوصول إلى الموقع'),
                ),
              ],
            ),
          );
        }

        // Show survey content
        if (_controller.survey.value == null) {
          return Center(
            child: Text('لا توجد بيانات الاستبيان', style: AppTheme.bodyLarge),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Survey name and description
              Container(
                padding: EdgeInsets.all(AppTheme.spacingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _controller.survey.value!.name ?? '',
                      style: AppTheme.headingLarge,
                    ),
                    SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      _controller.survey.value!.description ?? '',
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              // Questions stepper
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                ),
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: List.generate(
                    _controller.totalQuestions,
                    (index) => _buildStep(index),
                  ),
                ),
              ),

              // Current question content
              _buildQuestionWidget(),

              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStep(int index) {
    // Check if this question has been answered
    bool isAnswered = _controller.isQuestionAnswered(
      _controller.survey.value!.questions[index].id,
    );
    bool isCurrent = index == _controller.currentQuestionIndex.value;
    bool isPast = index < _controller.currentQuestionIndex.value;

    // Determine color based on state
    Color backgroundColor;
    if (isAnswered) {
      backgroundColor =
          AppColors
              .stepperCompletionColor; // Use the dedicated completion color
    } else if (isCurrent) {
      backgroundColor =
          AppColors.primaryColor; // Current question in primary color
    } else if (isPast) {
      backgroundColor =
          AppColors
              .warningColor; // Past but unanswered questions in warning color
    } else {
      backgroundColor =
          AppColors.stepperInactiveColor; // Future questions in inactive color
    }

    return Container(
      width: 28,
      height: 28,
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow:
            isCurrent
                ? [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.4),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: AppTheme.stepperTextStyle.copyWith(
            color: Colors.white, // Always use white text for better contrast
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            fontSize: 12, // Ensure text fits within the circle
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionWidget() {
    if (_controller.currentQuestion == null) {
      return Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('لا توجد أسئلة متاحة', style: AppTheme.bodyTextStyle),
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

  Widget _buildNavigationButtons() {
    final isLastQuestion =
        _controller.currentQuestionIndex.value ==
        _controller.totalQuestions - 1;
    final localizations = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.darkBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview answers button (only when on the last question)
            if (isLastQuestion)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ElevatedButton(
                  onPressed: _showAnswersPreview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.previewButtonColor,
                    foregroundColor: AppColors.primaryColor,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusMedium,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.preview, size: 18),
                      SizedBox(width: 8),
                      Text(
                        localizations.translate('previewAnswers'),
                        style: AppTheme.buttonTextStyle,
                      ),
                    ],
                  ),
                ),
              ),

            // Navigation buttons
            Row(
              children: [
                // Previous button (or empty space if on first question)
                SizedBox(
                  width:
                      MediaQuery.of(context).size.width *
                      0.43, // ~50% with some spacing
                  child:
                      _controller.currentQuestionIndex.value > 0
                          ? OutlinedButton(
                            onPressed: _controller.previousQuestion,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.grey[800],
                              side: BorderSide(
                                color: Colors.grey[400]!,
                                width: 1.5,
                              ),
                              elevation: 0,
                              minimumSize: Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.borderRadiusMedium,
                                ),
                              ),
                            ),
                            child: Text(
                              localizations.translate('previous'),
                              style: AppTheme.buttonTextStyle.copyWith(
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                          : Container(), // Empty container if on first question
                ),

                Spacer(), // Space between buttons
                // Next/Finish button
                SizedBox(
                  width:
                      MediaQuery.of(context).size.width *
                      0.43, // ~50% with some spacing
                  child: OutlinedButton(
                    onPressed: () {
                      if (_controller.currentQuestionIndex.value <
                          _controller.totalQuestions - 1) {
                        _controller.nextQuestion();
                      } else {
                        _handleSubmit();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppColors.darkBackgroundColor,
                      side: BorderSide(color: Colors.white, width: 1.5),
                      elevation: 0,
                      minimumSize: Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusMedium,
                        ),
                      ),
                    ),
                    child: Text(
                      _controller.currentQuestionIndex.value <
                              _controller.totalQuestions - 1
                          ? localizations.translate('next')
                          : localizations.translate('finish'),
                      style: AppTheme.buttonTextStyle.copyWith(
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    // First, validate all required questions are answered
    if (!_controller.validateAllQuestions()) {
      // Show error message for missing required answers
      final localizations = AppLocalizations.of(context);
      Get.snackbar(
        localizations.translate('validationError'),
        localizations.translate('requiredField'),
        backgroundColor: AppColors.errorColor,
        colorText: AppColors.primaryColor,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 3),
      );

      // Find the first unanswered required question and navigate to it
      final questions = _controller.survey.value?.questions ?? [];
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];
        if (question.isRequired &&
            _controller.getAnswerForQuestionRaw(question.id) == null) {
          // Navigate to this unanswered question
          _controller.goToQuestion(i);
          break;
        }
      }

      return;
    }

    // Show confirmation dialog
    final localizations = AppLocalizations.of(context);
    final shouldSubmit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (BuildContext context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 16),
                // Icon at the top
                Icon(
                  Icons.help_outline,
                  color: AppColors.primaryColor,
                  size: 48,
                ),
                SizedBox(height: 16),
                // Title after the icon
                Text(
                  localizations.translate('confirmSubmission'),
                  style: AppTheme.headingMedium.copyWith(color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                // Buttons in a row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Submit button
                    // Cancel button
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryColor,
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          localizations.translate('cancel'),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    SizedBox(width: 16),

                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          side: BorderSide(color: Colors.white, width: 1),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusSmall,
                            ),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          localizations.translate('submit'),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );

    if (shouldSubmit != true) {
      return;
    }

    // Show loading indicator instead of dialog
    setState(() {
      _isSubmitting = true;
    });

    // Get the answers and survey data
    final answers = _controller.answers;
    final surveyId = _controller.survey.value?.id ?? 0;

    // Submit the survey with all required parameters
    final result = await _controller.submitSurvey(
      surveyId: surveyId,
      answers: answers,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (result) {
      // Success - show success message and navigate back to home
      // Get.snackbar(
      //   localizations.translate('success'),
      //   localizations.translate('surveySubmittedSuccessfully'),
      //   backgroundColor: Colors.green,
      //   colorText: Colors.white,
      //   duration: Duration(seconds: 3),
      // );

      // Wait for snackbar to be visible and then navigate back
      await Future.delayed(Duration(milliseconds: 500));
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (_controller.isSubmissionError.value) {
      // Show custom error message if available
      Get.snackbar(
        localizations.translate('error'),
        _controller.submissionErrorMessage.value,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );

      // If it was already submitted, also navigate back
      if (_controller.isCompleted.value) {
        await Future.delayed(Duration(seconds: 2));
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  void _showAnswersPreview() {
    final localizations = AppLocalizations.of(context);
    // Collect answers for showing in preview
    final answersPreview = <int, String>{};
    for (final question in _controller.survey.value?.questions ?? []) {
      final answer = _controller.getAnswerForQuestionRaw(question.id);
      String formattedAnswer = localizations.translate('noAnswer');

      if (answer != null) {
        switch (question.questionType) {
          case QuestionType.textBox:
            formattedAnswer = answer.toString();
            break;

          case QuestionType.rating:
            final rating = int.tryParse(answer.toString()) ?? 0;
            formattedAnswer = '$rating ${localizations.translate('stars')}';
            break;

          case QuestionType.checkBox:
          case QuestionType.radioButton:
          case QuestionType.dropDown:
            // Log the answer type and value for debugging
            print('PREVIEW DEBUG: Question type: ${question.questionType}');
            print('PREVIEW DEBUG: Multi-choice raw value: $answer, type: ${answer.runtimeType}');
            // For checkboxes specifically, print more details about the answer structure
            if (question.questionType == QuestionType.checkBox) {
              print('PREVIEW DEBUG: CHECKBOX DETAILS:');
              if (answer is List) {
                print('PREVIEW DEBUG: List items: ${answer.length}');
                answer.forEach((item) => print('PREVIEW DEBUG: Item: $item (${item.runtimeType})'));
              } else if (answer is String) {
                print('PREVIEW DEBUG: String value: "$answer"');
                if (answer.startsWith('[') && answer.endsWith(']')) {
                  print('PREVIEW DEBUG: Looks like JSON array string');
                }
              } else if (answer != null) {
                print('PREVIEW DEBUG: Other type: ${answer.runtimeType}');
              }
            }
            final selectedOptions = <String>[];
            List<dynamic> answerList = [];
            
            // *** CHECKBOX-SPECIFIC APPROACH ***
            if (question.questionType == QuestionType.checkBox) {
              // Handle checkbox answers from raw data
              if (answer is List) {
                answerList.addAll(answer);
              } else if (answer is String) {
                try {
                  answerList.addAll(List<dynamic>.from(jsonDecode(answer)));
                } catch (_) {
                  answerList.addAll(answer
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty));
                }
              }
              // Map to option labels
              final selectedOptions = answerList.map((item) {
                final itemStr = item.toString();
                final matchedOption = question.answers.firstWhere(
                  (o) => o.id.toString() == itemStr,
                  orElse: () => throw '',
                );
                return matchedOption.answer ?? itemStr;
              }).toList();
              formattedAnswer = selectedOptions.isEmpty
                  ? (localizations.translate('noAnswer') ?? '')
                  : selectedOptions.join(' | ');
              break;
            }
              
            // For radio and dropdown answers, handle all possible formats
            try {
              if (answer == null) {
                // No answer selected
                answerList = [];
              } else if (answer is List) {
                // Already a list format
                answerList = answer;
              } else if (answer is String) {
                if (answer.startsWith('[') && answer.endsWith(']')) {
                  // JSON array string
                  try {
                    answerList = List<dynamic>.from(jsonDecode(answer));
                  } catch (_) {
                    // If JSON parse fails, try as comma-separated
                    answerList = answer.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  }
                } else if (answer.contains(',')) {
                  // Comma-separated values
                  answerList = answer.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                } else {
                  // Single value
                  answerList = [answer];
                }
              } else {
                // Any other type, convert to string and use as single value
                answerList = [answer.toString()];
              }
              
              // For Radio/Dropdown, ensure it's a single-selection answer
              if ((question.questionType == QuestionType.radioButton || 
                   question.questionType == QuestionType.dropDown) && 
                  answerList.length > 1) {
                answerList = [answerList.first];
              }
              
              // Match each value with an answer option
              for (final optionValue in answerList) {
                var optionStr = optionValue?.toString() ?? '';
                if (optionStr.isEmpty) continue;
                
                // First try to match by ID
                var matchedOption = question.answers.firstWhere(
                  (o) => o.id.toString() == optionStr,
                  orElse: () => app_models.SurveyAnswer(id: -1, answer: ''),
                );
                
                // If no match by ID, try by answer text
                if (matchedOption.id == -1) {
                  matchedOption = question.answers.firstWhere(
                    (o) => o.answer?.toString().toLowerCase() == optionStr.toLowerCase(),
                    orElse: () => app_models.SurveyAnswer(id: 0, answer: optionStr),
                  );
                }
                
                // Add the matched label (or value if no match found)
                if (matchedOption.answer != null && matchedOption.answer!.isNotEmpty) {
                  selectedOptions.add(matchedOption.answer!);
                } else {
                  selectedOptions.add(optionStr); // Fallback to the raw value
                }
              }
            } catch (e) {
              print('ERROR matching multi-choice answers: $e');
              selectedOptions.add('Error: $e');
            }
            
            formattedAnswer = selectedOptions.isEmpty
                ? (localizations.translate('noAnswer') ?? '')
                : selectedOptions.join(' | ');
            break;

          // Note: RadioButton and DropDown cases are now handled in the combined multi-choice section above
            break;

          case QuestionType.fileUpload:
            if (answer.toString().startsWith('data:')) {
              // It's a base64 file
              final nameMatch = RegExp(
                r'filename=([^;]+)',
              ).firstMatch(answer.toString());
              final fileName = nameMatch?.group(1) ?? 'uploaded_image.jpg';
              formattedAnswer = '📷 $fileName';
            } else if (answer.toString().contains('/')) {
              // It's a file path - legacy format
              formattedAnswer = '📷 ${answer.toString().split('/').last}';
            } else {
              formattedAnswer = '📷 ${answer.toString()}';
            }
            break;

          default:
            formattedAnswer = answer.toString();
        }
      }

      answersPreview[question.id] = formattedAnswer;
    }

    // Show answers in a bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkBackgroundColor,
      isScrollControlled: true,
      builder:
          (context) => Container(
            height:
                MediaQuery.of(context).size.height *
                0.8, // 80% of screen height
            padding: EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with title and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.translate('answersPreview'),
                      style: AppTheme.headingMedium,
                    ),
                    OutlinedButton.icon(
                      icon: Icon(Icons.close, color: Colors.white),
                      label: Text(
                        'إغلاق',
                        style: AppTheme.buttonTextStyle.copyWith(color: Colors.white),
                      ),
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppColors.darkBackgroundColor,
                        side: BorderSide(color: Colors.white, width: 1.5),
                        elevation: 0,
                        minimumSize: Size(100, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(color: AppColors.dividerColor, height: 24),

                // List of answers
                Expanded(
                  child: ListView.builder(
                    itemCount: _controller.survey.value?.questions.length ?? 0,
                    itemBuilder: (context, index) {
                      final question =
                          _controller.survey.value!.questions[index];
                      final questionId = question.id;
                      final formattedAnswer =
                          answersPreview[questionId] ?? 'لم يتم الإجابة';

                      // Create a card for each question and answer
                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.previewItemColor,
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusSmall,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context); // Close preview
                                _controller.goToQuestion(index);
                                setState(() {}); // Refresh UI
                              },
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primaryColor,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              question.question ?? '',
                              style: AppTheme.previewQuestionStyle,
                            ),
                            SizedBox(height: 8),

                            // For rating questions, show stars
                            if (question.questionType == QuestionType.rating &&
                                formattedAnswer != 'لم يتم الإجابة')
                              FormatterHelper.buildRatingStars(
                                int.tryParse(
                                      formattedAnswer.split(' ').first,
                                    ) ??
                                    0,
                              )
                            else
                              Text(
                                formattedAnswer,
                                style:
                                    formattedAnswer == 'لم يتم الإجابة'
                                        ? AppTheme.previewUnansweredStyle
                                        : AppTheme.previewAnswerStyle,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Close button at bottom
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                      side: BorderSide(color: AppColors.primaryColor, width: 1.5),
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusMedium,
                        ),
                      ),
                    ),
                    child: Text(
                      localizations.translate('close'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
