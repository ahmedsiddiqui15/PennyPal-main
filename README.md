# PennyPal

**Fresh All Along** — a student personal-finance app built with Flutter, Riverpod and Firebase.

PennyPal helps students track income and expenses, build smart budgets, grow savings goals, learn financial
skills and stay motivated through badges and challenges — wrapped in a premium amber-on-neutral fintech UI
with full light/dark theming.

> **SRS compliance:** see [`REQUIREMENTS_STATUS.md`](REQUIREMENTS_STATUS.md) for a requirement-by-requirement
> status report (green = completed, red = not completed) against the PennyPal Software Requirements
> Specification v1.0.

---

## Quick start

```bash
flutter pub get
flutter run
```

Firebase is already wired into this project (`lib/firebase_options.dart`,
`android/app/google-services.json`, and the Google Services Gradle plugin). See
[Firebase console setup](#firebase-console-setup) for the console-side steps that must exist before the app
can read and write data.

```bash
flutter analyze   # static analysis — clean
flutter test      # 45 unit + widget tests
```

---

## Backend — Firebase + Cloudinary

PennyPal has **no separate local database and no seeded runtime data**. Every user, transaction, income
entry, budget, saving goal, subscription, notification, badge, challenge, report and learning article lives
in Cloud Firestore; images (profile photos) live in **Cloudinary** (see [below](#cloudinary-image-uploads)).

**Offline is first-class.** Firestore's persistent on-device cache is enabled at start-up
(`FirestoreService.enableOfflinePersistence`), so entries made without a connection are stored locally and
**queued**, then synced automatically by the SDK when the connection returns. A banner (`connectivity_plus`)
shows the offline state. Beyond that cache, the only thing kept on-device is UI preference (theme mode,
currency, onboarding flag, AI chat history, optional Gemini API key) via `shared_preferences` — never
financial data.

If Firebase cannot initialise, the app shows a clear configuration error screen instead of silently
falling back to fake data.

### Firestore collections

`users` · `transactions` · `income` · `expenses` · `budgets` · `savingGoals` · `subscriptions` ·
`notifications` · `learningContent` · `supportQueries` · `badges` · `challenges` · `reports`

Every document carries `userId` (equal to the Firebase Auth uid) except the shared `learningContent`
collection, which is admin-managed. Queries filter on that single field and sort client-side, so **no
composite indexes are required**.

### One-time initial content

Two collections are populated once, on first read, so a brand-new project is not blank: the six starter
articles in `learningContent` and the starter challenge set in `challenges`. Both are written into Firestore
with deterministic ids (so concurrent first-reads cannot duplicate) and become ordinary documents
afterwards — admins can edit, unpublish or delete the articles from the **Content** screen.

---

## Features

### Authentication
Email/password registration and login, Google sign-in **and Google sign-up**, forgot-password reset (with
resend), **enforced email verification**, session persistence, logout, and role-based access (`student` /
`admin`). Sign-up and login carry full field validation plus a password policy (min 8 characters, a letter
and a number) with a live strength meter. Unverified accounts are held on a verify-email screen until they
confirm. The router enforces the auth, email-verification and role guards centrally, so no screen guards
itself.

Registration also offers an **optional profile photo** (camera or gallery) right on the sign-up form. It is
uploaded to **Cloudinary** and attached to the profile; a failed upload never blocks the account. The photo
can also be changed any time from Profile → Edit Profile (or by tapping the avatar on the Profile screen).

### Student panel
* **Dashboard** — greeting, animated balance card with privacy toggle, monthly income/expense metrics with
  trend pills, budget progress ring, financial health score, next-month prediction strip, smart insights and
  recent activity. A nine-tile quick-action grid links straight to Add Expense, Add Income, Scan Receipt,
  Budget, History, Learning, Feedback, Contact Support and the AI assistant.
* **Expenses** — today's and weekly spend, month-over-month comparison, category breakdown with per-category
  budget bars, search, category filters, four sort orders and full CRUD.
* **Add expense (3 ways)** — manual entry, **receipt scanning** (ML Kit OCR extracts amount + category +
  date) and **voice entry** ("I spent 500 on lunch"). All three converge on the same validated form and end
  with a Lottie + confetti success celebration.
* **Income** — income history with per-source breakdown, inline edit and delete.
* **Transactions** — unified ledger with search, type/date/category filters, sorting and per-day grouped
  totals.
* **Budget** — master monthly budget, per-category limits, overspending alerts and next-month prediction.
* **Savings** — goals with a monthly contribution and an estimated completion date (with a live preview in
  the form), animated progress, milestone chips, quick top-up, a completion celebration, and a dedicated
  **Goal History** section where completed goals are archived.
* **Reports** — KPI cards, 12-month income-vs-expense line chart, monthly savings bars, category doughnut,
  prediction card and **PDF export** (plus CSV generation) via the `pdf`/`printing` packages.
* **Penny AI assistant** — chat with animated bubbles and a typing indicator. Runs on a deterministic,
  offline coach by default (answers computed from the user's real snapshot — overspending, savings plans,
  budgets, forecasts) and can be upgraded to **Google Gemini**: add an API key in Settings → AI Assistant
  and Penny answers with an LLM grounded in the same numbers. Any failure silently falls back to the
  offline coach, so the chat never breaks.
* **Smart insights** — category spikes, savings-rate feedback, budget status, daily-average deviations and
  predictions, plus a transparent health-score breakdown.
* **Gamification** — level/points header, badge grid with locked/unlocked states and 30-day style
  challenges with progress logging.
* **Subscriptions** — Netflix/Spotify/ChatGPT Plus style tracker with monthly + annualised cost, next-billing
  countdown, quick-add presets and pause toggles.
* **Learning** — categorised financial-education library with article reader.
* **Support** — star-rating feedback and support queries with status history and admin replies (the
  dashboard deep-links into the Feedback and Contact Support tabs).
* **About** — a dedicated screen explaining PennyPal's purpose, features and the "guidance only, not a
  bank" disclaimer.
* **Notifications** — budget alerts, saving reminders, tips and achievement notifications with read state.
* **Profile** — avatar, edit profile (name, phone, photo, income goal, currency), settings and logout.

### Admin panel
Separate role-gated area with its own bottom navigation:
* **Overview** — total/active users, monthly expense volume, total savings, 6-month user-growth bar chart,
  platform activity table and recent signups.
* **Users** — search, inspect profiles, block/unblock accounts.
* **Content** — create, edit, publish/unpublish and delete learning articles.
* **Support** — triage queue with pending / in-progress / resolved states, resolution-rate meter and replies.

### Design system
Amber primary (`#F59E0B`) on `#FAFAF9`, dark mode on `#111827` with `#1F2937` cards, rounded cards, soft
shadows, generous spacing, Google Fonts (Poppins + Inter) and **System / Light / Dark** switching from
Profile → Settings. Animations use `flutter_animate`, `lottie` and `confetti`, plus a
`rive`-ready splash hook.

---

## Architecture

Feature-first clean architecture with a single data-access contract.

```
lib/
├── main.dart                     # entry point
├── app/
│   ├── app.dart                  # MaterialApp.router (themes, router, text scale clamp)
│   ├── bootstrap.dart            # async wiring: Firebase init, prefs, services, container
│   └── bootstrap_error_app.dart  # shown when Firebase cannot start
├── core/
│   ├── config/                   # app identity, version, currency options
│   ├── constants/                # collection names, spacing/radii, category & role enums
│   ├── theme/                    # palette, typography, light/dark theme factory
│   ├── routes/                   # route table + GoRouter with auth/role redirects
│   ├── widgets/                  # reusable UI kit (cards, buttons, rings, tiles, states)
│   └── utils/                    # formatters, validators, finance maths, JSON helpers
├── models/                       # immutable models + fromMap/toMap/copyWith
├── providers/                    # Riverpod: services, settings, auth, finance, content, admin
├── services/                     # auth, firestore repository, cloudinary, notifications,
│                                 # AI, OCR, voice, PDF, initial content
└── features/
    ├── auth/                     # splash, onboarding, login, register, forgot password
    ├── student/                  # dashboard, expenses, income, budget, savings, reports, AI,
    │                             # insights, gamification, subscriptions, learning, support,
    │                             # notifications, profile, shell
    └── admin/                    # shell, dashboard, users, content, support
```

### Key architectural decisions

**One repository contract, one backend.** `AppRepository` (in `services/repository.dart`) is the only
data-access interface; `FirebaseRepository` implements it against Cloud Firestore. `bootstrap.dart`
initialises Firebase, builds that implementation and injects it through Riverpod, so no screen ever touches
the SDK directly.

**Aggregates are derived, never stored.** `FinancialSnapshot` folds the raw ledger into every number the UI
needs (monthly totals, per-category spend, 12-month series, savings rate, health score, forecast). Dashboard,
insights, reports and the AI all read the same object, so they can never disagree.

**State.** Riverpod throughout: `AsyncValue` for load/error/empty states, a single `FinanceController` that
reloads affected collections after each mutation, and `GoRouter` redirects driven by `authProvider`.

**Models are SDK-free.** Models never import `cloud_firestore`; `core/utils/json_utils.dart` duck-types
timestamps, which keeps them unit-testable and web-safe.

---

## Firebase console setup

The client config is already committed. These console-side steps must be completed once for project
`pennypal-c7942` before the app can read or write data:

1. **Authentication** → enable the **Email/Password** and **Google** sign-in providers.

2. **Firestore Database** → create the database, then publish the [security rules](#security-rules) below.

3. **Images** → profile photos are stored on **Cloudinary**, not Firebase, so no Storage bucket is
   required — complete the separate [Cloudinary setup](#cloudinary-image-uploads) instead.

4. **Android Google Sign-In** → add your signing certificate's **SHA-1** (and SHA-256) under
   *Project settings → Your apps*. Run `cd android && ./gradlew signingReport` to print the debug
   fingerprint. Google sign-in fails with a `PlatformException` until this is registered.

5. **Create an admin** → sign up in the app, then set `role: "admin"` on that user's document in the `users`
   collection. The next sign-in opens the admin panel.

6. *(Optional)* **Cloud Messaging** → enables push for budget alerts, saving reminders and tips.

### Security rules

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function signedIn() { return request.auth != null; }
    function uid()      { return request.auth.uid; }
    function isAdmin() {
      return signedIn() &&
        get(/databases/$(database)/documents/users/$(uid())).data.role == 'admin';
    }

    // Owner of the stored document.
    function ownsExisting() { return signedIn() && resource.data.userId == uid(); }
    // Owner of the document being written.
    function ownsIncoming() {
      return signedIn() && request.resource.data.userId == uid();
    }

    match /users/{userId} {
      allow get, list: if signedIn() && (uid() == userId || isAdmin());
      allow create:    if signedIn() && uid() == userId;
      allow update:    if signedIn() && (uid() == userId || isAdmin());
      allow delete:    if isAdmin();
    }

    // Per-user financial data: owner writes it, admin can read and moderate.
    match /expenses/{doc}      { allow read: if ownsExisting() || isAdmin();
                                 allow create: if ownsIncoming();
                                 allow update, delete: if ownsExisting() || isAdmin(); }
    match /income/{doc}        { allow read: if ownsExisting() || isAdmin();
                                 allow create: if ownsIncoming();
                                 allow update, delete: if ownsExisting() || isAdmin(); }
    match /transactions/{doc}  { allow read: if ownsExisting() || isAdmin();
                                 allow create: if ownsIncoming();
                                 allow update, delete: if ownsExisting() || isAdmin(); }
    match /budgets/{doc}       { allow read: if ownsExisting() || isAdmin();
                                 allow create: if ownsIncoming();
                                 allow update, delete: if ownsExisting() || isAdmin(); }
    match /savingGoals/{doc}   { allow read: if ownsExisting() || isAdmin();
                                 allow create: if ownsIncoming();
                                 allow update, delete: if ownsExisting() || isAdmin(); }
    match /subscriptions/{doc} { allow read: if ownsExisting() || isAdmin();
                                 allow create: if ownsIncoming();
                                 allow update, delete: if ownsExisting() || isAdmin(); }
    match /notifications/{doc} { allow read: if ownsExisting() || isAdmin();
                                 allow create: if ownsIncoming();
                                 allow update, delete: if ownsExisting() || isAdmin(); }
    match /badges/{doc}        { allow read: if ownsExisting() || isAdmin();
                                 allow create: if ownsIncoming();
                                 allow update, delete: if ownsExisting() || isAdmin(); }
    match /challenges/{doc}    { allow read: if ownsExisting() || isAdmin();
                                 allow create: if ownsIncoming();
                                 allow update, delete: if ownsExisting() || isAdmin(); }
    match /reports/{doc}       { allow read: if ownsExisting() || isAdmin();
                                 allow create: if ownsIncoming();
                                 allow update, delete: if ownsExisting() || isAdmin(); }

    // Shared learning content: everyone reads, only admins write.
    match /learningContent/{doc} {
      allow read:  if signedIn();
      allow write: if isAdmin();
    }

    // Support: students create their own, admins triage everything.
    match /supportQueries/{doc} {
      allow read:   if ownsExisting() || isAdmin();
      allow create: if ownsIncoming();
      allow update: if ownsExisting() || isAdmin();
      allow delete: if isAdmin();
    }
  }
}
```

---

> **Images** are not stored in Firebase — profile photos go to **Cloudinary** (see
> [Cloudinary setup](#cloudinary-image-uploads)), so there are no Storage rules to publish.

## Gemini (optional)

Penny AI runs on a deterministic, offline coach by default. To upgrade it to **Google Gemini**,
supply an API key in one of two ways:

* **In the app (recommended):** Profile → Settings → **AI Assistant**, then paste a key from
  [Google AI Studio](https://aistudio.google.com/apikey). It is stored on-device with
  `shared_preferences`, so no rebuild is needed; clearing it returns to the offline coach.
* **At build time:** `flutter run --dart-define=GEMINI_API_KEY=<key>`. Override the model with
  `--dart-define=GEMINI_MODEL=gemini-3.8-flash` (the default is the `gemini-flash-latest` alias,
  which tracks the current model).

Penny sends each question with the user's live snapshot (income, expenses, budget, top categories,
forecast) as context. If the key is missing, rejected, rate-limited, or the device is offline, it
silently falls back to the offline coach — the chat never fails. Requests go straight to the Gemini
REST API (`generateContent`) over `http`. **Never commit a key**, because a `--dart-define` value is
embedded in the build. When Gemini is enabled, the user's question and a summary of their numbers
are sent to Google.

## Cloudinary (image uploads)

Profile photos are stored on **Cloudinary**, uploaded straight from the app with an **unsigned** upload
preset — no backend, and no Firebase Storage bucket or CORS setup required (Cloudinary's upload endpoint is
CORS-enabled, so web works too).

1. Create a free account at [cloudinary.com](https://cloudinary.com) and note your **cloud name**
   (dashboard, top-left).
2. Settings → **Upload** → *Add upload preset* → set **Signing mode: Unsigned**, optionally restrict the
   allowed formats and max file size, save, and note the **preset name**.
3. Pass both to the app at build time:

   ```bash
   flutter run -d chrome \
     --dart-define=CLOUDINARY_CLOUD_NAME=your-cloud \
     --dart-define=CLOUDINARY_UPLOAD_PRESET=your-unsigned-preset
   ```

Uploads land in the `pennypal/avatars` folder and the returned `secure_url` is saved to the profile
(`users/{uid}.photoUrl`), so the avatar renders anywhere that URL is used. If the two values are missing, the
app keeps the picked photo as a local preview and tells the user instead of failing silently.

> The preset is *unsigned*, so anyone who knows its name can upload to it. Keep it restricted (formats, max
> size) — that is the normal trade-off for client-side uploads without a server.

## Tech stack

| Area             | Choice                                                        |
| ---------------- | ------------------------------------------------------------- |
| Framework        | Flutter 3.x, Dart 3.x, Material 3                             |
| State            | `flutter_riverpod`                                            |
| Navigation       | `go_router` (stateful shells + auth/role redirects)           |
| Backend          | Firebase Auth, Cloud Firestore, Cloud Messaging              |
| Auth             | Email/password, Google Sign-In, password reset, roles         |
| Charts           | `fl_chart`                                                    |
| Animation        | `flutter_animate`, `lottie`, `rive`, `confetti`               |
| Device           | `image_picker`, `camera`, `google_mlkit_text_recognition`, `speech_to_text`, `connectivity_plus` |
| Reporting        | `pdf`, `printing`                                             |
| Image storage    | Cloudinary (unsigned uploads via REST over `http`)            |
| AI assistant     | Deterministic offline coach + optional Google Gemini (REST via `http`) |
| Offline          | Firestore persistent cache (queued writes, auto-sync on reconnect) |
| Local storage    | `shared_preferences` (UI preference only, never financial data) |
| Typography       | `google_fonts` (Poppins + Inter)                              |

---

## Testing

`flutter test` runs 45 tests:

* **Firestore mapping** — every model is written to and read back from a plain `Map<String, dynamic>`,
  exactly as `cloud_firestore` does. Covers users, expenses, income, ledger rows, budgets, goals,
  subscriptions, challenges, articles, notifications and badges, plus the shared value coercions
  (`asDateTime`, `asDouble`, `asBool`, …).
* **Unit** — formatters, validators, health-score/prediction maths, snapshot aggregation, receipt OCR
  parsing (amount/category extraction) and voice-expense parsing.
* **UI smoke** — renders the splash screen against the real theme.

The mapping suite is what makes the Firestore layer verifiable without a live project — no mocks of the SDK
are needed, because the models own their own serialisation.

---

## Platform notes

* **Web** — builds and runs (`flutter build web`). Receipt scanning (ML Kit) is Android/iOS only; the UI
  detects this and steers the user to manual entry. This is handled with a conditional import so the web
  build never pulls in `dart:io` or ML Kit. Image uploads go to **Cloudinary** (CORS-enabled), so no
  storage-bucket CORS configuration is needed.
* **Android** — camera, microphone, media and notification permissions are declared in the manifest.
* **iOS** — camera, microphone, photo-library and speech-recognition usage descriptions are declared in
  `Info.plist`.
* **Voice input** requires a device speech recogniser; when unavailable the app falls back to manual entry
  instead of erroring.

## Release builds

```bash
flutter build apk --release      # Android
flutter build ios --release      # iOS (macOS + Xcode required)
flutter build web --release      # Web
```
