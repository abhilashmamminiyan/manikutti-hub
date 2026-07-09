# Manikutti Hub - v2 Features & Verification

This document outlines the comprehensive list of features implemented in the v2 release of the Manikutti Hub ecosystem (across both Web Admin and Mobile Client), along with the required test cases and verification steps.

## 🌟 New Features (v2)

### 1. Web Dashboard (Next.js) - Home Loan Module
*   **Google Sheets Integration**: Added `HomeLoan_Ledger` schema integration in the API route (`/api/sheets/home-loan`).
*   **Data Entry UI**: Created a new page (`/emi/home-loan`) to manually record 1-year historical passbook data (Date, Total Payment, Principal, Interest, Balance).
*   **Data Visualization**: Implemented a stacked bar chart using `recharts` to visually distinguish principal vs. interest payments over time.
*   **Amortization Engine**: Added a future EMI amortization projector based on the outstanding balance and interest rate.

### 2. Mobile App (Flutter) - Core & Navigation
*   **Side Drawer Navigation**: Replaced the legacy navigation system with a unified Side Drawer (`AppDrawer`) for easier access to the growing list of features.
*   **Localization (English/Malayalam)**: Integrated `flutter_localizations`. All screens now support real-time language switching between English and Malayalam, controlled via a new Settings Screen. 

### 3. Mobile App (Flutter) - Smart Scan & Screenshots
*   **AI OCR Extraction**: Integrated Google ML Kit's On-Device Text Recognition. Users can pick screenshots of receipts (e.g., Google Pay), and the app automatically extracts the Raw Text and parses the monetary Amount using custom RegEx.
*   **Screenshots Hub**: Added a dedicated `ScreenshotsScreen` stub for browsing locally saved transaction receipts.

### 4. Mobile App (Flutter) - Bills & Reminders
*   **Bills Dashboard**: Added a new `BillsDashboard` stub to track recurring family utilities (Recharge, Electricity, Water).
*   **Notifications & Reminders Engine**: Added the foundational packages (`flutter_local_notifications` and `workmanager`) to schedule recurring background reminders specifically on the 3rd and 5th of the month.

---

## 🧪 Test Cases & Verification Steps

### Web Admin (Next.js)

**Test Case 1: Manual Home Loan Data Entry**
*   **Step**: Navigate to `/emi/home-loan`. Fill in a sample passbook entry and submit.
*   **Verification**: Ensure the API route returns a 200 OK and the data visually appends to the UI Data Table. 

**Test Case 2: Chart Rendering**
*   **Step**: Load the `/emi/home-loan` page with at least 3 historical records.
*   **Verification**: Verify the `recharts` stacked bar chart renders correctly, showing distinct colors for the Principal and Interest components.

### Mobile App (Flutter)

**Test Case 3: Language Switching**
*   **Step**: Open the Drawer -> Settings. Change the language to 'Malayalam'.
*   **Verification**: The UI should immediately re-render. Verify the Drawer now reads "ഡാഷ്ബോർഡ്" (Dashboard) and "ഭവന വായ്പ" (Home Loan).
*   **Step**: Restart the application.
*   **Verification**: The app should read the localized state from `SharedPreferences` and launch directly in Malayalam.

**Test Case 4: Smart Scan (OCR) Accuracy**
*   **Step**: Open the Drawer -> Smart Scan. Tap 'Scan Receipt' and select a valid Google Pay screenshot from the gallery.
*   **Verification**: Wait for ML Kit to process. Ensure the 'Extracted Amount' correctly identifies the INR amount (e.g., `₹500.00` should extract `500.00`).

**Test Case 5: Drawer Navigation Integrity**
*   **Step**: Tap through every item in the Side Drawer.
*   **Verification**: Ensure each tap successfully uses `Navigator.pushReplacement` without pushing multiple screens onto the stack (memory leak check).

---

## 🔐 Google Drive Configurations Needed
For the background sync service to upload screenshots automatically:
1.  **Google Cloud Console**: Enable the `Google Drive API` on the existing GCP project.
2.  **Service Account**: Generate a new JSON key for the Service Account (or use the existing one).
3.  **Drive Folder**: Create a dedicated folder named `Manikutti_Receipts` in your Google Drive. Share this folder with the Service Account email address, giving it **Editor** permissions.
4.  **App Configuration**: Provide the Folder ID to the Flutter app's `SyncService` so it knows where to direct the uploads.
