# Feature 14: Home Screen Widget, Voice Logging & Assistant Shortcuts

## 1. Overview & Purpose
This module provides fast, zero-friction expense logging and financial awareness without requiring the user to open or navigate the full app. It integrates:
1. **Interactive Phone Home Screen Widget**: Displays Month-to-Date total expenses, nearest pending mobile recharge / utility bill alert, and 1-tap quick action buttons (Voice Mic and Manual Add).
2. **AI Voice Expense Logging Engine**: Real-time on-device speech-to-text supporting Malayalam (`ml_IN`), Manglish, and English (`en_IN`), parsed by Google Gemini AI with intelligent offline regex fallback.
3. **Android Quick Settings Tile**: Notification shade tile accessible from any screen or lock screen with Manikutti branding and microphone.
4. **Google Assistant & Siri Shortcuts**: Deep linking via `manikutti://voice-expense` and App Actions (`actions.intent.RECORD_EXPENSE`).

---

## 2. Source Files & Implementation Matrix

### Web Application (`Manikutti`)
- [`src/app/api/ai/voice-expense/route.ts`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/app/api/ai/voice-expense/route.ts): Serverless Gemini AI route with structured JSON extraction and offline/rate-limit fallback parser.

### Mobile Client (`manikutti_mobile`)
- [`lib/services/voice_expense_service.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/services/voice_expense_service.dart): Core voice service handling Gemini API integration, offline regex parser, UTC timestamp normalization, SQLite persistence, and firing immediate confirmation notifications.
- [`lib/services/widget_data_service.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/services/widget_data_service.dart): Aggregates monthly expense total and scans pending/overdue recharges and bills, pushing updates to `HomeWidget`.
- [`lib/widgets/spiral_voice_waves.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/spiral_voice_waves.dart): CustomPainter acoustic wave visualizer featuring the Manikutti logo emblem at the center with 4 rotating holographic spiral arms and expanding ripple rings.
- [`lib/widgets/voice_dialog_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/voice_dialog_screen.dart): Translucent floating dialog overlay rendered directly over the phone's home screen wallpaper or current app without opening the main app.
- [`lib/widgets/voice_logging_sheet.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/voice_logging_sheet.dart): In-app bottom sheet UI with speech recognition, language toggle (Malayalam / English), animated pulsing mic, and transaction card.
- [`lib/main.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/main.dart): Deep link router (`manikutti://voice-dialog` and `manikutti://add-transaction`), `/voice-dialog` transparent route, and `HomeWidget.widgetClicked` stream listener.
- [`lib/screens/dashboard_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/dashboard_screen.dart): Hosts in-app Voice AI button in AppBar and triggers widget updates on data reload.

### Android Native Components
- [`android/app/src/main/kotlin/com/abhilash/manikutti/VoiceDialogActivity.kt`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/kotlin/com/abhilash/manikutti/VoiceDialogActivity.kt): Native translucent Activity with `BackgroundMode.transparent` hosting `VoiceDialogScreen`.
- [`android/app/src/main/kotlin/com/abhilash/manikutti/ManikuttiHomeWidgetProvider.kt`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/kotlin/com/abhilash/manikutti/ManikuttiHomeWidgetProvider.kt): Native `AppWidgetProvider` updating RemoteViews.
- [`android/app/src/main/kotlin/com/abhilash/manikutti/ManikuttiVoiceTileService.kt`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/kotlin/com/abhilash/manikutti/ManikuttiVoiceTileService.kt): Android `TileService` for Notification Shade quick toggle launching `VoiceDialogActivity`.
- [`android/app/src/main/res/layout/widget_layout.xml`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/res/layout/widget_layout.xml): Home screen widget layout.
- [`android/app/src/main/res/xml/shortcuts.xml`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/res/xml/shortcuts.xml): Google Assistant App Actions & app launcher shortcuts routing to `VoiceDialogActivity`.
- [`android/app/src/main/res/xml/manikutti_widget_info.xml`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/res/xml/manikutti_widget_info.xml): AppWidget provider metadata.
- [`android/app/src/main/res/values/styles.xml`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/android/app/src/main/res/values/styles.xml) & `values-night/styles.xml`: Declares `TransparentTheme` (`Theme.Translucent.NoTitleBar`) with dim amount.

---

## 3. Data Flow & Mechanics

1. **Floating Home Screen Overlay (Option B)**:
   - Tapping the mic on the **Home Screen Widget** or **Quick Settings Tile** launches `VoiceDialogActivity`.
   - The user stays on their home screen wallpaper (the main app dashboard does NOT open).
   - A floating frosted-glass card pops up with a pulsing mic and live speech transcription.
2. **Google Assistant Hands-Free Execution**:
   - Spoken phrases like *"Hey Google, 100 roopakku petrol adichu, ith Manikuttiyil save cheyyu"* deliver the captured transcript directly via intent `manikutti://voice-dialog?query=...`.
   - The app processes the query in the background without opening the main UI.
3. **Entity Extraction**:
   - Transcript sent to `/api/ai/voice-expense`.
   - Gemini maps natural speech to `{ amount, category, note, type, bankAccount }`.
   - If offline, `VoiceExpenseService.parseLocally` provides instantaneous rule-based extraction.
4. **Storage & Normalization**:
   - Recorded into local SQLite `transactions` table with `.toUtc().toIso8601String()` timestamp and `synced = 0`.
   - Fires an immediate system notification: 🔔 *"Manikutti: Record Saved - Saved ₹100 for Petrol (Transport)"*.
   - Automatically closes the floating dialog (returning the user to where they were).
   - Triggers `WidgetDataService.updateWidgetData()` to refresh the widget numbers immediately.
   - Fire-and-forget sync to Google Sheets via `SyncService.instance.syncData()`.
