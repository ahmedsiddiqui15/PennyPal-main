# PennyPal — Project Handover Guide

This document is the handover guide for the delivered PennyPal application. It describes the project as it is implemented in this repository. It does not replace Firebase Console setup; it tells a client, supervisor, or developer where each piece of configuration lives and what must be supplied before the app can run.

---

## 1. Project Information

| Item | Value |
| --- | --- |
| Project name | PennyPal |
| Tagline | Fresh All Along |
| Project version | `1.0.0+1` (`pubspec.yaml`; in-app version string `1.0.0`) |
| Package name | `pennypal` |
| Android application ID | `com.pennypal.pennypal` |
| iOS bundle ID | `com.pennypal.pennypal` |
| Project type | Cross-platform mobile application (Flutter). Android and iOS are the supported device targets. Web configuration exists in Firebase options, but the product is a mobile finance app. |
| Development status | Feature-complete student personal-finance application ready for handover. Firebase Authentication, Cloud Firestore, and optional Gemini must be configured by the project owner before production use. Release signing currently uses the debug keystore (see Build & Release). |
| Dart SDK | `>=3.3.0 <4.0.0` |

### Technology stack

| Area | Implementation in this project |
| --- | --- |
| UI | Flutter, Material 3, `google_fonts` (Poppins and Inter) |
| State | `flutter_riverpod` |
| Navigation | `go_router` |
| Authentication | Firebase Authentication (email/password and Google Sign-In) |
| Cloud data | Cloud Firestore (offline persistence enabled) |
| Push | Firebase Cloud Messaging (`firebase_messaging`) |
| Local profile database | SQLite via `sqflite` (`pennypal_local.db`) |
| Local preferences | `shared_preferences` |
| Profile images | App-private storage via `path_provider` (not a remote image host) |
| AI assistant | Offline coach by default; optional Google Gemini REST API via `.env` |
| Receipt scan | `google_mlkit_text_recognition` and `google_mlkit_barcode_scanning` on device |
| Voice entry | `speech_to_text` |
| Charts | `fl_chart` |
| Reports | `pdf` and `printing` (generated on device) |
| Camera / gallery | `image_picker`, `camera` |
| Connectivity | `connectivity_plus` |
| Animation | `flutter_animate`, `lottie`, `rive`, `confetti` |

There is no PHP server, Node.js server, or custom REST backend in this repository.

---

## 2. Project Overview

PennyPal is a student personal-finance application. A student records income and expenses, sets budgets and saving goals, tracks subscriptions, reads learning articles, reviews charts and PDF reports, and asks Penny (the in-app assistant) questions about their own numbers.

Financial records are stored in Cloud Firestore under the signed-in user's Firebase Auth ID. The app can keep working offline because Firestore persistence is enabled at startup. Writes queue on the device and sync when the network returns.

### Main purpose

Help a student see where money goes, stay inside a budget, and build saving habits, without acting as a bank.

### Main user features

- Splash, onboarding, login, registration, Google sign-in, forgot password, and email verification
- Dashboard with balance, monthly totals, health score, insights, and a light/dark theme toggle
- Expenses (manual, receipt scan, voice), income, and a combined transaction history
- Budgets, saving goals, and subscription tracking
- Reports with charts and on-device PDF export
- Penny AI assistant (offline coach, optional Gemini)
- Smart insights, badges, and challenges
- Learning articles
- Support queries and feedback
- In-app notifications list, plus optional Firebase Cloud Messaging
- Profile, edit profile (including a locally stored profile photo), settings, and logout

### Admin features

An admin is not created by a separate signup form. A signed-in user becomes an admin when the Firestore document `users/{uid}` has `role` set to `admin`. The admin area then provides:

- Overview (user counts, activity, recent signups)
- User search, profile inspection, and block/unblock
- Learning content create, edit, publish/unpublish, and delete
- Support queue with pending, in-progress, and resolved states, plus replies

---

## 3. Developer / Project Guide Information

