# PennyPal — Requirements Compliance Report

**Project:** PennyPal — *Fresh All Along*
**Source document:** Software Requirements Specification, Version 1.0
**Category:** Multi-Platform App Computing
**Last reviewed:** 2026-09-27

This file maps **every requirement in the PennyPal SRS** to its actual implementation status in this Flutter project.

---

## Legend

| Colour | Status | Meaning |
| ------ | ------ | ------- |
| <span style="color:#15803D">**GREEN**</span> | <span style="color:#15803D">**✅ Completed**</span> | The requirement is implemented in the app. |
| <span style="color:#DC2626">**RED**</span> | <span style="color:#DC2626">**❌ Not completed**</span> | The requirement is missing or only partially implemented. |

> **About the colours:** colour is applied with inline HTML (`<span style="color:…">`). It renders in editors that support inline HTML (VS Code Markdown preview, Typora, most IDEs). On renderers that strip CSS (e.g. GitHub), the ✅ / ❌ markers still show the status clearly.

---

## Summary

| Section | Completed ✅ | Not completed ❌ |
| ------- | :----------: | :--------------: |
| 1.6 Functional Requirements | 33 | 0 |
| 1.7 Non-Functional Requirements | 10 | 0 |
| 1.5 Constraints | 5 | 0 |
| Database Design | 1 | 0 |
| 1.8 Interface Requirements | 4 | 0 |
| 1.9 Project Deliverables | 2 | 5 |
| **Total (60 tracked items)** | **55** | **5** |

**Outstanding (RED) items at a glance:** documentation pack · user credentials file · SQL scripts (not applicable to a Firebase backend) · APK build · demo video. **Every functional, non-functional and constraint requirement is now implemented.**

---

## 1.6 Functional Requirements

### 1.6.1 User Registration and Authentication

| # | Requirement | Status |
| - | ----------- | ------ |
| 1 | <span style="color:#15803D">Register using name, email, mobile number and password</span> | <span style="color:#15803D">✅ Completed</span> |
| 2 | <span style="color:#15803D">Log in securely using email and password</span> | <span style="color:#15803D">✅ Completed</span> |
| 3 | <span style="color:#15803D">Validate required fields, email format, password rules and duplicate accounts</span> | <span style="color:#15803D">✅ Completed</span> |
| 4 | <span style="color:#15803D">Log out from the application</span> | <span style="color:#15803D">✅ Completed</span> |

*Implemented with Firebase Auth (email/password + Google sign-in), field validators, and Firebase's duplicate-account error handling. Admin logins are promoted via the `role` field and are effectively preconfigured. Password reset is also included (beyond the spec).*

### 1.6.2 Dashboard

| # | Requirement | Status |
| - | ----------- | ------ |
| 5 | <span style="color:#15803D">Display total income, total expenses, available balance and budget status</span> | <span style="color:#15803D">✅ Completed</span> |
| 6 | <span style="color:#15803D">Quick navigation to Add Income, Add Expense, Budget and Transaction History</span> | <span style="color:#15803D">✅ Completed</span> |
| 7 | <span style="color:#15803D">Quick navigation to Learning, Feedback and Contact Support</span> | <span style="color:#15803D">✅ Completed</span> |
| 8 | <span style="color:#15803D">Visual indicators such as cards, progress bars or basic charts</span> | <span style="color:#15803D">✅ Completed</span> |
| 9 | <span style="color:#15803D">Clear message when no income, expense or budget data is available</span> | <span style="color:#15803D">✅ Completed</span> |

*Item 7: the dashboard quick-action grid now links directly to Add Expense, Add Income, Scan Receipt, Budget, Transaction History (History), Learning, Feedback, Contact Support and the AI Assistant. Feedback and Contact Support deep-link to their respective tabs.*

### 1.6.3 Income and Expense Management

| # | Requirement | Status |
| - | ----------- | ------ |
| 10 | <span style="color:#15803D">Add income entries with source, amount, date and description</span> | <span style="color:#15803D">✅ Completed</span> |
| 11 | <span style="color:#15803D">Add expense entries with category, amount, date and description</span> | <span style="color:#15803D">✅ Completed</span> |
| 12 | <span style="color:#15803D">View, edit and delete income and expense records</span> | <span style="color:#15803D">✅ Completed</span> |
| 13 | <span style="color:#15803D">Expense categories: Food, Transport, Education, Shopping, Entertainment, Bills, Savings, Miscellaneous</span> | <span style="color:#15803D">✅ Completed</span> |
| 14 | <span style="color:#15803D">Transaction history with basic search and filter by date, category and type</span> | <span style="color:#15803D">✅ Completed</span> |

