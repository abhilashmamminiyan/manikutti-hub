# Feature 10: Notifications & Background Alerts

## 1. Overview & Purpose
Timely notifications keep family members informed about critical financial milestones: upcoming mobile plan expirations, monthly utility bills due dates, EMI deduction reminders, and high-value family spending events. The system combines local Android notifications with background OS worker polling.

---

## 2. Source Files & Implementation Matrix

### Mobile Client (`manikutti_mobile`)
- [`lib/services/notification_service.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/services/notification_service.dart):
  - Wraps `flutter_local_notifications`.
  - Android notification channel configuration:
    - ID: `manikutti_alerts`
    - Name: `Manikutti Financial Alerts`
    - Importance: `Importance.high`, `Priority.high`.
  - Methods: `initialize()`, `showImmediateNotification()`, `scheduleNotification()`, `cancelNotification()`.
- [`lib/main.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/main.dart):
  - Workmanager background execution callback:
    ```dart
    @pragma('vm:entry-point')
    void callbackDispatcher() {
      Workmanager().executeTask((task, inputData) async { ... });
    }
    ```
  - Periodically checks API for remote notifications and checks local recharge/utility tables.
- [`lib/services/api_service.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/services/api_service.dart):
  - `fetchNotifications(familyCode)`: Retrieves latest family alerts.

### Backend API & Google Sheets (`Manikutti`)
- `/api/sheets/notifications/route.ts`:
  - GET/POST notifications for a family.
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
