# ADCDA Inspector - Internal Tester Management Guide

## Overview

This document outlines how to manage internal testers for the ADCDA Inspector app using Firebase App Distribution.

## Tester Groups Structure

### Primary Groups

1. **adcda-internal** (Production)

   - ADCDA management team
   - Quality assurance team
   - Key stakeholders

2. **adcda-staging-testers** (Staging)

   - Development team
   - Extended QA team
   - Beta testers

3. **adcda-dev-testers** (Development)
   - Core development team
   - Technical leads

## Adding New Testers

### Via Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: `adcda-inspector-prod`
3. Navigate to App Distribution
4. Click on desired tester group
5. Click "Add testers"
6. Enter email addresses (one per line)
7. Click "Add testers"

### Via CLI (Advanced)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Add testers to group
firebase appdistribution:testers:add --project adcda-inspector-prod \
  --group adcda-internal \
  --emails "user1@adcda.ae,user2@adcda.ae"
```

## Tester Onboarding Process

### 1. Initial Setup

When a new tester is added:

1. They receive an email invitation
2. Must install Firebase App Distribution app on their device
3. Accept the invitation through the app
4. Will receive notifications for new builds

### 2. Device Requirements

**Android:**

- Android 5.0 (API level 21) or higher
- Firebase App Distribution app installed
- Allow installation from unknown sources

**iOS:**

- iOS 11.0 or higher
- Firebase App Distribution app installed
- Device UDID registered (for development builds)

### 3. Access Instructions

Send new testers the following:

```
Welcome to ADCDA Inspector Internal Testing!

1. Install Firebase App Distribution:
   - Android: https://play.google.com/store/apps/details?id=com.google.firebase.appdistribution
   - iOS: https://apps.apple.com/app/firebase-app-distribution/id1530136547

2. Accept the invitation email you received

3. You'll receive notifications when new builds are available

4. For support, contact: [development-team@adcda.ae]
```

## Release Process

### Automated Releases

Builds are automatically distributed when:

- Code is pushed to `main` branch (production builds)
- Code is pushed to `develop` branch (staging builds)
- Pull requests are merged

### Manual Releases

To trigger a manual release:

1. Go to GitHub repository
2. Click "Actions" tab
3. Select "Firebase App Distribution" workflow
4. Click "Run workflow"
5. Enter custom release notes if needed

### Release Notes

Release notes are automatically generated from:

- Git commit messages
- RELEASE_NOTES.md file
- Manual input during workflow dispatch

## Monitoring and Analytics

### Build Statistics

Track the following metrics:

- Number of downloads per build
- Crash reports and feedback
- Adoption rate of new versions
- Tester engagement

### Feedback Collection

Testers can provide feedback through:

- Firebase App Distribution feedback feature
- Direct email to development team
- Internal issue tracking system

## Security and Compliance

### Access Control

- Only authorized ADCDA personnel can be added as testers
- Regular audit of tester list (quarterly)
- Remove access for departed employees immediately

### Data Protection

- All builds are internal-only, not public
- Testers must agree to confidentiality terms
- No external distribution allowed

### Compliance Requirements

- Builds comply with ADCDA internal security policies
- Regular security scans of distributed apps
- Audit trail of all distributions maintained

## Troubleshooting

### Common Issues

1. **Tester not receiving builds**

   - Check email address is correct
   - Verify they're in the right tester group
   - Ensure Firebase App Distribution app is installed

2. **Installation fails on Android**

   - Enable "Install unknown apps" permission
   - Check device compatibility
   - Clear Firebase App Distribution app cache

3. **iOS installation issues**
   - Verify device UDID is registered
   - Check provisioning profile validity
   - Ensure iOS version compatibility

### Support Contacts

- **Technical Issues**: development-team@adcda.ae
- **Access Requests**: it-admin@adcda.ae
- **General Questions**: project-manager@adcda.ae

## Best Practices

### For Administrators

1. **Regular Cleanup**

   - Remove inactive testers monthly
   - Archive old builds to save storage
   - Update tester groups based on project needs

2. **Communication**

   - Send release announcements to testers
   - Provide clear testing instructions
   - Set expectations for feedback timeline

3. **Version Management**
   - Use semantic versioning
   - Maintain clear release notes
   - Tag important milestone builds

### For Testers

1. **Testing Guidelines**

   - Test on your primary device first
   - Report issues promptly with details
   - Test both Arabic and English interfaces
   - Verify UAE Pass integration works

2. **Feedback Quality**
   - Include device information
   - Provide steps to reproduce issues
   - Include screenshots when relevant
   - Test in different network conditions

## Metrics and Reporting

### Weekly Reports

Generate weekly reports including:

- Number of builds distributed
- Download statistics
- Crash reports summary
- Tester feedback summary

### Monthly Reviews

Conduct monthly reviews of:

- Tester group composition
- Distribution effectiveness
- Security compliance
- Process improvements

---

_Last updated: [Current Date]_
_Document owner: ADCDA Development Team_
