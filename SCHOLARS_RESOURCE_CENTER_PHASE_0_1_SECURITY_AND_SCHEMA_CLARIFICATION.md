# Scholars Resource Center — Phase 0.1
## Security Findings Clarification and Final Content Architecture

**Repository:** `ImperioKDB/Scholars`  
**Website:** `https://scholars.com.ng`  
**Supabase project inspected:** `scholarship-platform` (`cmdglabohpttgfofcmqc`)  
**Current phase:** 0.1 — read-only investigation and architecture clarification  
**Audit date:** 2026-11-06  
**Status:** Complete. No implementation was performed.

> This report is an investigation and design artifact only. No application source, database table, policy, grant, function, trigger, record, migration, dependency, environment variable, branch, commit, or deployment was changed during this phase.

## 1. Executive summary

The approved Resource Center direction is technically compatible with Scholars, but implementation should remain blocked until the existing live Supabase security findings are triaged and the editorial data model is approved. The Resource Center should be a separate content subsystem at `/resources`, with a separate administrative surface at `/admin/resources`, published-only public reads, and no reuse of scholarship matching, eligibility, application, profile, notification, or discovery tables.

The live investigation verified six public tables with RLS enabled and no policies. Five contain production data and one is empty. Their no-policy design is intentional for service-role or database-internal ledgers in most cases, but the absence of policies is not universally low risk: `announcement_log` is queried from the admin Server Component through the normal server client, creating a potential existing admin-dashboard read failure; and the live privileges on several SECURITY DEFINER worker functions differ from the repository migrations and grant `anon`/`authenticated` execution to operations intended to be service-role-only.

The live database contains 31 SECURITY DEFINER functions owned by `postgres`. Sixteen currently have effective `PUBLIC` execution, twelve have effective `anon` and/or `authenticated` execution without `PUBLIC`, and three are restricted to service-role/postgres according to the live privilege inspection. The most important verified grant mismatch is on `claim_notification_delivery`, `claim_workflow_job`, and `complete_workflow_job`: repository migrations revoke public execution and grant service-role execution, while live privileges still permit `anon` and `authenticated` execution. These functions mutate or return operational job/delivery state and require owner confirmation and remediation planning before a new editorial write path is introduced.

The existing admin authorization model is layered and can support `/admin/resources` without weakening it: middleware checks `/api/admin`, Server Component pages use `requireAdmin()`, API handlers use `assertAdmin()`, and optional AAL2/MFA checks are present in both the guard and middleware. The narrowest first-release approach is to reuse these controls, require `profiles.is_admin = true`, add a narrowly scoped editorial capability check in the Resource Center boundary, and require AAL2 for publishing/scheduling if the owner enables `REQUIRE_ADMIN_MFA=true` or the route explicitly requires it. No new role system is required for the first release.

The recommended editorial identity approach is a hybrid: a separate public editorial identity table with an optional link to `auth.users`/`profiles`, while articles store separate author and reviewer foreign keys to that editorial identity. This prevents private student profile fields from becoming public article metadata, supports different author and reviewer identities, and leaves room for future guest contributors without creating guest accounts. Public article queries should project only approved display fields.

The recommended launch schema includes `resource_articles`, `resource_categories`, `resource_article_categories`, `resource_editorial_identities`, and immutable `resource_revisions`. Tags are intentionally omitted from launch. Public content should use sanitized Markdown or a controlled structured-block format; for the first release, sanitized Markdown is the narrowest practical option if an existing trusted renderer is available, otherwise use structured JSON blocks without adding a dependency. Publishing should prohibit self-approval, preserve immutable revisions, and expose only articles with status `published` and `published_at <= now()`.

### High-priority blockers before implementation

1. Confirm and remediate the live worker-function grant drift, especially the three worker claim/complete functions with `anon`/`authenticated` execution.
2. Decide whether the `announcement_log` admin dashboard query should use a privileged server-only path or be replaced by an authorized aggregate; do not add a broad policy merely to make the widget work.
3. Review the sixteen SECURITY DEFINER functions with effective `PUBLIC` execution and revoke direct execution where the function is trigger-only, internal, or mutation-capable.
4. Confirm the editorial identity, author/reviewer, content format, image policy, and self-approval decision.
5. Verify a real non-production Supabase target for migration testing. The connected organization contains another active project named `serena`, but no evidence was established that it is a Scholars staging project.

## 2. Inspection methodology and limitations

### Verified inspections

The investigation used read-only repository inspection, live Supabase metadata and SQL catalog inspection, live migration tracking inspection, and source-to-database cross-reference. Inspected source areas included:

- `lib/admin/guard.ts:19-83`
- `lib/admin/access.ts:10-35`
- `middleware.ts:192-214` and the protected-route logic around `165-216`
- `app/admin/page.tsx:10-58`
- `app/api/admin/discovery/operations/route.ts:7-22`
- `app/api/admin/scholarships/route.ts:65-100`
- `app/api/admin/member-roles/route.ts:12-37`
- `app/api/admin/digest/route.ts:24-34`
- `app/api/admin/analytics/route.ts:29-32`
- Resource-relevant notification, analytics, digest, broadcast, workflow, and integration call sites
- `supabase/migrations/0015_add_announcement_log.sql`
- `supabase/migrations/0023_add_broadcast_delivery_log.sql`
- `supabase/migrations/0036_add_workflow_outbox_foundation.sql`
- `supabase/migrations/0051_add_atomic_notification_claim.sql`
- `supabase/migrations/0064_complete_discovery_trust_path.sql`
- `supabase/migrations/0086_add_daily_visitor_metrics.sql`
- Relevant function and authorization migrations identified by repository search

The live Supabase project reported `ACTIVE_HEALTHY`. The live migration tracking table reported 175 applied entries and latest version `20261105124524`. The live project list contains `scholarship-platform` and another active project named `serena`; project naming alone does not verify that `serena` is a staging target for Scholars.

### Limitations

No anonymous or authenticated exploit attempts were performed. No function was called for mutation testing. No policies, grants, function definitions, tables, records, migrations, environment variables, or deployments were changed. The report therefore distinguishes effective privilege exposure from demonstrated exploitation. A live privilege grant is verified; whether a particular function can be abused to produce a harmful outcome requires a separately approved controlled test or owner-led remediation.

