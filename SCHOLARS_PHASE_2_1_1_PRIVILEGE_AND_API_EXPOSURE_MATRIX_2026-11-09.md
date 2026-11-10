# Scholars Phase 2.1.1 — Privilege and API Exposure Matrix

**Snapshot:** Production Supabase project `cmdglabohpttgfofcmqc` (`eu-west-1`), metadata sampled 2026-11-09 10:35 UTC; advisor sampled 10:34 UTC.
**Code baseline:** Scholars `cf3682ce35912df7b9b9352193630fc404427c7c`; Phase 2.1 Updates reference `abb19a697703aab91f783b8e5258acebf35bf02a`.
**Scope:** No application rows, secrets, or live API responses were read; no destructive/write probes were performed.

## 1. Interpretation and certainty

All 11 requested tables have direct `relacl` grants to `anon`, `authenticated`, and `service_role` equal to `{postgres=arwdDxtm/postgres,anon=arwdDxtm/postgres,authenticated=arwdDxtm/postgres,service_role=arwdDxtm/postgres}`; owner/grantor is `postgres`. Effective `has_table_privilege` confirms INSERT, SELECT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER, and MAINTAIN for both browser roles. RLS is enabled and not forced on all 11; it governs ordinary row operations, not columns or TRUNCATE.

The advisor confirms public `/rest/v1/rpc` function resources. Exact deployed PostgREST exposed-schema settings and direct table-route HTTP success were not verified. Thus SQL ACLs are confirmed; table-route accessibility is conditional/unverified; no arbitrary SQL/TRUNCATE API was established or tested.

Role metadata confirms `anon` and `authenticated` are NOLOGIN/NOSUPERUSER/NOBYPASSRLS and have no membership path to service_role, postgres or supabase_admin. Browser table grants are direct, not inherited. `authenticator` is LOGIN/NOINHERIT and is a member of anon/authenticated/service_role for PostgREST role switching. `service_role` and `postgres` have BYPASSRLS; `supabase_admin` is superuser.

## 2. In-scope tables

| Table | Direct ACL / owner | RLS policies and row behavior | Exposure / target action |
|---|---|---|---|
| `public.scholarships` | `arwdDxtm` anon/auth/service; owner postgres | RLS on, not forced. SELECT verified rows, admin rows, caller's own saved/applied rows; writes require admin. | Whole-row verified SELECT includes `research_notes`, `created_by`, competitiveness/internal metadata. Public table route conditional. Use explicit allowlist projection; remove broad direct DML. |
| `public.scholarship_rules` | Same | SELECT if parent verified or caller admin; mutations admin-only. | Verified eligibility rules may be intentional; expose only approved normalized fields. |
| `public.opportunities` | Same | anon/auth may SELECT verified rows; admin-only writes. | Whole rows include `research_notes`/author metadata; deployed creation comment says research notes admin-only. Public view must omit them. |
| `public.cycle_events` | Same | SELECT `USING (true)`; authenticated writes admin-only. | Row includes `note` and `captured_by`; do not publish internal narrative/actor ID by default. |
| `public.applications` | Same | Own-row SELECT/INSERT/UPDATE/DELETE (`auth.uid()=profile_id`), admin SELECT. | Ordinary JWT rows remain owner-scoped by RLS; Next routes also scope to user. Direct calls bypass route validation but not RLS. Keep private; restrict columns and ownership fields. |
| `public.saved_scholarships` | Same | Own-row SELECT/INSERT/DELETE and admin SELECT. | Raw save activity is private. Preserve only owner-scoped application flow. |
| `public.saved_opportunities` | Same | Own-row SELECT/INSERT/DELETE/UPDATE and admin SELECT. | Raw save activity private; remove unused update rights. |
| `public.notifications` | Same; authenticated column UPDATE on `read_at` also exists | Own-row SELECT/UPDATE. | App uses `read_at`, but table UPDATE permits attempts on other columns of own rows. Revoke table-wide UPDATE; preserve only `read_at` or narrow RPC. |
| `public.scholarship_discovery_candidates` | Same | Admin SELECT/UPDATE; no ordinary public row policy. | Student/anon row access denied by RLS; broad TRUNCATE ACL is outside RLS. Publication RPC separate. Move to non-exposed schema/editor API. |
| `public.scholarship_discovery_candidate_claims` | Same | Admin SELECT/UPDATE. | Internal evidence/claims; RLS denies ordinary rows. Keep evidence private and role-scoped. |
| `public.scholarship_discovery_fetch_snapshots` | Same | Admin SELECT only. | Fetch URL/redirect/hash/status metadata; keep private and retention-limited. |

