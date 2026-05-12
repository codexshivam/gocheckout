# Implementation Phases Status

This document tracks the phased implementation we discussed for:
- Settings tabs hardening and UX reliability
- Auth, startup, onboarding, and session lifecycle hardening

## Status Legend
- [x] Completed
- [~] In progress / partially completed
- [ ] Not started

## Quick Snapshot

### Settings Track
- Completed: 10 phases
- In progress: 0 phases
- Not started: 0 phases

### Auth + Startup Track
- Completed: 11 phases
- In progress: 0 phases
- Not started: 0 phases

---

## A) Settings Phases

### [x] Phase S0: Foundation + Contracts
- Delivered:
  - Core architecture and tab orchestration hardened through prior slices.
  - Central settings contracts/constants module added in
    [lib/ui/views/settings/settings_contracts.dart](lib/ui/views/settings/settings_contracts.dart) and adopted in settings view logic.
  - Constants/contract catalog documented in
    [docs/SETTINGS_CONTRACTS_CONSTANTS_CATALOG.md](docs/SETTINGS_CONTRACTS_CONSTANTS_CATALOG.md).
  - Removed duplicated inline provider keys, verification slugs, and tab labels from settings orchestration paths.

### [x] Phase S1: Navigation Safety + Dirty State
- Delivered:
  - Unsaved-change guards on tab switch and back navigation.
  - Dirty tab indicators.
  - Confirm discard flows.

### [x] Phase S2: Profile Comfort + Validation
- Delivered:
  - Section hierarchy (Business Identity, Contact Information).
  - Required markers and clearer implications text.
  - Email/phone/WhatsApp format validation.
  - Keyboard and autofill hints.

### [x] Phase S3: Verification Trust UX
- Delivered:
  - Required checklist with completion indicators.
  - Upload quality/format guidance.
  - Clear required copy on document sections.
  - Rejected-state fallback panel.
  - Support/help action in tab.

### [x] Phase S4: Payments Guardrails
- Delivered:
  - At least one active method enforcement.
  - Save readiness gating with reason text.
  - Enabling requires provider credentials.
  - Disable confirmation dialogs.
  - Secret key show/hide toggles.
  - Provider-specific save validation summary and actionable grouped errors.
  - Last-updated metadata display with graceful fallbacks.
  - Provider-level fallback save path with partial success/failure summary.

### [x] Phase S5: Team Access Safety + Clarity
- Delivered:
  - Active vs pending split.
  - Better role explanation.
  - Strong email validation and duplicate detection.
  - Removal confirmation.
  - Export scope clarity.

### [x] Phase S6: Team Lifecycle (Pending Access)
- Delivered:
  - Resend action for pending access.
  - Lifecycle metadata fields (last sent, expiry) with fallback display.
  - Expiry-state UX with explicit expired badge and renew labeling.

### [x] Phase S7: Save Efficiency
- Delivered:
  - No-op save short-circuiting in Profile, Verification, Payments.
  - Duplicate save action short-circuiting while save is in progress.
  - Upload generation guards to suppress stale async upload callbacks after cancel/discard.

### [x] Phase S8: Responsive + Accessibility Comfort
- Delivered:
  - Team mobile card layout.
  - Compact action-row stacking.
  - Keyboard/autofill improvements.
  - Full semantic labels/focus-order audit for all tab controls.
  - Contrast review across status/help/support copy and action controls.

### [x] Phase S9: QA + Hardening Pass
- Delivered:
  - Practical regression and failure checklist documented in
    [docs/SETTINGS_QA_HARDENING_CHECKLIST.md](docs/SETTINGS_QA_HARDENING_CHECKLIST.md).
  - Automated baseline evidence captured (settings-focused analyzer run + full test suite pass) and logged in checklist execution notes.
  - Settings widget regression suite added for responsive rendering, dirty-state discard flow, no-op save behavior, and load-failure retry recovery.
  - Narrow-width status-row overflow fixed as part of S9 validation.
  - Completion criteria and run-condition evidence logged in checklist execution notes.

---

## B) Auth + Startup Phases

### [x] Phase A0: Risk Matrix + Standards
- Delivered:
  - 100-risk inventory compiled and grouped.
  - Execution plan documented.
  - Formal traceability matrix (risk -> mitigation -> test case) added in
    [docs/AUTH_RISK_TRACEABILITY_MATRIX.md](docs/AUTH_RISK_TRACEABILITY_MATRIX.md).

