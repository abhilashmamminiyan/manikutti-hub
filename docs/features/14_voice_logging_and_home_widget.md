# Feature 14: Home Screen Widget, Voice Logging & Assistant Shortcuts

## 1. Overview & Purpose
This module provides fast, zero-friction expense logging and financial awareness without requiring the user to open or navigate the full app. It integrates:
1. **Interactive Home Screen Keypad Widget ("Manikutti Quick Keypad")**:
   - Features an on-screen numeric calculator keypad (`1-9`, `0`, Clear `C`, Backspace `⌫`), preset chips (`+50`, `+100`, `+500`), and category selector directly on the user's home screen.
   - Bypasses Android's soft-keyboard limitation on `RemoteViews` by updating input state natively in < 10ms via explicit `BroadcastReceiver` intents.
   - Saves expenses directly into local SQLite `transactions` table with an ISO 8601 UTC timestamp and `synced = 0`.
   - Fires an immediate heads-up confirmation notification via `voice_expense_channel_v2` with vibration and sound.
   - Updates the month total across all widgets instantaneously.
2. **Summary & Quick Action Widget ("Manikutti Finance")**:
   - Displays Month-to-Date total expenses, nearest pending mobile recharge / utility bill alert, and 1-tap quick action buttons (Voice Mic and Manual Add).
3. **Category Preferences Manager**:
   - Allows users to customize and add new expense categories directly from **Settings $\rightarrow$ Expense Categories**.
   - Custom categories dynamically synchronize to the home screen Quick Log widget and manual transaction entry screens.
4. **AI Voice Expense Logging Engine**:
   - Real-time on-device speech-to-text supporting Malayalam (`ml_IN`), Manglish, and English (`en_IN`), parsed by Google Gemini AI with intelligent offline regex fallback.
5. **Android Quick Settings Tile**:
   - Notification shade tile accessible from any screen or lock screen with Manikutti branding and microphone.
6. **Google Assistant & Siri Shortcuts**:
   - Deep linking via `manikutti://voice-dialog` / `manikutti://voice-expense`, Google Assistant App Actions (`actions.intent.OPEN_APP_FEATURE` with localized Malayalam & English feature synonyms), and 1-tap Assistant Routines.

---

## 2. Source Files & Implementation Matrix

