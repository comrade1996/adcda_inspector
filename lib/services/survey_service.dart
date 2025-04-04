import 'dart:convert';
import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/models/api_response.dart';
import 'package:adcda_inspector/models/question_type.dart';
import 'package:adcda_inspector/models/survey.dart';
import 'package:adcda_inspector/models/survey_detail.dart';
import 'package:adcda_inspector/models/survey_dto.dart' as dto;
import 'package:adcda_inspector/models/survey_submit.dart';
import 'package:adcda_inspector/models/start_survey_request.dart' as start_request;
import 'package:adcda_inspector/services/api_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:adcda_inspector/utils/api_config.dart';

/// Service for handling survey-related API operations and data loading
class SurveyService {
  final ApiService _apiService;

  SurveyService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Fetch all available surveys
  Future<List<dto.SurveyDTO>> fetchAllSurveys({int languageId = AppConstants.defaultLanguageId}) async {
    try {
      // Make sure the languageId is explicitly passed as a query parameter
      final String endpoint = ApiConfig.surveysEndpoint;
      print('GET Request to: $endpoint?languageId=$languageId');
      
      final response = await _apiService.get(
        endpoint,
        queryParams: {'languageId': languageId},
      );
      
      // Add extra logging for debugging Urdu responses
      if (languageId == AppConstants.urduLanguageId) {
        print('Urdu language response type: ${response.runtimeType}');
        print('Urdu language response content: $response');
      }
      
      if (response == null) {
        print('Received null response from API, returning empty list');
        return [];
      } else if (response is List) {
        return response.map((item) => dto.SurveyDTO.fromJson(item ?? {})).toList();
      } else if (response is Map) {
        if (response['data'] is List) {
          return (response['data'] as List).map((item) => dto.SurveyDTO.fromJson(item ?? {})).toList();
        } else if (response['data'] == null) {
          // Handle case when data is null
          print('Response data field is null, returning empty list');
          return [];
        }
      }
      
      print('Could not parse survey response, returning empty list');
      return [];
    } catch (e) {
      print('Error in fetchAllSurveys: $e');
      throw Exception('Error fetching surveys: $e');
    }
  }

  /// Fetch detailed survey by ID
  Future<Survey> fetchSurvey(int surveyId, {int languageId = AppConstants.defaultLanguageId}) async {
    try {
      // Make sure the languageId is explicitly passed as a query parameter
      final String endpoint = ApiConfig.getSurveyDetailEndpoint(surveyId);
      print('GET Request to: $endpoint?languageId=$languageId');
      
      final response = await _apiService.get(
        endpoint,
        queryParams: {'languageId': languageId},
      );
      
      // Add extra logging for debugging Urdu responses
      if (languageId == AppConstants.urduLanguageId) {
        print('Urdu language survey response type: ${response.runtimeType}');
        print('Urdu language survey response content: $response');
      }
      
      if (response == null) {
        throw Exception('Received null response from API');
      } else if (response is Map<String, dynamic>) {
        return _convertApiResponseToSurvey(response);
      } else if (response is String) {
        try {
          final jsonData = json.decode(response);
          return _convertApiResponseToSurvey(jsonData);
        } catch (e) {
          print('Error decoding response string: $e');
          throw Exception('Invalid response format: $e');
        }
      }
      
      throw Exception('Unexpected response format from API');
    } catch (e) {
      print('Error in fetchSurvey: $e');
      throw Exception('Error fetching survey: $e');
    }
  }
  
