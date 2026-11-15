# Scholars Resource Centre — Phase 2B Administrator Self-Elevation Remediation Design

**Assessment date:** 2026-11-15
**Application repository:** `ImperioKDB/Scholars`
**Documentation repository:** `ImperioKDB/Updates`
**Production project:** `scholarship-platform` (`cmdglabohpttgfofcmqc`), `eu-west-1`, PostgreSQL 17.6.1.155
**Scope:** read-only design and implementation-readiness assessment. No production write, migration, source modification, merge, PR, or deployment was performed.

## Executive decision

**Final verdict: BLOCKED — MISSING REQUIREMENTS.**

The remediation design is sufficiently specified for review and staging preparation, but it is not ready for staging implementation. The required application dependencies are identifiable from source, yet safe-profile-upsert compatibility, the exact staged schema baseline, the administrator bootstrap/recovery operators, the production MFA setting, and the complete dependency cutover have not been demonstrated in an isolated Scholars staging deployment. The healthy `scholars-staging` Supabase project exists, but the previous staging assessment found it empty and blocked at baseline reconstruction. That project is not a substitute for a validated application staging environment.

## Evidence boundary

The following historical production findings are reused from the already-published Task 9/10 verification reports; they are not presented as newly reproduced here:

- **VERIFIED — DATABASE (prior read-only production verification):** `authenticated` had effective table-level `INSERT` and `UPDATE` on `public.profiles`, effective `INSERT` and `UPDATE` on `profiles.is_admin`, and an own-row update policy.
- **VERIFIED — DATABASE (prior read-only supplementary verification):** `public.is_admin(uuid)` was owned by `postgres`, `SECURITY DEFINER`, configured with an empty search path, and executable by PUBLIC/anon/authenticated/service_role. The function was not called.
- **VERIFIED — DATABASE (prior read-only supplementary verification):** no inspected trigger, constraint, or rule protected `is_admin`.
- **INFERRED:** an ordinary authenticated user had a database-supported path to attempt changing their own flag. No successful HTTP or database exploit was demonstrated.
- **VERIFIED — SOURCE (this reconstruction):** current `main` source still uses `profiles.is_admin` as the common platform-admin authority and still contains the generic profile upsert and the legacy UUID helper in migration history.
- **VERIFIED — CURRENT TASK:** the configured Supabase project inventory contains the named production project, a separate healthy project named `scholars-staging`, and an inactive unrelated project named `serena`. No SQL was executed against either project by this assessment.

## Recommended architecture

Retain `profiles.is_admin` as the single platform-admin authority for this remediation. This is the lowest-risk cutover because the current middleware, Server Component guard, API guard, RLS policies, storage policies, analytics functions, and admin pages all depend on the same flag. Do not introduce a parallel `admin_members` authority during this remediation; doing so would create dual authority and require a much larger, independently verified dependency migration.

Protect the flag at the database boundary, not only in Zod schemas or route code. Ordinary API roles must lose effective table-level profile `INSERT`/`UPDATE` privileges, then receive only the explicit ordinary columns required by verified application paths. An independent `BEFORE INSERT OR UPDATE` database guard must reject changes to `is_admin` unless the statement is executed by a narrowly owned, non-login administrator-controller role. A column-level revoke is not sufficient while a table-level grant remains.

Replace arbitrary-subject membership checks with a caller-bound helper, conceptually `security.is_admin_current()`, which derives the subject only from `auth.uid()`. It must return false for a null or missing subject, reveal no other user’s membership, use fully qualified names and a fixed empty search path, and be executable only by the roles needed for policy evaluation. Because RLS recursion is possible, the owner, privileges, and `SECURITY DEFINER` decision must be proven in staging. Update every dependent policy and routine in one transactional cutover; do not revoke the old helper’s execution before its replacements are active.

Create a restricted administrator lifecycle operation rather than restoring generic profile writes. The operation should bind the actor to `auth.uid()`, require an already-authorized administrator and AAL2, reject self-grant, require a valid `auth.users` target and reason/change ticket, protect the last administrator, write an immutable audit event in the same transaction, and use explicit ACLs. First bootstrap and emergency recovery must remain project-owner-controlled, two-person, private operations; no administrator roster or target UUID is invented here.

## Option comparison

