# Scholars — Administrator Authorization Security Remediation Specification

**Phase:** A0.6 — specification only
**Prepared:** 8–9 November 2026
**Primary repository reviewed:** `ImperioKDB/Scholars`, commit `cf3682ce35912df7b9b9352193630fc404427c7c`
**Documentation repository:** `ImperioKDB/Updates`
**Reference:** A0.5, commit `649d4e9921394120512c88cad98f5d0400ba0d68`; A0.4, commit `01b43be5881cd7050574bc12e180b2ab6a618885`
**Review mode:** narrowly scoped source review and read-only PostgreSQL catalog inspection; no exploit reproduction
**Decision:** **BLOCKED** — do not begin implementation or production change until an isolated Scholars staging environment and an independently verified administrator/recovery process are established.

## 1. Executive summary

A0.5 identified a critical live authorization defect: `authenticated` has effective `INSERT` and `UPDATE` privileges on `profiles.is_admin`; the own-row profile policy permits a user to affect their own row; and no flag-protective trigger, check, or rewrite rule was found. The later table-level grant in `supabase/migrations/0029_fix_profiles_upsert_table_privileges.sql:4` is not neutralized by its column-level revoke at lines 5–6. This is a **VERIFIED — DATABASE** structural self-elevation path. No write, exploit, production API probe, or user-row inspection was performed. The conclusion that the 29 application admin routes could accept a self-elevated caller is **INFERRED** from this database fact and their **VERIFIED — SOURCE** guards, not an observed HTTP exploit.

The live `public.is_admin(uuid)` is a stable SQL `SECURITY DEFINER` function owned by `postgres`, with an empty `search_path`, `PUBLIC EXECUTE`, and a body that returns `profiles.is_admin` for the supplied UUID. `anon`, `authenticated`, `service_role`, and `postgres` have effective SQL `EXECUTE`. It is therefore an arbitrary-UUID membership oracle at the database privilege layer. Direct PostgREST reachability remains **UNVERIFIED**; the arbitrary-UUID oracle is a separate finding from the self-elevation path and does not itself change `auth.uid()`.

A0.6’s targeted catalog checks found 55 live RLS policy definitions whose expressions mention `is_admin`, eight live routine bodies mentioning the flag/helper (the helper itself, five helper callers, and two routines reading the profile flag directly), and no view definition mentioning the helper. The current helper callers pass `auth.uid()` or an actor variable sourced from it; no legitimate arbitrary-subject admin check was identified in the inspected dependency set. This supports replacing the helper with a current-caller-bound function, but the full dependency migration must be validated against the approved staging database before changing the live schema.

All 29 reviewed `app/api/admin/**/route.ts` files contain a server-side guard. None uses a client-supplied admin/role field as its authorization predicate. However, every route’s effective predicate depends on the authenticated caller’s `profiles.is_admin` value; middleware and Server Component guards share the same trust source. Several routes use server-side service-role access after the guard, so correct ordering does not cure a guard whose underlying flag is user-writable. There are no Resource Center editorial write/publish routes yet; the current admin Resource Center surface is read-only.

**Recommended direction:** retain `profiles.is_admin` as the one platform-admin source for this remediation; remove the effective ordinary-user write path, protect the column with a database invariant, keep profile onboarding/upsert working through a safe allowlisted path, and use an audited, narrowly scoped operation for administrator lifecycle changes. Replace the UUID-accepting helper only after atomically migrating every dependent policy and routine. Do not create a second Resource Center-only admin system or hardcode an administrator identity.

This is specification-only. No application code, migration, database object/data, auth or storage setting, environment variable, project, deployment, or production configuration was changed. No administrator IDs/emails, profile rows, credentials, or secrets were read or recorded.

## 2. Scope, method, and evidence labels

The review reuses A0.4 and A0.5 and inspects only the relevant current guard/access/middleware/client files, the two migrations named in the A0.6 brief, narrowly relevant later profile/upsert and provisioning references, and all 29 admin API routes through the approved route-by-route review. The historical 129-migration review was not repeated. The A0.6 live inspection consisted only of read-only catalog/metadata queries against the source-matched Scholars project `cmdglabohpttgfofcmqc` (`scholarship-platform`), which A0.5 treats as production. No `profiles` or `auth.users` data rows were read.

- **VERIFIED — SOURCE:** directly observed in the cited repository source or migration. Source does not prove a deployed database or environment setting.
- **VERIFIED — DATABASE:** directly observed in read-only PostgreSQL catalog/metadata results for the matched live project.
- **INFERRED:** follows from verified evidence, but was not reproduced by an HTTP request or state-changing test.
- **UNVERIFIED:** the runtime setting, reachability, owner, or behavior was not established.
- **BLOCKED:** must not proceed without the identified safe environment, independent owner decision, or authorization.

A0.5’s exact project mapping, no-branch result, production setting caveats, and method are documented in its §§2, 6, 8–10. The connected `serena` project was excluded and must not be used as Scholars staging. No credentials or environment values were inspected.

## 3. A0.5 finding validation and A0.6 dependency check

### 3.1 Admin flag and helper

| Finding | A0.6 disposition |
|---|---|
| Authenticated effective writes to `profiles.is_admin` | **VERIFIED — DATABASE** in A0.5 §3.3: table-wide profile `INSERT`/`UPDATE` plus effective column rights. The A0.6 read-only check of `profiles.is_admin` metadata found `NOT NULL DEFAULT false`. No write was attempted. |
| Own-row update policy and no flag guard | **VERIFIED — DATABASE** in A0.5 §3.3: own-row policy permits the signed-in user’s row; no admin-flag trigger, check constraint, or rewrite rule was found. |
| Source explanation for privilege regression | **VERIFIED — SOURCE:** migration `0023_lock_admin_flag.sql:11-18,80-114` removes broad grants and grants specific profile columns, then grants helper execution to `PUBLIC`; `0029_fix_profiles_upsert_table_privileges.sql:1-7` later grants table-level `INSERT, UPDATE` and revokes only column-scoped privileges on `is_admin`. The live effective grants confirm that the later table grant wins for the protected column. `0002_harden_functions.sql:1-16` revokes API-role execution and sets an empty path, but does not define the function and is later contradicted by the `PUBLIC` grant in 0023. |
| `public.is_admin(uuid)` | **VERIFIED — DATABASE** in A0.5 §3.1: stable SQL, `SECURITY DEFINER`, owner `postgres` with `BYPASSRLS`, `search_path=''`, body selects `public.profiles.is_admin` for the supplied UUID and defaults false, ACL includes `PUBLIC:EXECUTE`; effective execution is true for anon/authenticated/service_role/postgres. |
| HTTP/PostgREST access to the UUID RPC | **UNVERIFIED.** The exposed-schema configuration and HTTP route were not established; no HTTP RPC request was made. Do not state that the RPC endpoint was reachable. |

The UUID function leaks a Boolean membership result for arbitrary IDs to roles with SQL execute rights. That is a verified SQL-level information oracle; it is not evidence that a UUID argument changes the JWT identity. The separate profile write path is what establishes the structural self-elevation risk.

### 3.2 Profile creation, update, and provisioning

**VERIFIED — DATABASE:** live `profiles.is_admin` is `NOT NULL DEFAULT false`. The Auth `on_auth_user_created` trigger calls `public.handle_new_user()`. Its inspected live/source definition is `SECURITY DEFINER`, owner `postgres`, `search_path=''`; it inserts only `public.profiles(id, full_name)` and uses `ON CONFLICT DO NOTHING` (`supabase/migrations/0021_add_user_presence.sql:20-40`). It does not assign admin state; the false default applies to new profiles.

