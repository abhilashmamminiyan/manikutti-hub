# Master Feature & File Implementation Map (AI Understandable Index)

> **Purpose for AI Agents & Developers**:  
> This file is the primary machine- and human-readable index mapping every functional capability of the **Manikutti Finance Ecosystem** to its underlying source files across both the **Next.js Web Admin Console (`Manikutti`)** and the **Flutter Mobile Client (`manikutti_mobile`)**, backend API routes, database schemas, and Google Sheets tabs.
>
> **Mandatory AI Rule**:  
> Before implementing changes or additions to any feature, consult the corresponding feature specification in `docs/features/`. When adding new files or changing architectural responsibilities, update this map immediately.

---

## 🗺️ System Architecture Overview

```
                               ┌──────────────────────────────────────────────┐
                               │       Google Sheets Database (Cloud)         │
                               │  - Admin Index: ADMIN_SPREADSHEET_ID         │
                               │  - Family Sheet: FAMILY_SPREADSHEET_ID       │
                               │  - Personal Sheets: Dynamic per user         │
                               └──────────────────────▲───────────────────────┘
                                                      │
                                                      │ Google Sheets API v4
                                                      │ Service Account JWT
                                                      ▼
                      ┌────────────────────────────────────────────────────────┐
                      │              Next.js Web App & API Gateway             │
                      │                   (Folder: /Manikutti)                 │
                      │  - NextAuth Stateless Session & Email OTP Verification │
                      │  - Material UI (MUI v6) Web Console & Dashboards       │
                      │  - Serverless API Routes (/api/sheets/*, /api/ai/*)    │
                      └──────────────▲──────────────────────────▲──────────────┘
                                     │                          │
                         HTTP REST   │ (Online)      HTTP REST  │ (Web Browser)
                         API Sync    │                          │
                                     ▼                          ▼
               ┌─────────────────────────────────┐   ┌─────────────────────────┐
               │    Flutter Mobile Client (App)  │   │  Web Desktop / Mobile   │
               │   (Folder: /manikutti_mobile)   │   │  Browser Users          │
               │  - SQLite (Local Offline DB)    │   └─────────────────────────┘
               │  - Workmanager Background Sync  │
               │  - UTC Timestamp Normalization  │
               │  - Google ML Kit OCR Scan       │
               │  - Multilingual (EN / Malayalam)│
               └─────────────────────────────────┘
```

---

## 📊 Comprehensive Feature Matrix

