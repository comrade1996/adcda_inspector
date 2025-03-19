import 'dart:convert';
import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/models/question_type.dart';
import 'package:adcda_inspector/models/survey.dart';
import 'package:adcda_inspector/models/survey_submit.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Service for handling survey-related API operations and data loading
class SurveyService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Fetch survey from the server
  Future<Survey> fetchSurvey(int surveyId, int languageId) async {
    try {
      final response = await _dio.get(
        '${AppConstants.surveyEndpoint}/$surveyId',
        queryParameters: {'languageId': languageId},
      );
      
      return Survey.fromJson(response.data);
    } catch (e) {
      // Fallback to load from local JSON if API fails
      return loadLocalSurvey();
    }
  }

  /// Load survey data from local JSON file
  Future<Survey> loadLocalSurvey() async {
    try {
      final jsonString = await rootBundle.loadString('assets/survey_data.json');
      final jsonData = json.decode(jsonString);
      return Survey.fromJson(jsonData);
    } catch (e) {
      // Create a default survey with sample data if local JSON also fails
      return Survey(
        id: 1,
        name: 'نموذج تقييم جاهزية مراكز الدفاع المدني',
        description: 'This is a sample survey',
        questions: [
          SurveyQuestion(
            id: 1,
            question: 'How would you rate your experience?',
            helpText: 'Please select a rating from 1 to 5',
            questionType: QuestionType.rating,
            isRequired: true,
            sortOrder: 1,
            answers: List.generate(
              5,
              (index) => SurveyAnswer(
                id: index + 1,
                answer: (index + 1).toString(),
                sortOrder: index + 1,
              ),
            ),
          ),
        ],
      );
    }
  }

  /// Submit survey answers to the server
  Future<bool> submitSurvey(SurveySubmit surveySubmit) async {
    try {
      await _dio.post(
        AppConstants.submitEndpoint,
        data: surveySubmit.toJson(),
      );
      return true;
    } catch (e) {
      // Handle error and return false to indicate failure
      print('Error submitting survey: $e');
      return false;
    }
  }
}