**VERIFIED — SOURCE:** `app/api/profile/route.ts:36-79` uses an allowlisted Zod schema that omits `is_admin`; `POST` authenticates, validates the profile payload, and upserts `{ id: user.id, ...parsed.data }` with the caller session (`:116-160`). That API route is not itself an admin-flag setter. Its validation is not the database security boundary: a user can address PostgREST or another authenticated client path without going through this handler, so DB grants/policies and a flag guard must independently reject protected-field writes. The `DELETE` handler at `:180-204` deletes only the caller’s own profile; it is not an elevation path but may remove an administrator’s profile and create a recovery/last-admin risk. Test and govern that lifecycle explicitly.

**VERIFIED — SOURCE:** `app/api/admin/member-roles/route.ts:7-37` updates only `community_role` to `student` or `contributor`, rejects a founder target, and does not modify `is_admin`. `app/admin/users/page.tsx:50-64,127-129` uses `requireAdmin()` before a service-role users/profile read and exposes a community-role control, not an `is_admin` setter. No source-grounded application setter for `is_admin` was found in the scoped profile/admin management paths. Other database-side or external service-role writers outside the inspected dependency set remain **UNVERIFIED**.

### 3.3 Downstream dependency inventory

The A0.6 read-only catalog review found **55 live policy definitions** in non-system schemas whose policy expressions mention `is_admin(`. The set includes application policies, Resource Center policies, and storage-object policy expressions; it is not a count of 55 distinct capabilities or 55 admin routes. **Eight live routine bodies** mention `is_admin`: `public.is_admin(uuid)`; `get_admin_metrics_summary`; `get_provider_analytics`; `get_daily_visitor_metrics`; `get_auth_confirmation_email_analytics`; `publish_discovery_candidate`; `flag_expired_opportunities`; and trigger routine `seed_scholarship_prompts`. No view definition from the targeted catalog query mentioned the helper.

The first five depend on the helper directly or through an actor variable initialized from `auth.uid()`. The two other routines read the profile admin flag directly; in the inspected definitions they do not write it. The analytics/publication routines are `SECURITY DEFINER` in the live catalog, so their internal checks must be migrated/tested with the same care as the RLS policies. A0.5 also found `publish_discovery_candidate(uuid)` has an ACL difference from the latest inspected source migration, including explicit anon execution; its body rejects a null actor and checks the same admin helper. Treat the ACL drift as an owner-review item, not proof of successful anonymous publication.

These live counts establish the size of the dependency cutover. Before implementation, rerun an exact function/policy dependency inventory on the approved staging copy and compare it to this baseline; do not assume the historical source file list captures all live objects.

## 4. Existing application authorization architecture

- `lib/admin/guard.ts:19-52` calls `supabase.auth.getUser()`, then reads the authenticated user’s `profiles.is_admin` and `community_role`; it requires `is_admin === true`, optionally requires `community_role === 'founder'`, and returns the authenticated user ID. `:64-81` checks current and next AAL2 only when a call option is passed or `REQUIRE_ADMIN_MFA === 'true'`.
- `lib/admin/access.ts:10-35` is the corresponding Server Component redirect guard and reads the same profile flag; it has the same conditional AAL2/founder behavior.
- `middleware.ts:192-214,304-327` gates `/api/admin/:path*`, reads the same profile flag, and conditionally checks AAL2. Middleware plus route-level guard is defense in depth, not an independent trust source.
- `lib/supabase/server.ts:6,20-46` creates the cookie/session-bound anon-key client and states that RLS applies. `lib/supabase/service.ts:1-23` creates a `server-only` service-role client and explicitly warns it bypasses RLS.
- A0.5 §4 found no missing inline guard among the 29 current admin API route files. The A0.6 route-by-route review also found no route relying on client-supplied `is_admin` or role state as its authorization predicate. It found that all 29 ultimately trust `profiles.is_admin`; route impact is **INFERRED** from the verified mutable flag, not route-runtime evidence.
- Source behavior conditionally checks MFA. No current route call explicitly requests `requireAal2`; whether production Vercel sets `REQUIRE_ADMIN_MFA=true` is **UNVERIFIED**. MFA enrolment support is not proof that admin operations enforce AAL2.
- In the reviewed routes, authorization is ordered before protected reads/writes and before service-role work. Some handlers call rate limiting or validate a path UUID before the guard. Whether every rate limiter has stateful/network effects is route/helper-dependent; such pre-auth throttling is not an authorization check. The only identified partial-write concern is discovery claim review: the claim update can precede a separate audit-event insert (`app/api/admin/discovery/claims/route.ts:22-28`).

## 5. Workstream A — protect `profiles.is_admin`

### 5.1 Keep the existing authority for this remediation

Retain `profiles.is_admin` as the single **platform-admin** source during A0.6/A1. This is the smallest safe conceptual change: it preserves current route and guard semantics and avoids operating two competing admin authorities. The field already has a false default and is used by 55 live policy definitions and eight routine bodies. A separate `admin_members` authority table would require a coordinated rewrite of those dependencies, introduce dual-write/migration questions, and add a second authorization plane without current evidence that delegated per-capability platform roles are necessary.

A separate append-only **audit** relation is recommended for grant/revoke events; it is not an alternate authority. Consider a separate capability/role model later only if an approved business requirement needs delegated platform permissions. Resource Center author/reviewer/publisher capabilities are a distinct future editorial model; they must not be implemented by adding a second Resource Center-only administrator system.

### 5.2 Remove all ordinary-user write paths, not just column grants

The implementation must remove effective `INSERT` and `UPDATE` authority on the protected field from `PUBLIC`, `anon`, and `authenticated`, including inherited/table-level grants. A column-level `REVOKE` cannot cancel a table-level DML grant. Specifically:

1. Revoke the later broad table-level profile grants from ordinary API roles, then grant only the required ordinary profile operations/columns. Keep own-row RLS and add an independent database guard on the admin field.
2. First verify in staging whether the existing PostgREST profile upsert works using only column-level grants. If it does, grant only the explicit safe columns that the API needs. If PostgREST `ON CONFLICT` still requires broader table rights, do **not** restore a broad table grant as the sole solution: replace the generic upsert with a fixed, allowlisted “update my profile” database operation/session route, and retain the flag guard as defense in depth.
3. Add a database-enforced `BEFORE INSERT OR UPDATE` guard for `profiles.is_admin`: ordinary API-role statements may leave the flag unchanged or accept the default false on creation, but cannot set it true, clear another account, or change it. A narrowly owned flag-management function may perform authorized transitions. Prefer an invoker-context trigger test proving direct PostgREST writes are denied even if table grants regress. Exception identity must be a non-login, narrowly privileged function-owner role—not a caller-supplied JWT claim or arbitrary custom session setting. Treat maintenance/bootstrap as a separate owner-authorized process, not a public bypass.
4. Keep `is_admin NOT NULL DEFAULT false`. Do not trust metadata, request JSON, JWT user metadata, client state, profile API validation, or a service-role key supplied by a browser as a source of admin authority.
5. Keep self-row profile update policy for ordinary fields only. A policy such as `auth.uid() = id` is not sufficient for a protected privilege column when ordinary users also have table-wide `UPDATE` rights.

A narrowly scoped administrator-management operation is preferable to granting application code generic profile DML for this column. It must derive the actor from `auth.uid()`, require an already-authorized administrator and AAL2, forbid self-grant, validate a real `auth.users` target, require a reason/change ticket, protect the last active administrator, update the flag and append its audit record in one transaction, and be executable only by the minimum intended role. Service-role usage is not a substitute for these checks. A two-person approval is required for first-admin bootstrap and emergency recovery; apply a second-approver gate to routine grants if owner policy requires it.

### 5.3 Legitimate administrator operations and trusted writes