The live catalog inspection did not expose secret values. Function bodies were inspected only to the extent necessary to classify authorization and privileged operations; sensitive contents are not reproduced here. Counts are exact counts obtained through read-only aggregate queries, not estimates.

## 3. Six RLS tables without policies

### 3.1 Summary

| Exact table | Production rows | Application access | Access path observed | Intent assessment | Classification | Resource Center relevance |
|---|---:|---|---|---|---|---|
| `public.announcement_log` | 17,053 | Yes | Service-role digest/broadcast code; normal server client in `app/admin/page.tsx` | Intended as a service-role-only dedupe ledger, but the admin page path is inconsistent with that intent | Potential existing application issue; requires owner confirmation | None; do not reuse |
| `public.auth_rate_limits` | 0 | No direct source reference found in the inspected checkout | Database function/internal rate-limit foundation | Intent cannot be fully confirmed because it is empty and no direct app call was found | Requires application-owner confirmation | None |
| `public.broadcast_delivery_log` | 6,461 | Yes | Service-role admin broadcast and Independence Day campaign routes | Intended service-role delivery ledger | Intentional and low risk for Resource Center, subject to grant/policy review | None; do not reuse |
| `public.notification_deliveries` | 6,818 | Yes | Service-role email/push/re-engagement workers and outbox | Intended service-role outbound-delivery ledger | Intentional table isolation, but worker function grant drift is a potential security concern | None; do not reuse |
| `public.visitor_daily_metrics` | 1,335 | Yes | Service-role `record_visitor_page_view`; admin aggregate RPC | Intended to deny browser table access and expose only controlled aggregate | Intentional and low risk for Resource Center; analytics privacy remains separate | None; do not reuse |
| `public.workflow_jobs` | 3 | Yes | Service-role GitHub integration, admin operations, discovery workers | Intended service-role job ledger, but live claim/complete grants are broader than expected | Potential security concern; requires immediate owner confirmation | None; do not reuse |

### 3.2 `public.announcement_log`

**Verified schema and purpose.** The table has `profile_id uuid NOT NULL` referencing `profiles(id)` with `ON DELETE CASCADE`, `listing_kind text NOT NULL` constrained to `scholarship` or `opportunity`, `listing_id uuid NOT NULL`, and `created_at timestamptz NOT NULL DEFAULT now()`. Its primary key is `(profile_id, listing_kind, listing_id)`, with an index on `(profile_id, created_at DESC)`. The migration comment explicitly says RLS is enabled with no policies so only the service-role cron client and postgres can read/write it (`supabase/migrations/0015_add_announcement_log.sql:1-29`).

**Verified access.** `lib/email/digest.ts:17,46,74-76,154` uses `createServiceClient()` to read and insert dedupe records. `app/api/admin/broadcast/route.ts:103,132,208-210` uses a service client to upsert records. `app/api/admin/page.tsx:11,35-39` uses the ordinary server client after the page’s admin layout/guard and reads the latest timestamp directly from `announcement_log`.

**Impact.** The service-role paths match the no-policy design. The admin page query does not. Because an authenticated server client is subject to RLS, the query may return an RLS error/null result or leave the dashboard statistic unavailable. The exact UI behavior depends on how the later page code handles `lastLog`; this was not changed or dynamically tested. Do not solve this by adding a broad authenticated policy. Prefer a narrow privileged aggregate or remove the widget dependency.

**Resource Center relevance.** None. Article publication dedupe and article revisions require their own tables and policies.

**Classification:** Requires application-owner confirmation and potential existing application issue.

### 3.3 `public.auth_rate_limits`

**Verified schema and state.** The table has `rate_key text NOT NULL PRIMARY KEY`, `attempt_count integer NOT NULL DEFAULT 1`, `window_start timestamptz NOT NULL DEFAULT now()`, and `updated_at timestamptz NOT NULL DEFAULT now()`. Exact live count is zero. No direct source reference to the table was found in the inspected application source; the repository uses a `check_rate_limit` database function and related rate-limit code instead.

**Impact and uncertainty.** The table may be an unused or legacy foundation, or may be reached indirectly by a function not represented by a direct table string in the source checkout. It cannot be classified safe solely because it is empty. No policy should be added without confirming the owning rate-limit design.

**Resource Center relevance:** None.

**Classification:** Requires application-owner confirmation.

### 3.4 `public.broadcast_delivery_log`

**Verified schema and state.** The table contains per-recipient campaign delivery state: UUID `id`, `broadcast_id`, `recipient_email`, nullable `recipient_user_id` referencing `auth.users(id)` with `ON DELETE SET NULL`, `status` constrained to `sent`/`failed`, positive `attempts`, provider/error fields, and `created_at`. Indexes exist on broadcast/time and recipient/time. Exact live count is 6,461.

**Verified access.** `app/api/admin/broadcast/route.ts:103,132,213-223` uses a service client after `assertAdmin()` to write sent/failed outcomes. `app/api/admin/independence-day/route.ts:79-83,122-138,176-188` uses a service client after `assertAdmin()` to check and write campaign delivery state.

**Impact.** No browser-role path was found. RLS with no policies is consistent with the migration’s operational intent. The table contains email addresses and provider/error metadata and must not be made publicly readable.

**Resource Center relevance:** None. Resource Center notifications, if ever needed, should use a separately reviewed content-event contract.

**Classification:** Intentional and low risk for this phase.

### 3.5 `public.notification_deliveries`

**Verified schema and state.** The table has UUID `id`, required `profile_id` referencing `profiles(id)` with cascade, optional `scholarship_id` referencing `scholarships(id)` with cascade, campaign/channel/schedule/dedupe/template fields, status and attempt controls, provider/error/lease timestamps, and a unique `dedupe_key`. The live status check includes pending, leased, accepted, delivered, bounced, suppressed, failed, retryable and dead_letter. Exact live count is 6,818. The repository migration describes it as an idempotent outbound notification ledger with RLS and no public policies (`0036_add_workflow_outbox_foundation.sql:30-62`).

