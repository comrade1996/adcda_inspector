@echo off
echo Building ADCDA Inspector for Android...

REM Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo Error: Flutter is not installed or not in PATH
    exit /b 1
)

REM Get dependencies
echo Getting Flutter dependencies...
flutter pub get

REM Clean previous builds
echo Cleaning previous builds...
flutter clean
flutter pub get

REM Check if keystore exists
if not exist "android\upload-keystore.jks" (
    echo Warning: Keystore not found at android\upload-keystore.jks
    echo Please place your existing keystore file there.
    exit /b 1
)

REM Check if key.properties exists
if not exist "android\key.properties" (
    echo Warning: key.properties not found. Please create it from template.
    echo Copy android\key.properties.template to android\key.properties and fill in values.
    exit /b 1
)

REM Check if google-services.json exists
if not exist "android\app\google-services.json" (
    echo Warning: google-services.json not found. Please add Firebase configuration.
    echo Copy android\app\google-services.json.template to android\app\google-services.json and fill in values.
    exit /b 1
)

REM Build APK
echo Building APK...
flutter build apk --release

REM Build App Bundle
echo Building App Bundle...
flutter build appbundle --release

echo.
echo Build completed successfully!
echo APK: build\app\outputs\flutter-apk\app-release.apk
echo AAB: build\app\outputs\bundle\release\app-release.aab
echo.

pause
