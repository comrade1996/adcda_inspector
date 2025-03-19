import 'package:adcda_inspector/models/question_type.dart';

/// Represents a survey with questions and other details
class Survey {
  final int id;
  final String? name;
  final String? description;
  final List<SurveyQuestion> questions;

  Survey({
    required this.id,
    this.name,
    this.description,
    this.questions = const [],
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      id: json['id'] as int,
      name: json['name'] as String?,
      description: json['description'] as String?,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => SurveyQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'questions': questions.map((e) => e.toJson()).toList(),
    };
  }
}

/// Represents a survey question with answers and validation rules
class SurveyQuestion {
  final int id;
  final String? question;
  final String? helpText;
  final QuestionType questionType;
  final bool isRequired;
  final bool allowMultipleAnswers;
  final int sortOrder;
  final List<SurveyAnswer> answers;
  final String? validationRegex;
  final String? validationMessage;
  
  // New properties to support UI enhancements
  final List<ValidValue>? validValues;
  final OptionsOrientation? orientation;
  final String? placeholder;
  final bool? multiline;

  SurveyQuestion({
    required this.id,
    this.question,
    this.helpText,
    required this.questionType,
    this.isRequired = false,
    this.allowMultipleAnswers = false,
    this.sortOrder = 0,
    this.answers = const [],
    this.validationRegex,
    this.validationMessage,
    this.validValues,
    this.orientation,
    this.placeholder,
    this.multiline,
  });

  // Getter for backward compatibility
  bool get required => isRequired ?? false;

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    return SurveyQuestion(
      id: json['id'] as int,
      question: json['question'] as String?,
      helpText: json['helpText'] as String?,
      questionType: QuestionType.fromInt(json['questionType'] as int),
      isRequired: json['isRequired'] as bool? ?? false,
      allowMultipleAnswers: json['allowMultipleAnswers'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
      answers: (json['answers'] as List<dynamic>?)
              ?.map((e) => SurveyAnswer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      validationRegex: json['validationRegex'] as String?,
      validationMessage: json['validationMessage'] as String?,
      validValues: (json['validValues'] as List<dynamic>?)
              ?.map((e) => ValidValue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          null,
      orientation: json['orientation'] == null
          ? null
          : OptionsOrientation.values[json['orientation'] as int],
      placeholder: json['placeholder'] as String?,
      multiline: json['multiline'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'helpText': helpText,
      'questionType': questionType.value,
      'isRequired': isRequired,
      'allowMultipleAnswers': allowMultipleAnswers,
      'sortOrder': sortOrder,
      'answers': answers.map((e) => e.toJson()).toList(),
      'validationRegex': validationRegex,
      'validationMessage': validationMessage,
      'validValues': validValues?.map((e) => e.toJson()).toList() ?? null,
      'orientation': orientation?.index,
      'placeholder': placeholder,
      'multiline': multiline,
    };
  }
}

/// Represents an answer option for a survey question
class SurveyAnswer {
  final int id;
  final String? answer;
  final String? icon;
  final int sortOrder;
  final int? score;

  SurveyAnswer({
    required this.id,
    this.answer,
    this.icon,
    this.sortOrder = 0,
    this.score,
  });

  factory SurveyAnswer.fromJson(Map<String, dynamic> json) {
    return SurveyAnswer(
      id: json['id'] as int,
      answer: json['answer'] as String?,
      icon: json['icon'] as String?,
      sortOrder: json['sortOrder'] as int? ?? 0,
      score: json['score'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'answer': answer,
      'icon': icon,
      'sortOrder': sortOrder,
      'score': score,
    };
  }
}

class ValidValue {
  final String? value;
  final String? text;

  ValidValue({
    this.value,
    this.text,
  });

  factory ValidValue.fromJson(Map<String, dynamic> json) {
    return ValidValue(
      value: json['value'] as String?,
      text: json['text'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'text': text,
    };
  }
}

enum OptionsOrientation { horizontal, vertical }
