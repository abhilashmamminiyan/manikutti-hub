# Manikutti Hub Documentation

Welcome to the comprehensive documentation directory for **Manikutti Hub**, an ecosystem designed for unified family financial tracking and personal wealth management.

---

## 📚 Table of Contents

1. [System Architecture & Feature Index](FEATURE_MAP.md)
2. [AI System Map & Agent Guidelines](../AI_SYSTEM_MAP.md)
3. [Future Possible Features & Upgrade Roadmap](UPGRADE_ROADMAP.md)
4. [Modular Feature Specifications](features/)
   - [01. Authentication & Security](features/01_authentication_and_security.md)
   - [02. Personal Finance Ledger](features/02_personal_finance_ledger.md)
   - [03. Family Shared Finance](features/03_family_shared_finance.md)
   - [04. Offline-First Sync Engine](features/04_offline_sync_engine.md)
   - [05. Loans & EMI Tracker](features/05_loans_and_emi_tracker.md)
   - [06. Utility Bills & Subscriptions](features/06_utility_bills_and_subscriptions.md)
   - [07. Mobile Recharges Tracker](features/07_mobile_recharges.md)
   - [08. Smart Scan & Receipt OCR](features/08_smart_scan_receipt_ocr.md)
   - [09. AI Financial Advisor](features/09_ai_financial_advisor.md)
   - [10. Notifications & Background Alerts](features/10_notifications_and_alerts.md)
   - [11. Calculator & Financial Tools](features/11_calculator_and_financial_tools.md)
   - [12. Internationalization & Theming](features/12_internationalization_and_theming.md)

---

## 🎯 How to Use This Documentation

- **For AI Coding Agents**:
  You are bound by `.agents/AGENTS.md` to read the corresponding feature specification before implementing modifications and update it when complete. Use [`FEATURE_MAP.md`](FEATURE_MAP.md) to discover which files to modify.

- **For Human Developers**:
  Read each feature document to understand the underlying Google Sheets tables, Next.js serverless handlers, Flutter client-side state, and edge cases. Check [`UPGRADE_ROADMAP.md`](UPGRADE_ROADMAP.md) when planning future sprints.

---

## 📦 Mobile Release Build & APK Size Optimization

- **Android Toolchain**: Uses AGP `9.1.1`, Gradle `9.3.1`, JDK `17`, and Flutter `stable` (`manikutti_mobile/.github/workflows/pipeline.yml`).
- **APK Size Reduction (`manikutti_mobile/android/app/build.gradle.kts` & `pipeline.yml`)**:
  - R8 code shrinking (`isMinifyEnabled = true`) + resource shrinking (`isShrinkResources = true`) with ProGuard rules (`android/app/proguard-rules.pro`).
  - Locale resource trimming via `androidResources { localeFilters.addAll(listOf("en", "ml")) }`.
  - Native library `.so` compression inside distributed APKs (`packaging { jniLibs { useLegacyPackaging = true } }`) plus `META-INF` / debug probe exclusions.
  - Per-ABI ARM builds (`--split-per-abi --target-platform android-arm64,android-arm --obfuscate --split-debug-info`) — Firebase App Distribution deploys `app-arm64-v8a-release.apk`, while GitHub Artifacts retain both `arm64-v8a` and `armeabi-v7a` APKs.
