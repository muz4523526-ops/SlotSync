# SlotSync

> **Premium healthcare appointment booking — find, book, and manage hospital visits with ease.**

SlotSync is a cross-platform mobile app built with Flutter & Firebase that connects patients with hospitals. Patients can search nearby hospitals, browse specialties, book slots, and manage appointments — all with a modern dark-mode UI. Hospitals get a dedicated admin dashboard to manage services, slots, and appointments.

---

## Features

### Patient
- **Smart Search** — Search hospitals by name, specialty, or insurance provider with real-time filtering
- **Google Maps Integration** — Browse hospitals on an interactive map with live location markers and "Get Directions"
- **Appointment Booking** — Pick a date, view available slots, and book in seconds
- **Live Appointments** — Track upcoming, completed, and cancelled appointments with status badges
- **In-App Chat** — Communicate with hospitals directly
- **Hospital Profiles** — View ratings, reviews, specialties, accepted insurance, and contact info
- **Dark Mode** — Pure black theme with subtle neon glow accents, persisted across sessions

### Hospital Admin
- **Dashboard** — Real-time stats on appointments, services, revenue, and recent activity
- **Appointment Management** — Accept/reject bookings with auto-slot release on reject
- **Service & Slot Management** — Add/edit/remove services and time slots
- **Profile Customisation** — Update hospital info, photos, and verification status

### Shared
- **Google Sign-In** — One-tap authentication (Android, iOS, Web)
- **Role-Based Routing** — Patients and hospitals are automatically redirected to the correct interface after login
- **Responsive Layout** — Adaptive admin sidebar on desktop, bottom nav on mobile

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter 3.11+, Dart |
| **State Management** | Riverpod (auto-dispose, family providers) |
| **Routing** | GoRouter with redirect guards |
| **Backend** | Firebase Auth, Cloud Firestore, Firebase Storage |
| **Maps** | google_maps_flutter, Geolocator |
| **UI** | Google Fonts (DM Sans), custom theme with light + dark mode |
| **Architecture** | Clean Architecture (features/ data / presentation) |

---

## Architecture
```
lib/
├── config/           # Router, Firebase init, theme
├── features/
│   ├── admin/        # Hospital dashboard, appointments, services, slots
│   ├── appointments/ # Booking screen, patient appointments list
│   ├── auth/         # Login, sign-up, Google sign-in
│   ├── chat/         # Patient-hospital messaging
│   ├── dashboard/    # Patient home, shells (patient & admin)
│   ├── hospitals/    # Search, detail, repositories, models
│   └── onboarding/   # Welcome screens
├── shared/
│   ├── models/       # HospitalModel, shared data types
│   ├── providers/    # Theme provider (dark mode persistence)
│   └── widgets/      # AppCard, GlassHeader, StatusBadge, common widgets
└── theme/            # AppColors, AppTheme (light + dark tokens)
```

---

## Setup

> **This is a demo / portfolio project.** To run it, you'll need your own Firebase project and Google Maps API key.

### Prerequisites
- Flutter 3.11+
- Firebase project ([console.firebase.google.com](https://console.firebase.google.com))
- Google Maps API key ([console.cloud.google.com](https://console.cloud.google.com))

### Steps

1. **Clone**
   ```bash
   git clone https://github.com/YOUR_USERNAME/slotsync.git
   cd slotsync
   ```

2. **Add Firebase config**
   - Place `google-services.json` in `android/app/`
   - Place `GoogleService-Info.plist` in `ios/Runner/`
   - Create `lib/firebase_options.dart` via `flutterfire configure`

3. **Add Maps API key**
   - `android/app/src/main/AndroidManifest.xml` — replace `android:value` for `com.google.android.geo.API_KEY`
   - `ios/Runner/AppDelegate.swift` — replace `GMSServices.provideAPIKey("...")`

4. **Run**
   ```bash
   flutter pub get
   flutter run
   ```

> ⚠️ The repo excludes `firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`, and keystore files to prevent unauthorised use.

---

## UI Preview

| Light Mode | Dark Mode |
|------------|-----------|
| *(screenshot)* | *(screenshot)* |

*Screenshots coming soon.*

---

## License

This project is available for **educational and portfolio purposes only**. You may view and learn from the code, but you may not publish or distribute it as your own.
