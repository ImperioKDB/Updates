# Scholars Phase 2.1.6 — Final Decision and Next Gate

**Verdict: BLOCKED — AUTHORIZED CAPTURE NOT AVAILABLE**

**Evidence time:** 2026-11-10, 10:57–11:01 CET.
**Author:** Manus AI

## Scope and methodology

This decision covers production `cmdglabohpttgfofcmqc`, existing staging `aqhktriwaglvvrchxmtd`, the current Scholars source repository, and the authorized capture/testing work. Evidence came from dedicated read-only Supabase project, migration, table, extension, and advisor tools; public GitHub compare/tree/file access; and local CLI version/help checks. No arbitrary SQL, API probe, data export, schema extraction, restore, migration, privilege/configuration change, or deployment was performed.

## Confirmed findings

The pinned Supabase CLI `2.122.1` works in version/help-only mode, but there is no approved non-writing database URL. There is no verified Management API scope for PostgREST configuration. Thus neither declarative nor SQL schema artifact was generated; no artifact hashes or cross-method coverage comparison exist. The existing staging project has no migration entries or tables in the inspected application schemas and was not used for testing.

Production inventory remains consistent with the prior reports at the migration head: the last three entries are the Airtel/Afara, Kayode/NNPC-SNEPCo, and Airtel eligibility updates. Production reports 45 public tables in the table inventory; the current application tree is `3deba708e146ceb2aa6846c4691d58ace93795b2` with three added migration files since the named baseline. Five installed extension versions match between projects. The fresh security advisor still flags 23 anon- and authenticated-callable `SECURITY DEFINER` functions, four owner-executed views, six RLS-enabled/no-policy tables, two mutable-search-path functions, and disabled leaked-password protection.

## Decision rationale

The required conditions for either “READY FOR INDEPENDENT BASELINE REVIEW” or “READY WITH CONDITIONS” are not met. Both capture artifacts, their hashes, coverage reconciliation, and artifact-specific security review are absent. PostgREST configuration and isolated compatibility testing remain unavailable. Prior function-body and table-privilege issues remain carried-forward review leads and are not represented as newly extracted definitions.

## Next gate

1. Provide a restricted, verified read-only database URL through approved secret injection. Confirm effective privileges without exposing the URL.
2. Provide sanitized Management API/PostgREST configuration evidence for both refs using verified `rest:read` and `data_api_config_read` access; do not grant secret-read scope.
3. Run the pinned CLI against an approved schema list, preserve strict-coverage failures, retain artifacts privately, hash each file, and reconcile schema classes against current inventory.
4. Obtain independent security review of the actual artifacts and destination creator/default-privilege model.
5. Provide an isolated local database environment or separate approval for a disposable test environment; use synthetic fixtures only.
6. Seek a separate explicit approval before any staging restoration. This phase does not authorize one.

## Explicit no-change statement

Production and existing staging were not modified. No tables, functions, triggers, policies, roles, privileges, defaults, buckets, data, or PostgREST settings were changed. No production data or storage files were exported. No application change, commit to Scholars, Vercel deployment, or staging restoration was performed.

## References

[1]: https://github.com/ImperioKDB/Updates/blob/a88ab72fcdddd58fe28315a1c04229a09511ab77/SCHOLARS_PHASE_2_1_5_BASELINE_CANDIDATE_AND_DECISION_REGISTER_2026-11-10.md "Phase 2.1.5 Decision Register"
[2]: https://github.com/ImperioKDB/Scholars/commit/3deba708e146ceb2aa6846c4691d58ace93795b2 "Current Scholars Main Commit"
[3]: https://supabase.com/docs/reference/api/v1-get-postgrest-service-config "Supabase Management API Get PostgREST Configuration"
