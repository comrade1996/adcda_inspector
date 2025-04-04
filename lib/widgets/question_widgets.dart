import 'dart:convert';
import 'package:adcda_inspector/constants/app_colors.dart';
import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/controllers/survey_controller.dart';
import 'package:adcda_inspector/models/survey.dart' as app_models;
import 'package:adcda_inspector/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:adcda_inspector/utils/background_decorator.dart';
import 'dart:io';
import 'dart:convert';
import 'package:mime/mime.dart';

import '../models/question_type.dart';

/// Base question widget that handles different question types
class QuestionWidget extends StatelessWidget {
  final app_models.SurveyQuestion question;
  final SurveyController? controller;

  const QuestionWidget({
    Key? key,
    required this.question,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('BUILDING WIDGET FOR QUESTION ${question.id}');
    print('  - Text: "${question.question}"');
    print('  - Type: ${question.questionType}');
    print('  - Has answers: ${question.answers.isNotEmpty}');
    if (question.answers.isNotEmpty) {
      print('  - answers Count: ${question.answers.length}');
    }

    // Create a stable field name (no timestamp) to avoid GlobalKey conflicts and rebuilds
    final fieldName = 'question_${question.id}';

    // Get existing answer value if available
    final existingAnswer = controller?.getAnswer(question.id);
    print('  - Existing answer: $existingAnswer');

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.darkBackgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question text
                      Text(
                        question.question ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'NotoKufiArabic',
                        ),
                        textDirection: AppConstants.appTextDirection,
                      ),
                      if (question.helpText != null &&
                          question.helpText!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            question.helpText!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontFamily: 'NotoKufiArabic',
                            ),
                            textDirection: AppConstants.appTextDirection,
                          ),
                        ),
                    ],
                  ),
                ),
                if (question.isRequired)
                  Container(
                    margin: EdgeInsets.only(left: 8, top: 4),
                    child: Text(
                      '*',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.errorColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Choose the appropriate form field type based on question type
          _buildQuestionFormField(fieldName, question, controller),
        ],
      ),
    );
  }
  
  // Helper method to build the right form field type for each question
  Widget _buildQuestionFormField(String fieldName, app_models.SurveyQuestion question, SurveyController? controller) {
    // Check if question has options in the answers array
    bool hasOptions = question.answers.isNotEmpty;
    
    switch (question.questionType) {
      case QuestionType.checkBox:
        print('WIDGET: Using CheckBox widget for question ${question.id}');
        return FormBuilder(
          autovalidateMode: AutovalidateMode.disabled,
          child: FormBuilderField<String>(
            name: fieldName,
            validator: question.isRequired
                ? FormBuilderValidators.required(
                    errorText: AppConstants.requiredField,
                  )
                : null,
            initialValue: controller?.getAnswer(question.id),
            onChanged: (value) {
              print('Field $fieldName changed to: $value (type: ${value?.runtimeType})');
              if (controller != null) {
                print('Updating controller for question ${question.id} with value: $value');
                controller.updateAnswer(question.id, value);
              }
            },
            builder: (FormFieldState<String> field) {
              List<String> checkboxValues = [];
              if (field.value != null) {
                try {
                  // Try to parse JSON list
                  final parsed = jsonDecode(field.value as String);
                  if (parsed is List) {
                    checkboxValues = parsed.map((v) => v.toString()).toList().cast<String>();
                  }
                } catch (e) {
                  print('Error parsing checkbox values: $e');
                }
              }
              
              return CheckboxQuestionWidget(
                question: question,
                isRequired: question.isRequired,
                selectedValues: checkboxValues,
                onValueChanged: (List<String> values) {
                  print('CHECKBOX: Updating with values: $values');
                  // Convert the list to a JSON string for the field
                  String jsonValues = jsonEncode(values);
                  field.didChange(jsonValues);
                  
                  // Make sure to update the controller directly
                  if (controller != null) {
                    print('CHECKBOX: Converting values to JSON for controller');
                    controller.updateAnswer(question.id, jsonValues);
                  }
                },
              );
            },
          ),
        );
        
      case QuestionType.radioButton:
        print('WIDGET: Using RadioButton widget for question ${question.id}');
        return FormBuilder(
          autovalidateMode: AutovalidateMode.disabled,
          child: FormBuilderField<String>(
            name: fieldName,
            validator: question.isRequired
                ? FormBuilderValidators.required(
                    errorText: AppConstants.requiredField,
                  )
                : null,
            initialValue: controller?.getAnswer(question.id),
            onChanged: (value) {
              print('Field $fieldName changed to: $value (type: ${value?.runtimeType})');
              if (controller != null) {
                print('Updating controller for question ${question.id} with value: $value');
                controller.updateAnswer(question.id, value);
              }
            },
            builder: (FormFieldState<String> field) {
              String? radioValue = field.value;
              print('RADIO WIDGET: Initial value for question ${question.id}: $radioValue');
              
              return RadioQuestionWidget(
                question: question,
                isRequired: question.isRequired,
                selectedValue: radioValue,
                onValueChanged: (String value) {
                  print('RADIO: Updating with value: $value');
                  field.didChange(value);
                  // Make sure to update the controller directly with the string value
                  if (controller != null) {
                    print('RADIO: Updating controller with string value: $value');
                    controller.updateAnswer(question.id, value);
                  }
                },
              );
            },
          ),
        );
      
      case QuestionType.dropDown:
        print('WIDGET: Using DropDown widget for question ${question.id}');
        return FormBuilder(
          autovalidateMode: AutovalidateMode.disabled,
          child: FormBuilderField<String>(
            name: fieldName,
            validator: question.isRequired
                ? FormBuilderValidators.required(
                    errorText: AppConstants.requiredField,
                  )
                : null,
            initialValue: controller?.getAnswer(question.id),
            onChanged: (value) {
              print('Field $fieldName changed to: $value (type: ${value?.runtimeType})');
              if (controller != null) {
                print('Updating controller for question ${question.id} with value: $value');
                controller.updateAnswer(question.id, value);
              }
            },
            builder: (FormFieldState<String> field) {
              int? selectedId;
              if (field.value != null) {
                selectedId = int.tryParse(field.value as String);
              }
              
              return DropdownQuestionWidget(
                question: question,
                isRequired: question.isRequired,
                selectedValue: selectedId,
                onValueChanged: (int value) {
                  print('DROPDOWN: Updating with value: $value');
                  field.didChange(value.toString());
                  if (controller != null) {
                    controller.updateAnswer(question.id, value.toString());
                  }
                },
              );
            },
          ),
        );
      
      case QuestionType.rating:
        print('WIDGET: Using Rating widget for question ${question.id}');
        return FormBuilder(
          autovalidateMode: AutovalidateMode.disabled,
          child: FormBuilderField<String>(
            name: fieldName,
            validator: question.isRequired
                ? FormBuilderValidators.required(
                    errorText: AppConstants.requiredField,
                  )
                : null,
            initialValue: controller?.getAnswer(question.id),
            onChanged: (value) {
              print('Field $fieldName changed to: $value (type: ${value?.runtimeType})');
              if (controller != null) {
                print('Updating controller for question ${question.id} with value: $value');
                controller.updateAnswer(question.id, value);
              }
            },
            builder: (FormFieldState<String> field) {
              // Safe conversion of field value to integer rating
              int initialRating = 0;
              if (field.value != null) {
                initialRating = int.tryParse(field.value as String) ?? 0;
              }
              print('RATING WIDGET: Initial converted rating: $initialRating');
              
              return RatingQuestionWidget(
                question: question,
                isRequired: question.isRequired,
                currentRating: initialRating,
                onRatingChanged: (int rating) {
                  print('RATING: Updating rating to $rating for question ${question.id}');
                  // Convert to string for the field
                  field.didChange(rating.toString());
                  // Make sure to update the controller directly with a string value
                  if (controller != null) {
                    print('RATING: Updating controller with string value: ${rating.toString()}');
                    controller.updateAnswer(question.id, rating.toString());
                  }
                },
              );
            },
          ),
        );
        
      // Handle other question types with default FormBuilder
      default:
        print('WIDGET: Using default widget for question ${question.id} of type ${question.questionType}');
        return FormBuilder(
          autovalidateMode: AutovalidateMode.disabled,
          child: FormBuilderField<String>(
            name: fieldName,
            validator: question.isRequired
                ? FormBuilderValidators.required(
                    errorText: AppConstants.requiredField,
                  )
                : null,
            initialValue: controller?.getAnswer(question.id),
            onChanged: (value) {
              print('Field $fieldName changed to: $value (type: ${value?.runtimeType})');
              if (controller != null) {
                print('Updating controller for question ${question.id} with value: $value');
                controller.updateAnswer(question.id, value);
              }
            },
            builder: (FormFieldState<String> field) {
              // Handle other question types
              switch (question.questionType) {
                case QuestionType.multiSelect:
                  print('WIDGET: Using MultiSelect widget for question ${question.id}');
                  return MultiSelectQuestionWidget(
                    question: question,
                    controller: controller ?? SurveyController(),
                    field: field,
                  );
                  
                case QuestionType.date:
                  print('WIDGET: Using Date widget for question ${question.id}');
                  return DateTimeQuestionWidget(
                    question: question,
                    controller: controller ?? SurveyController(),
                  );
                  
                case QuestionType.numeric:
                  print('WIDGET: Using Numeric widget for question ${question.id}');
                  return TextQuestionWidget(
                    question: question,
                    isRequired: question.isRequired,
                    value: field.value ?? '',
                    onValueChanged: (String value) {
                      field.didChange(value);
                    },
                    keyboardType: TextInputType.number,
                  );
                  
                case QuestionType.fileUpload:
                  print('WIDGET: Using FileUpload widget for question ${question.id}');
                  return FileUploadQuestionWidget(
                    question: question,
                    controller: controller ?? SurveyController(),
                    field: field,
                  );
                  
                case QuestionType.comment:
                case QuestionType.textBox:
                default:
                  print('WIDGET: Using TextBox widget for question ${question.id}');
                  return TextQuestionWidget(
                    question: question,
                    isRequired: question.isRequired,
                    value: field.value ?? '',
                    onValueChanged: (String value) {
                      field.didChange(value);
                    },
                    maxLines: question.multiline == true ? 5 : 1,
                  );
              }
            },
          ),
        );
    }
  }
}

