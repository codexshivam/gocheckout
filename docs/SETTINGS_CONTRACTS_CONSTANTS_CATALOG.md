# Settings Contracts And Constants Catalog

This document freezes canonical contracts/constants for Settings feature paths.

## Source of Truth

- Code constants: lib/ui/views/settings/settings_contracts.dart

## Stable Contracts

### Tab IDs

- basicDetails (index 0)
- documentVerification (index 1)
- paymentSettings (index 2)
- teamAccess (index 3)

### Section Labels

- Basic Details
- Document Verification
- Payment Settings
- Team Access

### Verification Storage Slugs

- citizenship
- business_registration
- pan

### Payment Provider Keys

- esewa
- khalti
- bankTransfer

### Payment Provider Labels

- eSewa
- Khalti
- Bank Transfer

## UX Copy Constants (Critical Dialogs)

- Discard Edits?
- Discard Unsaved Changes?
- Keep Editing
- Discard

## Enforcement Notes

- New settings tabs/flows should add constants in settings_contracts.dart first.
- Avoid introducing new inline literals for provider keys/slugs/tab labels in settings logic.
- If labels must change, update constants centrally and validate all tabs still pass the S9 checklist.
