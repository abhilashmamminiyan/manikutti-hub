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
3. **Always Sync with Main Before Merging**: Always fetch and merge the latest commits from `origin/main` into your feature branch before raising, testing, or merging a pull request to ensure full integration and prevent stale preview deployment failures.

## 3. GitHub CLI (`gh`) & Pull Request Automation Rules
1. **Repository-Scoped GH Configuration (`.gh`)**:
   - The repository is configured with a repository-local `.gh` configuration directory (`$WorkspaceRoot\.gh`) for GitHub CLI (`gh`) commands.
   - When executing `gh` commands or automation scripts (`scripts/automate_pr.ps1` / `scripts/automate_pr.sh`), always ensure `GH_CONFIG_DIR` points to the workspace `.gh` directory (`$WorkspaceRoot\.gh`) if present.
2. **Pull Request Lifecycle & CI Verification**:
   - When a feature or bugfix is completed, ask for user confirmation and run `scripts/automate_pr.ps1` (or `scripts/automate_pr.sh`).
   - Always observe the live GitHub Actions workflow run via `gh run watch`.
   - If the pipeline fails, inspect the failed step logs via `gh run view <id> --log-failed`, resolve the issue immediately, and rerun the pipeline until it passes.
   - Once verified green, confirm merge into `main` and synchronize the master hub submodule commit pointer.
