# Feature 14: Home Screen Widget, Voice Logging & Assistant Shortcuts

## 1. Overview & Purpose
This module provides fast, zero-friction expense logging and financial awareness without requiring the user to open or navigate the full app. It integrates:
1. **Interactive Phone Home Screen Widget**: Displays Month-to-Date total expenses, nearest pending mobile recharge / utility bill alert, and 1-tap quick action buttons (Voice Mic and Manual Add).
2. **AI Voice Expense Logging Engine**: Real-time on-device speech-to-text supporting Malayalam (`ml_IN`), Manglish, and English (`en_IN`), parsed by Google Gemini AI with intelligent offline regex fallback.
3. **Android Quick Settings Tile**: Notification shade tile accessible from any screen or lock screen with Manikutti branding and microphone.
4. **Google Assistant & Siri Shortcuts**: Deep linking via `manikutti://voice-dialog` / `manikutti://voice-expense`, Google Assistant App Actions (`actions.intent.OPEN_APP_FEATURE` with localized Malayalam & English feature synonyms), and 1-tap Assistant Routines.

---

## 2. Source Files & Implementation Matrix

### Web Application (`Manikutti`)
- [`src/app/api/ai/voice-expense/route.ts`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/app/api/ai/voice-expense/route.ts): Serverless Gemini AI route with structured JSON extraction (`action: 'create' | 'delete'`, count extraction, category/note/amount) and offline/rate-limit fallback parser.
- [`src/app/api/sheets/expense/route.ts`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/app/api/sheets/expense/route.ts): Enhanced `DELETE` endpoint supporting `action=delete_last&count=N` range deletion, exact ISO timestamp matching (`date=...`), and row ID deletion.
- [`src/lib/googleSheets.ts`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/lib/googleSheets.ts): Added `deleteRows(spreadsheetId, sheetName, startIndex, endIndex)` for batch row removal.