No existing public self-service admin-registration flow is authorized. No source-grounded legitimate flag setter was found in the scoped app paths, and no inspected live routine is an `is_admin` writer. The only anticipated flag writers should be the restricted lifecycle operation and a separately controlled one-time owner bootstrap/recovery. Confirm this inventory again in staging, including triggers, functions, grants, role memberships, service jobs, and default privileges.

A possible database object design—not SQL for execution—is:

- `profiles.is_admin` remains the authority and defaults false.
- A narrowly owned `NOLOGIN` role owns the flag-management function and has only the required profile-flag DML plus audit insert rights; it has no broad app-table privileges. Review whether it needs `BYPASSRLS`; prefer no bypass where feasible, and if a definer read helper requires it, scope the role’s table grants to the minimum and test for leakage.
- A protected RPC or server endpoint never accepts an `actor_id` as authority. For a signed-in admin it binds actor to `auth.uid()`, checks `profiles.is_admin` via the safe current-caller helper, enforces AAL2, and denies self-grant. Its execute ACL is explicit; `PUBLIC` and `anon` are denied.
- Grant/revoke plus immutable audit event commit or roll back together. Revoke takes effect on the next guard/profile authorization check; do not copy admin privilege into long-lived client claims without a tested revocation strategy.
- First admin is established only by an independently authorized Supabase project/database owner using an approved, private change procedure after verifying the target Auth UUID out-of-band. Do not guess an email/UUID, hardcode an identity, or include account identifiers in this report.

### 5.4 Risk of profile self-deletion

The self-service `DELETE /api/profile` path removes the caller’s profile, which also removes the flag row and may delete dependent app data (`app/api/profile/route.ts:162-204`). This is not self-elevation, but a legitimate administrator could revoke their own access or, if they are the last administrator, leave no ordinary recovery route. During implementation, decide whether an admin profile may self-delete; at minimum, prevent the last confirmed admin from self-deleting through the ordinary user endpoint and test the owner recovery procedure. Do not silently remove the user’s existing privacy deletion right without an approved policy decision; an alternative is to require a separate admin revocation/offboarding step first.

## 6. Workstream B — replace the arbitrary-UUID helper safely

### 6.1 Semantics and target contract

The inspected live RLS policies pass `auth.uid()`; the five helper-calling routines pass `auth.uid()` or an actor ID initialized from it. No inspected legitimate caller needs to ask whether an arbitrary other UUID is an administrator. Therefore, target a zero-argument current-caller helper, conceptually `is_admin_current()`, which:

- obtains the subject only from `auth.uid()` and never accepts a UUID from API input;
- returns `false` for `auth.uid() IS NULL`, a missing profile, or any lookup/error condition that can safely fail closed;
- reveals no arbitrary other user’s membership;
- is `SECURITY DEFINER` only if required to avoid profile-RLS recursion, with a dedicated non-login owner, least privileges, `SET search_path = ''`, fully qualified object names, no dynamic SQL, and no execute rights on unrelated data; verify function ownership and RLS behavior in staging;
- is not callable by `PUBLIC` or `anon`. Grant only the database role(s) needed to evaluate the policies/routines. If it must be executable by `authenticated` for policy evaluation, direct calls may disclose only the caller’s own Boolean status, not any other UUID. Prefer a non-PostgREST-exposed schema if policy privileges and Supabase schema configuration permit it; verify API exposure rather than assuming it.

`SECURITY INVOKER` is not automatically safer if reading `profiles` recursively invokes a policy that calls the helper. Test both execution modes; do not choose an invoker function that silently returns no row or recurses. A definer owner should not be `postgres` by default: use a dedicated `NOLOGIN` role with no superuser rights, no unnecessary `BYPASSRLS`, and only the permissions proven necessary. If RLS recursion forces a narrowly scoped bypass, restrict its table grants, schema rights, ownership, function body, and ACL, and document why.

### 6.2 Compatibility and atomic cutover

Do not change the `public.is_admin(uuid)` signature in isolation. The current migration history itself conflicts (`0002_harden_functions.sql:8-15` versus `0023_lock_admin_flag.sql:107-112`), and live ACLs confirm broad execution. The 55 policy definitions and five routine callers form a dependency cutover.

On staging, capture the exact dependency inventory and baseline grants first. Then prepare one transactional database migration (not to be written or executed in A0.6) that creates/grants the replacement helper, updates every referencing RLS policy and all dependent functions/routines to use the current caller, corrects the profile write boundary, and only then revokes the old helper’s broad execution. Do not create an interval in which a policy calls a function the ordinary role cannot execute, or where the unsafe helper remains the only policy check. Validate transaction behavior for all 55 policy definitions.

For compatibility, the old UUID signature may remain briefly as a restricted shim only if dependency or client evidence requires it: it must reject `NULL` and any `uid IS DISTINCT FROM auth.uid()`, call the new current-caller helper, be non-executable by `PUBLIC` and `anon`, and have only the minimum explicit execute grant needed for the compatibility period. It must never answer for an arbitrary subject. If no supported caller requires the shim, remove it after all dependencies are migrated and verified. No current caller evidence justifies arbitrary-subject semantics. Document and test the removal window; do not leave a permanent legacy oracle.

### 6.3 Other SECURITY DEFINER callers

Replace calls inside `get_admin_metrics_summary`, `get_provider_analytics`, `get_daily_visitor_metrics`, `get_auth_confirmation_email_analytics`, and `publish_discovery_candidate` with the current-caller helper, preserving each function’s intended inputs/results while validating ACLs independently. In particular, review the live anon execute drift on `publish_discovery_candidate(uuid)` against the source migration; its existing null-actor rejection is not a substitute for an explicit, least-privilege ACL. Review `flag_expired_opportunities()` and `seed_scholarship_prompts()` because they read `profiles.is_admin` directly, even though their current execute/trigger roles are restricted; confirm they do not become client-callable or write the protected flag. All names, owners, `SECURITY DEFINER` settings, ACLs, `search_path`, and function behavior must be checked in staging and after a separately approved production migration.

## 7. Workstream C — application authorization route matrix

### 7.1 Common interpretation

For all 29 rows below, the route review found a server-side `assertAdmin` guard (or equivalent shared admin assertion) and no client-supplied admin/role state as the authorization predicate. The effective authority is the authenticated user returned by Supabase `auth.getUser()` plus that caller’s `profiles.is_admin === true`; the founder export adds `community_role === 'founder'`. Middleware checks the same flag. The profile-flag write weakness is **VERIFIED — DATABASE**; route access after self-promotion is **INFERRED**, not runtime-proven. No route was exercised over HTTP, and none of these route results is a claim that production requests were attempted.

“Before” below means before the route’s protected read/write, service-role operation, or external email/push operation. Some handlers call a rate limiter or validate a UUID first; those are not authorization boundaries. RPC execution details are marked unverified where the function was not part of this route review.

