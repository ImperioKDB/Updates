# Scholars Resource Center — Manus Session Handoff

**Handoff date:** 2026-11-07  
**Project:** Scholars  
**Repository:** `ImperioKDB/Scholars`  
**Reference branch:** `main`  
**Expected source commit:** `41573f5ec2985851ba118e8b39a47f9c54532302`  
**Updates repository:** `ImperioKDB/Updates`  
**Continuation point:** After Phase A0.2 isolated native Supabase stack validation

## Read first

1. `SCHOLARS_RESOURCE_CENTER_PHASE_A0_1_NATIVE_RUNTIME_FEASIBILITY_REPORT_2026-11-07.md`
2. `SCHOLARS_RESOURCE_CENTER_PHASE_A0_2_NATIVE_STACK_VALIDATION_REPORT_2026-11-07.md`
3. This handoff document

These files are the durable continuation artifacts. No local stack, test users, JWTs, temporary database, or temporary Supabase home remains running after cleanup.

## Current status

Phase A0.1 established that this sandbox is compatible with Supabase’s experimental native runtime. Phase A0.2 then started one disposable local Supabase CLI `3.0.0` native stack and successfully validated the local PostgreSQL, Auth, PostgREST and HTTP-level RLS path.

The Resource Center migration/security phase did **not** begin. The migration safety gate stopped the run before any Scholars migration was applied. This was required by the task brief and must not be bypassed in the next session.

### What passed

- Supabase CLI `3.0.0` ran outside the tracked Scholars checkout.
- One stack started with explicit `--runtime native`.
- Local PostgreSQL started healthy and reported PostgreSQL 17.11.
- Expected Supabase roles were present: `anon`, `authenticated`, `service_role`, `postgres`, and `supabase_admin`.
- Expected local Supabase schemas were present, including `auth`, `extensions`, `graphql_public`, `public`, `realtime` and `storage`.
- PostgREST returned HTTP 200 on the local REST root endpoint.
- Auth returned HTTP 200 on the local settings endpoint.
- Two synthetic users were created using `.invalid` email addresses.
- Both users authenticated through local Auth and received local JWTs.
- Anonymous HTTP requests resolved to database role `anon` with `auth.uid() = null`.
- Each synthetic JWT resolved to database role `authenticated` with the correct local subject UUID.
- A temporary RLS probe returned no rows anonymously and only the caller’s own row for each authenticated user.
- All service endpoints were bound to `127.0.0.1`; no public exposure occurred.
- The stack was stopped and destroyed successfully.
- No local service remains running.
- The Scholars checkout remains clean at `main...origin/main`.

### What is not tested

All Resource Center-specific tests remain **NOT TESTED**:

- Anonymous published article reads
- Draft exclusion
- Future-scheduled article exclusion
- Direct base-table denial
- Ordinary student restrictions
- Admin restrictions
- Direct article status updates
- Revision update/delete restrictions
- Public view security metadata
- The five remediated `SECURITY DEFINER` function grants
- Default privileges for object-creation roles
- SQL-level and HTTP-level Resource Center evidence

No Resource Center tables, views, functions or policies were created in the local native stack.

## Why the migration phase stopped

The clean Scholars checkout contains:

- 129 SQL migration files
- 32 migration files with `seed` in the filename
- 2 Resource Center migration files dated `20261107`
- No `supabase/config.toml`
- No `supabase/supabase.lock`

The seed migrations contain real scholarship/opportunity content, external URLs, application instructions, contact details and research notes. They are not synthetic fixtures and must not be executed for this test.

The first migration, `0001_init.sql`, is explicitly marked **SUPERSEDED — kept for reference only**. Its own comments say it differs materially from the live project schema and must not be run against the live project. It cannot safely serve as an authoritative local baseline without a separate schema-reconstruction decision.

The next session must not:

- Apply only the two latest Resource Center migrations as a shortcut.
- Execute real-data seed migrations.
- Invent missing tables, enums, roles, functions or policies.
- Treat the Phase A0 ordinary-PostgreSQL results as proof of native PostgREST behavior.
- Use production or a hosted Supabase project to resolve missing dependencies.

## Safe next-phase choices

Before Resource Center security testing can continue, choose one explicitly authorized path:

