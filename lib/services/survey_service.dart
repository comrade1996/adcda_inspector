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
import 'package:get/get.dart';

/// Service for handling survey-related API operations and data loading
class SurveyService extends GetxService {
  final ApiService _apiService;
  
  // Observable error message for UI display
  final RxString errorMessage = ''.obs;

  SurveyService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Fetch all available surveys
  Future<List<dto.SurveyDTO>> fetchAllSurveys({int languageId = AppConstants.defaultLanguageId}) async {
    try {
      errorMessage.value = '';
      // Make sure the languageId is explicitly passed as a query parameter
      final String endpoint = ApiConfig.surveysEndpoint;
      print('GET Request to: $endpoint?languageId=$languageId');
      
      final response = await _apiService.get(
        endpoint,
        queryParams: {'languageId': languageId},
      );
      
      // Check for wrapped API response format
      if (response is Map<String, dynamic>) {
        // Check for success flag
        if (response['success'] == true) {
          if (response['data'] is List) {
            return (response['data'] as List).map((item) => dto.SurveyDTO.fromJson(item ?? {})).toList();
          } else if (response['data'] == null) {
            print('Response data field is null, returning empty list');
            return [];
          }
        } else {
          // Handle error case
          errorMessage.value = response['message'] ?? 'Failed to fetch surveys';
          print('API error: ${errorMessage.value}');
          return [];
        }
      } 
      // Fallback for legacy response format
      else if (response is List) {
        return response.map((item) => dto.SurveyDTO.fromJson(item ?? {})).toList();
      }
      
      print('Could not parse survey response, returning empty list');
      return [];
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error in fetchAllSurveys: $e');
      return [];
    }
  }

  /// Fetch detailed survey by ID
  Future<Survey?> fetchSurvey(int surveyId, {int languageId = AppConstants.defaultLanguageId}) async {
    try {
      errorMessage.value = '';
      // Make sure the languageId is explicitly passed as a query parameter
      final String endpoint = ApiConfig.getSurveyDetailEndpoint(surveyId);
      print('GET Request to: $endpoint?languageId=$languageId');
      
      final response = await _apiService.get(
        endpoint,
        queryParams: {'languageId': languageId},
      );
      
      // Check for wrapped API response format
      if (response is Map<String, dynamic>) {
        // Check for success flag
        if (response.containsKey('success') && response.containsKey('data')) {
          if (response['success'] == true) {
            if (response['data'] != null) {
              return _convertApiResponseToSurvey(response['data']);
            } else {
              errorMessage.value = 'Survey data is empty';
              return null;
            }
          } else {
            // Handle error case
            errorMessage.value = response['message'] ?? 'Failed to fetch survey';
            print('API error: ${errorMessage.value}');
            return null;
          }
        } else {
          // Legacy format or direct data response
          return _convertApiResponseToSurvey(response);
        }
      } else if (response is String) {
        try {
          final jsonData = json.decode(response);
          return _convertApiResponseToSurvey(jsonData);
        } catch (e) {
          errorMessage.value = 'Invalid response format';
          print('Error decoding response string: $e');
          return null;
        }
      }
      
      errorMessage.value = 'Unexpected response format from API';
      return null;
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error in fetchSurvey: $e');
      return null;
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
      errorMessage.value = 'Error loading local survey data';
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
      errorMessage.value = '';
      print('Starting new survey submission: ${request.toJson()}');
      final response = await _apiService.post(
        ApiConfig.startSurveyEndpoint,
        data: request.toJson(),
      );

      if (response == null) {
        errorMessage.value = 'Received null response from server';
        return null;
      }

      print('Start survey response: $response');
      
      // Check for wrapped API response format
      if (response is Map<String, dynamic>) {
        if (response.containsKey('success')) {
          if (response['success'] == true) {
            // Modern API wrapper format
            if (response['data'] != null) {
              var data = response['data'];
              
              // Try to find the GUID in the response data
              if (data is Map<String, dynamic>) {
                if (data.containsKey('submissionGuid')) {
                  return data['submissionGuid'];
                }
                if (data.containsKey('SubmissionGuid')) {
                  return data['SubmissionGuid'];
                }
                if (data.containsKey('guid')) {
                  return data['guid'];
                }
                // If there's only one key-value pair, assume it's the GUID
                if (data.length == 1) {
                  return data.values.first?.toString();
                }
              } else if (data is String) {
                // If data is directly a string, it might be the GUID
                return data;
              }
            } else {
              errorMessage.value = 'Response data field is null';
            }
          } else {
            // API returned an error
            errorMessage.value = response['message'] ?? 'Failed to start survey';
            print('API error: ${errorMessage.value}');
          }
        }
        // Legacy format or direct response
        else if (response.containsKey('submissionGuid')) {
          return response['submissionGuid'];
        } else if (response.containsKey('SubmissionGuid')) {
          return response['SubmissionGuid'];
        } else if (response.length == 1) {
          return response.values.first?.toString();
        }
      }
      
      errorMessage.value = 'Could not extract submission GUID from response';
      print('Could not extract submission GUID from response: $response');
      return null;
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error starting survey: $e');
      return null;
    }
  }