### [x] Phase A1: Team Access Assignment on Sign-in
- Delivered:
  - Team feature changed to pending email access model.
  - Auth resolves pending access on Google sign-in.
  - User is assigned to store team and active store is set.
  - Legacy invite compatibility fallbacks added.

### [x] Phase A2: Startup Resilience (Initial Slice)
- Delivered:
  - `checkSession` semantics improved (401 vs retryable failures).
  - Bootstrap single-flight locking.
  - Retry + timeout wrapper for startup session check.
  - Stale run generation guard to prevent race overrides.
  - Startup fallback retry controls exposed in auth screens.
  - Transition lock propagation to block conflicting auth actions during bootstrap/loading.

### [x] Phase A3: Onboarding Assignment Compatibility
- Delivered:
  - Onboarding flow skip when auth resolver already set active store.
  - Invite lookup normalizations for legacy records.
  - Idempotent onboarding assignment writes with active-store fallback routing.
  - Conditional user active-store updates to avoid duplicate write churn.
  - Invite cleanup hardened to tolerate already-deleted records.

### [x] Phase A4: OAuth Robustness
- Delivered:
  - OAuth launch unified through a single hardened flow for login/signup.
  - Web redirect sanitization rejects unsafe non-HTTPS origins (except localhost HTTP) and strips query/fragment callback artifacts.
  - Popup-blocked and callback/origin mismatch failures normalized to actionable recovery guidance.
  - Auth controller surfaces explicit retry copy for popup-blocked and callback-validation OAuth failures.
  - Added targeted tests for redirect sanitization and OAuth failure mapping behavior.

### [x] Phase A5: Session/Token Integrity
- Delivered:
  - Session check single-flight request coalescing to prevent duplicate concurrent `account.get()` calls.
  - Short-lived session cache to avoid rapid redundant session fetches during startup transitions.
  - Malformed payload guardrails for empty identity fields and invalid timestamp formats.
  - Clock-skew tolerance checks to reject implausible future `accessedAt` values.
  - Targeted unit tests for coalescing, malformed payload rejection, and skew boundary behavior.

### [x] Phase A6: Logout Transaction Hardening
- Delivered:
  - Deterministic local logout teardown even when remote session deletion fails.
  - In-flight bootstrap invalidation during logout to prevent stale state restoration.
  - Realtime unsubscribe guarantees via store session teardown before sign-out.

### [x] Phase A7: Error Taxonomy Platform
- Delivered:
  - Shared error envelope model with stable error codes and retryability metadata.
  - Consistent auth/startup error mapping into user-facing messages.
  - Onboarding state error handling migrated to the shared taxonomy.
  - Automated tests for taxonomy mapping behavior.

### [x] Phase A8: Data Contract Hardening
- Delivered:
  - Shared schema adapter utilities for type-coercion and null-safe parsing.
  - Migration-safe parsing in user/store/invite schema models.
  - Reduced cast fragility in auth pending-access team assignment flow.
  - Automated schema adapter/model coercion tests.

### [x] Phase A9: Tests + Failure Injection
- Delivered:
  - Auth lifecycle unit tests for startup single-flight behavior.
  - Retry/timeout and transient failure recovery checks.
  - Transition-lock coverage for conflicting bootstrap/login actions.
  - Logout teardown guarantees verified under remote failure.
  - Startup retry and profile-completion delegation coverage.

### [x] Phase A10: Rollout + Observability
- Delivered:
  - Runtime rollout flags for OAuth hardening/session integrity/telemetry and threshold tuning.
  - Auth lifecycle event instrumentation (bootstrap, login, signup, logout) with sampled telemetry emission.
  - OAuth failure threshold alerting in observability service for rapid incident detection.
  - Rollback-safe behavior toggle for OAuth hardening to allow fast production mitigation.
  - Staged rollout and rollback guidance captured through runtime flag controls in auth rollout config and observability thresholds.
  - Automated tests for observability thresholding/sampling and controller telemetry behavior.

---

## Recommended Next Execution Order
1. All implementation phases delivered; keep `flutter analyze` + `flutter test` in CI and run periodic manual exploratory QA.

---

## Notes
- Status markers above reflect implementation completed in this repository so far.
- This file is intentionally operational: update the checkboxes as each phase slice is merged.
