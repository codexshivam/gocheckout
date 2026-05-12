# Merchant Portal — About & Handoff

This document summarizes everything known about the Merchant Portal application, current implementation progress, architecture, important files and places to continue work. It is written so another AI agent or developer can pick up the project and continue feature work, QA, and production hardening.

---

**Project Overview**

- Purpose: A Flutter-based merchant portal used for managing settings, authentication, coupons, and related merchant operations backed by Appwrite services.
- Platform: Flutter (mobile/web), with native Android/iOS runners present under `android/` and `ios/`.
- Primary integrations: Appwrite (for auth, database, realtime), local feature flags and telemetry instrumentation.

**High-level Architecture**

- Presentation: Flutter UI under `lib/ui/` using controllers/state classes to separate logic from widgets.
- Domain/Services: `lib/data/services/` contains service-layer logic (AuthService, CouponValidationService, Observability). Services encapsulate network, cache, and single-flight logic.
- Repositories: `lib/data/repositories/` implement data persistence and Appwrite-specific behavior (soft-delete, scoping, normalization).
- Models/Schema: `lib/data/models/schema/` contains schema adapters and robust `fromMap`/`toMap` conversions.
- Config: `lib/data/config/` centralizes Appwrite collection IDs, rollout flags and other constants.
- Tests: Unit and widget tests under `test/` mirroring important services and UI flows.

**Key Patterns & Decisions**

- Single-flight/coalescing for session checks to avoid duplicated network calls.
- Short-lived TTL caches with clock skew tolerance to reduce flakiness across auth calls.
- Validation service for coupons centralizing all business rules (dates, code format, bounds).
- Repositories implement soft-delete semantics and active-store scoping; server-side enforcement is recommended as a follow-up.
- Feature flags / rollout config lives in `lib/data/config/` to gate risky behavior.
- Observability and telemetry hooks inserted at key controller/service boundaries.

**Important Files & Where to Look**

- App entry: [lib/main.dart](lib/main.dart)
- Auth service & bootstrap: [lib/data/services/auth_service.dart](lib/data/services/auth_service.dart)
- Auth controller (UI state): [lib/ui/state/auth_state_controller.dart](lib/ui/state/auth_state_controller.dart)
- Appwrite & config: [lib/data/config/appwrite_config.dart](lib/data/config/appwrite_config.dart)
- Coupons model: [lib/data/models/schema/coupon_models.dart](lib/data/models/schema/coupon_models.dart)
- Coupons repository: [lib/data/repositories/coupons_repository.dart](lib/data/repositories/coupons_repository.dart)
- Coupon validation: [lib/data/services/coupon_validation_service.dart](lib/data/services/coupon_validation_service.dart)
- Coupons UI: [lib/ui/views/coupons/](lib/ui/views/coupons/) (view, dialogs, logic, widgets)
- Settings UI and contracts: [lib/ui/views/settings/](lib/ui/views/settings/) and [lib/ui/views/settings/settings_contracts.dart](lib/ui/views/settings/settings_contracts.dart)
- Observability: [lib/data/services/auth_observability_service.dart](lib/data/services/auth_observability_service.dart)
- Implementation tracker & docs: [docs/IMPLEMENTATION_PHASES_README.md](docs/IMPLEMENTATION_PHASES_README.md)

If you need to find other changed files, search the repo for keywords like `coupon`, `auth_rollout`, `settings_contracts`, and `observability`.

**Progress / What Has Been Implemented**

- Implementation Roadmap: All tracked phases marked complete in the project's tracker:
  - Settings phases S0..S9 — completed (contracts, UI fixes, QA checklist automation, tests)
  - Auth phases A0..A10 — completed (session integrity, OAuth robustness, rollout instrumentation)
