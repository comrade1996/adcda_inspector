import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/question_type.dart';
import '../models/survey.dart' as app_models;
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';

/// Provides formatting utilities for displaying answers in different formats
class FormatterHelper {
  /// Format an answer value based on the question type for preview display
  static String formatAnswerForPreview(
    app_models.SurveyQuestion question,
    dynamic answerValue, {
    BuildContext? context,
  }) {
    // If context is provided, use localization
    final bool useLocalization = context != null;
    final localizations = useLocalization ? AppLocalizations.of(context) : null;

    if (answerValue == null) {
      return useLocalization
          ? localizations!.translate('noAnswer')
          : 'لم يتم الإجابة';
    }

    switch (question.questionType) {
      case QuestionType.rating:
        // For ratings, return the number of stars
        try {
          final rating = int.parse(answerValue.toString());
          final stars =
              useLocalization ? localizations!.translate('stars') : 'نجوم';
          return '$rating $stars';
        } catch (e) {
          return answerValue.toString();
        }

      case QuestionType.radioButton:
      case QuestionType.dropDown:
        // Find the matching answer option
        try {
          // Parse the answer ID (could be string or int)
          int? answerId;
          if (answerValue is int) {
            answerId = answerValue;
          } else if (answerValue is String) {
            answerId = int.tryParse(answerValue);
          }
          
          // Find the matching answer text from the answers array
          if (answerId != null && question.answers.isNotEmpty) {
            final selectedAnswer = question.answers.firstWhere(
              (answer) => answer.id == answerId,
              orElse: () => app_models.SurveyAnswer(id: 0, answer: 'غير معروف', sortOrder: 0),
            );
            return selectedAnswer.answer ?? 'غير معروف';
          } 
          
          // Fallback for old API response formats
          final optionValue = answerId ?? int.parse(answerValue.toString());
          final option = question.validValues?.firstWhere(
            (option) => option.value == optionValue.toString(),
            orElse: () => app_models.ValidValue(value: "0", text: ''),
          );
          return option?.text ?? answerValue.toString();
        } catch (e) {
          return answerValue.toString();
        }

      case QuestionType.checkBox:
      case QuestionType.multiSelect:
        try {
          // Try to parse the answer value into a list of IDs
          List<int> answerIds = [];
          
          if (answerValue is List) {
            // If it's already a list, try to convert each element to int
            answerIds = answerValue
                .map((item) => item is int ? item : int.tryParse(item.toString()) ?? 0)
                .where((id) => id > 0)
                .toList();
          } else if (answerValue is String) {
            // Try parsing as JSON first
            try {
              final jsonList = json.decode(answerValue);
              if (jsonList is List) {
                answerIds = jsonList
                    .map((item) => item is int ? item : int.tryParse(item.toString()) ?? 0)
                    .where((id) => id > 0)
                    .toList();
              }
            } catch (e) {
              // If not JSON, try parsing as comma-separated values
              answerIds = answerValue
                  .split(',')
                  .where((s) => s.isNotEmpty)
                  .map((s) => int.tryParse(s.trim()) ?? 0)
                  .where((id) => id > 0)
                  .toList();
            }
          }
          
          // If we have valid IDs, try to find the corresponding answer texts
          if (answerIds.isNotEmpty && question.answers.isNotEmpty) {
            final selectedLabels = <String>[];
            
            for (final id in answerIds) {
              final answer = question.answers.firstWhere(
                (ans) => ans.id == id,
                orElse: () => app_models.SurveyAnswer(id: 0, answer: '', sortOrder: 0),
              );
              
              if (answer.id > 0 && answer.answer?.isNotEmpty == true) {
                selectedLabels.add(answer.answer ?? '');
              }
            }
            
            if (selectedLabels.isNotEmpty) {
              return selectedLabels.join('، ');
            }
          }
          
          // Fallback for old API response formats
          return answerValue.toString();
        } catch (e) {
          return answerValue.toString();
        }

      case QuestionType.date:
        try {
          // Try to parse as DateTime first
          if (answerValue is DateTime) {
            return '${answerValue.year}-${answerValue.month.toString().padLeft(2, '0')}-${answerValue.day.toString().padLeft(2, '0')}';
          }
          
          // Check if it's already a formatted date string
          return answerValue.toString();
        } catch (e) {
          return answerValue.toString();
        }

      case QuestionType.textBox:
      case QuestionType.comment:
      case QuestionType.numeric:
      default:
        return answerValue.toString();
    }
  }

  /// Build a widget to display rating stars
  static Widget buildRatingStars(int rating, {double size = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color:
              index < rating
                  ? AppColors.starActiveColor
                  : AppColors.starInactiveColor,
          size: size,
        );
      }),
    );
  }
}
