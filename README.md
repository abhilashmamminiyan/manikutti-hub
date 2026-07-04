# Manikutti Hub (Finance Ecosystem)

A unified family financial tracking ecosystem consisting of a **Next.js Web Admin Console** and an **Offline-First Flutter Mobile Client**, both storing and reading data from a centralized **Google Sheets** database via a serverless Google Service Account authentication flow.

---

## 🏛️ Ecosystem Architecture

The ecosystem consists of three main components:

1. **Centralized Database (Google Sheets)**:
   - **Admin Index**: Keeps track of registered users and maps their emails directly to their unique Personal Spreadsheet IDs.
   - **Family Ledger**: Manages family transactions, member registries, active EMIs, and monthly utility dues.
   - **Personal Ledgers**: Individual sheets dynamically allocated to each user for personal income and expenses.

2. **Admin Web Console (`Manikutti` Submodule)**:
   - Built using **Next.js** and **Material UI (MUI) v6**.
   - Accessible only by authorized admin emails using secure, stateless **Email OTP Verification**.
   - Displays real-time charts (spending breakdown, cash flow comparison), ledger tables, and handles family invitation triggers.

3. **Mobile Client (`manikutti_mobile` Submodule)**:
   - Built using **Flutter** and **SQLite**.
   - Serves as the daily tracker for family members to record expenses locally.
   - Automatically synchronizes data with Google Sheets (via Next.js API endpoints) once an active internet connection is detected, using UTC timestamps to normalize timezone offsets.

---

## 📂 Repository Contents

This is a parent workspace linking the two components as submodules:

*   **[Manikutti](https://github.com/abhilashmamminiyan/Manikutti)** — Next.js Web Dashboard & API Routes.
*   **[manikutti_mobile](https://github.com/abhilashmamminiyan/manikutti_mobile)** — Flutter Offline-First Mobile Application.

---

## 🚀 Cloning the Workspace

To check out the entire workspace along with both submodules, clone with the `--recurse-submodules` flag:

```bash
git clone --recurse-submodules https://github.com/abhilashmamminiyan/manikutti-hub.git
```

If you already cloned the repository without the submodules, initialize and fetch them using:

```bash
git submodule update --init --recursive
```

---

## 💻 Local Development Setup

### 1. Web Dashboard & API
Ensure your `.env` variables are configured in the `Manikutti` directory, then start the Next.js server:
```bash
cd Manikutti
npm install
npm run dev
```
Open `http://localhost:3000` to view the dashboard console.

### 2. Flutter Mobile App
Resolve packages and build on a connected phone or emulator:
```bash
cd manikutti_mobile
flutter pub get
flutter run
```

---

## 🤖 Automated Submodule Sync Pipeline
This project is configured with a **GitHub Actions** integration in both submodules. Whenever new code is committed to the `main` branch of either `Manikutti` or `manikutti_mobile`, the parent repository automatically updates its submodule pointers. You do not need to manually commit pointer updates!
