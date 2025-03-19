import 'dart:convert';

import 'package:adcda_inspector/models/question_type.dart';
import 'package:adcda_inspector/models/survey.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Survey Models', () {
    test('QuestionType enum converts correctly from integer value', () {
      // Test conversion from integer values to QuestionType enum
      expect(QuestionType.fromInt(1), equals(QuestionType.checkBox));
      expect(QuestionType.fromInt(2), equals(QuestionType.radioButton));
      expect(QuestionType.fromInt(3), equals(QuestionType.textBox));
      expect(QuestionType.fromInt(4), equals(QuestionType.dropDown));
      expect(QuestionType.fromInt(5), equals(QuestionType.multiSelect));
      expect(QuestionType.fromInt(6), equals(QuestionType.rating));
      expect(QuestionType.fromInt(7), equals(QuestionType.date));
      expect(QuestionType.fromInt(8), equals(QuestionType.numeric));
      expect(QuestionType.fromInt(9), equals(QuestionType.fileUpload));
      expect(QuestionType.fromInt(10), equals(QuestionType.comment));
      
      // Test fallback for invalid value
      expect(QuestionType.fromInt(99), equals(QuestionType.textBox));
    });

    test('Survey model parses correctly from JSON', () {
      // Sample JSON data
      final String jsonData = '''
      {
        "id": 1,
        "name": "Test Survey",
        "description": "This is a test survey",
        "questions": [
          {
            "id": 1,
            "question": "Test Question",
            "helpText": "This is a help text",
            "questionType": 2,
            "isRequired": true,
            "allowMultipleAnswers": false,
            "sortOrder": 1,
            "answers": [
              {
                "id": 1,
                "answer": "Option 1",
                "sortOrder": 1
              },
              {
                "id": 2,
                "answer": "Option 2",
                "sortOrder": 2
              }
            ]
          }
        ]
      }
      ''';

      // Parse JSON
      final Map<String, dynamic> decodedJson = json.decode(jsonData);
      final Survey survey = Survey.fromJson(decodedJson);

      // Verify survey data
      expect(survey.id, equals(1));
      expect(survey.name, equals('Test Survey'));
      expect(survey.description, equals('This is a test survey'));
      expect(survey.questions.length, equals(1));

      // Verify question data
      final question = survey.questions.first;
      expect(question.id, equals(1));
      expect(question.question, equals('Test Question'));
      expect(question.helpText, equals('This is a help text'));
      expect(question.questionType, equals(QuestionType.radioButton));
      expect(question.isRequired, isTrue);
      expect(question.allowMultipleAnswers, isFalse);
      expect(question.sortOrder, equals(1));
      expect(question.answers.length, equals(2));

      // Verify answer data
      final answer1 = question.answers[0];
      final answer2 = question.answers[1];
      expect(answer1.id, equals(1));
      expect(answer1.answer, equals('Option 1'));
      expect(answer1.sortOrder, equals(1));
      expect(answer2.id, equals(2));
      expect(answer2.answer, equals('Option 2'));
      expect(answer2.sortOrder, equals(2));
    });

    test('Survey model converts correctly to JSON', () {
      // Create a survey object
      final survey = Survey(
        id: 1,
        name: 'Test Survey',
        description: 'This is a test survey',
        questions: [
          SurveyQuestion(
            id: 1,
            question: 'Test Question',
            helpText: 'This is a help text',
            questionType: QuestionType.radioButton,
            isRequired: true,
            sortOrder: 1,
            answers: [
              SurveyAnswer(
                id: 1,
                answer: 'Option 1',
                sortOrder: 1,
              ),
              SurveyAnswer(
                id: 2,
                answer: 'Option 2',
                sortOrder: 2,
              ),
            ],
          ),
        ],
      );

      // Convert to JSON
      final Map<String, dynamic> jsonMap = survey.toJson();

      // Verify JSON data
      expect(jsonMap['id'], equals(1));
      expect(jsonMap['name'], equals('Test Survey'));
      expect(jsonMap['description'], equals('This is a test survey'));
      expect(jsonMap['questions'], isA<List>());
      expect(jsonMap['questions'].length, equals(1));

      // Verify question data in JSON
      final questionJson = jsonMap['questions'][0];
      expect(questionJson['id'], equals(1));
      expect(questionJson['question'], equals('Test Question'));
      expect(questionJson['helpText'], equals('This is a help text'));
      expect(questionJson['questionType'], equals(2)); // RadioButton has value 2
      expect(questionJson['isRequired'], isTrue);
      expect(questionJson['sortOrder'], equals(1));
      expect(questionJson['answers'], isA<List>());
      expect(questionJson['answers'].length, equals(2));

      // Verify answer data in JSON
      final answer1Json = questionJson['answers'][0];
      final answer2Json = questionJson['answers'][1];
      expect(answer1Json['id'], equals(1));
      expect(answer1Json['answer'], equals('Option 1'));
      expect(answer1Json['sortOrder'], equals(1));
      expect(answer2Json['id'], equals(2));
      expect(answer2Json['answer'], equals('Option 2'));
      expect(answer2Json['sortOrder'], equals(2));
    });
  });
}