- Coupons feature: Implemented end-to-end
  - Model: Extended `Coupon` with lifecycle fields, scheduling, per-customer limits, soft-delete.
  - Repository: Appwrite-backed `CouponsRepository` with normalization and soft-delete semantics.
  - Validation: `CouponValidationService` centralizes rules and unit tests.
  - UI: Create/Edit/Delete coupon flows with date/time pickers and defensive validation.
  - Tests: Unit and widget tests added and stabilized.
- Observability & rollout: `auth_rollout_config.dart` and `auth_observability_service.dart` added; instrumentation wired into controllers.
- Docs: Updated `docs/IMPLEMENTATION_PHASES_README.md`, added `docs/SETTINGS_CONTRACTS_CONSTANTS_CATALOG.md`, `docs/AUTH_RISK_TRACEABILITY_MATRIX.md`, and the settings QA checklist with evidence.

**Test & Validation Status**

- `flutter analyze` was run against changed files and returned no issues after fixes.
- Full test suite (`flutter test`) passed in the latest runs. Some non-fatal widget test hit-test warnings were observed and mitigated.

**How to Run Locally**

1. Ensure Flutter SDK is installed and on PATH; run:

```bash
flutter --version
flutter pub get
```

2. Appwrite setup: fill placeholders in `lib/data/config/appwrite_config.dart` with your Appwrite endpoint, project id, and collection IDs. Server-side expectations:

- Ensure collections exist for coupons and settings, with appropriate indexes for uniqueness if required.
- Note: The repo uses soft-delete and client-side uniqueness checks; enforce uniqueness on the server for production safety.

3. Run analyzer and tests:

```bash
flutter analyze
flutter test
```

4. Run on device/emulator:

```bash
flutter run
```

**CI Recommendations**

- Add CI steps to run `flutter analyze` and `flutter test` and fail the build on analyzer errors and on test failures.
- Consider failing on analyzer warnings to reduce regression risk (opt-in until the team addresses warnings).

**Next Tasks / Priorities for Another Agent**

1. Harden production Appwrite usage
  - Add / verify server-side unique constraints and database indices for coupon codes.
  - Add server-side functions or rules to enforce per-customer limits and audit logs.
2. Security & Data Protection
  - Review auth flows and rotate any test keys stored in config.
  - Add stricter input sanitization and rate-limiting for public endpoints.
3. UI polish and accessibility
  - Improve date/time picker UX across platforms (native adaptivity for web/mobile).
  - Run accessibility scans and remediate color/contrast or semantics issues.
4. Telemetry & Monitoring
  - Wire telemetry to a production endpoint (the `auth_observability_service.dart` contains hooks).
  - Add health checks and cron jobs to reconcile soft-deleted items if real deletion is required.
5. CI/CD
  - Add GitHub Actions (or equivalent) to run analyzer/tests and build release artifacts. Include flake detector for widget tests.

**Operational Notes & Known Caveats**

- Tests are stable but UI widget tests may still have occasional flakiness around tap targets on very small screens — expand test surfaces if flaky.
- The app currently performs client-side uniqueness checks for coupons; this is susceptible to race conditions. Server-side enforcement required for production.
- Appwrite credentials are expected to be provided via `lib/data/config/appwrite_config.dart`; secret management is not set up in-repo.

**Where to Find Evidence of Work**

- Implementation phases and task history: [docs/IMPLEMENTATION_PHASES_README.md](docs/IMPLEMENTATION_PHASES_README.md)
- Settings QA checklist and artifacts: [docs/SETTINGS_QA_HARDENING_CHECKLIST.md](docs/SETTINGS_QA_HARDENING_CHECKLIST.md)
- Coupon validation tests: `test/data/services/coupon_validation_service_test.dart`

**If You Are an Automated Agent Taking Over — Checklist to Continue**

