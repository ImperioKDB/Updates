# Scholars Resource Center — Phase A0.2 Native Stack Validation Report

**Validation date:** 2026-11-07  
**Repository:** `ImperioKDB/Scholars`  
**Reference branch:** `main`  
**Expected source commit:** `41573f5ec2985851ba118e8b39a47f9c54532302`  
**CLI:** Supabase `3.0.0`  
**Stack:** `scholars-a02-test`  
**Runtime:** native  
**Classification:** local-only validation; no hosted Supabase access

## 1. Result at a glance

The disposable native Supabase stack started successfully and provided healthy local PostgreSQL, PostgREST and Auth services. All service endpoints bound to `127.0.0.1`; no public network exposure was used.

Local Auth and PostgREST validation **PASSED** with two synthetic users and real locally issued JWTs. Anonymous requests resolved to the `anon` database role with no subject. Each synthetic authenticated JWT resolved to the `authenticated` database role and could read only its own row from a temporary RLS-protected probe table.

Resource Center migration and security testing was **NOT TESTED**. The required migration gate stopped the test before applying application migrations because the repository does not contain a safe, self-contained local migration sequence: it has 129 SQL files, 32 seed-named files containing real scholarship/opportunity data, no `supabase/config.toml`, no local migration lock, and an initial migration explicitly marked superseded and unsafe for the live project. The brief prohibits executing unsafe seeds, inventing missing schema, or applying only the two latest migrations when earlier dependencies are required.

The local stack was stopped and destroyed after validation. Temporary users, probe tables, JWTs, stack data and working files were removed. The Scholars checkout remained clean.

## 2. Isolation and authorization evidence

### Isolation checks

**PASS.** Before startup:

- Work directory was `/tmp/scholars-native-a02`, outside `/tmp/scholars-repo`.
- `SUPABASE_HOME` was `/tmp/scholars-native-a02-home`, also outside the Scholars checkout.
- The temporary directories were empty before initialization.
- `supabase stack list --output-format json` returned `{"stacks":[]}` before startup.
- Only `SUPABASE_HOME` and `SUPABASE_EXPERIMENTAL_STACK` were present among Supabase-related environment variable names. No production URL, database URL, access token, service-role key or JWT secret was loaded.
- No `supabase link`, hosted command, remote database command or production `.env` file was used.
- The stack name was explicitly unique: `scholars-a02-test`.
- The runtime was explicitly set to `native`.
- The Phase A0 PostgreSQL data directory was not reused. Native stack data was created under the temporary `SUPABASE_HOME` stack directory.
- The generated configuration contained no hosted project reference or credentials.

The CLI printed local development keys during startup. Those values were used only in memory/temporary files for local requests and are intentionally omitted from this report. They were removed during cleanup.

## 3. Exact commands used

The CLI was invoked from the disposable work directory with a temporary Supabase home:

```bash
cd /tmp/scholars-native-a02
export SUPABASE_HOME=/tmp/scholars-native-a02-home
export SUPABASE_EXPERIMENTAL_STACK=1

npx --yes --package=supabase@3.0.0 supabase init

npx --yes --package=supabase@3.0.0 supabase start \
  --runtime native \
  --stack scholars-a02-test \
  --preparation on-demand \
  --exclude studio,mail,analytics,pooler,realtime,storage,functions \
  --output-format json
```

The stack was inspected with:

```bash
npx --yes --package=supabase@3.0.0 supabase stack status \
  --stack scholars-a02-test --output-format json
```

The local database was accessed only through the emitted loopback URL with the local `postgres` password. HTTP checks used only the local publishable/anonymous key and the JWTs issued by the local Auth service.

## 4. Stack startup and service health

### Startup

**PASS.** The CLI returned `Stack is ready.` and reported runtime `native`.

The native stack identifier was:

```text
95ba3087bdbd9118d0104292acd735b690f1c011a80da2f1568261317997008e
```

### Local endpoints

All endpoints were loopback-only:

| Service | Endpoint | Health |
|---|---|---|
| PostgreSQL | `127.0.0.1:22055` | **PASS — healthy** |
| PostgREST | `http://127.0.0.1:26335/rest/v1` | **PASS — HTTP 200 and healthy after activation** |
| Auth | `http://127.0.0.1:26335/auth/v1` | **PASS — HTTP 200 and healthy after activation** |
| Studio | Not enabled | **NOT TESTED — intentionally excluded** |
| Mailpit/local SMTP | Not enabled | **NOT TESTED — intentionally excluded** |
| Realtime, Storage, Functions, Analytics, Pooler | Not enabled | **NOT TESTED — intentionally excluded** |