| Route / methods | Current guard and ordering | Underlying authorization source | Sensitive action / privileged path | Required remediation |
|---|---|---|---|---|
| `app/api/admin/active-users/route.ts` — GET | `assertAdmin` before profile query and Auth enrichment. | Session user + own `profiles.is_admin`. | Returns up to 200 profile summaries; service-role Auth `listUsers` only for email enrichment, after guard. | Protect flag in DB; retain guard before service client; minimize exported fields. |
| `app/api/admin/analytics/route.ts` — GET | `assertAdmin` before parameters/report data access. | Session user + `profiles.is_admin`. | Analytics RPC/CSV exports, monitoring errors, fix-log metadata; no route service client. RPC internals remain unverified. | Protect flag; independently verify RPC ACLs/guards and export scope. |
| `app/api/admin/broadcast/route.ts` — GET/POST | Guard before privileged reads/recipients/email/push; POST rate limit precedes guard. | Session user + `profiles.is_admin`. | Service-role cross-user reads, email/push broadcast, announcement/delivery log writes. | Protect flag; retain guard before side effects; require AAL2 for high-impact broadcast; audit service-role boundary. |
| `app/api/admin/community-invitations/export/route.ts` — GET | `assertAdmin({ requireFounder:true })` before rate limit/export. | Session user + `profiles.is_admin` + founder `community_role`. | Service-role read/export of consented invitation data including names and phone numbers. | Protect admin flag and founder-role assignment separately; retain gate and minimize PII. |
| `app/api/admin/digest/route.ts` — POST | Rate limiter first, then `assertAdmin`, then body/helper. | Session user + `profiles.is_admin`. | Service-role listing/profile/email resolution, digest delivery, notification and announcement writes. | Protect flag; require AAL2 as policy dictates; keep service use post-guard. |
| `app/api/admin/discovery/claims/route.ts` — PATCH | Rate limit, then guard before JSON, read/update, audit insert. | Session user + `profiles.is_admin`. | Changes claim review status/reviewer/reason; writes separate review-event audit row. | Protect flag; make claim update + audit insert atomic to avoid an unaudited partial result. |
| `app/api/admin/discovery/operations/route.ts` — GET | Rate limit and guard precede service client/reads. | Session user + `profiles.is_admin`. | Service-role reads workflow error/result metadata and discovery candidate state. | Protect flag; retain post-guard, read-only service access. |
| `app/api/admin/discovery/route.ts` — GET/PATCH | Guard before reads, body parsing, update, and publish RPC. | Session user + `profiles.is_admin`. | Reads candidates/claims; PATCH changes review state or invokes `publish_discovery_candidate`. RPC security/side effects need independent verification. | Protect flag; review RPC ACL drift and transactional authorization separately. |
| `app/api/admin/discussion-reports/[id]/route.ts` — PATCH | Rate limit/UUID check precede guard; guard precedes body and moderation writes. | Session user + `profiles.is_admin`. | Updates report status/reviewer; “removed” also hides linked discussion using session client. | Protect flag; verify RLS on both writes; preserve guard. |
| `app/api/admin/discussion-reports/route.ts` — GET | Rate limit then guard before status parsing and select. | Session user + `profiles.is_admin`. | Reads report details, reporter/contact-related data, and joined discussion content. | Protect flag; confirm least-privilege RLS and fields. |
| `app/api/admin/discussions/[id]/route.ts` — PATCH | Rate limit/UUID check then guard; guard before parsing/write. | Session user + `profiles.is_admin`. | Moderates discussion publication/hidden status, pin, contributor verification. | Protect flag; verify mutation RLS; require AAL2 if policy classifies these as high-risk. |
| `app/api/admin/discussions/route.ts` — GET | Rate limit then guard before query. | Session user + `profiles.is_admin`. | Reads discussion bodies/status and joined scholarship metadata. | Protect flag; retain session/RLS and guard. |
| `app/api/admin/feedback/route.ts` — GET/PATCH | Rate limit then guard; reads/body parsing/write after guard. | Session user + `profiles.is_admin`. | Reads contact email/message; changes feedback status/resolution time. | Protect flag; verify RLS and minimize sensitive contact fields. |
| `app/api/admin/independence-day/route.ts` — GET/POST | GET guard precedes service reads; POST rate limit then guard before config/body/side effects. | Session user + `profiles.is_admin`. | Service-role campaign/Auth reads, batch email and push sends, delivery logs. | Protect flag; require AAL2; preserve pre-side-effect gate and server-only credentials. |
| `app/api/admin/member-roles/route.ts` — PATCH | Guard before parsing, target read, or update. | Session user + `profiles.is_admin`. | Changes only target `community_role` to student/contributor and rejects founder target; not an `is_admin` setter. | Protect `is_admin`; separately verify no ordinary path can assign founder; retain guard. |
| `app/api/admin/opportunities/[id]/route.ts` — PATCH/DELETE | Rate limit/ID validation then guard before mutation. | Session user + `profiles.is_admin`. | Updates or deletes opportunities; cache revalidation after write. DB cascade effects not independently verified. | Protect flag; review destructive-action AAL2 and exact RLS/cascade behavior. |
| `app/api/admin/opportunities/route.ts` — GET/POST | Rate limit then guard before read/body/insert. | Session user + `profiles.is_admin`. | Lists/creates opportunities; input may set opportunity `verified` metadata, not admin state. | Protect flag; decide whether `verified` may be client-set by any admin; verify RLS. |
| `app/api/admin/profile-nudges/route.ts` — POST | Rate limit, then guard before JSON/helper operations. | Session user + `profiles.is_admin`. | Service-role helper reads profiles/Auth users, updates reminder/delivery records, sends bulk email; force mode broadens sending. | Protect flag; require AAL2; keep force-send controls and service key server-side. |
| `app/api/admin/reengagement/enroll/route.ts` — POST | Rate limit then guard before JSON and service reads/upsert. | Session user + `profiles.is_admin`. | Service-role reads experiment/assignments and queues delivery records; route says `sends_started:false`. | Protect flag; retain guard; confirm queue semantics and least-privilege scope. |
| `app/api/admin/reengagement/route.ts` — GET/POST | Both rate-limit then guard before service access. | Session user + `profiles.is_admin`. | Service-role reads profiles/events/Auth and creates experiments/assignments; no sends in route. | Protect flag; retain guard before cross-user operations. |
| `app/api/admin/reengagement/summary/route.ts` — GET | Rate limit, then guard before parsing and service reads. | Session user + `profiles.is_admin`. | Service-role reads experiment/assignment/campaign event data and aggregates it. | Protect flag; retain guard and minimize cross-user read access. |
| `app/api/admin/schema-check/route.ts` — GET | Rate limit then guard before fixed `exec_sql` attempt and SELECT probes. | Session user + `profiles.is_admin`. | Diagnostic RPC and schema probes; RPC existence, privilege and execution context are **UNVERIFIED**. No service-role client evidenced. | Protect flag; verify or remove/restrict the diagnostic RPC in staging; do not assume RLS bypass. |
| `app/api/admin/scholarships/[id]/route.ts` — PATCH/DELETE | Rate limit/ID check then guard before body and writes. | Session user + `profiles.is_admin`. | Updates/deletes scholarship; PATCH may write cycle event; delete cascade described in source but not independently verified. | Protect flag; test RLS/cascade and AAL2 for destructive actions. |
| `app/api/admin/scholarships/[id]/rules/[ruleId]/route.ts` — DELETE | Rate limit/UUID checks, then guard before scoped delete. | Session user + `profiles.is_admin`. | Deletes one scholarship rule scoped to scholarship and rule IDs. | Protect flag; verify session RLS and destructive-action policy. |
| `app/api/admin/scholarships/[id]/rules/route.ts` — POST | Rate limit/ID check then guard before body/insert. | Session user + `profiles.is_admin`. | Inserts normalized rule for the path scholarship. | Protect flag; verify session RLS and caller-derived actor handling. |
| `app/api/admin/scholarships/route.ts` — GET/POST | Rate limit then guard before read/body/insert. | Session user + `profiles.is_admin`. | Lists or creates scholarship; may insert rules afterward, so a rules failure can follow a successful scholarship insert. | Protect flag; test RLS and make multi-row creation atomic if all-or-nothing is required. |
| `app/api/admin/test-profile-nudge/route.ts` — POST | Rate limit then guard before body/service/event. | Session user + `profiles.is_admin`. | Service-role Auth search and delivery helper followed by Inngest event; downstream effects are unverified. | Protect flag; require AAL2; constrain test target/environment and retain server-only key. |
| `app/api/admin/testimonials/[id]/route.ts` — PATCH/DELETE | Rate limit/ID validation then guard before consent read/write or delete. | Session user + `profiles.is_admin`. | Updates or deletes a testimonial; no service-role path shown. | Protect flag; verify RLS and any approval/consent policy. |
| `app/api/admin/testimonials/route.ts` — GET/POST | Rate limit then guard before reads/body/insert. | Session user + `profiles.is_admin`. | Reads drafts and creates testimonials; `approved` is content workflow state, not admin authorization. | Protect flag; separately enforce testimonial publication rules if required. |

