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

- [`lib/screens/dashboard_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/dashboard_screen.dart): Full personal finance mobile dashboard view with full-width responsive layout, streamlined AppBar with bold screen title, voice logging shortcut, activity notification badge, and profile sheet; features personal & family swipeable cards, Available Balance (`_sbiBalance + _canaraBalance`), dual-bank breakdown (SBI & Canara Bank), verified balance badges, tap-to-verify/adjust bottom sheet modal (`_showAdjustBankBalanceBottomSheet`), Monthly Budget & Pace Progress Bar, AI financial insight banner, category spending donut chart, monthly utilities & dues table, and family loans & EMI progress cards.
- [`lib/widgets/dashboard_budget_progress.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/dashboard_budget_progress.dart): Real-time visual progress bar showing monthly spend vs. base salary / budget, daily average burn rate, and remaining days pace indicator.
- [`lib/widgets/expense_pie_chart.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/expense_pie_chart.dart): Smooth animated donut chart built with `CustomPainter`, center total expenditure metric, category legend, and filter toggle (`All` / `Personal` / `Family`).
- [`lib/widgets/monthly_dues_section.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/monthly_dues_section.dart): Recurring monthly utilities & dues table featuring "Add Monthly Dues" dialog, Due Day, Unpaid (orange) / Paid (emerald) pills, amounts, and one-tap pay / delete actions.
- [`lib/widgets/family_loan_emi_card.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/family_loan_emi_card.dart): Family loans and EMI ledger cards displaying installment count progress bars, monthly EMI, principal paid, interest paid, and remaining balance to be paid.
- [`lib/screens/transactions_log_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/transactions_log_screen.dart): Dedicated transactions log screen with:
  - Bank Account filters (`All Banks`, `SBI`, `Canara Bank`) and bank badges on transaction cards.
  - Date filtering (`This Month`, `Last Month`, `All Time`, `Custom Range` with DateRangePicker).
  - Amount ordering (Amount High to Low, Low to High) and date sorting (Newest first, Oldest first).
  - Type filters (`All`, `Personal`, `Family`, `Transfer`).
  - Search by note, category, or type.
  - Distinct `Transfer` badge with neutral `⇄ ₹Amount` styling.
  - Filtered inflow/outflow summary cards and pull-to-refresh synchronization.
- [`lib/screens/bank_statement_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/bank_statement_screen.dart): Bank statement upload screen with target bank account selector (`SBI` / `Canara Bank`), AI & regex extraction with statement running balance capture, automatic closing balance detection, auto-detection of self-transfers between user accounts, duplicate prevention, note editing per row, and verified baseline balance persistence upon import (see Feature 13).
- [`lib/screens/add_transaction_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/add_transaction_screen.dart): Form to input amount, category, date, notes, bank account selection, toggle Personal vs. Family, and dedicated `Transfer` mode that selects `From Account` and `To Account` and creates balanced contra entries.
- [`lib/services/bank_balance_service.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/services/bank_balance_service.dart): Core balance manager providing verified baseline balances (from uploaded statements or user verification) and calculating live bank balances via $\text{Verified Baseline} + \sum_{t > \text{Baseline Date}} \text{Credits} - \sum_{t > \text{Baseline Date}} \text{Debits}$.
- [`lib/models/transaction_model.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/models/transaction_model.dart): Dart representation of transactions including `bankAccount` field (defaults to `'SBI'`) and `isTransfer` getter.
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
- **Calendar Month Dashboard Metrics vs Live Bank Balance**: Personal monthly metrics (`Income`, `Spent`, `Family Spent`) dynamically calculate over the current calendar month (`tDate.year == now.year && tDate.month == now.month`) and reset on the 1st of each month. In contrast, **Available Balance** represents true cumulative liquid funds (`_sbiBalance + _canaraBalance`), computed continuously by `BankBalanceService` using verified statement baselines and post-statement transaction deltas.
- **Dashboard Quick Log Limit**: Dashboard transactions log is strictly capped to the latest 5 transactions of the current calendar month. Older records are browsable on the dedicated Transactions Log screen.
- **Automated Pull Request Scripting**: The ecosystem provides `scripts/automate_pr.ps1` and `scripts/automate_pr.sh` for automated test execution, sync with `origin/main`, CI pipeline observation, and squash-merging.
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