`arwdDxtm` means INSERT (`a`), SELECT (`r`), UPDATE (`w`), DELETE (`d`), TRUNCATE (`D`), REFERENCES (`x`), TRIGGER (`t`), MAINTAIN (`m`). The only actual column-level ACL discovered was authenticated UPDATE on `notifications.read_at`; table-wide UPDATE defeats that narrow distinction. `anon`/`authenticated` have public schema USAGE but no CREATE. Target identifiers use UUID defaults; no target-owned serial sequences found.

## 3. Adjacent no-policy objects flagged by advisor

| Object | anon/auth ACL | RLS | Assessment |
|---|---|---|---|
| `announcement_log` | Full `arwdDxtm` | Enabled, no policies | Default-deny ordinary rows; broad non-RLS grants remain. |
| `auth_rate_limits` | Full `arwdDxtm` | Enabled, no policies | Migration describes server-only use; row access default-deny; broad ACL remains. |
| `broadcast_delivery_log` | Full `arwdDxtm` | Enabled, no policies | Default-deny rows; broad ACL remains. |
| `notification_deliveries` | Full `arwdDxtm` | Enabled, no policies | Internal queue; default-deny rows; TRUNCATE is not RLS-filtered. |
| `workflow_jobs` | Full `arwdDxtm` | Enabled, no policies | Worker queue; default-deny rows; broad ACL remains. |
| `visitor_daily_metrics` | No anon/auth table ACL | Enabled, no policies | No browser table grant; advisor flag alone is not exposure. |

The first five belong in the correction inventory. Worker functions `claim_notification_delivery`, `claim_workflow_job`, and `complete_workflow_job` are service_role/postgres-only. RLS protects row access; it does not substitute for revoking unnecessary object privileges.

## 4. Views

| View | Owner/options | anon/auth SELECT | Definition finding |
|---|---|---|---|
| `resource_public_editorial_identities` | postgres; `security_barrier=true`, no `security_invoker` | Yes | Active identities and allowlisted display fields; advisor flags owner-execution semantics. |
| `resource_public_categories` | postgres; security barrier, no invoker | Yes | Active category fields. |
| `resource_public_articles` | postgres; security barrier, no invoker | Yes | Published content, URLs/images, author fields, publish/review dates. Review author and `last_reviewed_at` approval. |
| `resource_public_article_categories` | postgres; security barrier, no invoker | Yes | Active categories joined to published articles. |

`security_barrier` governs predicate reordering; it is not `security_invoker` and does not cause underlying RLS to run as the API caller. These public projections are intentional but require JWT-based positive/negative tests and field-level approval.

## 5. Complete SECURITY DEFINER inventory

The live catalog returned 42 public functions; 31 are `SECURITY DEFINER`. All 31 are postgres-owned and pin `search_path` to empty or `public` (one includes `auth`). Exactly 23 have effective EXECUTE for both anon and authenticated; eight are service-role-only. The advisor independently reports the 23 browser-callable subset. SQL ACL is confirmed; HTTP invocation for trigger-returning functions is unverified.

### 5.1 Browser-executable functions (23)

