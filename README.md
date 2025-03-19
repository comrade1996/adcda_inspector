# ADCDA Survey Application

A comprehensive survey application developed for the Abu Dhabi Civil Defence Authority (ADCDA) to evaluate the readiness of civil defense centers.

## Features

- **Dynamic Survey Loading**: Surveys are loaded dynamically from the server or from a local JSON file.
- **Multiple Question Types**: Support for various question types including:
  - Checkbox
  - Radio Button
  - Text Box
  - Dropdown
  - Multi-Select
  - Rating
  - Date
  - Numeric
  - File Upload
  - Comment
- **Validation**: Built-in validation for required fields and custom validation using regex patterns.
- **Modern UI/UX**: Tailwind-like styling with animations to enhance user experience.
- **Responsive Design**: Works seamlessly on various screen sizes.
- **State Management**: Utilizes GetX for efficient state management.
- **Multi-language Support**: Ready for localization with English, Arabic, and Urdu support.

## Project Structure

```
lib/
├── constants/      # Application-wide constants
├── controllers/    # GetX controllers for state management
├── data/           # Static data and mock services
├── models/         # Data models for the application
├── screens/        # UI screens
├── services/       # API and data services
├── utils/          # Utility functions and helpers
└── widgets/        # Reusable UI components
```

## Getting Started

### Prerequisites

- Flutter SDK (3.7.0 or higher)
- Dart SDK (3.0.0 or higher)

### Installation

1. Clone the repository:
   ```
   git clone <repository-url>
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Run the application:
   ```
   flutter run
   ```

## Survey Models

The application implements the following key models:

- **Survey**: Represents a complete survey with questions.
- **SurveyQuestion**: Represents a single question in the survey.
- **SurveyAnswer**: Represents possible answers for multiple-choice questions.
- **SurveySubmit**: Used when submitting a completed survey.
- **SurveySubmitAnswer**: Represents answers submitted by users.

## Usage

1. Start the application
2. Enter your email to begin the survey
3. Answer each question and navigate using the next/previous buttons
4. Review your answers before submitting
5. Submit the survey to save your responses

## Development

### Adding New Question Types

To add a new question type:

1. Add the new type to `QuestionType` enum in `lib/models/question_type.dart`
2. Create a new widget for the question type in `lib/widgets/question_widgets.dart`
3. Add the new case to the `_getQuestionWidget()` method in the `QuestionWidget` class

### Modifying the Survey Data

The survey data is stored in `assets/survey_data.json`. You can modify this file to change the questions, or implement a server-side API to load the data dynamically.

## Testing

Run the tests using:

```
flutter test
```

## Deployment

### Building for Production

```
flutter build apk --release  # For Android
flutter build ios            # For iOS
flutter build web            # For Web
```

### Server Configuration

For production deployment, update the API endpoints in `lib/constants/app_constants.dart` to point to your production server.

## License

This project is proprietary software developed for the Abu Dhabi Civil Defence Authority.

## Acknowledgments

- Flutter Team for the excellent framework
- GetX library for state management solutions
- All contributors to the project