### 7.2 Cross-route findings

- **Routes without a server-side guard:** none found among the 29 reviewed files.
- **Routes trusting client-supplied administrator state:** none found as the authorization predicate. This does not neutralize direct database writes or the inferred self-elevation path.
- **Routes relying on `profiles.is_admin`:** all 29. The founder-only export additionally checks `community_role`.
- **Routes using service-role privileges:** active-users, broadcast, community-invitations export, digest, discovery operations, independence-day, profile-nudges (through its helper), reengagement/enroll, reengagement, reengagement/summary, and test-profile-nudge. In each reviewed source path, service use is after the app guard. The guard is not an independent trust boundary until its DB source is fixed.
- **Guard timing:** all 29 route reviews found the guard before the protected route data action; rate limits/ID validation may run first. The admin users Server Component (`app/admin/users/page.tsx:50-64`) also runs `requireAdmin()` before its service-role cross-user read. The app admin Resource Center page remains read-only (`app/admin/resources/page.tsx`, A0.5 §4.1).
- **Indirect privilege change:** no reviewed admin route directly writes `profiles.is_admin`. The verified direct-database self-row write path can make any of these guard checks succeed afterward; this is **INFERRED** from A0.5 live grants/policies plus source guard logic. `member-roles` changes community role only; whether another route can assign `founder` is **UNVERIFIED**.
- **No route-specific runtime assessment:** no request, RPC, email, push, database write, or route test was executed. Delegated service/provider details and individual table RLS outcomes remain unverified unless explicitly established above.

## 8. Workstream D — administrator migration, lifecycle, and recovery

The current legitimate admin population, identity owner, independent recovery operator, and any prior misuse are **UNVERIFIED**. No user rows or account identifiers were examined. Do not guess the founder’s email or hardcode a UUID.

1. **Identify safely:** after an authorized owner opens the remediation phase, obtain a read-only list of profile UUIDs currently marked admin from the isolated/staging copy first. For production baseline, an authorized database/security owner may obtain the minimum necessary identifiers through a restricted, audited channel; map UUIDs to Auth identities out-of-band in Supabase Admin UI. Do not place emails, UUIDs, or raw user lists in a repository report. Confirm each candidate with the project/application owner and an independent reviewer.
2. **Freeze and baseline:** record the source commit, applied schema version, effective profile privileges/policies, helper definitions/ACLs, current admin count, and a private encrypted baseline snapshot. Do not alter rows during identification. Investigate any unexpected admin accounts/log evidence under a separate incident-response authorization; A0.6 did not inspect logs or user rows.
3. **Migrate existing admins:** after the protected write path passes staging tests, preserve only owner-approved existing admins. Map the verified UID list through the restricted one-time migration/operation. Do not bulk-promote by email domain, metadata, or `community_role`. Record each transition in an append-only audit relation with actor, target, operation, timestamp, reason/ticket, and result. Verify the independent break-glass identity before closing the change.
4. **Ongoing grants/revokes:** only an already-authorized administrator operating through the restricted, AAL2-protected lifecycle function may propose/execute changes; actor comes from `auth.uid()`, target must exist, self-grant is rejected, reason/ticket is mandatory, and the final admin cannot be removed without project-owner recovery approval. For grants, require a distinct second approver when the owner policy adopts two-person control. All writes and audit entries are one transaction.
5. **First administrator:** because no trustworthy current administrator population or owner identity was established here, the first admin cannot be provisioned by the app. A verified Supabase project owner plus an independent reviewer must approve a one-time, out-of-band operation using the exact target Auth UUID verified privately. No public registration flow, guessed identifier, or hardcoded identity.
6. **Emergency recovery:** document a sealed, owner-controlled Supabase control-plane/database-owner procedure with two-person approval, change ticket, private UID verification, immediate post-change audit, and independent sign-in/AAL2 confirmation. It must not grant ordinary authenticated users table-level DML or a general service-role credential. If the normal function fails, owner-level recovery is distinct from an end-user self-service route.
7. **Revocation:** protected DB reads are evaluated on each request, so database flag changes should deny subsequent requests; verify this in staging across middleware, routes, RLS policies, RPCs, and open sessions. If any future design moves authority into JWT claims or a cache, add explicit revocation/expiry tests before adoption.

Until the project owner identifies the legitimate admin/recovery process, the design is not operationally ready. This unknown is a reason for the **BLOCKED** verdict, not an invitation to inspect or change production users in this phase.

## 9. Workstream E — minimum safe environment architecture

A0.5 established that `cmdglabohpttgfofcmqc` is the source-matched live Scholars project, its branch list was empty, and no separate Scholars staging project was identified. `serena` is unrelated and excluded. No new project or branch was created.

Before implementation, the owner must establish or identify:

- A dedicated Supabase **staging project** with a separate project ref, API URL, anon key, service-role key, Auth configuration, storage buckets/policies, and isolated database. Do not clone production PII; use synthetic accounts and sanitized schema/metadata.
- A dedicated Vercel Preview deployment/environment mapped only to that Supabase staging ref, with distinct environment variables and no production service credential. Preview variables must not be inherited from Production accidentally. Never paste keys into chat or report.
- At least two synthetic authenticated users: ordinary user, current admin test account, plus a separate independent owner/recovery operator; synthetic accounts must not be production identities. Include an anon client and role-specific direct PostgREST clients.
- A reproducible schema/migration baseline at the exact Scholars commit; migration application and rollback rehearsal; isolated Auth email delivery and disabled/redirected external side effects; database backups/snapshot and a secure test-data reset path.
- A documented production mapping, independent database/security owner, application owner, approver/recovery operator, and explicit change window. Establish the effective staging/production `REQUIRE_ADMIN_MFA` values without exposing unrelated secrets.

If a separate staging project cannot be established, no production or live-project test substitutes for it. Owner actions: create/identify the isolated project, configure a Vercel Preview mapping and secret separation, seed synthetic roles, verify schema/API exposure, and provide the staging project ref for a later authorized read-only check. No staging configuration is changed by this report.

## 10. Workstream F — security regression test specification

All tests run only in the isolated staging project. Use disposable synthetic users and direct PostgREST requests as well as app routes. Assertions are expected outcomes, not tests executed in A0.6.