1. Pull repository and run `flutter pub get`.
2. Run `flutter analyze` and `flutter test`. Fix any environment-specific failures.
3. Inspect `lib/data/config/appwrite_config.dart` and provide Appwrite credentials in a secrets store; do not commit secrets.
4. Run the app locally and exercise coupon flows: create, redeem, expire, and soft-delete scenarios.
5. Add server-side rules for coupon uniqueness and per-customer enforcement.
6. Open a PR with any fixes; include updated test results and CI config.

---

If you want, I can also:

- Generate a CI GitHub Actions workflow that runs `flutter analyze` and `flutter test`.
- Create a short `CONTRIBUTING.md` with dev environment steps and branch rules.

Last update: 2026-05-09 — captures full implementation of Settings S0..S9, Auth A0..A10, and Coupons feature as implemented in repository.

**What the User (Merchant) Can Do**

- Sign in and manage their account and session (including OAuth flows and session recovery).
- Configure application-level and store-specific settings via the Settings UI (`lib/ui/views/settings/`).
- Create, edit, schedule, and soft-delete coupons with validation around dates, amounts and per-customer limits via the Coupons UI (`lib/ui/views/coupons/`).
- Preview coupon validity windows and constraints before publishing; validation rules live in `lib/data/services/coupon_validation_service.dart`.
- Use the app on mobile or web (Flutter cross-platform) to perform merchant administration tasks.
- Run local developer checks and diagnostics: `flutter analyze` and `flutter test` to validate code and behavior.

**What Type Of App This Is**

- Audience: A B2B merchant administration portal (admin dashboard) intended for merchants or operators to manage storefront settings, promotions, and operational configuration.
- Platform: Cross-platform Flutter application targeting mobile and web with native Android/iOS runners included for platform-specific builds.
- Backend model: Client-driven frontend that uses Appwrite as the primary backend for auth and data storage. The app currently relies on client-side validation and soft-delete semantics; production deployments should add server-side rules and indexes for safety and correctness.
- Deployment model: Designed as a managed admin app which can be run locally for development, packaged for mobile stores, or deployed as a web app/PWA for browser-based merchant access.

**Products, Links, and Other Functionalities**

This project contains more than coupons — it supports product management, external/internal links and other merchant admin features. The implementation is modular and follows the same service/repository/ui patterns used elsewhere.

- Products
  - Responsibilities: product catalog CRUD (create/read/update/delete), pricing, inventory metadata, categorization, visibility scoping per store, and soft-delete/archive workflow.
  - Key places to look: search the repo for `product`, `catalog`, `inventory`, and `sku` to find models, repository implementations, and UI screens. Typical file locations: `lib/data/models/schema/`, `lib/data/repositories/`, `lib/ui/views/products/`.
  - Tests: product model and repository unit tests, and product screen widget tests (look under `test/` for product-related tests).
  - Next steps: add server-side indexing and search optimization, bulk import/export (CSV/JSON), SKU uniqueness enforcement, and reconciliation jobs for inventory.

- Links (deep links & external links)
  - Responsibilities: store and present merchant-facing links (e.g., storefront links, external integrations, help links), and support deep linking into parts of the app.
  - Key places to look: search for `link`, `deepLink`, `deeplink`, `url` in the `lib/` tree. UI components for links are typically in `lib/ui/widgets/` or under relevant view folders.
  - Next steps: standardize a `Link` model, validate and sanitize URLs server-side, and add link management UI with preview/target validation.

- Other Functionalities (examples)
  - Order/Transaction views: read-only dashboards for orders and financial summaries (look for `order`, `transaction` keywords).
  - Integrations: third-party integrations (payment gateways, analytics) — search for integration-specific service classes.
  - Exports & Reports: scheduled or on-demand exports for accounting and analytics.
  - Next steps: implement export pipelines, webhooks for external systems, and an integrations management UI with OAuth/client credentials rotation.

If you want, I can scan the workspace to produce a file-by-file map for `product`, `link`, `order`, and `integration` related code and add direct links into `about.md`.


**Features & Breakdown**

