# Feature 10: Notifications & Background Alerts

## 1. Overview & Purpose
Timely notifications keep family members informed about critical financial milestones: upcoming mobile plan expirations, monthly utility bills due dates, EMI deduction reminders, and high-value family spending events. The system combines local Android notifications with background OS worker polling.

---

## 2. Source Files & Implementation Matrix

### Mobile Client (`manikutti_mobile`)
- [`lib/screens/notification_settings_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/notification_settings_screen.dart):
  - Comprehensive user-facing notification preferences screen.
  - Live OS permission monitor (detects whether Android permits notifications or is blocking them).
  - 1-tap deep bridge to phone's Android App Notification Settings via native MethodChannel.
  - Granular toggles: Voice & Widget Expense Confirmations (`key_voice_notifications_enabled`), Salary Reminders (`key_salary_notifications_enabled`), Bill Due Alerts (`key_bill_due_notifications_enabled`), Family Shared Finance Alerts (`key_payment_notifications_enabled`).
  - "Send Test Notification" action for instant on-device shade delivery verification.
- [`lib/screens/settings_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/settings_screen.dart):
  - Houses the top-level `Notifications` preference tile routing to `NotificationSettingsScreen`.
- [`lib/services/notification_service.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/services/notification_service.dart):
  - Wraps `flutter_local_notifications` and **Firebase Cloud Messaging (`firebase_messaging` + `firebase_core`)** with dedicated vector small icon `ic_notification` (`drawable/ic_notification.xml`) and voice icon `ic_tile_mic` (`drawable/ic_tile_mic.xml`).
  - Methods: `initialize()`, `initializeFirebasePush()`, `syncFcmTokenWithServer()`, `areNotificationsEnabled()`, `openSystemNotificationSettings()`, `showImmediateNotification()`, `sendTestNotification()`, `scheduleMonthlyReminder()`.
- [`lib/services/voice_expense_service.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/services/voice_expense_service.dart):
  - Checks user toggle `key_voice_notifications_enabled` before posting immediate confirmation notification to `voice_expense_channel_v2` with `ic_tile_mic`.
- [`android/app/src/main/kotlin/com/abhilash/manikutti/MainActivity.kt`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/kotlin/com/abhilash/manikutti/MainActivity.kt) & [`VoiceDialogActivity.kt`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/kotlin/com/abhilash/manikutti/VoiceDialogActivity.kt):
  - Implements MethodChannel `com.abhilash.manikutti/settings` launching `Settings.ACTION_APP_NOTIFICATION_SETTINGS`.
- [`lib/main.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/main.dart):
  - Initializes Firebase (`Firebase.initializeApp()`), registers `FirebaseMessaging.onBackgroundMessage`, initializes `FeatureFlagService`, and runs Workmanager background execution callback (`@pragma('vm:entry-point') callbackDispatcher`) as an offline-resilient polling backup.
- [`lib/services/api_service.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/services/api_service.dart):
  - `_TelemetryHttpClient`: Intercepts HTTP >= 400 and network exceptions across all API routes (including `/api/sheets/home-loan`) -> logs to Firebase Crashlytics + `/api/telemetry/errors`.
  - `registerFcmToken(token)`: Persists device FCM token to Firestore via backend.
  - `fetchNotifications(familyCode)`: Retrieves latest family alerts.
