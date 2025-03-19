import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/models/question_type.dart';
import 'package:adcda_inspector/models/survey.dart';
import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

/// Utility class for handling validation logic
class ValidationUtils {
  /// Generate validators based on question properties
  static dynamic getValidators(SurveyQuestion question) {
    List<FormFieldValidator<dynamic>> validators = [];

    // Add required validator if needed
    if (question.isRequired) {
      validators.add(
        FormBuilderValidators.required(
              errorText:
                  question.validationMessage ?? AppConstants.requiredField,
            )
            as FormFieldValidator<dynamic>,
      );
    }

    // Add custom regex validator if provided
    if (question.validationRegex != null &&
        question.validationRegex!.isNotEmpty) {
      validators.add(
        ((value) {
              if (value == null || value.toString().isEmpty) {
                return null; // Skip regex validation for empty values (already handled by required validator)
              }

              try {
                final regex = RegExp(question.validationRegex!);
                if (!regex.hasMatch(value.toString())) {
                  return question.validationMessage ??
                      AppConstants.validationError;
                }
              } catch (e) {
                print('Invalid regex pattern: ${question.validationRegex}');
              }
              return null;
            })
            as FormFieldValidator<dynamic>,
      );
    }

    // Add type-specific validators
    switch (question.questionType) {
      case QuestionType.numeric:
        validators.add(
          FormBuilderValidators.numeric(errorText: AppConstants.invalidNumber)
              as FormFieldValidator<dynamic>,
        );
        break;
      case QuestionType.date:
        validators.add(
          ((value) {
                if (value != null && value is! DateTime) {
                  return AppConstants.invalidDate;
                }
                return null;
              })
              as FormFieldValidator<dynamic>,
        );
        break;
      default:
        break;
    }

    return FormBuilderValidators.compose(validators);
  }
}