### Option A — reviewed local migration bundle

Provide or create a reviewed, local-only migration bundle that contains the complete schema dependencies required by the Resource Center migrations, excludes real-data seed content, and is known to match the intended Scholars schema. Apply it only in a new disposable native stack.

### Option B — schema reconstruction assessment

Run a separate read-only/reconstruction phase to resolve:

- The superseded `0001_init.sql` baseline.
- Duplicate numeric migration prefixes and ordering.
- Dependencies among schema, privilege, function and policy migrations.
- Which data migrations are safe to omit for a synthetic security test.
- Required extensions, roles, triggers and default privileges.

This phase must not use production to fill gaps.

### Option C — stop and report

If neither a safe local bundle nor an authorized reconstruction plan is available, keep the Resource Center migration/security tests unexecuted and report the limitation.

## If a future stack is authorized

Use a new disposable directory and temporary Supabase home. Do not reuse the deleted A0.2 stack:

```bash
rm -rf /tmp/scholars-native-a03 /tmp/scholars-native-a03-home
mkdir -p /tmp/scholars-native-a03 /tmp/scholars-native-a03-home
cd /tmp/scholars-native-a03

export SUPABASE_HOME=/tmp/scholars-native-a03-home
export SUPABASE_EXPERIMENTAL_STACK=1

npx --yes --package=supabase@3.0.0 supabase init

npx --yes --package=supabase@3.0.0 supabase start \
  --runtime native \
  --stack scholars-a03-test \
  --preparation on-demand \
  --exclude studio,mail,analytics,pooler,realtime,storage,functions \
  --output-format json
```

Before startup, verify that the workdir and `SUPABASE_HOME` are outside the Scholars checkout, no Supabase-related production environment variables are loaded, `supabase stack list` does not contain the chosen stack name, and no hosted command will be used. Keep Auth and REST enabled. Use only `.invalid` synthetic identities and local JWTs.

After startup, verify service health individually. Do not treat a successful CLI exit as proof that lazy REST/Auth services are healthy; activate and test them over loopback HTTP, then inspect `supabase stack status --output-format json` again.

If migrations are authorized later, inspect every candidate file before execution, apply only an approved complete local sequence, record each migration result, and stop immediately on missing dependencies or unsafe behavior. Never fall back to a hosted database.

## Cleanup requirements

At the end of any future local run:

```bash
export SUPABASE_HOME=/tmp/scholars-native-a03-home
export SUPABASE_EXPERIMENTAL_STACK=1

npx --yes --package=supabase@3.0.0 supabase stop \
  --stack scholars-a03-test --yes
npx --yes --package=supabase@3.0.0 supabase stack destroy \
  --stack scholars-a03-test --yes
```

Then remove only the disposable workdir and temporary Supabase home after verifying the stack is destroyed. Do not delete shared npm/native artifact caches unless exclusive ownership is established. Confirm no loopback listener or Supabase stack process remains and run `git status --short --branch` in the Scholars checkout.

## Immutable authorization boundary

The next session is not authorized to:

- Access or modify production Supabase.
- Access or modify the `serena` project.
- Create another hosted Supabase project.
- Run `supabase link`.
- Run hosted database commands.
- Run `supabase db push --linked`.
- Load production `.env` files, database URLs, JWT secrets or API keys.
- Modify tracked Scholars source files or migrations.
- Commit, push, merge or deploy to Scholars.
- Seed real student, scholarship or opportunity data.
- Implement the editorial interface or publishing workflow.
- Apply security fixes during validation.

The only completed authorization in A0.2 was one disposable local native stack. That stack no longer exists.

## Prior durable reports

The reports in this Updates repository are the authoritative evidence package:

- `SCHOLARS_RESOURCE_CENTER_PHASE_A0_1_NATIVE_RUNTIME_FEASIBILITY_REPORT_2026-11-07.md` — platform/CLI feasibility; recommendation was conditionally ready.
- `SCHOLARS_RESOURCE_CENTER_PHASE_A0_2_NATIVE_STACK_VALIDATION_REPORT_2026-11-07.md` — actual local stack startup, service health, Auth/JWT/PostgREST/RLS results, migration stop and cleanup.

No credentials, JWTs, real user data or temporary local database files are included in this handoff.
