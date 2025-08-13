# Firebase App Distribution Setup Checklist

Use this checklist to ensure your Firebase App Distribution CI/CD pipeline is properly configured.

## ✅ Prerequisites Setup

- [ ] Firebase account with admin access
- [ ] GitHub repository with admin access
- [ ] Flutter SDK installed (3.24.3 or later)
- [ ] Android Studio installed
- [ ] Java JDK 17 installed
- [ ] Git configured with repository access

## ✅ Firebase Project Configuration

- [ ] Firebase project created: `adcda-inspector-prod`
- [ ] Android app added with package name: `com.adcda.inspector`
- [ ] iOS app added with bundle ID: `com.adcda.inspector`
- [ ] App Distribution enabled in Firebase Console
- [ ] Tester group created: `adcda-internal`
- [ ] Internal team members added to tester group

## ✅ Android Configuration

- [ ] Keystore created using `scripts\create-keystore.bat`
- [ ] `android\key.properties` created from template
- [ ] Keystore passwords configured in `key.properties`
- [ ] `google-services.json` downloaded and placed in `android\app\`
- [ ] Android build configuration updated with Firebase plugins
- [ ] ProGuard rules created

## ✅ iOS Configuration (if building iOS)

- [ ] Apple Developer account enrolled
- [ ] Distribution certificate created and exported as .p12
- [ ] Provisioning profile created for enterprise distribution
- [ ] `GoogleService-Info.plist` downloaded and placed in `ios\Runner\`
- [ ] `ExportOptions.plist` configured with team ID
- [ ] iOS signing configuration updated

## ✅ GitHub Secrets Configuration

### Firebase Secrets

- [ ] `FIREBASE_SERVICE_ACCOUNT` (service account JSON, base64 encoded)
- [ ] `FIREBASE_ANDROID_APP_ID` (from Firebase Console)
- [ ] `FIREBASE_IOS_APP_ID` (from Firebase Console, if building iOS)
- [ ] `GOOGLE_SERVICES_JSON` (google-services.json content, base64 encoded)
- [ ] `GOOGLE_SERVICE_INFO_PLIST` (GoogleService-Info.plist content, base64 encoded)

### Android Signing Secrets

- [ ] `KEYSTORE_BASE64` (keystore file content, base64 encoded)
- [ ] `KEYSTORE_PASSWORD` (keystore password)
- [ ] `KEY_PASSWORD` (key password)
- [ ] `KEY_ALIAS` (set to: adcda-inspector)

### iOS Signing Secrets (if building iOS)

- [ ] `P12_CERTIFICATE` (certificate .p12 file, base64 encoded)
- [ ] `P12_PASSWORD` (certificate password)
- [ ] `PROVISIONING_PROFILE` (provisioning profile, base64 encoded)

## ✅ Environment Configuration

- [ ] Environment files created in `assets\env\`:
  - [ ] `.env.prod` with production Firebase configuration
  - [ ] `.env.staging` with staging Firebase configuration
  - [ ] `.env.dev` with development Firebase configuration
- [ ] Firebase app IDs updated in environment files
- [ ] Tester groups configured in environment files

## ✅ Code Integration

- [ ] Firebase dependencies added to `pubspec.yaml`
- [ ] Firebase initialization added to `main.dart`
- [ ] Environment loading configured in `main.dart`
- [ ] Firebase service helper created
- [ ] Assets configuration updated to include environment files

## ✅ CI/CD Pipeline

- [ ] GitHub Actions workflow created: `.github\workflows\firebase-distribution.yml`
- [ ] Workflow permissions configured
- [ ] Build triggers configured (main, develop branches)
- [ ] Manual workflow dispatch enabled
- [ ] Artifact upload configured

## ✅ Security Configuration

- [ ] `.gitignore` updated to exclude sensitive files
- [ ] Template files created for configuration
- [ ] Sensitive files added to `.gitignore`
- [ ] Service account permissions configured

## ✅ Testing and Validation

- [ ] Local Android build test successful
- [ ] Local iOS build test successful (if applicable)
- [ ] GitHub Actions workflow test successful
- [ ] Firebase distribution test successful
- [ ] Tester group receives build notifications
- [ ] App installs and runs correctly on test devices

## ✅ Documentation

- [ ] Setup documentation created
- [ ] Tester management guide created
- [ ] Release notes template created
- [ ] Build scripts created for local development
- [ ] Troubleshooting guide available

## ✅ Final Verification

- [ ] All secrets properly configured and tested
- [ ] All template files have corresponding real files (not committed)
- [ ] CI/CD pipeline runs without errors
- [ ] Internal testers can successfully install and run the app
- [ ] Release process documented and tested
- [ ] Team trained on tester management

## 🚀 Go Live

Once all items are checked:

1. **Push to main branch** to trigger first production build
2. **Verify distribution** to internal testers
3. **Collect feedback** from initial test group
4. **Monitor** GitHub Actions for any issues
5. **Document** any additional setup steps discovered

## 📞 Support

If you encounter issues during setup:

1. Check GitHub Actions logs for detailed error messages
2. Verify all secrets are properly base64 encoded
3. Ensure Firebase project permissions are correct
4. Review Firebase Console for any configuration issues
5. Contact development team for assistance

---

**Setup completed by**: ******\_\_\_\_******  
**Date**: ******\_\_\_\_******  
**Verified by**: ******\_\_\_\_******  
**Date**: ******\_\_\_\_******