The first status check showed PostgREST and Auth as sleeping because on-demand preparation was selected. A REST root request and Auth settings request activated both services. The final status check reported database, REST and Auth as `running` and `healthy`.

The local listener check showed only loopback listeners on ports `22055` and `26335`. No public bind address was used.

## 5. PostgreSQL validation

### Version

**PASS.** The local database reported:

```text
PostgreSQL 17.11 on x86_64-pc-linux-gnu, compiled by gcc (GCC 15.2.0), 64-bit
```

### Roles

**PASS.** The expected Supabase API roles were present:

| Role | Superuser | Bypass RLS |
|---|---:|---:|
| `anon` | false | false |
| `authenticated` | false | false |
| `postgres` | false | true |
| `service_role` | false | true |
| `supabase_admin` | true | true |

### Schemas and extensions

**PASS.** The local database included `auth`, `extensions`, `graphql_public`, `public`, `realtime` and `storage` schemas.

The inspected extensions included:

- `pg_stat_statements` 1.11
- `pgcrypto` 1.3
- `uuid-ossp` 1.1

The local `supabase_migrations` table had no application migration records before the Scholars migrations were considered. This was expected for a newly initialized disposable stack.

## 6. Auth validation

### Synthetic identities

Two synthetic accounts were created locally with `.invalid` email domains:

- One ordinary student identity.
- One admin-labelled synthetic identity.

The admin label was stored only as local test metadata. It did not create an elevated database role; both users correctly received the standard JWT role claim `authenticated`. No real student email, identity or production account was used.

Signup returned HTTP 200 for both users. Because the local configuration did not return a session directly from signup, each account was authenticated separately through the local password-token endpoint.

### JWT issuance and claims

**PASS.** The local Auth password-token endpoint returned a JWT for both synthetic identities.

Sanitized claim evidence:

| Identity | JWT `sub` matched local Auth user | JWT role claim | JWT issuer |
|---|---:|---|---|
| Synthetic student | **PASS** | `authenticated` | local `127.0.0.1` Auth issuer |
| Synthetic admin-labelled user | **PASS** | `authenticated` | local `127.0.0.1` Auth issuer |

### Database authorization context

**PASS.** A temporary local view returned `auth.uid()` and `auth.role()` through PostgREST:

| Request | `auth.uid()` | `auth.role()` | Result |
|---|---|---|---|
| Anonymous | null | `anon` | **PASS** |
| Student JWT | student subject UUID | `authenticated` | **PASS** |
| Admin-labelled JWT | admin subject UUID | `authenticated` | **PASS** |

This confirms that local Auth-issued JWTs reached the local database authorization context correctly.

## 7. PostgREST and RLS validation

A temporary local table, `public.a02_auth_probe`, was created solely for this validation. It contained one synthetic row owned by each synthetic identity. RLS was enabled with a policy allowing `authenticated` users to read only rows where `auth.uid() = owner_id`.

| Request | HTTP result | Rows returned | Result |
|---|---:|---|---|
| Anonymous with local anonymous key | 200 | `[]` | **PASS** |
| Student JWT | 200 | student-owned row only | **PASS** |
| Admin-labelled JWT | 200 | admin-owned row only | **PASS** |

This validates the required local HTTP path: Auth-issued JWT → PostgREST → database role → `auth.uid()` → RLS policy.

No Resource Center table or production schema was used in this probe.

## 8. Migration safety gate

### Repository inventory

The clean Scholars checkout contained:

- 129 SQL migration files.
- 32 migration files whose names contain `seed`.
- 2 Resource Center migrations dated `20261107`.
- No `supabase/config.toml`.
- No `supabase/supabase.lock`.

The seed-named migrations contain real scholarship and opportunity content, external URLs, application instructions, contact details and research notes. They are not synthetic test fixtures and were not executed.

The first file, `0001_init.sql`, is explicitly marked **SUPERSEDED — kept for reference only**. Its comments state that it differs from the live project schema and must not be run against the live project. It therefore cannot be treated as an authoritative fresh-project baseline without a separate schema reconstruction decision.

### Decision

