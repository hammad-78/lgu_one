# LGU Connect (`lgu_one`)

An unofficial app for students of **Lahore Garrison University (LGU)**, providing small everyday facilities in one place. LGU Connect brings together student utilities: events, societies, news, jobs and internships, a lost and found board, student collaboration, a GPA/CGPA calculator, and push notifications.

Built with **Flutter** and **Firebase**.

> This is an independent student project and is not affiliated with or endorsed by Lahore Garrison University.

---

## Table of contents

- [Features](#features)
- [App flow](#app-flow)
- [Tech stack](#tech-stack)
- [Project structure](#project-structure)
- [Getting started](#getting-started)
- [Firebase setup](#firebase-setup)
- [Cloud Functions](#cloud-functions)
- [Firestore data model](#firestore-data-model)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [Flutter resources](#flutter-resources)
- [Author](#author)

---

## Features

### Open to everyone (no login)

| Feature | Description |
| --- | --- |
| **Upcoming events** | Live event list from Firestore with friendly dates ("Today", "Tomorrow", "In 3 days") and countdowns. |
| **Societies** | Browse university societies. |
| **News carousel** | Latest campus news in a swipeable carousel. |
| **Jobs and internships** | Card-swiper feed of opportunities, with links that open in the browser. |
| **GPA / CGPA calculator** | SGPA mode (courses with credit hours and grades) and CGPA mode (across semesters). Uses a 4.00 grading scale and excludes W, I and Tr grades. |
| **LGU Student Portal** | The official student portal (`student.lgu.edu.pk`) loaded inside the app through a WebView. |
| **Notifications** | In-app notification history plus push notifications, with a permission banner and shortcut to system settings if notifications are blocked. |
| **Recommendations** | Students can submit suggestions and feedback. |
| **Contact and support** | One-tap WhatsApp support. |

### Requires an LGU email

These features ask for a student email (`student@lgu.edu.pk`) before opening.

- **Lost and Found**
  - Post lost or found items with photos (uploaded to Firebase Storage, with thumbnails).
  - Anonymous, **secret-key based ownership**: an 8-character key is generated, and only its **SHA-256 hash** is stored. Use the key to edit or manage your own listing later.
  - Listings start as `pending` and go live only after admin approval.
  - Contact the poster directly on WhatsApp (Pakistani phone number formatting built in).
- **Student collaboration**
  - Post collaboration requests and join others' posts.
  - Uses the same secret-key ownership model as Lost and Found.

### Admin panel

Admins sign in with Firebase Auth. The account must also have a matching document in the `admins` collection with `isAdmin: true`.

Admins can manage:

- News
- Jobs
- Events (add and edit)
- Societies (add and edit)
- Lost and Found approvals (approve or reject pending listings)
- Collaboration posts
- Broadcast notifications

### Push notifications

Powered by Firebase Cloud Messaging and Cloud Functions:

- New event created
- Daily event reminders (every day at 9:00 AM, Asia/Karachi)
- Lost and Found listing approved
- Collaboration updates
- Admin announcements
- Tapping a notification routes to the right screen (Lost and Found or Collaboration)

---

## App flow

```text
main.dart  (Firebase, FCM background handler, timezone init)
   └── SplashScreen  (2 seconds)
         └── HomeScreen  (notification setup, dashboard, feeds)
               ├── Open access
               │     ├── Upcoming events
               │     ├── Societies
               │     ├── News and jobs feeds
               │     ├── GPA calculator
               │     └── Student portal (WebView)
               ├── LGU email gate
               │     ├── Lost and Found
               │     └── Collaboration
               └── Admin
                     └── Sign-in → Admin home → manage screens
```

---

## Tech stack

**App**

- Flutter (Dart SDK `^3.9.2`), Material with light and dark themes that follow the system setting
- Firebase Core, Cloud Firestore, Firebase Auth, Firebase Storage, Firebase Messaging
- `flutter_local_notifications`, `permission_handler`, `app_settings`, `timezone`
- `webview_flutter`, `url_launcher`, `carousel_slider`, `flutter_card_swiper`, `skeletonizer`
- `image_picker`, `crypto`, `intl`, `shared_preferences`, `fluttertoast`, `http`

**Backend**

- Cloud Firestore with security rules (`firestore.rules`)
- Firebase Cloud Functions v2 (Node.js 22, `firebase-admin`, `firebase-functions`)

**Platforms**: Android, iOS, web, Windows, macOS and Linux runner folders are included. The app is designed and tested primarily for mobile.

---

## Project structure

```text
lgu_one/
├── lib/
│   ├── main.dart                  # App entry point
│   ├── theme.dart                 # Light and dark AppTheme
│   ├── home_screen.dart           # Dashboard, feeds, notification setup
│   ├── dashboard_grid.dart        # Portal, Lost and Found, GPA shortcuts
│   ├── student_portal_screen.dart # WebView for the LGU portal
│   ├── recommendation_page.dart   # Feedback form
│   ├── about.dart
│   ├── auth/                      # Splash and LGU email dialog
│   ├── admin/                     # Admin sign-in, home and management screens
│   ├── Lost_Found/                # Listings, post/edit, secret key utils, service
│   ├── collaboration/             # Collaboration board and join flow
│   ├── events/                    # Upcoming events
│   ├── societies/                 # Society list and cards
│   ├── news_section/              # News carousel and detail
│   ├── jobs/                      # Jobs swiper and cards
│   ├── gpa/                       # GPA and CGPA calculator
│   ├── notification/              # FCM and local notification service
│   └── utils/                     # Shared helpers (WhatsApp support, etc.)
├── functions/                     # Firebase Cloud Functions (Node.js)
├── firestore.rules                # Firestore security rules
├── firebase.json
├── assets/images/                 # App icons and images
├── android/ ios/ web/ windows/ macos/ linux/
└── test/
```

---

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `^3.9.2` or newer)
- Android Studio or VS Code with the Flutter extension
- A Firebase project (see [Firebase setup](#firebase-setup))
- [Node.js 22](https://nodejs.org/) and the [Firebase CLI](https://firebase.google.com/docs/cli) if you want to deploy functions or rules

### Run the app

```bash
git clone https://github.com/hammad-78/lgu_one.git
cd lgu_one
flutter pub get
flutter run
```

To build a release APK:

```bash
flutter build apk --release
```

---

## Firebase setup

The app calls `Firebase.initializeApp()` with no options, so it relies on the platform config files.

1. Create a project in the [Firebase console](https://console.firebase.google.com/).
2. Add an **Android** app with package name `com.example.lgu_one` (or change it to your own) and place `google-services.json` in `android/app/`.
3. For iOS, add an iOS app and place `GoogleService-Info.plist` in `ios/Runner/`.
4. Enable these services:
   - **Authentication** (Email/Password, used by the admin sign-in)
   - **Cloud Firestore**
   - **Storage** (Lost and Found images)
   - **Cloud Messaging**
5. Create your first admin:
   1. Add a user in Firebase Authentication.
   2. In Firestore, create `admins/{that user's UID}` with the field `isAdmin: true`.
6. Update `.firebaserc` to point at your own project ID.
7. Deploy rules:

   ```bash
   firebase deploy --only firestore:rules
   ```

---

## Cloud Functions

Located in `functions/`.

| Function | Trigger | What it does |
| --- | --- | --- |
| `onEventCreated` | New document in `events` | Sends a push notification about the new event. |
| `sendDailyEventReminders` | Scheduled, daily at 9:00 AM (Asia/Karachi) | Notifies users about upcoming events. |
| `onLostFoundListingUpdated` | Update in `lost_found_items` | When a listing changes to `active` (approved), broadcasts a notification. |
| `onCollaborationUpdated` | Update in `collaborations` | Broadcasts collaboration updates. |
| `onAdminNotificationCreated` | New document in `admin_notifications` | Saves the announcement to `notifications` and sends it through FCM to all registered devices. |

Deploy:

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

---

## Firestore data model

| Collection | Purpose |
| --- | --- |
| `events` | Campus events shown in the app. |
| `societies` | University societies. |
| `news` | News items for the carousel. |
| `jobs` | Jobs and internships. |
| `lost_found_items` | Listings with `status` (`pending`, `active`, `rejected`, `resolved`), `secretKeyHash`, contact number and images. |
| `collaborations` | Collaboration posts, with an `info` map that includes status and the secret key. |
| `notifications` | Public notification history (written by Cloud Functions only). |
| `admin_notifications` | Announcement requests created by admins. |
| `device_tokens` | FCM tokens registered by devices. |
| `recommendations` | Feedback submitted by students. |
| `admins` | Admin records, keyed by UID. |
| `users`, `timetable_reminders` | Per-user data, readable only by the owner. |

---

## Roadmap

- [ ] Lock down write access on `news`, `jobs` and `events` to admins only
- [ ] Restrict Lost and Found and Collaboration deletes to the owner (secret-key hash) or an admin
- [ ] Validate `device_tokens` writes
- [ ] Move the LGU email check to a server-verified flow (for example, a Google Workspace sign-in restricted to the LGU domain)
- [ ] Society portal, ticketing and payments
- [ ] Timetable reminders
- [ ] Replace the default application ID (`com.example.lgu_one`) before publishing to the Play Store
- [ ] Add screenshots to this README and expand test coverage

---

## Contributing

Contributions, bug reports and ideas are welcome.

1. Fork the repository
2. Create a branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "Add your feature"`
4. Push the branch: `git push origin feature/your-feature`
5. Open a pull request

Please run `flutter analyze` before submitting.

---

## Flutter resources

This project is built with Flutter. If this is your first Flutter project, these resources can help:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

---

## Author

**Hammad Ali Khan**
Student at Lahore Garrison University, Flutter and Firebase developer.

GitHub: [@hammad-78](https://github.com/hammad-78)