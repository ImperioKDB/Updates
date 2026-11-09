# Scholars Phase 2.1.1 — Security Remediation and Rollback Plan

**Status:** Proposal only; no SQL, code, schema, ACL, API setting, or Vercel deployment change was applied.
**Production target:** `cmdglabohpttgfofcmqc` (`eu-west-1`).
**Reference:** Phase 2.1 security policy at Updates baseline commit `abb19a697703aab91f783b8e5258acebf35bf02a` and [production investigation](SCHOLARS_PHASE_2_1_1_PRODUCTION_SECURITY_INVESTIGATION_2026-11-09.md).

> **Safety:** SQL snippets in this document are design examples only. They are not migrations and must not be pasted into production without the approvals, inventory, staging baseline, application compatibility work, and verification gates below. No permission changes were authorized by the investigation request.

## 1. Risk priority and response posture

Treat this as a **high-priority production security-readiness defect**. The clear data-exposure concern is not only the broad grants: the database has public read predicates over whole rows, public RPCs with security-definer execution, and a specific public `is_admin(uuid)` status oracle plus an anon-callable admin metrics routine with an unguarded application outcome aggregate. Broad TRUNCATE is a verified database ACL, but no HTTP/direct-SQL invocation path was tested or established. Do not label it an exploited vulnerability or claim rows were accessed.

The smallest low-regret containment candidates are the two function corrections (`is_admin(uuid)` arbitrary-user oracle, and `get_admin_metrics_summary` application outcome aggregate) and excess direct table ACLs. They still require an approved migration that preserves policy function evaluation and current API calls. Do not rush a blanket revoke that breaks RLS, catalogue browse, matching, save, application, or admin workflows.

## 2. Required preconditions and approvals

Before preparing an executable migration:

1. Confirm the exact production and staging project IDs, API exposed-schema allowlist, API version, connection strings/roles, and who runs migrations. Current ledger does not record an execution-role field.
2. Inventory all `public` objects and all `from(...)`, `rpc(...)`, relation URLs, storage paths, Vercel routes, triggers, and scheduled workers. The current Scholars source uses default `public` clients in server components and API routes.
3. Map every applied production migration to tracked source. Resolve the missing `create_opportunities_and_saved_opportunities` file and the separate untracked `is_admin` restore migrations before using a clean build as proof of reproducibility.
4. Capture a read-only before snapshot for direct ACLs, effective privileges, policies, forced-RLS flags, default ACLs per owner, function ACL/body/security/search path, view owner/options/definitions, sequence ACLs, and exposed-schema settings. Store it in a restricted audit location; do not dump student rows or secrets.
5. Decide public catalogue fields, especially `research_notes`, cycle-event `note`/`captured_by`, competitiveness/acceptance values, public discussion identity/presence, and aggregate thresholds.
6. Obtain security/product approval for API compatibility and migration order; editorial approval for researcher/reviewer/approver roles and separation of duties; database-owner approval for `supabase_admin` default-ACL handling; explicit production release approval after staging tests pass.
7. Bootstrap the existing `scholars-staging` project with a reproducible schema-only baseline and synthetic fixtures. It had no Scholars migration baseline or public application tables when inspected; do not copy production user data to make it usable.

## 3. Phased implementation sequence

### Phase A — Fix high-risk function authorization (separate reviewed migrations)

**A1. Replace the arbitrary-user admin predicate without breaking RLS.** The live migration history shows `is_admin(uuid)` needs EXECUTE for policy evaluation under the calling role; simply revoking it from anon/authenticated can break policy evaluation. First inventory every policy, view, and function that calls it. Add a current-subject-only helper, update those RLS expressions, then revoke the arbitrary-UUID RPC.

Non-executable sketch, to be adapted and tested in staging:

```sql
-- Example only. Use the approved non-exposed schema/owner and test every caller.
CREATE OR REPLACE FUNCTION private.is_current_user_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT COALESCE((
    SELECT p.is_admin
    FROM public.profiles AS p
    WHERE p.id = auth.uid()
  ), false);
$$;

-- The policy helper can be executable by browser roles only because it
-- reveals the current principal's own boolean, never an arbitrary UUID.
REVOKE ALL ON FUNCTION private.is_current_user_admin() FROM PUBLIC, anon, authenticated;
GRANT USAGE ON SCHEMA private TO anon, authenticated;
GRANT EXECUTE ON FUNCTION private.is_current_user_admin() TO anon, authenticated;

-- Update every dependent policy/view/routine first, then close the old RPC.
REVOKE ALL ON FUNCTION public.is_admin(uuid) FROM PUBLIC, anon, authenticated;
```

