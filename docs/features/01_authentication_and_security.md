# Feature 01: Authentication, Session Management & App Security

## 1. Overview & Purpose
The Manikutti ecosystem provides secure, stateless authentication designed for personal and family use without requiring users to remember passwords. It employs a 6-digit Email One-Time Password (OTP) verification flow, generating signed stateless JWT session tokens. On the mobile client, it adds an optional local PIN / biometric App Lock layer to guard access on shared devices.

---

## 2. Source Files & Implementation Matrix

### Web Application (`Manikutti`)
- [`src/lib/auth.ts`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/lib/auth.ts): NextAuth.js configuration options, credentials provider, JWT callbacks, session mapping.
- [`src/lib/authHelper.ts`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/lib/authHelper.ts): Extracts user email from NextAuth session or `Authorization: Bearer <token>` header for serverless routes.
- [`src/lib/email.ts`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/lib/email.ts): Email transport sending OTP codes using Resend / Nodemailer.
- [`src/app/login/page.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/app/login/page.tsx) / [`src/screens/LoginScreen.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/screens/LoginScreen.tsx): Web login UI with email input, OTP countdown timer, and verify trigger.
- [`src/components/ProtectedPage.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/components/ProtectedPage.tsx): React client wrapper redirecting unauthenticated sessions to `/login`.
- Serverless API Routes:
  - `/api/auth/[...nextauth]/route.ts`: NextAuth API handler.
  - `/api/auth/otp/route.ts`: Generates 6-digit cryptographic OTP, sets 10-minute expiry, sends via email.

### Mobile Client (`manikutti_mobile`)
- [`lib/screens/login_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/login_screen.dart): Flutter OTP login screen, countdown timer, resend button.
- [`lib/screens/app_lock_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/app_lock_screen.dart): 4-digit PIN verification overlay before dashboard access.
- [`lib/screens/setup_app_lock_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/setup_app_lock_screen.dart): PIN setup, confirmation, and biometric toggle.
- [`lib/services/api_service.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/services/api_service.dart): Stores JWT in `FlutterSecureStorage` and `SharedPreferences` (`session_token`), attaches `Authorization: Bearer <token>` to requests.

---

## 3. Data Flow & Security Mechanics

1. **OTP Request**:
   - Client sends `{ email: "user@example.com" }` to `/api/auth/otp`.
   - Server validates email format, creates a 6-digit random code, and persists code with timestamp in memory/cache/Sheets.
   - Code is emailed to the user.
2. **OTP Verification & JWT Issuance**:
   - User inputs 6 digits. Client posts `{ email, otp }`.
   - Server verifies code validity. If correct, NextAuth issues a signed JWT containing `{ email, sub, iat, exp }`.
   - Mobile app saves token in `FlutterSecureStorage`.
3. **API Authorization**:
   - For every protected API endpoint (`/api/sheets/*`, `/api/ai/*`), `getAuthUserEmail(request)` extracts either the NextAuth session or parses the bearer token.
   - If unauthorized, returns HTTP 401 `{ error: 'Unauthorized' }`.
4. **App Lock Layer (Mobile)**:
   - On app startup (`main.dart`), check `prefs.getBool('app_lock_enabled')`.
   - If enabled, route directly to `AppLockScreen` before unlocking `DashboardScreen`.

---

## 4. Edge Cases & Validation Rules

- **Case-Insensitive Email**: All emails MUST be normalized with `.trim().toLowerCase()` to prevent duplicate accounts or authentication mismatches.
- **OTP Expiration**: OTP codes expire strictly after 10 minutes.
- **Offline Mobile Login**: If the mobile device is offline, existing saved session in `FlutterSecureStorage` permits dashboard entry. Re-authentication is only required upon explicit logout or token expiry.
- **Biometric Availability**: `local_auth` handles fallback to device PIN if biometric hardware is not enrolled.

---

## 5. Future Possible Upgrades

- **WebAuthn / Passkeys**: FIDO2 biometric login in the web browser (Face ID / Touch ID / Windows Hello).
- **Google One-Tap OAuth**: Direct "Sign in with Google" without typing an email or waiting for OTP.
- **Session Revocation & Device Management**: Track active devices in `User_Sheets` and provide "Log out from all devices".

---

## 6. AI Modification & Maintenance Instructions

- When modifying the login flow:
  1. Never expose raw JWT secrets or service account keys in client bundles.
  2. Maintain fallback between `FlutterSecureStorage` and `SharedPreferences` in `api_service.dart` for platforms where keychain access might fail.
  3. Ensure all new API routes call `await getAuthUserEmail(request)` before processing data.
