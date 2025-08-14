# المفتش الذكي - ADCDA Inspector

A comprehensive smart inspection application developed for the Abu Dhabi Civil Defence Authority (ADCDA) to evaluate the readiness of civil defense centers and conduct digital surveys.

## Features

### 🔐 **Authentication & Security**
- **UAE Pass Integration**: Secure OAuth 2.0 authentication with PKCE flow
- **Biometric Authentication**: Face ID and fingerprint support
- **Multi-environment Support**: Development, staging, and production configurations

### 📋 **Survey Management**
- **Dynamic Survey Loading**: Surveys loaded dynamically from server or local JSON
- **Multiple Question Types**: Support for various question types including:
  - Radio Button (Single Selection)
  - Checkbox (Multiple Selection)
  - Text Input (Multi-line comments)
  - Rating Scale (Star-based rating)
  - Date Picker (Calendar selection)
  - File Upload (Document attachment)
- **Smart Validation**: Built-in validation for required fields with visual feedback
- **Answer Persistence**: Maintains user answers across navigation

### 🎨 **Modern UI/UX**
- **Dark/Light Theme Support**: Automatic theme switching with user preference
- **Responsive Design**: Optimized for various screen sizes and orientations
- **Modern Card-based Design**: Clean, intuitive interface
- **Smooth Animations**: Enhanced user experience with fluid transitions
- **Arabic RTL Support**: Full right-to-left language support

### 🌐 **Internationalization**
- **Multi-language Support**: English and Arabic localization
- **Dynamic Language Switching**: Real-time language change with country flags
- **Localized Content**: All UI elements properly translated

### 🚀 **CI/CD & Distribution**
- **Firebase App Distribution**: Automated build and distribution pipeline
- **GitHub Actions**: Continuous integration with automated testing
- **Multi-platform Builds**: Android APK/AAB and iOS IPA generation
- **Environment-based Deployment**: Separate configurations for dev/staging/prod

## Project Structure

```
lib/
├── config/         # Environment configuration and settings
├── constants/      # Application-wide constants and colors
├── controllers/    # GetX controllers for state management
├── data/           # Static data and mock services
├── l10n/          # Localization files (English/Arabic)
├── models/         # Data models for surveys and authentication
├── screens/        # UI screens (login, dashboard, surveys)
├── services/       # API services, UAE Pass, and authentication
├── theme/          # Dark/light theme configurations
├── uaepass/        # Custom UAE Pass integration
├── utils/          # Utility functions and helpers
└── widgets/        # Reusable UI components
```

## Technical Stack

- **Framework**: Flutter 3.32.8
- **State Management**: GetX
- **Authentication**: UAE Pass OAuth 2.0 with PKCE
- **Localization**: Flutter Intl (English/Arabic)
- **Theme**: Custom dark/light theme system
- **Storage**: Secure storage for tokens and preferences
- **CI/CD**: GitHub Actions + Firebase App Distribution
- **Platforms**: Android, iOS, Web

## Getting Started

### Prerequisites

