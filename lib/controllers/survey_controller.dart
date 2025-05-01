import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/models/question_type.dart';
import 'package:adcda_inspector/models/survey.dart';
import 'package:adcda_inspector/models/survey_submit.dart';
import 'package:adcda_inspector/models/start_survey_request.dart' as start_request;
import 'package:adcda_inspector/services/location_service.dart';
import 'package:adcda_inspector/services/survey_service.dart';
import 'package:adcda_inspector/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:adcda_inspector/l10n/app_localizations.dart';
import 'package:adcda_inspector/constants/app_colors.dart';

/// Controller for managing survey state using GetX
class SurveyController extends GetxController {
  final SurveyService _surveyService = SurveyService();
  final LocationService _locationService = LocationService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Observable variables
  final Rx<Survey?> survey = Rx<Survey?>(null);
  final RxInt currentQuestionIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isCompleted = false.obs;
  final RxMap<int, dynamic> answers = RxMap<int, dynamic>();
  final RxBool hasLocationPermission = false.obs;
  final RxDouble currentLatitude = 0.0.obs;
  final RxDouble currentLongitude = 0.0.obs;
  final RxBool locationLoading = false.obs;
  final RxBool isSubmissionError = false.obs;
  final RxString submissionErrorMessage = ''.obs;
  
  // Current language ID
  int _currentLanguageId = AppConstants.defaultLanguageId;
  
  // Device info
  String? _deviceType;
  
  // Submission GUID for the current survey
  String? submissionGuid;

  @override
  void onInit() {
    super.onInit();
    _checkLocationPermission();
    _getDeviceInfo();
  }