The helper owner must be a non-login least-privilege role with only the required read access to `profiles.is_admin`; no owner/table ownership or general `BYPASSRLS` is intended. If `private` is excluded from PostgREST exposure, verify function resolution/USAGE in policy execution and confirm no RPC route is exposed. Do not leave a period where policies reference a helper without execute rights.

**A2. Fix admin metrics.** Add a top-level `is_current_user_admin()` guard before any data-bearing query or move the entire function to an authenticated admin-only route. Review the output fields and time window; the application status aggregate should not be returned to anon. Then revoke any direct anon/PUBLIC EXECUTE explicitly and grant only the intended role.

```sql
-- Example only; preserve the exact signature and replace the body safely.
REVOKE ALL ON FUNCTION public.get_admin_metrics_summary(timestamptz)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_metrics_summary(timestamptz)
  TO authenticated;
```

This grant sketch is safe only after the function has an unconditional top-level admin check and RLS helper permissions are correct. A direct `anon` ACL survives `REVOKE ... FROM PUBLIC`; both principals must be handled explicitly.

**A3. Review remaining definer routines.** Enforce an allowlist: public-safe projections only; admin routines call a non-arbitrary current-admin guard; student functions require caller/target equality; worker functions service-only. Specifically review `run_achievement_checks(uuid)` (cross-user mutation), `get_trending_scholarship_ids` (caller-controlled threshold/window), public discussion/contributor profile fields, social-proof thresholds, and trigger functions with browser EXECUTE. Keep trigger execution intact while removing only direct RPC access.

### Phase B — Create compatibility API before changing grants

1. Add an exposed `api` schema containing explicit catalogue views and the limited RPCs required by the Next.js app.
2. Public catalogue views contain only product-approved fields, with `verified/published` predicates and no unreviewed notes or evidence. For invoker views, grant the caller only the needed base-table SELECT columns, maintain correct RLS for view callers, and keep `public` out of PostgREST's exposed schema list so browser clients cannot address base tables directly. For owner-executed views, use a non-login owner, minimum column grants, role-specific RLS, reviewed predicates, and exhaustive negative tests; `security_barrier` alone is insufficient.
3. Add authenticated RPCs or server APIs for applications, saves, and notification state. Prefer `SECURITY INVOKER` with RLS and column grants. If `SECURITY DEFINER` is required, validate `auth.uid()` in the function and use a narrow owner. Do not expose general-purpose table update/delete functions.
4. Add editorial functions/routes only after trusted roles and separation of duties are approved. Evidence reads are scoped and logged; publication writes append the review/approval event transactionally.
5. Update Next.js call sites to use `.schema('api')`/`api.rpc(...)` or server routes. Update generated Supabase types from the exact approved schema; ensure `SUPABASE_SERVICE_ROLE_KEY` stays server-only and out of client bundles. Do not alter the production API schema setting yet.
6. Build and test the complete replacement surface in staging; preserve current response shapes where needed, with explicit deprecation/compatibility review.

### Phase C — Remove excess browser ACLs and fix defaults

Only after Phase B routes/tests pass, revoke the broad table ACLs from browser roles on the original 11 objects **and** adjacent no-policy tables. Then grant only the minimum remaining access for invoker projections and narrowly scoped user operations. If student RPCs use invoker security, do not revoke the column/table privileges those functions need; constrain them to explicit columns and RLS. Keep editorial/worker objects inaccessible to browser roles.

Non-executable ACL sketch:

```sql
-- Example object list only. Run only after dependency and compatibility review.
REVOKE ALL PRIVILEGES ON TABLE
  public.scholarships,
  public.scholarship_rules,
  public.opportunities,
  public.cycle_events,
  public.applications,
  public.saved_scholarships,
  public.saved_opportunities,
  public.notifications,
  public.scholarship_discovery_candidates,
  public.scholarship_discovery_candidate_claims,
  public.scholarship_discovery_fetch_snapshots
FROM anon, authenticated;

-- Then grant exact view/function/column rights approved for the new API.
-- Do not restore broad table-wide DML or TRUNCATE as a rollback shortcut.
```

The same migration plan must include `announcement_log`, `auth_rate_limits`, `broadcast_delivery_log`, `notification_deliveries`, and `workflow_jobs`, after verifying service dependencies. `visitor_daily_metrics` had no browser ACL, but include it in the before/after inventory.

For defaults, preserve the verified safe `postgres` defaults and resolve `supabase_admin` defaults with the authorized administrative mechanism. Do not run `ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin` from an unprivileged migration session; verify role membership/provider support first. Future objects should have no browser ACL by default for tables, sequences, or functions. Grant `service_role` only per object/function where required, not automatically all privileges. Defaults apply only to future objects and only when created by the specified role.

