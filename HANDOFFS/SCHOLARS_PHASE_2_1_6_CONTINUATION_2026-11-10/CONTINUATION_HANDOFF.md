# Scholars — Phase 2.1.6 Continuation Handoff

**Prepared:** 2026-11-10
**Package purpose:** Carry forward the verified Phase 2.1.5 and 2.1.6 state into a new Manus session.
**Current decision:** **BLOCKED — AUTHORIZED CAPTURE NOT AVAILABLE.**
**Safety:** This handoff and export are not authorization to retrieve data, configure secrets, capture production DDL, restore staging, modify Supabase, or deploy.

## Read this first

This package contains the original Phase 2.1.5 task brief, the **latest corrected six Phase 2.1.5 reports**, and all **eight Phase 2.1.6 reports** at the latest remote evidence commit. Check `MANIFEST.sha256` before relying on the ZIP or extracted files. The files under `reports/` are sanitized documentation only; there is no raw schema, credential, database row, student record, storage object, or Vault content in this package.

The repository already has an earlier Phase 2.1.5 export at `HANDOFFS/SCHOLARS_PHASE_2_1_5_HANDOFF_2026-11-10/` and a ZIP with the same stem. That earlier package predates the corrected 2.1.5 reports and the Phase 2.1.6 review. **Use this Phase 2.1.6 package as the current handoff.** Its source materials are at the exact commits listed below.

## Current state and provenance

- **Updates repository:** `ImperioKDB/Updates`, branch `main`.
- **Latest evidence commit included:** `1c6eb532229c8dea0ee84389d5129f22709ea5cd` — `docs: add Phase 2.1.6 capture review`.
- **Corrected Phase 2.1.5 report commit:** `09f54e4b64d2f952d32919ce9eeb11e7e3e343b6` — `docs: refine Phase 2.1.5 schema baseline reports`.
- This package is being published as a later documentation-only commit. On the new session, check `Updates/main` and use its latest commit rather than assuming the hash recorded in this package is still the branch head.
- **Application repository:** `ImperioKDB/Scholars`; `main` was `3deba708e146ceb2aa6846c4691d58ace93795b2` at review time.
- **Compared application baseline:** `cf3682ce35912df7b9b9352193630fc404427c7c`.
- The compare showed three additional, data-oriented migration files at current main and no application-source edits: `20261109130500_correct_airtel_afara_application_route.sql`, `20261109131500_reverify_kayode_and_nnpc_snepco_sources.sql`, and `20261109132500_update_airtel_scholarship_eligibility.sql`. Their matching final migration-ledger versions were observed. They are not recovery of a historical chain and do not prove current production row values.

## Environment identity

| Environment | Supabase project ref | Name | Region | Status | PostgreSQL |
|---|---|---|---|---|---|
| Production | `cmdglabohpttgfofcmqc` | `scholarship-platform` | `eu-west-1` | `ACTIVE_HEALTHY` | 17.6.1.155 |
| Staging | `aqhktriwaglvvrchxmtd` | `scholars-staging` | `eu-west-1` | `ACTIVE_HEALTHY` | 17.11.0.018 |

Production’s previously established migration-ledger count is 180; the latest authorized listing still reached `20261109120215`, `20261109120725`, and `20261109121207`, but the full ledger count was not independently recomputed in the later review. Staging’s migration inventory was empty and its table inventory returned no tables in `public`, `api`, `private`, `editorial`, and `worker`. This does not establish absence of every other object kind and does not authorize using staging as a restore/test target.

Both extension inventories reported the same five installed versions: `pg_stat_statements` 1.11, `pgcrypto` 1.3, `plpgsql` 1.0, `supabase_vault` 0.3.1, and `uuid-ossp` 1.1. Vault contents were not read. Earlier catalog figures (including 45 public tables, 4 public views, 31 security-definer functions) are inventory evidence, not counts of captured portable DDL.

## What Phase 2.1.5 established

The pinned Supabase CLI `2.122.1` was run only in version/help mode. `supabase db dump` has no `--schema-only` flag; schema-only is the default. Declarative generation help supports `--db-url`, `--schema`, `--output-dir`, `--strict-coverage`, and `--experimental`. No database URL was supplied; no dump or declarative tree was generated; no artifact hashes, extraction warnings, pg-delta runtime version, or cross-method comparison exist.

The Supabase MCP session was authenticated but did not expose token scopes and had no PostgREST config GET operation. The supported Management API endpoint requires `rest:read` and `data_api_config_read`; no authorized GET was made in the final review. Production and staging `db_schema`, `db_extra_search_path`, anonymous-role behavior, OpenAPI exposure mode, and other relevant settings remain unknown, not unset. A prior unauthenticated request returned HTTP 401; do not treat it as evidence of configuration values.

## What Phase 2.1.6 added

