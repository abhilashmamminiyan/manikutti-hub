# Feature 12: Internationalization (i18n) & Dynamic Theming

## 1. Overview & Purpose
The Manikutti ecosystem is designed to be deeply accessible to Malayalam-speaking families across Kerala and the diaspora, as well as English speakers. It features first-class localization across Flutter arb files and UI screens, paired with a modern Material 3 design system supporting Light and Dark modes.

---

## 2. Source Files & Implementation Matrix

### Mobile Client (`manikutti_mobile`)
- Localization Resource Files:
  - [`lib/l10n/app_en.arb`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/l10n/app_en.arb): English localized strings.
  - [`lib/l10n/app_ml.arb`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/l10n/app_ml.arb): Malayalam localized strings (മലയാളം).
  - [`lib/l10n/app_localizations.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/l10n/app_localizations.dart): Generated Flutter localizations delegate.
  - `l10n.yaml`: Flutter localization generator configuration.
- Theming & Styles:
  - [`lib/theme/app_theme.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/theme/app_theme.dart):
    - Light Theme (`ColorScheme.fromSeed(seedColor: Color(0xFF0F766E))`).
    - Dark Theme (`ColorScheme.fromSeed(..., brightness: Brightness.dark)`).
    - Typography, card elevations, button styling, and input decoration themes.
- [`lib/screens/settings_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/settings_screen.dart):
  - User toggles for language selection (English vs. മലയാളം) and theme mode (System / Light / Dark).

### Web Application (`Manikutti`)
- [`src/app/providers.tsx`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/app/providers.tsx): Material UI v6 `ThemeProvider` and `CssBaseline`.
- [`src/index.css`](file:///d:/MERN/Personal/my-apps/finance-tracker/Manikutti/src/index.css) & `tailwind.config.js`: Custom CSS variables and color palettes.

---

## 3. Data Flow & Mechanics

1. **Language Switching**:
   - User selects language in `SettingsScreen`.
   - Locale code stored in `SharedPreferences` (`language_code`: `'en'` or `'ml'`).
   - `MyApp` in `main.dart` listens to locale changes and re-renders the widget tree with `Locale('ml')`.
   - All UI widgets access translated strings via `AppLocalizations.of(context)!.stringKey`.
2. **Theme Switching**:
   - User toggles Theme Mode (`ThemeMode.system`, `ThemeMode.light`, `ThemeMode.dark`).
   - Stored in `SharedPreferences` (`theme_mode`).
   - Dynamically applied to `MaterialApp(theme: AppTheme.lightTheme, darkTheme: AppTheme.darkTheme)`.

---

## 4. Edge Cases & Malayalam Typography

- **Complex Malayalam Ligatures**: To avoid clipping or improper glyph rendering on older Android versions, font styling uses adequate line heights and system font fallbacks.
- **Number & Currency Formatting**: While labels are in Malayalam, currency values utilize standard Indian numbering formatting (e.g., ₹1,50,000.00) with western numerals for universal readability.
- **Fallback Strings**: If an arb key is missing in `app_ml.arb`, Flutter automatically falls back to the English string in `app_en.arb`.

---

## 5. Future Possible Upgrades

- **Web Localization**: Implement `next-intl` or `react-i18next` on the Web Admin Console for full Malayalam web support.
- **Dynamic AMOLED Pure Black Mode**: Pitch-black theme option optimized for OLED screens to maximize battery savings.
- **Regional Dialect Nuances**: Nuanced Malayalam terms tailored for informal Kerala household budgeting.

---

## 6. AI Modification & Maintenance Instructions

- When adding new UI elements or text:
  1. NEVER hardcode raw text strings directly in Flutter widgets. Always add keys to both `lib/l10n/app_en.arb` AND `lib/l10n/app_ml.arb`.
  2. Run `flutter gen-l10n` or verify that generated localizations compile.
  3. Ensure contrast ratios in `lib/theme/app_theme.dart` meet WCAG AA standards (minimum 4.5:1) for both light and dark modes.