| Area / test | Expected result |
|---|---|
| Authenticated user updates own `is_admin` false→true through table REST | Database denies the request or trigger aborts; row remains unchanged; no route gains admin access. |
| Authenticated user updates own `is_admin` true→false | Denied through ordinary profile path; if the account is a legitimate admin, only the protected revocation workflow may change it. |
| Authenticated user inserts own profile with `is_admin:true` | Denied; profile creation via Auth still produces a profile with `is_admin=false`. |
| Authenticated user inserts profile for another UUID with `is_admin:true` | Denied by grants/RLS/flag trigger; no row is created. |
| Authenticated user updates another account’s flag | Denied; target row unchanged. |
| Direct PostgREST `PATCH`, `POST`, and upsert/on-conflict requests including protected field | All fail closed regardless of whether app Zod schema is bypassed; safe ordinary profile updates still succeed through the approved path. |
| Profile API sends `is_admin` or extra fields | API rejects or strips unknown fields; DB remains final enforcement. Existing allowed profile update/onboarding behavior and self-delete policy behave as approved. |
| Privilege regression guard | Reapplying broad table-level `INSERT/UPDATE` in a negative migration fixture still cannot change `is_admin` because the independent database invariant rejects it; default/grants are audited. Never run this fixture against production. |
| Anonymous helper call | `anon` cannot execute the legacy UUID helper; public RPC access to replacement is absent or returns no privileged information. |
| Authenticated arbitrary-UUID lookup | No API-role caller can query another user’s admin status. During any compatibility window, non-self UUID returns false/error; final contract has no UUID argument. |
| `auth.uid() IS NULL` / service-role invocation | Current-user helper returns false/denies; it does not treat a null subject or service role as an administrator. Trusted jobs use a separately authenticated narrow job path. |
| Function ACL/owner/search path | ACL matches the allowlist exactly; `PUBLIC` and `anon` are denied; owner is the reviewed non-login least-privilege role; `search_path=''`; no dynamic/unqualified caller-controlled object lookup. |
| Search-path/temp-object spoof test | A staging caller creates malicious same-name objects in permitted temporary/user schemas and invokes the helper/RPC; it still resolves only schema-qualified intended objects and cannot alter the authorization decision. `anon/authenticated` cannot create objects in `public` per current catalog, but this does not replace the test. |
| All 55 policy dependencies | For anon, authenticated ordinary, authenticated admin, and service role, expected SELECT/INSERT/UPDATE/DELETE allow/deny outcomes are enumerated per table/object; every policy calls the replacement helper and no broad legacy call remains. Include all five Resource Center tables and storage-object policies in scope. |
| All five dependent routines and two direct flag readers | Ordinary users fail closed; legitimate AAL2 admin behavior remains as intended; `publish_discovery_candidate` anon ACL drift is resolved; scheduler/trigger routines retain only intended execution and cannot set `is_admin`. |
| API admin denial | Ordinary authenticated user receives 401/403 from every one of the 29 route families for protected operations and cannot access admin Server Components; no service-role read/write or outbound email/push begins after denial. |
| Admin guard consistency | Valid synthetic admin can use allowed operations; AAL1 is rejected for routes designated high-risk; AAL2 is accepted; route, middleware, Server Component, and DB/RLS results agree. |
| Client state manipulation | Changing browser storage, React props, network payload role fields, or UI visibility never grants access. All 29 routes continue to derive identity from `auth.getUser()` and trusted DB authority. |
| Service-role isolation | Static/build checks show `lib/supabase/service.ts` is server-only and absent from client bundles; request payload cannot supply a key; no service action runs before successful server guard. Denied requests produce no logs, messages, or mutations except explicitly approved rate-limit telemetry. |
| Privileged lifecycle operation | Active AAL2 admin can grant/revoke only another eligible UID with required approval/reason; self-grant is denied; last-admin protection works; attempt and success audit are atomic and immutable to ordinary/admin API roles. |
| Revocation and stale session | After successful revocation, next middleware, route, RLS, helper, and RPC request is denied without waiting for a JWT role refresh. Existing service jobs remain separately authorized. |
| Emergency recovery | Simulated loss of all app admins is recoverable only by the independent project owner procedure with two-person approval and complete audit; ordinary users cannot invoke it. |
| Resource Center compatibility | Existing public read views remain public as intended; admin reader still works; direct authenticated editorial writes remain denied until approved workflow endpoints exist; future author/reviewer/publisher checks must be separate from platform admin. |
| Migration atomicity and rollback | Injected failure before migration commit rolls back grants, policies, functions, and trigger as one unit. After commit, application rollback does not restore broad DML/PUBLIC execute. Recovery uses a forward fix, not re-opening the vulnerability. |

Also test safe profile upsert with the actual Supabase/PostgREST version and exact API grants; the 0029 source comment says upsert requires table-level rights, so do not assume column-only grants preserve it.

## 11. Workstream G — ordered implementation and migration plan

A0.6 does not write or execute this plan. Stages 4–5 are one atomic security migration boundary; do not deploy them as separate changes that leave old policies or privileges exposed.

| Stage | Prerequisites and objects | Main risks / acceptance criteria | Rollback requirements |
|---|---|---|---|
| **1. Establish isolated staging** | Owner provisions/identifies Supabase staging and Vercel Preview; synthetic Auth users; separate keys, Auth/email, storage and schemas. | Risk: production variables/data leak into Preview. Accept only when project refs and URL/key mappings are verified without revealing secrets, no production PII is copied, and a staging health check proves isolation. | Tear down/reset only the staging fixture as approved; no production impact. |
| **2. Verify production state and baseline** | Separate owner authorization; capture current live function bodies/owners/ACLs, 55-policy dependency inventory, all grants/role memberships, triggers, default privileges, project mapping, migration version, Auth/API exposure and MFA Boolean. Privately inventory current admin UUIDs. | Risk: incomplete drift inventory or exposing user data. Accept when owner signs a sanitized baseline; identifiers remain in restricted private evidence, not GitHub. No write/test in production. | Baseline is read-only; preserve encrypted metadata snapshot; no DDL rollback applies. |
| **3. Prepare membership/recovery** | Project owner identifies legitimate admins and independent break-glass operator through private verification; approve two-person grant/recovery and last-admin policy. | Risk: lockout, unauthorized promotion, lost account deletion workflow. Accept when at least one legitimate admin and independent owner recovery path are confirmed without hardcoded identity; audit/change process documented. | No account changes yet; stop if identities/operator unresolved. |
| **4–5. Protect flag and atomically replace helper/dependencies** | Approved staging baseline. Objects: grants/column privileges, profile-write path, flag guard trigger, lifecycle function/audit relation, replacement helper, 55 RLS policies, five helper callers, two direct flag-reader routines, and legacy helper ACL. | Highest risk: lockout, PostgREST upsert breakage, a gap where policy execution or grants are weaker, definer recursion/privilege misuse. Run a single transactional migration: ensure safe helper and ACL exist; update all policies/routines; enforce flag protection; remove broad ordinary grants; then revoke/compatibly shim legacy UUID helper. Accept only after direct PostgREST denial, safe profile upsert success, full policy matrix, null/search-path behavior, ACL audit, and auth lifecycle tests pass. | Before commit, database transaction must roll back completely on any error. After commit, never restore authenticated table DML or PUBLIC UUID-helper execution; use a forward corrective migration. Keep tested backup and owner recovery route. |
| **6. Update application guards** | Stage 4–5 stable in staging. Files: `lib/admin/guard.ts`, `lib/admin/access.ts`, `middleware.ts`, and only affected route call sites. Keep existing 29 routes; avoid unrelated rewrites. | Risk: mismatch among middleware/API/RLS or introducing fallback to client state. Accept when shared guard semantics, deny/error paths, AAL2 policy and identity derivation are consistent; app guards query only the protected source; no client role claims. | Application code can roll back only while the database compatibility contract still supports it; DB remains protected and old helper cannot become arbitrary. |
| **7. Add regression tests** | Approved isolated CI secrets and synthetic fixture; use direct REST and app endpoints in staging. | Risk: tests only cover Zod API, not direct PostgREST. Accept when all §10 expected outcomes pass and test logs contain no real PII/secrets. | Test fixture reset only in staging; test failure blocks next stage. |
| **8. Test legitimate admin workflows** | Known synthetic admin and owner recovery operator. Exercise user board, broadcasts/digests only with sink/disabled delivery, scholarship/discovery/moderation workflows, community role operations, and safe profile onboarding. | Risk: accidental external email/push or service-role operations. Accept when all intended admin actions work at AAL2, denied user paths have no privileged side effect, and email/push are sandboxed. | Reset synthetic data and disable staging integrations; no production sends. |
| **9. Verify Resource Center compatibility** | Secure common admin authority and policy cutover pass. Existing Resource Center remains read-only. | Risk: Resource Center policies still call legacy helper or trust client. Accept when all RC policies use approved helper, public views remain as intended, direct writes from ordinary user fail, and no editorial mutation is enabled prematurely. Later editorial workflow requires its own approved design/tests for author/reviewer separation, revisions, transactions and audit. | Disable only staging RC test fixtures; do not revert to unsafe helper/grants. |
| **10. Prepare production change and rollback** | Signed staging evidence, owner-approved admin roster/baseline, source commit, migration checksum, downtime/transaction plan, backup, exact rollback/forward-fix decision, runbook and monitoring. | Risk: live drift, lockout, unintended external effects. Accept only when database/security owner and application owner approve; verify target project reference before execution; rehearse recovery; preserve a forward-only secure rollback. | No rollback may regrant authenticated flag writes or public UUID oracle. Use app rollback with compatible secure DB or a tested forward migration. |
| **11. Obtain explicit production authorization** | Exact migration/code diff, target project/deployment, change window, approvers and acceptance criteria presented for a separate approval. | Risk: scope creep and unauthorized production modification. Accept only on explicit, new authorization; no implicit approval from A0.6 publication. | If approval is withheld, stop with no production changes. If approved, monitor and verify post-deploy catalog/tests; have owner recovery operator available. |