- Flutter SDK (3.32.8 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / Xcode for platform-specific development
- Firebase project setup for distribution

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd adcda_inspector
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up environment files:
   ```bash
   # Copy template files and configure with your credentials
   cp assets/env/.env.dev.template assets/env/.env.dev
   cp assets/env/.env.staging.template assets/env/.env.staging
   cp assets/env/.env.prod.template assets/env/.env.prod
   ```

4. Run the application:
   ```bash
   flutter run --flavor dev  # Development
   flutter run --flavor staging  # Staging
   flutter run --flavor prod  # Production
   ```

## UAE Pass Integration

The application integrates with UAE Pass for secure government authentication:

### Features
- **OAuth 2.0 Flow**: Standard authorization code flow with PKCE
- **Multi-Environment**: Support for development, staging, and production
- **App Detection**: Automatic detection of UAE Pass app installation
- **Browser Fallback**: Web-based authentication when app is unavailable
- **Secure Storage**: Encrypted token storage with automatic refresh

### Configuration
Environment-specific UAE Pass settings are configured in:
- `assets/env/.env.dev` - Development (Sandbox)
- `assets/env/.env.staging` - Staging environment
- `assets/env/.env.prod` - Production environment

## Application Flow

### 1. Authentication
- Launch app → Splash screen with logo
- Login screen with UAE Pass integration
- Biometric authentication option
- Secure token management

### 2. Dashboard
- Modern card-based interface
- Statistics overview (Pending, Completed, Overdue, Today)
- Quick access to surveys and settings
- Theme toggle (Dark/Light mode)

### 3. Survey Completion
- Dynamic question loading
- Multiple question types with validation
- Progress tracking with navigation
- Answer persistence across sessions
- Preview before submission

### 4. Submission & Sync
- Offline capability with local storage
- Automatic sync when online
- Submission confirmation
- Result tracking and history

## Development Guide

### Environment Setup

1. **Firebase Configuration**:
   ```bash
   # Add your Firebase configuration files
   android/app/google-services.json
   ios/Runner/GoogleService-Info.plist
   ```

2. **UAE Pass Setup**:
   - Register your app with UAE Pass
   - Configure redirect URIs: `adcdainspector://uaepass/callback`
   - Update environment files with your credentials

3. **Keystore Setup** (Android):
   ```bash
   # Generate keystore for release builds
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

### Building & Testing

```bash
# Development build
flutter run --flavor dev

# Release builds
flutter build apk --release --flavor prod
flutter build appbundle --release --flavor prod
flutter build ios --release --flavor prod

# Run tests
flutter test
flutter test --coverage
```

## CI/CD Pipeline

The project includes automated GitHub Actions workflows:

### Features
- **Automated Builds**: Android APK/AAB and iOS IPA generation
- **Firebase Distribution**: Automatic distribution to testers
- **Environment Management**: Separate builds for dev/staging/prod
- **Security**: Encrypted secrets management
- **Artifact Storage**: Build artifacts with 30-day retention

### Setup
1. Configure GitHub Secrets:
   - `FIREBASE_ANDROID_APP_ID`
   - `FIREBASE_SERVICE_ACCOUNT`
   - `KEYSTORE_BASE64`
   - `GOOGLE_SERVICES_JSON`

2. Trigger builds:
   - Push to `main` or `develop` branches
   - Manual workflow dispatch with custom release notes

## Deployment

### Firebase App Distribution
- **Internal Distribution**: ADCDA team members only
- **Tester Groups**: Organized by department/role
- **Release Notes**: Automated with build information
- **Version Management**: Semantic versioning with build numbers

### Production Release
1. Update version in `pubspec.yaml`
2. Test thoroughly in staging environment
3. Create production build via GitHub Actions
4. Distribute to production tester group
5. Monitor for issues and feedback

## Security Considerations

- **OAuth 2.0 + PKCE**: Secure authentication flow
- **Token Encryption**: All sensitive data encrypted at rest
- **Certificate Pinning**: API communication security
- **Biometric Protection**: Device-level security integration
- **Environment Isolation**: Separate configurations per environment

## Troubleshooting

### Common Issues
1. **UAE Pass Authentication Fails**:
   - Check redirect URI configuration
   - Verify environment variables
   - Ensure UAE Pass app is installed (for app-based flow)

2. **Build Failures**:
   - Verify all secrets are configured in GitHub
   - Check keystore and certificate validity
   - Ensure Firebase configuration files are present

3. **Theme Issues**:
   - Clear app data and restart
   - Check system theme settings
   - Verify theme controller initialization

## License

This project is proprietary software developed for the Abu Dhabi Civil Defence Authority (ADCDA).

## Support & Contact

For technical support or questions:
- **Development Team**: Internal ADCDA IT Department
- **UAE Pass Issues**: UAE Pass Technical Support
- **Firebase Issues**: Firebase Console Support

## Acknowledgments

- **UAE Pass Team**: For authentication platform and support
- **Flutter Team**: For the excellent cross-platform framework
- **Firebase Team**: For distribution and analytics platform
- **GetX Community**: For state management solutions
- **ADCDA Leadership**: For project vision and requirements
