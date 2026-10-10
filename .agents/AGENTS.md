# AI Agent Rules for Manikutti Hub

These rules apply to all automated agent tasks within the Manikutti Hub repository:

## 1. Feature Documentation Lifecycle (Mandatory)
Before and after modifying any code in this repository:
1. **Read the Respected Feature File First**:
   - Before modifying, adding, or refactoring code for any feature, you MUST first read its corresponding documentation file in `docs/features/<feature-name>.md` and inspect `docs/FEATURE_MAP.md`.
   - Understand the current architecture, data flow, affected files across Web (`Manikutti`) and Mobile (`manikutti_mobile`), database sheets/tables, and existing conventions.
   - For new capabilities or upgrades, consult `docs/UPGRADE_ROADMAP.md`.
2. **Preserve Architectural Contracts**:
   - Ensure UTC date normalization on all mobile transaction timestamps (`.toUtc().toIso8601String()`).
   - Maintain offline-first SQLite resilience before network sync.
   - Respect authentication and Google Sheets schema boundaries.
3. **Update Documentation After Changes**:
   - After completing code modifications and verification, you MUST immediately update the corresponding feature document in `docs/features/<feature-name>.md` to reflect the latest implementation details, changed files, new endpoints, or updated schemas.
   - If new files, endpoints, or features were introduced, update `docs/FEATURE_MAP.md` and `AI_SYSTEM_MAP.md`.
   - If a proposed upgrade from `docs/UPGRADE_ROADMAP.md` was completed, update its status in the roadmap.
   - Never leave code changes undocumented.

## 2. Git Workflow Rules
1. **Feature Branches**: Always create a new branch for every new feature or distinct task rather than pushing directly to `main` or reusing old feature branches.
2. **Pull Before Push**: Always pull the latest changes from the remote tracking branch before attempting to push, to avoid merge conflicts and rejected pushes.

