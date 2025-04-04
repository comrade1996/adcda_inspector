/// DTO class for transferring survey data from the API
class SurveyDTO {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final String? createdAt;

  SurveyDTO({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.createdAt,
  });

  factory SurveyDTO.fromJson(Map<String, dynamic> json) {
    // Handle empty or null json
    if (json == null || json.isEmpty) {
      return SurveyDTO(
        id: 0,
        name: 'Unnamed Survey',
        description: '',
        isActive: false,
        createdAt: null,
      );
    }
    
    // Safely extract and parse the id field, providing a fallback 
    int id;
    try {
      if (json['id'] == null) {
        id = 0;
      } else if (json['id'] is String) {
        id = int.tryParse(json['id']) ?? 0;
      } else if (json['id'] is int) {
        id = json['id'];
      } else {
        id = 0;
      }
    } catch (e) {
      print('Error parsing survey id: $e');
      id = 0;
    }
    
    return SurveyDTO(
      id: id,
      name: json['name'] ?? json['title'] ?? 'Unnamed Survey',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] ?? json['created'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}

/// DTO for survey submission answer, matching the API expectations
class SurveySubmitAnswerDTO {
  final int questionId;
  final int? answerId;
  final String? textAnswer;
  final double? numericAnswer;
  final DateTime? dateAnswer;
  final String? comments;

  SurveySubmitAnswerDTO({
    required this.questionId,
    this.answerId,
    this.textAnswer,
    this.numericAnswer,
    this.dateAnswer,
    this.comments,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      if (answerId != null) 'answerId': answerId,
      if (textAnswer != null) 'textAnswer': textAnswer,
      if (numericAnswer != null) 'numericAnswer': numericAnswer,
      if (dateAnswer != null) 'dateAnswer': dateAnswer?.toIso8601String(),
      if (comments != null) 'comments': comments,
    };
  }
  
  factory SurveySubmitAnswerDTO.fromJson(Map<String, dynamic> json) {
    return SurveySubmitAnswerDTO(
      questionId: json['questionId'],
      answerId: json['answerId'],
      textAnswer: json['textAnswer'],
      numericAnswer: json['numericAnswer'],
      dateAnswer: json['dateAnswer'] != null 
          ? DateTime.parse(json['dateAnswer']) 
          : null,
      comments: json['comments'],
    );
  }
}

/// DTO for complete survey submission, matching the API expectations
class SurveySubmitDTO {
  final int surveyId;
  final int incidentId;
  final int? respondentId;
  final String? respondentEmail;
  final int languageId;
  final List<SurveySubmitAnswerDTO> answers;
  
  SurveySubmitDTO({
    required this.surveyId,
    required this.incidentId,
    this.respondentId,
    this.respondentEmail,
    required this.languageId,
    required this.answers,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'surveyId': surveyId,
      'incidentId': incidentId,
      if (respondentId != null) 'respondentId': respondentId,
      if (respondentEmail != null) 'respondentEmail': respondentEmail,
      'languageId': languageId,
      'answers': answers.map((a) => a.toJson()).toList(),
    };
  }
  
  factory SurveySubmitDTO.fromJson(Map<String, dynamic> json) {
    return SurveySubmitDTO(
      surveyId: json['surveyId'],
      incidentId: json['incidentId'],
      respondentId: json['respondentId'],
      respondentEmail: json['respondentEmail'],
      languageId: json['languageId'],
      answers: (json['answers'] as List)
          .map((a) => SurveySubmitAnswerDTO.fromJson(a))
          .toList(),
    );
  }
}

/// DTO for survey submission response
class SurveySubmissionDTO {
  final String guid;
  final int surveyId;
  final int incidentId;
  final int? respondentId;
  final String? respondentEmail;
  final int languageId;
  final DateTime submittedAt;
  final List<SurveySubmitAnswerDTO>? answers;
  
  SurveySubmissionDTO({
    required this.guid,
    required this.surveyId,
    required this.incidentId,
    this.respondentId,
    this.respondentEmail,
    required this.languageId,
    required this.submittedAt,
    this.answers,
  });
  
  factory SurveySubmissionDTO.fromJson(Map<String, dynamic> json) {
    return SurveySubmissionDTO(
      guid: json['guid'],
      surveyId: json['surveyId'],
      incidentId: json['incidentId'],
      respondentId: json['respondentId'],
      respondentEmail: json['respondentEmail'],
      languageId: json['languageId'],
      submittedAt: json['submittedAt'] != null 
          ? DateTime.parse(json['submittedAt']) 
          : DateTime.now(),
      answers: json['answers'] != null 
          ? (json['answers'] as List)
              .map((a) => SurveySubmitAnswerDTO.fromJson(a))
              .toList()
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'guid': guid,
      'surveyId': surveyId,
      'incidentId': incidentId,
      if (respondentId != null) 'respondentId': respondentId,
      if (respondentEmail != null) 'respondentEmail': respondentEmail,
      'languageId': languageId,
      'submittedAt': submittedAt.toIso8601String(),
      if (answers != null) 'answers': answers!.map((a) => a.toJson()).toList(),
    };
  }
}
