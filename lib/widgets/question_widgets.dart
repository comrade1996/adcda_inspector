import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/controllers/survey_controller.dart';
import 'package:adcda_inspector/models/question_type.dart';
import 'package:adcda_inspector/models/survey.dart' as app_models;
import 'package:adcda_inspector/theme/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_form_builder/src/form_builder_field.dart' show OptionsOrientation;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';

/// Base widget for survey questions
class QuestionWidget extends StatelessWidget {
  final app_models.SurveyQuestion question;
  final SurveyController controller;

  const QuestionWidget({
    Key? key,
    required this.question,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget questionWidget;
    
    // Select the appropriate widget based on question type
    switch (question.questionType) {
      case QuestionType.radioButton:
        questionWidget = RadioButtonQuestionWidget(
          question: question,
          controller: controller,
        );
        break;
      case QuestionType.checkBox:
        questionWidget = CheckBoxQuestionWidget(
          question: question,
          controller: controller,
        );
        break;
      case QuestionType.dropDown:
        questionWidget = DropdownQuestionWidget(
          question: question,
          controller: controller,
        );
        break;
      case QuestionType.multiSelect:
        questionWidget = MultiSelectQuestionWidget(
          question: question,
          controller: controller,
        );
        break;
      case QuestionType.textBox:
      case QuestionType.numeric:
      case QuestionType.comment:
        questionWidget = TextBoxQuestionWidget(
          question: question,
          controller: controller,
        );
        break;
      case QuestionType.fileUpload:
        questionWidget = FileUploadQuestionWidget(
          question: question,
          controller: controller,
        );
        break;
      case QuestionType.rating:
        questionWidget = RatingQuestionWidget(
          question: question,
          controller: controller,
        );
        break;
      case QuestionType.date:
        questionWidget = DateTimeQuestionWidget(
          question: question,
          controller: controller,
        );
        break;
      default:
        questionWidget = TextBoxQuestionWidget(
          question: question,
          controller: controller,
        );
    }

    // Build the question container with consistent styling
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header with number badge
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.03),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question number badge
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${question.id}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Question text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (question.question != null)
                        Text(
                          question.question!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      if (question.helpText != null)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            question.helpText!,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Question input field
          Padding(
            padding: EdgeInsets.all(16),
            child: questionWidget,
          ),
        ],
      ),
    );
  }
}

/// RadioButton question type widget
class RadioButtonQuestionWidget extends StatelessWidget {
  final app_models.SurveyQuestion question;
  final SurveyController controller;

  const RadioButtonQuestionWidget({
    Key? key,
    required this.question,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use answers if validValues is not available
    final options = question.validValues ?? 
                    question.answers.map((a) => 
                        app_models.ValidValue(
                            value: a.id.toString(), 
                            text: a.answer
                        )
                    ).toList();

    return FormBuilderRadioGroup<String>(
      name: 'question_${question.id}',
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        errorText: controller.getValidationError(question.id),
      ),
      validator: question.isRequired
          ? FormBuilderValidators.required(errorText: AppConstants.requiredField)
          : null,
      options: options
          .map((option) => FormBuilderFieldOption<String>(
                value: option.value ?? '',
                child: Text(
                  option.text ?? '',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ))
          .toList(),
      onChanged: (value) {
        controller.updateAnswer(question.id, value);
      },
    );
  }
}

/// Checkbox question type widget
class CheckBoxQuestionWidget extends StatelessWidget {
  final app_models.SurveyQuestion question;
  final SurveyController controller;

  const CheckBoxQuestionWidget({
    Key? key,
    required this.question,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use answers if validValues is not available
    final options = question.validValues ?? 
                    question.answers.map((a) => 
                        app_models.ValidValue(
                            value: a.id.toString(), 
                            text: a.answer
                        )
                    ).toList();
    final initialValues = controller.getAnswerAsList(question.id);

    return FormBuilderCheckboxGroup<String>(
      name: 'question_${question.id}',
      separator: SizedBox(height: 10),
      decoration: InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        errorText: controller.getValidationError(question.id),
      ),
      validator: question.isRequired
          ? FormBuilderValidators.required(errorText: AppConstants.requiredField)
          : null,
      options: options
          .map((option) => FormBuilderFieldOption<String>(
                value: option.value ?? '',
                child: Text(
                  option.text ?? '',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ))
          .toList(),
      initialValue: initialValues,
      onChanged: (values) {
        controller.updateAnswer(question.id, values);
      },
    );
  }
}

/// Dropdown question type widget
class DropdownQuestionWidget extends StatelessWidget {
  final app_models.SurveyQuestion question;
  final SurveyController controller;

  const DropdownQuestionWidget({
    Key? key,
    required this.question,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use answers if validValues is not available
    final options = question.validValues ?? 
                    question.answers.map((a) => 
                        app_models.ValidValue(
                            value: a.id.toString(), 
                            text: a.answer
                        )
                    ).toList();
    final initialValue = controller.getAnswer(question.id);

    return FormBuilderDropdown<String>(
      name: 'question_${question.id}',
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'اختر إجابة',
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.borderColor,
            width: 1,
          ),
        ),
        errorText: controller.getValidationError(question.id),
      ),
      validator: question.isRequired
          ? FormBuilderValidators.required(errorText: AppConstants.requiredField)
          : null,
      items: options
          .map((option) => DropdownMenuItem<String>(
                value: option.value ?? '',
                child: Text(
                  option.text ?? '',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ))
          .toList(),
      initialValue: initialValue,
      onChanged: (value) {
        controller.updateAnswer(question.id, value);
      },
      icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
      alignment: AlignmentDirectional.centerEnd,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(8),
    );
  }
}

/// MultiSelect question type widget
class MultiSelectQuestionWidget extends StatelessWidget {
  final app_models.SurveyQuestion question;
  final SurveyController controller;

