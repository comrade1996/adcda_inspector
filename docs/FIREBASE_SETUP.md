# Firebase App Distribution Setup Guide

This guide will help you set up Firebase App Distribution for the ADCDA Inspector app with automated CI/CD pipeline.

## Prerequisites

- Firebase account with admin access
- GitHub repository with admin access
- Android Studio (for Android keystore generation)
- Xcode (for iOS signing, macOS only)

## Step 1: Firebase Project Setup

### 1.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `adcda-inspector-prod`
4. Enable Google Analytics (optional)
5. Complete project creation

### 1.2 Add Android App

1. In Firebase Console, click "Add app" → Android
2. Enter package name: `com.adcda.inspector`
3. Enter app nickname: `ADCDA Inspector Android`
4. Download `google-services.json`
5. Place it in `android/app/google-services.json`

### 1.3 Add iOS App

1. In Firebase Console, click "Add app" → iOS
2. Enter bundle ID: `com.adcda.inspector`
3. Enter app nickname: `ADCDA Inspector iOS`
4. Download `GoogleService-Info.plist`
5. Place it in `ios/Runner/GoogleService-Info.plist`

### 1.4 Enable App Distribution

1. In Firebase Console, go to "App Distribution"
2. Click "Get started"
3. Create tester group: `adcda-internal`
4. Add internal team email addresses

## Step 2: Android Signing Setup

### 2.1 Create Keystore

Run the keystore creation script:

```bash
scripts\create-keystore.bat
```

Or manually:

```bash
keytool -genkey -v -keystore android/keystore/adcda-inspector-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias adcda-inspector
```

### 2.2 Configure Key Properties

1. Copy `android/key.properties.template` to `android/key.properties`
2. Fill in your keystore details:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=adcda-inspector
storeFile=keystore/adcda-inspector-key.jks
```

## Step 3: iOS Signing Setup (macOS only)

### 3.1 Apple Developer Account

1. Enroll in Apple Developer Program
2. Create App ID: `com.adcda.inspector`
3. Create Distribution Certificate
4. Create Provisioning Profile for Enterprise Distribution

### 3.2 Export Certificate

1. Open Keychain Access
2. Export certificate as `.p12` file
3. Set password for certificate

### 3.3 Update Export Options

Edit `ios/Runner/ExportOptions.plist`:

```xml
<key>teamID</key>
<string>YOUR_TEAM_ID</string>
<key>provisioningProfiles</key>
<dict>
    <key>com.adcda.inspector</key>
    <string>YOUR_PROVISIONING_PROFILE_NAME</string>
</dict>
```

## Step 4: GitHub Secrets Configuration

Add the following secrets to your GitHub repository:

### Firebase Secrets

- `FIREBASE_SERVICE_ACCOUNT`: Service account JSON (base64 encoded)
- `FIREBASE_ANDROID_APP_ID`: Android app ID from Firebase
- `FIREBASE_IOS_APP_ID`: iOS app ID from Firebase
- `GOOGLE_SERVICES_JSON`: google-services.json content (base64 encoded)
- `GOOGLE_SERVICE_INFO_PLIST`: GoogleService-Info.plist content (base64 encoded)

### Android Signing Secrets

- `KEYSTORE_BASE64`: Keystore file content (base64 encoded)
- `KEYSTORE_PASSWORD`: Keystore password
- `KEY_PASSWORD`: Key password
- `KEY_ALIAS`: Key alias (adcda-inspector)

### iOS Signing Secrets (if building iOS)

- `P12_CERTIFICATE`: Certificate .p12 file (base64 encoded)
- `P12_PASSWORD`: Certificate password
- `PROVISIONING_PROFILE`: Provisioning profile (base64 encoded)

## Step 5: Service Account Setup

### 5.1 Create Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Go to IAM & Admin → Service Accounts
4. Create new service account: `firebase-distribution-ci`
5. Download JSON key file

### 5.2 Grant Permissions

1. In Firebase Console, go to Project Settings → Service Accounts
2. Add the service account email
3. Grant "Firebase App Distribution Admin" role

### 5.3 Encode Service Account

```bash
# Linux/macOS
base64 -i service-account.json

# Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("service-account.json"))
```

## Step 6: Environment Configuration

Update environment files in `assets/env/`:

### .env.prod

```env
FIREBASE_PROJECT_ID=adcda-inspector-prod
FIREBASE_ANDROID_APP_ID=1:123456789:android:abcdef123456
FIREBASE_IOS_APP_ID=1:123456789:ios:abcdef123456
FIREBASE_TESTER_GROUPS=adcda-internal
```

## Step 7: Testing the Setup

### 7.1 Local Build Test

```bash
# Android
scripts\build-android.bat

# iOS (macOS only)
flutter build ios --release
```

### 7.2 CI/CD Test

1. Push changes to `main` or `develop` branch
2. Check GitHub Actions workflow
3. Verify builds are distributed to Firebase
4. Check tester group receives notification

## Step 8: Managing Testers

### 8.1 Add Testers

1. Go to Firebase Console → App Distribution
2. Click on tester group
3. Add email addresses
4. Testers will receive invitation emails

### 8.2 Release Management

- Builds are automatically distributed on push to main/develop
- Manual releases can be triggered via GitHub Actions
- Release notes are generated from commit messages

## Troubleshooting

### Common Issues

1. **Build fails with signing error**

   - Check keystore path and passwords
   - Verify key.properties file exists

2. **Firebase distribution fails**

   - Verify service account permissions
   - Check app IDs in environment files

3. **iOS build fails**
   - Verify provisioning profile and certificate
   - Check team ID and bundle identifier

### Support

For technical issues, contact the development team or check:

- [Firebase Documentation](https://firebase.google.com/docs/app-distribution)
- [Flutter Documentation](https://flutter.dev/docs)
- GitHub Actions logs for detailed error messages