### Mobile Client (`manikutti_mobile`)
- [`lib/services/voice_expense_service.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/services/voice_expense_service.dart): Core voice service handling Gemini API integration, offline regex parser with multilingual intent extraction (`create` vs `delete`), zero-amount guards, SQLite deletion, and confirmation notifications.
- [`lib/database/db_helper.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/database/db_helper.dart): Added `getLastTransactions(count)`, `deleteLastTransactions(count)`, and `deleteZeroOrNegativeTransactions()`.
- [`lib/services/api_service.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/services/api_service.dart): Added `deleteLastTransactions(count, sheetName)` and `deleteExpenseByDate(date, sheetName)`.
- [`lib/screens/transactions_log_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/transactions_log_screen.dart): Added swipe-to-delete Dismissible gesture, long-press deletion dialog, trash action icon, and auto-purge of invalid zero-amount records on load.
- [`lib/services/widget_data_service.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/services/widget_data_service.dart): Aggregates monthly expense total and scans pending/overdue recharges and bills, pushing updates to `HomeWidget`.
- [`lib/widgets/spiral_voice_waves.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/spiral_voice_waves.dart): CustomPainter acoustic wave visualizer featuring the Manikutti logo emblem at the center with 4 rotating holographic spiral arms and expanding ripple rings.
- [`lib/widgets/voice_dialog_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/voice_dialog_screen.dart): Translucent floating dialog overlay rendered directly over the phone's home screen wallpaper or current app without opening the main app, rendering create/delete confirmations.
- [`lib/widgets/voice_logging_sheet.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/voice_logging_sheet.dart): In-app bottom sheet UI with speech recognition, language toggle (Malayalam / English), animated pulsing mic, and structured create/delete transaction cards.
- [`lib/main.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/main.dart): Deep link router (`manikutti://voice-dialog` and `manikutti://add-transaction`), `/voice-dialog` transparent route, dedicated `@pragma('vm:entry-point') voiceDialogMain` entrypoint hosting `VoiceDialogApp`, and 2-minute App Lock timer exemption for voice dialogs.
- [`lib/screens/dashboard_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/dashboard_screen.dart): Hosts in-app Voice AI button in AppBar and triggers widget updates on data reload.

### Android Native Components
- [`android/app/src/main/kotlin/com/abhilash/manikutti/VoiceDialogActivity.kt`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/kotlin/com/abhilash/manikutti/VoiceDialogActivity.kt): Native translucent Activity with `BackgroundMode.transparent`, `getDartEntrypointFunctionName() = "voiceDialogMain"`, and `singleInstance` task isolation.
- [`android/app/src/main/kotlin/com/abhilash/manikutti/ManikuttiHomeWidgetProvider.kt`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/kotlin/com/abhilash/manikutti/ManikuttiHomeWidgetProvider.kt): Native `AppWidgetProvider` updating RemoteViews and binding `widget_btn_mic` with an explicit `PendingIntent` (requestCode 100).
- [`android/app/src/main/kotlin/com/abhilash/manikutti/ManikuttiVoiceTileService.kt`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/kotlin/com/abhilash/manikutti/ManikuttiVoiceTileService.kt): Android `TileService` for Notification Shade quick toggle launching `VoiceDialogActivity`.
- [`android/app/src/main/res/layout/widget_layout.xml`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/res/layout/widget_layout.xml): Home screen widget layout.
- [`android/app/src/main/res/xml/shortcuts.xml`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/res/xml/shortcuts.xml): Google Assistant App Actions (`OPEN_APP_FEATURE`, `CREATE_ITEM`) & app launcher shortcuts routing to `VoiceDialogActivity`.
- [`android/app/src/main/res/values/arrays.xml`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/res/values/arrays.xml): Feature synonyms for Assistant voice routing in Malayalam and English.
- [`android/app/src/main/res/xml/manikutti_widget_info.xml`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/res/xml/manikutti_widget_info.xml): AppWidget provider metadata.
- [`android/app/src/main/res/values/styles.xml`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/res/values/styles.xml) & `values-night/styles.xml`: Declares `TransparentTheme` (`Theme.Translucent.NoTitleBar`) with dim amount.

---

## 3. Data Flow & Mechanics

1. **Floating Home Screen Overlay (Option B)**:
   - Tapping the mic on the **Home Screen Widget** or **Quick Settings Tile** launches `VoiceDialogActivity` directly via explicit `PendingIntent`.
   - `VoiceDialogActivity` runs in an isolated task stack (`android:taskAffinity="com.abhilash.manikutti.voice"`, `launchMode="singleInstance"`) and boots dedicated entrypoint `voiceDialogMain`.
   - The user stays on their home screen wallpaper without opening `MainActivity` or triggering `AppLockScreen`.
   - A floating frosted-glass card pops up with the animated spiral acoustic wave visualizer and live speech transcription.
2. **Google Assistant Hands-Free Execution**:
   - Spoken phrases like *"Hey Google, 100 roopakku petrol adichu, ith Manikuttiyil save cheyyu"* deliver the captured transcript directly via intent `manikutti://voice-dialog?query=...`.
   - The app processes the query in the background without opening the main UI.
3. **Intent Classification & Entity Extraction**:
   - Transcript sent to `/api/ai/voice-expense`.
   - Gemini classifies intent as `action: "create"` or `action: "delete"`.
   - **For "create"**: Extracts `{ amount (> 0), category, note, type, bankAccount }`. If amount is missing or <= 0, the system prompts the user and rejects saving bogus ₹0 records.
   - **For "delete"**: Extracts transaction count `count` (1 to 10) from phrases like *"delete last 2 transactions"*, *"undo last expense"*, *"avasaana transaction delete aakku"*, or *"അവസാനത്തെ രണ്ട് ട്രാൻസാക്ഷൻ ഒഴിവാക്കുക"*.
   - If offline, `VoiceExpenseService.parseLocally` provides instantaneous rule-based extraction supporting Malayalam and English numbers and commands.
4. **Storage & Normalization**:
   - **Creation**: Recorded into local SQLite `transactions` table with `.toUtc().toIso8601String()` timestamp and `synced = 0`. Fires an immediate system notification via dedicated `voice_expense_channel` (max importance, sound, vibration): 🔔 *"Manikutti: Expense Saved - Saved ₹100 for Petrol (Fuel)"* or *"Manikutti: Income Recorded - Recorded +₹100 for Received from Ajesh (Income)"*. Guaranteed to post via `await` before overlay dismissal, and automatically ensures Android 13+ `POST_NOTIFICATIONS` permissions.
   - **Deletion**: Deletes the last N records from SQLite, deletes synced records from Google Sheets via `DELETE /api/sheets/expense?action=delete_last&count=N`, purges any stray ₹0 records, updates the widget, and notifies: 🔔 *"Manikutti: Transaction Deleted - Deleted last 2 transactions"*.
   - **Manual Cleanup**: In `TransactionsLogScreen`, users can swipe left to delete, long-press to delete, or tap the delete icon on any transaction, and any ₹0 entries are automatically cleaned up on load.
   - Automatically closes the floating dialog (returning the user to where they were).
   - Triggers `WidgetDataService.updateWidgetData()` to refresh the widget numbers immediately.
   - Fire-and-forget sync to Google Sheets via `SyncService.instance.syncData()`.
