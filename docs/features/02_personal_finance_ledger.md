# Feature 02: Personal Finance Ledger & Expense Tracking

## 1. Overview & Purpose
The Personal Finance Ledger enables individual users to record, categorize, inspect, and analyze their personal daily income and expenditures. Every user has their own isolated Google Spreadsheet automatically provisioned upon initial login (`Manikutti_Personal_<userEmail>`), coupled with a local offline SQLite database on the mobile app.

---

## 2. Source Files & Implementation Matrix

### Web Application (`Manikutti`)
- [`src/app/personal/page.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/app/personal/page.tsx): Personal dashboard route wrapped in `ProtectedPage`.
- [`src/screens/PersonalDashboard.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/screens/PersonalDashboard.tsx): Full personal finance UI containing:
  - Metric cards: Total Expenses, Income, Net Savings.
  - Category breakdown chart and filter chips.
  - Interactive expense list table with edit/delete actions.
  - Floating Action Buttons (`CalculatorFAB`, `FAB`).
- [`src/components/AddRecordModal.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/components/AddRecordModal.tsx): Dialog for creating or editing expense/income entries.
- [`src/components/CategorySection.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/components/CategorySection.tsx): Category grouping view.
- API Route:
  - `src/app/api/sheets/expense/route.ts`: GET, POST, PUT, DELETE for personal transactions.

- [`lib/screens/dashboard_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/dashboard_screen.dart): Full personal finance mobile dashboard view with full-width responsive layout, streamlined AppBar with bold screen title, voice logging shortcut, activity notification badge, and profile sheet; features personal & family swipeable cards, dual-bank breakdown (SBI & Canara Bank), Monthly Budget & Pace Progress Bar, AI financial insight banner, category spending donut chart, monthly utilities & dues table, and family loans & EMI progress cards.
- [`lib/widgets/dashboard_budget_progress.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/dashboard_budget_progress.dart): Real-time visual progress bar showing monthly spend vs. base salary / budget, daily average burn rate, and remaining days pace indicator.
- [`lib/widgets/expense_pie_chart.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/expense_pie_chart.dart): Smooth animated donut chart built with `CustomPainter`, center total expenditure metric, category legend, and filter toggle (`All` / `Personal` / `Family`).
- [`lib/widgets/monthly_dues_section.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/monthly_dues_section.dart): Recurring monthly utilities & dues table featuring "Add Monthly Dues" dialog, Due Day, Unpaid (orange) / Paid (emerald) pills, amounts, and one-tap pay / delete actions.
- [`lib/widgets/family_loan_emi_card.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/family_loan_emi_card.dart): Family loans and EMI ledger cards displaying installment count progress bars, monthly EMI, principal paid, interest paid, and remaining balance to be paid.
- [`lib/screens/transactions_log_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/transactions_log_screen.dart): Dedicated transactions log screen with bank filters, date filters, amount sorting, and type filters.
- [`lib/screens/bank_statement_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/bank_statement_screen.dart): Bank statement upload screen with target bank account selector (`SBI` / `Canara Bank`), AI extraction, duplicate prevention, and note editing per row (see Feature 13).
- [`lib/screens/add_transaction_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/add_transaction_screen.dart): Form to input amount, category, date, notes, bank account selection (`SBI` or `Canara Bank`), and toggle Personal vs. Family.
- [`lib/models/transaction_model.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/models/transaction_model.dart): Dart representation of transactions including `bankAccount` field (defaults to `'SBI'`).
- [`lib/database/db_helper.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/database/db_helper.dart): SQLite CRUD methods for table `transactions` (Database version 3 with `bankAccount TEXT` column migration).

### Database & Google Sheets
- **Spreadsheet**: `Manikutti_Personal_<userEmail>` (Mapped in Admin Index `User_Sheets!A:B`).
- **Sheet Tab**: `Personal_Expenses`
- **Columns**:
  - `Col A`: Date (`YYYY-MM-DD` or ISO UTC timestamp)
  - `Col B`: Amount (Numeric float)
  - `Col C`: Category (e.g., Food, Travel, Utilities, Shopping, Salary)
  - `Col D`: Note (Description)
  - `Col E`: Status / isPaid (`Paid` / `Pending`)
  - `Col F`: Type (`Expense` / `Income`)
  - `Col G`: Added By (User email)
  - `Col H`: Bank Account (`SBI` / `Canara Bank`, defaults to `'SBI'`)

---

## 3. Data Flow & Mechanics

1. **Adding an Entry (Web)**:
   - User submits `AddRecordModal`.
   - Client sends POST `/api/sheets/expense` with payload.
   - Server resolves user's personal spreadsheet ID via `GoogleSheetsService.findOrCreateSheet('Personal')`.
   - Appends row into `Personal_Expenses!A:G`.
2. **Adding an Entry (Mobile)**:
   - User saves in `AddTransactionScreen`.
   - Writes directly to local SQLite:
     ```dart
     await DbHelper.instance.insertTransaction(
       TransactionModel(
         date: selectedDate.toUtc().toIso8601String(),
         amount: amount,
         category: category,
         note: note,
         isPaid: true,
         type: 'Expense', // or 'Income'
         addedBy: userEmail,
         synced: 0,
       )
     );
     ```
   - Triggers `SyncService.instance.syncData()` in background.
   - When network is available, pushes to `/api/sheets/expense` and updates local `synced = 1`.

---

## 4. Edge Cases & Validation Rules

- **Zero or Negative Amounts**: Rejected at form level and API level. Amounts must be `> 0`.
- **UTC Date Invariance**: Dates must be stored in UTC format. Display layers convert to device timezone.
- **Empty Category**: Defaults to `"Other"` if omitted.
- **Calendar Month Dashboard Reset**: The mobile dashboard metrics (`Income`, `Spent`, `Family Spent`, `Net Available Balance`) dynamically calculate over the current calendar month (`tDate.year == now.year && tDate.month == now.month`). When a new calendar month starts (e.g. October), metrics reset automatically for the new month while historical transactions remain accessible via `TransactionsLogScreen`.
- **Dashboard Quick Log Limit**: Dashboard transactions log is strictly capped to the latest 5 transactions of the current calendar month. Older records are browsable on the dedicated Transactions Log screen.
- **Dynamic Sheet Creation**: If a new user logs in and doesn't have a personal spreadsheet, `GoogleSheetsService` automatically creates the sheet under the Service Account and shares it with the user's email.

---

## 5. Future Possible Upgrades

- **Recurring Auto-Logging**: Ability to mark an expense as "Recurring Daily/Weekly/Monthly" so it logs automatically without manual input.
- **Custom Categories & Color Badges**: Allow users to create custom categories with custom icons and hex colors in `Settings`.
- **Multiple Payment Modes**: Track payment instrument (Cash, UPI, Credit Card, Debit Card).

---

## 6. AI Modification & Maintenance Instructions

- When updating the Personal Ledger:
  1. If you modify columns in `Personal_Expenses`, update both `GoogleSheetsService.ensureSheetsExist` in `Manikutti/src/lib/googleSheets.ts` and `TransactionModel.fromSheetRow` / `toSheetRow`.
  2. Keep SQLite columns in `manikutti_mobile/lib/database/db_helper.dart` in sync; increment database version if altering tables.
  3. Always test calculating net balance: `Sum(Income) - Sum(Expense)`.
