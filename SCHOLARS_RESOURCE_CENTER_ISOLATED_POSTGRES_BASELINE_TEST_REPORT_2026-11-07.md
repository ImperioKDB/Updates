# Scholars Resource Center — Isolated PostgreSQL Baseline Test Report

**Phase:** A0 — isolated PostgreSQL test environment and baseline testing  
**Investigation date:** 2026-11-07  
**Source repository:** `ImperioKDB/Scholars`  
**Source branch/head:** `main` at `41573f5ec2985851ba118e8b39a47f9c54532302`  
**Production systems:** Not connected to or modified  
**Test data:** Synthetic only  
**Report scope:** Environment assessment and baseline testing only

## 1. Executive verdict

**PARTIALLY VERIFIED — USEFUL SQL/RLS BASELINE, NOT A SUPABASE-EQUIVALENT TEST ENVIRONMENT.**

The sandbox initially had no Docker, Podman, PostgreSQL, Supabase CLI, Supabase local stack or PostgREST. A disposable PostgreSQL 16 cluster was installed and started under `/tmp`, with a temporary Unix socket and port. The two current Resource Center migrations applied successfully after creating synthetic Supabase-like roles, a minimal `auth` schema, a minimal `auth.uid()` helper, a minimal `profiles` table and stubs for the five pre-existing worker functions required by the security migration.

The isolated database reproduced important PostgreSQL behavior:

- Public projection views were owner-executed `security_barrier` views, not `security_invoker` views.
- Anonymous access to the public article projection returned only the eligible published synthetic article.
- Anonymous direct base-table access was denied by table privileges.
- Ordinary authenticated students received zero base-table rows and could not insert or update articles through RLS.
- An authenticated synthetic admin could directly change a draft article to `published`, demonstrating that the current broad admin policy is not an editorial workflow-transition boundary.
- Authenticated revision update/delete attempts were denied by table privileges.
- The five remediation functions denied execution to `anon` and `authenticated` while retaining `service_role` execution.
- Synthetic `supabase_admin` default privileges remained broad after the migration narrowed defaults for `postgres`, matching the production catalog finding.

These tests do **not** prove Supabase PostgREST behavior, Supabase Auth behavior, production behavior, or service-role behavior. The test runtime was ordinary PostgreSQL 16, while production reports PostgreSQL 17.6.1.155. PostgREST, Supabase Auth JWT processing, Supabase-specific role setup, Supabase local services and production extensions/configuration were unavailable or simulated.

**No Scholars repository files, production database objects, production records, credentials, environment variables, deployments or grants were changed.** The temporary database and synthetic data were removed after testing.

## 2. Environment selected and why

### 2.1 Capability assessment

| Capability | Result | Evidence |
|---|---|---|
| Docker | **NOT AVAILABLE** | `command -v docker` returned unavailable |
| Podman | **NOT AVAILABLE** | `command -v podman` returned unavailable |
| PostgreSQL before setup | **NOT AVAILABLE** | `psql`, `postgres`, `initdb` and `pg_isready` unavailable |
| PostgreSQL after setup | **AVAILABLE** | Ubuntu PostgreSQL 16.15 installed locally and used on temporary port `55432` |
| Supabase CLI | **NOT AVAILABLE** | `command -v supabase` returned unavailable |
| Supabase local development stack | **NOT AVAILABLE** | Supabase CLI and Docker unavailable |
| PostgREST | **NOT AVAILABLE** | No PostgREST binary/service was present |
| Node.js/Python | **AVAILABLE** | Node 22.23.4, npm 10.9.9, Python 3.12.3 |
| Automated SQL/database tests | **AVAILABLE, ordinary PostgreSQL only** | `psql` migration and access-test scripts passed against the disposable cluster |
| Scholars JavaScript test suite | **NOT TESTED** | `npm test` failed because `vitest` is not installed in the checkout; no dependency installation was performed |

### 2.2 Selected approach

