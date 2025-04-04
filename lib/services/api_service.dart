import 'dart:convert';
import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/models/api_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized API service for handling all HTTP requests
class ApiService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  ApiService({Dio? dio}) 
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: AppConstants.baseApiUrl,
          connectTimeout: Duration(seconds: 30),
          receiveTimeout: Duration(seconds: 30),
          contentType: 'application/json',
          responseType: ResponseType.json,
        ));

  /// Get authentication token and add to headers
  Future<Map<String, dynamic>> _getAuthHeaders() async {
    final token = await _secureStorage.read(key: 'access_token');
    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  /// Perform a GET request
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams, Map<String, dynamic>? headers}) async {
    try {
      // Add auth headers if not provided
      final authHeaders = await _getAuthHeaders();
      final mergedHeaders = {...authHeaders, ...?headers};

      // Ensure endpoint starts with '/' if it doesn't include the full URL
      final String url = endpoint.startsWith('http') 
          ? endpoint 
          : endpoint.startsWith('/') 
              ? '${AppConstants.baseApiUrl}$endpoint'
              : '${AppConstants.baseApiUrl}/$endpoint';
      
      print('GET Request to: $url, Query params: $queryParams');
      
      final response = await _dio.get(
        url,
        queryParameters: queryParams,
        options: Options(headers: mergedHeaders),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');
      
      return _handleResponse(response);
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Make a POST request to the specified endpoint
  Future<dynamic> post(String endpoint, {
    Map<String, dynamic>? queryParams,
    dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    try {
      // Add auth headers if not provided
      final authHeaders = await _getAuthHeaders();
      final mergedHeaders = {
        'Content-Type': 'application/json',
        ...authHeaders,
        ...?headers?.map((key, value) => MapEntry(key, value.toString())),
      };

      // Ensure endpoint starts with '/' if it doesn't include the full URL
      final String url = endpoint.startsWith('http') 
          ? endpoint 
          : '${AppConstants.baseApiUrl}$endpoint';
      
      print('POST Request to: $url, Query params: $queryParams, Data: ${jsonEncode(data)}');
      
      final response = await _dio.post(
        url,
        queryParameters: queryParams,
        data: data,
        options: Options(headers: mergedHeaders),
      );
      
      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');
      
      return _handleResponse(response);
    } on DioException catch (e) {
      print('Error Status: ${e.response?.statusCode}');
      print('Error Data: ${e.response?.data}');
      throw Exception('Error making POST request: ${e.message}');
    } catch (e) {
      print('Unexpected error in POST request: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  /// Handle response and extract data
  dynamic _handleResponse(Response response) {
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      final data = response.data;
      
      // Check if the response follows the API wrapper structure
      if (data is Map && data.containsKey('success') && data.containsKey('data')) {
        // Check if the API call was successful according to the wrapper
        if (data['success'] == true) {
          return data; // Return the whole response with success, message, and data
        } else {
          // If API indicates failure, throw an exception with the message
          final message = data['message'] ?? 'API returned failure status';
          throw Exception(message);
        }
      }
      
      // Response doesn't follow the wrapper structure, return as is
      return data;
    } else {
      throw Exception('Request failed with status code ${response.statusCode}');
    }
  }

  /// Handle error response
  void _handleError(DioException error) {
    if (error.response != null) {
      print('Error Status: ${error.response!.statusCode}');
      print('Error Data: ${error.response!.data}');
      
      // Check for 401 Unauthorized error (expired token)
      if (error.response!.statusCode == 401) {
        // We will let the auth service handle token refresh
      }
      
      // Try to parse error message from API response if available
      if (error.response!.data is Map) {
        final data = error.response!.data as Map;
        if (data.containsKey('message')) {
          throw Exception(data['message']);
        }
      }
    } else {
      print('Error Message: ${error.message}');
    }
    
    throw Exception('${error.message}. ${error.response?.data?['message'] ?? ''}');
  }
}
