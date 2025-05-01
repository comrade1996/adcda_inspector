/// Question types for survey questions
enum QuestionType {
  checkBox,    // 1
  radioButton, // 2
  textBox,     // 3
  dropDown,    // 4
  multiSelect, // 5
  rating,      // 6
  date,        // 7
  numeric,     // 8
  fileUpload,  // 9
  comment;      // 10

  /// Convert from int to QuestionType - directly matches server enum values
  static QuestionType fromInt(int value) => QuestionTypeExtension.fromInt(value);

  /// Convert string to QuestionType (needed for backward compatibility)
  static QuestionType fromString(String value) => QuestionTypeExtension.fromString(value);
}

/// Extension to convert int to QuestionType
extension QuestionTypeExtension on QuestionType {
  // Convert from int to QuestionType - directly matches server enum values
  static QuestionType fromInt(int value) {
    switch (value) {
      case 1: return QuestionType.checkBox;
      case 2: return QuestionType.radioButton;
      case 3: return QuestionType.textBox;
      case 4: return QuestionType.dropDown;
      case 5: return QuestionType.multiSelect;
      case 6: return QuestionType.rating;
      case 7: return QuestionType.date;
      case 8: return QuestionType.numeric;
      case 9: return QuestionType.fileUpload;
      case 10: return QuestionType.comment;
      default: return QuestionType.textBox; // Default fallback
    }
  }
  
  // Convert string to QuestionType (needed for backward compatibility)
  static QuestionType fromString(String value) {
    if (value == null || value.isEmpty) {
      return QuestionType.textBox; // Default for empty strings
    }
    
    // Try to parse as integer first - PREFERRED METHOD
    final intValue = int.tryParse(value.trim());
    if (intValue != null) {
      return fromInt(intValue); // Use the integer mapping directly
    }
    
    // Minimal text fallback only if absolutely needed
    final lowerType = value.toLowerCase().trim();
    if (lowerType.contains('check')) return QuestionType.checkBox;      // 1
    if (lowerType.contains('radio')) return QuestionType.radioButton;   // 2
    if (lowerType.contains('text') && !lowerType.contains('area')) return QuestionType.textBox;    // 3
    if (lowerType.contains('drop')) return QuestionType.dropDown;       // 4
    if (lowerType.contains('multi')) return QuestionType.multiSelect;   // 5
    if (lowerType.contains('rat')) return QuestionType.rating;          // 6
    if (lowerType.contains('date')) return QuestionType.date;           // 7
    if (lowerType.contains('num')) return QuestionType.numeric;         // 8
    if (lowerType.contains('file')) return QuestionType.fileUpload;     // 9
    if (lowerType.contains('comment') || lowerType.contains('area')) return QuestionType.comment; // 10
    
    // Default fallback
    return QuestionType.textBox;
  }
  
  // Convert from QuestionType to int - needed for API submission
  int toInt() {
    switch (this) {
      case QuestionType.checkBox: return 1;
      case QuestionType.radioButton: return 2;
      case QuestionType.textBox: return 3;
      case QuestionType.dropDown: return 4; 
      case QuestionType.multiSelect: return 5;
      case QuestionType.rating: return 6;
      case QuestionType.date: return 7;
      case QuestionType.numeric: return 8;
      case QuestionType.fileUpload: return 9;
      case QuestionType.comment: return 10;
    }
  }
  
  // Readable name for the question type
  String get name {
    switch (this) {
      case QuestionType.checkBox: return 'Checkbox';
      case QuestionType.radioButton: return 'Radio Button';
      case QuestionType.textBox: return 'Text Field';
      case QuestionType.dropDown: return 'Dropdown';
      case QuestionType.multiSelect: return 'Multi-Select';
      case QuestionType.rating: return 'Rating Scale';
      case QuestionType.date: return 'Date Picker';
      case QuestionType.numeric: return 'Number Input';
      case QuestionType.fileUpload: return 'File Upload';
      case QuestionType.comment: return 'Text Area';
    }
  }
}