**RECOMMENDATION / LIMITATION:** Because the preferred Supabase local stack was unavailable, the safest available alternative was a temporary ordinary PostgreSQL instance. It was selected because it can exercise PostgreSQL RLS, ACLs, roles, policies, views, constraints and `SECURITY DEFINER` metadata without touching production.

The environment is not a Supabase replica. It is a narrowly scoped SQL baseline harness.

## 3. Exact setup and test commands used

All temporary files were outside the repositories, under `/tmp`:

```bash
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq postgresql postgresql-client

/usr/lib/postgresql/16/bin/initdb \
  -D /tmp/scholars-phase-a0-pgdata \
  --auth-local=trust --auth-host=trust

/usr/lib/postgresql/16/bin/pg_ctl \
  -D /tmp/scholars-phase-a0-pgdata \
  -o "-k /tmp/scholars-phase-a0-sock -p 55432" \
  -l /tmp/scholars-phase-a0.log start

createdb -h /tmp/scholars-phase-a0-sock -p 55432 scholars_a0
```

The bootstrap script created only synthetic local objects:

- Roles: `anon`, `authenticated`, `service_role`, `supabase_admin`.
- Minimal `auth.users` table.
- Minimal `public.profiles` table with an `is_admin` flag.
- Synthetic `auth.uid()` helper based on a local session setting.
- Synthetic `public.is_admin(uuid)` helper.
- Five stub worker functions with the signatures required by the security migration.
- Synthetic broad `supabase_admin` default privileges to compare the migration’s role scope.

The current repository migration files were applied directly from the clean Scholars checkout:

```bash
psql -h /tmp/scholars-phase-a0-sock -p 55432 -d scholars_a0 \
  -v ON_ERROR_STOP=1 \
  -f /tmp/scholars-repo/supabase/migrations/20261107130000_security_boundary_remediation.sql

psql -h /tmp/scholars-phase-a0-sock -p 55432 -d scholars_a0 \
  -v ON_ERROR_STOP=1 \
  -f /tmp/scholars-repo/supabase/migrations/20261107130100_resource_center_schema.sql
```

Synthetic records represented:

- One eligible published article.
- One draft article.
- One future-dated published article.
- One future-scheduled article.
- One archived article.
- One synthetic category and editorial identity.
- One synthetic revision.
- One ordinary student and one admin profile.

The cluster was stopped and the `/tmp/scholars-phase-a0-pgdata`, socket and test files were removed after the baseline.

## 4. Migration results

| Migration | Result | Evidence |
|---|---|---|
| `20261107130000_security_boundary_remediation.sql` | **PASS** | All targeted REVOKE/GRANT and default-privilege statements completed successfully |
| `20261107130100_resource_center_schema.sql` | **PASS** | All tables, indexes, constraints, policies, views, revokes and grants completed successfully |

The migration test used local stubs for objects that already exist in the production application’s broader migration history. It therefore verifies migration syntax and local PostgreSQL behavior, not completeness of a fresh Supabase project bootstrap.

## 5. Security test matrix