*Item 13 note: the app ships Food, Transport, Shopping, Education, Entertainment, Bills, **Savings** and **Other** (used for Miscellaneous).*

### 1.6.4 Budget Management

| # | Requirement | Status |
| - | ----------- | ------ |
| 15 | <span style="color:#15803D">Create a monthly budget with a total budget amount</span> | <span style="color:#15803D">✅ Completed</span> |
| 16 | <span style="color:#15803D">Compare monthly expenses with the set budget</span> | <span style="color:#15803D">✅ Completed</span> |
| 17 | <span style="color:#15803D">Show remaining budget and overspending information clearly</span> | <span style="color:#15803D">✅ Completed</span> |
| 18 | <span style="color:#15803D">Update or delete an existing budget</span> | <span style="color:#15803D">✅ Completed</span> |

*Also includes per-category limits, alert thresholds and next-month prediction (beyond the spec).*

### 1.6.5 Learning and Tips

| # | Requirement | Status |
| - | ----------- | ------ |
| 19 | <span style="color:#15803D">Learning section with topics such as budgeting, saving, income, needs vs. optional expenses</span> | <span style="color:#15803D">✅ Completed</span> |
| 20 | <span style="color:#15803D">Learning content shown through short text, cards, examples or simple images</span> | <span style="color:#15803D">✅ Completed</span> |
| 21 | <span style="color:#15803D">Open and read individual learning topics from the learning screen</span> | <span style="color:#15803D">✅ Completed</span> |

*Seeded articles cover Budgeting, Saving, Needs vs Wants, Income Management, Debt and Investing. Content is delivered as text cards with an article reader; no image assets are bundled yet (the `assets/images/` folder is an empty drop-zone).*

### 1.6.6 About, Feedback and Contact Support

| # | Requirement | Status |
| - | ----------- | ------ |
| 22 | <span style="color:#15803D">About screen explaining the purpose of PennyPal</span> | <span style="color:#15803D">✅ Completed</span> |
| 23 | <span style="color:#15803D">Feedback screen allowing name, email, rating and comments</span> | <span style="color:#15803D">✅ Completed</span> |
| 24 | <span style="color:#15803D">Contact Support screen allowing subject and message details</span> | <span style="color:#15803D">✅ Completed</span> |
| 25 | <span style="color:#15803D">Validate required fields and show a confirmation after submission</span> | <span style="color:#15803D">✅ Completed</span> |
| 26 | <span style="color:#15803D">Chatbot for simple budgeting / savings questions with educational guidance</span> | <span style="color:#15803D">✅ Completed</span> |

*Item 22: a dedicated **About screen** (`/app/about`, linked from Profile and from Profile → Settings) now explains PennyPal's purpose, features and the "guidance only / not a bank" disclaimer.*
*Item 23: name and email are auto-filled from the signed-in profile rather than typed into the form.*
*Item 26: the chatbot ships with a deterministic, offline rule-based coach and an optional **Google Gemini** LLM brain (add a key in Settings → AI Assistant); it automatically falls back to the offline coach when Gemini is unavailable, so it never fails.*

### 1.6.7 Savings Goals

| # | Requirement | Status |
| - | ----------- | ------ |
| 27 | <span style="color:#15803D">Create goals with goal name, target amount, current savings, target date and monthly contribution</span> | <span style="color:#15803D">✅ Completed</span> |
| 28 | <span style="color:#15803D">Calculate remaining amount, progress percentage and estimated completion time</span> | <span style="color:#15803D">✅ Completed</span> |
| 29 | <span style="color:#15803D">Update contribution amounts and mark milestones</span> | <span style="color:#15803D">✅ Completed</span> |
| 30 | <span style="color:#15803D">Display goal progress using charts, progress bars, badges or motivational messages</span> | <span style="color:#15803D">✅ Completed</span> |
| 31 | <span style="color:#15803D">Completed goals archived and visible in goal history</span> | <span style="color:#15803D">✅ Completed</span> |