- [`lib/services/crash_reporting_service.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/services/crash_reporting_service.dart):
  - Configures `firebase_crashlytics` (`FlutterError.onError`, `PlatformDispatcher.instance.onError`, `CrashlyticsRouteObserver`) and buffers structured error telemetry offline in `SharedPreferences` until flushed to `/api/telemetry/errors`.
- [`android/app/proguard-rules.pro`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/proguard-rules.pro):
  - Retains `ComponentRegistrar` zero-arg constructors (`firebase-components:18.0.0` compatibility with AGP 9 R8 full mode), `com.it_nomads.fluttersecurestorage.**`, ML Kit classes, and Crashlytics `SourceFile,LineNumberTable` attributes.

### Backend API & Firebase (`Manikutti`)
- [`src/lib/firebaseAdmin.ts`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/lib/firebaseAdmin.ts):
  - Modular `firebase-admin` v14 initialization (`FIREBASE_SERVICE_ACCOUNT`) providing Cloud Firestore & FCM `sendFcmToUsers()` multicast helper with automatic stale token pruning.
- [`src/lib/errorTelemetry.ts`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/lib/errorTelemetry.ts) & [`src/app/api/telemetry/errors/route.ts`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/app/api/telemetry/errors/route.ts):
  - Persists mobile & web API failure telemetry to the `Error_Logs` sheet in `ADMIN_SPREADSHEET_ID` and serves filtered logs to Admin UI (`DiagnosticsTab.tsx`) and AI CLI (`scripts/read_crashes.mjs`).
- [`src/app/api/notifications/register-token/route.ts`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/app/api/notifications/register-token/route.ts):
  - Authenticated `POST` saving device FCM token to Firestore `users/{email}.fcmTokens`.
- `/api/sheets/notifications/route.ts`:
  - GET/POST notifications for a family; triggers FCM push alerts to targeted or all family members.
- `/api/sheets/expense/route.ts`:
  - Triggers instant FCM multicast pushes to fellow family members whenever a shared `Family_Expenses` transaction is posted.
- **Google Sheets Tab**: `Notifications` in `FAMILY_SPREADSHEET_ID`
  - Columns: `[NotificationID, Title, Message, Date, TargetUserEmail, ReadStatus]`

---

## 3. Data Flow & Mechanics

1. **Local Scheduled Alerts**:
   - When a mobile recharge or utility bill is created, `NotificationService` schedules a notification for $N$ days before the expiry date at 9:00 AM local time.
2. **Background Polling via Workmanager**:
   - Every 15 minutes (or OS-governed interval), `callbackDispatcher` activates in the background.
   - Queries `ApiService.fetchNotifications(familyCode)`.
   - Compares the latest notification date against `last_notified_date` in `SharedPreferences`.
   - If a new unread alert is found, fires `showImmediateNotification()` so the user gets a system tray alert even if the app is closed.

---

## 4. Edge Cases & OS Permissions

- **Android 13+ Notification Permission**: `requestPermission()` must be invoked during setup or first launch; otherwise notifications are silently blocked by the OS.
- **Exact Alarms (Android 12+)**: Uses `SCHEDULE_EXACT_ALARM` permissions for precise bill due-date alarms.
- **Background Execution Limits**: Handled via `Workmanager` which adheres to Android Battery Saver and Doze Mode rules without causing battery drain.

---

## 5. Future Possible Upgrades

- **Firebase Cloud Messaging (FCM)**: Transition from background polling to instant server-to-device push notifications.
- **WhatsApp Notification Bot**: Send bill reminders and spending summaries to family members on WhatsApp using Twilio or WhatsApp Cloud API.
- **Weekly Digest Email**: Consolidated weekly summary email triggered on Sunday evenings.

---

## 6. AI Modification & Maintenance Instructions

- When modifying notifications:
  1. The entry point `callbackDispatcher` in `main.dart` MUST have `@pragma('vm:entry-point')` to prevent the Dart compiler from stripping it in release AOT builds.
  2. Always verify that notification channel IDs remain consistent to avoid duplicate channels in Android settings.


---

## 6. SMS Expense Detection & Mandatory EMI Alert Channels (Added)

- **New Android Notification Channels (`NotificationChannelHelper.kt`, `notification_service.dart`)**:
  - `sms_expense_channel` (`Bank SMS Transactions`, High Importance): Interactive notifications asking `"Transaction detected — want to log?"` with **Yes, Log** and **Dismiss** PendingIntent actions handled by `SmsWidgetActionReceiver`.
  - `emi_mandatory_channel` (`Mandatory Monthly EMI & Share Alerts`, High Importance): Day-before-10th reminders (`NotificationService.scheduleMonthlyReminder` with custom `channelId`, `channelName`, `payload: 'emi_mandatory'`) scheduled by `EmiReminderService` and cancelled/updated automatically when paid or SMS-detected.
- **Settings UI (`manikutti_mobile/lib/screens/notification_settings_screen.dart`)**:
  - Added **Bank SMS Expense Detection** toggle (`sms_detection_enabled`), Android `RECEIVE_SMS` / `READ_SMS` permission request button, and manual **Scan Recent Bank SMS** trigger.