| Area | Result | Evidence and interpretation |
|---|---|---|
| Anonymous users can read eligible published articles | **PASS — ordinary PostgreSQL** | `anon` queried `resource_public_articles` and received only `published-article` with `published_at <= now()` |
| Anonymous users cannot read drafts | **PASS — ordinary PostgreSQL** | `draft-article` was absent from the public projection |
| Anonymous users cannot read future/unpublished articles | **PASS — ordinary PostgreSQL** | Future-dated, scheduled and archived fixtures were absent from the public article projection |
| Anonymous users cannot query private base tables | **PASS — ordinary PostgreSQL** | Direct `anon` SELECT on `resource_articles` failed with permission denied |
| Public projections expose only intended fields | **PARTIALLY VERIFIED** | Explicit view columns were inspected and public query returned the selected fields; PostgREST schema exposure was not available |
| View security is invoker-executed | **FAIL / NOT THE APPROVED MODEL** | All four views had `{security_barrier=true}`, owner `postgres`, and no `security_invoker=true`; owner bypass-RLS was true |
| Ordinary student can read base articles | **PASS — ordinary PostgreSQL** | Authenticated synthetic student received zero rows from `resource_articles` |
| Ordinary student can read revisions | **PASS — ordinary PostgreSQL** | Authenticated synthetic student received zero rows from `resource_revisions` |
| Ordinary student can read public articles | **PASS — ordinary PostgreSQL** | Student could read the one eligible public article through the projection |
| Ordinary student can create articles | **PASS — ordinary PostgreSQL** | Insert failed with an RLS policy error |
| Ordinary student can change article status | **PASS — ordinary PostgreSQL** | Update affected zero rows because the student could not pass the article policy |
| Admin can directly change article status | **FAIL for future workflow expectation / VERIFIED current behavior** | Synthetic admin updated `draft-article` to `published`; no transition function or freshness check blocked it |
| Admin can update revision snapshots | **PASS — ordinary PostgreSQL** | Authenticated update failed with permission denied |
| Admin can delete revision snapshots | **PASS — ordinary PostgreSQL** | Authenticated delete failed with permission denied |
| Revisions require complete snapshots | **NOT TESTED as a semantic contract / absent from schema** | The only local database check is `jsonb_typeof(state) = 'object'`; required keys are not enforced |
| Revision restoration creates a new revision | **NOT IMPLEMENTED** | No restoration operation exists in the migration or current foundation |
| Stale approval reuse is prevented | **NOT IMPLEMENTED** | No approval identity/freshness operation exists |
| Five remediated functions block anon/authenticated | **PASS — ordinary PostgreSQL** | All five returned `false` for `anon` and `authenticated` execution privileges |
| Five remediated functions retain service-role execution | **PASS — simulated role ACL** | All five returned `true` for `service_role` execution privilege |
| `postgres` default privileges narrowed | **PASS — ordinary PostgreSQL** | Local post-migration defaults for objects created by `postgres` retained only `postgres`/`service_role` grants |
| `supabase_admin` default privileges narrowed | **FAIL / NOT ADDRESSED BY MIGRATION** | Synthetic broad `supabase_admin` defaults remained for functions, tables and sequences |

## 6. Detailed findings

### 6.1 Public views

**VERIFIED:** Each public view was created with:

```text
owner = postgres
reloptions = {security_barrier=true}
owner_bypasses_rls = true
```

The underlying base tables had RLS enabled and `FORCE ROW LEVEL SECURITY = false`. The local public projection query returned only the eligible published article. This confirms the explicit predicates function in ordinary PostgreSQL.

**INFERENCE:** The public boundary currently depends on owner-executed view definitions, explicit column lists and fixed predicates rather than invoker-context RLS. A future view edit could expose owner-readable rows or columns even if base-table RLS remains unchanged.

**UNVERIFIED:** PostgREST behavior, generated schema exposure, HTTP error formats and Supabase view security semantics were not tested because PostgREST and the Supabase local stack were unavailable.

### 6.2 Base-table access

**VERIFIED:** The local migration produced the following effective pattern:

- `anon`: no base-table SELECT.
- `authenticated`: table-level SELECT/INSERT/UPDATE grants on the article/category/identity tables, but only admin RLS policies allow rows/actions.
- `resource_revisions`: authenticated SELECT/INSERT grants, with admin-only policies; no authenticated update/delete privileges.
- `service_role`: controlled table grants were present in the local ACL model.

**VERIFIED:** Ordinary student reads returned zero rows and student article insertion failed with RLS denial.

**VERIFIED:** An admin could directly update a draft article’s `status`, `published_at` and `reviewer_identity_id`. This is current access control, not a safe editorial workflow transition.

### 6.3 Function ACLs and defaults

**VERIFIED:** The five targeted worker/maintenance functions returned:

```text
anon_execute = false
authenticated_execute = false
service_role_execute = true
```

**PARTIALLY VERIFIED:** The local harness simulated a broad `supabase_admin` default ACL because ordinary PostgreSQL installation does not create Supabase’s platform roles and defaults automatically. The migration only altered defaults for role `postgres`; it did not alter the separate synthetic `supabase_admin` defaults. This reproduces the scope distinction observed in production, but not Supabase’s platform provisioning behavior.