| # | Feature Name | Primary Doc | Next.js Web Files (`Manikutti`) | Flutter Mobile Files (`manikutti_mobile`) | Backend APIs & Services | Database / Sheets Tab |
|---|--------------|-------------|---------------------------------|-------------------------------------------|-------------------------|------------------------|
| **01** | **Authentication & Security** | [`01_authentication_and_security.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/01_authentication_and_security.md) | `src/lib/auth.ts`<br>`src/lib/authHelper.ts`<br>`src/lib/email.ts`<br>`src/app/login/page.tsx`<br>`src/screens/LoginScreen.tsx`<br>`src/components/ProtectedPage.tsx` | `lib/screens/login_screen.dart`<br>`lib/screens/app_lock_screen.dart`<br>`lib/screens/setup_app_lock_screen.dart`<br>`lib/services/api_service.dart` | `/api/auth/[...nextauth]`<br>`/api/auth/otp`<br>`/api/auth/invite-info` | `User_Sheets` (Admin Sheet), `SharedPreferences`, `FlutterSecureStorage` |
| **02** | **Personal Finance Ledger** | [`02_personal_finance_ledger.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/02_personal_finance_ledger.md) | `src/app/personal/page.tsx`<br>`src/screens/PersonalDashboard.tsx`<br>`src/components/AddRecordModal.tsx`<br>`src/components/CategorySection.tsx` | `lib/screens/dashboard_screen.dart`<br>`lib/screens/transactions_log_screen.dart`<br>`lib/screens/add_transaction_screen.dart`<br>`lib/models/transaction_model.dart`<br>`lib/database/db_helper.dart` | `/api/sheets/expense`<br>`GoogleSheetsService.findOrCreateSheet('Personal')` | `Personal_Expenses` (Personal Sheet), `transactions` table (SQLite) |
| **03** | **Family Finance & Shared Ledger** | [`03_family_shared_finance.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/03_family_shared_finance.md) | `src/app/family/page.tsx`<br>`src/screens/FamilyDashboard.tsx`<br>`src/screens/AdminDashboard.tsx`<br>`src/screens/FamilySetupScreen.tsx`<br>`src/screens/FamilyTrackingSetup.tsx`<br>`src/app/join-family/page.tsx`<br>`src/components/admin/*` | `lib/screens/dashboard_screen.dart`<br>`lib/services/api_service.dart` | `/api/sheets/family`<br>`/api/sheets/admin`<br>`/api/sheets/groups`<br>`/api/sheets/init` | `Family_Expenses`, `Family_Members`, `Invitations` (Family Sheet) |
| **04** | **Offline-First Sync Engine** | [`04_offline_sync_engine.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/04_offline_sync_engine.md) | N/A (Serverless REST endpoints receive sync payloads) | `lib/services/sync_service.dart`<br>`lib/database/db_helper.dart`<br>`lib/main.dart` (Workmanager task)<br>`lib/models/transaction_model.dart` | `/api/sheets/expense`<br>`/api/sheets/family` | SQLite `transactions` (`synced` flag 0/1), Google Sheets Append & Deduplication |
| **05** | **Loans & EMI Tracking** | [`05_loans_and_emi_tracker.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/05_loans_and_emi_tracker.md) | `src/app/emi/page.tsx`<br>`src/app/emi/home-loan/page.tsx`<br>`src/screens/EMIScreen.tsx` | `lib/screens/loans_emi_screen.dart`<br>`lib/screens/home_loan_screen.dart`<br>`lib/models/emi_model.dart`<br>`lib/models/loan_model.dart`<br>`lib/models/home_loan_model.dart` | `/api/sheets/emi`<br>`/api/sheets/loans`<br>`/api/sheets/home-loan` | `Loans`, `Loan_Expenses`, `Loan_Repayments`, `HomeLoan_Ledger` (Family Sheet) |
| **06** | **Utility Bills & Monthly Subscriptions** | [`06_utility_bills_and_subscriptions.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/06_utility_bills_and_subscriptions.md) | `src/components/PersonalUtilities.tsx`<br>`src/screens/PersonalDashboard.tsx` | `lib/screens/bills_dashboard.dart`<br>`lib/screens/add_utility_screen.dart`<br>`lib/models/utility_model.dart` | `/api/sheets/utilities`<br>`/api/sheets/monthly` | `Personal_Utilities` (Personal Sheet), `Monthly_Expenses` (Family Sheet) |
| **07** | **Mobile Recharges Tracker** | [`07_mobile_recharges.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/07_mobile_recharges.md) | `src/components/admin/RechargesTab.tsx`<br>`src/screens/AdminDashboard.tsx` | `lib/screens/mobile_recharges_screen.dart`<br>`lib/screens/add_mobile_recharge_screen.dart`<br>`lib/models/mobile_recharge_model.dart`<br>`lib/database/db_helper.dart` | `/api/sheets/mobile-recharges` | `Mobile_Recharges` (Personal Sheet), SQLite `mobile_recharges` table |
| **08** | **Smart Scan & Receipts / OCR** | [`08_smart_scan_receipt_ocr.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/08_smart_scan_receipt_ocr.md) | N/A (Client-side native ML processing) | `lib/screens/smart_scan_screen.dart`<br>`lib/screens/screenshots_screen.dart` | Google ML Kit (`google_mlkit_text_recognition`), `image_picker` | Local device storage & camera/gallery |
| **09** | **AI Financial Advisor (Gemini Multilingual)** | [`09_ai_financial_advisor.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/09_ai_financial_advisor.md) | `src/app/api/ai/expense-advisor/route.ts` | `lib/widgets/ai_advisor_card.dart`<br>`lib/services/api_service.dart`<br>`lib/screens/dashboard_screen.dart` | `/api/ai/expense-advisor`<br>Google Gemini 2.5 Flash API (`GEMINI_API_KEY`) | Dynamic aggregation of `Personal_Expenses` or `Family_Expenses` |
| **10** | **Push Notifications & Background Alerts** | [`10_notifications_and_alerts.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/10_notifications_and_alerts.md) | N/A | `lib/services/notification_service.dart`<br>`lib/main.dart` (Workmanager)<br>`lib/services/api_service.dart` | `/api/sheets/notifications` | `Notifications` tab in Family Sheet, `flutter_local_notifications` |
| **11** | **In-App Calculator & Split Tools** | [`11_calculator_and_financial_tools.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/11_calculator_and_financial_tools.md) | `src/components/Calculator.tsx`<br>`src/components/CalculatorFAB.tsx`<br>`src/components/CalculatorModal.tsx`<br>`src/components/FAB.tsx` | Built-in numeric controllers in expense/recharge screens | `/api/sheets/calculator` | `Calculator_History` (Personal and Family sheets) |
| **12** | **Localization & Theming** | [`12_internationalization_and_theming.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/12_internationalization_and_theming.md) | Material UI Theme Provider (`src/app/providers.tsx`), Tailwind CSS | `lib/l10n/app_en.arb`<br>`lib/l10n/app_ml.arb`<br>`lib/l10n/app_localizations.dart`<br>`lib/theme/app_theme.dart`<br>`lib/screens/settings_screen.dart` | N/A (Client-side localization) | `SharedPreferences` (`language_code`, `theme_mode`) |
| **13** | **Bank Statement Upload & Duplicate Filtering** | [`13_bank_statement_upload.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/13_bank_statement_upload.md) | `src/lib/googleSheets.ts`<br>`src/app/api/sheets/expense/route.ts`<br>`src/app/api/statement/parse/route.ts` | `lib/screens/bank_statement_screen.dart`<br>`lib/screens/transactions_log_screen.dart`<br>`lib/widgets/app_drawer.dart`<br>`lib/services/api_service.dart`<br>`lib/database/db_helper.dart` | `/api/statement/parse`<br>`/api/sheets/expense` (batch POST) | `Personal_Expenses` (Personal Sheet), SQLite `transactions` table |
| **14** | **Home Screen Widget, Voice Logging & Shortcuts** | [`14_voice_logging_and_home_widget.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/14_voice_logging_and_home_widget.md) | `src/app/api/ai/voice-expense/route.ts` | `lib/services/voice_expense_service.dart`<br>`lib/services/widget_data_service.dart`<br>`lib/widgets/voice_logging_sheet.dart`<br>`lib/main.dart`<br>`android/app/src/main/kotlin/...` | `/api/ai/voice-expense` | SQLite `transactions`, `mobile_recharges`, HomeWidget RemoteViews |

---

## 🎯 Quick Navigation for AI Tasks

When asked to work on a task, match the prompt against this table and immediately consult the target documentation before touching code:

- **Login / Auth / OTP / Session / App Lock** ➡️ [`docs/features/01_authentication_and_security.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/01_authentication_and_security.md)
- **Personal Expenses / Transactions / Categories / Budgeting** ➡️ [`docs/features/02_personal_finance_ledger.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/02_personal_finance_ledger.md)
- **Family Sharing / Multi-User / Family Code / Members / Admin Dashboard** ➡️ [`docs/features/03_family_shared_finance.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/03_family_shared_finance.md)
- **Offline Mode / SQLite / Background Sync / Duplicates / Connectivity** ➡️ [`docs/features/04_offline_sync_engine.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/04_offline_sync_engine.md)
- **Loans / EMI / Home Loan / Amortization / Prepayments** ➡️ [`docs/features/05_loans_and_emi_tracker.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/05_loans_and_emi_tracker.md)
- **Electricity / Wi-Fi / Water Bills / Subscriptions** ➡️ [`docs/features/06_utility_bills_and_subscriptions.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/06_utility_bills_and_subscriptions.md)
- **Mobile Recharges / Operator / Expiry Date / Alerts** ➡️ [`docs/features/07_mobile_recharges.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/07_mobile_recharges.md)
- **Bill Scan / Google Pay Screenshot / ML OCR** ➡️ [`docs/features/08_smart_scan_receipt_ocr.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/08_smart_scan_receipt_ocr.md)
- **AI Advisor / Gemini / Malayalam Advice / Financial Suggestions** ➡️ [`docs/features/09_ai_financial_advisor.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/09_ai_financial_advisor.md)
- **Notifications / Workmanager / Periodic Alerts** ➡️ [`docs/features/10_notifications_and_alerts.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/10_notifications_and_alerts.md)
- **Calculator / History / Quick Math** ➡️ [`docs/features/11_calculator_and_financial_tools.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/11_calculator_and_financial_tools.md)
- **Malayalam Translation / English / Dark Mode / Colors** ➡️ [`docs/features/12_internationalization_and_theming.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/12_internationalization_and_theming.md)
- **Bank Statement Upload / PDF & CSV Ingestion / Duplicate Filter** ➡️ [`docs/features/13_bank_statement_upload.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/13_bank_statement_upload.md)
- **Voice Logging / Home Widget / Quick Settings / Assistant Shortcuts** ➡️ [`docs/features/14_voice_logging_and_home_widget.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/14_voice_logging_and_home_widget.md)
- **Future Feature Proposals & Architectural Roadmap** ➡️ [`docs/UPGRADE_ROADMAP.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/UPGRADE_ROADMAP.md)
