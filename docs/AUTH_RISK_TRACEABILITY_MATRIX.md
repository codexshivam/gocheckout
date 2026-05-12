# Auth Risk Traceability Matrix

This matrix maps key auth/startup risks to implemented mitigations and validation evidence.

| Risk ID | Risk | Mitigation | Code Reference | Validation Evidence |
|---|---|---|---|---|
| A-R01 | Duplicate bootstrap runs race and override state | Bootstrap single-flight with in-flight future lock and generation invalidation | lib/ui/state/auth_state_controller.dart | test/ui/state/auth_state_controller_test.dart (bootstrap single-flight) |
| A-R02 | Transient backend failure during session check logs out valid users | Retry + timeout wrapper with retryable code handling | lib/ui/state/auth_state_controller.dart | test/ui/state/auth_state_controller_test.dart (retries transient errors) |
| A-R03 | Session check hangs causing startup deadlock | Timeout handling and explicit error fallback | lib/ui/state/auth_state_controller.dart | test/ui/state/auth_state_controller_test.dart |
| A-R04 | Concurrent login/signup while startup in progress causes conflicts | Transition lock blocks auth actions during bootstrap/loading | lib/ui/state/auth_state_controller.dart | test/ui/state/auth_state_controller_test.dart (login blocked during bootstrap) |
| A-R05 | OAuth popup blocked leads to unclear failure path | Actionable popup-blocked error mapping | lib/data/services/auth_service.dart, lib/ui/state/auth_state_controller.dart | test/data/services/auth_service_test.dart, test/ui/state/auth_state_controller_test.dart |
| A-R06 | Redirect/callback mismatch causes opaque auth failures | Redirect/callback mismatch normalization and explicit recovery copy | lib/data/services/auth_service.dart, lib/ui/state/auth_state_controller.dart | test/data/services/auth_service_test.dart, test/ui/state/auth_state_controller_test.dart |
| A-R07 | Unsafe web callback origin used in OAuth flow | Redirect sanitization (https only except localhost http), query/fragment strip | lib/data/services/auth_service.dart | test/data/services/auth_service_test.dart (sanitizeWebRedirectUri) |
| A-R08 | Duplicate session calls create unnecessary load and race windows | Session check coalescing in-flight requests + short TTL cache | lib/data/services/auth_service.dart | test/data/services/auth_service_test.dart (coalesces concurrent checkSession) |
| A-R09 | Malformed user payload accepted as valid session | Required field and timestamp parse guards | lib/data/services/auth_service.dart | test/data/services/auth_service_test.dart (rejects malformed payload) |
| A-R10 | Clock skew / future timestamp session anomalies bypass checks | Skew tolerance validation on accessedAt | lib/data/services/auth_service.dart | test/data/services/auth_service_test.dart (small vs large skew) |
| A-R11 | Logout network failure leaves stale local auth state | Deterministic local teardown even when remote logout fails | lib/ui/state/auth_state_controller.dart | test/ui/state/auth_state_controller_test.dart (logout clears local session on failure) |
| A-R12 | Stale bootstrap completes after logout and restores user | Bootstrap generation invalidated on logout | lib/ui/state/auth_state_controller.dart | test/ui/state/auth_state_controller_test.dart |
| A-R13 | Pending invite access not reconciled on auth | Resolve pending store access during bootstrap/login/signup | lib/ui/state/auth_state_controller.dart, lib/data/services/auth_service.dart | test/ui/state/auth_state_controller_test.dart (bootstrap resolves pending access) |
| A-R14 | Data contract drift in Appwrite docs breaks parsing | Schema adapter for coercion/null safety and migration-safe model parsing | lib/data/models/schema/schema_adapter.dart and schema models | test/data/models/schema_adapter_test.dart |
| A-R15 | Inconsistent user-visible errors reduce recovery clarity | Shared error envelope taxonomy and stable mapping | lib/data/models/app_error_envelope.dart | test/data/models/app_error_envelope_test.dart |
| A-R16 | OAuth failures in prod not visible quickly | Telemetry + oauth failure threshold alerts | lib/data/services/auth_observability_service.dart, lib/ui/state/auth_state_controller.dart | test/data/services/auth_observability_service_test.dart |
| A-R17 | Unsafe rollout requires code rollback | Runtime feature flags for oauth hardening/session integrity/telemetry | lib/data/config/auth_rollout_config.dart | test/ui/state/auth_state_controller_test.dart (hardening flag behavior) |
| A-R18 | Incident response lacks operational runbook | Rollout/rollback guidance maintained via tracker and risk matrix standards | docs/IMPLEMENTATION_PHASES_README.md, docs/AUTH_RISK_TRACEABILITY_MATRIX.md | Documentation review |

## Standards

- Add a new Risk ID for any auth behavior change that introduces a failure mode.
- Every new risk must include mitigation, code reference, and at least one validation artifact.
- Keep this matrix in sync with IMPLEMENTATION_PHASES_README.md phase status updates.
