# Feature 12: Internationalization (i18n) & Dynamic Theming

## 1. Overview & Purpose
The Manikutti ecosystem is designed to be deeply accessible to Malayalam-speaking families across Kerala and the diaspora, as well as English speakers. It features first-class localization across Flutter arb files and UI screens, paired with a dual-style Material 3 design system supporting:
1. **Modern Heritage Teal Theme** (Light and Dark modes): Crisp, clean banking layout with glassmorphic accents and ambient elevations.
2. **The Handwritten Pen & Paper Ledger Theme** (Light and Dark modes): A tactile, physical notebook and diary experience featuring warm parchment stationary, fountain pen navy ink typography, leather-bound accents, pastel bookmark thumb-index tabs, and fluid page and tab morph transitions.

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
    - `enum ThemeStyle { modern, paper }`
    - `PaperMorphPageTransitionsBuilder`: Custom `PageTransitionsBuilder` utilizing `FadeTransition` and `ScaleTransition` with `Curves.easeInOutCubicEmphasized` for paper morphing.
    - `lightTheme` & `darkTheme`: Modern Heritage Teal design system.
    - `paperLightTheme`: Warm cream stationery (`#F8F5EE`), fountain pen navy ink (`#0F2038`), leather saddle brown (`#5A3119`), pastel thumb-tab colors (Blue `#BCD7EF`, Peach `#F6CEBF`, Green `#C6E6CD`, Purple `#E2D1E8`), and handwritten typography via `GoogleFonts` (`kalam`, `caveat`, `patrickHand`, `jetbrainsMono`).
    - `paperDarkTheme`: Midnight notebook palette (`#191A1C`) with soft warm ink contrast.
    - Ambient desk elevation shadows (`paperCardShadow`).
- Main & Root Management:
  - [`lib/main.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/main.dart):
    - Stored `theme_style` in `SharedPreferences`.
    - `MyApp.getThemeStyle(context)` & `MyApp.setThemeStyle(context, style)`.
    - `MyApp.restartApp(context)`: Re-instantiates root state and cleans route stack for an instantaneous theme rebuild.
- Screens & Navigation:
  - [`lib/screens/settings_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/settings_screen.dart):
    - Theme Design Style selector (`Modern` vs `Paper Theme`).
    - Restart confirmation dialog prompting user to reload the app when switching styles.
  - [`lib/screens/login_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/login_screen.dart):
    - Adapts brand emblems to leather diary badges (`Icons.menu_book_rounded`), parchment cards, and desk shadows in paper mode.
  - [`lib/widgets/app_drawer.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/widgets/app_drawer.dart):
    - Leather notebook header with gold foil stitch border, parchment background, and notebook badges.
  - [`lib/screens/dashboard_screen.dart`](file:///d:/MERN/Personal/my-apps/finance-tracker/manikutti_mobile/lib/screens/dashboard_screen.dart):
    - Leather and fountain navy cards (`PERSONAL DIARY LEDGER`), paper bank summary, bookmark thumb-index tabs (`All`, `Personal`, `Family`), and an `AnimatedSwitcher` morph transition between transaction tab states.

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
2. **Theme Mode Switching**:
   - User toggles Theme Mode (`ThemeMode.system`, `ThemeMode.light`, `ThemeMode.dark`).
   - Stored in `SharedPreferences` (`theme_mode`).
   - Dynamically applied to `MaterialApp(theme: activeLightTheme, darkTheme: activeDarkTheme)`.
3. **Theme Design Style Switching (Modern vs Paper)**:
   - User selects `Paper Theme` or `Modern` in `SettingsScreen`.
   - If changed, a modal dialog appears: "Restart Required: Switching to the Paper Theme transforms the app into a tactile handwritten diary ledger with paper morph transitions. Would you like to restart now?"
   - On confirmation, the preference is saved to `SharedPreferences` (`theme_style`: `'paper'` or `'modern'`), and `MyApp.restartApp(context)` tears down and rebuilds the root app state.
   - `MaterialApp` injects `paperLightTheme` / `paperDarkTheme` with `PaperMorphPageTransitionsBuilder` on every route transition.

---

## 4. Edge Cases & Malayalam Typography

- **Complex Malayalam Ligatures**: To avoid clipping or improper glyph rendering on older Android versions, font styling uses adequate line heights and system font fallbacks.
- **Handwritten Fonts in Paper Mode**: Kalam and Caveat provide natural curved handwriting strokes for headers and notes, while JetBrains Mono provides clear, legible monospace numbers for ledger bookkeeping figures.
- **Number & Currency Formatting**: While labels are in Malayalam, currency values utilize standard Indian numbering formatting (e.g., ₹1,50,000.00) with western numerals for universal readability.
- **Fallback Strings**: If an arb key is missing in `app_ml.arb`, Flutter automatically falls back to the English string in `app_en.arb`.

---

## 5. Future Possible Upgrades

- **Web Localization**: Implement `next-intl` or `react-i18next` on the Web Admin Console for full Malayalam web support.
- **Web Paper Theme**: Port parchment CSS backgrounds and handwritten web fonts to Next.js / Tailwind.
- **Custom Bookmark Colors**: Let users customize bookmark thumb-index tab pastel hues.

---

## 6. AI Modification & Maintenance Instructions

- When adding new UI elements or text:
  1. NEVER hardcode raw text strings directly in Flutter widgets. Always add keys to both `lib/l10n/app_en.arb` AND `lib/l10n/app_ml.arb`.
  2. Run `flutter gen-l10n` or verify that generated localizations compile.
  3. Ensure contrast ratios meet WCAG AA standards for both Modern and Paper themes (light and dark).
  4. Always test route transitions to ensure `PaperMorphPageTransitionsBuilder` runs smoothly at 60/120fps.
