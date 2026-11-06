# Scholars Resource Center — Phase 0.2
## Final Security and Schema Readiness

**Repository:** `ImperioKDB/Scholars`  
**Website:** `https://scholars.com.ng`  
**Supporting reports:**

- `SCHOLARS_RESOURCE_CENTER_PHASE_0_PRE_IMPLEMENTATION_VALIDATION.md`
- `SCHOLARS_RESOURCE_CENTER_PHASE_0_1_SECURITY_AND_SCHEMA_CLARIFICATION.md`

**Supabase project inspected:** `scholarship-platform` (`cmdglabohpttgfofcmqc`)  
**Current phase:** 0.2 — read-only remediation planning and final architecture validation  
**Audit date:** 2026-11-06  
**Final readiness classification:** **C. BLOCKED BY EXISTING SECURITY FINDINGS**

> No application source, database table, RLS policy, grant, function, trigger, record, migration, dependency, environment variable, secret, branch, commit or deployment was changed during this phase.

## 1. Executive summary

The Resource Center architecture is defined well enough to implement after specific owner decisions, but the project is not ready to enter implementation because the live Supabase privilege state contains an unresolved security-boundary discrepancy. Three functions intended by the repository migrations to be service-role-only currently have effective `anon` and `authenticated` execution: `claim_notification_delivery`, `claim_workflow_job`, and `complete_workflow_job`. The live database also has broad default privileges for functions and tables in `public`, while the worker migrations revoke only from `PUBLIC`, not explicitly from `anon` and `authenticated`. This is the strongest explanation of the live ACL shape, but the exact historical operation that established the defaults was not found in the repository migration history and must remain an inference.

The live state must not be “fixed” as part of Resource Center work. The owner should approve a separate security remediation migration that explicitly revokes `anon` and `authenticated` execution from the three worker functions, verifies all overloads, and tests digest, notification, discovery and re-engagement workers in a non-production target. The same remediation should review the other broad SECURITY DEFINER grants, especially `flag_expired_opportunities`, `run_achievement_checks`, `seed_scholarship_prompts`, trigger-only functions, and sensitive analytics functions.

The `announcement_log` design is internally inconsistent. Its migration says RLS with no policies is intentional because only service-role code should read/write it (`supabase/migrations/0015_add_announcement_log.sql:8-11`), and the digest/broadcast paths use the service client. However, `app/admin/page.tsx:11,35-39,116,306` reads the table through the normal server client to populate the “last digest” control. Live table ACLs also grant table privileges to `anon` and `authenticated`, although RLS currently blocks rows because there are no policies. The safest smallest future correction is to remove the dashboard statistic or replace it with a narrowly scoped, admin-checked server-only aggregate. A broad authenticated policy is not recommended.

The Resource Center public-data model must account for a PostgreSQL limitation: RLS controls rows, not columns. A policy on `resource_articles` would not by itself stop a public visitor from selecting `created_by`, `reviewer_identity_id`, or internal notes for an allowed row. The recommended model is a dedicated public view for each public resource surface, with an explicit approved-column list, `security_invoker = true`, RLS enforced on base tables, and explicit view grants. Public pages use ordinary server/browser-safe access to those views; they do not use service-role credentials. Direct Supabase queries remain safe because the base tables are not public read surfaces and the views expose only approved columns.

For revision integrity, use a hybrid model: normalized current article/category/identity tables for efficient public reads, plus immutable revision rows containing a complete canonical JSON snapshot of the published article state, including slug, title, excerpt, content, canonical URL, article type, featured image reference, author/reviewer display snapshots, category associations, source/review metadata and publication timestamps. Restoring a prior revision creates a new revision from the old snapshot; it never mutates historical rows.

Database-enforced workflow transitions are required for publication integrity. Ordinary RLS-protected writes may handle draft editing and revision creation, but submit, review-return, schedule, publish, archive and correction operations should use narrow server-side operations that validate the actor, status, reviewer separation, revision identity, approval freshness, scheduled time and MFA/AAL2 requirement. No Resource Center function should be implemented until the existing privilege findings are resolved or explicitly accepted by the owner.

## 2. Inspection methodology, evidence labels and limitations

### Evidence labels

- **Verified:** directly observed in source, live catalog metadata, live ACLs, live migration tracking, or repository migration text.
- **Inference:** a reasoned explanation supported by verified facts but not proven by an observed historical event.
- **Recommendation:** proposed future design or remediation; not an existing system fact.
- **Unverified:** could not be established from the available read-only evidence.

### Read-only inspections performed

The inspection covered:

- All 31 live `public` SECURITY DEFINER functions identified in Phase 0.1.
- Current function signatures, owners, `prosecdef` status, ACLs and effective execution for `public`, `anon`, `authenticated` and service-role access.
- Current `pg_default_acl` entries for `public` schema functions, tables and sequences.
- Current table ACLs and effective select privileges for the six RLS-enabled/no-policy tables.
- Applied migration tracking entries for workflow/outbox, notification claim, discovery trust path, provider analytics, visitor metrics and confirmation analytics.
- Full repository search for later grant/revoke/default-privilege statements.
- `app/admin/page.tsx`, `lib/email/digest.ts`, `app/api/admin/broadcast/route.ts`, and the original announcement migration.
- Existing admin guards, middleware and relevant source routes.

### Limitations

