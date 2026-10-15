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

### Mobile Client (`manikutti_mobile`)
- [`lib/screens/dashboard_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/dashboard_screen.dart): Hosts the integrated Family Loans & EMI Ledger directly on the main dashboard screen.
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
     - Standalone recurring EMI commitments registered in `Monthly_Expenses` (e.g. store finances, unlinked vehicle loans), automatically deduplicated against active loans by name to prevent double-counting.
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
