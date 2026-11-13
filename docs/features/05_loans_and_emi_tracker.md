# Feature 05: Loans & Equated Monthly Installment (EMI) Tracker

## 1. Overview & Purpose
The Loans and EMI Tracker gives families complete visibility into outstanding liabilities, bank loans (e.g., Personal Loans, Vehicle Loans, and Home Loans), monthly installment due dates, interest vs. principal distribution, and prepayment histories. Dedicated workflows exist for general loans and long-term Home Loans.

---

## 2. Source Files & Implementation Matrix

### Web Application (`Manikutti`)
- [`src/app/emi/page.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/app/emi/page.tsx) / [`src/screens/EMIScreen.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/screens/EMIScreen.tsx): General EMI overview, active loan cards, monthly outflow calculator.
- [`src/app/emi/home-loan/page.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/app/emi/home-loan/page.tsx): Specialized Home Loan dashboard with amortization schedules and prepayment impact visualizer.
- Backend API Routes:
  - `/api/sheets/emi/route.ts`: General EMI registry.
  - `/api/sheets/loans/route.ts`: Loans overview and status tracking.
  - `/api/sheets/home-loan/route.ts`: Home Loan amortizations, disbursements, and prepayment ledger.
  - `/api/sheets/monthly/route.ts`: Tracks `Total Months` (`K`) and `Paid Months` (`L`) tenure on loan/EMI rows in `Monthly_Expenses!A:L` and supports atomic 1-tap `Paid` + `Family_Expenses` logging (`logToFamily`).
  - `/api/sheets/transfers/route.ts`: Tracks inter-member monthly pool transfers (e.g., `Ajesh -> Nisha ₹3,750`, `Abhilash -> Nisha ₹12,500`).

### Mobile Client (`manikutti_mobile`)
- [`lib/screens/dashboard_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/dashboard_screen.dart): Hosts the integrated Family Loans & EMI Ledger directly on the main dashboard screen and schedules local "Have you paid?" reminders for unpaid assigned loans.
- [`lib/screens/simple_family_home_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/simple_family_home_screen.dart): Clean Basic-member home screen listing assigned monthly EMIs with 1-tap Paid button, member attribution, and tenure progress.
- [`lib/widgets/family_pool_transfers_card.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/family_pool_transfers_card.dart): ₹12,500 monthly equal-share breakdown and inter-member transfer history (`Family_Transfers`).
- [`lib/widgets/family_loan_emi_card.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/family_loan_emi_card.dart): Modern loan and EMI tracker widget displaying installment count progress bars, monthly payment amounts, principal paid, interest paid, and balance to be paid for both Home Loan and active consumer EMIs.
- [`lib/screens/loans_emi_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/loans_emi_screen.dart): Dedicated loans dashboard displaying active liabilities and monthly obligations.
- [`lib/screens/home_loan_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/home_loan_screen.dart): Dedicated Home Loan tracking with principal paid vs. outstanding metrics.
- Models:
  - [`lib/models/emi_model.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/models/emi_model.dart): Loan title, bank name, EMI amount, due day, total tenure, remaining installments.
  - [`lib/models/loan_model.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/models/loan_model.dart): Broad liability model.
  - [`lib/models/home_loan_model.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/models/home_loan_model.dart): Specialized Home Loan schedule model.

### Google Sheets Storage (`FAMILY_SPREADSHEET_ID`)
- `Loans`: `[LoanID, LoanName, Lender, PrincipalAmount, InterestRate, TenureMonths, StartDate, Status]`
- `Loan_Repayments`: `[RepaymentID, LoanID, PaymentDate, Amount, PrincipalComponent, InterestComponent, Note]`
- `HomeLoan_Ledger`: `[TransactionDate, DisbursedAmount, PrepaymentAmount, EMIPaid, OutstandingBalance, Note]`

---

## 3. Financial Calculations & Data Formulas

1. **Standard EMI Formula**:
   $$E = P \cdot r \cdot \frac{(1 + r)^n}{(1 + r)^n - 1}$$
   Where:
   - $P$ = Principal loan amount
   - $r$ = Monthly interest rate ($\text{Annual Rate} / 12 / 100$)
   - $n$ = Tenure in months
2. **Prepayment Impact**:
   - Each lump-sum prepayment directly reduces principal outstanding $P_{\text{new}} = P_{\text{current}} - \text{Prepayment}$.
   - The user can choose to either reduce monthly EMI or reduce remaining tenure $n$.