## 7. Supabase-specific behavior not reproduced

The following remain unverified:

1. Supabase local development stack behavior.
2. PostgREST direct HTTP access and schema cache behavior.
3. Supabase Auth JWT parsing and the production `auth.uid()` implementation.
4. Real `anon`, `authenticated` and `service_role` role attributes as provisioned by Supabase.
5. Service-role RLS bypass behavior in the exact Supabase configuration.
6. Supabase’s actual ownership and default-privilege provisioning roles.
7. PostgreSQL 17.6.1.155 production behavior versus local PostgreSQL 16.15.
8. Supabase migration-history integration and CLI application behavior.
9. Supabase API exposure of views and exact column metadata.
10. Production extensions, hooks, triggers and policies outside the two Resource Center migrations.

The ordinary PostgreSQL results must not be described as proof of production or PostgREST behavior.

## 8. Differences between isolated environment and production

| Dimension | Isolated A0 environment | Production reference |
|---|---|---|
| Database engine | PostgreSQL 16.15 | PostgreSQL 17.6.1.155 reported for Supabase |
| Hosting | Temporary local Unix socket/port | Supabase managed project |
| PostgREST | Not installed | Production Supabase API path exists, but not exercised here |
| Auth | Minimal synthetic `auth.users` and `auth.uid()` | Supabase Auth |
| Roles | Synthetic local roles | Supabase-managed role environment |
| Existing schema | Minimal stubs plus Resource Center migrations | Full Scholars schema and migration history |
| Service role | ACL simulation; exact bypass semantics not tested | Supabase service-role behavior |
| Data | Synthetic fixtures only | Production currently has zero Resource Center rows |
| Defaults | Synthetic `supabase_admin` defaults modeled from observed evidence | Production has role-specific default ACL rows |
| Application | No Next.js runtime or HTTP integration test | Deployed Scholars application |

## 9. Blockers to reliable Supabase-equivalent testing

1. No Docker or Podman runtime.
2. No Supabase CLI.
3. No Supabase local development stack.
4. No PostgREST service.
5. No verified non-production Supabase project or branch.
6. No permission to create another Supabase project under the current plan constraints.
7. No installed Scholars JavaScript dependencies, so the repository’s Vitest suite was not run.
8. Ordinary PostgreSQL cannot by itself validate Supabase Auth, PostgREST, platform role provisioning or API schema exposure.

## 10. Recommended next steps for Phase A security remediation

1. Keep the current A0 report classified as an ordinary PostgreSQL baseline, not a Supabase certification.
2. Obtain an explicitly approved disposable Supabase-compatible target, such as an owner-provided local Supabase stack on a machine with Docker or an approved temporary environment. Do not use `serena` without explicit approval.
3. Re-run the public-view tests through PostgREST using synthetic JWT identities for `anon`, student and admin roles.
4. Decide and document whether the production design is `security_invoker=true` plus base-table RLS, or owner-executed explicit projections with mandatory view-definition regression tests.
5. Add workflow tests proving that ordinary admin table writes cannot bypass guarded publication transitions once the workflow is implemented.
6. Define and test the complete revision snapshot contract, immutable history, restoration-by-new-revision and stale-approval prevention.
7. Review default privileges for every object-creation role, especially `postgres` and `supabase_admin`, in the approved non-production target before any production remediation.
8. Install repository dependencies only in a disposable checkout if JavaScript regression tests are required; do not change tracked source files.
9. Keep production migrations, grants, content and deployments unchanged until the Supabase-equivalent test pass is complete and separately approved.

## 11. Final status

**A0 BASELINE COMPLETE WITH LIMITATIONS.**

The available environment supported a useful isolated PostgreSQL test, but not a Supabase-equivalent integration test. The baseline confirms the important current behavior and the direct-admin-status-update gap. It does not authorize fixes, production migration changes, editorial implementation, deployment or repository changes.

The next step requires explicit approval of a genuine Supabase-compatible non-production test target or acceptance that the remaining Supabase-specific checks are unverified.