  const MultiSelectQuestionWidget({
    Key? key,
    required this.question,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use answers if validValues is not available
    final options = question.validValues ?? 
                    question.answers.map((a) => 
                        app_models.ValidValue(
                            value: a.id.toString(), 
                            text: a.answer
                        )
                    ).toList();
    final initialValues = controller.getAnswerAsList(question.id);

    // Using Wrap with ChoiceChip for multi-select instead of FormBuilderFilterChip
    return FormBuilder(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = initialValues.contains(option.value);
              return ChoiceChip(
                label: Text(
                  option.text ?? '',
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary.withOpacity(0.15),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.borderColor,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                onSelected: (selected) {
                  final List<String> updatedValues = List.from(initialValues);
                  if (selected) {
                    if (!updatedValues.contains(option.value)) {
                      updatedValues.add(option.value ?? '');
                    }
                  } else {
                    updatedValues.remove(option.value);
                  }
                  controller.updateAnswer(question.id, updatedValues);
                },
              );
            }).toList(),
          ),
          // Error message
          if (controller.getValidationError(question.id) != null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                controller.getValidationError(question.id)!,
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// TextBox question type widget
class TextBoxQuestionWidget extends StatelessWidget {
  final app_models.SurveyQuestion question;
  final SurveyController controller;

  const TextBoxQuestionWidget({
    Key? key,
    required this.question,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final initialValue = controller.getAnswer(question.id);
    final isMultiline = question.multiline ?? 
                        question.questionType == QuestionType.comment;

    return FormBuilderTextField(
      name: 'question_${question.id}',
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: question.placeholder ?? 'أدخل إجابتك هنا',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        errorText: controller.getValidationError(question.id),
      ),
      validator: question.isRequired
          ? FormBuilderValidators.required(errorText: AppConstants.requiredField)
          : null,
      initialValue: initialValue,
      onChanged: (value) {
        controller.updateAnswer(question.id, value);
      },
      maxLines: isMultiline ? 4 : 1,
      textAlign: TextAlign.start,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
      ),
    );
  }
}

/// File upload question type widget
class FileUploadQuestionWidget extends StatelessWidget {
  final app_models.SurveyQuestion question;
  final SurveyController controller;

  const FileUploadQuestionWidget({
    Key? key,
    required this.question,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fileName = controller.getAnswer(question.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload button
        GestureDetector(
          onTap: () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.any,
              allowMultiple: false,
            );

            if (result != null) {
              PlatformFile file = result.files.first;
              controller.updateAnswer(question.id, file.path);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.borderColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file),
                SizedBox(width: 8),
                Text('اختر ملف'),
              ],
            ),
          ),
        ),
        
        // Display selected file name
        if (fileName != null && fileName.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: () => controller.updateAnswer(question.id, null),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          
        // Error message
        if (controller.getValidationError(question.id) != null)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              controller.getValidationError(question.id)!,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

/// Rating question type widget
class RatingQuestionWidget extends StatelessWidget {
  final app_models.SurveyQuestion question;
  final SurveyController controller;

  const RatingQuestionWidget({
    Key? key,
    required this.question,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final initialValue = controller.getAnswer(question.id);
    double? initialRating;
    
    try {
      if (initialValue != null && initialValue.isNotEmpty) {
        initialRating = double.parse(initialValue);
      }
    } catch (e) {
      initialRating = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: RatingBar.builder(
            initialRating: initialRating ?? 0,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 5,
            itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => Icon(
              Icons.star,
              color: AppColors.primary,
            ),
            onRatingUpdate: (rating) {
              controller.updateAnswer(question.id, rating.toString());
            },
          ),
        ),
        
        // Error message
        if (controller.getValidationError(question.id) != null)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              controller.getValidationError(question.id)!,
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

/// DateTime question type widget
class DateTimeQuestionWidget extends StatelessWidget {
  final app_models.SurveyQuestion question;
  final SurveyController controller;

  const DateTimeQuestionWidget({
    Key? key,
    required this.question,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final initialValue = controller.getAnswer(question.id);
    // Create a unique key for each date time picker instance
    final String fieldName = 'question_${question.id}';

    return FormBuilderDateTimePicker(
      name: fieldName,
      inputType: InputType.date,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'اختر تاريخ',
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.borderColor,
            width: 1,
          ),
        ),
        errorText: controller.getValidationError(question.id),
      ),
      validator: question.isRequired
          ? FormBuilderValidators.required(errorText: AppConstants.requiredField)
          : null,
      initialValue: initialValue != null ? DateTime.parse(initialValue) : null,
      onChanged: (value) {
        controller.updateAnswer(question.id, value.toString());
      },
    );
  }
}
