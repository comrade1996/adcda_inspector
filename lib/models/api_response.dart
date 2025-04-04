/// Generic API response model
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;
  final List<String>? errors;

  ApiResponse({
    required this.success,
    this.message = '',
    this.data,
    this.statusCode,
    this.errors,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJson) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJson != null ? fromJson(json['data']) : null,
      statusCode: json['statusCode'],
      errors: json['errors'] != null
          ? List<String>.from(json['errors'].map((e) => e.toString()))
          : null,
    );
  }

  factory ApiResponse.success(T? data, {String message = 'Success'}) {
    return ApiResponse(
      success: true,
      message: message,
      data: data,
      statusCode: 200,
    );
  }

  factory ApiResponse.error(String message, {List<String>? errors, int? statusCode}) {
    return ApiResponse(
      success: false,
      message: message,
      errors: errors,
      statusCode: statusCode ?? 400,
    );
  }
}