**STOPPED BEFORE MIGRATION APPLICATION — PASS.** The brief requires inspecting the complete history and prohibits unsafe seeds, arbitrary stubs, silently replacing missing migrations, or using production to resolve dependencies. Applying only the two Resource Center migrations would violate the same requirement because the repository contains earlier dependencies and the local stack has no application migration history.

No Scholars migration was applied. No Resource Center table, view, function or policy was created in the local stack.

## 9. Resource Center security test matrix

Because the migration safety gate stopped the test before application migrations, all Resource Center-specific checks are recorded honestly as **NOT TESTED** rather than inferred from Phase A0’s ordinary-PostgreSQL results.

| Resource Center check | Status | Reason |
|---|---|---|
| Anonymous published article reads | **NOT TESTED** | Resource Center migrations not applied |
| Anonymous draft exclusion | **NOT TESTED** | Resource Center migrations not applied |
| Future-scheduled article exclusion | **NOT TESTED** | Resource Center migrations not applied |
| Anonymous direct base-table denial | **NOT TESTED** | Resource Center migrations not applied |
| Ordinary student access restrictions | **NOT TESTED** | Resource Center migrations not applied |
| Admin access restrictions | **NOT TESTED** | Resource Center migrations not applied |
| Direct article status update behavior | **NOT TESTED** | Resource Center migrations not applied |
| Revision update/delete restrictions | **NOT TESTED** | Resource Center migrations not applied |
| Public view security metadata | **NOT TESTED** | Resource Center migrations not applied |
| Five remediated `SECURITY DEFINER` function grants | **NOT TESTED** | Resource Center migrations not applied |
| Default privileges for relevant creation roles | **NOT TESTED** | Resource Center migrations not applied |
| SQL-level Resource Center evidence | **NOT TESTED** | Resource Center migrations not applied |
| HTTP-level Resource Center evidence | **NOT TESTED** | Resource Center migrations not applied |

The independent local Auth, PostgREST and generic RLS path was validated successfully in Sections 6 and 7.

## 10. Differences from production that remain

Even after a successful native local startup, this environment is not production-equivalent:

- The local database began empty apart from Supabase system schemas and local test objects.
- The local service versions were those resolved by CLI `3.0.0`, not independently compared with the hosted project.
- Production schema history, migration drift, ownership, grants, default privileges and deployed settings were not imported.
- The local Auth configuration used synthetic users, local issuer settings and autoconfirm behavior.
- Studio, Storage, Realtime, Functions, SMTP, Analytics and Pooler were intentionally excluded.
- The native runtime runs host processes and does not provide Docker network/filesystem isolation.
- No local test was performed against a hosted project, by design.

## 11. Cleanup verification

**PASS.** The stack was stopped and destroyed with CLI `3.0.0` using the same temporary `SUPABASE_HOME` and stack name. The temporary work directory and Supabase home were removed, including local test users, probe objects, JWT files and stack data.

The shared npm and native artifact caches were not deleted because they may be used by other work and were not established to be exclusive to this test.

Post-cleanup verification confirmed:

- No listener remained on local ports `22055` or `26335`.
- No `scholars-a02-test` stack remained in the temporary Supabase home.
- `/tmp/scholars-native-a02` and `/tmp/scholars-native-a02-home` were removed.
- `/tmp/scholars-repo` remained clean at `main...origin/main`.
- No production credential or hosted project was accessed.

## 12. Recommendation for the next phase

**Do not proceed directly to Resource Center security assertions from this run.** The next phase requires a safe local schema source before any Resource Center migration can be applied. The options are:

1. Provide or authorize a complete, self-contained synthetic/local migration baseline that is known to match the current Scholars schema, with real-data seed migrations excluded.
2. Provide a reviewed local-only migration bundle or schema dump that does not contain production data or credentials.
3. Separately authorize a migration-reconstruction task to resolve the superseded `0001_init.sql`, duplicate migration sequence numbers and dependencies before running the Resource Center migrations.

No production access, hosted fallback, security fixes, CMS work, deployment or repository modification was performed.

## References

[1]: https://supabase.com/docs/guides/local-development/docker-and-native-runtimes "Docker and native runtimes"
[2]: https://supabase.com/docs/guides/local-development/running-multiple-local-projects "Running multiple local projects"
[3]: https://supabase.com/docs/guides/local-development/cli/getting-started "Supabase CLI"
