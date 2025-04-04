import 'package:adcda_inspector/models/question_type.dart';

/// Survey detail model to match the API response
class SurveyDetailDTO {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final List<SurveyQuestionDetailDTO>? questions;

  SurveyDetailDTO({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    this.questions,
  });

  factory SurveyDetailDTO.fromJson(Map<String, dynamic> json) {
    return SurveyDetailDTO(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      isActive: json['isActive'] ?? false,
      questions: json['questions'] != null
          ? List<SurveyQuestionDetailDTO>.from(
              json['questions'].map((q) => SurveyQuestionDetailDTO.fromJson(q)))
          : null,
    );
  }
}

/// Survey question detail model
class SurveyQuestionDetailDTO {
  final int id;
  final String questionText;
  final String? helpText;
  final int questionTypeId;
  final bool isRequired;
  final int sortOrder;
  final List<SurveyAnswerDetailDTO>? answers;

  SurveyQuestionDetailDTO({
    required this.id,
    required this.questionText,
    this.helpText,
    required this.questionTypeId,
    required this.isRequired,
    required this.sortOrder,
    this.answers,
  });

  factory SurveyQuestionDetailDTO.fromJson(Map<String, dynamic> json) {
    return SurveyQuestionDetailDTO(
      id: json['id'],
      questionText: json['questionText'] ?? '',
      helpText: json['helpText'],
      questionTypeId: json['questionTypeId'] ?? 1,
      isRequired: json['isRequired'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
      answers: json['answers'] != null
          ? List<SurveyAnswerDetailDTO>.from(
              json['answers'].map((a) => SurveyAnswerDetailDTO.fromJson(a)))
          : null,
    );
  }

  /// Convert questionTypeId to QuestionType enum
  QuestionType get questionType {
    switch (questionTypeId) {
      case 1:
        return QuestionType.checkBox;
      case 2:
        return QuestionType.radioButton;
      case 3:
        return QuestionType.textBox;
      case 4:
        return QuestionType.dropDown;
      case 5:
        return QuestionType.multiSelect;
      default:
        return QuestionType.textBox;
    }
  }
}

/// Survey answer detail model
class SurveyAnswerDetailDTO {
  final int id;
  final String answerText;
  final int sortOrder;

  SurveyAnswerDetailDTO({
    required this.id,
    required this.answerText,
    required this.sortOrder,
  });

  factory SurveyAnswerDetailDTO.fromJson(Map<String, dynamic> json) {
    return SurveyAnswerDetailDTO(
      id: json['id'],
      answerText: json['answerText'] ?? '',
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

/// Survey list item model
class SurveyDTO {
  final int id;
  final String name;
  final String? description;
  final bool isActive;

  SurveyDTO({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
  });

  factory SurveyDTO.fromJson(Map<String, dynamic> json) {
    return SurveyDTO(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      isActive: json['isActive'] ?? false,
    );
  }
}

/// Survey submission model
class SurveySubmitDTO {
  final String guid;
  final List<SurveyAnswerSubmitDTO> answers;

  SurveySubmitDTO({
    required this.guid,
    required this.answers,
  });

  Map<String, dynamic> toJson() {
    return {
      'guid': guid,
      'answers': answers.map((answer) => answer.toJson()).toList(),
    };
  }
}

/// Answer submission model
class SurveyAnswerSubmitDTO {
  final int questionId;
  final List<int> answerIds;
  final String? textAnswer;

  SurveyAnswerSubmitDTO({
    required this.questionId,
    required this.answerIds,
    this.textAnswer,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'answerIds': answerIds,
      'textAnswer': textAnswer,
    };
  }
}

/// Start survey request model
class StartSurveyRequest {
  final int surveyId;
  final String? respondentEmail;
  final String? respondentName;
  final int languageId;

  StartSurveyRequest({
    required this.surveyId,
    this.respondentEmail,
    this.respondentName,
    required this.languageId,
  });

  Map<String, dynamic> toJson() {
    return {
      'surveyId': surveyId,
      'respondentEmail': respondentEmail,
      'respondentName': respondentName,
      'languageId': languageId,
    };
  }
}
