# Feature 11: In-App Calculator & Financial Calculation Tools

## 1. Overview & Purpose
The In-App Calculator allows users to perform instant mathematical calculations (summing multiple store receipts, calculating tax splits, discount percentages) directly inside the finance tracker without switching apps. Calculations are preserved in an interactive history log and can be copied directly into expense fields.

---

## 2. Source Files & Implementation Matrix

### Web Application (`Manikutti`)
- [`src/components/Calculator.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/components/Calculator.tsx): Main calculator component with numeric keypad, operators (`+`, `-`, `*`, `/`, `%`), clear, backspace, and memory/history tape.
- [`src/components/CalculatorModal.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/components/CalculatorModal.tsx): Floating modal wrapper accessible from anywhere on the web dashboard.
- [`src/components/CalculatorFAB.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/components/CalculatorFAB.tsx): Draggable floating action button positioned at the bottom right.
- [`src/components/FAB.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/components/FAB.tsx): Quick access speed dial menu.
- Backend API Route:
  - `/api/sheets/calculator/route.ts`: Persists calculation history into Google Sheets.

### Google Sheets Storage
- `Calculator_History` tab (in Personal & Family Sheets):
  - Columns: `[Timestamp, Expression, Result, UserEmail, Note]`

---

## 3. Data Flow & Mechanics

1. **Floating Action Trigger**:
   - User clicks the calculator FAB on any screen.
   - `CalculatorModal` opens without navigating away from the current page.
2. **Expression Evaluation**:
   - Sanitized mathematical evaluation (tokenized to prevent `eval()` code injection).
   - Results display in real time as operands are entered.
3. **Insert Into Expense**:
   - When entering a new expense in `AddRecordModal`, tapping the result automatically pastes the calculated total into the amount input field.
4. **History Preservation**:
   - Calculations are stored in local component state and optionally synchronized to `Calculator_History` in Google Sheets for record keeping.

---

## 4. Edge Cases & Safety

- **Code Injection Prevention**: Never use raw JavaScript `eval()`. Use tokenized parsers or abstract syntax tree (AST) expression evaluators.
- **Division by Zero**: Returns `"Cannot divide by 0"` error message gracefully without crashing state.
- **Precision Rounding**: All currency calculations round to 2 decimal places ($₹0.00$).

---

## 5. Future Possible Upgrades

- **SIP & Compound Interest Calculator**: Built-in tabs for Systematic Investment Plan (SIP) returns and Fixed Deposit maturity value.
- **Inflation Impact Visualizer**: Calculate what an expense today will cost in 5, 10, or 20 years given an inflation rate (e.g. 6%).
- **Mobile Floating Calculator Overlay**: Android overlay bubble that floats over UPI apps (Google Pay / PhonePe) to calculate split totals before making payments.

---

## 6. AI Modification & Maintenance Instructions

- When updating Calculator tools:
  1. Ensure keyboard shortcuts (`Enter` for `=`, `Escape` to close, `Backspace` to delete) remain functional on desktop web.
  2. Prevent floating modal from occluding primary submit buttons on mobile viewport sizes.