**Verified access.** `lib/email/outbox.ts:23-95`, `lib/push/campaigns.ts:282-404`, `lib/push/adminBroadcast.ts:75-84`, `app/api/integrations/github/reengagement/route.ts:25-54`, and `app/api/admin/reengagement/enroll/route.ts:54-58` use service-side paths. Delivery claiming uses `claim_notification_delivery` through `lib/email/outbox.ts:63-70`.

**Impact.** Direct table isolation is appropriate because rows include profile associations, campaign identifiers and provider state. The separate SECURITY DEFINER claim function has a live grant issue documented below; that is distinct from this table’s no-policy design.

**Resource Center relevance:** None at launch. Do not use the notification outbox for editorial revisions or article publication.

**Classification:** Intentional table design; potential security concern exists in its worker RPC grant.

### 3.6 `public.visitor_daily_metrics`

**Verified schema and state.** The table stores `day`, an opaque `visitor_key`, positive `page_views`, `first_seen` and `last_seen`; primary key `(day, visitor_key)`. The migration explicitly revokes all table privileges from `anon` and `authenticated` and grants service-role select/insert/update (`0086_add_daily_visitor_metrics.sql:13-18`). Exact live count is 1,335.

**Verified access.** `app/api/events/route.ts:49-70` uses `createServiceClient()` and calls `record_visitor_page_view`. Admin analytics calls `get_daily_visitor_metrics`; the migration function checks `is_admin(auth.uid())` before aggregating (`0086_add_daily_visitor_metrics.sql:68-108`).

**Impact.** The table intentionally avoids raw IP/user-agent storage and browser table access. The live function ACL nevertheless shows `get_daily_visitor_metrics` executable by `anon` and `authenticated`; the function’s internal admin check is the compensating control. This remains a defense-in-depth grant issue, not a demonstrated data disclosure.

**Resource Center relevance:** None. Article analytics should be designed separately with privacy/consent review.

**Classification:** Intentional and low risk for the table itself; requires grant review for the aggregate function.

### 3.7 `public.workflow_jobs`

**Verified schema and state.** The table stores durable job state: UUID `id`, `kind`, unique `idempotency_key`, JSON `payload`, status constrained to pending/leased/succeeded/retryable/dead_letter, attempts, availability/lease/correlation/error/result fields and timestamps. Exact live count is 3. The repository migration says it is a service-role/worker ledger with RLS and no public policies (`0036_add_workflow_outbox_foundation.sql:1-28`).

**Verified access.** `app/api/integrations/github/discovery-jobs/route.ts:11-36` uses service-role access for claim, enqueue and completion. `app/api/integrations/github/reengagement/route.ts:25-55` uses service-role access for idempotent job creation and completion. `app/api/admin/discovery/operations/route.ts:7-22` uses service-role access after `assertAdmin()` to read operational status.

**Impact.** No-policy table isolation is intentional, but live function privileges are not aligned with the intended service-only boundary: `claim_workflow_job` and `complete_workflow_job` are effectively executable by `anon` and `authenticated`, although the migration explicitly revokes public and grants service-role only. Both functions mutate/return workflow state. No direct browser RPC call was found in the application source, and no exploit call was performed; the live grant is nevertheless a verified potential security concern.

**Resource Center relevance:** None. Do not schedule editorial publication through this generic job table until worker grants are reconciled and the job contract is explicitly approved.

**Classification:** Potential security concern.

## 4. SECURITY DEFINER function investigation

### 4.1 Live grant summary

The live catalog contains 31 `public` SECURITY DEFINER functions. All inspected functions are owned by `postgres`. Effective privileges were checked for `public`, `anon`, `authenticated`, and service-role-related access without invoking mutation functions.

- **16 functions:** effective `PUBLIC` execution is true; this also implies anon/authenticated execution.
- **12 functions:** `PUBLIC` execution is false, but `anon` and/or `authenticated` execution is true.
- **3 functions:** public/anon/authenticated execution is false; service-role/postgres access is present.

The existence of a grant is verified. Exploitation is not demonstrated because this phase did not call functions as anonymous or authenticated users.

### 4.2 Function-by-function matrix

All rows below are `public.<function>`, `SECURITY DEFINER`, owner `postgres`.