### Phase D — Migrate private/editorial data and finish the API boundary

1. Add new non-exposed schema objects and policies additively; keep existing tables during migration. Do not drop old tables/buckets or delete rows.
2. Copy only required evidence into the new schema; reconcile row counts and primary/foreign-key references without reading student content; preserve `created_at`, provenance and audit IDs where applicable.
3. Dual-read or compare through controlled server code; do not dual-write public and private approval states without a single transaction/source of truth.
4. Switch read/write calls; retain a compatibility window. After evidence of zero legacy callers, remove browser ACLs from old internal tables and update API exposure config.
5. Keep a migration ledger mapping: production applied version/name ↔ tracked SQL file/hash ↔ new version. Resolve the missing production opportunity-table creation migration and separate historical `is_admin` changes before future schema work.

## 4. Verification gates and go/no-go

### Before migration

- All current call sites are inventoried and assigned an owner.
- Staging is a reproducible schema-only clone with synthetic fixtures; tests run under real Supabase `anon`, `authenticated`, editor, approver, and service contexts.
- A documented before snapshot and rollback package are complete.
- No unreviewed field/role/default is left implicit.

### After each migration

- Read-only ACL/policy/default/view/function/sequence snapshots match the approved matrix.
- `anon` and non-admin authenticated users cannot call protected RPCs, read internal columns, touch another student's data, write catalogue/evidence, or invoke worker routines.
- Admin/editor paths still work only for authorized, role-scoped users; no self-approval where prohibited.
- Public reads and student flows preserve intended behavior; Vercel Preview build passes before production switch.
- No accidental `SECURITY DEFINER` default or PUBLIC EXECUTE grant exists.
- No storage bucket, application row, evidence row, or other user data is deleted or changed during verification.

### Production rollout

Use a maintenance/release window, one reviewed migration at a time, and a feature flag for new API calls. Verify exact API settings and PostgREST cache refresh behavior. Roll forward only after canary positive/negative checks and green application health. Do not make a live TRUNCATE/unauthorized write probe. If an emergency concern requires a production read-only API verification, obtain an approved, strictly scoped request plan and use a known synthetic/non-sensitive identifier only.

## 5. Rollback plan

Rollback restores service availability without reintroducing the broad ACL defect:

1. **Application/API incompatibility:** revert the application code or toggle the API feature flag to the last compatible route. Keep the new restrictive database grants if old application code can still use a safe server endpoint; do not reopen `public` wholesale.
2. **Projection/function defect:** restore the prior safe view/function definition from the reviewed migration, not the old public `is_admin(uuid)`/admin metrics behavior. Use additive `CREATE OR REPLACE` or a new versioned function; do not drop data objects.
3. **RLS/privilege regression:** restore only the minimum previously approved grants required for a known call site, after confirming access with role/JWT tests. Never roll back by granting `ALL` to anon/authenticated or `PUBLIC`.
4. **API schema setting error:** restore the prior schema list only with a tested compatibility plan; note this can re-expose base tables. Prefer reverting route code while retaining protections, and obtain security approval before any schema-list reversal.
5. **Default ACL error:** restore only the captured role-specific defaults needed by the migration owner. Do not apply global `GRANT ... TO PUBLIC` or broad defaults. Defaults are future-only and cannot replace restoring existing-object ACLs.
6. **Data migration mismatch:** keep source rows intact; stop switch-over, repair forward, or re-run idempotent copy. No destructive down migration is permitted.

Capture pre/post schema/ACL fingerprints and alert thresholds. Rollback is not permission to erase logs or evidence; retain minimal incident metadata per approved policy.

## 6. Operational gates after code work

When implementation is separately authorized: run repository tests, type generation/check, lint, `next build`, and migration validation; push normally without force; trigger and verify Vercel deployment; inspect logs and repeat until green. The present investigation changes no app code and therefore has no build/deployment status to report.

## 7. Related documents

- [Production security investigation](SCHOLARS_PHASE_2_1_1_PRODUCTION_SECURITY_INVESTIGATION_2026-11-09.md)
- [Privilege and API exposure matrix](SCHOLARS_PHASE_2_1_1_PRIVILEGE_AND_API_EXPOSURE_MATRIX_2026-11-09.md)
- [Least-privilege target design](SCHOLARS_PHASE_2_1_1_LEAST_PRIVILEGE_TARGET_DESIGN_2026-11-09.md)
- [Security test specification](SCHOLARS_PHASE_2_1_1_SECURITY_TEST_SPECIFICATION_2026-11-09.md)