### Atomicity rule

The flag protection, safe profile write compatibility, helper semantics/ACL, all policy callers, and dependent privileged routines are coupled. Prefer a single database transaction and a staged deploy order that does not leave old broad grants or a helper that policies cannot execute. If a large policy replacement cannot safely fit one transaction, use a rigorously reviewed compatibility helper that is self-only and fail-closed before migrating callers; never retain arbitrary-UUID behavior during the compatibility window. Application guard refactoring can be separate only after database authority is fixed and its compatibility tests pass.

## 12. Workstream H — Resource Center integration implications

The Resource Center remains **BLOCKED** until this Scholars-wide admin foundation is trustworthy. Do not begin editorial implementation in A0.6. After the shared admin authority is repaired:

- Keep `profiles.is_admin` as the platform-admin override; do not make a new Resource Center-only admin role system.
- Use distinct, database-enforced editorial author, reviewer and publisher capabilities mapped to editorial identities. Derive actor identity from `auth.uid()`; never accept client-supplied actor/admin IDs.
- Article authoring, category/identity management, revision creation, approval, scheduling, publication, archiving and audit must occur through narrow server/database operations with role-specific authorization and AAL2 for sensitive transitions.
- Enforce reviewer/author separation, approved-revision binding to the same article, immutable revisions, valid transitions, and an append-only transition audit within atomic transactions. The existing schema is not proof these controls exist; A0.4 §2 describes the gaps.
- Keep public reads limited to the approved published snapshot. A0.5 found that current live views expose mutable article/category base rows rather than the approved revision; address that as a separate backend invariant before publishing new editorial content.
- Keep service-role access server-only, behind verified actor/job checks. Public read views and editorial reads must not inherit a broad service credential.

The admin reader at `app/admin/resources/page.tsx:6-17` is not an editorial workflow. No Resource Center write endpoint, transition RPC, or audit operation was found in A0.5’s scoped source/live inventory.

## 13. Dependency and risk matrix

| Dependency / risk | Evidence and confidence | Severity / consequence | Required gate |
|---|---|---|---|
| Table-wide profile grant defeats column-only revoke | **VERIFIED — DATABASE** effective auth grants; **VERIFIED — SOURCE** migration 0029:1-7. | Critical: structural own-row admin self-elevation. | Remove ordinary effective DML on flag; independent DB trigger/invariant; direct PostgREST denial test. |
| Own-row profile RLS does not protect privileged column | **VERIFIED — DATABASE** A0.5 §3.3; no flag trigger/check/rule found. | Critical: user can alter own trust value. | Enforce protected field invariant regardless of own-row policy; preserve safe profile fields. |
| `public.is_admin(uuid)` arbitrary oracle | **VERIFIED — DATABASE** A0.5 §3.1; `PUBLIC EXECUTE`, `SECURITY DEFINER`, arbitrary UUID. | High: role membership Boolean disclosure and unsafe shared dependency. | Migrate all callers; restrict/remove old UUID function; verify actual PostgREST schema exposure in staging. |
| 55 helper-dependent policies and 5 helper caller routines | **VERIFIED — DATABASE** targeted catalog inventory. | High: partial cutover can break or weaken broad application/RC authorization. | Exact staged dependency diff; atomic migration and per-role allow/deny matrix. |
| Two routines directly read `profiles.is_admin` | **VERIFIED — DATABASE** function body inventory; not flag writers in inspected definitions. | Medium/high: behavior can drift from new policy semantics. | Review `flag_expired_opportunities` and `seed_scholarship_prompts` ACL/actor semantics and test them. |
| App guards/middleware share one mutable flag | **VERIFIED — SOURCE** guard/access/middleware; DB flaw **VERIFIED — DATABASE**. Route consequence **INFERRED**. | Critical: all 29 guarded API routes plus admin pages depend on same trust. | Repair database source first; maintain shared server guard and full 29-route regression suite. |
| Service-role operations after guard | **VERIFIED — SOURCE** route helpers and `lib/supabase/service.ts`; runtime secret scoping **UNVERIFIED**. | High: successful guard permits cross-user RLS bypass and outbound effects. | Guard must rely on immutable authority; service key stays server-only; test zero side effects on denial. |
| Production MFA flag and API exposure | **UNVERIFIED** A0.5 §§6,8; no Vercel environment inspection or HTTP probe. | High: AAL2/API guard coverage unknown. | Owner confirms effective environment Booleans/schema mapping; staging verifies route behavior. |
| No isolated Scholars staging | **VERIFIED — DATABASE METADATA/SOURCE** A0.5 §6; no branch or separate project identified. | Blocking: no safe target for implementation testing. | Owner establishes separate Supabase/Vercel Preview architecture before A1. |
| Legitimate admin roster and recovery operator | **UNVERIFIED**; no profile rows/admin identities/logs read. | Blocking: unsafe migration or lockout risk. | Owner verifies roster privately and names independent recovery operator/two-person approval. |
| PostgREST upsert behavior with column-only grants | Migration 0029 comment says table-level DML is required; actual staging behavior **UNVERIFIED**. | High: fixing the flag may break profile onboarding, or restoring broad grants reopens defect. | Test actual version in staging; use explicit safe columns or fixed allowlisted RPC/handler plus DB guard. |
| Founder-role assignment and admin self-deletion | Founder assignment **UNVERIFIED**; profile DELETE source **VERIFIED**. | Medium/high: founder export extra gate may be mutable; last-admin lockout possible. | Inventory role writers; protect founder assignment; implement last-admin/offboarding rule. |
| Resource Center review/publish controls | A0.4/A0.5 source/database scope: currently no editorial write workflow; mutable view/revision gaps established in A0.5. | High for future publishing; currently no write path. | Keep blocked until shared admin fix, reviewer separation, immutable revisions, transactional publication and audit are separately tested. |

## 14. Verdict and owner actions

# **BLOCKED**

The remediation design is technically specified, but the A0.6 readiness rule requires an identified legitimate administrator recovery mechanism and a credible isolated test environment. Those critical facts remain unresolved: no Scholars staging project/branch was identified; no current admin roster or independent recovery operator was verified; production AAL2 and exposed-schema/API settings remain unknown. The route-level impact is inferred from source plus live grant evidence and has not been reproduced, by design. The live database is treated as production and must not be used as a test target.