class RadioQuestionWidget extends StatelessWidget {
  final app_models.SurveyQuestion question;
  final bool isRequired;
  final String? selectedValue;
  final Function(String) onValueChanged;

  const RadioQuestionWidget({
    Key? key,
    required this.question,
    required this.isRequired,
    required this.selectedValue,
    required this.onValueChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: question.answers.map((answer) {
        final optionValue = answer.id.toString();
        final isSelected = selectedValue == optionValue;
        return InkWell(
          onTap: () {
            print('Radio option tapped: ${answer.id} - ${answer.answer}');
            if (isSelected) {
              // Allow deselecting by setting to a sentinel value ("0" as fallback)
              onValueChanged("0"); // Use "0" as a sentinel value for "none selected"
            } else {
              onValueChanged(optionValue);
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.radioButtonActiveColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.radioButtonActiveColor
                    : AppColors.radioButtonInactiveColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.radioButtonActiveColor
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.radioButtonActiveColor
                          : AppColors.radioButtonInactiveColor,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    answer.answer ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'NotoKufiArabic',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class CheckboxQuestionWidget extends StatelessWidget {
  final app_models.SurveyQuestion question;
  final bool isRequired;
  final List<String> selectedValues;
  final Function(List<String>) onValueChanged;

  const CheckboxQuestionWidget({
    Key? key,
    required this.question,
    required this.isRequired,
    required this.selectedValues,
    required this.onValueChanged,
  }) : super(key: key);

  void _toggleValue(String value) {
    final List<String> newValues = List.from(selectedValues);
    if (newValues.contains(value)) {
      newValues.remove(value);
    } else {
      newValues.add(value);
    }
    print('CheckboxQuestionWidget: Selected values updated to: $newValues');
    onValueChanged(newValues);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: question.answers.map((answer) {
        final optionValue = answer.id.toString();
        final isSelected = selectedValues.contains(optionValue);
        return InkWell(
          onTap: () {
            print('Checkbox option tapped: ${answer.id} - ${answer.answer}');
            _toggleValue(answer.id.toString());
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.radioButtonActiveColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.radioButtonActiveColor
                    : AppColors.radioButtonInactiveColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.radioButtonActiveColor
                          : AppColors.radioButtonInactiveColor,
                      width: 2,
                    ),
                    color: isSelected
                        ? AppColors.radioButtonActiveColor
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    answer.answer ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'NotoKufiArabic',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Dropdown question type widget
class DropdownQuestionWidget extends StatelessWidget {
  final app_models.SurveyQuestion question;
  final bool isRequired;
  final int? selectedValue;
  final Function(int) onValueChanged;

  const DropdownQuestionWidget({
    Key? key,
    required this.question,
    required this.isRequired,
    required this.selectedValue,
    required this.onValueChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Find the selected item's text
    String selectedText = '';
    if (selectedValue != null) {
      final selectedOption = question.answers.firstWhere(
        (option) => option.id == selectedValue,
        orElse: () => app_models.SurveyAnswer(id: 0, answer: ''),
      );
      selectedText = selectedOption.answer ?? '';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.dropdownBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedValue,
          hint: Text(
            question.placeholder ?? 'اختر إجابة',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontFamily: 'NotoKufiArabic',
            ),
          ),
          icon: Icon(Icons.arrow_drop_down, color: Colors.white),
          dropdownColor: AppColors.darkBackgroundColor,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontFamily: 'NotoKufiArabic',
          ),
          onChanged: (value) {
            if (value != null) {
              onValueChanged(value);
            }
          },
          items: question.answers.map((option) {
            return DropdownMenuItem<int>(
              value: option.id,
              child: Text(
                option.answer ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontFamily: 'NotoKufiArabic',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// MultiSelect question type widget
class MultiSelectQuestionWidget extends StatelessWidget {
  final app_models.SurveyQuestion question;
  final SurveyController? controller;
  final FormFieldState<dynamic> field;

  const MultiSelectQuestionWidget({
    Key? key,
    required this.question,
    required this.controller,
    required this.field,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final initialValues = controller?.getAnswerAsList(question.id);

    // Using Wrap with ChoiceChip for multi-select instead of FormBuilderFilterChip
    return FormBuilder(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderColor, width: 1),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: question.answers.map((option) {
                final optionValue = option.id.toString();
                final isSelected = initialValues?.contains(optionValue) ?? false;
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.borderColor,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 2,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: ChoiceChip(
                    label: Text(
                      option.answer ?? '',
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primaryColor
                            : Colors.white,
                        fontSize: 14,
                        fontFamily: 'NotoKufiArabic',
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primaryColor.withOpacity(0.15),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.borderColor,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    onSelected: (selected) {
                      final List<String> updatedValues = List.from(
                        initialValues ?? [],
                      );
                      if (selected) {
                        if (!updatedValues.contains(
                          optionValue,
                        )) {
                          updatedValues.add(optionValue);
                        }
                      } else {
                        updatedValues.remove(optionValue);
                      }
                      controller?.updateAnswer(question.id, updatedValues);
                      field.didChange(updatedValues);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          // Error message
          if (controller?.getValidationError(question.id) != null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                controller!.getValidationError(question.id)!,
                style: TextStyle(color: AppColors.errorColor, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// TextBox question type widget
class TextQuestionWidget extends StatelessWidget {
  final app_models.SurveyQuestion question;
  final bool isRequired;
  final String value;
  final Function(String) onValueChanged;
  final TextInputType? keyboardType;
  final int? maxLines;

  const TextQuestionWidget({
    Key? key,
    required this.question,
    required this.isRequired,
    required this.value,
    required this.onValueChanged,
    this.keyboardType,
    this.maxLines,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.textInputBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textInputBorderColor, width: 1),
      ),
      child: TextField(
        controller: TextEditingController(text: value)
          ..selection = TextSelection.fromPosition(
            TextPosition(offset: value.length),
          ),
        onChanged: onValueChanged,
        style: TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontFamily: 'NotoKufiArabic',
        ),
        maxLines: maxLines ?? 1,
        minLines: maxLines != null ? maxLines : 1,
        expands: false,
        keyboardType: keyboardType ?? TextInputType.text,
        textAlign: TextAlign.right,
        cursorColor: AppColors.primaryColor,
        decoration: InputDecoration(
          hintText: 'أدخل إجابتك هنا',
          hintStyle: TextStyle(
            fontSize: 14,
            color: AppColors.whiteMutedColor,
            fontFamily: 'NotoKufiArabic',
          ),
          contentPadding: EdgeInsets.all(16),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
        ),
      ),
    );
  }
}

/// File upload question type widget
class FileUploadQuestionWidget extends StatefulWidget {
  final app_models.SurveyQuestion question;
  final SurveyController? controller;
  final FormFieldState<dynamic> field;

  const FileUploadQuestionWidget({
    Key? key,
    required this.question,
    required this.controller,
    required this.field,
  }) : super(key: key);

  @override
  State<FileUploadQuestionWidget> createState() =>
      _FileUploadQuestionWidgetState();
}

class _FileUploadQuestionWidgetState extends State<FileUploadQuestionWidget> {
  String? _fileName;
  String? _fileBase64;

  @override
  void initState() {
    super.initState();
    final answer = widget.controller?.getAnswer(widget.question.id);
    if (answer != null && answer is String) {
      if (answer.startsWith('data:')) {
        // It's already base64
        _fileBase64 = answer;
        // Extract filename if embedded in the data
        final nameMatch = RegExp(r'filename=([^;]+)').firstMatch(answer);
        _fileName = nameMatch?.group(1) ?? 'uploaded_file';
      } else if (answer.contains('/')) {
        // It's a path, consider it legacy format
        _fileName = answer.split('/').last;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload button
        GestureDetector(
          onTap: () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.image,
              allowMultiple: false,
            );

            if (result != null) {
              PlatformFile file = result.files.first;

              // Read file as bytes and convert to base64
              if (file.path != null) {
                final bytes = await File(file.path!).readAsBytes();
                final base64String = base64Encode(bytes);

                // Create data URI with file type and name
                final mimeType = lookupMimeType(file.name) ?? 'image/jpeg';
                final dataUri = 'data:$mimeType;filename=${file.name};base64,$base64String';

                // Save to controller
                widget.controller?.updateAnswer(widget.question.id, dataUri);
                setState(() {
                  _fileName = file.name;
                  _fileBase64 = dataUri;
                });
              }
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BackgroundDecorator.cardPatternDecoration,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file, color: AppColors.primaryColor),
                SizedBox(width: 12),
                Text(
                  'اختر ملف',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'NotoKufiArabic',
                  ),
                ),
              ],
            ),
          ),
        ),

        // Show file name if selected
        if (_fileName != null)
          Container(
            margin: EdgeInsets.only(top: 12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.fileBackgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.insert_drive_file,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _fileName!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 16, color: Colors.white60),
                  onPressed: () {
                    widget.controller?.updateAnswer(widget.question.id, null);
                    setState(() {
                      _fileName = null;
                      _fileBase64 = null;
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Rating question type widget
class RatingQuestionWidget extends StatefulWidget {
  final app_models.SurveyQuestion question;
  final bool isRequired;
  final int currentRating;
  final Function(int) onRatingChanged;

  const RatingQuestionWidget({
    Key? key,
    required this.question,
    required this.isRequired,
    required this.currentRating,
    required this.onRatingChanged,
  }) : super(key: key);

  @override
  State<RatingQuestionWidget> createState() => _RatingQuestionWidgetState();
}

class _RatingQuestionWidgetState extends State<RatingQuestionWidget> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.currentRating;
    print('RATING WIDGET: Initial rating for question ${widget.question.id} is $_currentRating');
  }

  @override
  void didUpdateWidget(RatingQuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ensure the rating gets updated if the external value changes
    if (oldWidget.currentRating != widget.currentRating) {
      _currentRating = widget.currentRating;
      print('RATING WIDGET: Updated rating for question ${widget.question.id} to $_currentRating');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Rating display
          Center(
            child: RatingBar(
              initialRating: _currentRating.toDouble(),
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              ratingWidget: RatingWidget(
                full: Icon(Icons.star, color: Colors.amber),
                half: Icon(Icons.star_half, color: Colors.amber),
                empty: Icon(Icons.star_border, color: Colors.amber),
              ),
              onRatingUpdate: (rating) {
                final newRating = rating.toInt();
                print('RATING WIDGET: Rating changed for question ${widget.question.id} from $_currentRating to $newRating');
                setState(() {
                  _currentRating = newRating;
                });
                widget.onRatingChanged(newRating);
              },
            ),
          ),
          
          // Rating value text
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '$_currentRating/5',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// DateTime question type widget
class DateTimeQuestionWidget extends StatefulWidget {
  final app_models.SurveyQuestion question;
  final SurveyController? controller;

  const DateTimeQuestionWidget({
    Key? key,
    required this.question,
    required this.controller,
  }) : super(key: key);

  @override
  State<DateTimeQuestionWidget> createState() => _DateTimeQuestionWidgetState();
}

class _DateTimeQuestionWidgetState extends State<DateTimeQuestionWidget> {
  @override
  Widget build(BuildContext context) {
    final format = DateFormat('yyyy-MM-dd');
    // Create a stable field name (no timestamp) to avoid GlobalKey conflicts and rebuilds
    final fieldName = 'datetime_${widget.question.id}';

    // Try to parse existing date value if available
    DateTime? initialDate;
    if (widget.controller?.getAnswer(widget.question.id) != null) {
      try {
        final dateStr = widget.controller!.getAnswer(widget.question.id)!;
        initialDate = DateTime.tryParse(dateStr);
      } catch (e) {
        // Silently handle parse errors
      }
    }

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Theme(
        // Apply a theme override for the date picker
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primaryColor,
            onPrimary: Colors.white,
            onSurface:
                Colors.black, // Fixed: Text color for dates in the calendar
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor:
                  AppColors.primaryColor, // Fixed: Text color for buttons
            ),
          ),
        ),
        child: FormBuilderDateTimePicker(
          name: fieldName,
          inputType: InputType.date,
          format: format,
          decoration: InputDecoration(
            labelText: 'حدد التاريخ',
            labelStyle: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontFamily: 'NotoKufiArabic',
            ),
            hintText: 'اضغط لاختيار التاريخ',
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontFamily: 'NotoKufiArabic',
            ),
            fillColor: Color(0xFFF1F1F4),
            filled: true,
            prefixIcon: Container(
              padding: EdgeInsets.all(12),
              child: Icon(
                Icons.calendar_today,
                color: AppColors.primaryColor,
                size: 22,
              ),
            ),
            suffixIcon: Icon(
              Icons.arrow_drop_down,
              color: Colors.black87,
              size: 24,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            errorStyle: TextStyle(
              color: Colors.red[700],
              fontSize: 12,
              fontFamily: 'NotoKufiArabic',
            ),
          ),
          validator:
              widget.question.isRequired
                  ? FormBuilderValidators.required(
                      errorText: AppConstants.requiredField,
                    )
                  : null,
          initialValue: initialDate,
          onChanged: (value) {
            widget.controller?.updateAnswer(
              widget.question.id,
              value.toString(),
            );
          },
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'NotoKufiArabic',
          ),
          locale: const Locale('ar', 'AE'),
        ),
      ),
    );
  }
}