### Web Application (`Manikutti`)
- [`src/app/api/ai/voice-expense/route.ts`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/app/api/ai/voice-expense/route.ts): Serverless Gemini AI route with structured JSON extraction (`action: 'create' | 'delete'`, count extraction, category/note/amount) and offline/rate-limit fallback parser.
- [`src/app/api/sheets/expense/route.ts`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/app/api/sheets/expense/route.ts): Enhanced `DELETE` endpoint supporting `action=delete_last&count=N` range deletion, exact ISO timestamp matching (`date=...`), and row ID deletion.
- [`src/lib/googleSheets.ts`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/lib/googleSheets.ts): Added `deleteRows(spreadsheetId, sheetName, startIndex, endIndex)` for batch row removal.
- [`src/app/voice-dialog/page.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/app/voice-dialog/page.tsx) & `src/app/voice-expense/page.tsx`: Client-side fallback and automated Android intent bridge for `https://manikutti.vercel.app/voice-dialog`.
- [`public/.well-known/assetlinks.json`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/public/.well-known/assetlinks.json): Digital Asset Links verification file enabling seamless Android App Links without browser disambiguation prompts.

### Mobile Client (`manikutti_mobile`)
- [`lib/services/category_service.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/services/category_service.dart): Manages system and user-defined custom expense categories, persists them to `SharedPreferences`, syncs them to `HomeWidget` storage, and notifies active listeners.
- [`lib/screens/category_preferences_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/category_preferences_screen.dart): Dedicated preferences screen for viewing, adding, and removing categories with immediate synchronization to widget and transaction logs.
- [`lib/screens/settings_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/settings_screen.dart): Hosts the "Expense Categories" settings card navigating to `CategoryPreferencesScreen`.
- [`lib/screens/add_transaction_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/add_transaction_screen.dart): Dynamically populates expense categories from `CategoryService`.
- [`lib/services/widget_data_service.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/services/widget_data_service.dart): Aggregates monthly expense total, synchronizes category list, and dispatches updates to both `ManikuttiHomeWidgetProvider` and `ManikuttiQuickLogWidgetProvider`.
- [`lib/services/voice_expense_service.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/services/voice_expense_service.dart): Core voice service handling Gemini API integration, offline regex parser with multilingual intent extraction (`create` vs `delete`), zero-amount guards, SQLite deletion, and confirmation notifications.
- [`lib/database/db_helper.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/database/db_helper.dart): Added `getLastTransactions(count)`, `deleteLastTransactions(count)`, and `deleteZeroOrNegativeTransactions()`.
- [`lib/services/api_service.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/services/api_service.dart): Added `deleteLastTransactions(count, sheetName)` and `deleteExpenseByDate(date, sheetName)`.
- [`lib/screens/transactions_log_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/transactions_log_screen.dart): Added swipe-to-delete Dismissible gesture, long-press deletion dialog, trash action icon, and auto-purge of invalid zero-amount records on load.
- [`lib/screens/notification_settings_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/notification_settings_screen.dart): Added Google Assistant & Deep Links management card, live deep link viewer (`https://manikutti.vercel.app/voice-dialog`), and 1-tap "Sync Shortcuts" bridge to `ShortcutManagerCompat`.
- [`lib/widgets/spiral_voice_waves.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/spiral_voice_waves.dart): CustomPainter acoustic wave visualizer featuring the Manikutti logo emblem at the center with 4 rotating holographic spiral arms and expanding ripple rings.
- [`lib/widgets/voice_dialog_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/voice_dialog_screen.dart): Translucent floating dialog overlay with `MethodChannel('com.abhilash.manikutti/voice_dialog')` listener handling warm `onNewIntent` query events and rendering create/delete confirmations.
- [`lib/widgets/voice_logging_sheet.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/voice_logging_sheet.dart): In-app bottom sheet UI with speech recognition, language toggle (Malayalam / English), animated pulsing mic, and structured create/delete transaction cards.
- [`lib/main.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/main.dart): Dual-protocol deep link router (`manikutti://` and `https://manikutti.vercel.app`), `/voice-dialog` transparent route, dedicated `@pragma('vm:entry-point') voiceDialogMain` entrypoint hosting `VoiceDialogApp`, and 2-minute App Lock timer exemption for voice dialogs.
- [`lib/screens/dashboard_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/dashboard_screen.dart): Hosts in-app Voice AI button in AppBar and triggers widget updates on data reload.

### Android Native Components
- [`android/app/src/main/kotlin/com/abhilash/manikutti/ManikuttiQuickLogWidgetProvider.kt`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/kotlin/com/abhilash/manikutti/ManikuttiQuickLogWidgetProvider.kt): Interactive `AppWidgetProvider` handling keypad digit accumulation, presets, backspace, clear, category cycling, direct SQLite `manikutti.db` inserts, heads-up notification posting, and widget updates.
- [`android/app/src/main/kotlin/com/abhilash/manikutti/ManikuttiHomeWidgetProvider.kt`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/kotlin/com/abhilash/manikutti/ManikuttiHomeWidgetProvider.kt): Native `AppWidgetProvider` updating RemoteViews and binding `widget_btn_mic` with an explicit `PendingIntent` (requestCode 100).
- [`android/app/src/main/kotlin/com/abhilash/manikutti/NotificationChannelHelper.kt`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/kotlin/com/abhilash/manikutti/NotificationChannelHelper.kt): Declares system notification channels including `voice_expense_channel_v2` with `IMPORTANCE_HIGH`, sound, and vibration.
- [`android/app/src/main/kotlin/com/abhilash/manikutti/VoiceDialogActivity.kt`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/kotlin/com/abhilash/manikutti/VoiceDialogActivity.kt): Native translucent Activity with `BackgroundMode.transparent`, `getDartEntrypointFunctionName() = "voiceDialogMain"`, `singleInstance` task isolation, and `onNewIntent(intent: Intent)` warm event bridge.
- [`android/app/src/main/kotlin/com/abhilash/manikutti/ShortcutHelper.kt`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/kotlin/com/abhilash/manikutti/ShortcutHelper.kt): Registers dynamic shortcuts to `ShortcutManagerCompat` using `androidx.core:core-google-shortcuts`.
- [`android/app/src/main/kotlin/com/abhilash/manikutti/MainActivity.kt`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/kotlin/com/abhilash/manikutti/MainActivity.kt): Initializes dynamic shortcuts on boot and exposes `publishShortcuts` to Flutter.
- [`android/app/src/main/res/layout/quick_log_widget_layout.xml`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/res/layout/quick_log_widget_layout.xml): Interactive keypad widget layout containing digital display, category selector, 4x3 numpad, presets, and save button.
- [`android/app/src/main/res/xml/manikutti_quick_log_widget_info.xml`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/res/xml/manikutti_quick_log_widget_info.xml): AppWidget provider metadata for the Quick Keypad widget.
- [`android/app/src/main/res/layout/widget_layout.xml`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/res/layout/widget_layout.xml): Summary home screen widget layout.

---

## 3. Data Flow & Mechanics

1. **Interactive Home Screen Keypad Input Flow**:
   - **Keypad Taps**: Tapping digits `1-9`, `0`, or presets `+50`, `+100`, `+500` triggers explicit `BroadcastReceiver` intents (`ACTION_KEYPAD_DIGIT`, `ACTION_KEYPAD_PRESET`).
   - **Instant Rendering**: `ManikuttiQuickLogWidgetProvider` updates the `quick_log_display` TextView in `< 10ms` natively without launching any activity or spinning up the Dart engine.
   - **Category Selection**: Tapping category chips updates the active category and highlights the chip (`widget_cat_chip_active_bg`). Tapping `More ▾` cycles through custom categories configured in `CategoryPreferencesScreen`.
   - **1-Tap Save Action (`ACTION_SAVE_EXPENSE`)**:
     1. Validates that `amount > 0`.
     2. Extracts user email and family code from `FlutterSharedPreferences`.
     3. Inserts transaction directly into `manikutti.db` (`transactions` table) with `.toUtc().toIso8601String()` ISO 8601 UTC timestamp and `synced = 0`.
     4. Posts an instant heads-up system notification via `voice_expense_channel_v2`: 🔔 *"Manikutti: Expense Saved - Saved ₹150 for Food (Home Widget)"* with sound and vibration.
     5. Recalculates month's total expense directly from SQLite and updates `total_expense`.
     6. Flashes `"Saved ₹150 for Food ✓"` status on the widget, resets amount to `₹ 0`, and refreshes both the Quick Log and Summary widgets.
     7. When internet is active, Flutter's background worker or sync engine pushes unsynced records to Google Sheets.

2. **Category Customization Flow**:
   - Users navigate to **Settings $\rightarrow$ Expense Categories**.
   - Can add custom categories (e.g. *Gym, Snacks, Books*) or delete custom categories.
   - Any additions or removals automatically trigger `CategoryService.syncToWidget()`, updating `widget_categories` in widget SharedPreferences and refreshing the on-widget category selector.

3. **Floating Home Screen Overlay (Option B)**:
   - Tapping the mic on the **Home Screen Widget** or **Quick Settings Tile** launches `VoiceDialogActivity` directly via explicit `PendingIntent`.
   - `VoiceDialogActivity` runs in an isolated task stack (`android:taskAffinity="com.abhilash.manikutti.voice"`, `launchMode="singleInstance"`) and boots dedicated entrypoint `voiceDialogMain`.
   - The user stays on their home screen wallpaper without opening `MainActivity` or triggering `AppLockScreen`.
   - A floating frosted-glass card pops up with the animated spiral acoustic wave visualizer and live speech transcription.

4. **Google Assistant Hands-Free Execution & Next.js Deep Links**:
   - **Verified HTTPS App Link**: `https://manikutti.vercel.app/voice-dialog` with `android:autoVerify="true"` and `assetlinks.json`.
   - **Dynamic Shortcuts**: `ShortcutHelper` pushes `voice_expense` to `ShortcutManagerCompat`, automatically registering it in **Google Assistant Settings $\rightarrow$ Shortcuts**.
   - **Warm Launch Support**: If the overlay is already alive, `VoiceDialogActivity.onNewIntent()` relays the incoming query via `com.abhilash.manikutti/voice_dialog` without dropping intents.

5. **Storage & Normalization**:
   - **Creation**: Recorded into local SQLite `transactions` table with `.toUtc().toIso8601String()` timestamp and `synced = 0`. Instant system notification fired via `voice_expense_channel_v2`.
   - **Deletion**: Deletes the last N records from SQLite, deletes synced records from Google Sheets via `DELETE /api/sheets/expense?action=delete_last&count=N`, purges any stray ₹0 records, updates the widget, and notifies.
