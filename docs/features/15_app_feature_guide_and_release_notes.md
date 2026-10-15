# Feature 15: About App, User Feature Catalog & Release Notes ("What's New")

## 1. Overview & Purpose
This module introduces a non-technical, user-centric discovery and onboarding experience within Manikutti Hub. Designed specifically for regular users and family members, it showcases every capability of the application from a benefit-oriented perspective, strictly free of technical jargon, database schemas, or cloud backend references.

Key elements include:
1. **Feature Catalog & Index Page (`AboutAppScreen`)**: Searchable, categorized repository of all active, popular, security, and upcoming capabilities.
2. **Dedicated Per-Feature Detail Screens (`FeatureDetailScreen`)**: In-depth explanations of value, key highlights, direct in-app navigation actions, and step-by-step screenshot tutorials.
3. **Simulated Smartphone Screenshot Tutorials (`FeatureMockupPreview` & `ScreenshotTutorialStepper`)**: High-fidelity, responsive vector smartphone mockups demonstrating complex workflows (e.g., adding the Android Home Screen Widget, invoking Google Assistant commands, configuring Quick Settings tiles, uploading bank statements, setting up biometric unlock).
4. **"What's New" Release Notes System (`WhatsNewService` & `WhatsNewScreen`)**: Automated version tracking with reactive unread indicators (red badge dot) on the Settings icon in the Dashboard AppBar, the App Drawer, and within the Settings menu.

---

## 2. Source Files & Implementation Matrix

### Mobile Client (`manikutti_mobile`)
- Data Models & Data Source:
  - [`lib/models/app_feature_info.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/models/app_feature_info.dart): Data structures for `AppFeature`, `TutorialStep`, and `MockupType`.
  - [`lib/services/app_features_data.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/services/app_features_data.dart): Comprehensive catalog of 13 application features, non-technical overviews, benefits, and step-by-step walkthroughs.
  - [`lib/services/whats_new_service.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/services/whats_new_service.dart): Version change tracker with `ValueNotifier<bool> hasUnreadNotifier` and persistent `last_seen_release_version` in `SharedPreferences`.
- Visual Tutorial & Mockup Components:
  - [`lib/widgets/feature_mockup_preview.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/feature_mockup_preview.dart): Vector-based realistic smartphone frame rendering mockups for Home Widget addition, Google Assistant & Quick Settings tile, Bank Statement upload, Biometrics, and Voice Logging.
  - [`lib/widgets/screenshot_tutorial_stepper.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/screenshot_tutorial_stepper.dart): Interactive multi-step carousel with step pills, pro tips, and forward/back navigation.
- Screens:
  - [`lib/screens/about_app_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/about_app_screen.dart): Index screen with app identity card, "What's New" banner, category filter chips, search input, and feature cards.
  - [`lib/screens/feature_detail_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/feature_detail_screen.dart): Dedicated per-feature page embedding hero card, overview, tutorial stepper, benefit checklist, and 1-tap "Try Feature Now" button.
  - [`lib/screens/whats_new_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/whats_new_screen.dart): Release highlights sheet showing version milestones and automatically clearing unread badges.
  - [`lib/screens/settings_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/settings_screen.dart): Integrates "App Information & Feature Guides" group with reactive unread dot.
- Navigation & Entrypoints:
  - [`lib/screens/dashboard_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/dashboard_screen.dart): Settings icon button in AppBar equipped with unread notification dot badge.
  - [`lib/widgets/app_drawer.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/app_drawer.dart): Added "About Manikutti" entry and unread dot badge on "Settings" list tile.
  - [`lib/main.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/main.dart): Invokes `WhatsNewService.instance.init()` upon startup.
- Localization:
  - [`lib/l10n/app_en.arb`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/l10n/app_en.arb) & [`lib/l10n/app_ml.arb`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/l10n/app_ml.arb): English and Malayalam keys for About App and What's New.

---

## 3. Data Flow & Mechanics

1. **Unread Dot Lifecycle**:
   - On app startup, `WhatsNewService.instance.init()` retrieves `last_seen_release_version` from `SharedPreferences`.
   - If `last_seen_release_version != WhatsNewService.currentVersion` (e.g. `'2.2.1'`), `hasUnreadNotifier.value` is set to `true`.
   - `ValueListenableBuilder<bool>` listens to `hasUnreadNotifier` in `DashboardScreen`, `AppDrawer`, and `SettingsScreen`, instantly rendering a red badge dot on the Settings icon.
   - When the user visits `WhatsNewScreen`, `WhatsNewService.instance.markAsRead()` records `'2.2.1'` to `SharedPreferences` and sets `hasUnreadNotifier.value = false`, immediately removing the unread badges across all screens without requiring an app reload.
2. **Category Filtering & Search**:
   - `AboutAppScreen` dynamically filters features based on the active category pill (`All Features`, `Voice & Widgets`, `Banking & Statements`, `Privacy & Security`, `Family & Budget`, `Upcoming Roadmap`) and real-time substring search matching title, tagline, or body text.
3. **Interactive Step Navigation**:
   - In `ScreenshotTutorialStepper`, the user steps through stages (Step 1, Step 2, Step 3).
   - Each step transitions the vector smartphone preview to match the physical user action (e.g., long-pressing wallpaper -> selecting widget card -> viewing pinned live card).

---

## 4. User-Perspective Guidelines & Tone Contracts

- **Zero Technical References**: UI strings, descriptions, and mockups never mention Google Sheets, API endpoints, JSON payloads, service accounts, or database tables. All backend operations are presented as "Secure Cloud Vault", "Private Cloud Backup", or "Local Phone Vault".
- **Family & Regional Tone**: Terminology is optimized for everyday Kerala households, referencing local payment practices (e.g., UPI, milk, fish, petrol, electricity, mobile recharges) with bilingual Malayalam/English presentation.

---

## 5. Future Possible Upgrades

- **Interactive In-App Tooltips**: Overlay spotlight coach-marks guiding new users through their first expense or voice recording.
- **Dynamic In-App Feedback & Voting**: Allow family members to vote on upcoming features in the Sneak Peek roadmap directly from their phone.

---

## 6. AI Modification & Maintenance Instructions

- When releasing a new version:
  1. Increment `WhatsNewService.currentVersion` in `lib/services/whats_new_service.dart`.
  2. Add the corresponding `AppReleaseNote` entry to the top of `releases` with user-friendly benefit highlights.
  3. Ensure all new features are registered in `lib/services/app_features_data.dart` with localized title and descriptions.
  4. Never remove the unread dot reactivity pattern.