3. **Constant Family EMI Dues Aggregation**:
   - The system computes the family's fixed, non-negotiable monthly EMI obligations by combining:
     - All active loans from `Loans` (`status: Active`) summing `monthlyEMI`.
     - Standalone recurring EMI commitments registered in `Monthly_Expenses` whose category is `EMI` or whose title includes `emi` or `loan`, automatically deduplicated against active loans by name to prevent double-counting.
   - **Independent Fault-Tolerant Dashboard Fetching & Home Loan Ledger Safety**:
     - `/api/sheets/monthly/route.ts` reads `Monthly_Expenses!A:J`.
     - `/api/sheets/home-loan/route.ts` normalizes `familyCode` matching (trimmed, case-insensitive) and sanitizes formatted currency/comma strings (`parseLoanAmount`). It detects whether Row 1 is a header (`Date`) before slicing so data rows are never silently skipped if a header is missing, assigns exact 0-based sheet row indices (`id`), guards header rows from mutation, and maps `DELETE` (`id + 1`, with optional `date` match check) to `GoogleSheetsService.deleteRow()`'s 1-based A1 row contract.
     - `HomeLoanCalculator` (`manikutti_mobile/lib/utils/home_loan_calculator.dart`) & Web `home-loan/page.tsx` dynamically recalculate Interest, Principal, and Remaining Balance whenever the selected repayment Date, Loan Interest Rate (%), or Total EMI changes using daily reducing-balance interest against the prior ledger entry.
     - `GoogleSheetsService.ensureSheetsExist()` (`Manikutti/src/lib/googleSheets.ts`) caches verified spreadsheets for 5 minutes and deduplicates concurrent in-flight verification requests so simultaneous mobile/dashboard calls do not spam `spreadsheets.get` or hit Google Sheets `429` read-quota errors.
     - Mobile `DashboardScreen._fetchFamilyDuesAndNotifications()` fetches `fetchMonthlyExpenses`, `fetchNotifications`, `fetchLoansData`, `fetchEmiBills`, and `fetchHomeLoanHistory` in independent `try/catch` blocks so a partial failure never prevents Home Loan or Loans/EMI cards from rendering.
   - **Role Feature Gating**: `FamilyLoanEmiSection` hides the Home Loan card or EMI cards individually based on `FeatureKeys.homeLoan` and `FeatureKeys.loansEmiLedger`.
   - **Dashboard Integration**:
     - **Web Admin Dashboard** (`OverviewTab.tsx`): Prominently surfaced as a dedicated KPI card `Constant EMI Dues` with a `Fixed` badge.
     - **Web Family Dashboard** (`FamilyDashboard.tsx`): Displayed as a primary overview metric alongside monthly spend.
     - **Mobile Dashboard** (`dashboard_screen.dart`): Displayed directly in the `FAMILY LEDGER POOL` hero card as `Constant EMI` alongside pool outflow. Individual commitment items are badged with `EMI • FIXED` and dedicated wallet icons.

---

## 4. Edge Cases & Validation Rules

- **Zero Interest Rate**: If interest rate is $0\%$, formula falls back to $E = P / n$ to prevent division by zero.
- **Tenure Expiry**: When remaining installments reach 0, status transitions to `Completed`.
- **Prepayment Exceeding Principal**: Cannot enter a prepayment larger than current outstanding principal.

---

## 5. Future Possible Upgrades

- **Floating Interest Rate Revision**: Historical rate log allowing users to update their interest rate when the RBI repo rate changes without corrupting past repayments.
- **Auto-Payment Reminders**: Push notification on mobile 3 days prior to EMI debit day.
- **Tax Benefit Calculator**: Separate tracking of Principal (Section 80C up to ₹1.5L) and Interest (Section 24b up to ₹2L) deductions for Indian income tax filing.

---

## 6. AI Modification & Maintenance Instructions

- When modifying the Loans or EMI modules:
  1. Double check all interest rate formulas for annual vs. monthly rate conversion.
  2. Verify that prepayments decrement the balance properly in both the Home Loan ledger and summary views.
  3. Ensure numeric fields parse correctly (strip commas `₹` and whitespace before parsing floats).


---

## 6. Admin Loan/Home Loan Configuration & Mandatory Before-10th Tracking