No anonymous or authenticated function call was made. No mutation or exploit test was attempted. No live migration, policy, grant, function definition, table, record, deployment, environment variable or secret was changed. The report therefore distinguishes a verified privilege discrepancy from a demonstrated exploit. The cause of the default privilege configuration was not found in repository migrations; its role in the worker ACL drift is marked as an inference.

## 3. Priority A — SECURITY DEFINER remediation plan

### 3.1 Live grant baseline

The live catalog contains 31 `public` SECURITY DEFINER functions, all owned by `postgres`.

- 16 have effective `PUBLIC` execution, which also covers anonymous and authenticated API callers.
- 12 have `PUBLIC` false but effective `anon` and/or `authenticated` execution.
- 3 have `public`, `anon` and `authenticated` execution false and are restricted to postgres/service-role access.

A function in the `public` schema is ordinarily directly callable through Supabase RPC if the caller has EXECUTE on the exact signature. A trigger function can also be executed by PostgreSQL as part of its trigger, even when direct RPC execution is unnecessary. Therefore, “PUBLIC grant” is not automatically an exploit, but it is unnecessary exposure for trigger-only or internal mutation functions.

### 3.2 Prioritized remediation matrix

| Priority | Scope | Narrowest proposed correction | Why |
|---|---|---|---|
| P0 | `claim_notification_delivery`, `claim_workflow_job`, `complete_workflow_job` | Explicitly revoke EXECUTE from `PUBLIC`, `anon`, and `authenticated` on the exact signatures; grant only `service_role`; verify overloads | Live ACLs conflict with the service-role-only intent in migrations and expose worker state mutation/RPC to browser roles |
| P0 | Default ACL configuration | Owner-led separate migration/administrative change to stop broad default function/table privileges for future `public` objects, followed by explicit grants per object | Current `pg_default_acl` grants `anon`/`authenticated` function and table privileges by default; new objects can silently repeat the problem |
| P1 | `flag_expired_opportunities()` | Revoke from `PUBLIC`, `anon`, and `authenticated`; retain service-role only unless a verified browser feature requires it | It is a mutation operation invoked by the cron service path, not a public feature |
| P1 | `run_achievement_checks(uuid)`, `seed_scholarship_prompts()` | Revoke direct browser execution; retain only the invoking trigger/service role or a narrow internal role after call-site verification | Mutation/maintenance functions do not need direct public RPC exposure |
| P1 | Trigger-only functions | Revoke direct execution from `PUBLIC`, `anon`, and `authenticated`; preserve trigger execution and any explicitly required internal caller | Trigger execution is distinct from direct RPC and does not justify browser EXECUTE |
| P1 | `get_auth_confirmation_email_analytics`, `get_provider_analytics`, `get_daily_visitor_metrics`, `get_admin_metrics_summary` | Grant only authenticated if the owner intentionally keeps direct RPC; otherwise expose through guarded admin route/service path and revoke browser RPC. Preserve internal admin checks either way | These functions read sensitive analytics/profile/auth-linked data; internal checks are useful but grants are broader than needed |
| P1 | `publish_discovery_candidate(uuid)` | Keep only the intended authenticated/admin route boundary or move to service-role-only; retain the function’s internal admin/readiness checks | It performs privileged scholarship/discovery writes; route and function checks both matter |
| P2 | `is_admin(uuid)` | Retain public execution only if required by RLS/function policy design; otherwise replace policy dependency with a safely scoped internal helper and revoke direct RPC | It is a role oracle. Its result is not a profile dump, but direct access is not automatically required by the Resource Center |
| P2 | `get_trending_scholarship_ids`, contributor profile functions | Confirm public product contract and projection; retain anon/auth only where the public route requires it | These are read paths, but exact output/privacy contract should be explicit |
| P2 | `notify_*`, `sync_*`, achievement trigger wrappers | Document trigger-only semantics and exact trigger dependencies; remove direct grants if not needed | Cleanup and defense-in-depth; do not change until trigger regression tests exist |
| P3 | `get_scholarship_discussions`, `get_scholarship_social_proof` | Retain anon/auth or public-equivalent execution only after confirming bounded parameters and safe projections | These are intentionally public reads used by public scholarship/community routes |
| P3 | `record_visitor_page_view`, `award_xp`, `check_rate_limit` | Retain service-role/postgres-only execution as currently observed | Current restriction matches server-side use |

### 3.3 Function-level remediation matrix

All functions below are in schema `public`, owned by `postgres`, and `SECURITY DEFINER`. “RPC” means direct Supabase RPC is technically possible when the caller has EXECUTE; “route required” identifies whether the existing application feature uses the function through a guarded server route or service client. Migration references establish intended permissions where available.

