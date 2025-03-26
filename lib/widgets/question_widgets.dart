import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:adcda_inspector/models/survey.dart' as app_models;
import 'package:adcda_inspector/models/question_type.dart';
import 'package:adcda_inspector/controllers/survey_controller.dart';
import 'package:adcda_inspector/constants/app_constants.dart';
import 'package:adcda_inspector/constants/app_colors.dart';
import 'package:adcda_inspector/utils/background_decorator.dart';

/// Base question widget that handles different question types
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
    // Wrap with a container to ensure white background
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(16),
      decoration: BackgroundDecorator.lightPatternDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question title with required indicator if needed
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            // Fix RTL issue by removing textDirection explicitly
            children: [
              Expanded(
                child: Text(
                  question.question ??
                      'سؤال', // Using question field instead of questionText
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'NotoKufiArabic',
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              if (question.isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          // Question input field
          FormBuilderField(
            name: 'question_${question.id}',
            validator: null, // Remove validator from here, will handle in individual widgets
            onChanged: (value) {
              controller.updateAnswer(question.id, value);
            },
            builder: (FormFieldState<dynamic> field) {
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

              return Column(
                children: [
                  questionWidget,
                  if (field.errorText != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        field.errorText!,
                        style: TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// RadioButton question type widget
class RadioButtonQuestionWidget extends StatefulWidget {
  final app_models.SurveyQuestion question;
  final SurveyController controller;

  const RadioButtonQuestionWidget({
    Key? key,
    required this.question,
    required this.controller,
  }) : super(key: key);

  @override
  State<RadioButtonQuestionWidget> createState() => _RadioButtonQuestionWidgetState();
}

class _RadioButtonQuestionWidgetState extends State<RadioButtonQuestionWidget> {
  // Local state to track selection
  String? selectedValue;
  
  @override
  void initState() {
    super.initState();
    // Initialize with any existing value
    selectedValue = widget.controller.getAnswer(widget.question.id);
  }
  
  @override
  Widget build(BuildContext context) {
    // Use answers if validValues is not available
    final options =
        widget.question.validValues ??
        widget.question.answers
            .map(
              (a) =>
                  app_models.ValidValue(value: a.id.toString(), text: a.answer),
            )
            .toList();
    
    // Custom radio button implementation for better visibility
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options.map((option) {
        final optionValue = option.value ?? '';
        final optionText = option.text ?? '';
        
        // Check if this option is selected
        final isSelected = selectedValue == optionValue;
        
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              // Update both local state and controller
              setState(() {
                selectedValue = optionValue;
              });
              widget.controller.updateAnswer(widget.question.id, optionValue);
            },
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected 
                          ? AppColors.primary
                          : Colors.grey[400]!,
                      width: 2.5,
                    ),
                    color: isSelected 
                        ? AppColors.primary 
                        : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 2,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    optionText,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
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
    final options =
        question.validValues ??
        question.answers
            .map(
              (a) =>
                  app_models.ValidValue(value: a.id.toString(), text: a.answer),
            )
            .toList();
    final initialValues = controller.getAnswerAsList(question.id);

    return Container(
      decoration: BackgroundDecorator.cardPatternDecoration,
      child: FormBuilderCheckboxGroup<String>(
        name: 'question_${question.id}',
        orientation: OptionsOrientation.vertical,
        decoration: InputDecoration(
          border: InputBorder.none,
          fillColor: Colors.white,
          filled: true,
        ),
        validator:
            question.isRequired
                ? FormBuilderValidators.required(
                  errorText: AppConstants.requiredField,
                )
                : null,
        options:
            options
                .map(
                  (option) => FormBuilderFieldOption<String>(
                    value: option.value ?? '',
                    child: Text(
                      option.text ?? '',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontFamily: 'NotoKufiArabic',
                      ),
                    ),
                  ),
                )
                .toList(),
        initialValue: initialValues,
        onChanged: (values) {
          controller.updateAnswer(question.id, values);
        },
      ),
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
    final options =
        question.validValues ??
        question.answers
            .map(
              (a) =>
                  app_models.ValidValue(value: a.id.toString(), text: a.answer),
            )
            .toList();
    final initialValue = controller.getAnswer(question.id);

    return FormBuilderDropdown<String>(
      name: 'question_${question.id}',
      decoration: InputDecoration(
        hintText: 'اختر إجابة',
        fillColor: Colors.white,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      validator:
          question.isRequired
              ? FormBuilderValidators.required(
                errorText: AppConstants.requiredField,
              )
              : null,
      items:
          options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.value ?? '',
                  child: Text(
                    option.text ?? '',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontFamily: 'NotoKufiArabic',
                    ),
                  ),
                ),
              )
              .toList(),
      initialValue: initialValue,
      onChanged: (value) {
        controller.updateAnswer(question.id, value);
      },
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
    final options =
        question.validValues ??
        question.answers
            .map(
              (a) =>
                  app_models.ValidValue(value: a.id.toString(), text: a.answer),
            )
            .toList();
    final initialValues = controller.getAnswerAsList(question.id);

    // Using Wrap with ChoiceChip for multi-select instead of FormBuilderFilterChip
    return FormBuilder(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.borderColor,
                width: 1.0,
              ),
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
              children:
                  options.map((option) {
                    final isSelected = initialValues.contains(option.value);
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.borderColor,
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
                          option.text ?? '',
                          style: TextStyle(
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                            fontSize: 14,
                            fontFamily: 'NotoKufiArabic',
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withOpacity(0.15),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : AppColors.borderColor,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        onSelected: (selected) {
                          final List<String> updatedValues = List.from(
                            initialValues,
                          );
                          if (selected) {
                            if (!updatedValues.contains(option.value)) {
                              updatedValues.add(option.value ?? '');
                            }
                          } else {
                            updatedValues.remove(option.value);
                          }
                          controller.updateAnswer(question.id, updatedValues);
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),
          // Error message
          if (controller.getValidationError(question.id) != null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                controller.getValidationError(question.id)!,
                style: TextStyle(color: AppColors.error, fontSize: 12),
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
    // Check if this should be a multiline text field
    bool isMultiline = question.questionType == QuestionType.comment;

    return FormBuilderTextField(
      name: 'question_${question.id}',
      decoration: InputDecoration(
        hintText: question.placeholder ?? 'أدخل إجابتك هنا',
        fillColor: Color(0xFFF1F1F4), 
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none, 
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: isMultiline ? 16 : 14),
        errorText: null, // Removed duplicate validation message
        hintStyle: TextStyle(
          color: Color(0xFF9CA3AF), 
          fontSize: 14,
          fontFamily: 'NotoKufiArabic',
        ),
        errorStyle: TextStyle(
          color: Colors.red[700],
          fontSize: 12,
          fontFamily: 'NotoKufiArabic',
        ),
      ),
      initialValue: controller.getAnswer(question.id),
      maxLines: isMultiline ? 5 : 1,
      keyboardType: isMultiline ? TextInputType.multiline : TextInputType.text,
      validator:
          question.isRequired
              ? FormBuilderValidators.required(
                errorText: AppConstants.requiredField,
              )
              : null,
      onChanged: (value) {
        controller.updateAnswer(question.id, value);
      },
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontFamily: 'NotoKufiArabic',
      ),
      textAlign: TextAlign.right,
    );
  }
}

/// File upload question type widget
class FileUploadQuestionWidget extends StatefulWidget {
  final app_models.SurveyQuestion question;
  final SurveyController controller;

  const FileUploadQuestionWidget({
    Key? key,
    required this.question,
    required this.controller,
  }) : super(key: key);

  @override
  State<FileUploadQuestionWidget> createState() =>
      _FileUploadQuestionWidgetState();
}

class _FileUploadQuestionWidgetState extends State<FileUploadQuestionWidget> {
  String? _fileName;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    final answer = widget.controller.getAnswer(widget.question.id);
    if (answer != null) {
      _filePath = answer;
      _fileName = answer.split('/').last;
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
              type: FileType.any,
              allowMultiple: false,
            );

            if (result != null) {
              PlatformFile file = result.files.first;
              widget.controller.updateAnswer(widget.question.id, file.path);
              setState(() {
                _fileName = file.name;
                _filePath = file.path;
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BackgroundDecorator.cardPatternDecoration,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file, color: AppColors.primary),
                SizedBox(width: 12),
                Text(
                  'اختر ملف',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'NotoKufiArabic',
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_fileName != null)
          Container(
            margin: EdgeInsets.only(top: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderColor, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.description, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _fileName!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontFamily: 'NotoKufiArabic',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.error, size: 18),
                  onPressed: () {
                    setState(() {
                      _fileName = null;
                      _filePath = null;
                    });
                    widget.controller.updateAnswer(widget.question.id, null);
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
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
    // Default max rating is 5
    double maxRating = 5;

    // We don't use options in SurveyQuestion as it doesn't exist in the model

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BackgroundDecorator.cardPatternDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'التقييم: ${controller.getAnswer(question.id) ?? '0'}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'NotoKufiArabic',
            ),
          ),
          SizedBox(height: 12),
          Center(
            child: RatingBar.builder(
              initialRating:
                  controller.getAnswer(question.id) != null
                      ? double.parse(controller.getAnswer(question.id)!)
                      : 0,
              minRating: 0,
              maxRating: maxRating,
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: maxRating.toInt(),
              itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder:
                  (context, _) => Icon(Icons.star, color: AppColors.primary),
              onRatingUpdate: (rating) {
                controller.updateAnswer(question.id, rating.toString());
              },
            ),
          ),
          if (maxRating > 0)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ضعيف',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'NotoKufiArabic',
                    ),
                  ),
                  Text(
                    'ممتاز',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'NotoKufiArabic',
                    ),
                  ),
                ],
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
  final SurveyController controller;

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
    if (widget.controller.getAnswer(widget.question.id) != null) {
      try {
        final dateStr = widget.controller.getAnswer(widget.question.id)!;
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
            child: Icon(Icons.calendar_today, color: AppColors.primary, size: 22),
          ),
          suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.black87, size: 24),
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
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
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
          widget.controller.updateAnswer(widget.question.id, value.toString());
        },
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontFamily: 'NotoKufiArabic',
        ),
        locale: const Locale('ar', 'AE'),
      ),
    );
  }
}
