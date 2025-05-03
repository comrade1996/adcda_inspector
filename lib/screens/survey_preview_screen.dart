import 'package:adcda_inspector/constants/app_colors.dart';
import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/controllers/survey_controller.dart';
import 'package:adcda_inspector/models/question_type.dart';
import 'package:adcda_inspector/models/survey.dart';
import 'package:adcda_inspector/models/survey_submit.dart';
import 'package:adcda_inspector/services/survey_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'dart:convert';

class SurveyPreviewScreen extends StatefulWidget {
  final Survey survey;
  final Map<int, dynamic> answers;
  final int? incidentId;
  final int? respondentId;
  final String? respondentEmail;

  const SurveyPreviewScreen({
    Key? key,
    required this.survey,
    required this.answers,
    required this.incidentId,
    this.respondentId,
    this.respondentEmail,
  }) : super(key: key);

  @override
  State<SurveyPreviewScreen> createState() => _SurveyPreviewScreenState();
}

class _SurveyPreviewScreenState extends State<SurveyPreviewScreen> {
  final SurveyController _controller = Get.find<SurveyController>();
  final SurveyService _surveyService = SurveyService();
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'مراجعة الاستبيان',
          style: TextStyle(fontFamily: 'NotoKufiArabic'),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
      ),
      body:
          _isSuccess
              ? _buildSuccessView()
              : _isSubmitting
              ? _buildLoadingView()
              : _buildPreviewContent(),
    );
  }

  Widget _buildPreviewContent() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              // Survey Title
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.survey.name ?? 'استبيان',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoKufiArabic',
                      ),
                    ),
                    if (widget.survey.description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          widget.survey.description!,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontFamily: 'NotoKufiArabic',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Instructions
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.infoColor.withOpacity(0.1),
                  border: Border.all(
                    color: AppColors.infoColor.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.infoColor),
                        SizedBox(width: 8),
                        Text(
                          'مراجعة الإجابات',
                          style: TextStyle(
                            color: AppColors.textPrimaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'NotoKufiArabic',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'يرجى مراجعة إجاباتك قبل الإرسال النهائي للاستبيان',
                      style: TextStyle(
                        color: AppColors.textSecondaryColor,
                        fontSize: 14,
                        fontFamily: 'NotoKufiArabic',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Questions and Answers
              ...widget.survey.questions.map((question) {
                final answer = widget.answers[question.id];
                if (answer == null) return SizedBox.shrink();

                return _buildQuestionPreview(question, answer);
              }).toList(),

              if (_errorMessage != null)
                Container(
                  margin: EdgeInsets.only(top: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.errorColor),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppColors.errorColor,
                            fontSize: 14,
                            fontFamily: 'NotoKufiArabic',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _buildBottomButtons(),
      ],
    );
  }

  Widget _buildQuestionPreview(SurveyQuestion question, dynamic answer) {
    print(
      'PREVIEW DATA - Question: ${question.id} (${question.questionType}), Answer: $answer (${answer.runtimeType})',
    );

    // Dump all answer details for debugging
    if (question.questionType == QuestionType.checkBox) {
      print('======== CHECKBOX DEBUG ========');
      print('Question ID: ${question.id}');
      print('Question Text: ${question.question}');
      print('Question Type: ${question.questionType}');
      print('Answer Value: $answer');
      print('Answer Type: ${answer.runtimeType}');
      print('Available options:');
      for (var option in question.answers) {
        print('  - Option ID: ${option.id}, Text: ${option.answer}');
      }
      print('==============================');
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Text(
            question.question ?? '',
            style: TextStyle(
              color: AppColors.textPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoKufiArabic',
            ),
          ),
          SizedBox(height: 8),

          // Answer
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: _buildAnswerContent(question, answer),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerContent(SurveyQuestion question, dynamic answer) {
    print(
      'ANSWER CONTENT DEBUG (FIXED) - Question ID: ${question.id}, Type: ${question.questionType}, Raw Answer: $answer (${answer.runtimeType})',
    );
    final questionType = question.questionType;

    // RADIO BUTTONS AND DROPDOWNS
    if (questionType == QuestionType.radioButton ||
        questionType == QuestionType.dropDown) {
      try {
        print(
          'RADIO/DROPDOWN - Processing answer: $answer (${answer.runtimeType})',
        );

        // Extract the selected answer ID
        int? selectedId;

        if (answer is int) {
          selectedId = answer;
        } else if (answer is String) {
          try {
            selectedId = int.parse(answer);
          } catch (e) {
            print('Cannot parse radio/dropdown answer to int: $e');
          }
        }

        print('RADIO/DROPDOWN - Selected ID: $selectedId');

        // Find the corresponding answer option
        if (selectedId != null) {
          final selectedOption = question.answers.firstWhere(
            (opt) => opt.id == selectedId,
            orElse: () => SurveyAnswer(id: -1, answer: 'غير معروف'),
          );

          print('RADIO/DROPDOWN - Found option: ${selectedOption.answer}');

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.radio_button_checked,
                size: 18,
                color: AppColors.primaryColor,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedOption.answer ?? 'خيار غير معروف',
                  style: TextStyle(
                    color: AppColors.textPrimaryColor,
                    fontSize: 14,
                    fontFamily: 'NotoKufiArabic',
                  ),
                ),
              ),
            ],
          );
        }

        // Fallback text if no valid answer found
        return Text(
          'لم يتم اختيار إجابة',
          style: TextStyle(
            color: AppColors.textSecondaryColor,
            fontStyle: FontStyle.italic,
            fontFamily: 'NotoKufiArabic',
          ),
        );
      } catch (e) {
        print('Error displaying radio/dropdown answer: $e');
        return Text(
          'خطأ في عرض الإجابة: $e',
          style: TextStyle(
            color: AppColors.errorColor,
            fontFamily: 'NotoKufiArabic',
          ),
        );
      }
    }
    // CHECKBOXES AND MULTI-SELECT
    else if (questionType == QuestionType.checkBox ||
        questionType == QuestionType.multiSelect) {
      try {
        print('CHECKBOX - Raw answer data: $answer (${answer.runtimeType})');

        // Extract selected IDs from various possible formats
        List<int> selectedIds = [];

        if (answer is List) {
          print('CHECKBOX - Answer is a List directly');

          // Convert all items to integers if possible
          for (var item in answer) {
            if (item is int) {
              selectedIds.add(item);
            } else if (item is String) {
              try {
                selectedIds.add(int.parse(item));
              } catch (e) {
                print('Cannot parse list item to int: $e');
              }
            }
          }
        } else if (answer is String) {
          // Try to parse as JSON
          try {
            dynamic parsed = jsonDecode(answer);
            print('CHECKBOX - Parsed JSON: $parsed (${parsed.runtimeType})');

            if (parsed is List) {
              for (var item in parsed) {
                if (item is int) {
                  selectedIds.add(item);
                } else if (item is String) {
                  try {
                    selectedIds.add(int.parse(item));
                  } catch (e) {
                    print('Cannot parse JSON item to int: $e');
                  }
                }
              }
            }
          } catch (e) {
            print('CHECKBOX - Not valid JSON: $e');

            // If not JSON, try as a single value
            try {
              selectedIds.add(int.parse(answer));
            } catch (e) {
              print('Cannot parse answer as single int: $e');
            }
          }
        } else if (answer is int) {
          selectedIds.add(answer);
        }

        print('CHECKBOX - Final selected IDs: $selectedIds');

        // Build UI for checkbox selections
        if (selectedIds.isNotEmpty) {
          // Create a lookup map for answer texts
          Map<int, String> answerTexts = {};
          for (var option in question.answers) {
            if (option.id != null) {
              answerTexts[option.id!] = option.answer ?? 'خيار غير معروف';
            }
          }

          print('CHECKBOX - Answer text map: $answerTexts');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                selectedIds.map((id) {
                  String displayText = answerTexts[id] ?? 'خيار غير معروف';
                  print('CHECKBOX - Displaying option: $id -> $displayText');

                  return Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_box,
                          size: 18,
                          color: AppColors.primaryColor,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            displayText,
                            style: TextStyle(
                              color: AppColors.textPrimaryColor,
                              fontSize: 14,
                              fontFamily: 'NotoKufiArabic',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          );
        }

        // If no valid checkbox selections found
        return Text(
          'لم يتم اختيار أي خيارات',
          style: TextStyle(
            color: AppColors.textSecondaryColor,
            fontStyle: FontStyle.italic,
            fontFamily: 'NotoKufiArabic',
          ),
        );
      } catch (e) {
        print('Error displaying checkbox answer: $e');
        return Text(
          'خطأ في عرض الإجابة: $e',
          style: TextStyle(
            color: AppColors.errorColor,
            fontFamily: 'NotoKufiArabic',
          ),
        );
      }
    }
    // For rating questions
    else if (questionType == QuestionType.rating) {
      int rating = 0;
      if (answer is String) {
        rating = int.tryParse(answer) ?? 0;
      } else if (answer is int) {
        rating = answer;
      }

      return Row(
        children: [
          ...List.generate(5, (index) {
            return Icon(
              index < rating ? Icons.star : Icons.star_border,
              color: index < rating ? Colors.amber : Colors.grey,
              size: 20,
            );
          }),
          SizedBox(width: 8),
          Text(
            '$rating/5',
            style: TextStyle(
              color: AppColors.textPrimaryColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoKufiArabic',
            ),
          ),
        ],
      );
    }
    // Text box or other question types
    else if (questionType == QuestionType.textBox ||
        questionType == QuestionType.numeric ||
        questionType == QuestionType.comment) {
      return Text(
        answer.toString(),
        style: TextStyle(
          color: AppColors.textPrimaryColor,
          fontSize: 14,
          fontFamily: 'NotoKufiArabic',
        ),
      );
    }
    // File upload
    else if (questionType == QuestionType.fileUpload && answer is String) {
      final fileName = answer.split('/').last;
      return Row(
        children: [
          Icon(Icons.attachment, size: 16, color: AppColors.primaryColor),
          SizedBox(width: 8),
          Text(
            fileName,
            style: TextStyle(
              color: AppColors.textPrimaryColor,
              fontSize: 14,
              fontFamily: 'NotoKufiArabic',
            ),
          ),
        ],
      );
    }
    // Date
    else if (questionType == QuestionType.date && answer is String) {
      DateTime? date = DateTime.tryParse(answer);
      if (date != null) {
        final formattedDate = DateFormat('yyyy-MM-dd').format(date);
        return Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: AppColors.primaryColor),
            SizedBox(width: 8),
            Text(
              formattedDate,
              style: TextStyle(
                color: AppColors.textPrimaryColor,
                fontSize: 14,
                fontFamily: 'NotoKufiArabic',
              ),
            ),
          ],
        );
      }
    }

    // Default case
    return Text(
      answer.toString(),
      style: TextStyle(
        color: AppColors.textPrimaryColor,
        fontSize: 14,
        fontFamily: 'NotoKufiArabic',
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Get.back(),
              child: Text(
                'تعديل الإجابات',
                style: TextStyle(fontFamily: 'NotoKufiArabic'),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _submitSurvey,
              child: Text(
                'إرسال الاستبيان',
                style: TextStyle(fontFamily: 'NotoKufiArabic'),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/images/loader.json', width: 150, height: 150),
          SizedBox(height: 24),
          Text(
            'جاري إرسال الاستبيان...',
            style: TextStyle(
              color: AppColors.textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              fontFamily: 'NotoKufiArabic',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 100,
            color: AppColors.successColor,
          ),
          SizedBox(height: 24),
          Text(
            'تم إرسال الاستبيان بنجاح',
            style: TextStyle(
              color: AppColors.textPrimaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'NotoKufiArabic',
            ),
          ),
          SizedBox(height: 16),
          Text(
            'شكراً لك على إكمال الاستبيان',
            style: TextStyle(
              color: AppColors.textSecondaryColor,
              fontSize: 16,
              fontFamily: 'NotoKufiArabic',
            ),
          ),
          SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () => Get.until((route) => route.isFirst),
            icon: Icon(Icons.home),
            label: Text(
              'العودة للرئيسية',
              style: TextStyle(fontFamily: 'NotoKufiArabic'),
            ),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _submitSurvey() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Create formatted answers list
      final List<SurveySubmitAnswer> formattedAnswers = [];

      widget.answers.forEach((questionId, answerValue) {
        // Get the corresponding question to determine its type
        final question = widget.survey.questions.firstWhere(
          (q) => q.id == questionId,
        );

        // Handle different answer types
        SurveySubmitAnswer answer;

        if (answerValue is int) {
          answer = SurveySubmitAnswer(
            questionId: questionId,
            answerId: answerValue,
          );
        } else if (answerValue is double) {
          answer = SurveySubmitAnswer(
            questionId: questionId,
            numericAnswer: answerValue,
          );
        } else if (answerValue is DateTime) {
          answer = SurveySubmitAnswer(
            questionId: questionId,
            dateAnswer: answerValue,
          );
        } else if (answerValue is List) {
          // For multiple choice, we'll use the first value as answerId
          if (answerValue.isNotEmpty && answerValue[0] is int) {
            answer = SurveySubmitAnswer(
              questionId: questionId,
              answerId: answerValue[0],
            );
          } else {
            answer = SurveySubmitAnswer(
              questionId: questionId,
              textAnswer: answerValue.join(', '),
            );
          }
        } else {
          // Default to text answer
          answer = SurveySubmitAnswer(
            questionId: questionId,
            textAnswer: answerValue.toString(),
          );
        }

        formattedAnswers.add(answer);
      });

      // Create submit object
      final SurveySubmit submitData = SurveySubmit(
        surveyId: widget.survey.id,
        incidentId: widget.incidentId ?? 0,
        respondentId: widget.respondentId,
        respondentEmail: widget.respondentEmail,
        languageId: AppConstants.defaultLanguageId,
        answers: formattedAnswers,
      );

      print('Submitting survey data: ${jsonEncode(submitData.toJson())}');

      // Submit the survey
      await _surveyService.submitSurvey(submitData);

      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage =
            'حدث خطأ أثناء إرسال الاستبيان. يرجى المحاولة مرة أخرى.';
      });
      print('Error submitting survey: $e');
    }
  }
}