| Function and signature | Current effective execution | Privileged operation / sensitive access | Existing route or trigger | Resource Center relationship | Classification |
|---|---|---|---|---|---|
| `award_xp(p_profile_id uuid, p_event_type text, p_points integer, p_dedupe_key text, p_metadata jsonb)` | service-role/postgres only | XP ledger mutation; profile-linked | `app/api/xp/share/route.ts:110-132` | None | Intentional service-only |
| `check_achievements()` | PUBLIC | Trigger function; delegates achievement checks | Achievement trigger | None | Potential security concern: trigger-only grant |
| `check_application_submitted()` | PUBLIC | Trigger/achievement side effects | Application trigger | None | Potential security concern: trigger-only grant |
| `check_community_discussion_achievements()` | PUBLIC | Trigger/achievement side effects | Community trigger | None | Potential security concern: trigger-only grant |
| `check_community_reaction_achievements()` | PUBLIC | Trigger/achievement side effects | Community reaction trigger | None | Potential security concern: trigger-only grant |
| `check_first_action_achievements()` | PUBLIC | Trigger/achievement side effects | Saved/application triggers; migration `0008...:105-125` | None | Potential security concern: trigger-only grant |
| `check_rate_limit(p_key text, p_max_attempts integer, p_window_seconds integer)` | service-role/postgres only | Rate-limit state operation | Called through server-side rate-limit boundary | None | Intentional service-only |
| `check_referral_completion()` | PUBLIC | Trigger/referral achievement side effects | Referral trigger | None | Potential security concern: trigger-only grant |
| `claim_notification_delivery(p_delivery_id uuid, p_lease_until timestamptz)` | anon + authenticated; PUBLIC false | Mutates and returns notification delivery lease state | `lib/email/outbox.ts:63-70`; migration `0051...:28-29` expects service-role only | None | Potential security concern; live grant drift |
| `claim_workflow_job(p_kind text, p_lease_until timestamptz)` | anon + authenticated; PUBLIC false | Mutates and returns a workflow job lease/payload | `app/api/integrations/github/discovery-jobs/route.ts:11-17`; migration `0064...:50-51` expects service-role only | None | Potential security concern; live grant drift |
| `complete_workflow_job(p_job_id uuid, p_success boolean, p_result jsonb, p_error jsonb, p_retry_at timestamptz)` | anon + authenticated; PUBLIC false | Mutates job status/result/error/dead-letter state and returns the row | `app/api/integrations/github/discovery-jobs/route.ts:34-38`; migration `0064...:73-74` expects service-role only | None | Potential security concern; live grant drift |
| `flag_expired_opportunities()` | anon + authenticated; PUBLIC false | Updates opportunity expiration state | `app/api/cron/deadline-check/route.ts:20-22` via service client | None | Potential security concern; verify internal auth and revoke browser execution if not needed |
| `get_admin_metrics_summary(p_since timestamptz)` | anon + authenticated; PUBLIC false | Reads events/applications aggregate; migration body includes admin predicate | `app/admin/page.tsx:48`; admin API path | None | Grant too broad for defense-in-depth; owner confirmation |
| `get_auth_confirmation_email_analytics(p_since timestamptz, p_until timestamptz)` | anon + authenticated; PUBLIC false | Reads confirmation analytics and `auth.users` confirmation timestamps; function checks admin | `app/admin/page.tsx:48-58` and admin analytics | None | Sensitive read; grant too broad, internal check verified |
| `get_community_contributor_profile(p_discussion_id uuid)` | anon + authenticated; PUBLIC false | Public contributor projection by discussion | `app/api/community/contributors/[discussionId]/route.ts:15` | No; public contributor display only | Likely intentional but review exact projection |
| `get_daily_visitor_metrics(p_since timestamptz, p_until timestamptz)` | anon + authenticated; PUBLIC false | Aggregates visitor keys/page views; migration body checks admin | `app/admin/analytics/page.tsx:57`; admin analytics API | None | Sensitive aggregate; grant too broad, internal check verified |
| `get_provider_analytics(p_since timestamptz, p_until timestamptz, p_scholarship_id uuid)` | anon + authenticated; PUBLIC false | Reads profiles, events, applications, demographic aggregates; function checks admin | `app/admin/analytics/page.tsx:51`; `app/api/admin/analytics/route.ts:116` | None | Sensitive aggregate; grant too broad, internal check verified |
| `get_public_contributor_profile(p_profile_id uuid)` | anon + authenticated; PUBLIC false | Public contributor projection | `app/community/contributors/[profileId]/page.tsx:25` | No; public contributor display only | Likely intentional but review privacy projection |
| `get_scholarship_discussions(p_scholarship_id uuid, p_sort text, p_limit integer)` | PUBLIC | Public discussion read function | `lib/scholarship-community.ts:112` | None | Public by design, but ensure bounded limit and safe projection |
| `get_scholarship_social_proof(p_scholarship_id uuid)` | PUBLIC | Public social-proof aggregate/read | `lib/scholarship-community.ts:117` | None | Public by design |
| `get_trending_scholarship_ids(threshold integer, days integer)` | anon + authenticated; PUBLIC false | Reads aggregate interaction data | `app/dashboard/page.tsx:39` | None | Review whether authenticated-only grant is required |
| `handle_new_user()` | PUBLIC | Inserts initial `profiles` row from auth trigger | Trigger on `auth.users`; `0001_init.sql:134-150` | None | Trigger-only grant should be reviewed |
| `is_admin(uid uuid)` | PUBLIC | Reads role/admin state and returns boolean | Used by RLS and functions | Resource editor authorization dependency | Public role oracle; retain only if required by policy design, otherwise restrict safely |
| `notify_discussion_helpful()` | PUBLIC | Trigger notification side effect | Community trigger | None | Trigger-only grant should be reviewed |
| `notify_discussion_reply()` | PUBLIC | Trigger notification side effect | Community trigger | None | Trigger-only grant should be reviewed |
| `publish_discovery_candidate(candidate_id uuid)` | anon + authenticated; PUBLIC false | Inserts scholarship/rules, updates discovery candidate, records review event; function checks admin and readiness | `app/api/admin/discovery/route.ts:40`; migration `0064...:76-115` | None | Sensitive mutation; internal admin check verified, grant still broader than needed |
| `record_visitor_page_view(p_visitor_key text, p_seen_at timestamptz)` | service-role/postgres only | Inserts/updates visitor daily metrics | `app/api/events/route.ts:67-70` | None | Intentional service-only |
| `run_achievement_checks(p_profile_id uuid)` | PUBLIC | Reads profile/application/save/referral state and inserts achievements/XP | Trigger delegates; no direct Resource Center route | None | Mutation-capable public grant; review |
| `seed_scholarship_prompts()` | PUBLIC | Seed/maintenance operation for scholarship prompts | No direct app call identified | None | Potential security concern; maintenance function should not be public |
| `sync_scholarship_discussion_helpful_count()` | PUBLIC | Trigger-maintained count synchronization | Discussion trigger | None | Trigger-only grant should be reviewed |
| `sync_waec_summary_fields()` | PUBLIC | Trigger-maintained profile/WAEC summary synchronization | Profile/WAEC trigger | None | Sensitive profile-related trigger grant should be reviewed |

### 4.3 Practical risk interpretation

The most concrete verified issue is not that every function is exploitable, but that live execution privileges are broader than the apparent application design. A browser can normally reach Supabase RPC endpoints directly even when the application UI does not expose a button. A no-argument trigger function with PUBLIC execution may be callable directly unless PostgreSQL trigger-only semantics or an internal check prevents useful abuse. A function that mutates workflow or delivery state should not rely on “the frontend does not call it.”

The worker grant mismatch is especially important because the repository’s own migrations document the intended boundary: service-role-only claim/complete functions. The live catalog reports `anon`/`authenticated` execution. This may have arisen from a later grant, a migration drift, or a Supabase default/privilege change; the cause was not established in this read-only phase. The owner should compare all applied migration definitions and ACL changes before implementation.

Some functions contain their own admin checks, including the inspected provider analytics, confirmation-email analytics, daily visitor aggregate, and discovery publication paths. That is a meaningful compensating control and means the report does not claim an unauthenticated data breach. It does not make the grants ideal: reducing execution privileges remains the narrowest defense-in-depth fix, subject to controlled regression testing.