| Function | ACL | Data/side effect and assessment |
|---|---|---|
| `get_admin_metrics_summary(timestamptz)` | anon + authenticated direct | Returns aggregate JSON. `outcome_rollup` counts all application statuses outside the admin predicate applied to event metrics. Confirmed aggregate disclosure path if anon/student calls; not applicant rows/answers. |
| `get_auth_confirmation_email_analytics(timestamptz,timestamptz)` | anon + authenticated direct | Admin guard before query; returns totals, daily metrics, recent request metadata/domain/confirmation timing (not email address). Over-granted, but no protected output proven for non-admin. |
| `get_daily_visitor_metrics(timestamptz,timestamptz)` | anon + authenticated direct | Admin guard and date validation; daily visitor/page aggregates. |
| `get_provider_analytics(timestamptz,timestamptz,uuid)` | anon + authenticated direct | Admin guard; sensitive signup/retention/activation, demographic, acquisition, saves/application/status and funnel aggregates. |
| `is_admin(uuid)` | PUBLIC (inherited anon/auth) | Definer query returns any supplied profile's `is_admin` bit; confirmed admin-status oracle. Replace with no-argument current-user helper after policy callers migrate. |
| `get_community_contributor_profile(uuid)` | anon + authenticated direct | Returns ID/name/institution/community bio/role/contribution count/avatar for qualifying published non-anonymous author; no email/phone. Requires consent/product approval. |
| `get_public_contributor_profile(uuid)` | anon + authenticated direct | Similar public identity projection for qualifying profile. Verify consent and field allowlist. |
| `get_scholarship_discussions(uuid,text,integer)` | PUBLIC + anon/auth direct | Published content plus non-anonymous name/avatar/role and `author_is_online` based on last-seen within 10 minutes. Anonymous identity suppressed; online presence needs approval. |
| `get_scholarship_social_proof(uuid)` | PUBLIC + anon/auth direct | Exact save/applicant/discussion/view counts for verified scholarship. Institution names only have threshold >=5; exact counts have no small-cohort threshold. Product approval needed. |
| `get_trending_scholarship_ids(integer,integer)` | anon + authenticated direct | Caller-supplied save threshold/window; no positive/minimum clamp. Threshold 1 reveals single-save IDs; 0/negative returns any scholarship with a save. Bound or restrict. |
| `publish_discovery_candidate(uuid)` | anon + authenticated direct | Definer write; actor is `auth.uid()` and null/non-admin rejected. Requires approved, quality-ready, verified/current evidence, confirmed claims and URL. Creates an unverified scholarship, compiled rules, event; copies evidence into internal notes. Retain only for intended editor/admin capability; test atomicity. |
| `run_achievement_checks(uuid)` | PUBLIC + anon/auth | Recomputes fact-based/idempotent achievements/XP for arbitrary UUID; lacks caller/target equality. Unauthorized cross-user side effect, not arbitrary XP fabrication. Make service/trigger-only or self-only. |
| `check_achievements()` | PUBLIC + anon/auth; trigger-returning | Calls achievement recompute on XP event. Trigger-only; direct RPC unverified, direct EXECUTE unnecessary. |
| `check_application_submitted()` | PUBLIC + anon/auth; trigger-returning | Awards XP on submitted transition. Preserve trigger, remove browser EXECUTE after regression tests. |
| `check_community_discussion_achievements()` | PUBLIC + anon/auth; trigger-returning | Recomputes discussion author's achievements. |
| `check_community_reaction_achievements()` | PUBLIC + anon/auth; trigger-returning | Recomputes reaction actor and discussion author. |
| `check_first_action_achievements()` | PUBLIC + anon/auth; trigger-returning | Recomputes achievement for triggering profile. |
| `check_referral_completion()` | PUBLIC + anon/auth; trigger-returning | Awards referral XP on completion threshold. |
| `handle_new_user()` | PUBLIC + anon/auth; trigger-returning | Creates profile from Auth NEW row. |
| `notify_discussion_helpful()` | PUBLIC + anon/auth; trigger-returning | Inserts notification for discussion author on reaction. |
| `notify_discussion_reply()` | PUBLIC + anon/auth; trigger-returning | Notifies parent author; metadata includes parent ID and anonymous flag. |
| `sync_scholarship_discussion_helpful_count()` | PUBLIC + anon/auth; trigger-returning | Recalculates helpful count from reaction rows. |
| `sync_waec_summary_fields()` | PUBLIC + anon/auth; trigger-returning | Reads WAEC rows and updates profile summary fields. |

