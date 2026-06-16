# 🔥 Firebase Setup Guide for MediConnect

## Step 1: Create Firebase Project

1. Go to https://console.firebase.google.com/
2. Click **"Add project"** (or "Create a project")
3. Enter project name: **`MediConnect`**
4. Click **Continue**
5. (Optional) Enable Google Analytics
6. Click **Create project**
7. Wait for project creation, then click **Continue**

---

## Step 2: Add Android App

1. Click the **Android icon** (⚙️ Settings → Add app → Android)
2. Fill in:
   - **Android package name**: `com.muz.mediconnect`
   - **App nickname**: `MediConnect Android`
   - **Debug signing certificate SHA-1**: `1F:48:5F:FA:CE:7A:F0:6B:60:C7:FB:D4:3E:0C:DC:2D:65:11:66:57`
3. Click **Register app**
4. Click **Download google-services.json**
5. **IMPORTANT**: Move this file to:
   ```
   c:\Users\muz45\slotsync_app\android\app\google-services.json
   ```
6. Click **Next** through the remaining steps
7. Click **Continue to console**

Add this SHA-256 as well after app creation in Firebase Console → Project settings → Your apps → `com.muz.mediconnect`:

```text
CF:9B:BC:84:94:7E:62:62:46:7D:63:53:EA:D5:1F:B9:D4:B2:5C:CB:56:C5:16:C4:49:D7:7E:C6:F7:80:11:CF
```

Then re-download `google-services.json`. The file should contain non-empty `oauth_client` entries. If it shows `"oauth_client": []`, Google sign-in is still not configured correctly for Android.

---

## Step 3: Add Web App (For Windows/Desktop Testing)

1. Click the **Web icon** `</>` 
2. Fill in:
   - **App nickname**: `MediConnect Web`
   - ✅ Check "Also set up Firebase Hosting" (optional)
3. Click **Register app**
4. **COPY the firebaseConfig** - it looks like this:

```javascript
const firebaseConfig = {
  apiKey: "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXX",
  authDomain: "mediconnect-XXXXX.firebaseapp.com",
  projectId: "mediconnect-XXXXX",
  storageBucket: "mediconnect-XXXXX.appspot.com",
  messagingSenderId: "123456789012",
  appId: "1:123456789012:web:abcdef123456"
};
```

5. **Share this config with me** (I need all values)
6. Click **Continue to console**

---

## Step 4: Enable Email/Password Authentication

1. In Firebase Console, click **Authentication** in left menu
2. Click **Get started**
3. Click **Sign-in method** tab
4. Click **Email/Password**
5. Toggle **Enable**
6. Click **Save**

---

## Step 5: Create Firestore Database

1. Click **Firestore Database** in left menu
2. Click **Create database**
3. Select **Start in test mode** (for development)
4. Click **Next**
5. Choose a location **closest to you**
6. Click **Enable**

---

## Step 6: Set Firestore Security Rules (Test Mode)

Your rules should look like this (for development):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

---

## Step 7: Share Your Firebase Config

**Please share the following values with me:**

```
apiKey: "YOUR_API_KEY"
authDomain: "YOUR_PROJECT.firebaseapp.com"
projectId: "YOUR_PROJECT_ID"
storageBucket: "YOUR_PROJECT.appspot.com"
messagingSenderId: "YOUR_SENDER_ID"
appId: "YOUR_APP_ID"
```

Once you provide these, I'll:
✅ Configure Firebase in your app
✅ Set up authentication with email/password
✅ Create hospital and patient databases
✅ Connect all screens to Firebase
✅ Test everything works

---

## Quick Checklist

- [ ] Created Firebase project
- [ ] Downloaded `google-services.json` and placed in `android/app/`
- [ ] Copied Firebase web config (apiKey, projectId, etc.)
- [ ] Enabled Email/Password authentication
- [ ] Created Firestore Database in test mode
- [ ] Ready to share config with AI

---

## Need Help?

If you get stuck at any step, let me know which step and I'll guide you through it!
