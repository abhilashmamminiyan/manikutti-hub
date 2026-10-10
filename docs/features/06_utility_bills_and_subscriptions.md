# Feature 06: Utility Bills & Recurring Subscriptions

## 1. Overview & Purpose
The Utility Bills and Subscriptions module tracks recurring domestic expenditures such as Electricity (KSEB), Water, Piped Gas, Internet/Wi-Fi, and OTT subscriptions (Netflix, Spotify, Amazon Prime). It ensures households avoid late fees by tracking due dates and logging paid bills directly into the expense ledger.

---

## 2. Source Files & Implementation Matrix

### Web Application (`Manikutti`)
- [`src/components/PersonalUtilities.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/components/PersonalUtilities.tsx): Reusable utilities dashboard widget showing pending bills, monthly averages, and mark-as-paid action.
- [`src/screens/PersonalDashboard.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/screens/PersonalDashboard.tsx): Hosts personal utilities section.
- Backend API Routes:
  - `/api/sheets/utilities/route.ts`: CRUD for utility definitions and payment status.
  - `/api/sheets/monthly/route.ts`: Monthly recurring bills aggregation.

### Mobile Client (`manikutti_mobile`)
- [`lib/screens/bills_dashboard.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/bills_dashboard.dart): Bills management dashboard displaying upcoming, paid, and overdue bills.
- [`lib/screens/add_utility_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/add_utility_screen.dart): Form to register a new recurring utility bill.
- [`lib/models/utility_model.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/models/utility_model.dart): Data model:
  - `id`, `name`, `amount`, `dueDate`, `category` (Electricity, Water, Wi-Fi, OTT, Gas), `frequency` (Monthly, Bi-Monthly, Annual), `isPaid`.

### Google Sheets Storage
- **Personal Sheet**: `Personal_Utilities` (`[UtilityName, Category, AverageAmount, DueDayOfMonth, Frequency, LastPaidDate, AutoLogExpense]`)
- **Family Sheet**: `Monthly_Expenses` (`[BillName, ExpectedAmount, ActualPaid, DueDate, PaidBy, Status]`)

---

## 3. Data Flow & Mechanics

1. **Bill Registration**:
   - User adds a bill specifying name (e.g. "Home Fibernet"), amount (e.g. ₹999), and due day (e.g. 15th of each month).
   - Stored in `Personal_Utilities` or `Monthly_Expenses`.
2. **Bill Payment & Expense Logging**:
   - When the user taps "Mark as Paid", the status transitions to `Paid` with timestamp `LastPaidDate`.
   - If `AutoLogExpense` is true, the system automatically posts a corresponding entry to `Personal_Expenses` or `Family_Expenses` under the "Utilities" category.
3. **Monthly Reset**:
   - At the beginning of a new calendar month, recurring commitments in `Monthly_Expenses` reset their status to `Unpaid` based on calendar comparison of `LastPaidDate` with the current month and year (`isPaidThisMonth`).
   - Both the Next.js API endpoints (`/api/sheets/monthly`, `/api/sheets/admin/stats`) and Flutter mobile app (`DashboardScreen`) dynamically enforce this reset, ensuring paid statuses from previous months (e.g. July) do not persist into new months (e.g. October).

---

## 4. Edge Cases & Validation Rules

- **Bi-Monthly Utilities**: Electricity in Kerala (KSEB) is often billed bi-monthly. The frequency field (`Bi-Monthly`) handles alternating billing cycles.
- **Variable vs. Fixed Bills**: Utilities support fixed amounts (e.g., Netflix subscription) and variable estimates (e.g., Electricity meter readings).
- **Overdue Detection**: Any bill with `dueDay < today` and `isPaid == false` within the active cycle displays a prominent red "Overdue" badge.

---

## 5. Future Possible Upgrades

- **Bharat Bill Payment System (BBPS) Integration**: Fetch live electricity or water bill amounts using consumer numbers.
- **Calendar Event Export**: Add utility due dates to Google Calendar / Apple Calendar.
- **Bill PDF Storage**: Attach scanned utility receipts to Google Drive.

---

## 6. AI Modification & Maintenance Instructions

- When modifying Utility logic:
  1. When a bill is marked as paid, ensure the generated expense transaction adheres to UTC date normalization rules.
  2. Preserve the link between `Personal_Utilities` and `Personal_Expenses` so duplicates are not created if the user marks as paid multiple times.