- **Extended Schemas (`Manikutti/src/lib/googleSheets.ts`)**:
  - **`Loans!A:N`**: Added columns `Interest Rate`, `Start Date`, `Balance Remaining`, `Tenure Months`, `Paid Months`, `Payer Name` (default `Ajesh`), `Share Recipient` (default `Nisha`). Backward-compatible fallback for older `A:G` rows.
  - **`HomeLoan_Config!A:K`**: Stores Family-level Home Loan baseline (`Family Code`, `Principal Amount`, `Interest Rate`, `Start Date`, `Balance Remaining`, `Monthly EMI`, `Due Day`, `Payer Name`, `Share Recipient`, `Updated At`, `Updated By`).
  - **`EMI_Monthly_Tracking!A:K`**: Monthly settlement ledger keyed by `Month Key` (`YYYY-MM`) + `Loan Key`, tracking `Paid To Payer`, `Shared With Recipient`, `Auto SMS Detected`, `Confirmed By`, `Updated At`, `Notes`.
- **API Endpoints**:
  - `GET /api/sheets/loans?familyCode=...&monthKey=YYYY-MM`: Returns `loans` (`A:N`), `homeLoanConfig`, and `monthlyTracking` for the given month.
  - `POST /api/sheets/loans` (`action: 'confirmMonthlyTracking'`): Upserts `EMI_Monthly_Tracking`; when paid is confirmed, automatically appends an `EMI` entry into `Family_Expenses`, marks matching `Monthly_Expenses` bills paid, appends to `Notifications` sheet, and dispatches FCM push notifications to Mom (`Nisha`) and Abhilash with format: `"[Payer] paid loan \"[Loan-Name]\" amount \"₹[Amount]\" at \"[Date]\""`.
  - `POST /api/sheets/home-loan` (`action: 'saveConfig'`): Admin-only save of `HomeLoan_Config` plus optional `HomeLoan_Ledger` baseline snapshot.
  - `GET /api/sheets/admin/stats`: Includes `homeLoanConfig`, `emiMonthlyTracking`, and extended `Loans` fields.
- **Web Admin & Mobile UI**:
  - Web `LedgerTab`, `AdminDialogs`, `useAdminDashboard`, and `AdminDashboard` allow configuring Home Loan & individual Loans with interest rate, start date (e.g., from January), tenure/paid months, remaining balance (including `Auto-Calc` helper and 1-click presets for active Bajaj Finance repayment schedules), payer, and share recipient.
  - Repayment Schedule Engines ([`repayment_schedules_data.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/data/repayment_schedules_data.dart) & [`repaymentSchedulesData.ts`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/data/repaymentSchedulesData.ts)): Ingested complete amortization schedules directly from authentic documents:
    1. **Bajaj Personal Loan (`P595PRB70267501`)**: ₹2,15,378 @ 30.00% p.a., 48 months tenure, monthly EMI ₹7,755, Customer: Nisha P, Payer: Ajesh.
    2. **Bajaj Lifestyle 0% (`P595PSC90568277`)**: ₹28,369 @ 0.00% p.a., 8 months tenure, monthly EMI ₹3,546, Customer: Nisha P, Payer: Ajesh.
    3. **Bajaj Lifestyle 23.58% (`P595PSC89289290`)**: ₹78,000 @ 23.58% p.a., 18 months tenure, monthly EMI ₹4,834 (initial ₹4,411), Customer: Nisha P, Payer: Ajesh.
    - Provides real-time calculation of Remaining Principal, Paid Principal, Remaining Interest, Paid Interest, and Interest Rates.
  - **Demo Role Experience ([`demo_role_home_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/demo_role_home_screen.dart))**: Dedicated screen for Mother and Brother with role `Demo`. Contains only:
    1. **SMS Expense Tracking**: Real-time bank SMS monitoring and pending queue actions.
    2. **Zero-Confirmation EMI Auto-Log**: If Ajesh receives an EMI debit SMS, the app automatically confirms the payment without prompting, updates the ledger, and alerts Mom & Abhilash.
    3. **Fallback 1-Tap Manual Payment**: If the bank SMS fails or is delayed, allows Mother or Brother to mark the assigned loan as paid with 1 tap.
    4. **Repayment Schedule Tracking**: Interactive breakdown and month-by-month installment sheet viewer.
