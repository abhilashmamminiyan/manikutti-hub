# Feature 16: Family Goals & Purchase Wishlist (Lakshyam / ലക്ഷ്യം)

## 1. Overview & Purpose
**Lakshyam (ലക്ഷ്യം)** provides a shared, collaborative space for household members to define, track, and fulfill collective financial goals. Stored within the shared **Family Google Spreadsheet** (`FAMILY_SPREADSHEET_ID`), all registered family members can view progress, track pooled savings, celebrate milestone completions, and receive culturally rich, AI-generated motivation in Malayalam powered by **Google Gemini 1.5 Flash**.

---

## 2. Source Files & Implementation Matrix

### Web Application (`Manikutti`)
- [`src/screens/AdminDashboard.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/screens/AdminDashboard.tsx):
  - Sidebar navigation item: **"Lakshyam / ലക്ഷ്യം (Goals)"** added to both mobile drawer and desktop drawer.
  - Active tab routing for `'goals'`.
- [`src/hooks/useAdminDashboard.ts`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/hooks/useAdminDashboard.ts):
  - Integrated `'goals'` into the `activeTab` type union.
- [`src/components/admin/GoalsTab.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/components/admin/GoalsTab.tsx):
  - **Empty Screen View**:
    - Central Target hero illustration.
    - Inspiring family motivation quote in Malayalam & English:  
      *“ഒരുമിച്ചുള്ള ചെറിയ സമ്പാദ്യങ്ങൾ കുടുംബത്തിന്റെ വലിയ സ്വപ്നങ്ങൾ സാക്ഷാത്കരിക്കും. നിങ്ങളുടെ ആദ്യ കുടുംബ ലക്ഷ്യം ഇന്ന് തന്നെ നിശ്ചയിക്കൂ!”*  
      *(Together, small savings fulfill big family dreams. Set your first family goal today!)*
    - **"Add My First Goal / ആദ്യ ലക്ഷ്യം ചേർക്കുക"** CTA button.
  - **Active Goals Screen View**:
    - **Top Gemini AI Motivation Banner**: Dynamic encouragement in authentic Malayalam generated based on the family's active goals and completion percentages, with refresh capability and quota caching.
    - **Portfolio Summary Metrics (4-Card Row)**: Total Family Target, Pooled Savings, Overall Progress (%), and Active Goals count.
    - **Filter Chips**: `All Goals`, `💰 Savings (സമ്പാദ്യം)`, `🛍️ Want to Buy (വാങ്ങാൻ)`, and `✅ Completed`.
    - **Goal Cards Grid**: Shows title, type badge, target vs. saved breakdown, linear progress bar, remaining to save, target date countdown, `Added By` attribution, quick **"+ Add Savings"** deposit action, and edit/archive controls.
    - **Dialogs**:
      - `AddGoalDialog`: Modal to create or edit goals.
      - `DepositDialog`: Quick modal to add funds to a specific goal.

### Backend APIs (`Manikutti`)
- [`src/app/api/sheets/goals/route.ts`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/app/api/sheets/goals/route.ts):
  - **`GET`**: Reads `Family_Goals!A:I` on the shared family spreadsheet. Computes progress percentages, remaining amounts, and summary metrics (`topActiveGoal`, `overallProgressPercentage`).
  - **`POST`**: Appends new family goal with validation (`title`, `targetAmount`, `goalType` in `Saving` / `Purchase`, `targetDate`, `note`, `addedBy`).
  - **`PATCH`**: Supports two operational modes:
    - Deposit mode: atomically increments `currentAmount` and sets `status = 'Completed'` when target is met.
    - Direct edit mode: updates title, target, type, date, note, and status.
  - **`DELETE`**: Archives goal row without breaking index integrity.
- [`src/app/api/ai/goal-motivation/route.ts`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/app/api/ai/goal-motivation/route.ts):
  - Next.js serverless route invoking Google Gemini 1.5 Flash (`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent`).
  - System instruction as *"Manikutti Family Goal Coach"* (മണിക്കുട്ടി കുടുംബ ലക്ഷ്യം കോച്ച്).
  - 30-Minute in-memory cache per family to protect free-tier Gemini API quotas.
  - Built-in rule-based Malayalam fallback engine if Gemini is rate-limited or offline.

### Central Database (Google Sheets)
- **Spreadsheet**: `FAMILY_SPREADSHEET_ID`
- **Tab Name**: `Family_Goals` (configured in [`src/lib/googleSheets.ts`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/lib/googleSheets.ts))
- **Columns**:
  - `Col A`: `Title` (Goal name)
  - `Col B`: `Target Amount` (Numeric float)
  - `Col C`: `Current Amount` (Pooled saved float)
  - `Col D`: `Status` (`Active` / `Completed` / `Paused` / `Archived`)
  - `Col E`: `Goal Type` (`Saving` / `Purchase`)
  - `Col F`: `Target Date` (`YYYY-MM-DD` or empty)
  - `Col G`: `Added By` (User email)
  - `Col H`: `Note` (Description or notes)
  - `Col I`: `Created At` (ISO UTC timestamp)

---

## 3. Data Flow & Mechanics

1. **Viewing Goals & Motivation**:
   - Admin or family member opens the **Lakshyam / ലക്ഷ്യം (Goals)** tab in `AdminDashboard`.
   - The UI fetches `/api/sheets/goals?sheetType=family`.
   - If `goals.length === 0`: Displays the empty screen with the inspiring quote and "Add My First Goal" CTA.
   - If `goals.length > 0`: Simultaneously fetches `/api/ai/goal-motivation?sheetType=family` and displays the Gemini AI motivation banner at the top of the dashboard.
2. **Adding a Contribution (+ Add Savings)**:
   - User clicks **"+ Add Savings"** on any active goal card.
   - User inputs contribution amount (₹).
   - Client sends `PATCH /api/sheets/goals` with `{ id, addAmount, sheetType: 'family' }`.
   - Backend atomically increments `currentAmount`. If `newCurrent >= targetAmount`, status transitions to `'Completed'`.
   - Both goal cards and AI motivation refresh dynamically.

---

## 4. Mobile Client Contract (Home Screen Widget Readiness)

The endpoint `/api/sheets/goals?sheetType=family` provides pre-aggregated fields ready for direct consumption by the mobile Flutter Home Screen widget:
```json
{
  "summary": {
    "totalGoals": 2,
    "activeGoals": 2,
    "totalTargetAmount": 85000,
    "totalSavedAmount": 55000,
    "overallProgressPercentage": 64.7,
    "topActiveGoal": {
      "id": 1,
      "title": "Living Room Smart TV",
      "targetAmount": 45000,
      "currentAmount": 32000,
      "goalType": "Purchase",
      "progressPercentage": 71,
      "remainingAmount": 13000
    }
  }
}
```
The future mobile widget can directly bind to `topActiveGoal` and `overallProgressPercentage` with zero client-side calculation overhead.

---

## 5. Edge Cases & Validation Rules

- **Zero or Negative Target**: Form and API strictly require `targetAmount > 0`.
- **Target Overflow**: If saved amount reaches or exceeds target, status automatically updates to `Completed`.
- **Gemini 429 Quota Graceful Fallback**: The client never crashes; the server falls back to the intelligent rule-based Malayalam engine.
