# Scholars Phase 2.1.6 — Application Compatibility and Type Review

**Status:** Partial repository comparison complete; database compatibility unverified.
**Evidence time:** 2026-11-10, 10:57–11:00 CET.
**Author:** Manus AI

## Scope and methodology

The review compares Scholars baseline `cf3682ce35912df7b9b9352193630fc404427c7c` with current `main` and checks production migration metadata for the three post-baseline changes. GitHub public compare/tree/raw-file access was used. Supabase evidence is limited to read-only migration, table, and extension inventory. No application build, database type generation, migration execution, or deployment was run.

## Confirmed repository and ledger findings

Current Scholars `main` is `3deba708e146ceb2aa6846c4691d58ace93795b2`, three commits ahead of the stated baseline. The compare contains exactly three added files and no application-source edits:

- `20261109130500_correct_airtel_afara_application_route.sql`
- `20261109131500_reverify_kayode_and_nnpc_snepco_sources.sql`
- `20261109132500_update_airtel_scholarship_eligibility.sql`

The current tree contains 132 SQL migration files; the prior baseline count was 129. The files are data-oriented updates to existing opportunity, scholarship, and rules records (including appended research notes), not new schema definitions. The production migration listing includes the matching last three version/name entries `20261109120215`, `20261109120725`, and `20261109121207`. This confirms the ledger records them; it does not confirm current row values, whether a baseline capture includes their effects, or a complete historical replay path. [1] [2]

## Compatibility and types

There is no production DDL artifact from which to generate or compare types. Staging has no migrations or application tables in the inspected schemas, so it is not a valid type-generation target. The current source-tree scan did not identify a generated `database.types` path in its filtered search; this is not a complete proof that no type contract exists under another name. No schema/type mismatch can be measured without a trusted schema source.

Previously reviewed call-site analysis warns that a blanket browser-role grant revoke would disrupt catalogue browsing, matching, saves, applications, notifications, profiles/WAEC, community, Resource Center, and admin routes. That dependency risk is inherited; this phase did not run application paths or JWT tests. Do not change privileges until compatible projections/routes are added and tested.

## Limitations, security implications, and next action

Without a reviewed schema capture, exact database/app contract compatibility, function and view behavior, default privileges, PostgREST exposure, and role-specific RLS remain unknown. The three current migrations update existing records and contain research-note text; they must not be mistaken for schema-baseline recovery. Once capture is authorized, compare the artifacts with current migration state and application call sites, generate types from an approved isolated schema, and run synthetic role tests. Do not apply these migrations to production or staging as part of this phase.

## References

[1]: https://github.com/ImperioKDB/Scholars/compare/cf3682ce35912df7b9b9352193630fc404427c7c...3deba708e146ceb2aa6846c4691d58ace93795b2 "Scholars Baseline-to-Main Compare"
[2]: https://github.com/ImperioKDB/Updates/blob/a88ab72fcdddd58fe28315a1c04229a09511ab77/SCHOLARS_PHASE_2_1_5_APPLICATION_COMPATIBILITY_AND_PRIVILEGE_ANALYSIS_2026-11-10.md "Phase 2.1.5 Application Compatibility Analysis"