These identity fields are not stored in the source code. The project owner must fill them in before formal submission.

| Field | Value |
| --- | --- |
| Developer / team name | `REQUIRED FROM PROJECT OWNER` |
| Project guide / supervisor name | `REQUIRED FROM PROJECT OWNER` |
| Organization / institute | `REQUIRED FROM PROJECT OWNER` |
| Project contact email | `REQUIRED FROM PROJECT OWNER` |
| Additional contact | `REQUIRED FROM PROJECT OWNER` |

Firebase project configured in this repository: `pennypal-c7942`.

---

## 4. Email Credentials & Configuration

This application does **not** send mail through SMTP, an app password, or a custom mail library. There is no OTP email flow.

Account emails are sent by **Firebase Authentication**:

- Registration calls `sendEmailVerification()`.
- The verify-email screen can resend that message and then reloads the user to check `emailVerified`.
- Forgot password calls `sendPasswordResetEmail()`.

Those messages use the templates in the Firebase Console for project `pennypal-c7942` (Authentication → Templates). The sender address is Firebase's default auth sender unless the project owner customizes it in the Firebase Console. No SMTP password is stored in this repository.

| Field | Status in this project |
| --- | --- |
| Email address | `REQUIRED FROM PROJECT OWNER` if a custom Firebase sender or support inbox is needed. The app itself has no mailbox. |
| SMTP host | Not used. `YOUR_SMTP_HOST` |
| SMTP port | Not used. |
| SMTP username | Not used. `YOUR_EMAIL@example.com` |
| SMTP password / app password | Not used. `YOUR_APP_PASSWORD` — do not put a real password in this file or in Git. |
| Sender email | Firebase Authentication sender. Customize in Firebase Console. `REQUIRED FROM PROJECT OWNER` if a branded sender is required. |
| Sender name | Firebase Authentication template. Default product name in the app is PennyPal. |
| Encryption type | Not applicable. Firebase delivers the mail. There is no TLS/SSL SMTP setting in the app. |
| Email verification | Enabled in code. Firebase Console must have the Email/Password provider turned on. Unverified email/password users are kept on `/verify-email` until they open the link. |
| Password reset email | Enabled in code via Forgot Password. Firebase sends the reset link. |
| OTP email | Not implemented. |

Support messages inside the app are stored in Firestore (`supportQueries`). They are not emailed.

---

## 5. Environment Configuration

The environment file is the project-root file `.env`, next to `pubspec.yaml`. It is listed as a Flutter asset so `flutter_dotenv` can load it at startup (`lib/app/bootstrap.dart`).

`.env` is listed in `.gitignore`. A template is committed as `.env.example`.

Copy the template, then replace the placeholders:

```bash
copy .env.example .env
```

On macOS or Linux:

```bash
cp .env.example .env
```

### Variables the application actually reads

| Variable | Required | Purpose |
| --- | --- | --- |
| `GEMINI_API_KEY` | Optional | Google Gemini API key for Penny AI. If missing, empty, or still `YOUR_API_KEY_HERE`, the assistant uses the offline coach. |
| `GEMINI_MODEL` | Optional | Gemini model id. If missing or still `YOUR_MODEL_HERE`, the app uses `gemini-flash-latest`. |

Example (placeholders only):

```env
GEMINI_API_KEY=YOUR_API_KEY_HERE
GEMINI_MODEL=YOUR_MODEL_HERE
```

## Email and password

Login and registration use **Firebase Authentication**. The app does not store these passwords in code. Create both accounts once in the app (or in the Firebase Console), then use them to review the project.