| Function and signature | Classification | Current live execution | Internal authorization | Existing feature / RPC need | Intended minimum grant | Regression risk | Evidence |
|---|---|---|---|---|---|---|---|
| `award_xp(uuid,text,integer,text,jsonb)` | Service-role-only worker | postgres, service_role | Server route/user/dedupe controls; function ACL is restrictive | Direct server RPC from `app/api/xp/share/route.ts:110-132`; no browser RPC | service_role, postgres | XP share stops if service client changes | `0025_atomic_share_xp_cap.sql:48-49`; later hardening in `0055`, `0071` |
| `check_achievements()` | Trigger-only | PUBLIC/anon/auth | Trigger context; no ordinary route required | Direct RPC not required | Trigger execution; no browser EXECUTE | Achievement trigger behavior could break if privileges are changed incorrectly | `0008_fix_first_action_achievement_timing.sql:89-103` |
| `check_application_submitted()` | Trigger-only | PUBLIC/anon/auth | Trigger context | No direct route found | Trigger execution only | Application XP/achievement side effects | Function identified live; exact creation migration should be reconciled before change |
| `check_community_discussion_achievements()` | Trigger-only | PUBLIC/anon/auth | Trigger context | No direct route found | Trigger execution only | Community achievement side effects | Function identified live; exact creation migration should be reconciled |
| `check_community_reaction_achievements()` | Trigger-only | PUBLIC/anon/auth | Trigger context | No direct route found | Trigger execution only | Reaction achievement side effects | Function identified live; exact creation migration should be reconciled |
| `check_first_action_achievements()` | Trigger-only | PUBLIC/anon/auth | Trigger context | Used by saved/application triggers | Trigger execution only | First-save/first-application achievements | `0008...:105-125` |
| `check_rate_limit(text,integer,integer)` | Service-role-only/internal | postgres, service_role | Server-side rate-limit boundary | No browser RPC | service_role, postgres | Public endpoints could lose throttling if changed incorrectly | Live ACL; source rate-limit helper |
| `check_referral_completion()` | Trigger-only | PUBLIC/anon/auth | Trigger context | No direct route found | Trigger execution only | Referral completion/XP effects | Function identified live; exact creation migration should be reconciled |
| `claim_notification_delivery(uuid,timestamptz)` | Service-role-only worker | postgres, anon, authenticated, service_role; PUBLIC false | No user-facing authorization; worker client is the intended caller | `lib/email/outbox.ts:63-70` through service client; direct browser RPC not required | service_role, postgres | Digest/notification worker cannot claim deliveries if service grant is removed | `0051_add_atomic_notification_claim.sql:1-29`; live ACL drift verified |
| `claim_workflow_job(text,timestamptz)` | Service-role-only worker | postgres, anon, authenticated, service_role; PUBLIC false | No user-facing authorization | `app/api/integrations/github/discovery-jobs/route.ts:11-17` uses service client | service_role, postgres | Discovery worker cannot lease jobs | `0064_complete_discovery_trust_path.sql:29-51`; live ACL drift verified |
| `complete_workflow_job(uuid,boolean,jsonb,jsonb,timestamptz)` | Service-role-only worker | postgres, anon, authenticated, service_role; PUBLIC false | No user-facing authorization | `app/api/integrations/github/discovery-jobs/route.ts:34-38` uses service client | service_role, postgres | Discovery worker cannot complete/retry jobs | `0064_complete_discovery_trust_path.sql:53-74`; live ACL drift verified |
| `flag_expired_opportunities()` | Internal maintenance mutation | postgres, anon, authenticated, service_role; PUBLIC false | No browser authorization established | `app/api/cron/deadline-check/route.ts:20-22` service client | service_role, postgres | Deadline cron could fail if service grant is omitted | `0075_flag_expired_opportunities.sql:69-70`; current live grant broader than intended |
| `get_admin_metrics_summary(timestamptz)` | Admin read with internal authorization | postgres, anon, authenticated, service_role; PUBLIC false | Migration body includes `public.is_admin(auth.uid())` | `app/admin/page.tsx:48` normal server RPC; direct browser RPC not required | authenticated only if deliberately retained, otherwise guarded server path/service role | Admin dashboard metrics could fail; removing browser RPC requires route/query adjustment | `0045_add_admin_metrics_summary.sql:4-60`, `0056_add_community_layer.sql:450-451` |
| `get_auth_confirmation_email_analytics(timestamptz,timestamptz)` | Admin read with internal authorization | postgres, anon, authenticated, service_role; PUBLIC false | Function checks `public.is_admin(auth.uid())` | `app/admin/page.tsx:48-58`; admin analytics | authenticated with internal check, or guarded server-only path | Admin confirmation analytics could fail | `0103_add_confirmation_email_analytics.sql:31-125` |
| `get_community_contributor_profile(uuid)` | Publicly intended read with projection | postgres, anon, authenticated, service_role; PUBLIC false | Safe projection is the primary control | `app/api/community/contributors/[discussionId]/route.ts:15`; direct RPC is part of public read model | anon, authenticated | Contributor page could fail if anon grant removed | `0061_add_contributor_profiles.sql:53-54`; `0062...:94-95` |
| `get_daily_visitor_metrics(timestamptz,timestamptz)` | Admin read with internal authorization | postgres, anon, authenticated, service_role; PUBLIC false | Function checks admin and validates range | `app/admin/analytics/page.tsx:57`; admin route | authenticated only if direct RPC retained, otherwise guarded route/service role | Admin visitor analytics could fail | `0086_add_daily_visitor_metrics.sql:68-108` |
| `get_provider_analytics(timestamptz,timestamptz,uuid)` | Admin read with internal authorization | postgres, anon, authenticated, service_role; PUBLIC false | Function checks `is_admin` | `app/admin/analytics/page.tsx:51`; `app/api/admin/analytics/route.ts:116` | authenticated with internal check, or guarded server-only path | Provider analytics could fail | `0072_add_provider_analytics.sql:131-132`, `0073`, `0078`, `0082:120-121` |
| `get_public_contributor_profile(uuid)` | Publicly intended read with projection | postgres, anon, authenticated, service_role; PUBLIC false | Safe projection is the primary control | `app/community/contributors/[profileId]/page.tsx:25`; public page | anon, authenticated | Public contributor page could fail | `0062_add_public_contributor_profile_page.sql:94-96` |
| `get_scholarship_discussions(uuid,text,integer)` | Publicly intended read | PUBLIC/anon/auth | Function/query bounds and projection | `lib/scholarship-community.ts:112` | anon, authenticated; PUBLIC only if explicitly desired | Community discussion reads could fail | `0034_add_scholarship_discussions.sql:380-381`; `0056:374` |
| `get_scholarship_social_proof(uuid)` | Publicly intended read | PUBLIC/anon/auth | Aggregate/projection | `lib/scholarship-community.ts:117` | anon, authenticated; PUBLIC only if explicitly desired | Social proof could fail | `0034...:380-381`; `0059:87` |
| `get_trending_scholarship_ids(integer,integer)` | Public/read function with implicit route boundary | postgres, anon, authenticated, service_role; PUBLIC false | No admin requirement; parameter bounds must be verified | `app/dashboard/page.tsx:39`; direct authenticated RPC path | authenticated, possibly anon if public dashboard need is approved | Dashboard trending IDs could fail | Live call site; exact grant migration should be reconciled |
| `handle_new_user()` | Trigger-only | PUBLIC/anon/auth | Trigger context from `auth.users` | No direct RPC required | Trigger execution only | Signup profile bootstrap could fail | `0001_init.sql:134-150` |
| `is_admin(uuid)` | Internal authorization helper / possible role oracle | PUBLIC/anon/auth | Returns role boolean; used by policies/functions | RLS/function dependency, not necessarily direct UI RPC | Minimal caller role required by policies; direct public execution only if proven necessary | RLS/admin checks could fail if revoked without replacement | `0002_harden_functions.sql:10-12`; `0023_lock_admin_flag.sql:112`; live ACL |
| `notify_discussion_helpful()` | Trigger-only | PUBLIC/anon/auth | Trigger context | No direct route found | Trigger execution only | Helpful notification behavior | Live function/trigger inventory |
| `notify_discussion_reply()` | Trigger-only | PUBLIC/anon/auth | Trigger context | No direct route found | Trigger execution only | Reply notification behavior | Live function/trigger inventory |
| `publish_discovery_candidate(uuid)` | Administrative mutation | postgres, anon, authenticated, service_role; PUBLIC false | Checks actor `auth.uid()` and `is_admin`, plus candidate readiness | `app/api/admin/discovery/route.ts:40`; route also guarded | Authenticated only if internal admin check is retained; service-role is narrower | Discovery publication could fail; must test admin route | `0061_harden_scholarship_verification_agent.sql:104-105`; `0064:76-115`; `0066:40-41` |
| `record_visitor_page_view(text,timestamptz)` | Service-role-only worker | postgres, service_role | Validates visitor-key shape; server client only | `app/api/events/route.ts:67-70` service client | service_role, postgres | Page-view monitoring could fail | `0086_add_daily_visitor_metrics.sql:38-66` |
| `run_achievement_checks(uuid)` | Internal mutation/helper | PUBLIC/anon/auth | Function evaluates profile-linked state; no direct public feature identified | Trigger wrappers call it; no direct route found | Trigger/internal caller only | Achievement awards could fail if trigger privileges change | `0008_fix_first_action_achievement_timing.sql:34-87` |
| `seed_scholarship_prompts()` | Internal maintenance mutation | PUBLIC/anon/auth | No internal auth verified from available source references | No direct app call identified | service_role/postgres or migration-only execution | Prompt seed/maintenance operations could fail | Live function; creation migration requires reconciliation |
| `sync_scholarship_discussion_helpful_count()` | Trigger-only | PUBLIC/anon/auth | Trigger context | No direct route found | Trigger execution only | Discussion counts could drift if changed | Live function/trigger inventory |
| `sync_waec_summary_fields()` | Trigger-only/profile maintenance | PUBLIC/anon/auth | Trigger context | No direct route found | Trigger execution only | Profile/WAEC summary updates could fail | Live function/trigger inventory |