  /// Get device information
  Future<void> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _deviceType = 'Android ${androidInfo.version.release} - ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceType = 'iOS ${iosInfo.systemVersion} - ${iosInfo.model}';
      } else {
        _deviceType = 'Unknown';
      }
      
      print('Device type: $_deviceType');
    } catch (e) {
      print('Error getting device info: $e');
      _deviceType = 'Unknown';
    }
  }

  /// Check if we have location permission and request if needed
  Future<void> _checkLocationPermission() async {
    locationLoading.value = true;
    final permission = await _locationService.checkPermission();
    hasLocationPermission.value = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    
    if (hasLocationPermission.value) {
      await _getLocation();
    }
    locationLoading.value = false;
  }

  /// Request location permission from user
  Future<bool> requestLocationPermission() async {
    locationLoading.value = true;
    final permission = await _locationService.requestPermission();
    hasLocationPermission.value = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    
    if (hasLocationPermission.value) {
      await _getLocation();
    } else {
      // Show platform-specific instructions dialog
      if (Get.context != null) {
        await DialogHelper.showLocationPermissionDialog(Get.context!);
      }
    }
    locationLoading.value = false;
    return hasLocationPermission.value;
  }

  /// Get current location with permission handling
  Future<bool> _getLocation() async {
    try {
      locationLoading.value = true;
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        currentLatitude.value = position.latitude;
        currentLongitude.value = position.longitude;
        print('Got location: ${position.latitude}, ${position.longitude}');
        locationLoading.value = false;
        return true;
      }
      
      locationLoading.value = false;
      return false;
    } catch (e) {
      print('Error getting location: $e');
      locationLoading.value = false;
      
      String errorMessage;
      if (e.toString().contains('denied forever')) {
        errorMessage = 'تم رفض إذن الوصول إلى الموقع بشكل نهائي. يرجى الانتقال إلى إعدادات التطبيق وتفعيل إذن الموقع.';
      } else {
        errorMessage = 'لا يمكن الوصول إلى موقعك. يرجى التأكد من تفعيل خدمات الموقع.';
      }
      
      Get.snackbar(
        'خطأ',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );
      
      return false;
    }
  }

  /// Load a survey by ID
  Future<void> loadSurvey(int surveyId, int languageId) async {
    isLoading.value = true;
    answers.clear();
    currentQuestionIndex.value = 0;
    submissionGuid = null;
    _currentLanguageId = languageId;
    isSubmissionError.value = false;
    submissionErrorMessage.value = '';
    
    try {
      // First check location permission
      if (!hasLocationPermission.value) {
        await requestLocationPermission();
        if (!hasLocationPermission.value) {
          isLoading.value = false;
          return; // Can't proceed without location permission
        }
      }
      
      // Get location
      final hasLocation = await _getLocation();
      if (!hasLocation) {
        // Show error and return
        Get.snackbar(
          'خطأ',
          'الوصول إلى الموقع مطلوب لإكمال الاستبيان.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return;
      }

      // Start new survey submission
      final startRequest = start_request.StartSurveyRequest(
        surveyId: surveyId,
        incidentId: 0,
        languageId: languageId,
        latitude: currentLatitude.value,
        longitude: currentLongitude.value,
        deviceType: _deviceType,
      );
      
      submissionGuid = await _surveyService.startSurvey(startRequest);
      
      if (submissionGuid == null) {
        throw Exception('فشل في بدء الاستبيان. يرجى المحاولة مرة أخرى.');
      }
      
      print('Started survey with submission GUID: $submissionGuid');

      // Load survey details
      final loadedSurvey = await _surveyService.fetchSurvey(
        surveyId, 
        languageId: languageId
      );
      
      survey.value = loadedSurvey;
      
      // Clear previous answers
      answers.clear();
      
      isLoading.value = false;
    } catch (e) {
      print('Error loading survey: $e');
      isLoading.value = false;
      Get.snackbar(
        'خطأ',
        'لا يمكن تحميل الاستبيان. يرجى التأكد من اتصال الإنترنت ومحاولة مرة أخرى.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Get the current question
  SurveyQuestion? get currentQuestion {
    if (survey.value == null ||
        survey.value!.questions.isEmpty ||
        currentQuestionIndex.value >= survey.value!.questions.length) {
      return null;
    }
    return survey.value!.questions[currentQuestionIndex.value];
  }

  /// Get the total number of questions
  int get totalQuestions => survey.value?.questions.length ?? 0;

  /// Check if the current question is the last one
  bool get isLastQuestion =>
      currentQuestionIndex.value == (survey.value?.questions.length ?? 0) - 1;

  /// Check if the current question is the first one
  bool get isFirstQuestion => currentQuestionIndex.value == 0;

  /// Move to the next question
  void nextQuestion() {
    if (currentQuestionIndex.value <
        (survey.value?.questions.length ?? 0) - 1) {
      currentQuestionIndex.value++;
    }
  }

  /// Move to the previous question
  void previousQuestion() {
    if (currentQuestionIndex.value > 0) {
      currentQuestionIndex.value--;
    }
  }

  /// Save answer for the current question
  void saveAnswer({
    int? answerId,
    String? textAnswer,
    double? numericAnswer,
    DateTime? dateAnswer,
    String? comments,
  }) {
    if (currentQuestion == null) return;

    final questionId = currentQuestion!.id;

    // Check if we already have an answer for this question
    if (answers.containsKey(questionId)) {
      // Update existing answer
      var answer = answers[questionId] as SurveySubmitAnswer;
      answers[questionId] = SurveySubmitAnswer(
        questionId: questionId,
        answerId: answerId ?? answer.answerId,
        textAnswer: textAnswer ?? answer.textAnswer,
        numericAnswer: numericAnswer ?? answer.numericAnswer,
        dateAnswer: dateAnswer ?? answer.dateAnswer,
        comments: comments ?? answer.comments,
      );
    } else {
      // Create new answer
      answers[questionId] = SurveySubmitAnswer(
        questionId: questionId,
        answerId: answerId,
        textAnswer: textAnswer,
        numericAnswer: numericAnswer,
        dateAnswer: dateAnswer,
        comments: comments,
      );
    }
  }

  /// Check if the current question has been answered
  bool isQuestionAnswered(int questionId) {
    return answers.containsKey(questionId);
  }

  /// Get the answer for a specific question
  SurveySubmitAnswer? getAnswerForQuestion(int questionId) {
    if (answers.containsKey(questionId)) {
      return answers[questionId] as SurveySubmitAnswer;
    }
    return null;
  }

  /// Get validation error for a specific question
  String? getValidationError(int questionId) {
    // Implement validation logic here
    final question = survey.value?.questions.firstWhere(
      (q) => q.id == questionId,
      orElse:
          () => SurveyQuestion(
            id: questionId,
            question: 'Unknown Question',
            questionType: QuestionType.textBox,
            isRequired: false,
            sortOrder: 0,
            answers: [],
          ),
    );

    // Check if required and not answered
    if (question?.isRequired == true && !answers.containsKey(questionId)) {
      return AppConstants.requiredField;
    }

    return null;
  }

  /// Get answer value as string
  String? getAnswer(int questionId) {
    print('Getting answer for question $questionId: ${answers[questionId]}');
    final value = getAnswerForQuestionRaw(questionId);
    if (value == null) {
      return null;
    }
    return value.toString();
  }

  /// Helper method to get a single answer as a string
  String? getAnswerString(int questionId) {
    return answers[questionId];
  }

  /// Helper method to get answers as a list of strings
  List<int> getAnswerAsList(int questionId) {
    if (answers[questionId] == null) return [];
    
    try {
      // First try to parse as JSON list
      final List<dynamic> parsed = jsonDecode(answers[questionId]!);
      return parsed.map((item) => int.parse(item.toString())).toList();
    } catch (e) {
      // If parsing fails, try comma-separated format
      try {
        return answers[questionId]!
            .split(',')
            .where((s) => s.isNotEmpty)
            .map((s) => int.parse(s.trim()))
            .toList();
      } catch (e) {
        print('Error parsing answer list: $e');
        return [];
      }
    }
  }

  /// Get the answer value for a specific question (for form fields)
  dynamic getAnswerForQuestionRaw(int questionId) {
    if (!answers.containsKey(questionId)) {
      return null;
    }
    
    // Get the question to determine how to extract the value
    SurveyQuestion defaultQuestion = SurveyQuestion(
      id: questionId,
      question: 'Unknown Question',
      questionType: QuestionType.textBox,
      isRequired: false,
      sortOrder: 0,
      answers: [],
    );
    
    final question = survey.value?.questions.firstWhere(
      (q) => q.id == questionId,
      orElse: () => defaultQuestion,
    ) ?? defaultQuestion;
    
    final answer = answers[questionId];
    
    // Return the appropriate value based on question type
    switch (question.questionType) {
      case QuestionType.radioButton:
      case QuestionType.dropDown:
        return answer is SurveySubmitAnswer ? answer.answerId : answer;
      case QuestionType.checkBox:
      case QuestionType.multiSelect:
        if (answer is List) {
          return answer;
        } else if (answer is SurveySubmitAnswer && answer.textAnswer != null) {
          try {
            return jsonDecode(answer.textAnswer!);
          } catch (_) {
            return [];
          }
        }
        return [];
      case QuestionType.textBox:
      default:
        return answer is SurveySubmitAnswer ? answer.textAnswer : answer;
    }
  }

  /// Update answer in any format
  void updateAnswer(int questionId, dynamic answerValue) {
    print('SurveyController: Updating answer for question $questionId with value: $answerValue (type: ${answerValue.runtimeType})');
    
    // Get the question to determine how to handle the value
    SurveyQuestion defaultQuestion = SurveyQuestion(
      id: questionId,
      question: 'Unknown Question',
      questionType: QuestionType.textBox,
      isRequired: false,
      sortOrder: 0,
      answers: [],
    );
    
    final question = survey.value?.questions.firstWhere(
      (q) => q.id == questionId,
      orElse: () => defaultQuestion,
    ) ?? defaultQuestion;
    
    // Handle different question types appropriately
    switch (question.questionType) {
      case QuestionType.radioButton:
      case QuestionType.dropDown:
        // Ensure radio button and dropdown values are stored as strings
        if (answerValue is int) {
          answers[questionId] = answerValue.toString();
        } else {
          answers[questionId] = answerValue;
        }
        break;
        
      case QuestionType.checkBox:
      case QuestionType.multiSelect:
        if (answerValue is List) {
          // Ensure all list items are strings (for consistent parsing)
          List<String> normalizedValues = answerValue.map((item) => item.toString()).toList();
          
          // Store as JSON string for consistent storage and retrieval
          print('Storing checkbox values as JSON: $normalizedValues');
          answers[questionId] = jsonEncode(normalizedValues);
        } else if (answerValue is String) {
          // If it's already a string, try to parse to see if it's valid JSON
          try {
            // Try to decode to verify it's valid JSON
            jsonDecode(answerValue);
            // If no exception, it's valid JSON, store as is
            print('Using existing JSON string for checkbox: $answerValue');
            answers[questionId] = answerValue;
          } catch (e) {
            // If it's not valid JSON, wrap the single value in a list and encode
            print('Converting single string to JSON array for checkbox: $answerValue');
            answers[questionId] = jsonEncode([answerValue]);
          }
        } else {
          // For other types, convert to string and wrap in a JSON array
          print('Converting other value type to JSON array for checkbox: $answerValue');
          answers[questionId] = jsonEncode([answerValue.toString()]);
        }
        
        // Debug the final stored value
        print('Final stored checkbox value: ${answers[questionId]} (${answers[questionId].runtimeType})');
        break;
        
      case QuestionType.textBox:
      default:
        // For other types, store as is
        answers[questionId] = answerValue;
        break;
    }
    
    print('SurveyController: Updated answer for question $questionId: ${answers[questionId]} (type: ${answers[questionId].runtimeType})');
  }

  /// Get all answers as a map
  Map<int, dynamic>? getAnswers() {
    if (answers.isEmpty) return null;
    return answers;
  }

  /// Submit the survey to the server
  Future<bool> submitSurvey({
    required int surveyId,
    required Map<int, dynamic> answers,
  }) async {
    // Get localization from the current context
    final context = Get.context!;
    final localizations = AppLocalizations.of(context);
    
    // Show confirmation dialog before submitting
    final shouldSubmit = await _showConfirmationDialog();
    if (!shouldSubmit) {
      return false; // User cancelled submission
    }
    
    isSubmitting.value = true;
    isSubmissionError.value = false;
    submissionErrorMessage.value = '';
    
    try {
      // Verify we have a submission GUID
      if (submissionGuid == null || submissionGuid!.isEmpty) {
        throw Exception(localizations.translate('noActiveSubmission') ?? 'No active submission found. Please restart the survey.');
      }
      
      // Verify location data
      if (!hasLocationPermission.value) {
        final hasPermission = await requestLocationPermission();
        if (!hasPermission) {
          throw Exception(localizations.translate('locationPermissionRequired') ?? 'Location permission required to submit survey.');
        }
      }
      
      // Get current location to ensure it's up-to-date
      final hasLocation = await _getLocation();
      if (!hasLocation) {
        throw Exception(localizations.translate('cannotGetLocation') ?? 'Cannot get current location. Please check your device settings.');
      }

      // Format answers for submission
      final formattedAnswers = _formatAnswersForSubmission(answers);
      
      // Create survey submit object
      final surveySubmit = SurveySubmit(
        surveyId: surveyId,
        answers: formattedAnswers,
        languageId: _currentLanguageId,
        latitude: currentLatitude.value,
        longitude: currentLongitude.value,
        deviceType: _deviceType,
      );

      // Show loading indicator during submission
      Get.dialog(
        AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(localizations.translate('submitting') ?? 'Submitting survey...'),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      try {
        // Submit the survey with the GUID
        final success = await _surveyService.submitSurveyWithGuid(
          submissionGuid!,
          surveySubmit,
        );

        // Close the loading dialog
        Get.back();

        if (success) {
          isCompleted.value = true;
          Get.snackbar(
            localizations.translate('success') ?? 'Success',
            localizations.translate('surveySubmittedSuccessfully') ?? 'Survey submitted successfully!',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: Duration(seconds: 5),
          );
          isSubmitting.value = false;
          return true;
        } else {
          throw Exception(localizations.translate('failedToSubmit') ?? 'Failed to submit survey');
        }
      } catch (e) {
        // Close the loading dialog if still open
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
        
        print('Error in submission: $e');
        String errorMessage = localizations.translate('errorSubmitting') ?? 'Failed to submit survey. Please try again.';
        
        // Check if it's an already submitted error
        if (e.toString().toLowerCase().contains('already been submitted')) {
          errorMessage = localizations.translate('alreadySubmitted') ?? 'This survey has already been submitted.';
          isCompleted.value = true; // Mark as completed since it's already submitted
        }
        
        isSubmissionError.value = true;
        submissionErrorMessage.value = errorMessage;
        
        Get.snackbar(
          localizations.translate('error') ?? 'Error',
          errorMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
        );
        
        isSubmitting.value = false;
        return isCompleted.value; // Return true if it was already submitted
      }
    } catch (e) {
      // Close the loading dialog if still open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      
      print('Error submitting survey: $e');
      
      isSubmissionError.value = true;
      submissionErrorMessage.value = localizations.translate('networkError') ?? 'Failed to submit survey. Please check your internet connection and try again.';
      
      Get.snackbar(
        localizations.translate('error') ?? 'Error',
        submissionErrorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      
      isSubmitting.value = false;
      return false;
    }
  }

  /// Show a confirmation dialog before submitting the survey
  Future<bool> _showConfirmationDialog() async {
    // Return true directly without showing the dialog
    return true;
  }

  /// Reset the survey state
  void resetSurvey() {
    currentQuestionIndex.value = 0;
    answers.clear();
    isCompleted.value = false;
  }

  /// Reset the survey state
  void resetSurveyState() {
    // Clear answers
    answers.clear();
    
    // Reset step
    currentQuestionIndex.value = 0;
    
    // Reset flags
    isSubmitting.value = false;
    isLoading.value = false;
    
    print('Survey state reset completed');
  }

  /// Validate all questions
  bool validateAllQuestions() {
    final unansweredRequiredQuestions =
        survey.value!.questions
            .where(
              (question) =>
                  question.isRequired && !answers.containsKey(question.id),
            )
            .toList();

    return unansweredRequiredQuestions.isEmpty;
  }

  /// Go to a specific question
  void goToQuestion(int index) {
    if (index >= 0 && index < (survey.value?.questions.length ?? 0)) {
      currentQuestionIndex.value = index;
    }
  }

  /// Check if we can navigate to a specific question
  bool canNavigateToQuestion(int index) {
    // Only allow navigation to questions that have been answered or are the next question
    if (index <= currentQuestionIndex.value + 1) {
      return true;
    }
    return false;
  }

  /// Get a map of question IDs to answers
  Map<int, dynamic> getAnswersMap() {
    print('DEBUG - All answers in controller: $answers');
    return answers;
  }

  List<SurveySubmitAnswer> _formatAnswersForSubmission(Map<int, dynamic> answers) {
    final List<SurveySubmitAnswer> formattedAnswers = [];
    print('Formatting answers for submission: $answers');

    answers.forEach((questionId, answerValue) {
      // Skip null or empty answers
      if (answerValue == null) {
        print('Skipping null answer for question $questionId');
        return;
      }

      // Get the corresponding question to determine its type
      final question = survey.value!.questions.firstWhere(
        (q) => q.id == questionId,
        orElse: () => SurveyQuestion(
          id: questionId,
          question: 'Unknown Question',
          questionType: QuestionType.textBox,
          isRequired: false,
          sortOrder: 0,
          answers: [],
        ),
      );

      print('Processing question ID: $questionId, type: ${question.questionType}, value: $answerValue (${answerValue.runtimeType})');

      // Handle different question types
      switch (question.questionType) {
        case QuestionType.radioButton:
        case QuestionType.dropDown:
          // For radio buttons and dropdowns, the answerId should be an integer
          int? parsedAnswerId;
          if (answerValue is String) {
            // Try to parse string to int for radio buttons and dropdowns
            try {
              parsedAnswerId = int.parse(answerValue);
            } catch (e) {
              print('Error parsing radio/dropdown answer as int: $e');
              // If parsing fails, use the string as textAnswer
              formattedAnswers.add(SurveySubmitAnswer(
                questionId: questionId,
                textAnswer: answerValue,
              ));
              return;
            }
          } else if (answerValue is int) {
            parsedAnswerId = answerValue;
          }
          
          formattedAnswers.add(SurveySubmitAnswer(
            questionId: questionId,
            answerId: parsedAnswerId,
          ));
          break;

        case QuestionType.checkBox:
        case QuestionType.multiSelect:
          // For checkboxes, handle it as a list of selected answer IDs
          try {
            List<dynamic> selectedAnswers = [];
            
            // Handle different formats of checkbox answers
            if (answerValue is String) {
              // If it's a JSON string, decode it
              try {
                selectedAnswers = jsonDecode(answerValue);
              } catch (e) {
                print('Error decoding checkbox JSON: $e');
                // If it's not valid JSON, it might be a single value
                selectedAnswers = [answerValue];
              }
            } else if (answerValue is List) {
              selectedAnswers = answerValue;
            } else if (answerValue is bool && answerValue) {
              // For a boolean value, include the question ID if true
              selectedAnswers = [questionId.toString()];
            } else {
              // For any other value, treat it as a single selection
              selectedAnswers = [answerValue];
            }
            
            print('Checkbox selected answers: $selectedAnswers');
            
            // For multiple selected answers, create separate entries for each
            for (var selected in selectedAnswers) {
              int? answerId;
              // Try to parse as int if it's a string
              if (selected is String) {
                try {
                  answerId = int.parse(selected);
                } catch (e) {
                  // If not a valid int, use as text
                  formattedAnswers.add(SurveySubmitAnswer(
                    questionId: questionId,
                    textAnswer: selected,
                  ));
                  continue;
                }
              } else if (selected is int) {
                answerId = selected;
              } else if (selected is bool && selected) {
                // For boolean values, use question ID for true
                answerId = questionId;
              }
              
              if (answerId != null) {
                formattedAnswers.add(SurveySubmitAnswer(
                  questionId: questionId,
                  answerId: answerId,
                ));
              }
            }
          } catch (e) {
            print('Error processing checkbox answers: $e');
            // Fallback: add as text answer
            formattedAnswers.add(SurveySubmitAnswer(
              questionId: questionId,
              textAnswer: answerValue.toString(),
            ));
          }
          break;

        case QuestionType.rating:
          // For ratings, ensure it's a numeric value
          double? rating;
          if (answerValue is String) {
            try {
              rating = double.parse(answerValue);
            } catch (e) {
              print('Error parsing rating as double: $e');
            }
          } else if (answerValue is num) {
            rating = answerValue.toDouble();
          }
          
          formattedAnswers.add(SurveySubmitAnswer(
            questionId: questionId,
            numericAnswer: rating,
          ));
          break;

        case QuestionType.textBox:
          // For text boxes, check if it's a numeric value first
          if (answerValue is num) {
            // It's a number, use numericAnswer
            formattedAnswers.add(SurveySubmitAnswer(
              questionId: questionId,
              numericAnswer: answerValue.toDouble(),
            ));
          } else if (answerValue is String && double.tryParse(answerValue) != null) {
            // It's a string that can be parsed as a number
            formattedAnswers.add(SurveySubmitAnswer(
              questionId: questionId,
              numericAnswer: double.parse(answerValue),
            ));
          } else {
            // It's a non-numeric string or other value
            String textValue = answerValue is String 
                ? answerValue 
                : answerValue.toString();
            
            formattedAnswers.add(SurveySubmitAnswer(
              questionId: questionId,
              textAnswer: textValue,
            ));
          }
          break;

        case QuestionType.date:
          // For date questions, ensure we have a DateTime
          DateTime? dateValue;
          if (answerValue is DateTime) {
            dateValue = answerValue;
          } else if (answerValue is String) {
            try {
              dateValue = DateTime.parse(answerValue);
            } catch (e) {
              print('Error parsing date string: $e');
            }
          }
          
          formattedAnswers.add(SurveySubmitAnswer(
            questionId: questionId,
            dateAnswer: dateValue,
          ));
          break;

        default:
          // For other types, check if it's a numeric value first
          if (answerValue is num) {
            // It's a number, use numericAnswer
            formattedAnswers.add(SurveySubmitAnswer(
              questionId: questionId,
              numericAnswer: answerValue.toDouble(),
            ));
          } else if (answerValue is String && double.tryParse(answerValue) != null) {
            // It's a string that can be parsed as a number
            formattedAnswers.add(SurveySubmitAnswer(
              questionId: questionId,
              numericAnswer: double.parse(answerValue),
            ));
          } else {
            // It's a non-numeric string or other value
            formattedAnswers.add(SurveySubmitAnswer(
              questionId: questionId,
              textAnswer: answerValue is String 
                  ? answerValue 
                  : answerValue.toString(),
            ));
          }
          break;
      }
    });

    print('Formatted ${formattedAnswers.length} answers for submission');
    return formattedAnswers;
  }
}
