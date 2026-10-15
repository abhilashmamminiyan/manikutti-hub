# Feature 03: Family Shared Finance & Multi-User Ledger

## 1. Overview & Purpose
Family Shared Finance allows members of a household to pool and track collective expenses (groceries, home repairs, utilities, children's school fees, dining out) in a single shared Family Ledger. It supports administrative oversight, invitation code distribution, member tracking, and individual expenditure attribution while maintaining personal privacy for separate private accounts.

---

## 2. Source Files & Implementation Matrix

### Web Application (`Manikutti`)
- [`src/app/family/page.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/app/family/page.tsx): Family ledger view.
- [`src/screens/FamilyDashboard.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/screens/FamilyDashboard.tsx): Main family tracking console showing monthly pooled totals, member contributions, and recent shared expenses.
- [`src/screens/AdminDashboard.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/screens/AdminDashboard.tsx): Admin console with tabs:
  - `OverviewTab.tsx`: Aggregated ecosystem metrics.
  - `ExpensesTab.tsx`: Detailed filtered family expenses.
  - `LedgerTab.tsx`: Balance sheet.
  - `MembersTab.tsx`: List of registered members, invitation generator, role assignment.
  - `RechargesTab.tsx`: Overview of family mobile plan recharges.
  - `AdminDialogs.tsx`: Modals for adding family members and sending invite emails.
- [`src/screens/FamilySetupScreen.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/screens/FamilySetupScreen.tsx): Initial wizard to name a family and initialize the shared sheet.
- [`src/app/join-family/page.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/app/join-family/page.tsx): Landing page for accepting an invite via 6-digit family code.
- Backend API Routes:
  - `/api/sheets/family/route.ts`: CRUD for family shared transactions.
  - `/api/sheets/admin/route.ts` & `/api/sheets/admin/stats/route.ts`: Admin analytics and member queries.
  - `/api/sheets/groups/route.ts`: Family group info, codes, and registry.
  - `/api/sheets/init/route.ts`: Initializes required tabs on the family spreadsheet.

### Mobile Client (`manikutti_mobile`)
- [`lib/screens/dashboard_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/dashboard_screen.dart): Tab/filter to switch between "Personal" and "Family" view.
- [`lib/screens/add_transaction_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/add_transaction_screen.dart): "Family" toggle button that attaches `familyCode` to the transaction.
- [`lib/services/api_service.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/services/api_service.dart): `getFamilyInfo()`, `getCachedFamilyCode()`, and `joinFamily(code)`.

### Central Database (Google Sheets)
- **Spreadsheet**: `FAMILY_SPREADSHEET_ID`
- **Tabs**:
  - `Family_Expenses`: `[Date, Amount, Category, Note, AddedBy, FamilyCode]`
  - `Family_Members`: `[Family Code, User Email, Role (Admin/Member), Joined Date, Nickname, Base Salary, Current Salary]` *(Backward compatible with legacy 6-column sheets where Col F was Monthly Income)*
  - `Invitations`: `[InviteCode, FamilyName, CreatedBy, ExpiryDate, Status]`

---

## 3. Data Flow & Mechanics

1. **Dynamic Salary & Base Salary Tracking**:
   - Family members have a contractual **Base Salary** (standard baseline) and an editable **Current Salary** (this month's credited salary).
   - Allows users whose monthly salary varies (overtime, bonuses, deductions, unpaid leave) to adjust their income for the current month without losing their base baseline.
   - Users and Admins can update salary via Web Admin Overview (`OverviewTab.tsx`), Web Family Dashboard (`FamilyDashboard.tsx`), or Mobile Dashboard bottom sheet (`dashboard_screen.dart`).
   - Endpoint `/api/sheets/family` (`action: updateMember`) handles atomic column updates (Col F for `baseSalary`, Col G for `currentSalary`). Backward compatibility defaults `currentSalary` to `baseSalary` when Col G is blank.
2. **Automated Monthly Salary Prompt & Income Logging (Day 4 & Day 5)**:
   - On the 4th of every month at 9:00 AM, `NotificationService` (ID `9004`, channel `salary_channel`) triggers an actionable alert: *"Have you got your salary?"*.
   - A prominent **Salary Prompt Banner** appears on the Mobile Dashboard with three one-tap options:
     - **Yes**: Automatically logs the current effective salary as an `Income` transaction (category: `'Salary'`, note: `'Monthly Salary Income'`) in SQLite and Google Sheets, marks the month confirmed in `SharedPreferences`, and cancels further alerts.
     - **Basic**: Logs the contractual baseline (`Base Salary`) as `Income`, marks the month confirmed, and cancels further alerts.
     - **Edit**: Opens the *"Edit Salary Income"* dialog allowing the user to input the exact credited amount, optionally update the standard base salary baseline, and check *"Record as Income in transaction log for this month"*.
   - **Day 5 Follow-Up**: If the user has not confirmed or logged a salary transaction by Day 5, a follow-up notification (ID `9005`) and Day 5 dashboard banner are dispatched.
   - **Auto-Dismissal**: If a salary income transaction for the current calendar month is already detected in the ledger, the prompt banner and notifications are automatically suppressed.
2. **Family Invitation**:
   - Admin generates an invitation in `MembersTab.tsx`.
   - Generates random 6-character alphanumeric code stored in `Invitations` tab.
   - An invitation email with joining link is triggered.
2. **Joining a Family**:
   - New user enters the invite code on Web (`/join-family`) or Mobile.
   - Server checks `Invitations` tab. If valid and not expired:
     - Appends user's email to `Family_Members`.
     - Updates invitation status to `Used` or increments accepted count.
     - Caches `familyCode` in user's profile and mobile `SharedPreferences`.
3. **Recording Shared Expenses**:
   - When recorded, the expense includes `addedBy: userEmail` and `familyCode`.
   - Appended to `Family_Expenses!A:F`.
   - Accessible by all members verified against `Family_Members`.

---

## 4. Edge Cases & Authorization Rules

- **Membership Verification**: Before serving data from `FAMILY_SPREADSHEET_ID`, `checkMembership(spreadsheetId, email)` verifies that the requester's email is present in `Family_Members!B:B`.
- **Role Restrictions**: Only users with role `Admin` in `Family_Members` can remove members or generate invitations.
- **Family Code Fallback**: If a mobile user records a family expense while offline before their family code is cached, the mobile app queues it and resolves `familyCode` upon network reconnection before pushing.

---

## 5. Future Possible Upgrades

- **Multiple Family Groups**: Support users belonging to multiple groups (e.g. "Primary Family", "Siblings Trip", "Apartment Flatmates").
- **Spending Approvals**: Require admin approval for transactions exceeding a set threshold (e.g., ₹10,000).
- **Individual Contribution Settlement**: Track who spent what and calculate monthly member refunds.

---

## 6. AI Modification & Maintenance Instructions

- When altering Family Finance:
  1. Never bypass `checkMembership()` in `Manikutti/src/lib/googleSheets.ts`.
  2. Always ensure the `addedBy` column stores the authenticated user's email, not client-supplied arbitrary text.
  3. Ensure `Family_Expenses` columns in `ensureSheetsExist` match the read ranges in `/api/sheets/family/route.ts`.