### 3.4 Important distinction: trigger execution versus RPC execution

A trigger function being `SECURITY DEFINER` does not mean it must be directly callable by browser roles. PostgreSQL invokes a trigger function as part of the trigger event; direct `EXECUTE` is a separate privilege. Therefore, the proposed P1 cleanup for trigger-only functions is not “disable the trigger.” It is “remove unnecessary direct RPC execution while preserving the trigger and testing the triggering DML.”

The report does not claim that every PUBLIC trigger grant is currently exploitable. It identifies unnecessary direct exposure and recommends narrow privilege cleanup after dependency verification.

## 4. Priority B — Worker-function grant drift

### 4.1 Verified repository intent

The repository explicitly defines the intended permission boundary:

- `supabase/migrations/0051_add_atomic_notification_claim.sql:1-29` comments “Service-role only,” creates `claim_notification_delivery(uuid,timestamptz)`, revokes all from `public`, and grants EXECUTE to `service_role`.
- `supabase/migrations/0064_complete_discovery_trust_path.sql:29-51` creates `claim_workflow_job(text,timestamptz)`, revokes all from `public`, and grants EXECUTE to `service_role`.
- `supabase/migrations/0064_complete_discovery_trust_path.sql:53-74` creates `complete_workflow_job(uuid,boolean,jsonb,jsonb,timestamptz)`, revokes all from `public`, and grants EXECUTE to `service_role`.

