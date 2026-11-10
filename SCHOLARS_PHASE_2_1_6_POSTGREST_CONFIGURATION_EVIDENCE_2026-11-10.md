# Scholars Phase 2.1.6 — PostgREST Configuration Evidence

**Status:** BLOCKED — authorized configuration read unavailable.
**Evidence time:** 2026-11-10, 10:57–11:00 CET.
**Author:** Manus AI

## Scope and method

The review concerns the PostgREST configuration for production `cmdglabohpttgfofcmqc` and staging `aqhktriwaglvvrchxmtd`. Project references and health were confirmed through the authenticated Supabase project-list tool. Available Supabase tools were inspected for a supported configuration read. No Management API GET was made because the connector did not disclose scopes and exposed no relevant read operation. No token was extracted or displayed.

## Confirmed findings

Both project references are present in the authorized project listing and report `ACTIVE_HEALTHY` in `eu-west-1`. Production is `scholarship-platform`, PostgreSQL 17.6.1.155; staging is `scholars-staging`, PostgreSQL 17.11.0.018.

No current value was obtained for `db_schema`, `db_extra_search_path`, `max_rows`, pool settings, anonymous database role, or OpenAPI exposure mode. These values are **unknown**, not unset. The PostgREST settings cannot be inferred from the table inventory, security advisor, or earlier API behavior. The prior Phase 2.1.5 report similarly found this path blocked and specified the documented endpoint and scope requirements. [1] [2]

## Limitations and security implications

The documented endpoint is `GET https://api.supabase.com/v1/projects/{ref}/postgrest`; required authorization was identified in prior reviewed material as `rest:read` plus `data_api_config_read`. This workspace cannot verify those scopes. Do not call a broader or alpha endpoint, request secret-read permission, or infer API exposure from SQL state. The exposed-schema allowlist remains a material compatibility and security input for any future baseline.

No response status is reported because no request was made. No project setting was changed. The report contains no JWT-related or database secret material.

## Unresolved questions and next action

An authorized project administrator must provide a sanitized, timestamped read result for each project, containing the project ref, HTTP status, `db_schema`, `db_extra_search_path`, and approved non-secret settings. Confirm anonymous-role and OpenAPI settings through a supported administrator export if the endpoint does not expose them. Reconcile the result with schema grants and the application API dependency list before independent baseline review.

## References

[1]: https://supabase.com/docs/reference/api/v1-get-postgrest-service-config "Supabase Management API Get PostgREST Configuration"
[2]: https://github.com/ImperioKDB/Updates/blob/a88ab72fcdddd58fe28315a1c04229a09511ab77/SCHOLARS_PHASE_2_1_5_POSTGREST_CONFIGURATION_EVIDENCE_2026-11-10.md "Phase 2.1.5 PostgREST Configuration Evidence"
