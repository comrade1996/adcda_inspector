/// Represents a survey submission with answers
class SurveySubmit {
  final int surveyId;
  final int incidentId;
  final int? respondentId;
  final String? respondentEmail;
  final int languageId;
  final List<SurveySubmitAnswer> answers;
  final double? latitude;
  final double? longitude;
  final String? deviceType;

  SurveySubmit({
    required this.surveyId,
    this.incidentId = 0,
    this.respondentId,
    this.respondentEmail,
    required this.languageId,
    this.answers = const [],
    this.latitude,
    this.longitude,
    this.deviceType,
  });

  factory SurveySubmit.fromJson(Map<String, dynamic> json) {
    return SurveySubmit(
      surveyId: json['surveyId'] as int,
      incidentId: json['incidentId'] as int? ?? 0,
      respondentId: json['respondentId'] as int?,
      respondentEmail: json['respondentEmail'] as String?,
      languageId: json['languageId'] as int,
      answers: (json['answers'] as List<dynamic>?)
              ?.map((e) => SurveySubmitAnswer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      deviceType: json['deviceType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'surveyId': surveyId,
      'incidentId': incidentId,
      'languageId': languageId,
      'answers': answers.map((e) => e.toJson()).toList(),
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

/// Represents an answer to a survey question in a submission
class SurveySubmitAnswer {
  final int questionId;
  final int? answerId;
  final String? textAnswer;
  final double? numericAnswer;
  final DateTime? dateAnswer;
  final String? comments;

  SurveySubmitAnswer({
    required this.questionId,
    this.answerId,
    this.textAnswer,
    this.numericAnswer,
    this.dateAnswer,
    this.comments,
  });

  factory SurveySubmitAnswer.fromJson(Map<String, dynamic> json) {
    return SurveySubmitAnswer(
      questionId: json['questionId'] as int,
      answerId: json['answerId'] as int?,
      textAnswer: json['textAnswer'] as String?,
      numericAnswer: (json['numericAnswer'] as num?)?.toDouble(),
      dateAnswer: json['dateAnswer'] != null
          ? DateTime.parse(json['dateAnswer'] as String)
          : null,
      comments: json['comments'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'answerId': answerId,
      'textAnswer': textAnswer,
      'numericAnswer': numericAnswer,
      'dateAnswer': dateAnswer?.toIso8601String(),
      'comments': comments,
    };
  }
}