The exact signatures in those migrations match the live signatures inspected. No overload was observed for any of the three functions.

### 4.2 Verified live state

The live ACL for each function is:

```text
postgres=X/postgres,
 anon=X/postgres,
 authenticated=X/postgres,
 service_role=X/postgres
```

`PUBLIC` is not present as a direct ACL entry, but `anon` and `authenticated` are explicitly present and effective. Therefore, checking only `has_function_privilege('public', ...)` would miss the discrepancy.

Live applied migration tracking contains the corresponding feature entries:

- `20260915195600` — `add_workflow_outbox_foundation`
- `20260919200501` — `add_atomic_notification_claim`
- `20260928111649` — `complete_discovery_trust_path`

The repository search found no later migration that grants `anon` or `authenticated` on these three functions, and no migration containing `ALTER DEFAULT PRIVILEGES` or a later explicit grant for these exact signatures.

### 4.3 Default privilege evidence

The live `pg_default_acl` catalog reports for `postgres` in schema `public`:

```text
functions: postgres=X, anon=X, authenticated=X, service_role=X
relations: postgres=arwdDxtm, anon=arwdDxtm, authenticated=arwdDxtm, service_role=arwdDxtm
sequences: postgres=rwU, anon=rwU, authenticated=rwU, service_role=rwU
```

This is a verified current default-privilege configuration. The repository contains no matching default-privilege statement.

### 4.4 Cause assessment

**Strong inference, not a directly observed historical event:** when these functions were created, the live default function ACL likely added explicit `anon` and `authenticated` EXECUTE entries. The migration statements revoke from `PUBLIC`, but `REVOKE ... FROM PUBLIC` does not remove separately granted privileges from `anon` or `authenticated`. The current ACL is exactly consistent with that sequence: the public role entry is absent, while anon/authenticated remain.

**What cannot be established:** the inspection did not identify the exact dashboard action, platform operation, timestamp or historical migration that created the current default privilege rows. No repository migration changes default privileges. It is not safe to claim a specific operator or later migration caused the drift.

### 4.5 Proposed correction, not executed

Use a dedicated, owner-approved security remediation migration with exact signatures:

```sql
revoke all on function public.claim_notification_delivery(uuid, timestamptz) from public, anon, authenticated;
grant execute on function public.claim_notification_delivery(uuid, timestamptz) to service_role;

revoke all on function public.claim_workflow_job(text, timestamptz) from public, anon, authenticated;
grant execute on function public.claim_workflow_job(text, timestamptz) to service_role;

revoke all on function public.complete_workflow_job(uuid, boolean, jsonb, jsonb, timestamptz) from public, anon, authenticated;
grant execute on function public.complete_workflow_job(uuid, boolean, jsonb, jsonb, timestamptz) to service_role;
```

The production correction must also explicitly review/fix the `public` schema default privileges so future objects do not recreate the discrepancy. That default-privilege correction is broader than the three-function fix and requires separate owner approval. Do not rely on future migrations saying only `FROM PUBLIC`.

### 4.6 Required regression tests before production

In a non-production target:

1. Assert exact ACLs for all three signatures and verify `has_function_privilege('anon', ...) = false`, `has_function_privilege('authenticated', ...) = false`, and service-role access remains true.
2. Verify anonymous and authenticated RPC calls fail with permission denied without changing rows.
3. Verify the digest worker can still claim a notification, send/mark accepted, and mark retryable using the service client.
4. Verify discovery worker claim and completion through the authenticated GitHub integration route using its service-role client.
5. Verify re-engagement enqueue/worker paths still create and complete jobs.
6. Verify no overload retains a broader grant.
7. Create a throwaway function/table in the test environment and inspect default ACL behavior before allowing a new production migration.
8. Run the existing CI typecheck, tests and build, then run integration checks for cron/worker routes.

No correction or test call was executed in this phase.

## 5. Priority C — `announcement_log` inconsistency

### 5.1 Verified current design

The original migration creates `public.announcement_log`, enables RLS and creates no policies. Its comments explicitly say only the service-role cron client and postgres should read/write it (`supabase/migrations/0015_add_announcement_log.sql:8-11`).

Service-role access is correctly used by:

- `lib/email/digest.ts:17,46,58-76,134-156`.
- `app/api/admin/broadcast/route.ts:103,132,208-210`.

The inconsistent path is:

- `app/admin/page.tsx:11` creates the ordinary server client.
- `app/admin/page.tsx:35-39` reads `announcement_log` directly.
- `app/admin/page.tsx:116` maps the result to `lastDigestAt`.
- `app/admin/page.tsx:306` passes it to `SendDigestButton`.

The surrounding page is admin-protected, but the normal server client remains subject to RLS. A page-level admin check does not automatically bypass table RLS.

### 5.2 Live privileges

The live table ACL includes table privileges for `anon` and `authenticated`, consistent with the live default relation privileges, but `has_table_privilege('anon', ... 'select')` does not mean rows are visible: RLS is enabled and there are no policies. The live no-policy table is therefore still row-denied to browser roles. The broad table ACL is defense-in-depth debt and should not be mistaken for a safe public read model.

### 5.3 Options

**A. Narrow server-only aggregate using the service client after admin authorization.** This preserves the statistic and matches the table’s original service-only intent, but adds a service-role read inside a Server Component. It must be server-only, remain behind `requireAdmin()`, select only `max(created_at)`, and never serialize table rows.