This section describes primary product features, responsibilities, key files, tests, and recommended next steps for each feature so another agent can pick up development confidently.

- Authentication
  - Responsibilities: user sign-in/out, OAuth flows, session validation and refresh, single-flight session coalescing, TTL cache, error mapping and telemetry.
  - Key files: [lib/data/services/auth_service.dart](lib/data/services/auth_service.dart), [lib/ui/state/auth_state_controller.dart](lib/ui/state/auth_state_controller.dart), [lib/data/config/appwrite_config.dart](lib/data/config/appwrite_config.dart).
  - Tests: `test/data/services/auth_service_test.dart` and controller tests under `test/ui/state/`.
  - Next steps: add server-side session validation endpoints if needed, rotate keys, and add e2e login flows.

- Settings
  - Responsibilities: app configuration, persistent user preferences, contracts/constants validation, UI for editing settings, QA checklist automation.
  - Key files: [lib/ui/views/settings/](lib/ui/views/settings/) and [lib/ui/views/settings/settings_contracts.dart](lib/ui/views/settings/settings_contracts.dart).
  - Tests: `test/ui/views/settings/settings_view_test.dart` and other settings unit tests.
  - Next steps: export/import settings, add access controls, and add integration tests for settings persistence.

- Coupons
  - Responsibilities: create/edit/delete coupons, validation rules (dates, amounts, per-customer limits), normalization, soft-delete and scoping to active stores.
  - Key files: [lib/data/models/schema/coupon_models.dart](lib/data/models/schema/coupon_models.dart), [lib/data/repositories/coupons_repository.dart](lib/data/repositories/coupons_repository.dart), [lib/data/services/coupon_validation_service.dart](lib/data/services/coupon_validation_service.dart), `lib/ui/views/coupons/`.
  - Tests: `test/data/services/coupon_validation_service_test.dart`, `test/ui/views/coupons/coupons_view_test.dart`.
  - Next steps: add server-side uniqueness/indexes, audit logs, redemption records, and concurrency-safe redemption API.

- Observability & Rollout
  - Responsibilities: collect auth-related telemetry, gate features via rollout flags, propagate errors and metrics to observability backends.
  - Key files: [lib/data/services/auth_observability_service.dart](lib/data/services/auth_observability_service.dart), [lib/data/config/auth_rollout_config.dart](lib/data/config/auth_rollout_config.dart).
  - Tests: unit tests around telemetry hooks and rollout logic.
  - Next steps: integrate with a production telemetry backend (e.g., Sentry, Datadog), and add sampling/PII scrubbing.

- Repositories & Services (data layer)
  - Responsibilities: Appwrite collections access, mapping DTOs <-> domain models, soft-delete, client-side guards, caching, and normalization.
  - Key files: `lib/data/repositories/`, `lib/data/services/`.
  - Tests: repository unit tests and service integration tests.
  - Next steps: add comprehensive retry/backoff, server-side validation mirrors, and pagination cursors for list endpoints.

- UI (presentation)
  - Responsibilities: views, dialogs, input validation, responsive layout, pickers, and user workflows.
  - Key files: `lib/ui/views/`, `lib/ui/widgets/`, controllers under `lib/ui/state/`.
  - Tests: widget tests for major flows (settings, coupons, auth) under `test/ui/`.
  - Next steps: accessibility improvements, responsive layout polish, localized strings, and visual regression testing.

- Testing & QA
  - Coverage: unit tests for services/validation, widget tests for UI flows, analyzer passes configured in developer workflow.
  - Key files: `test/` directory (see specific test files above).
  - Next steps: add CI, flake detection for widget tests, and end-to-end integration tests.

- Security & Ops
  - Concerns: client-side uniqueness checks, secret management for Appwrite credentials, server-side enforcement gaps, and telemetry PII handling.
  - Recommendations: server-side constraints, secrets managed outside repo (CI secrets), penetration testing, and audit logging for coupon redemptions.