  /// Convert API response to Survey model - FIXED VERSION
  Survey _convertApiResponseToSurvey(Map<String, dynamic> data) {
    List<SurveyQuestion> questions = [];
    
    if (data['questions'] != null && data['questions'] is List) {
      for (var q in data['questions']) {
        if (q == null) continue;
        
        // CRITICAL: Parse answers array from the API
        List<SurveyAnswer> answers = [];
        if (q['answers'] != null && q['answers'] is List) {
          for (var a in q['answers']) {
            if (a == null) continue;
            answers.add(SurveyAnswer(
              id: a['id'] ?? 0,
              answer: a['answer'] ?? '',
              icon: a['icon'],
              sortOrder: a['sortOrder'] ?? 0,
            ));
          }
          print('Parsed ${answers.length} answers for question ${q['id']}');
        }
        
        // DETERMINE QUESTION TYPE - DIRECT MAPPING FROM SERVER ENUM
        QuestionType questionType;
        
        // Get the type from the API directly
        int apiType = 0;
        if (q['questionType'] is int) {
          apiType = q['questionType'];
        } else if (q['questionType'] is String && q['questionType'].toString().isNotEmpty) {
          apiType = int.tryParse(q['questionType'].toString()) ?? 0;
        }
        
        // Direct mapping from server enum
        switch (apiType) {
          case 1: questionType = QuestionType.checkBox; break;
          case 2: questionType = QuestionType.radioButton; break;
          case 3: questionType = QuestionType.textBox; break;
          case 4: questionType = QuestionType.dropDown; break;
          case 5: questionType = QuestionType.multiSelect; break;
          case 6: questionType = QuestionType.rating; break;
          case 7: questionType = QuestionType.date; break;
          case 8: questionType = QuestionType.numeric; break;
          case 9: questionType = QuestionType.fileUpload; break;
          case 10: questionType = QuestionType.comment; break;
          default: questionType = QuestionType.textBox; // Default
        }
        
        // Add the question to our list
        questions.add(SurveyQuestion(
          id: q['id'] ?? 0,
          question: q['questionText'] ?? '',
          helpText: q['helpText'] as String?,
          questionType: questionType,
          isRequired: q['isRequired'] == true,
          allowMultipleAnswers: q['allowMultipleAnswers'] == true,
          validValues: null, // Set to null, we're not using validValues anymore
          answers: answers,
          sortOrder: q['order'] as int? ?? 0,
        ));
      }
    }
    
    return Survey(
      id: data['id'] ?? 0,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      questions: questions,
    );
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
            questionType: QuestionType.radioButton,
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

  /// Start a new survey submission
  Future<String?> startSurvey(start_request.StartSurveyRequest request) async {
    try {
      print('Starting new survey submission: ${request.toJson()}');
      final response = await _apiService.post(
        ApiConfig.startSurveyEndpoint,
        data: request.toJson(),
      );

      if (response == null) {
        print('Received null response from startSurvey API');
        return null;
      }

      print('Start survey response: $response');
      
      // Response format should be { "submissionGuid": "guid" } or similar
      if (response is Map<String, dynamic>) {
        if (response.containsKey('submissionGuid')) {
          return response['submissionGuid'];
        }
        
        // Try alternate key names that might be used
        if (response.containsKey('SubmissionGuid')) {
          return response['SubmissionGuid'];
        }
        
        // If there's only one key-value pair, assume it's the GUID
        if (response.length == 1) {
          return response.values.first?.toString();
        }
      }
      
      print('Could not extract submission GUID from response: $response');
      return null;
    } catch (e) {
      print('Error starting survey: $e');
      return null;
    }
  }

  /// Submit a survey with answers
  Future<bool> submitSurveyWithGuid(String guid, SurveySubmit submit) async {
    try {
      print('Submitting survey with GUID: $guid');
      print('Submission data: ${json.encode(submit.toJson())}');
      
      final response = await _apiService.post(
        ApiConfig.getSubmitEndpoint(guid),
        data: submit.toJson(),
      );

      print('Survey submission response: $response');
      
      if (response == null) {
        print('Received null response from submitSurveyWithGuid API');
        return false;
      }
      
      // Consider any non-error response as success
      return true;
    } catch (e) {
      print('Error submitting survey: $e');
      return false;
    }
  }

  /// Get survey submission details
  Future<Survey?> getSurveySubmission(String guid, {int languageId = 1}) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.baseUrl}/SurveySubmissions/$guid',
        queryParams: {'languageId': languageId},
      );

      if (response.statusCode == 200) {
        return Survey.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error getting survey submission: $e');
      return null;
    }
  }

  /// Fetch mock survey for testing and development
  Future<Survey> fetchMockSurvey() async {
    final String surveyJson = await rootBundle.loadString('assets/data/mock_survey.json');
    final Map<String, dynamic> surveyData = json.decode(surveyJson);
    return Survey.fromJson(surveyData);
  }

  /// Submit survey answers
  Future<bool> submitSurvey(Map<String, dynamic> submitData) async {
    try {
      final String endpoint = ApiConfig.submitEndpoint;
      print('POST Request to: $endpoint');
      print('Survey data: ${json.encode(submitData)}');
      
      final response = await _apiService.post(
        endpoint,
        data: submitData,
      );
      
      if (response is Map && response.containsKey('success')) {
        return response['success'] == true;
      }
      
      // Consider it successful if we don't get an explicit error
      return true;
    } catch (e) {
      print('Error in submitSurvey: $e');
      return false;
    }
  }

  /// Check if a survey has already been submitted
  Future<bool> checkSurveySubmission(int surveyId, int? respondentId) async {
    if (respondentId == null) {
      return false; // Cannot check without respondent ID
    }
    
    try {
      final String endpoint = ApiConfig.checkSubmissionEndpoint;
      print('GET Request to: $endpoint?surveyId=$surveyId&respondentId=$respondentId');
      
      final response = await _apiService.get(
        endpoint,
        queryParams: {
          'surveyId': surveyId,
          'respondentId': respondentId,
        },
      );
      
      if (response is bool) {
        return response;
      } else if (response is Map) {
        if (response.containsKey('data') && response['data'] is bool) {
          return response['data'];
        } else if (response.containsKey('submitted')) {
          return response['submitted'] == true;
        } else if (response.containsKey('exists')) {
          return response['exists'] == true;
        }
      }
      
      return false;
    } catch (e) {
      print('Error in checkSurveySubmission: $e');
      return false;
    }
  }
  
  /// Get all submissions for a specific survey
  Future<List<dto.SurveySubmissionDTO>> getSurveySubmissions(int surveyId) async {
    try {
      final String endpoint = ApiConfig.getSubmissionsBySurveyEndpoint(surveyId);
      print('GET Request to: $endpoint');
      
      final response = await _apiService.get(endpoint);
      
      if (response is List) {
        return response.map((item) => dto.SurveySubmissionDTO.fromJson(item)).toList();
      } else if (response is Map && response['data'] is List) {
        return (response['data'] as List).map((item) => dto.SurveySubmissionDTO.fromJson(item)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error in getSurveySubmissions: $e');
      return [];
    }
  }
}