| Role | Email | Password | Where it opens |
| --- | --- | --- | --- |
| Student (user) | `ahmedsdi224413@gmail.com` | `ahmedsiddiqui15` | Student home |
| Admin | `mya25934@gmail.com` | `Admin@123` | Admin panel |
Obtain a key from [Google AI Studio](https://aistudio.google.com/apikey). Never commit the filled `.env`.

`CloudinaryConfig` can also read compile-time values `CLOUDINARY_CLOUD_NAME` and `CLOUDINARY_UPLOAD_PRESET` (`--dart-define`). The current profile-photo flow does **not** call Cloudinary. Profile images are stored on the device (section 9). Leave Cloudinary unset unless a future change explicitly uses it.

Firebase client configuration is not in `.env`. It is in `lib/firebase_options.dart` and `android/app/google-services.json`.

---

## 6. Database Configuration

The app uses two stores.

### Cloud Firestore (financial and account data)

| Setting | Value |
| --- | --- |
| Technology | Cloud Firestore |
| Project | `pennypal-c7942` |
| Location | Google Cloud (Firebase Console). Not a file inside this repository. |
| Offline cache | Enabled in `FirestoreService.enableOfflinePersistence()` with unlimited cache size on mobile. |
| Access | `FirebaseRepository` through `AppRepository`. Screens do not call Firestore directly. |

Collections defined in `AppConstants`:

| Collection | Role |
| --- | --- |
| `users` | Profile: name, email, phone, role, currency, income goal, theme, blocked flag, streak |
| `transactions` | Unified ledger rows |
| `income` | Income entries |
| `expenses` | Expense entries |
| `budgets` | Budget limits |
| `savingGoals` | Saving goals |
| `subscriptions` | Recurring subscriptions |
| `notifications` | In-app notification documents |
| `learningContent` | Shared articles (admin-managed) |
| `supportQueries` | Feedback and support tickets |
| `badges` | Per-user badge records |
| `challenges` | Challenges |
| `reports` | Saved report metadata |

User-owned documents are keyed by the Firebase Auth user id. `learningContent` and starter `challenges` are shared. The first read can write starter learning articles and challenges with fixed document ids so they are not duplicated.

Initialization: create the Firestore database in the Firebase Console and publish security rules before real users write data. Recommended rules are documented in `README.md` under Firebase console setup. This repository does not contain a `firestore.rules` file.

### SQLite (profile image path only)

| Setting | Value |
| --- | --- |
| Technology | `sqflite` |
| File | `pennypal_local.db` |
| Location | The platform SQLite databases directory (`getDatabasesPath()`), private to the app |
| Schema version | `1` |
| Created by | `lib/core/database/app_database.dart` on first open |
| Migration | `onUpgrade` runs `CREATE TABLE IF NOT EXISTS`. It does not delete existing rows. |

Table `user_profile`:

| Column | Notes |
| --- | --- |
| `id` | Integer primary key |
| `user_id` | Firebase Auth uid, unique |
| `profile_image_path` | Absolute path of the local image file, or null |
| `updated_at` | UTC ISO-8601 timestamp |

SQLite does not store the image bytes and does not store income, expenses, or passwords.

### Shared preferences

`shared_preferences` stores theme mode, currency code, onboarding-seen flag, last user id, notification toggle, reminder hour, and AI chat history. Legacy Gemini keys that used to live in preferences are deleted on startup. Do not put API keys back into preferences.

---

## 7. API Configuration

| Service | Used for | Where to configure | Secret in Git? |
| --- | --- | --- | --- |
| Firebase Authentication | Login, register, Google sign-in, verification email, password reset, session | Firebase Console → Authentication. Enable **Email/Password** and **Google**. Client files: `lib/firebase_options.dart`, `android/app/google-services.json`. | Client config is already in the project. Do not add extra private keys to Markdown. |
| Cloud Firestore | All finance and account documents | Firebase Console → Firestore. Create the database and publish rules. | No extra key in `.env`. |
| Firebase Cloud Messaging | Push permission and device token | Firebase Console → Cloud Messaging. Initialized in `NotificationService` after Firebase starts. | No extra key in `.env`. |
| Google Sign-In | Continue with Google on login and register | Same Firebase project. Android requires the app SHA-1 and SHA-256 under Project settings → Your apps. | No password in the repo. |
| Google Gemini | Optional Penny AI answers | Root `.env`: `GEMINI_API_KEY`, `GEMINI_MODEL`. Endpoint: `https://generativelanguage.googleapis.com/v1beta`. | `.env` must stay untracked. Use `YOUR_API_KEY_HERE` in examples. |
| Google ML Kit | On-device receipt text and barcode scan | No API key. Models run on the device. | None. |
| Cloudinary | Present in `CloudinaryService` only | Optional `--dart-define=CLOUDINARY_CLOUD_NAME` and `CLOUDINARY_UPLOAD_PRESET`. **Not used by the current profile photo flow.** | Do not commit real values. |

No other third-party API keys are read by the application.

---

## 8. Authentication

Implemented in `lib/services/auth_service.dart` (`FirebaseAuthService`) and `lib/providers/auth_providers.dart`. Routes and guards are in `lib/core/routes/app_router.dart`.

| Flow | Behavior |
| --- | --- |
| Registration | Email, name, phone, and password. Password rules: at least 8 characters, no spaces, at least one letter and one number. Creates a Firebase user and a `users/{uid}` document with role `student`. Sends a verification email. Registration does not upload a profile photo. |
| Login | Email and password through Firebase Auth. |
| Google | `GoogleSignIn` on both Login and Register. A cancelled Google sheet is treated as a failure message. New Google users get a Firestore profile through the same load-or-create path. |
| Email verification | Email/password users who are not verified are redirected to `/verify-email`. They open the Firebase link, return, and tap **I've verified my email**. Resend is available. |
| Password reset | Forgot Password screen calls `sendPasswordResetEmail`. There is no in-app OTP. |
| Session | Firebase Auth persists the session. `authStateChanges` drives routing. A signed-in user skips onboarding and the auth screens. |
| Logout | Signs out of Google Sign-In (if used) and Firebase Auth. Local profile image files are not deleted on logout, so the same user sees the photo after signing back in on that device. |
| Roles | `student` uses the student shell. `admin` uses the admin shell. Set `role` to `admin` in Firestore for the first administrator. |
| Blocked users | The `blocked` field exists on the user document and is managed from the admin users screen. |

---

## 9. File & Image Storage

### Profile images (current behavior)

Flow: image picker → `ProfileImageService` → app-private folder → SQLite path → Profile and dashboard avatar.

1. Edit Profile → Change photo → gallery or camera (`image_picker`).
2. The service checks the extension (`.jpg`, `.jpeg`, `.png`, `.webp`, `.heic`, `.heif`), rejects empty files, and rejects files over 5 MB. The picker also requests quality 85 and a maximum edge of 1024.
3. The file is copied into the application documents directory under `profile_images/`.
4. The filename is `user_<userId>_<uuid>.jpg` (or the normalized extension). User ids are sanitized. One user's file cannot reuse another user's name.
5. Only the absolute path is saved in SQLite `user_profile.profile_image_path`.
6. Replacing the photo writes a new file, updates the path, then deletes the previous file.
7. Remove photo clears the SQLite path and deletes the file.
8. If the file is missing, the avatar shows initials. A remote `photoUrl` on the user document (for example from Google) is used only when no local file path is stored.

Profile photos are not uploaded to Firebase Storage, Cloudinary, or any other server.

### Other images

| Asset | Storage |
| --- | --- |
| App logo, onboarding art, Google button icon | Bundled in `assets/images/` |
| Receipt photo | Selected for on-device OCR preview. It is not copied into `profile_images/` and is not uploaded. |
| Lottie / Rive | Bundled in `assets/lottie/` |
| PDF reports | Generated in memory and shared through the printing plugin. They are not stored in SQLite. |

---

## 10. Project Structure

```
PennyPal_Flutter_Project/
├── PROJECT_GUIDE.md          # this handover guide
├── README.md                 # feature and Firebase notes (older image section; see section 9 of this guide)
├── pubspec.yaml              # package name, version, dependencies, assets
├── .env.example              # Gemini placeholders only
├── .env                      # local secrets (gitignored; create from the example)
├── .gitignore
├── firebase.json             # FlutterFire project mapping
├── lib/
│   ├── main.dart             # starts bootstrap or the configuration error screen
│   ├── firebase_options.dart # Firebase client options (do not publish extra copies of keys)
│   ├── app/                  # PennyPalApp, bootstrap, startup error UI
│   ├── core/
│   │   ├── config/           # app identity, Gemini, unused Cloudinary defines
│   │   ├── constants/        # Firestore collection names, spacing, asset paths
│   │   ├── database/         # SQLite open, migration, user_profile DAO
│   │   ├── routes/           # GoRouter and auth redirects
│   │   ├── theme/            # light, dark, colors, text styles
│   │   ├── utils/            # validators, money formatting, currency conversion
│   │   └── widgets/          # shared buttons, avatar, fields, dialogs
│   ├── features/
│   │   ├── auth/             # splash, onboarding, login, register, forgot password, verify email
│   │   ├── student/          # dashboard, money tools, AI, learning, profile
│   │   └── admin/            # overview, users, content, support
│   ├── models/               # plain data models
│   ├── providers/            # Riverpod controllers
│   └── services/             # Auth, Firestore repository, Gemini, OCR, profile images, PDF
├── assets/images/            # logo, onboarding, google_icon.png
├── assets/lottie/
├── android/                  # applicationId com.pennypal.pennypal, google-services.json
├── ios/                      # bundle id com.pennypal.pennypal
└── test/                     # unit and widget tests
```

Profile image types live under `lib/features/student/profile/data/`. The image service lives in `lib/services/profile_image_service.dart` so it can be shared with the dashboard avatar.

---

## 11. Installation Guide

1. Install Flutter (stable channel) with a Dart SDK that satisfies `>=3.3.0 <4.0.0`, plus Android Studio and/or Xcode.
2. Clone or copy this project.
3. From the project root, install packages:

   ```bash
   flutter pub get
   ```

4. Create the local environment file:

   ```bash
   copy .env.example .env
   ```

   Put a real Gemini key in `.env` only if Penny should call Gemini. The app still runs if the placeholders are left in place.

5. In the Firebase Console for `pennypal-c7942`:
   - Enable Email/Password and Google authentication.
   - Create the Cloud Firestore database.
   - Publish Firestore security rules (see `README.md`).
   - For Android Google sign-in, register the debug (and later release) SHA-1 and SHA-256.

   Print the debug fingerprints:

   ```bash
   cd android
   .\gradlew signingReport
   ```

6. Confirm `android/app/google-services.json` matches that Firebase Android app. Do not replace it with a file from a different project unless the whole Firebase app is being moved.
7. Connect a device or start an emulator, then run section 12.
8. Create the first admin after a normal signup by setting `role` to `admin` on that user's Firestore document.

---

## 12. Run Guide

From the project root:

```bash
flutter pub get
flutter run
```

Choose a device when more than one is connected:

```bash
flutter devices
flutter run -d <device-id>
```

Useful checks:

```bash
flutter analyze
flutter test
```

If Firebase fails to initialize, the app shows the bootstrap error screen instead of fake data. Fix the Firebase project setup and run again.

---

## 13. Build & Release Guide

Version name and build number come from `pubspec.yaml` (`1.0.0+1`).

Android App Bundle:

```bash
flutter build appbundle
```

Android APK:

```bash
flutter build apk --release
```

iOS (on macOS, with signing configured in Xcode):

```bash
flutter build ipa
```

Current Android release build type in `android/app/build.gradle.kts` signs with the **debug** keystore so a release build can be produced without a private upload key. Before a Play Store submission, replace that with a release keystore that is **not** committed to Git, and register that keystore's SHA-1 with Firebase or Google sign-in will fail in production.

R8 minify and resource shrinking are currently disabled.

---

## 14. Security Rules

Never commit:

- `.env` after real values are added
- Gemini API keys, Firebase Admin SDK private keys, or service-account JSON
- SMTP passwords, app passwords, or OAuth client secrets written into Markdown
- Android release keystores (`.jks`, `.keystore`) and their passwords
- Personal user exports, receipt photos, or copied `profile_images` folders

Firebase **client** files (`google-services.json`, `firebase_options.dart`) identify the app. They are not a license to open the database. Access must be limited by Firestore security rules in the Firebase Console.

Passwords are handled by Firebase Authentication. They are not stored in SQLite or SharedPreferences.

Profile images stay in application-private storage. They are not written to the public gallery.

---

## 15. GitHub Guidelines

| Item | Rule |
| --- | --- |
| `.gitignore` | Already ignores `.env`, build outputs, `.dart_tool/`, and Android debug/profile/release intermediates. |
| `.env` | Local only. Never push it. |
| `.env.example` | Safe to commit. It contains `YOUR_API_KEY_HERE` and `YOUR_MODEL_HERE` only. |
| Branches | Use a feature branch for changes. Do not force-push `main`. |
| Commits | One purpose per commit. Do not commit generated `build/` output. |
| Repository | This project can be hosted on GitHub or another Git host. Firebase and Gemini stay in their own consoles; the repo only holds client configuration and the `.env` template. |

Before the first push of a new remote, confirm `git status` does not list `.env`.

---

## 16. Troubleshooting

| Problem | What to check |
| --- | --- |
| App opens a configuration error screen | Firebase did not start. Confirm `google-services.json`, `firebase_options.dart`, and `flutter pub get`. Read the message on that screen. |
| Login says no account or wrong password | Email/Password provider must be enabled. The user must register first. |
| Verification email never arrives | Firebase Console → Authentication → Templates, and the user's spam folder. Use Resend on the verify screen. This app has no SMTP settings to change. |
| Google sign-in fails on Android | Add the signing SHA-1 from `gradlew signingReport` to the Firebase Android app, then download a fresh `google-services.json` if Firebase asks for it. |
| Firestore permission denied | Publish security rules. Confirm the user is signed in and documents include the correct `userId`. |
| Profile photo missing after reinstall | Images live in app-private storage. Uninstalling the app deletes them. They are not in the cloud. |
| Profile photo shows initials | The SQLite path is empty or the file was deleted. Pick the photo again. The UI is designed not to crash. |
| Penny does not use Gemini | `.env` must sit in the project root, be listed in `pubspec.yaml` assets (it is), and contain a real `GEMINI_API_KEY`. Restart the app after editing `.env`. Placeholders keep the offline coach. |
| `LaunchTheme` or Android resource errors | Do not remove `android/app/src/main/res/values/styles.xml` or the launch background. |
| Packages fail to resolve | Run `flutter pub get` with a network connection. Do not edit `pubspec.lock` by hand. |

---

## 17. Final Delivery Checklist

- [ ] Project runs with `flutter pub get` and `flutter run`
- [ ] Required packages installed (`flutter pub get` completed without errors)
- [ ] `.env` created from `.env.example`
- [ ] Gemini key added only if AI cloud answers are required; otherwise offline coach is accepted
- [ ] Email/Password and Google providers enabled in Firebase Authentication
- [ ] Firebase email verification and password-reset templates reviewed (no custom SMTP in this app)
- [ ] Cloud Firestore database created and security rules published
- [ ] Android SHA-1 / SHA-256 registered for Google sign-in
- [ ] First admin `role` set in Firestore if an admin demo is required
- [ ] No real API keys, SMTP passwords, or keystore passwords committed
- [ ] `.env` is not in the Git commit
- [ ] Debug accounts and personal finance entries removed from the Firebase project if this build is for someone else
- [ ] No stray receipt photos or private profile images added to the repository
- [ ] Release build produced and installed once (`flutter build apk --release` or `flutter build appbundle`)
- [ ] This guide and `.env.example` are included in the delivery

---

*PennyPal 1.0.0 — handover guide. Configuration above matches the source in this repository. Fields marked REQUIRED FROM PROJECT OWNER are not present in the code and must be supplied by the owner.*