## 5. Existing admin authorization assessment

### 5.1 Admin Server Component page

The sequence is:

1. `middleware.ts` refreshes the Supabase session and handles protected-path behavior.
2. `app/admin/layout.tsx` invokes `requireAdmin()` from `lib/admin/access.ts` for the admin subtree.
3. `requireAdmin()` calls `supabase.auth.getUser()` and redirects unauthenticated users to `/login?next=/admin`.
4. It reads the current user’s `profiles.is_admin` and `community_role`.
5. Non-admin users are redirected to `/dashboard`.
6. If `requireAal2` is requested or `REQUIRE_ADMIN_MFA=true`, it checks the Supabase MFA assurance level and redirects to `/settings/security?required=admin-mfa` unless current and next levels are `aal2`.

`lib/admin/access.ts:10-35` is the relevant source.

### 5.2 Admin API route

The sequence is:

1. `middleware.ts:192-214` checks that `/api/admin/*` has a user and that `profiles.is_admin = true`; it optionally enforces AAL2 when `REQUIRE_ADMIN_MFA=true`.
2. The route handler creates the normal server Supabase client.
3. The route calls `assertAdmin()` in `lib/admin/guard.ts:19-83`.
4. `assertAdmin()` independently calls `auth.getUser()`, reads `profiles.is_admin` and `community_role`, optionally enforces founder status, and optionally enforces AAL2.
5. Only after this guard does the route query or mutate domain data.

Examples: `app/api/admin/scholarships/route.ts:65-90`, `app/api/admin/member-roles/route.ts:12-15`, `app/api/admin/discovery/operations/route.ts:7-13`, and `app/api/admin/digest/route.ts:24-33`.

### 5.3 Privileged database operation

The preferred path is a guarded route using the normal server client, so RLS remains active and the database policy checks the authenticated identity. Some operational routes intentionally create a server-only service-role client after authentication/authorization, for example discovery operations, broadcast delivery, digest sending and worker integrations. `lib/supabase/service.ts` is server-only and bypasses RLS; it must never be used for ordinary public article reads.

For a Resource Center, public pages should use the normal server/browser-safe read path against a published-only policy. Publishing mutations should be server-side, validate the session and admin/editor capability before using either normal RLS writes or a tightly scoped service operation, and record the actor in article/revision/audit fields.

### 5.4 MFA-required operation

The existing model supports staged AAL2 enforcement. Global admin API MFA is controlled through `REQUIRE_ADMIN_MFA`; `assertAdmin()` also supports per-operation `requireAal2`. A Resource Center publish/schedule action can require AAL2 without weakening ordinary admin reads. The narrowest approach is to keep current middleware and guards unchanged, use `assertAdmin(supabase, { requireAal2: true })` for publication/scheduling if the owner wants explicit step-up, and keep preview/read operations behind the ordinary admin guard.

### 5.5 Suitability for `/admin/resources`

The model is sufficient for first release without new roles. Add a dedicated route group and route handlers that reuse `requireAdmin()`/`assertAdmin()`, then apply a narrow editorial capability check. For the first release, `profiles.is_admin` can be the editor/reviewer capability, while workflow rules prevent self-approval. Do not infer editorial authority from public profile fields, client-side state, or a hidden UI control.

A future role table may be justified if the owner needs non-admin editors or distinct reviewer permissions. That is not necessary to launch a safe admin-only first release and should not be introduced during the Resource Center schema phase without an explicit authorization decision.

## 6. Editorial identity recommendation

### Option A — Direct `profiles.id`

This is the smallest schema, but it couples public editorial identity to a private student profile. Even with a carefully selected projection, future profile changes, deletion, privacy withdrawal, or sensitive-column joins can create accidental disclosure. It also does not naturally support guests.

### Option B — Separate editorial identity linked optionally to a user

This cleanly separates public display fields and allows guest authors. It requires one more table and an editorial lifecycle, but it is the strongest privacy boundary and is easy to query through a safe public projection.

### Option C — Hybrid (recommended)

Create a separate `resource_editorial_identities` table containing only public editorial fields and an optional `user_id` link to `auth.users`/`profiles`. Articles reference this table twice: `author_editorial_identity_id` and `reviewer_editorial_identity_id`. Internal association is preserved, public profile data is not exposed, and a future guest can have `user_id IS NULL`.

Recommended rules:

- The public query exposes only `display_name`, `bio`, and optional approved `avatar_path`/public URL.
- `user_id` is administrative-only and must never be selected by the public article query.
- A linked identity can be disabled/archived without deleting historical article attribution.
- Author and reviewer must be separate nullable relationships, not one overloaded “owner” field.
- A published article must have an approved author identity and a reviewer identity unless the owner explicitly approves a one-person exception for a low-risk content type.
- Guest identities require explicit owner approval and the same content review policy.

## 7. Final proposed database schema

The following is a design specification only. No table or migration was created.

### 7.1 `resource_editorial_identities`

| Column | Type / nullability / default | Keys and constraints | Visibility |
|---|---|---|---|
| `id` | `uuid NOT NULL DEFAULT gen_random_uuid()` | PK | Public as opaque relation only; not normally rendered |
| `user_id` | `uuid NULL` | FK to `auth.users(id)` `ON DELETE SET NULL`; unique when non-null | Admin only |
| `display_name` | `text NOT NULL` | Check trimmed length 1–160 | Public |
| `bio` | `text NULL` | Check max length, sanitized at write | Public |
| `avatar_path` | `text NULL` | Check approved storage-path shape; no arbitrary remote URL | Public only through safe image URL/proxy |
| `is_active` | `boolean NOT NULL DEFAULT true` | — | Admin only |
| `created_at` | `timestamptz NOT NULL DEFAULT now()` | — | Admin only |
| `updated_at` | `timestamptz NOT NULL DEFAULT now()` | — | Admin only |

Indexes: unique partial index on `user_id WHERE user_id IS NOT NULL`; index on `(is_active, display_name)`. Do not cascade-delete the identity when a user account is removed; historical attribution must survive.

### 7.2 `resource_categories`