Before a separately authorized implementation phase, the owner must: (1) establish isolated Scholars Supabase staging and Vercel Preview separation; (2) privately verify the existing legitimate admin population and designate an independent two-person recovery process; (3) confirm the effective production MFA and API-exposure settings without sharing secrets; and (4) approve the staged migration and rollback runbook after all dependency and direct-REST tests pass in staging.

**No implementation or production changes occurred.** This report is the sole A0.6 deliverable. Stop after publication and wait for independent review and explicit implementation authorization.


## Appendix A. Exact route and shared-source locators

These locators support the route matrix in §7. The A0.6 route review inspected the complete files at Scholars commit `cf3682ce35912df7b9b9352193630fc404427c7c`; line spans identify the handler/operation, while the shared helper citations identify the common authority source.

| Route in §7 | Current Scholars source locator |
|---|---|
| `app/api/admin/active-users/route.ts` | `app/api/admin/active-users/route.ts:10-16,19-79` |
| `app/api/admin/analytics/route.ts` | `app/api/admin/analytics/route.ts:29-140` |
| `app/api/admin/broadcast/route.ts` | `app/api/admin/broadcast/route.ts:98-133,136-263` |
| `app/api/admin/community-invitations/export/route.ts` | `app/api/admin/community-invitations/export/route.ts:10-39` |
| `app/api/admin/digest/route.ts` | `app/api/admin/digest/route.ts:24-34` |
| `app/api/admin/discovery/claims/route.ts` | `app/api/admin/discovery/claims/route.ts:7-29` |
| `app/api/admin/discovery/operations/route.ts` | `app/api/admin/discovery/operations/route.ts:7-22` |
| `app/api/admin/discovery/route.ts` | `app/api/admin/discovery/route.ts:7-50` |
| `app/api/admin/discussion-reports/[id]/route.ts` | `app/api/admin/discussion-reports/[id]/route.ts:9-35` |
| `app/api/admin/discussion-reports/route.ts` | `app/api/admin/discussion-reports/route.ts:7-22` |
| `app/api/admin/discussions/[id]/route.ts` | `app/api/admin/discussions/[id]/route.ts:9-32` |
| `app/api/admin/discussions/route.ts` | `app/api/admin/discussions/route.ts:7-23` |
| `app/api/admin/feedback/route.ts` | `app/api/admin/feedback/route.ts:24-75` |
| `app/api/admin/independence-day/route.ts` | `app/api/admin/independence-day/route.ts:78-213` |
| `app/api/admin/member-roles/route.ts` | `app/api/admin/member-roles/route.ts:7-37` |
| `app/api/admin/opportunities/[id]/route.ts` | `app/api/admin/opportunities/[id]/route.ts:21-105` |
| `app/api/admin/opportunities/route.ts` | `app/api/admin/opportunities/route.ts:26-93` |
| `app/api/admin/profile-nudges/route.ts` | `app/api/admin/profile-nudges/route.ts:20-54` |
| `app/api/admin/reengagement/enroll/route.ts` | `app/api/admin/reengagement/enroll/route.ts:8-66` |
| `app/api/admin/reengagement/route.ts` | `app/api/admin/reengagement/route.ts:35-143` |
| `app/api/admin/reengagement/summary/route.ts` | `app/api/admin/reengagement/summary/route.ts:1-56` |
| `app/api/admin/schema-check/route.ts` | `app/api/admin/schema-check/route.ts:47-60,75-114,154` |
| `app/api/admin/scholarships/[id]/route.ts` | `app/api/admin/scholarships/[id]/route.ts:34-160` |
| `app/api/admin/scholarships/[id]/rules/[ruleId]/route.ts` | `app/api/admin/scholarships/[id]/rules/[ruleId]/route.ts:18-50` |
| `app/api/admin/scholarships/[id]/rules/route.ts` | `app/api/admin/scholarships/[id]/rules/route.ts:121-166` |
| `app/api/admin/scholarships/route.ts` | `app/api/admin/scholarships/route.ts:6-134` |
| `app/api/admin/test-profile-nudge/route.ts` | `app/api/admin/test-profile-nudge/route.ts:10-56` |
| `app/api/admin/testimonials/[id]/route.ts` | `app/api/admin/testimonials/[id]/route.ts:22-113` |
| `app/api/admin/testimonials/route.ts` | `app/api/admin/testimonials/route.ts:23-79` |

Shared source: `lib/admin/guard.ts:19-52,64-83`; `lib/admin/access.ts:10-35`; `middleware.ts:192-214,304-327`; `lib/supabase/server.ts:6,20-46`; `lib/supabase/service.ts:1-23`; `app/api/profile/route.ts:36-79,116-160,180-204`; `app/api/admin/member-roles/route.ts:7-37`; `app/admin/users/page.tsx:50-64,127-129`; `app/admin/resources/page.tsx:6-17`.

## Appendix B. Targeted live function ACL details

The following are **VERIFIED — DATABASE** catalog findings from the read-only A0.6 inspection of `cmdglabohpttgfofcmqc`; they are not conclusions inferred from migration text. They are listed to make the function-privilege design auditable and do not establish HTTP/PostgREST reachability.

| Live routine | Security/owner/configuration | Effective caller notes |
|---|---|---|
| `public.is_admin(uuid)` | SQL, `STABLE`, `SECURITY DEFINER`, owner `postgres` (`BYPASSRLS`), `search_path=''`; returns a Boolean for the supplied UUID. | `PUBLIC EXECUTE`, therefore anon, authenticated, service_role and postgres pass SQL privilege checks. Arbitrary UUID is accepted. |
| `public.get_admin_metrics_summary(timestamptz)` | `SECURITY DEFINER`, owner `postgres`, `search_path=public`; calls helper with `auth.uid()`. | Explicit `EXECUTE` for anon, authenticated and service_role. Its own admin check must fail closed for NULL/ordinary callers after cutover. |
| `public.get_provider_analytics(...)` | `SECURITY DEFINER`, owner `postgres`, `search_path=public`; calls helper with `auth.uid()`. | Explicit `EXECUTE` for anon, authenticated and service_role. |
| `public.get_daily_visitor_metrics(...)` | `SECURITY DEFINER`, owner `postgres`, `search_path=public`; calls helper with `auth.uid()`. | Explicit `EXECUTE` for anon, authenticated and service_role. |
| `public.get_auth_confirmation_email_analytics(...)` | `SECURITY DEFINER`, owner `postgres`, `search_path=public,auth`; calls helper with `auth.uid()`. | Explicit `EXECUTE` for anon, authenticated and service_role. |
| `public.publish_discovery_candidate(uuid)` | `SECURITY DEFINER`, owner `postgres`, `search_path=public`; derives `actor_id` from `auth.uid()` and checks the helper before publishing. | Live ACL includes explicit anon/authenticated/service_role execution; the anon route is expected to fail its null-actor check, but that behavior was not HTTP-tested. A0.5 notes source/live ACL drift. |
| `public.flag_expired_opportunities()` | `SECURITY DEFINER`, owner `postgres`, `search_path=public`; directly reads `profiles.is_admin`. | Service_role/postgres execute only in the inspected live ACL; no flag write was identified. |
| `public.seed_scholarship_prompts()` | Trigger routine, `SECURITY DEFINER`, owner `postgres`, `search_path=public`; reads profile admin/community-role state for attribution. | Service_role/postgres ACL in the inspected catalog; no flag write was identified. |

The four analytics routines’ broad SQL execute grants do not mean an anonymous HTTP request has been tested or can retrieve privileged rows. Their internal authorization and output behavior must be validated in staging. The `public` schema has USAGE but no CREATE grant for anon, authenticated, or service_role in the inspected catalog; this limits ordinary schema-object creation but does not eliminate the need for empty `search_path`, qualified names, minimal function ownership, or temporary-object spoof tests.