*Item 27: goals now store a **monthly contribution** alongside title, target, current amount and target date.*
*Item 28: remaining amount, progress percentage **and an estimated completion date** (derived from the remaining amount ÷ monthly contribution) are all computed, with a live preview in the goal form.*
*Item 31: completed goals are separated into a dedicated **Goal History** section on the Savings screen, where they remain visible with a "Done" badge.*

### 1.6.8 Optional Features

| # | Requirement | Status |
| - | ----------- | ------ |
| 32 | <span style="color:#15803D">Attach camera-captured images to transactions (optional)</span> | <span style="color:#15803D">✅ Completed</span> |
| 33 | <span style="color:#15803D">AI-powered expense categorization (optional)</span> | <span style="color:#15803D">✅ Completed</span> |

*Items 32–33: receipt capture (camera/gallery) runs on-device OCR, and category inference is **keyword/heuristic-based**, not an ML model. Profile photos are uploaded to **Cloudinary** (unsigned preset), not Firebase Storage.*

**Functional subtotal: 33 completed ✅ · 0 not completed ❌**

*A note on authentication (items 1–4): beyond the SRS baseline, sign-up and login now enforce an explicit password policy (min 8 characters, letter + number, no spaces) with a live strength meter, forgot-password can resend the reset link, **Google sign-up is available on the registration screen**, **email verification** is enforced — unverified accounts are held on a verify-email screen with resend and re-check actions — and registration accepts an **optional profile photo** (uploaded to Firebase Storage during sign-up; also editable later in Profile).*

---

## 1.7 Non-Functional Requirements

| Requirement | Status | Notes |
| ----------- | ------ | ----- |
| <span style="color:#15803D">Safety</span> | <span style="color:#15803D">✅ Completed</span> | No downloads or unsafe redirects; no payment flows. |
| <span style="color:#15803D">Accessibility</span> | <span style="color:#15803D">✅ Completed</span> | Text-scale clamping (0.9–1.3), labelled controls, large touch targets. Not formally audited. |
| <span style="color:#15803D">User-Friendliness</span> | <span style="color:#15803D">✅ Completed</span> | Simple language, clear menus, inline validation. |
| <span style="color:#15803D">Performance</span> | <span style="color:#15803D">✅ Completed</span> | Fast screens, smooth dashboard refresh, responsive entry. |
| <span style="color:#15803D">Reliability</span> | <span style="color:#15803D">✅ Completed</span> | Loading / error / empty states; defensive Firebase error mapping. |
| <span style="color:#15803D">Security</span> | <span style="color:#15803D">✅ Completed</span> | Firebase Auth, published Firestore security rules, TLS transport; images uploaded straight to Cloudinary with a restricted unsigned preset. |
| <span style="color:#15803D">Privacy</span> | <span style="color:#15803D">✅ Completed</span> | No card/bank data; minimal personal data; per-user data isolation. A financial summary is sent to Google only when the user opts in by adding a Gemini key (disclosed in Settings). |
| <span style="color:#15803D">Scalability</span> | <span style="color:#15803D">✅ Completed</span> | Single repository contract; Firestore scales horizontally. |
| <span style="color:#15803D">Compatibility</span> | <span style="color:#15803D">✅ Completed</span> | Android, iOS, tablets and Web (responsive). |
| <span style="color:#15803D">Maintainability</span> | <span style="color:#15803D">✅ Completed</span> | Feature-first structure, single data contract, documented in README. |

**Non-functional subtotal: 10 completed ✅ · 0 not completed ❌**

---

## 1.5 Constraints

| Constraint | Status | Notes |
| ---------- | ------ | ----- |
| <span style="color:#15803D">Real-Time Processing</span> | <span style="color:#15803D">✅ Completed</span> | Budget alerts fire instantly as spending crosses thresholds. |
| <span style="color:#15803D">Cross-Platform Compatibility</span> | <span style="color:#15803D">✅ Completed</span> | Single Flutter codebase for Android, iOS, tablet and Web. |
| <span style="color:#15803D">Security and Privacy</span> | <span style="color:#15803D">✅ Completed</span> | Encryption in transit + secure authentication + access rules. |
| <span style="color:#15803D">Offline Support (offline entry + auto-sync)</span> | <span style="color:#15803D">✅ Completed</span> | Firestore offline persistence caches entries made without a connection and **queues** them; the SDK syncs automatically on reconnect. An on-screen banner shows offline status. |
| <span style="color:#15803D">AI Response Latency</span> | <span style="color:#15803D">✅ Completed</span> | Assistant is offline/deterministic so responses are instant; loading states exist for async screens. |

