# SlotSync — Setup Guide

Premium healthcare appointment booking platform built with Flutter + Firebase.

## Prerequisites

- Flutter 3.24+ / Dart 3+
- Node.js 18+ (for Cloud Functions)
- Firebase CLI: `npm install -g firebase-tools`
- Android Studio / Xcode (for mobile builds)
- Google Cloud account (Maps API)

---

## 1. Clone & Install Dependencies

```bash
cd slotsync_app
flutter pub get
cd firebase/functions && npm install && cd ../..
```

---

## 2. Firebase Setup

### Create Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create project **SlotSync**
3. Enable: **Authentication**, **Firestore**, **Storage**, **Cloud Messaging**, **Analytics**, **Crashlytics**, **Functions**

### Register Apps

```bash
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates/updates `lib/firebase_options.dart`.

### Deploy Rules & Functions

```bash
firebase deploy --only firestore:rules,storage:rules
firebase deploy --only functions
```

### Firestore Indexes

Create composite indexes (Firebase Console will prompt via error links):

| Collection     | Fields                                              |
|----------------|-----------------------------------------------------|
| appointments   | patientId ASC, appointmentDate DESC                 |
| appointments   | hospitalId ASC, appointmentDate ASC                 |
| slots          | hospitalId ASC, date ASC, isBlocked ASC             |
| reviews        | hospitalId ASC, createdAt DESC                      |
| messages       | conversationId ASC, createdAt ASC                   |

---

## 3. Authentication

In Firebase Console → Authentication → Sign-in method:

- **Email/Password** — Enable
- **Google** — Enable
- **Apple** — Enable (iOS, requires Apple Developer account)

### Android Google Sign-In Setup

```bash
cd android && ./gradlew signingReport
```

For this app, the Android package name must be:

```text
com.muz.mediconnect
```

Add these debug fingerprints to Firebase Console → Project settings → Your apps → Android app `com.muz.mediconnect`:

```text
SHA-1: 1F:48:5F:FA:CE:7A:F0:6B:60:C7:FB:D4:3E:0C:DC:2D:65:11:66:57
SHA-256: CF:9B:BC:84:94:7E:62:62:46:7D:63:53:EA:D5:1F:B9:D4:B2:5C:CB:56:C5:16:C4:49:D7:7E:C6:F7:80:11:CF
```

After adding the fingerprints:

1. Re-open Firebase Console → Authentication → Sign-in method → Google and make sure it is enabled.
2. Download a fresh `android/app/google-services.json`.
3. Replace the existing file in this project.
4. Confirm the new `google-services.json` includes non-empty `oauth_client` entries for `com.muz.mediconnect`.

If `oauth_client` stays empty, Google sign-in on Android will fail with `ApiException: 10` / `DEVELOPER_ERROR`.

---

## 4. Google Maps

### Get API Key

1. [Google Cloud Console](https://console.cloud.google.com) → Enable **Maps SDK for Android/iOS**
2. Create API key, restrict by app bundle ID

### Android

`android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY"/>
```

### iOS

`ios/Runner/AppDelegate.swift`:

```swift
GMSServices.provideAPIKey("YOUR_API_KEY")
```

Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>SlotSync needs your location to find nearby hospitals.</string>
```

---

## 5. Android Build

```bash
flutter run -d android
flutter build apk --release
flutter build appbundle --release
```

---

## 6. iOS Build

```bash
cd ios && pod install && cd ..
flutter run -d ios
flutter build ios --release
```

---

## 7. Push Notifications

### Android

Add `google-services.json`. FCM works automatically with Firebase.

### iOS

1. Upload APNs key in Firebase Console
2. Enable Push Notifications capability in Xcode
3. Add background modes: `remote-notification`

---

## 8. Firestore Schema

```
users/{userId}
hospitals/{hospitalId}
departments/{deptId}
services/{serviceId}
appointments/{appointmentId}
slots/{slotId}
reviews/{reviewId}
messages/{messageId}
notifications/{notificationId}
waitlists/{waitlistId}
documents/{documentId}
analytics/{docId}
```

See model files in `lib/shared/models/` for full field definitions.

---

## 9. Running Tests

```bash
flutter test
```

---

## 10. Design System

| Token      | Value     |
|------------|-----------|
| Background | `#F5F7FB` |
| Primary    | `#2D7FF9` |
| Accent     | `#5BA4FF` |
| Cards      | `#FFFFFF` |
| Text       | `#111827` |
| Subtext    | `#6B7280` |
| Radius     | 20px      |
| Font       | DM Sans   |

Bottom navigation: **Home · Search · Appointments · Messages · Profile**

---

## 11. Deployment Checklist

- [ ] Replace Firebase config with production project
- [ ] Deploy Firestore & Storage rules
- [ ] Deploy Cloud Functions
- [ ] Create Firestore indexes
- [ ] Configure Google Maps API keys
- [ ] Enable Crashlytics
- [ ] Test auth flows (Email, Google, Apple)
- [ ] Test push notifications on physical devices
