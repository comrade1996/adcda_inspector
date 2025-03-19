import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/controllers/survey_controller.dart';
import 'package:adcda_inspector/widgets/question_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:get/get.dart';

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
      appBar: AppBar(
        title: Obx(() => Text(_controller.survey.value?.name ?? 'Survey')),
        backgroundColor: Colors.white, // White AppBar
        foregroundColor: Colors.black,
        elevation: 0, // Remove shadow
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100], // Very light grey background
          image: DecorationImage(
            image: AssetImage("assets/background_pattern.png"), // Replace with your pattern
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.1),
              BlendMode.dstATop,
            ),
          ),
        ),
        child: Obx(() {
          if (_controller.isLoading.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF007BFF)), // Placeholder ADCDA color
                  ).animate().rotate(duration: 800.ms),
                  SizedBox(height: 16),
                  Text(AppConstants.loadingText),
                ],
              ),
            );
          }

          if (_controller.survey.value == null) {
            return Center(
              child: Text('Failed to load survey. Please try again.'),
            );
          }

          if (_controller.isCompleted.value) {
            return _buildCompletionScreen();
          }

          return _buildSurveyForm();
        }),
      ),
    );
  }

  Widget _buildSurveyForm() {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display survey description if available
                  if (_controller.survey.value?.description != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Text(
                        _controller.survey.value!.description!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),

                  // Progress indicator
                  LinearProgressIndicator(
                    value: (_controller.currentQuestionIndex.value + 1) /
                        _controller.totalQuestions,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF007BFF)), // Placeholder ADCDA color
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Question ${_controller.currentQuestionIndex.value + 1} of ${_controller.totalQuestions}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Current question
                  if (_controller.currentQuestion != null)
                    QuestionWidget(
                      question: _controller.currentQuestion!,
                      controller: _controller,
                    ).animate().fadeIn(duration: 300.ms),
                  else
                    Text('No questions available'),
                ],
              ),
            ),
          ),
          // Bottom navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          Obx(() => ElevatedButton.icon(
                onPressed: _controller.isFirstQuestion
                    ? null
                    : () {
                        _controller.previousQuestion();
                      },
                icon: Icon(Icons.arrow_back),
                label: Text(AppConstants.previousButton),
                style: ElevatedButton.styleFrom(
                  disabledForegroundColor: Colors.grey.withOpacity(0.38),
                  disabledBackgroundColor: Colors.grey.withOpacity(0.12),
                ),
              )).animate().scale(duration: 200.ms, curve: Curves.easeInOut),

          // Next/Submit button
          Obx(() {
            final isLastQuestion = _controller.isLastQuestion;
            final currentQuestion = _controller.currentQuestion;
            final questionAnswered = currentQuestion != null &&
                (!currentQuestion.isRequired ||
                    _controller.isQuestionAnswered(currentQuestion.id));

            return ElevatedButton.icon(
              onPressed: _controller.isSubmitting.value
                  ? null
                  : () {
                      if (isLastQuestion) {
                        // Validate all answers before submitting
                        if (_formKey.currentState?.validate() ?? false) {
                          _handleSubmit();
                        }
                      } else {
                        // Move to the next question if this one is valid
                        if (!currentQuestion!.isRequired ||
                            questionAnswered ||
                            (_formKey.currentState?.validate() ?? false)) {
                          _controller.nextQuestion();
                        }
                      }
                    },
              icon: Icon(isLastQuestion ? Icons.check : Icons.arrow_forward),
              label: Text(isLastQuestion
                  ? AppConstants.submitButton
                  : AppConstants.nextButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastQuestion
                    ? Colors.green
                    : Color(0xFF007BFF), // Placeholder ADCDA color
                foregroundColor: Colors.white,
              ),
            ).animate().scale(duration: 200.ms, curve: Curves.easeInOut);
          }),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 100,
            color: Colors.green,
          ),
          SizedBox(height: 16),
          Text(
            'Survey Completed!',
            style: TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      final answers = _formKey.currentState?.value;

      // Show confirmation dialog
      bool? confirmSubmit = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Confirm Submission"),
            content: Text("Are you sure you want to submit the survey?"),
            actions: <Widget>[
              TextButton(
                child: Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              ElevatedButton(
                child: Text("Submit"),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );

      if (confirmSubmit == true) {
        _controller.submitSurvey(answers!);
      }
    }
  }
}