These 11 trigger-returning functions have unnecessary EXECUTE grants. PostgREST may reject normal RPC invocation because they return `trigger` and have no trigger context; no HTTP call was made. Preserve trigger behavior when revoking direct browser grants in staging.

### 5.2 Service-role-only definer routines (8)

| Function | ACL | Intended behavior |
|---|---|---|
| `award_xp(uuid,text,integer,text,jsonb)` | postgres + service_role | Validates events/points, daily share cap, idempotent ledger. |
| `check_rate_limit(text,integer,integer)` | postgres + service_role | Server-side rate counter; validate inputs at caller. |
| `claim_notification_delivery(uuid,timestamptz)` | postgres + service_role | Leases an eligible outbox row. |
| `claim_workflow_job(text,timestamptz)` | postgres + service_role | Claims eligible job with locking. |
| `complete_workflow_job(uuid,boolean,jsonb,jsonb,timestamptz)` | postgres + service_role | Records worker result/retry/dead-letter state. |
| `flag_expired_opportunities()` | postgres + service_role | Flags expired verified rows and queues admin notification. |
| `record_visitor_page_view(text,timestamptz)` | postgres + service_role | Validates visitor key and updates metrics. |
| `seed_scholarship_prompts()` | postgres + service_role; trigger-returning | Adds default prompts on verification transition. |

Keep service-role-only unless replaced by a dedicated least-privilege worker role. `service_role` stays server-side.

## 6. Non-definer API-executable functions (10)

Separate live catalog query found 10 public functions with anon and/or authenticated EXECUTE that are not SECURITY DEFINER.

| Function | Browser ACL | Assessment |
|---|---|---|
| `calculate_profile_completeness(profiles)` | anon + authenticated | IMMUTABLE calculation over caller-supplied composite; no stored profile query. |
| `catalog_slug(text,text)` | anon + authenticated | Pure slug computation on supplied inputs. |
| `replace_waec_results(uuid,jsonb)` | authenticated only | Invoker-security; requires `auth.uid()=p_profile_id` before replacing own WAEC rows. Preserve/test; app call `app/api/profile/waec/route.ts:86-92`. |
| `set_catalog_slug()` | PUBLIC + anon/auth; trigger-returning | Trigger-only. |
| `set_profile_completeness()` | PUBLIC + anon/auth; trigger-returning | Trigger-only. |
| `set_updated_at()` | PUBLIC + anon/auth; trigger-returning | Trigger-only. |
| `sync_xp_total()` | PUBLIC + anon/auth; trigger-returning | Recomputes XP total for trigger profile, invoker-security. |
| `touch_scholarship_discussion_updated_at()` | PUBLIC + anon/auth; trigger-returning | Trigger-only. |
| `touch_scholarship_prompt_updated_at()` | PUBLIC + anon/auth; trigger-returning | Trigger-only. |
| `validate_scholarship_discussion_parent()` | PUBLIC + anon/auth; trigger-returning | Validates reply parent scholarship, trigger-only. |

The seven trigger functions have unnecessary browser EXECUTE but are not definer functions; actual RPC invocation was not tested. No public function `exec_sql` exists in any schema. The app schema-check route's attempted call is not a current SQL execution path.

## 7. Roles and default ACLs

