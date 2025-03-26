import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/models/question_type.dart';
import 'package:adcda_inspector/models/survey.dart';
import 'package:adcda_inspector/models/survey_submit.dart';
import 'package:adcda_inspector/services/survey_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controller for managing survey state using GetX
class SurveyController extends GetxController {
  final SurveyService _surveyService = SurveyService();
  
  // Observable variables
  final Rx<Survey?> survey = Rx<Survey?>(null);
  final RxInt currentQuestionIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isCompleted = false.obs;
  final RxMap<int, dynamic> answers = RxMap<int, dynamic>();
  
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
  
  /// Load survey data
  Future<void> loadSurvey(int surveyId, {int languageId = AppConstants.defaultLanguageId}) async {
    try {
      isLoading.value = true;
      final loadedSurvey = await _surveyService.fetchSurvey(surveyId, languageId);
      survey.value = loadedSurvey;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load survey: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Move to the next question
  void nextQuestion() {
    if (currentQuestionIndex.value < (survey.value?.questions.length ?? 0) - 1) {
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
    String? comments
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
      orElse: () => null as SurveyQuestion,
    );
    
    if (question == null) return null;
    
    // Check if required and not answered
    if (question.isRequired && !answers.containsKey(questionId)) {
      return AppConstants.requiredField;
    }
    
    return null;
  }
  
  /// Get answer value as string
  String? getAnswer(int questionId) {
    final answer = getAnswerForQuestion(questionId);
    if (answer == null) return null;
    
    if (answer.textAnswer != null) return answer.textAnswer;
    if (answer.answerId != null) return answer.answerId.toString();
    if (answer.numericAnswer != null) return answer.numericAnswer.toString();
    if (answer.dateAnswer != null) return answer.dateAnswer.toString();
    
    return null;
  }
  
  /// Get answer value as list of strings
  List<String> getAnswerAsList(int questionId) {
    final answer = getAnswerForQuestion(questionId);
    if (answer == null) return [];
    
    // For multiple selection, parsing comma-separated values
    if (answer.textAnswer != null && answer.textAnswer!.contains(',')) {
      return answer.textAnswer!.split(',');
    }
    
    // Single value as a list
    if (answer.textAnswer != null) return [answer.textAnswer!];
    if (answer.answerId != null) return [answer.answerId.toString()];
    
    return [];
  }
  
  /// Update answer for a question
  void updateAnswer(int questionId, dynamic value) {
    // If value is null, remove the answer
    if (value == null) {
      answers.remove(questionId);
      return;
    }
    
    // Get the question type
    final question = survey.value?.questions.firstWhere(
      (q) => q.id == questionId,
      orElse: () => null as SurveyQuestion,
    );
    
    if (question == null) return;
    
    // Handle different value types based on question type
    switch (question.questionType) {
      case QuestionType.textBox:
      case QuestionType.comment:
        saveAnswer(textAnswer: value.toString());
        break;
      case QuestionType.numeric:
        try {
          final numValue = double.parse(value.toString());
          saveAnswer(numericAnswer: numValue);
        } catch (e) {
          saveAnswer(textAnswer: value.toString());
        }
        break;
      case QuestionType.date:
        if (value is DateTime) {
          saveAnswer(dateAnswer: value);
        } else {
          saveAnswer(textAnswer: value.toString());
        }
        break;
      case QuestionType.dropDown:
      case QuestionType.radioButton:
        saveAnswer(textAnswer: value.toString());
        break;
      case QuestionType.checkBox:
      case QuestionType.multiSelect:
        if (value is List) {
          // Join list values with comma for multiple selections
          saveAnswer(textAnswer: value.join(','));
        } else {
          saveAnswer(textAnswer: value.toString());
        }
        break;
      case QuestionType.fileUpload:
        saveAnswer(textAnswer: value.toString());
        break;
      case QuestionType.rating:
        try {
          final numValue = double.parse(value.toString());
          saveAnswer(numericAnswer: numValue);
        } catch (e) {
          saveAnswer(textAnswer: value.toString());
        }
        break;
      default:
        saveAnswer(textAnswer: value.toString());
    }
  }
  
  /// Get all answers as a map
  Map<int, dynamic>? getAnswers() {
    if (answers.isEmpty) return null;
    return answers;
  }
  
  /// Submit the survey with all answers
  Future<bool> submitSurvey({
    int incidentId = 1,
    int? respondentId,
    String? respondentEmail,
    int languageId = AppConstants.defaultLanguageId,
  }) async {
    if (survey.value == null) return false;
    
    try {
      isSubmitting.value = true;
      
      // Check for required questions
      final unansweredRequiredQuestions = survey.value!.questions
          .where((question) => question.isRequired && !answers.containsKey(question.id))
          .toList();
      
      if (unansweredRequiredQuestions.isNotEmpty) {
        Get.snackbar(
          'Validation Error',
          'Please answer all required questions',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
        );
        return false;
      }
      
      // Create survey submit object
      final surveySubmit = SurveySubmit(
        surveyId: survey.value!.id,
        incidentId: incidentId,
        respondentId: respondentId,
        respondentEmail: respondentEmail,
        languageId: languageId,
        answers: answers.values.cast<SurveySubmitAnswer>().toList(),
      );
      
      // Submit the survey
      final result = await _surveyService.submitSurvey(surveySubmit);
      
      if (result) {
        isCompleted.value = true;
        Get.snackbar(
          'Success',
          AppConstants.surveyCompleteText,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[100],
        );
      } else {
        Get.snackbar(
          'Error',
          AppConstants.serverError,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
        );
      }
      
      return result;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit survey: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
  
  /// Reset the survey state
  void resetSurvey() {
    currentQuestionIndex.value = 0;
    answers.clear();
    isCompleted.value = false;
  }
}