| Column | Type / nullability / default | Keys and constraints | Visibility |
|---|---|---|---|
| `id` | `uuid NOT NULL DEFAULT gen_random_uuid()` | PK | Public relation only |
| `slug` | `text NOT NULL` | Unique; lowercase URL-safe check | Public |
| `name` | `text NOT NULL` | Unique case-insensitive policy or normalized slug | Public |
| `description` | `text NULL` | Sanitized/max length | Public |
| `display_order` | `integer NOT NULL DEFAULT 0` | Check `>= 0` | Public |
| `is_active` | `boolean NOT NULL DEFAULT true` | — | Public filter; admin controls |
| `created_at` | `timestamptz NOT NULL DEFAULT now()` | — | Admin only |
| `updated_at` | `timestamptz NOT NULL DEFAULT now()` | — | Admin only |

Indexes: unique `slug`; `(is_active, display_order, slug)`. Category deletion should be blocked while referenced by a published article, or implemented as archive/deactivate. Do not silently cascade-delete article taxonomy.

### 7.3 `resource_articles`

| Column | Type / nullability / default | Keys and constraints | Visibility |
|---|---|---|---|
| `id` | `uuid NOT NULL DEFAULT gen_random_uuid()` | PK | Public opaque relation only |
| `slug` | `text NOT NULL` | Unique; lowercase URL-safe check | Public |
| `title` | `text NOT NULL` | Max length; sanitized | Public when published; drafts admin only |
| `excerpt` | `text NULL` | Max length; sanitized | Public when published |
| `content_markdown` | `text NOT NULL DEFAULT ''` | Sanitized on write; bounded size | Public only when published; admin drafts/revisions |
| `status` | `text NOT NULL DEFAULT 'draft'` | Check `draft`, `in_review`, `scheduled`, `published`, `archived` | Public filter; admin controls |
| `scheduled_for` | `timestamptz NULL` | Required for `scheduled`; must be future at scheduling time | Admin only; public filter uses it |
| `published_at` | `timestamptz NULL` | Required for `published`; immutable publication event except correction workflow | Public if published and arrived |
| `archived_at` | `timestamptz NULL` | Required when archived | Admin only |
| `last_reviewed_at` | `timestamptz NULL` | Required for deadline/eligibility-sensitive content | Public display for trust |
| `canonical_url` | `text NULL` | Valid absolute `https` URL or null; do not allow `javascript:`/`data:` | Public metadata |
| `featured_image_path` | `text NULL` | Approved storage path only | Public only for published articles |
| `article_type` | `text NOT NULL DEFAULT 'guide'` | Small launch enum/check | Public |
| `reading_time_minutes` | `integer NULL` | Check positive and bounded | Public |
| `author_identity_id` | `uuid NOT NULL` | FK to editorial identity `ON DELETE RESTRICT` | Public display through safe identity projection |
| `reviewer_identity_id` | `uuid NULL` | FK to editorial identity `ON DELETE RESTRICT`; required before publish by workflow constraint | Public display only if approved; internal association admin-only |
| `created_by` | `uuid NULL` | FK to `auth.users(id)` `ON DELETE SET NULL` | Admin only |
| `updated_by` | `uuid NULL` | FK to `auth.users(id)` `ON DELETE SET NULL` | Admin only |
| `created_at` | `timestamptz NOT NULL DEFAULT now()` | — | Admin only |
| `updated_at` | `timestamptz NOT NULL DEFAULT now()` | — | Public metadata may expose date only if approved |

Indexes: unique slug; `(status, published_at DESC)`; `(status, scheduled_for)`; `(author_identity_id)`; `(reviewer_identity_id)`; optionally a partial index for public reads where `status = 'published'` and `published_at IS NOT NULL`. Enforce `published_at <= now()` in the query/policy rather than a time-dependent CHECK constraint.

Article deletion should be archival by default. Hard deletion should be restricted to a separate owner-level maintenance action and should not be part of the first release. Revisions should prevent data loss during correction.

### 7.4 `resource_article_categories`

| Column | Type / nullability / default | Keys and constraints | Visibility |
|---|---|---|---|
| `article_id` | `uuid NOT NULL` | FK to articles `ON DELETE CASCADE` | Public relation for published articles |
| `category_id` | `uuid NOT NULL` | FK to categories `ON DELETE RESTRICT` | Public relation for published articles |
| `created_at` | `timestamptz NOT NULL DEFAULT now()` | — | Admin only |

Primary key `(article_id, category_id)`. Index `(category_id, article_id)`. No duplicate associations. At launch require at least one active category for an article submitted for review; whether drafts may be uncategorized is an editorial decision.

### 7.5 `resource_revisions`

| Column | Type / nullability / default | Keys and constraints | Visibility |
|---|---|---|---|
| `id` | `uuid NOT NULL DEFAULT gen_random_uuid()` | PK | Admin only |
| `article_id` | `uuid NOT NULL` | FK to article `ON DELETE CASCADE` | Admin only |
| `revision_number` | `integer NOT NULL` | Unique with article; positive | Admin only |
| `title` | `text NOT NULL` | Snapshot | Admin only; public only through current published article |
| `excerpt` | `text NULL` | Snapshot | Admin only |
| `content_markdown` | `text NOT NULL` | Immutable snapshot | Admin only |
| `change_summary` | `text NULL` | Sanitized/max length | Admin/reviewer only |
| `created_by` | `uuid NULL` | FK auth user `ON DELETE SET NULL` | Admin only |
| `created_at` | `timestamptz NOT NULL DEFAULT now()` | — | Admin only |

Unique `(article_id, revision_number)`, index `(article_id, revision_number DESC)`. No UPDATE or DELETE policies for ordinary editors. Corrections create a new revision; rollback means promoting a prior revision into a new revision, not mutating history.

### 7.6 Explicit launch omissions

Tags are omitted because the brief does not establish a launch requirement. Comments, article reactions, user submissions, AI provenance, ad placements and article analytics are separate future designs. A Resource Center article may store source references as sanitized links in content or, if the owner later requires structured citation reporting, through a separately approved `resource_article_sources` table. Do not add redundant copied profile fields to articles.

## 8. RLS policy matrix

The proposed model must use database policies, not frontend hiding. Public queries must be inherently limited to published articles whose publication time has arrived.

