import 'dart:convert';
import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/models/api_response.dart';
import 'package:dio/dio.dart';

/// Centralized API service for handling all HTTP requests
class ApiService {
  final Dio _dio;
  
  ApiService({Dio? dio}) 
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: AppConstants.baseApiUrl,
          connectTimeout: Duration(seconds: 30),
          receiveTimeout: Duration(seconds: 30),
          contentType: 'application/json',
          responseType: ResponseType.json,
        ));

  /// Perform a GET request
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams, Map<String, dynamic>? headers}) async {
    try {
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
        options: Options(headers: headers),
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
      // Ensure endpoint starts with '/' if it doesn't include the full URL
      final String url = endpoint.startsWith('http') 
          ? endpoint 
          : '${AppConstants.baseApiUrl}$endpoint';
      
      print('POST Request to: $url, Query params: $queryParams, Data: ${jsonEncode(data)}');
      
      final Map<String, String> requestHeaders = {
        'Content-Type': 'application/json',
        ...?headers?.map((key, value) => MapEntry(key, value.toString())),
      };
      
      final response = await _dio.post(
        url,
        queryParameters: queryParams,
        data: data,
        options: Options(headers: requestHeaders),
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
      if (response.data is Map && response.data.containsKey('data')) {
        // Return just the data part if it follows the ApiResponse format
        return response.data['data'];
      }
      return response.data;
    } else {
      throw Exception('Request failed with status code ${response.statusCode}');
    }
  }

  /// Handle error response
  void _handleError(DioException error) {
    if (error.response != null) {
      print('Error Status: ${error.response!.statusCode}');
      print('Error Data: ${error.response!.data}');
    } else {
      print('Error Message: ${error.message}');
    }
    
    throw Exception('${error.message}. ${error.response?.data?['message'] ?? ''}');
  }
}
