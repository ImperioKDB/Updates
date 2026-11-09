# Scholars Phase 2.1.2 — Staging Environment Readiness Audit

**Investigation date:** 2026-11-09
**Status:** Read-only staging inspection; no staging changes were made.
**Verdict:** **BLOCKED — ADDITIONAL INVESTIGATION REQUIRED**

## Verified staging identity

The Supabase project list and project metadata identify the staging project as:

- **Project name:** `scholars-staging`
- **Project ID/ref:** `aqhktriwaglvvrchxmtd`
- **Region:** `eu-west-1`
- **Status:** `ACTIVE_HEALTHY`
- **Database version:** PostgreSQL 17.11.0.018
- **Project URL:** `https://aqhktriwaglvvrchxmtd.supabase.co`

Production remains `cmdglabohpttgfofcmqc`, named `scholarship-platform`, in the same region, with status `ACTIVE_HEALTHY` and PostgreSQL 17.6.1.155.

## Current staging state

The Supabase table inventory returned no tables for the requested application schemas (`public`, `api`, `private`, `editorial`, and `worker`). The migration inventory returned no migrations. This confirms that staging is not merely missing a few Scholars tables: it has no inspected Scholars application baseline.

The staging database still contains platform-managed schemas/resources. The extension inventory shows platform extensions and a version set that differs from production, including `index_advisor` 0.2.1 versus production 0.2.0, `pg_graphql` 1.6.2 versus production 1.6.1, and `wrappers` 0.6.3 versus production 0.6.2. These differences are not themselves application blockers, but they mean staging is not a byte-for-byte database clone.

The staging security advisor returned no findings in the inspected response. That result should not be interpreted as proof that the future Scholars security design is complete because the application schema is absent.

No staging storage bucket inventory was created or modified. Existing platform resources must be inventoried again immediately before reconstruction. The project identity and empty application state were confirmed before any setup action, satisfying the phase's inspection prerequisite but not authorizing setup.

## Production-to-repository migration reconciliation

Production's migration ledger contains 177 entries through:

- `20261109120215 / correct_airtel_afara_application_route`
- `20261109120725 / reverify_kayode_and_nnpc_snepco_sources`
- `20261109121207 / update_airtel_scholarship_eligibility`

The inspected Scholars baseline contains 129 SQL migration files. The repository has duplicate numeric prefixes, including `0002`, `0004`, `0006`, `0015`, `0021`, `0023`, `0034`, `0035`, `0045`, `0046`, `0052`, `0057`, `0061`, `0062`, `0063`, `0078`, `0087`, `0102`, and `0103`. Numeric ordering alone is therefore not a reliable production mapping key.

### High-confidence or known gaps

| Production ledger item | Repository finding | Reproducibility status |
|---|---|---|
| `20260821182641 / 0001_init` | Content maps to `0001_init.sql` | High confidence |
| `20260821183455 / 0002_harden_functions` | Content maps to `0002_harden_functions.sql` | High confidence |
| `20260824090656 / grant_is_admin_execute_to_authenticated` | No same-named tracked file | Missing source/provenance |
| `20260902181511 / restore_is_admin_execute_for_rls` | No same-named tracked file | Missing source/provenance |
| `20260913160933 / restore_is_admin_policy_execute` | No same-named tracked file | Missing source/provenance |
| `20260907051428 / create_opportunities_and_saved_opportunities` | No same-named file; `opportunities` and saved-opportunity creation exists in the production ledger but not as a matching tracked migration | Missing source/provenance |
| `20260913160132 / lock_admin_flag` | Maps to `0023_lock_admin_flag.sql` | High confidence; duplicate prefix exists |
| `20260916093313 / add_scholarship_discovery_candidates` | No exact same-named file; related discovery migrations exist under duplicate numeric prefixes | Partial/needs content hash mapping |
| `20260928110643 / add_safe_fetch_and_structured_claims` | No exact same-named file; related file exists under a duplicate numeric prefix | Partial/needs content hash mapping |
| `20260916153549 / add_admin_metrics_summary` | Maps to `0045_add_admin_metrics_summary.sql` | High confidence; duplicate prefix exists |
| `20260916153727 / fix_admin_metrics_summary_numeric_pattern` | No distinct same-named tracked file | Missing source/provenance |
| `20261107115338 / security_boundary_remediation` | Maps by content to `20261107130000_security_boundary_remediation.sql` | High confidence; ledger order is authoritative |
| `20261107115403 / resource_center_schema` | Maps by content to `20261107130100_resource_center_schema.sql` | High confidence; ledger order is authoritative |
| Local `0020_add_cycle_events.sql` | No confirmed matching production ledger entry from prior source scan | Unresolved |
| Ledger entries after `20261107115403` | Current production includes three 2026-11-09 entries not present in the stated application baseline | Baseline drift; reconcile before reconstruction |

The repository baseline is therefore not a reproducible production baseline without a ledger-to-file mapping based on content, ordered application records, and the actual migration execution role. Do not manufacture missing SQL files or silently treat the current staging emptiness as a clean reset target.

## Configuration and deployment evidence

The Scholars baseline uses `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` for browser, server-session, and public clients. Server-only code uses `SUPABASE_SERVICE_ROLE_KEY`. The static baseline includes server API routes, cron/integration workers, storage uploads, and public Resource Center reads. Environment variable names were inspected without reading values.

No Vercel deployment or environment configuration was changed. A future staging reconstruction must use a staging-only URL and keys, and must prove that service credentials cannot enter browser bundles or client responses.

## Readiness decision

Staging is **not ready to run the Phase 2.1.2 security suite** because:

1. No Scholars application tables were found in the requested schemas.
2. No staging migration ledger entries were found.
3. The production ledger is ahead of the stated application baseline.
4. Several production migrations have no same-named tracked source file.
5. Duplicate migration prefixes make filename order insufficient.
6. Authenticated test identities and synthetic fixtures do not yet exist.
7. Actual staging PostgREST settings and storage policies require an explicit pre-reconstruction inventory.

The project is healthy and can be used as the named staging target after a reviewed, schema-only reconstruction plan is approved. No setup should be executed during this phase.

## References

[1]: https://github.com/ImperioKDB/Scholars/commit/cf3682ce35912df7b9b9352193630fc404427c7c "Scholars application baseline"
[2]: https://github.com/ImperioKDB/Updates/commit/7f7eb680562b6e89c0172b5534848f2b576002c0 "Phase 2.1.1 audit handoff"