Phase 2.1.6 used dedicated read-only project, migration, table, extension, and advisor tools, public GitHub metadata, and local CLI help checks. No arbitrary SQL, sensitive production RPC, PostgREST API request, row export, schema extraction, migration, restore, application change, or deployment was performed.

The dedicated security advisor reported (snapshot time 2026-11-10 10:00:20 UTC) 23 `SECURITY DEFINER` functions callable by `anon` and the same 23 callable by `authenticated`; four postgres-owned Resource Center views flagged as security-definer; six RLS-enabled tables with no policies (`announcement_log`, `auth_rate_limits`, `broadcast_delivery_log`, `notification_deliveries`, `visitor_daily_metrics`, and `workflow_jobs`); mutable search paths on `public.catalog_slug` and `public.set_catalog_slug`; and disabled leaked-password protection. These are advisor/configuration findings, **not by themselves proof of a successful exploit or data exposure**. Function bodies, complete ACLs, policies and effective privileges were not re-extracted. Do not blanket-revoke browser grants or invoke sensitive RPCs.

No isolated compatibility test ran. The workspace did not provide `postgres`, `initdb`, `psql`, `pg_dump`, or Docker. Creating another Supabase project was outside authorization. No type generation or application build was run. Existing staging must not be used to work around this blocker.

## Report set in this package

Read `reports/SCHOLARS_PHASE_2_1_6_FINAL_DECISION_AND_NEXT_GATE_2026-11-10.md` first. It contains the latest blocked verdict and next gate. The package also contains:

- `PHASE_2_1_5_BRIEF.txt` — original Phase 2.1.5 instructions.
- `reports/` — six corrected Phase 2.1.5 reports plus eight Phase 2.1.6 reports covering access readiness, PostgREST, capture/integrity, method coverage, security, compatibility/types, isolated tests, and the final decision.
- `SOURCE_REPOSITORY_STATE.txt` — source revisions and package lineage.
- `NEXT_SESSION_PROMPT.txt` — standalone continuation prompt.
- `MANIFEST.sha256` — SHA-256 checksums for package files, excluding the manifest itself.

## Next gate — preserve the blocked status until prerequisites exist

1. Ask an authorized project administrator for an approved non-writing database URL delivered through a secure secret-injection mechanism, not chat or Git. Verify target ref/endpoint and the effective privileges without printing the URL. If its restrictions cannot be established, stop.
2. Obtain sanitized PostgREST evidence for both project refs using verified `rest:read` and `data_api_config_read` access, or an approved administrator export. Do not grant secret-read scope. Omit `jwt_secret`, credentials, and tokens.
3. Confirm approved schema selection and separate handling for `auth`, `storage`, extensions, and platform-managed objects. Do not assume `public` captures all dependencies.
4. Only after access is authorized, run pinned CLI `2.122.1` to generate a strict-coverage declarative tree and an independent default schema-only dump. Keep raw files private; log exact commands, exit codes, warnings, output inventories, and SHA-256 hashes.
5. Scan the private artifacts for data/DML, bucket rows, credentials, Vault material, roles/ownership, platform internals, and unsupported objects. Reconcile object coverage with prior catalog and dependency-matrix evidence. Get independent security review of actual definitions, privileges, RLS, views, functions/search paths, managed-schema objects, and destination creator defaults.
6. Obtain a genuinely isolated local PostgreSQL/Supabase test environment or separate approval for a disposable environment. Restore only a reviewed schema with synthetic fixtures, generate types, and run role-specific tests there.
7. Existing staging restoration, any migration/privilege/PostgREST change, production change, and deployment each require separate explicit approval. Phase 2.1.5 and 2.1.6 provide none.
8. Publish only sanitized reports and verify the commit and changed paths. Never force-push or publish raw artifacts.

## Ready-to-use prompt for a new Manus session

> Continue the Scholars controlled schema-baseline work from the latest Phase 2.1.6 review. Start by reading this `CONTINUATION_HANDOFF.md`, `MANIFEST.sha256`, and all 14 report files in `reports/`; then check the latest `ImperioKDB/Updates` main commit because it may have advanced beyond the package. Current verdict is **BLOCKED — AUTHORIZED CAPTURE NOT AVAILABLE**. No production schema dump or declarative tree exists; CLI 2.122.1 was checked only in help mode; PostgREST scopes/config remain unavailable; no isolated database/test environment exists; and staging is not authorized for restoration. Fresh security-advisor findings are documented, but they do not establish exploitability. Do not request credentials in chat, populate `SUPABASE_DB_URL`, run an extraction workflow, access production rows, invoke sensitive RPCs, alter Supabase, restore staging, change privileges, deploy, or force-push. Resume only after an administrator provides a verified non-writing connection and sanitized scoped PostgREST evidence through approved channels. Follow the next-gate steps above, keep raw artifacts private, and publish sanitized updates to `Updates` only.