| Table | Anonymous | Authenticated student | Authorized editor | Authorized reviewer | Existing admin | Server-side privileged |
|---|---|---|---|---|---|---|
| `resource_editorial_identities` | Read only active approved display fields through a safe public projection, or no direct table read | Same public projection | Read/write approved editorial fields; cannot alter audit history freely | Read approved fields | Full editorial management | Full controlled access |
| `resource_categories` | Read active categories only | Same | Create/update/deactivate; no destructive delete while referenced | Read | Full management | Full controlled access |
| `resource_articles` | `SELECT` only where `status='published' AND published_at IS NOT NULL AND published_at <= now()`; no draft/revision/reviewer fields | Same public policy; no write | Read drafts assigned/owned as permitted; create/update drafts; submit for review; cannot approve own article | Read submitted/in-review content and reviewer-visible fields; can return/recommend changes; cannot edit author content unless explicitly assigned | Full editorial/admin workflow; publish/archive; preferably AAL2 for publish | Controlled maintenance/scheduling only |
| `resource_article_categories` | Read associations only through published articles | Same | Manage associations for editable articles | Read/manage during review if needed | Full | Full |
| `resource_revisions` | No access | No access | Insert revisions for editable articles; no update/delete | Read revisions for assigned review; no destructive mutation | Read/restore by creating a new revision | Full controlled maintenance |

For the first release, “authorized editor,” “authorized reviewer,” and “existing admin” can all be represented by `profiles.is_admin = true`, with workflow checks providing separation of duties. A future role table is not necessary. If the owner later delegates editing to non-admin accounts, introduce a dedicated capability model rather than weakening article policies.

The public policy must not expose `reviewer_identity_id`, `created_by`, `updated_by`, revision bodies, change summaries, internal notes, or `user_id`. If a public join is used for author display, select only active identity display fields and never join the entire profile row.

Publishing and scheduling authorization must be validated twice: in the server route/action and in the database policy/function boundary. The write path must validate status transitions, author/reviewer identities, categories, content safety, canonical URL, image path, and self-approval rules. Do not rely on a client-side disabled button.

## 9. Content format and rendering recommendation

### Comparison

- **Structured JSON blocks:** strongest control over allowed elements and rendering, easy to validate, but more editor complexity and awkward for long-form copy unless a block editor already exists.
- **Markdown in PostgreSQL:** compact, portable, mobile-friendly and suitable for headings/lists/tables/code/citations, but must be parsed and sanitized with a strict allowlist. Raw HTML and dangerous URL schemes must be rejected.
- **HTML in PostgreSQL:** easiest to render but highest stored-XSS and maintenance risk; not recommended for launch.

### Recommendation

Use sanitized Markdown for the first release only if the existing dependency set already contains a trusted renderer/sanitizer that can be configured with an allowlist. Otherwise use a small structured-block JSON schema and render known block types with existing React components. Do not introduce a new package merely for convenience; first demonstrate the current package set is insufficient.

For either approach:

- Escape/sanitize before storage and again at render time.
- Permit only `https` and approved internal relative links; reject `javascript:`, `data:`, `vbscript:`, unsafe protocol-relative forms and arbitrary inline HTML.
- Permit a defined heading hierarchy, paragraph, emphasis, strong text, lists, blockquotes, tables, code blocks and source links.
- Validate images by approved Supabase Storage path or trusted origin, MIME type, size and dimensions; do not accept arbitrary remote image URLs by default.
- Require one H1 supplied by the page shell/title and prevent content from creating competing H1s.
- Preserve accessible table headers, alt text and keyboard navigation.
- Render public article pages as server components with crawler-visible HTML, metadata, canonical URLs, Article JSON-LD and BreadcrumbList JSON-LD.
- Store external citations as visible links and source metadata; deadline/eligibility claims must have a `last_reviewed_at` and official source reference.
- Never pass student profile or matching data into article rendering or advertising.

## 10. Publishing workflow

### Permitted states

`draft → in_review → scheduled → published → archived`

Allowed side paths:

- `in_review → draft` when the reviewer returns the article for changes.
- `scheduled → draft` when scheduling is cancelled or the article requires correction before publication.
- `published → draft` only through an explicit correction workflow that creates a new revision and preserves the prior published revision; do not silently overwrite the live version.
- `published → archived` for withdrawal, staleness or replacement.
- `archived → draft` only by an authorized admin, creating a new working revision.

### Ownership and approval

An author/editor may create and edit a draft and submit it for review. A reviewer must verify content safety, sources, mobile readability, canonical data, image rights and deadline-sensitive claims. The reviewer cannot be the same person as the author for the normal workflow. Self-approval should be prohibited because it weakens the only human separation-of-duties control.

An existing admin can be both author and reviewer only under an explicit owner-approved emergency exception, recorded in the revision/audit history. The safer first-release rule is to require two distinct editorial identity IDs for publication.

Only an authorized reviewer/admin may approve `in_review → scheduled` or `in_review → published`. Scheduling stores `scheduled_for`; a server-side scheduled operation promotes due rows only after rechecking the article state and reviewer approval. The scheduler must be idempotent and must not publish an article whose revision or source review has changed since approval.

Publication records `published_at`, reviewer identity and the revision promoted. Article reads filter on status and time, so scheduled content is not publicly visible before its time. Corrections create a new revision and new review decision; the original revision remains immutable.

## 11. Migration safety plan

### Versioning

The repository has historical numeric filename collisions, including the previously identified duplicate `0102` names. Filenames are therefore not a safe unique identity key. New migrations should use a globally unique UTC timestamp prefix, for example `20261106190000_create_resource_center_schema.sql`, selected after checking both the repository and live `supabase_migrations.schema_migrations` table. Do not reuse a historical numeric prefix and do not rely on alphabetical order alone.

### Preflight and drift checks

Before creating a migration:

1. Fetch the current repository branch and compare migration files by content, not only filename.
2. Read the live applied migration tail and check for duplicate-version history.
3. Inspect live tables, constraints, indexes, policies, storage buckets, functions and grants.
4. Verify that no Resource Center object already exists under a variant name.
5. Generate a schema/policy diff for review.
6. Test the migration against a disposable non-production Supabase project or a local Postgres/Supabase environment with representative RLS tests.
7. Confirm the migration is additive and has a forward-fix or reversible operational plan.