**B. Remove the dashboard statistic.** This is the smallest security surface and avoids using service-role credentials for a non-essential UI convenience. The digest button can continue to operate through its existing guarded API route.

**C. Dedicated authorized database function.** This can return only `max(created_at)` after an internal admin check, but it adds a new SECURITY DEFINER surface and requires careful grants, search path and function testing. Given the current grant drift, it is not the safest immediate option.

### 5.4 Recommendation

Recommend **B for the initial security remediation**: remove the non-essential `lastDigestAt` dashboard statistic, or defer it until a broader operational metrics design exists. If product insists on retaining it, choose **A** with a server-only service client after `requireAdmin()`, a one-value aggregate, no table row serialization, and explicit error handling. Do not create an authenticated RLS policy on `announcement_log`. Do not use a new SECURITY DEFINER function while the existing function ACL baseline remains unresolved.

This is a recommendation only. No application change was made.

## 6. Priority D — secure Resource Center public read model

### 6.1 PostgreSQL boundary

RLS is row-level security. It decides which rows a role can access; it does not hide columns of an allowed row. A policy such as “anon may select published articles” would not by itself prevent selecting `created_by`, `reviewer_identity_id`, `internal_notes` or `user_id` from those rows. The Resource Center must therefore use a column-projection boundary in addition to RLS.

### 6.2 Compared approaches

| Approach | Strength | Weakness | Decision |
|---|---|---|---|
| Column-level grants | Database-native column allowlist | Complex to maintain; easy to miss newly added sensitive columns; awkward with PostgREST/schema evolution | Not recommended as the primary model |
| Dedicated public view | Explicit columns, stable API, direct Supabase queries can be safe | Requires view policy/grant discipline and view/RLS configuration | **Recommended** |
| Server-only projection with normal authenticated client | No public DB surface; easy to keep private fields out | Direct Supabase querying can still expose base-table data if grants/policies are wrong; public pages depend on server path | Useful as an additional application boundary, not sufficient alone |
| Server-side service-role read | Bypasses RLS and can project safely in code | Dangerous for public requests; direct Supabase access remains a separate exposure; secret-bearing path | Not recommended for public pages |

### 6.3 Recommended public views

Create, only after approval, dedicated views such as:

- `public.resource_public_articles`
- `public.resource_public_categories`
- `public.resource_public_editorial_identities`
- optionally `public.resource_public_article_categories`

Each view must explicitly list approved columns. Do not use `SELECT *`. The article view should expose only fields such as public article ID/slug/title/excerpt/content/article type/canonical URL/featured image public path/reading time/publication date/last-reviewed date and approved public author display fields. It must not expose `created_by`, `updated_by`, internal reviewer associations, private notes, revision IDs, revision bodies, user IDs or internal administrative timestamps.

Use `security_invoker = true` for the views so the view respects the querying role’s permissions and the base-table RLS policies rather than running with owner privileges. The base `resource_articles` RLS policy remains the source of truth: anon/authenticated can see only rows where `status = 'published'` and `published_at IS NOT NULL AND published_at <= now()`. Grant `SELECT` on the public views to `anon` and `authenticated`; do not grant direct table SELECT on the base editorial tables to those roles. If the chosen Supabase/Postgres configuration requires an explicit security-invoker syntax/version check, validate it in non-production before migration.

The categories view should expose only active categories used by public content. The editorial identity view should expose only active approved `display_name`, public bio and approved avatar path. It must never expose `user_id`. Public article queries should join the views, not the base tables. Admin queries use base tables through guarded normal server access or a narrowly controlled server path.

This model remains safe when a visitor directly queries Supabase: the base tables are not public read surfaces, the views contain only allowlisted columns, and the row predicate is enforced by invoker RLS. The frontend is not the security boundary.

## 7. Priority E — revision and publication integrity

### 7.1 Compared models

**A. Fully normalized revision tables.** Every revision has typed columns and separate revision-category/source/identity snapshot tables. Strong relational validation, but a large schema and more opportunities for partial snapshots.

**B. Immutable JSON snapshots.** A single JSON document captures the complete article state. Exact reconstruction is easy, but arbitrary JSON is harder to query/validate and can drift without a schema contract.

**C. Hybrid (recommended).** Current article/category/identity tables remain normalized for reads and workflow. Each revision stores one immutable, schema-versioned JSON snapshot containing the complete canonical published state, with typed audit columns and optional normalized audit relations for reporting.

### 7.2 Complete snapshot contract

`resource_revisions.state jsonb NOT NULL` should contain, at minimum:

- `schema_version`
- article `id`, `slug`, `title`, `excerpt`, `content`, `article_type`
- `canonical_url`
- `featured_image_path`
- `reading_time_minutes`
- author identity ID plus approved public display snapshot
- reviewer identity ID plus approved public display snapshot
- complete category associations, including stable IDs, slugs and names at publication
- source references and source URLs
- `last_reviewed_at`
- `status`, `scheduled_for`, `published_at`, `archived_at`
- the revision number and publication event metadata

The article’s normalized current row stores the currently editable/published state for efficient queries. A revision is created whenever an article is submitted, approved, scheduled, published, corrected or restored. The published article must point to the exact revision that was promoted, for example through `published_revision_id`.

### 7.3 Immutability and restoration

