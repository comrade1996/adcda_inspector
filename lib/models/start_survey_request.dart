/// Represents a request to start a new survey
class StartSurveyRequest {
  final int surveyId;
  final int incidentId; // This field is required by the API but will always be set to 0
  final int? respondentId;
  final String? respondentEmail;
  final int languageId;
  final double? latitude;
  final double? longitude;
  final String? deviceType;

  StartSurveyRequest({
    required this.surveyId,
    required this.incidentId, // Required but will always be 0
    this.respondentId,
    this.respondentEmail,
    required this.languageId,
    this.latitude,
    this.longitude,
    this.deviceType,
  });

  factory StartSurveyRequest.fromJson(Map<String, dynamic> json) {
    return StartSurveyRequest(
      surveyId: json['surveyId'] as int,
      incidentId: json['incidentId'] as int,
      respondentId: json['respondentId'] as int?,
      respondentEmail: json['respondentEmail'] as String?,
      languageId: json['languageId'] as int,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      deviceType: json['deviceType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'surveyId': surveyId,
      'incidentId': incidentId, // Always will be 0
      'languageId': languageId,
    };

    if (respondentId != null) {
      json['respondentId'] = respondentId;
    }
    
    if (respondentEmail != null) {
      json['respondentEmail'] = respondentEmail;
    }
    
    if (latitude != null) {
      json['latitude'] = latitude;
    }
    
    if (longitude != null) {
      json['longitude'] = longitude;
    }
    
    if (deviceType != null) {
      json['deviceType'] = deviceType;
    }
    
    return json;
  }
}