### Staging availability

The connected Supabase organization lists `scholarship-platform` and another active project named `serena`. The inspection did not establish that `serena` is a Scholars staging/development project, nor that it is safe to mutate. Treat staging as **unverified/unavailable** until the owner confirms its purpose and access boundaries. Do not use it for testing based on its name alone.

### Rollback and production data protection

Do not write destructive down migrations as the default. For schema mistakes, use a reviewed forward-fix migration. For a failed migration, stop before application rollout, inspect the transaction/error, and restore only through a tested operational procedure. Never delete production content, revisions or images as part of a Resource Center rollback. Feature-flag the public route and publishing actions separately. Keep the new schema isolated so disabling the route does not affect scholarship, profile or application tables.

For scheduled publication, rollback means disabling the scheduler/public route or archiving affected content through an audited operation, not deleting rows. Before any production migration, take an owner-approved database backup and verify restore procedures.

## 12. Resource Center implementation sequence

No step below is authorized by this report; it is the narrowest recommended sequence after approval.

1. **Schema and RLS:** create only the approved Resource Center tables, constraints, indexes, policies and optional storage path/bucket rules. Independently test anonymous published reads and all denials before building the editor.
2. **Public read-only pages:** add `/resources`, category views only if needed, and `/resources/[slug]` using normal server reads and published/time predicates. No publishing mutation.
3. **Administrative editorial interface:** add `/admin/resources` and guarded APIs/actions using existing admin guards. Build draft editing and revision creation first; do not add publication in the same first increment if avoidable.
4. **Publishing and scheduling:** add review, approval, scheduling, idempotent due-publication processing, archive and correction flow. Require separate author/reviewer identities and test AAL2 behavior.
5. **SEO and sitemap:** add metadata, canonicals, Article/BreadcrumbList JSON-LD, internal links, and sitemap entries only for public published articles.
6. **Content upload/storage:** add only after the image policy is approved. Use safe paths, MIME/size validation and no arbitrary remote image embedding.
7. **Advertising/monetization:** defer. Perform privacy/consent, ad labeling, performance and policy review before any AdSense script, `ads.txt` or targeting changes.

Each stage should have a deployable checkpoint and can be independently disabled. No stage should modify the matching evaluator, eligibility rules, student profile authorization, application state, scholarship publication workflow or notification worker.

## 13. Regression test plan

### Resource Center access and content security

- Anonymous users can read a published article whose `published_at` has arrived.
- Anonymous users receive no draft, in-review, scheduled, archived, revision or reviewer-note data.
- Anonymous users cannot read a scheduled article before its time, even by slug or direct API query.
- Authenticated students have exactly the same public read boundary and no admin/editor writes.
- Editors can create/update drafts only within their capability boundary.
- Reviewers can review and return content but cannot self-approve.
- A different reviewer can approve and schedule an author’s article.
- Publishing requires the required MFA/AAL2 condition when configured.
- Slug uniqueness rejects collisions safely and preserves existing public URLs.
- Revisions are immutable to editors and inaccessible to public users.
- A correction creates a new revision and preserves the prior audit record.
- Scheduler publication is idempotent and cannot publish an unreviewed/stale revision.
- Category deletion is blocked or archived when referenced.
- Sitemap excludes drafts, in-review, scheduled and archived articles.
- Canonical URLs and JSON-LD match the public route and contain no unsanitized script delimiters.
- Markdown/blocks reject unsafe HTML and URL schemes.
- Image upload rejects unsafe MIME types, oversized files and unapproved paths.

### Existing Scholars regression suite

Run the existing CI typecheck, unit tests and production build, then verify:

- Email/password signup, confirmation, password recovery and reset.
- Google sign-in callback and safe `next` handling.
- MFA enrollment, verification and AAL2 enforcement.
- Student onboarding and profile authorization/withdrawal.
- Dashboard and scholarship matching/eligibility scoring.
- Applications, saved scholarships and deadline state.
- Existing scholarship administration and discovery approval.
- Cron deadline checks and notification workers.
- Broadcast and digest operations.
- GitHub discovery/reengagement integrations.
- Public scholarship/opportunity pages and existing sitemap/robots behavior.
- Admin pages, admin API 401/403 behavior and service-role boundaries.
- No Resource Center code path reads or writes `profiles` sensitive fields, matching records or application state except through explicitly approved public links.

Before implementation, separately regression-test the identified live grant drift. Do not use production mutation calls for this; reproduce in an approved staging target or local database with equivalent ACLs.

## 14. Unresolved blockers

1. The owner has not confirmed whether the second Supabase project `serena` is a safe Scholars staging target.
2. The cause of live ACL drift on worker and analytics functions has not been established.
3. The owner has not chosen between sanitized Markdown and structured blocks after checking existing renderer dependencies.
4. The owner has not approved the editorial identity table and guest-contributor policy.
5. The owner has not confirmed whether all first-release editors/reviewers are existing admins.
6. The owner has not approved the self-approval rule; this report recommends prohibition.
7. The `announcement_log` query in `app/admin/page.tsx` needs owner confirmation and a narrowly scoped remediation plan; this audit did not change it.
8. The existing SECURITY DEFINER PUBLIC grants need a full owner-approved triage, especially trigger-only and mutation-capable functions.
9. Image licensing, storage path policy and article source/citation requirements remain decisions.
10. Advertising remains a later phase and requires privacy/consent and policy review.

## 15. Final recommendation

Do not implement the Resource Center yet. First resolve the live Supabase grant drift and confirm a safe non-production test target. Then approve the hybrid editorial identity model, separate author/reviewer relationships, published-only RLS boundary, immutable revisions, sanitized content format and no-self-approval workflow.

After those decisions, implement additively in the seven stages above. The first database migration must use a unique UTC timestamp version, be tested outside production, and include complete RLS policies before any content row is inserted. Public routes must use ordinary server reads and never the service-role client. Admin publishing must reuse the existing layered guard/MFA model rather than replacing it.

**Final stop condition:** this phase is complete as a read-only clarification. No tables, policies, migrations, routes, components, content records, grants, function definitions, deployments or secrets were changed. The next permitted action is a separately approved implementation phase after the blockers are resolved.