RLS should allow editors to insert revisions but not update/delete them. Database constraints/triggers or a dedicated server operation should reject changes to a revision after insertion. The public view must not include the revision table.

To restore revision 4 after revision 7 was published:

1. Read revision 4 through an authorized admin operation.
2. Copy its complete `state` into a new revision 8 with a new revision number and actor/change summary.
3. Set the normalized article draft to the copied state.
4. Send it through review again; do not retain revision 4’s approval as current approval.
5. Publish only after the new reviewer decision and required MFA.

Revision 4 and revision 7 remain unchanged. This reconstructs the old content without mutating historical records or silently reviving an obsolete approval.

## 8. Priority F — database-enforced editorial workflow

### 8.1 Permitted transitions

The only normal transitions are:

- `draft → in_review`
- `in_review → draft` (returned for changes)
- `in_review → scheduled`
- `in_review → published` only for an explicitly approved immediate-publication path
- `scheduled → published` only when `now() >= scheduled_for` and the approved revision is unchanged
- `scheduled → draft` when scheduling is cancelled or content changes
- `published → archived`
- `published → draft` only through a correction operation that creates a new revision and clears obsolete approval
- `archived → draft` only by an authorized admin, creating a new working revision

No direct `draft → published`, `draft → scheduled`, or `in_review → archived` transition is permitted without the explicitly modeled approval action.

### 8.2 Required invariants

The database/server operation must reject:

- author and approving reviewer being the same editorial identity in the normal path;
- non-admin/student actors publishing or scheduling;
- direct status updates that bypass the transition operation;
- scheduling without a reviewer-approved revision;
- publication before `scheduled_for`;
- publication of a revision different from the approved revision;
- edits to a revision after approval;
- content changes that retain an old approval timestamp or reviewer;
- publication without an active approved author, reviewer, category and required source/review metadata.

### 8.3 Ordinary writes versus dedicated operations

Ordinary RLS-protected writes are suitable for creating/editing drafts and inserting a new immutable revision, provided policies limit the actor to an editable article and disallow revision UPDATE/DELETE.

Dedicated server-side RPC/database operations are recommended for:

- `submit_resource_article_for_review`
- `return_resource_article_to_draft`
- `approve_resource_article`
- `schedule_resource_article`
- `publish_resource_article`
- `archive_resource_article`
- `restore_resource_revision_as_draft`

Each operation must validate `auth.uid()`, the actor’s admin/editor/reviewer capability, author/reviewer separation, current status, approved revision ID, content/source requirements and MFA/AAL2 where required. The operation should set actor IDs and timestamps atomically. The final implementation must explicitly revoke direct browser execution from service-only operations; it must not repeat the existing “revoke PUBLIC only” mistake.

Publishing/scheduling should require AAL2 through the existing `assertAdmin(..., { requireAal2: true })` route boundary and a database-side actor/MFA representation that cannot be forged by the client. If the database cannot independently verify AAL2, the route must be the mandatory privileged boundary and the database operation must still validate admin identity and workflow state.

## 9. Priority G — migration and non-production readiness

### 9.1 Staging availability

**Verified:** the connected Supabase organization lists two active projects: `scholarship-platform` and `serena`.

**Not established:** no evidence proves that `serena` is a Scholars staging/development database. Its name, active status and region are insufficient. It must not be mutated or used for testing until the owner confirms ownership, project linkage, data purpose and non-production status.

**Conclusion:** a genuine non-production Scholars database is **unverified**.

### 9.2 Safe alternative

If no owner-confirmed staging project exists, create or authorize a disposable isolated Supabase project or local Postgres/Supabase environment seeded only with synthetic representative data. Reproduce:

- base article/category/editorial/revision tables;
- public views;
- anon/authenticated/editor/reviewer/admin roles;
- RLS policies and view grants;
- publication time predicates;
- revision and workflow operations;
- exact ACL and default-privilege checks.

No production data should be copied into the test target unless separately approved, minimized and sanitized.

### 9.3 Production migration plan

1. Select a unique UTC timestamp migration version after checking repository files and live `schema_migrations`.
2. Reconcile the historical migration naming collisions by version/content, not filename alone.
3. Produce a schema diff for tables, columns, constraints, indexes, views, policies, grants, functions and storage.
4. Review the separate SECURITY DEFINER remediation plan before any Resource Center migration.
5. Run the migration against the confirmed non-production target with synthetic fixtures.
6. Verify ACLs and RLS as `anon`, `authenticated`, editor, reviewer, admin and service-role-equivalent roles.
7. Verify direct PostgREST/view queries cannot expose private columns or drafts.
8. Verify backup creation and restoration in the target environment.
9. Run repository CI: typecheck, tests and production build.
10. Deploy a Vercel preview with the public route feature-disabled or content-empty and test metadata, sitemap and auth regressions.
11. Obtain explicit production approval, including the exact migration version and owner sign-off.
12. Take an owner-approved production backup/restore checkpoint.
13. Apply the additive migration through the approved Supabase path.
14. Run post-migration catalog checks for schema, RLS, view security behavior, grants and default privileges.
15. Verify anonymous published reads, draft denial, author/reviewer workflow, MFA publication, sitemap filtering and all existing Scholars regression tests.

### 9.4 Rollback/forward-fix

Prefer an additive forward fix. Disable the public route or publishing operations if a defect appears. Archive/repair content through audited operations rather than deleting production rows. Use a tested restore procedure only for a database-level incident. Do not create a destructive down migration that drops article history, identities, revisions or images by default.

