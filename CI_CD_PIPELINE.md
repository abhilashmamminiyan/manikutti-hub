# Ecosystem CI/CD & Release Architecture

This document outlines the Continuous Integration (CI), Continuous Deployment (CD), and version control architecture for the Manikutti Finance Tracker ecosystem.

## 1. The Polyrepo Pattern

This ecosystem follows the industry-standard **Polyrepo** architecture. Instead of placing all code in one massive repository (a Monorepo), the ecosystem is decentralized:

*   **`manikutti_mobile`**: An independent repository containing only the Flutter app. It builds, tests, and deploys itself.
*   **`Manikutti`**: An independent repository containing only the Next.js Web Dashboard. It builds, tests, and deploys itself.
*   **`manikutti-hub` (Parent)**: Acts solely as a "Meta-repo" connecting the two child repositories together using Git Submodules. **It does not run deployments.**

## 2. CI/CD Workflow & Branching Strategy

Both the Web and Mobile repositories follow a strict branch protection and automated deployment pipeline. 

### Step 1: Feature Development & PR Checks
Developers create isolated branches (e.g., `feature/2026-07-04`). Opening a Pull Request (PR) against `main` triggers the **Quality Gates** (`pr-checks.yml`).

For the Mobile repo, this pipeline automatically enforces:
*   `dart format`: Checks if the code matches standard Dart formatting.
*   `flutter analyze`: Runs static code analysis to catch syntax or logic errors.
*   `flutter test`: Runs any written unit tests.

*Direct pushes to `main` are blocked. All code must pass these checks first.*

### Step 2: Auto-Merge
Once the Quality Gate passes, the CI pipeline utilizes a Personal Access Token (`PAT_TOKEN`) to automatically squash and merge the Pull Request into the `main` branch. 

> **Important Note:** The auto-merge uses a PAT instead of the default `GITHUB_TOKEN`. GitHub intentionally prevents actions performed by the default token from triggering other workflows. By using the PAT, the merge commit correctly triggers the deployment pipelines.

### Step 3: Automated Deployment
Merging into `main` immediately triggers the deployment pipelines.

**Mobile Deployment (`distribute.yml`)**:
1. Checks out the `main` branch.
2. Sets up Java 17 and Flutter.
3. Automatically increments the Android Build Number using the unique `GITHUB_RUN_NUMBER`.
4. Compiles the Release APK.
5. Uploads the binary directly to **Firebase App Distribution** targeting the `family` tester group.
6. Attaches the Git commit message as the release notes.

**Web Deployment**:
Functions similarly — merging to `main` triggers a build and deploys the Next.js static output to the web hosting provider (Vercel / Firebase Hosting).

## 3. Parent Repo Synchronization

Since deployments happen independently in the child repos, the Parent Repo (`manikutti-hub`) must be kept up to date so it always points to the latest stable production code.

This is handled by the **`sync-parent.yml`** workflow, which exists in both child repositories.

**How it works:**
1. Right after the `main` branch deployment is triggered, the sync workflow runs.
2. It uses the `PAT_TOKEN` to clone the parent repository (`manikutti-hub`).
3. It forces the parent repository to pull the latest commits from the submodules (`git submodule update --remote --merge`).
4. It commits the updated submodule pointers back to the parent repository.

This ensures that anyone cloning the `manikutti-hub` repo is instantly given the exact code combination currently running in production.

## 4. Why This Architecture? (Industry Best Practice)

While it might seem tempting to move all deployment logic into the Parent Repo, that is an anti-pattern. 

**Why we deploy independently:**
*   **Speed & Reliability:** Submodules are notoriously difficult to check out and manage inside CI/CD runners. Building them separately is much faster.
*   **Immediate Feedback:** If a Flutter build fails, the error logs appear directly in the `manikutti_mobile` repository next to the code that caused the error, rather than being buried in a massive Parent Repo pipeline.
*   **Decoupled Lifecycles:** Web apps deploy instantly. Mobile apps sometimes require App Store / Play Store review. Tying their releases together arbitrarily slows down web updates.

### Analytics & Release Tracking
To track releases for analytics in a polyrepo setup, the application automatically sends its version (e.g., `1.0.0+4`) alongside any telemetry data to Firebase Analytics. If an error spike occurs, developers simply look up GitHub Release `1.0.0+4` in the `manikutti_mobile` repository to see the exact code that caused the issue.