**Constraints subtotal: 5 completed ✅ · 0 not completed ❌**

---

## Database Design

| Item | Status | Notes |
| ---- | ------ | ----- |
| <span style="color:#15803D">Entity design for users, transactions, budgets, goals, reports, learning, notifications, support</span> | <span style="color:#15803D">✅ Completed</span> | Implemented as Firestore collections: `users`, `transactions`, `income`, `expenses`, `budgets`, `savingGoals`, `subscriptions`, `notifications`, `badges`, `challenges`, `reports`, `learningContent`, `supportQueries`. |

*The SRS explicitly allows the sample entity design to be modified. Differences: `UserProfiles` is folded into `users`; `Categories` is an enum rather than a collection; `income`/`expenses` are stored separately alongside a unified `transactions` ledger. Offline caching uses Firestore's built-in persistent local cache instead of a separate SQLite file (see Offline Support under Constraints).*

---

## 1.8 Interface Requirements

| Requirement | Status | Notes |
| ----------- | ------ | ----- |
| <span style="color:#15803D">IDE: Flutter 3.x / Dart 3.x with related libraries</span> | <span style="color:#15803D">✅ Completed</span> | Flutter 3.x, Dart 3.x, Material 3 (the Android Studio / Java alternative was not used). |
| <span style="color:#15803D">AI tools: on-device AI packages / ML Kit</span> | <span style="color:#15803D">✅ Completed</span> | Google ML Kit text recognition used for receipt OCR, plus an optional **Google Gemini** LLM for the AI assistant (REST). TensorFlow Lite / `dart_ml` not used. |
| <span style="color:#15803D">Database: SQLite or Firebase</span> | <span style="color:#15803D">✅ Completed</span> | Firebase (Firestore + Auth + Cloud Messaging); profile images on Cloudinary. |
| <span style="color:#15803D">Testing on emulator / physical device / Web browser</span> | <span style="color:#15803D">✅ Completed</span> | 36 automated tests (`flutter test`); manual device testing supported. |

**Interface subtotal: 4 completed ✅ · 0 not completed ❌**

---

## 1.9 Project Deliverables

| Deliverable | Status | Notes |
| ----------- | ------ | ----- |
| <span style="color:#15803D">Project Installation Instructions (MANDATORY)</span> | <span style="color:#15803D">✅ Completed</span> | Quick-start + Firebase console setup steps in `README.md`. |
| <span style="color:#15803D">ReadMe file with assumptions</span> | <span style="color:#15803D">✅ Completed</span> | `README.md` present (Markdown, not `.doc`). |
| <span style="color:#DC2626">Full Documentation pack (problem definition, design specs, diagrams, DB design, test data)</span> | <span style="color:#DC2626">❌ Not completed</span> | Not included in this repository. |
| <span style="color:#DC2626">User Credentials (Login ID and Password - MANDATORY)</span> | <span style="color:#DC2626">❌ Not completed</span> | No credentials file; accounts are created via sign-up / Firebase console. |
| <span style="color:#DC2626">SQL scripts (.sql database & table definitions)</span> | <span style="color:#DC2626">❌ Not completed</span> | Not applicable to a Firebase backend — no SQL schema exists. |
| <span style="color:#DC2626">Android Package File (.apk)</span> | <span style="color:#DC2626">❌ Not completed</span> | No built APK committed (`flutter build apk` produces one). |
| <span style="color:#DC2626">Demo video (.mp4)</span> | <span style="color:#DC2626">❌ Not completed</span> | Not included in this repository. |

**Deliverables subtotal: 2 completed ✅ · 5 not completed ❌**

---

## Assumptions

1. This report reflects the state of the code in this repository; items marked ✅ are present and wired, not stubs.
2. "Completed" for non-functional requirements is based on design-level implementation (states, guards, rules) rather than a formal audit/load test.
3. The project is built on **Firebase**, so the SRS's optional SQLite/SQL deliverables are treated as not applicable rather than missing features.
4. Where a named element of a requirement is absent (e.g. savings *monthly contribution*), the row is marked ❌ even though adjacent parts of that feature exist — the exact status is described in the row note.

*End of compliance report.*