## 10. Priority H — final Resource Center architecture

### Article schema

`resource_articles` stores the current normalized article state: UUID, unique lowercase slug, title, excerpt, content representation, article type, status, scheduled/publication/archive timestamps, last-reviewed timestamp, canonical URL, approved featured-image path, reading time, author identity ID, reviewer identity ID, created/updated actor IDs, timestamps and `published_revision_id`.

### Category schema

`resource_categories` stores UUID, unique URL-safe slug, name, description, display order, active flag and timestamps. `resource_article_categories` is a composite-key join with restricted category deletion.

### Editorial identity schema

`resource_editorial_identities` stores UUID, optional `user_id` link with `ON DELETE SET NULL`, public display name, public biography, approved avatar path, active flag and timestamps. Public views never expose `user_id`.

### Revision schema

`resource_revisions` stores UUID, article ID, revision number, immutable complete `state jsonb`, schema version, actor, change summary, created timestamp and publication event metadata. The state includes all article metadata and category/identity snapshots required to reconstruct the exact published state.

### Public read model

Dedicated `security_invoker = true` views expose only approved columns. Base-table RLS limits rows to active published content with publication time reached. Public pages use ordinary server/browser-safe access to views; no service-role credentials are used.

### Admin write model

`/admin/resources` and `/api/admin/resources` reuse `lib/admin/access.ts`, `lib/admin/guard.ts` and `middleware.ts`. Draft editing uses RLS-protected ordinary writes; status transitions and publication use narrow server/database operations. Publish/schedule requires existing admin authorization and AAL2/MFA according to the approved policy.

### RLS

Anon/authenticated roles can select only public views and only rows allowed by published/time predicates. They cannot select base drafts, reviewer fields, revisions or internal identity links. Editors/reviewers/admins receive separate policies for the smallest required article/revision operations. Service-role access is reserved for controlled maintenance and scheduled operations.

### MFA

Preserve existing authentication and admin guards. Require AAL2 for publication, scheduling, archive and restore operations where the owner enables the existing MFA configuration or the operation explicitly requires it.

### Image storage

Use a reviewed Resource Center image path or bucket boundary, not arbitrary remote images. Validate content type, size, dimensions, filename/path and ownership server-side. Public article views expose only approved public paths/URLs.

### Rendering

Use sanitized Markdown only if an existing trusted renderer can be configured with a strict allowlist; otherwise use controlled structured blocks. Never store/render arbitrary unsanitized HTML. Restrict links to safe protocols, validate images and preserve heading/list/table/code accessibility.

### SEO and sitemap

Public article pages are server-rendered and include stable slugs, canonicals, Article/BreadcrumbList structured data, mobile metadata and internal links. `app/sitemap.ts` includes only published articles whose publication time has arrived. Draft, in-review, scheduled and archived content is excluded. Preview paths are authenticated and noindex if introduced.

### Publishing and scheduling

Approval creates a revision snapshot and reviewer record. Scheduling stores an approved revision ID and `scheduled_for`. Publication is idempotent, checks that the article/revision has not changed, and refuses early publication. Corrections create new revisions and new review decisions.

### Explicit isolation confirmations

- Public pages do **not** use service-role credentials.
- Draft content cannot be queried by public visitors.
- Public views expose only approved columns.
- Revisions cannot be publicly queried.
- Existing scholarship, matching, eligibility, applications, onboarding and profile data remain isolated.
- Existing authentication, middleware, admin guards and MFA checks remain intact.
- Ads and AdSense are not part of the initial implementation.

## 11. Required owner decisions before implementation

1. Approve a separate security-remediation change for the three worker-function ACL discrepancies.
2. Confirm whether the owner authorizes a default-privilege correction in `public`; this is broader than the Resource Center and must be separately scoped.
3. Decide whether to remove the `announcement_log` dashboard statistic or retain it through a server-only service aggregate.
4. Confirm the editorial identity hybrid model and whether all first-release authors/reviewers are existing admins.
5. Approve self-approval prohibition and two-person author/reviewer separation.
6. Approve the dedicated public-view model with `security_invoker = true` and published-only base RLS.
7. Choose sanitized Markdown versus structured blocks after dependency review.
8. Confirm the image storage/path policy.
9. Confirm a real non-production Scholars database, or approve a disposable isolated test target.
10. Approve whether publication/scheduling/restore require explicit AAL2 in addition to the existing `REQUIRE_ADMIN_MFA` behavior.

## 12. Final readiness decision

**Classification: C. BLOCKED BY EXISTING SECURITY FINDINGS.**

The project must not be labeled ready for implementation while the service-role-only worker boundary remains unexplained and live ACLs permit `anon`/`authenticated` execution on the three worker functions. The current default privileges and table/function ACL state also require owner-approved remediation planning. The Resource Center schema and public-read architecture are sufficiently defined, but implementation should wait for the decisions above and a non-production verification pass.

After the owner approves the remediation scope, verifies a safe test target and resolves the listed architecture decisions, the next phase may begin with an additive schema/RLS migration and direct-view tests. No Resource Center implementation, security correction, migration or deployment was performed in this report.

## 13. Final stop condition

This read-only investigation is complete. No code, SQL, database grants, RLS policies, migrations, tables, records, dependencies, secrets or deployments were changed. Await explicit owner approval before implementation or security remediation.
