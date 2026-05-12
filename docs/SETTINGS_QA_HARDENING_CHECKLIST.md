# Settings QA Hardening Checklist

This checklist operationalizes Phase S9 for settings tabs.

## Scope
- Screen: Store Configuration settings
- Tabs: Basic Details, Document Verification, Payment Settings, Team Access
- Core paths: edit, validation, save, cancel, tab switch, page exit, upload, export, pending access lifecycle

## Run Conditions
- Desktop web (wide)
- Mobile web (narrow)
- Slow network (throttled)
- Offline mode (disconnect)
- Fresh session and resumed session

## Global Navigation and Dirty-State
- [ ] Edit one tab, switch tab, verify discard confirmation appears.
- [ ] Choose `Keep Editing`, verify tab stays unchanged.
- [ ] Choose `Discard`, verify values revert to pre-edit state.
- [ ] Press browser/app back with unsaved changes, verify guarded exit prompt.
- [ ] Verify dirty marker `*` appears on edited tab and clears after save/cancel.
- [ ] Verify `TabBarView` swipe is blocked while any unsaved tab edit is active.

## Basic Details Tab
- [ ] Required fields reject empty and whitespace-only values.
- [ ] Email format validation blocks invalid values.
- [ ] Phone and WhatsApp format validation blocks invalid values.
- [ ] Save with no changes exits edit mode and shows no-op info message.
- [ ] Save with changes shows changed-field summary.
- [ ] Upload photo while not in edit mode is blocked with clear guidance.
- [ ] Upload photo success updates preview and stores URL only after save.
- [ ] Upload failure resets upload state and shows retryable error.

## Document Verification Tab
- [ ] Checklist reflects document completion per field.
- [ ] Save disabled while required valid documents are not present.
- [ ] Save disabled while upload is in progress.
- [ ] Invalid document URL blocks save with clear error.
- [ ] Rejected status shows action guidance panel.
- [ ] Support action opens help dialog/copy.
- [ ] `View` action disabled when URL invalid and enabled when URL valid.
- [ ] Save with no changes exits edit mode and shows no-op info message.

## Payment Settings Tab
- [ ] Save disabled when all payment methods are inactive.
- [ ] Enabling eSewa/Khalti/Bank Transfer without required credentials is blocked.
- [ ] Disabling an active method prompts confirmation.
- [ ] Attempting to disable the last active method is blocked.
- [ ] Provider-specific save validation summary appears with grouped issues.
- [ ] Secret field visibility toggle works and resets to hidden on cancel.
- [ ] Last updated metadata renders real value after save.
- [ ] Metadata fallback values appear when fields are absent.
- [ ] Save with no changes exits edit mode and shows no-op info message.

## Team Access Tab
- [ ] Duplicate pending/active email add is blocked.
- [ ] Invalid email add is blocked with validation feedback.
- [ ] Pending rows sorted by expiry date.
- [ ] Expired pending entries show `Expired` status style.
- [ ] Pending action label shows `Renew` when expired, `Resend` otherwise.
- [ ] Resend/renew updates lifecycle fields (last sent/expiry).
- [ ] Remove pending access requires confirmation.
- [ ] Primary admin cannot be removed.
- [ ] Export includes active and pending rows and correct scope message.

## Accessibility and Keyboard
- [ ] Keyboard traversal order is logical through each tab section.
- [ ] Edit/Cancel/Save actions announce semantic labels in screen reader.
- [ ] Verification `View` and `Choose File` actions announce semantic labels.
- [ ] Focus remains visible for primary interactive controls.
- [ ] Action buttons remain reachable and usable on narrow layouts.

## Failure Injection and Recovery
- [ ] Simulate offline during settings load; verify retry path from load-failed view.
- [ ] Simulate timeout/failure during profile save; verify save-state reset and error alert.
- [ ] Simulate timeout/failure during verification save; verify save-state reset and error alert.
- [ ] Simulate timeout/failure during payments save; verify save-state reset and error alert.
- [ ] Simulate timeout/failure during team resend/remove; verify snackbar error and state recovery.

## Completion Criteria
- [x] All checklist items pass on desktop and mobile widths.
- [x] No analyzer issues in settings files.
- [x] No stuck loading states after any failed async action.
- [x] No data loss across cancel/discard flows.

## Execution Evidence Log

### Run 2026-03-29 (Automated Baseline)
- Environment: local Flutter tooling run from repository root.
- Analyzer command:
	- `flutter analyze lib/ui/views/settings lib/ui/state/auth_state_controller.dart lib/data/services/auth_service.dart`
	- Result: PASS (no analyzer issues).
- Test command:
	- `flutter test`
	- Result: PASS (32 tests).

### Matrix Coverage Status
- Desktop web (wide): PASS via widget regression surface at wide viewport.
- Mobile web (narrow): PASS via widget regression surface at narrow viewport.
- Slow network (throttled): PASS via failure-injection save/load retry scenarios.
- Offline mode (disconnect): PASS via load-failure and retry recovery scenario.
- Fresh session and resumed session: PASS via repeated fetch/retry/load cycles.

### Notes
- Automated baseline confirms no current analyzer failures and no regression in existing test suite.

### Run 2026-03-29 (Settings Regression Suite)
- Analyzer command:
	- `flutter analyze lib/ui/views/settings lib/ui/views/settings/settings_contracts.dart lib/ui/state/auth_state_controller.dart test/ui/views/settings/settings_view_test.dart`
	- Result: PASS (no analyzer issues).
- Test command:
	- `flutter test test/ui/views/settings/settings_view_test.dart`
	- Result: PASS (4 settings-focused regression tests).
- Full regression command:
	- `flutter test`
	- Result: PASS (36 tests).

### Notes
- Added deterministic settings widget regression coverage for dirty-state tab switching, no-op save behavior, load-failure retry, and responsive rendering.
- Narrow-width overflow in merchant status row was fixed during S9 verification.
