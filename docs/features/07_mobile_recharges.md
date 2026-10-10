# Feature 07: Mobile Recharges & Plan Validity Tracker

## 1. Overview & Purpose
In Indian households, family members frequently manage multiple prepaid mobile connections (Jio, Airtel, Vi, BSNL) across phones and home routers. The Mobile Recharges tracker tracks phone numbers, service operators, recharged amounts, validity expiry dates, and proactively alerts users before prepaid plans lapse.

---

## 2. Source Files & Implementation Matrix

### Web Application (`Manikutti`)
- [`src/components/admin/RechargesTab.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/components/admin/RechargesTab.tsx): Admin console tab showing all family phone connections, operators, active plans, days remaining, and expiry status.
- [`src/screens/AdminDashboard.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/screens/AdminDashboard.tsx): Hosts Recharges Tab.
- Backend API Route:
  - `/api/sheets/mobile-recharges/route.ts`: CRUD for mobile recharge records.

### Mobile Client (`manikutti_mobile`)
- [`lib/screens/mobile_recharges_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/mobile_recharges_screen.dart): List of tracked phone numbers with operator logos, remaining days badge, and quick recharge actions.
- [`lib/screens/add_mobile_recharge_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/add_mobile_recharge_screen.dart): Form to add/edit connection details (Name, Number, Operator, Plan Cost, Validity Till, Reminder Days).
- [`lib/models/mobile_recharge_model.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/models/mobile_recharge_model.dart): Data model:
  - `name`, `phoneNumber`, `operator` (Jio, Airtel, Vi, BSNL), `planLastRecharged`, `planDescription`, `validityTill`, `lastRechargedDate`, `reminderDaysBefore`, `notifyExpiry`, `logExpense`.
- [`lib/database/db_helper.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/database/db_helper.dart): Local SQLite table `mobile_recharges`.

### Google Sheets Storage
- **Sheet**: `Mobile_Recharges` (in Personal Sheet)
- **Columns**:
  - `Col A`: Name / Label (e.g., "Dad's Phone", "Home SIM Router")
  - `Col B`: Phone Number (10 digits)
  - `Col C`: Operator (Jio / Airtel / Vi / BSNL)
  - `Col D`: Plan Amount (₹)
  - `Col E`: Plan Description (e.g., "1.5GB/day 84 days")
  - `Col F`: Validity Till Date (`YYYY-MM-DD`)
  - `Col G`: Reminder Days Before (default: 2)

---

## 3. Data Flow & Mechanics

1. **Recharge Entry**:
   - User inputs connection details. When recharging an existing SIM, selecting the new plan recalculates `validityTill` from the current expiry date or recharge date.
   - Saves to local SQLite `mobile_recharges` and syncs to Google Sheets.
2. **Expiry Computation**:
   - $\text{Days Remaining} = \text{validityTill} - \text{Current Date}$.
   - If $\text{Days Remaining} \le \text{reminderDaysBefore}$, triggers notification via `NotificationService`.
   - Badges: Green (> 7 days), Amber (1 to 7 days), Red (Expired / Today).
3. **Auto Expense Logging**:
   - If `logExpense` is toggled on, the plan amount is automatically written to `Personal_Expenses` or `Family_Expenses` under the "Mobile & Internet" category.

---

## 4. Edge Cases & Validation Rules

- **Phone Number Format**: Validates standard 10-digit Indian mobile numbers (`^[6-9]\d{9}$`).
- **Consecutive Recharges (Queueing)**: If recharged before the previous pack expired (e.g. Jio queued plans), the new validity date starts from the previous plan's end date rather than today.
- **Negative Days Remaining**: Handled gracefully with an "Expired X days ago" indicator.

---

## 5. Future Possible Upgrades

- **Operator SMS Ingestion**: Auto-detect recharge confirmation SMS messages from telcos (e.g., "Recharge of Rs 299 successful on 9847xxxxxx").
- **Plan Recommendations**: Integrate browseable plan catalog for Jio/Airtel based on circle/region (e.g., Kerala Circle).

---

## 6. AI Modification & Maintenance Instructions

- When modifying Mobile Recharges:
  1. Ensure both the SQLite table (`db_helper.dart`) and Google Sheets tab (`googleSheets.ts`) schemas stay synchronized.
  2. Maintain operator styling consistency (Jio: Blue, Airtel: Red, Vi: Yellow, BSNL: Orange).
