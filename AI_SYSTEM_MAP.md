# AI Agent System Guide & Architecture Index

> **Notice for AI Assistants & LLMs**:  
> You are working in the **Manikutti Finance Tracker Hub** repository. This document is your mandatory entry point. Read this document and the referenced feature files in `docs/features/` **before modifying or creating code**.

---

## 🏗️ Repository Architecture

This repository is a parent workspace linking two standalone projects:
1. **`Manikutti/` (Submodule)**:
   - Next.js 14/15 App Router web application.
   - Material UI (MUI v6) + Tailwind CSS frontend.
   - Serverless API routes under `src/app/api/`.
   - Google Sheets Service (`src/lib/googleSheets.ts`) acting as the central cloud database using Service Account JWT authentication.
   - NextAuth.js stateless session & custom Email OTP handler.
2. **`manikutti_mobile/` (Submodule)**:
   - Flutter mobile application (Dart).
   - Local offline database using SQLite (`sqflite`).
   - Bidirectional sync engine (`SyncService`) with UTC timestamp deduplication.
   - Background alerts and notification polling via `workmanager` and `flutter_local_notifications`.
   - On-device OCR using Google ML Kit (`google_mlkit_text_recognition`).
   - Multilingual support (English & Malayalam arb files).

---

## 📜 Mandatory AI Workflow Rules

Whenever you receive a prompt to update, debug, or add a feature in this repository:

1. **Rule 1: Consult the Feature Document First**  
   Match the request to one of the feature documents in [`docs/features/`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/features/) (or check [`docs/FEATURE_MAP.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/FEATURE_MAP.md)).  
   Read the specific feature document before editing any files. Understand its:
   - Data flow & schemas
   - Cross-project dependencies (Web vs. Mobile vs. Google Sheets)
   - Edge cases and validation logic
   - Future upgrade roadmap

2. **Rule 2: Respect Project Boundaries & Submodules**  
   - Web changes belong strictly in `Manikutti/`.
   - Mobile changes belong strictly in `manikutti_mobile/`.
   - Shared documentation and cross-cutting rules belong in `docs/` and `.agents/`.
   - Submodules have their own git repositories and CI/CD pipelines. Never commit submodule root pointers unless you are deliberately updating tracked commits.

3. **Rule 3: Adhere to Critical Architectural Patterns**  
   - **UTC Date Normalization**: In `manikutti_mobile`, all transaction and expense timestamps MUST be converted to ISO 8601 UTC (`.toUtc().toIso8601String()`) before syncing with Google Sheets, preventing timezone mismatch duplicates between local device time (e.g. IST UTC+5:30) and Vercel cloud servers.
   - **Offline-First Resilience**: Mobile writes must always write to local SQLite first with `synced = 0`. Then trigger `SyncService.instance.syncData()` non-blockingly.
   - **Stateless Google Sheets Access**: Google Sheets access happens via `GoogleSheetsService` in `Manikutti/src/lib/googleSheets.ts` using JWT credentials stored in environment variables (`GOOGLE_SERVICE_ACCOUNT_EMAIL`, `GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY`, `ADMIN_SPREADSHEET_ID`, `FAMILY_SPREADSHEET_ID`).

4. **Rule 4: Update Documentation After Implementation**  
   After you finish modifying any code or adding a feature:
   - Update the respective document in `docs/features/<feature-name>.md`.
   - If new files, endpoints, or DB columns/sheets were introduced, update [`docs/FEATURE_MAP.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/FEATURE_MAP.md).
   - If a proposed future feature was completed, move it from the roadmap to the active feature documentation in [`docs/UPGRADE_ROADMAP.md`](file:///d:/MERN/Personal/my-apps/finance-tracker/docs/UPGRADE_ROADMAP.md).

---

## 🗂️ Documentation Directory Index

```
docs/
├── README.md                              # Main human-friendly documentation overview
├── FEATURE_MAP.md                         # Matrix of all features, files, APIs, and DB tables
├── UPGRADE_ROADMAP.md                     # Planned future features & upgrade guides
└── features/                              # Detailed modular feature specifications
    ├── 01_authentication_and_security.md     # Web NextAuth, Email OTP, Mobile App Lock
    ├── 02_personal_finance_ledger.md         # Personal expenses, categories, stats, budgets
    ├── 03_family_shared_finance.md           # Multi-user family groups, invite codes, ledger
    ├── 04_offline_sync_engine.md             # SQLite, Workmanager, UTC deduplication
    ├── 05_loans_and_emi_tracker.md           # Loans, EMI calculator, Home Loan ledger
    ├── 06_utility_bills_and_subscriptions.md # Monthly recurring dues, utilities
    ├── 07_mobile_recharges.md                # Recharge tracking, validity alerts
    ├── 08_smart_scan_receipt_ocr.md          # Google ML Kit text recognition, screenshot parsing
    ├── 09_ai_financial_advisor.md            # Gemini 2.5 Flash Malayalam financial insights
    ├── 10_notifications_and_alerts.md        # Local notifications, background polling
    ├── 11_calculator_and_financial_tools.md  # In-app calculator, history, expense math
    └── 12_internationalization_and_theming.md# Flutter l10n (EN/ML), Material 3 theming
```

---

## 🤖 Terminal Execution & Git Rules Reminder

- On Windows, always invoke commands via `cmd /c` or `powershell -Command`.
- When creating features, follow the project Git rule in `.agents/AGENTS.md`:
  - Always work on a separate branch (e.g. `feature/<name>` or `fix/<name>`).
  - Always pull latest changes before pushing.
