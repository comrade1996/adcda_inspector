/// Question types for survey questions
enum QuestionType {
  checkBox(1),
  radioButton(2),
  textBox(3),
  dropDown(4),
  multiSelect(5),
  rating(6),
  date(7),
  numeric(8),
  fileUpload(9),
  comment(10);

  final int value;
  const QuestionType(this.value);

  factory QuestionType.fromInt(int value) {
    return QuestionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => QuestionType.textBox,
    );
  }
}