| Role | Flags / grants | Boundary |
|---|---|---|
| `anon` | NOLOGIN/NOSUPERUSER/NOBYPASSRLS; public USAGE/no CREATE; direct broad table ACLs; 23 definer functions effective. | RLS applies to ordinary row operations. |
| `authenticated` | NOLOGIN/NOSUPERUSER/NOBYPASSRLS; direct broad table ACLs; 23 definer functions effective. | No membership in service_role; direct API still bypasses Next route checks. |
| `authenticator` | LOGIN/NOINHERIT; member of anon/authenticated/service_role. | PostgREST role switch for API JWT/credentials; not a browser role. |
| `service_role` | NOLOGIN/BYPASSRLS; broad target ACLs; worker RPCs. | Server-side credential only. |
| `postgres` | LOGIN/BYPASSRLS; owner/grantor; postgres defaults exclude browser roles. | Current inspection role; historical migration executor not proven. |
| `supabase_admin` | SUPERUSER/BYPASSRLS; default ACLs still grant browser roles. | Platform role; adjust only through supported admin path. |

`pg_default_acl` for `postgres` public schema limits future tables/functions/sequences to postgres/service_role. `supabase_admin` defaults continue granting anon/auth broad table/sequence rights and function EXECUTE. Defaults apply only to objects created by that role; they do not fix existing ACLs. Platform edges involving `supabase_realtime_admin` and `supabase_storage_admin` were observed; no browser-role path to privileged roles exists. Do not modify platform-managed memberships in app migrations.

## 8. Migration and root-cause map

| Production ledger version/name | Repository mapping / finding |
|---|---|
| `20260821182641 / 0001_init`; `20260821183455 / 0002_harden_functions` | High-confidence matches to `0001_init.sql` / `0002_harden_functions.sql`. |
| `20260824090656 / grant_is_admin_execute_to_authenticated`; `20260902181511 / restore_is_admin_execute_for_rls`; `20260913160933 / restore_is_admin_policy_execute` | Deployed ledger statements verified; no dedicated same-name tracked files. Regrants support policy execution and widen helper reachability. |
| `20260907051428 / create_opportunities_and_saved_opportunities` | Deployed ledger creation exists; no matching CREATE TABLE migration found in checked-out repo. Source provenance gap. |
| `20260913160132 / lock_admin_flag` | High-confidence match to `0023_lock_admin_flag.sql`; local file grants `is_admin(uuid)` to PUBLIC at lines 110–112. |
| `20260916093313 / add_scholarship_discovery_candidates`; `20260928110643 / add_safe_fetch_and_structured_claims` | High-confidence matches to `0042_add_scholarship_discovery_candidates.sql` and `0062_add_safe_fetch_and_structured_claims.sql`. |
| `20260916153549 / add_admin_metrics_summary`; `20260916153727 / fix_admin_metrics_summary_numeric_pattern` | First maps to `0045_add_admin_metrics_summary.sql`; second has no distinct matching file. Revoking PUBLIC does not revoke direct anon grant. |
| `20261107115338 / security_boundary_remediation`; `20261107115403 / resource_center_schema` | High-confidence content matches `20261107130000_security_boundary_remediation.sql` and `20261107130100_resource_center_schema.sql`; ledger order authoritative. |
| Local `0020_add_cycle_events.sql` | Deployed statement scan found no matching CREATE TABLE record; exact production mapping unresolved. |

The security remediation changes defaults for creator `postgres` only and explicitly leaves existing objects untouched. `supabase_admin` defaults remain broad. Exact historical origin of existing grants cannot be proven without ACL snapshots/out-of-band SQL history; legacy defaults are plausible, not confirmed for each object.

## 9. Companion documents

- [Production security investigation](SCHOLARS_PHASE_2_1_1_PRODUCTION_SECURITY_INVESTIGATION_2026-11-09.md)
- [Least-privilege target design](SCHOLARS_PHASE_2_1_1_LEAST_PRIVILEGE_TARGET_DESIGN_2026-11-09.md)
- [Security remediation and rollback plan](SCHOLARS_PHASE_2_1_1_SECURITY_REMEDIATION_AND_ROLLBACK_PLAN_2026-11-09.md)
- [Security test specification](SCHOLARS_PHASE_2_1_1_SECURITY_TEST_SPECIFICATION_2026-11-09.md)
