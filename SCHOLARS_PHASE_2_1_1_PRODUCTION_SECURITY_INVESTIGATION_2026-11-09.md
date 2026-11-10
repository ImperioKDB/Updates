# Scholars Phase 2.1.1 — Production Security Investigation

**Status:** Read-only investigation complete; remediation not authorized or applied.
**Severity:** **High — production least-privilege blocker; certain RPC disclosures are confirmed by ACL/body metadata, while table-route and destructive HTTP access were not tested.**
**Baseline:** Updates commit [`abb19a697703aab91f783b8e5258acebf35bf02a`](https://github.com/ImperioKDB/Updates/commit/abb19a697703aab91f783b8e5258acebf35bf02a), especially `SCHOLARS_PHASE_2_1_EVIDENCE_RETENTION_AND_SECURITY_POLICY_2026-11-08.md`.
**Production:** Supabase project `cmdglabohpttgfofcmqc`, `eu-west-1`; metadata sampled `2026-11-09 10:35:19 UTC`, advisor sampled `10:34:53 UTC`.
**Source revisions:** Scholars main `cf3682ce35912df7b9b9352193630fc404427c7c`; Updates main was fast-forwarded to `912158f9a7043aa744531275d78d44d164c9c05f` before staging.
**Method:** Read-only Supabase MCP metadata SQL, migration ledger/project metadata/advisors, plus static repository review. Inspection SQL ran as `postgres`; migration ledger has 177 entries, latest version `20261107115403`. No application rows, personal data, secrets, credentials, API responses, or live forms were read or tested.

## 1. Executive summary

The 2026-11-08 Phase 2.1 baseline security finding remains present in production. Each of the 11 in-scope tables has direct grants to `anon`, `authenticated`, and `service_role` equivalent to `arwdDxtm`: INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, and MAINTAIN. All reviewed relations are owned by `postgres`. RLS is enabled but not forced on all 11. RLS constrains ordinary row operations; it does not provide column projection and does not filter TRUNCATE.

Supabase's current security advisor reports 23 anon-callable and 23 authenticated-callable `SECURITY DEFINER` functions through public `/rest/v1/rpc` resources. A full live catalog review found 31 public definer routines total: 23 browser-executable and eight service-role-only. Therefore public RPC exposure is confirmed, while the exact PostgREST exposed-schema allowlist and successful direct table-route requests remain unverified; no HTTP call was made.

The most material public-read concern is whole-row visibility: `scholarships` and `opportunities` have verified-row SELECT policies and include `research_notes` described by migration comments as admin-only; `cycle_events` has `USING (true)` and includes `note` and `captured_by`. Table SELECT permissions are not column-restricted. Next.js catalogue routes use explicit projections, but those server-side projections do not constrain independent PostgREST table requests if the tables are exposed.

Two callable functions have specific exposure defects. `public.is_admin(uuid)` is SECURITY DEFINER, owned by `postgres`, and EXECUTE is granted to PUBLIC; it accepts any UUID and returns that profile's admin bit, enabling admin-status enumeration. `public.get_admin_metrics_summary(timestamptz)` is executable by anon; its `outcome_rollup` counts all application statuses independently of the admin predicate applied to the event aggregation. This can disclose aggregate status counts, not applicant rows or answers. `get_scholarship_social_proof` exposes exact saved/applicant/discussion/view counts to the public; the five-student threshold applies only to institution names. `get_trending_scholarship_ids` has caller-controlled threshold/window without a positive minimum; threshold 1 or lower can disclose IDs associated with a single save. `get_scholarship_discussions` returns an online indicator for non-anonymous authors based on a 10-minute last-seen window. These public-data choices need explicit approval.

Six other public tables are flagged by Supabase as RLS-enabled with no policies. Five—`announcement_log`, `auth_rate_limits`, `broadcast_delivery_log`, `notification_deliveries`, and `workflow_jobs`—also have full anon/auth table ACLs. Default-deny RLS prevents ordinary browser-role row access when no policy matches, but TRUNCATE is outside RLS; that is a database-level privilege concern, not proof of successful HTTP truncation. `visitor_daily_metrics` has no anon/auth table ACL.

**Layered root cause:** (1) the 2026-11-07 remediation changes future defaults for objects created by `postgres` only and explicitly leaves existing ACLs untouched; (2) live `supabase_admin` default ACLs still grant browser roles broad table, sequence, and function rights; (3) several function grants are explicitly broad, especially `is_admin(uuid)` to PUBLIC; and (4) `get_admin_metrics_summary` revoking PUBLIC did not revoke a separate direct anon grant. The exact historical source of each table ACL cannot be proven without prior ACL snapshots/out-of-band DDL history; legacy defaults are plausible but not confirmed for every object.

**Readiness:** Not ready for production implementation. Current `scholars-staging` had no Scholars migration baseline or application tables in `public`; it is not a test-ready clone. Resolve exact PostgREST settings and route behavior, migration runner/role, missing/mismatched source mappings, public field decisions, existing direct `.from()`/`.rpc()` compatibility, and synthetic staging setup first.

## 2. Confirmed table, RLS, and column facts

For every in-scope table the direct ACL is `{postgres=arwdDxtm/postgres,anon=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres}`. `has_table_privilege()` independently confirms effective browser-role rights. The only actual column ACL found was authenticated UPDATE on `notifications.read_at`; it is not restrictive while table-wide UPDATE remains granted. `anon` and `authenticated` have `USAGE` but not `CREATE` on `public`.

All 11 tables have RLS enabled and `FORCE ROW LEVEL SECURITY` disabled. Core policy behavior:

- `scholarships`: verified rows, admin rows, and the caller's own saved/applied rows are SELECT-visible; mutations require admin. Whole-row SELECT includes `research_notes` and other internal metadata.
- `scholarship_rules`: SELECT follows a verified parent scholarship or admin status; mutations require admin.
- `opportunities`: anon/auth can SELECT verified rows; admin-only mutations. `research_notes` is not excluded by this policy.
- `cycle_events`: SELECT is `USING (true)`; authenticated writes require admin. The row includes `note` and `captured_by`.
- `applications`: own-row SELECT/INSERT/UPDATE/DELETE; admins can SELECT. Next routes authenticate and scope to the user's ID, but that does not remove the direct PostgREST surface.
- `saved_scholarships` / `saved_opportunities`: own-row operations plus admin SELECT; saved opportunities also has own-row UPDATE.
- `notifications`: own-row SELECT/UPDATE; app updates `read_at`, but table-wide UPDATE lets a direct client attempt other columns on its own row.
- `scholarship_discovery_candidates` / `scholarship_discovery_candidate_claims`: admin SELECT/UPDATE; snapshots admin SELECT. RLS denies ordinary student row access, but broad table privileges and non-RLS privileges remain.

The six adjacent no-policy objects are listed above; the five with broad browser ACLs need correction even though row reads/writes default-deny. These roles cannot use ordinary RLS policies to bypass no-policy default deny, but TRUNCATE is not row-filtered. No target-owned serial sequences were found; IDs use UUID defaults.

See the [privilege/API matrix](SCHOLARS_PHASE_2_1_1_PRIVILEGE_AND_API_EXPOSURE_MATRIX_2026-11-09.md) for per-table ACL/RLS/API distinctions, adjacent tables, views, and complete function inventory.

## 3. Functions and views

The live catalog has 42 public functions; 31 use `SECURITY DEFINER`. All 31 are owned by `postgres`, with a pinned `search_path` of empty string or `public` (one includes `auth`). The 23 browser-executable definer names are: `check_achievements`, `check_application_submitted`, `check_community_discussion_achievements`, `check_community_reaction_achievements`, `check_first_action_achievements`, `check_referral_completion`, `get_admin_metrics_summary`, `get_auth_confirmation_email_analytics`, `get_community_contributor_profile`, `get_daily_visitor_metrics`, `get_provider_analytics`, `get_public_contributor_profile`, `get_scholarship_discussions`, `get_scholarship_social_proof`, `get_trending_scholarship_ids`, `handle_new_user`, `is_admin`, `notify_discussion_helpful`, `notify_discussion_reply`, `publish_discovery_candidate`, `run_achievement_checks`, `sync_scholarship_discussion_helpful_count`, and `sync_waec_summary_fields`.

Eleven are trigger-returning functions with unnecessary browser EXECUTE. Catalog ACLs are confirmed, but actual HTTP invocation is unverified and may be rejected by PostgREST because they return `trigger` and require trigger context. The remaining 12 return data or act: five analytics/admin-related functions (`get_admin_metrics_summary`, confirmation analytics, visitor metrics, provider analytics, `is_admin`); two public contributor-profile functions; public discussions/social proof/trending IDs; discovery publication; and `run_achievement_checks(uuid)`. Admin analytics functions check `is_admin(auth.uid())` in their bodies, except the outcome-count path in `get_admin_metrics_summary`. `publish_discovery_candidate` checks current actor, approval, quality, verification, freshness, claims and URL, then creates an initially unverified scholarship plus rules/event. `run_achievement_checks` is idempotent and fact-based but accepts an arbitrary profile UUID without caller/target equality, enabling unauthorized cross-user side effects (not arbitrary XP fabrication).

Eight definer functions are postgres/service_role-only: `award_xp`, `check_rate_limit`, `claim_notification_delivery`, `claim_workflow_job`, `complete_workflow_job`, `flag_expired_opportunities`, `record_visitor_page_view`, and `seed_scholarship_prompts`. Preserve server-only intent; no service credential was read.

Four Resource Center views—`resource_public_editorial_identities`, `resource_public_categories`, `resource_public_articles`, and `resource_public_article_categories`—grant SELECT to anon/auth. They are postgres-owned, have `security_barrier=true`, and lack `security_invoker=true`; definitions filter active/published rows and return projections, but owner execution governs underlying access/RLS. `security_barrier` is not invoker security. The advisor flags them as security-definer views. Review public author fields and `last_reviewed_at` for approval.

A separate catalog query found 10 public non-definer functions executable by anon and/or authenticated: two pure calculations (`calculate_profile_completeness(profiles)`, `catalog_slug(text,text)`); authenticated-only `replace_waec_results(uuid,jsonb)`, which requires `auth.uid()=p_profile_id`; and seven trigger routines (`set_catalog_slug`, `set_profile_completeness`, `set_updated_at`, `sync_xp_total`, `touch_scholarship_discussion_updated_at`, `touch_scholarship_prompt_updated_at`, `validate_scholarship_discussion_parent`). Trigger ACLs are unnecessary, but they are not SECURITY DEFINER; HTTP invocation was not tested. No public function named `exec_sql` exists in any schema in the live catalog.

## 4. App/API boundary and migration provenance

The app's catalogue routes `app/api/scholarships/route.ts` and `app/api/opportunities/route.ts` use explicit projections. Student application routes (`app/api/applications/route.ts`, `app/api/applications/[id]/route.ts`, draft/check-in/click routes) authenticate and scope ordinary operations to the current user; `app/api/notifications/route.ts` similarly scopes rows. `lib/supabase/service.ts` uses server-only `SUPABASE_SERVICE_ROLE_KEY`; `lib/admin/guard.ts` checks user/admin. These app-layer controls are not substitutes for database ACL/RPC controls. No client-only `.from()` call to the audited tables was found in the reviewed static search; server routes/pages do query them.

RPC call sites include `lib/scholarship-community.ts` (discussion/social proof), `app/dashboard/page.tsx` (trending), `app/community/contributors/[profileId]/page.tsx` and `app/api/community/contributors/[discussionId]/route.ts` (public contributor projections), `app/admin/page.tsx` (admin metrics), `app/admin/analytics/page.tsx` and `app/api/admin/analytics/route.ts` (admin analytics), `app/api/admin/discovery/route.ts` (publication), and `app/api/profile/waec/route.ts` (self-scoped WAEC replacement). Worker/cron functions are called through service clients. The API surface remains independently callable according to database ACLs.

`app/api/admin/schema-check/route.ts` calls `rpc('exec_sql',...)` after rate limit and `assertAdmin`, but the deployed catalog contains no `exec_sql` function in any schema. The route comments that it may be absent and falls back to column probes. No SQL-execution RPC is present in this snapshot; this route was not invoked.

| Production ledger version/name | Repository mapping / finding |
|---|---|
| `20260821182641 / 0001_init`; `20260821183455 / 0002_harden_functions` | High-confidence matches to `0001_init.sql` and `0002_harden_functions.sql`. |
| `20260824090656 / grant_is_admin_execute_to_authenticated`; `20260902181511 / restore_is_admin_execute_for_rls`; `20260913160933 / restore_is_admin_policy_execute` | Applied ledger statements verified; no dedicated same-named tracked files. Regrants support RLS policy execution and make helper callable. |
| `20260907051428 / create_opportunities_and_saved_opportunities` | Applied table creation exists in ledger; no matching tracked CREATE TABLE migration found in inspected Scholars commit; source gap. |
| `20260913160132 / lock_admin_flag` | High-confidence match to `0023_lock_admin_flag.sql`; local file grants `is_admin(uuid)` to PUBLIC at lines 110–112. |
| `20260916093313 / add_scholarship_discovery_candidates`; `20260928110643 / add_safe_fetch_and_structured_claims` | High-confidence matches to `0042_add_scholarship_discovery_candidates.sql` and `0062_add_safe_fetch_and_structured_claims.sql`. |
| `20260916153549 / add_admin_metrics_summary`; `20260916153727 / fix_admin_metrics_summary_numeric_pattern` | First maps to `0045_add_admin_metrics_summary.sql`; second has no distinct matching file. Revoking PUBLIC does not revoke separate direct anon grant. |
| `20261107115338 / security_boundary_remediation`; `20261107115403 / resource_center_schema` | High-confidence content matches `20261107130000_security_boundary_remediation.sql` and `20261107130100_resource_center_schema.sql`; ledger order is authoritative. |
| Local `0020_add_cycle_events.sql` | No matching CREATE TABLE statement found in deployed ledger scan; exact production application/version unresolved. |

Live `pg_default_acl` for creator role `postgres` limits future public tables/functions/sequences to postgres/service_role. `supabase_admin` defaults still grant browser roles broad table/sequence rights and function EXECUTE. The checked-in security remediation changes defaults for `postgres` only and explicitly leaves existing objects untouched. The current inspection role is postgres; ledger does not prove executor identity for every historical migration. Direct table ACLs are verified; exact historical source cannot be proven without ACL snapshots/out-of-band DDL history.

## 5. Role graph, severity, and readiness

`anon` and `authenticated` are NOLOGIN, NOSUPERUSER, NOBYPASSRLS and have no membership path to service_role, postgres, or supabase_admin. Their broad ACLs are direct grants, not inherited. PostgREST `authenticator` is LOGIN/NOINHERIT and a member of anon/authenticated/service_role to switch roles for API credentials; this does not mean browser roles can become service_role. `service_role` is NOLOGIN and BYPASSRLS; `postgres` is LOGIN and BYPASSRLS; `supabase_admin` is superuser/BYPASSRLS. Platform membership edges involving `supabase_realtime_admin` and `supabase_storage_admin` were seen; do not alter platform-managed edges in an app migration.

High-priority findings: direct browser grants including TRUNCATE on all 11 tables; whole-row public-read policies for catalogue/cycle tables; PUBLIC admin-status oracle; anon application-status aggregate; public exact social-proof metrics and low-threshold trending; 23 browser-executable definer functions; and broad `supabase_admin` defaults. No row contents were read and no successful exploit was demonstrated. Table route availability is conditional on exposed-schema configuration; advisor confirms an RPC surface, but no HTTP calls were made.

Before implementation, resolve exposed schemas/route behavior; identify migration executor; map missing production source; approve public field-by-field projections (research notes, cycle notes/actor IDs, competitiveness values, aggregates, identity/presence); decide role separation; correct `supabase_admin` defaults through supported controls; and bootstrap staging with schema plus synthetic fixtures. Then run JWT-based API tests, verify ACL/default/function/view state, migrate app calls to the intended boundary, pass Next/Vercel Preview, and obtain separate production migration approval.

## 6. No-change statement and companion documents

This was read-only inspection and documentation. No Scholars source, SQL migration, data, grants, defaults, RLS, functions, storage, staging schema, or Vercel deployment changed. No secrets were read; no destructive/write probes were attempted. `scholars-staging` is not currently a test-ready clone.

- [Privilege and API exposure matrix](SCHOLARS_PHASE_2_1_1_PRIVILEGE_AND_API_EXPOSURE_MATRIX_2026-11-09.md)
- [Least-privilege target design](SCHOLARS_PHASE_2_1_1_LEAST_PRIVILEGE_TARGET_DESIGN_2026-11-09.md)
- [Security remediation and rollback plan](SCHOLARS_PHASE_2_1_1_SECURITY_REMEDIATION_AND_ROLLBACK_PLAN_2026-11-09.md)
- [Security test specification](SCHOLARS_PHASE_2_1_1_SECURITY_TEST_SPECIFICATION_2026-11-09.md)