  /// Submit a survey with answers
  Future<bool> submitSurveyWithGuid(String guid, SurveySubmit submit) async {
    try {
      errorMessage.value = '';
      print('Submitting survey with GUID: $guid');
      print('Submission data: ${json.encode(submit.toJson())}');
      
      final response = await _apiService.post(
        ApiConfig.getSubmitEndpoint(guid),
        data: submit.toJson(),
      );

      print('Survey submission response: $response');
      
      if (response == null) {
        errorMessage.value = 'Received null response from server';
        return false;
      }
      
      // Check for wrapped API response format
      if (response is Map<String, dynamic> && response.containsKey('success')) {
        if (response['success'] == true) {
          return true;
        } else {
          // API returned an error
          errorMessage.value = response['message'] ?? 'Failed to submit survey';
          print('API error: ${errorMessage.value}');
          return false;
        }
      }
      
      // Consider any non-error response as success for backwards compatibility
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error submitting survey: $e');
      return false;
    }
  }

  /// Get survey submission details
  Future<Survey?> getSurveySubmission(String guid, {int languageId = 1}) async {
    try {
      errorMessage.value = '';
      final response = await _apiService.get(
        '${ApiConfig.baseUrl}/SurveySubmissions/$guid',
        queryParams: {'languageId': languageId},
      );

      // Check for wrapped API response format
      if (response is Map<String, dynamic> && response.containsKey('success')) {
        if (response['success'] == true) {
          if (response['data'] != null) {
            return Survey.fromJson(response['data']);
          } else {
            errorMessage.value = 'Response data field is null';
            return null;
          }
        } else {
          // API returned an error
          errorMessage.value = response['message'] ?? 'Failed to get survey submission';
          print('API error: ${errorMessage.value}');
          return null;
        }
      } 
      // Legacy response format
      else if (response is Map<String, dynamic>) {
        return Survey.fromJson(response);
      }
      
      errorMessage.value = 'Invalid response format from server';
      return null;
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error getting survey submission: $e');
      return null;
    }
  }

  /// Fetch mock survey for testing and development
  Future<Survey> fetchMockSurvey() async {
    try {
      final String surveyJson = await rootBundle.loadString('assets/data/mock_survey.json');
      final Map<String, dynamic> surveyData = json.decode(surveyJson);
      return Survey.fromJson(surveyData);
    } catch (e) {
      errorMessage.value = 'Error loading mock survey data';
      print('Error loading mock survey: $e');
      // Return empty survey on error
      return Survey(id: 0, name: '', description: '', questions: []);
    }
  }

  /// Submit survey answers
  Future<bool> submitSurvey(Map<String, dynamic> submitData) async {
    try {
      errorMessage.value = '';
      final String endpoint = ApiConfig.submitEndpoint;
      print('POST Request to: $endpoint');
      print('Survey data: ${json.encode(submitData)}');
      
      final response = await _apiService.post(
        endpoint,
        data: submitData,
      );
      
      // Check for wrapped API response format
      if (response is Map<String, dynamic> && response.containsKey('success')) {
        if (response['success'] == true) {
          return true;
        } else {
          // API returned an error
          errorMessage.value = response['message'] ?? 'Failed to submit survey';
          print('API error: ${errorMessage.value}');
          return false;
        }
      }
      
      // Consider it successful if we don't get an explicit error for backwards compatibility
      return true;
    } catch (e) {
      errorMessage.value = e.toString();
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
      errorMessage.value = '';
      final String endpoint = ApiConfig.checkSubmissionEndpoint;
      print('GET Request to: $endpoint?surveyId=$surveyId&respondentId=$respondentId');
      
      final response = await _apiService.get(
        endpoint,
        queryParams: {
          'surveyId': surveyId,
          'respondentId': respondentId,
        },
      );
      
      // Check for wrapped API response format
      if (response is Map<String, dynamic> && response.containsKey('success')) {
        if (response['success'] == true) {
          if (response['data'] is bool) {
            return response['data'];
          } else if (response['data'] is Map) {
            final data = response['data'] as Map;
            if (data.containsKey('submitted')) {
              return data['submitted'] == true;
            } else if (data.containsKey('exists')) {
              return data['exists'] == true;
            }
          }
          return false;
        } else {
          // API returned an error
          errorMessage.value = response['message'] ?? 'Failed to check survey submission';
          print('API error: ${errorMessage.value}');
          return false;
        }
      } 
      // Legacy response formats
      else if (response is bool) {
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
      errorMessage.value = e.toString();
      print('Error in checkSurveySubmission: $e');
      return false;
    }
  }
  
  /// Get all submissions for a specific survey
  Future<List<dto.SurveySubmissionDTO>> getSurveySubmissions(int surveyId) async {
    try {
      errorMessage.value = '';
      final String endpoint = ApiConfig.getSubmissionsBySurveyEndpoint(surveyId);
      print('GET Request to: $endpoint');
      
      final response = await _apiService.get(endpoint);
      
      // Check for wrapped API response format
      if (response is Map<String, dynamic> && response.containsKey('success')) {
        if (response['success'] == true) {
          if (response['data'] is List) {
            return (response['data'] as List).map((item) => dto.SurveySubmissionDTO.fromJson(item)).toList();
          } else {
            errorMessage.value = 'Response data is not a list';
            return [];
          }
        } else {
          // API returned an error
          errorMessage.value = response['message'] ?? 'Failed to get survey submissions';
          print('API error: ${errorMessage.value}');
          return [];
        }
      } 
      // Legacy response formats
      else if (response is List) {
        return response.map((item) => dto.SurveySubmissionDTO.fromJson(item)).toList();
      }
      
      errorMessage.value = 'Invalid response format from server';
      return [];
    } catch (e) {
      errorMessage.value = e.toString();
      print('Error in getSurveySubmissions: $e');
      return [];
    }
  }
  
  /// Clear current error message
  void clearError() {
    errorMessage.value = '';
  }
}