| Option | Compatibility | Security | Regression risk | Assessment |
|---|---|---|---|---|
| Narrow column-level privileges only | Preserves direct profile calls only if PostgREST upsert semantics are proven; later migrations may have added columns | Better than current grants but insufficient if table-level grants remain or a future grant regresses | High until every upsert column and trigger is tested | Necessary component, not sufficient alone |
| Carefully designed database functions | Can preserve ordinary profile writes through allow-listed operations and provide controlled admin lifecycle | Strongest boundary when actor, target, AAL2, ACL, ownership, and audit are enforced | Medium; requires route/RPC contract tests and policy recursion testing | Preferred for admin lifecycle and fallback if upsert cannot be preserved |
| Server-side profile mutation endpoints | Can preserve UX while keeping service credentials server-only | Strong if endpoint validates session and allow-listed fields, but database guard remains necessary | Medium/high; generic upsert is currently central to onboarding and settings | Useful for sensitive fields and as a compatibility fallback |
| Combined approach | Keeps safe, proven ordinary writes and moves privileged/sensitive writes behind fixed operations | Best defense in depth | Highest initial test surface, but avoids a broad profile-write grant | Recommended |

## Administrator lifecycle

**Bootstrap:** a verified Supabase project owner and independent reviewer identify the target Auth UUID privately, confirm the exact schema baseline, apply a one-time owner procedure, and record the change ticket and audit evidence. No email, UUID, or roster is placed in this report.

**Promotion:** an existing AAL2 administrator invokes the restricted lifecycle operation for another eligible Auth UUID; self-grant is rejected; reason and ticket are mandatory; a second approver is required where owner policy mandates two-person control.

**Demotion/revocation:** the same operation records the actor, target, prior state, new state, reason, ticket, and timestamp atomically. The final active administrator cannot be removed through the ordinary path. Revocation must be observed on the next middleware, route, RLS, RPC, and service-boundary authorization check; no long-lived role claim may delay revocation.

**Emergency recovery:** use a sealed project-owner/database-owner procedure with two-person approval and private target verification. Recovery must not expose a service-role credential to the browser or create an ordinary authenticated bypass.

**MFA/AAL2:** require AAL2 for administrator promotion, demotion, recovery, destructive admin operations, broadcasts, exports, and publishing. The source supports AAL2 checks conditionally, but the production value of `REQUIRE_ADMIN_MFA` and explicit high-risk route call sites remain unverified.

**Auditing:** use an append-only administrator action relation with actor, target, action, timestamp, reason/ticket, approval reference, and result. Ordinary users and ordinary administrators must not be able to rewrite or delete audit events.

## `public.is_admin(uuid)` disposition

The legacy helper is a dependency cutover, not an isolated ACL change. Its current arbitrary-UUID signature is unnecessary in the inspected source callers: policies pass `auth.uid()`, and the reviewed routine callers derive actors from `auth.uid()`. The proposed migration therefore targets a current-caller helper and updates all policies/routines before tightening or removing the legacy helper.

Do not revoke `PUBLIC EXECUTE` in isolation. First establish the exact live/staged dependency inventory, create and test the replacement helper, update every referencing policy and routine, verify anonymous, ordinary-authenticated, administrator, and service-role behavior, and only then remove or temporarily restrict the legacy signature. If a compatibility shim is required, it must reject null and any UUID different from `auth.uid()` and must never answer for an arbitrary subject.

## Required staging gate

The implementation cannot proceed until the owner provides a representative schema-only baseline at the approved Scholars revision, configures the isolated Vercel Preview environment with staging-only Supabase variables, verifies the effective staging grants/policies/functions/triggers/owners, establishes synthetic ordinary/admin/recovery identities, and decides the approved last-admin and recovery policies. The prior staging report records `scholars-staging` as healthy but empty and blocked at baseline reconstruction; no remediation was applied there.

The companion SQL file is a review proposal, not an instruction to execute. The verification plan defines expected outcomes only; it contains no test result claims.

## No-go conditions

Do not implement if the only available option is to restore broad `authenticated` profile DML, rely on client-supplied role state, use a service-role key as an end-user authority, guess an administrator identity, use `serena` as staging, test against production, or remove helper execution before the policy/routine cutover is validated.
