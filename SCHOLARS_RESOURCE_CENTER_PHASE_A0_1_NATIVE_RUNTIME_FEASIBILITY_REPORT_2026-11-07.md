# Scholars Resource Center — Phase A0.1 Native Runtime Feasibility Report

**Investigation date:** 2026-11-07  
**Repository:** `ImperioKDB/Scholars`  
**Reference branch:** `main`  
**Scope:** Read-only feasibility assessment. No Supabase stack was started. No production or hosted Supabase project was accessed or modified. No tracked repository file was changed.

## 1. Final recommendation

**CONDITIONALLY READY.**

The sandbox satisfies the documented platform prerequisites for the experimental Supabase native runtime: Ubuntu 24.04.5 LTS, Linux `amd64`, glibc 2.39, a non-root `ubuntu` account, approximately 23 GiB memory, approximately 38 GiB available disk, `tar`, Node.js 22.23.4 and network access to Supabase documentation and release infrastructure.

The current Supabase CLI can be executed outside the tracked repository. CLI `3.0.0` exposes the experimental `stack` commands and `supabase start --runtime native`. The official documentation states that the native runtime can run the local Supabase services as host processes without Docker, including Postgres, Auth, PostgREST, Realtime, Storage, Edge Functions and Studio.[1] [2]

This is not classified as fully ready because the runtime is Public Alpha and its stack commands are experimental and outside the CLI compatibility promise.[1] It was not started during this assessment, so actual service startup, archive downloads, local JWT issuance, PostgREST access and Studio readiness remain unverified in this sandbox.

The safest next step is a separately authorized, disposable native stack under a temporary work directory and temporary `SUPABASE_HOME`, with no production credentials, no hosted-project link and no tracked-repository dependency installation. The stack should be started only after confirming those isolation controls in the next task.

## 2. Environment compatibility evidence

### Operating system and architecture

**VERIFIED:**

```text
OS:           Ubuntu 24.04.5 LTS
Kernel:       Linux 6.18.38+
Architecture: x86_64 / amd64
CPU count:    6
glibc:        2.39
```

The native-runtime documentation supports Linux on `amd64` or `arm64` with glibc 2.35 or later, including Ubuntu 22.04 or later.[1] This sandbox meets that requirement.

### Memory and disk

**VERIFIED:**

```text
Memory:       23 GiB total, approximately 21 GiB available
Swap:         0
Disk:         48 GiB filesystem, approximately 38 GiB available
```

**RECOMMENDATION:** The available resources are adequate for a single disposable native project, but the lack of swap means the stack should not be run concurrently with other memory-heavy workloads. Supabase’s announcement reports approximately 290 MiB idle memory for the native runtime with cached artifacts, but that is an upstream measurement rather than a guarantee for this sandbox.[3]

### Node, npm, account and host tools

**VERIFIED:**

```text
Node.js:      v22.23.4
npm:          10.9.9
Python:       3.12.3
GNU tar:      1.35
Non-root:     ubuntu (uid 1000)
Postgres OS:  postgres (uid 104), available from the earlier A0 setup
```

The current CLI installation guide requires Node.js 20 or later when the CLI is run through npm or `npx`.[4] The sandbox meets that requirement.

### Network and artifact download capability

**VERIFIED:** An HTTPS request to the official Supabase documentation returned HTTP 200. The native-runtime documentation states that the CLI downloads verified service archives from Supabase’s GitHub releases, with an S3 fallback, and extracts them with the host `tar` command.[1]

**UNVERIFIED:** The actual service archive download and checksum verification were not run because this task prohibits starting the native stack and the CLI’s preparation operation was not invoked. GitHub release and S3 allowlisting should be checked before a future isolated start if the sandbox uses outbound allowlists.

## 3. Supabase CLI and native-runtime support

### Current CLI probe

**VERIFIED:** Running the current published CLI outside the tracked repository produced:

```text
CLI version: 3.0.0
```

The probe was executed from `/tmp/supabase-cli-probe` using a temporary npm package cache. It did not run `supabase init`, `supabase start`, `supabase link`, a hosted command or any database operation.

With `SUPABASE_EXPERIMENTAL_STACK=1`, the CLI exposed:

- `supabase stack list`
- `supabase stack start`
- `supabase stack status`
- `supabase stack stop`
- `supabase stack destroy`
- `supabase stack install`
- `supabase stack logs`
- `supabase start --runtime native`
- `--preparation on-demand`
- `--eager`
- `--exclude`

The current release is `v3.0.0`, published 2026-11-02.[5]

### Native runtime maturity

**VERIFIED:** The official feature page labels the native runtime **Public Alpha** and says the experimental setting is required in CLI v2.119.0 or later.[2] The documentation explicitly says the `supabase stack` commands are experimental and not covered by the CLI compatibility promise.[1]

**IMPLICATION:** The native runtime is suitable for an isolated feasibility or CI test environment with pinned CLI/artifact versions and cleanup procedures. It should not be treated as production-equivalent infrastructure or a stable long-term local-development contract without a fallback.

## 4. Expected services and feasibility

The official documentation describes the native runtime as the same local Supabase project model run as host processes rather than containers. The expected local service surface includes:

- PostgreSQL
- Auth / GoTrue
- PostgREST
- Realtime
- Storage
- Edge Functions
- Studio
- Local API gateway and supporting services

**VERIFIED FROM DOCUMENTATION:** Postgres starts immediately; other services can start on their first request, and `--eager` activates all enabled services before the command returns.[1] The CLI guide documents local REST, Auth, Storage, Realtime and Studio endpoints for a normal local stack.[4]

**NOT TESTED:** This sandbox did not start any of these services, so their actual local ports, process health, JWT issuance, REST responses, database role setup and Studio behavior remain unverified here.

### Feasibility by capability

| Capability | Phase A0 PostgreSQL | Proposed native runtime | Current A0.1 status |
|---|---|---|---|
| PostgreSQL | Ordinary PostgreSQL 16 | Supabase local PostgreSQL with the local service bundle | **Conditionally feasible** |
| Auth | Synthetic `auth.users` and `auth.uid()` only | Supabase Auth / GoTrue | **Expected, not tested** |
| PostgREST | Not available | Local REST gateway | **Expected, not tested** |
| JWT role simulation | Manual `SET ROLE` and session setting | Supabase-issued local JWTs and API roles | **Expected, not tested** |
| RLS testing | PostgreSQL ACL/RLS behavior tested | RLS through PostgREST and real local roles | **Partially verified in A0; native untested** |
| Public view testing | Direct SQL only | Direct PostgREST requests as anon/student/admin | **Partially verified in A0; native untested** |
| Service-role testing | Simulated local role ACL | Local service/secret-key path | **Expected, not tested** |
| Studio | Not available | Local Studio, subject to REST dependency | **Expected, not tested** |
| Production isolation | No production connection | Local files/processes; safe if no hosted link/credentials are used | **Design feasible; actual stack not started** |

## 5. Proposed safe setup for a future authorized test

This is a proposed plan, not an executed setup.

### Isolation controls

1. Use a temporary directory outside `/tmp/scholars-repo`, such as `/tmp/scholars-native-a01`.
2. Set `SUPABASE_HOME` to another disposable directory, such as `/tmp/scholars-native-a01-home`, so stack data and downloaded artifacts are separated from any user-level local Supabase state.
3. Do not run `supabase link`, `supabase db push --linked`, hosted commands or any command that needs a production project reference.
4. Do not load production `.env` files or production Supabase URLs/keys.
5. Use a named stack, such as `--stack scholars-a01-test`, so it cannot collide with another local stack.
6. Bind and access local services only on loopback if the generated configuration permits it. Never expose the local API or Studio publicly.
7. Use synthetic users, synthetic articles, synthetic categories and synthetic revisions only.
8. Record the CLI version and lock/artifact versions before testing.
9. Destroy the stack and remove the disposable `SUPABASE_HOME` after the test.

### Proposed commands

Do not run these commands without explicit authorization for the next phase:

```bash
mkdir -p /tmp/scholars-native-a01 /tmp/scholars-native-a01-home
cd /tmp/scholars-native-a01

export SUPABASE_HOME=/tmp/scholars-native-a01-home
export SUPABASE_EXPERIMENTAL_STACK=1

# Install or invoke a pinned CLI outside the tracked Scholars checkout.
npx --yes --package=supabase@3.0.0 supabase --version

# Initialize only in the disposable directory.
npx --yes --package=supabase@3.0.0 supabase init

# Start only after confirming the directory contains no production credentials
# and the native runtime is selected explicitly.
npx --yes --package=supabase@3.0.0 supabase start \
  --runtime native \
  --stack scholars-a01-test \
  --preparation on-demand \
  --output-format json
```

For the Resource Center tests, the next phase should keep Auth and REST enabled. Studio may be excluded if it is not needed, which reduces the service surface. The exact `--exclude` list should be chosen after inspecting the generated local configuration and confirming that REST/Auth remain enabled.

The test should then apply only the local migration set, create synthetic Auth users through the local Auth service or documented local seed path, and test the four public views through local PostgREST using local publishable/anon and synthetic authenticated JWTs. It should not use production JWTs or production API keys.

## 6. Differences from production

Even if the native stack starts successfully, it will not be identical to the managed production project. Expected differences include:

- Local service versions and configuration may differ from the production Supabase project.
- Local Auth settings, email delivery, redirect URLs and providers will be synthetic or disabled.
- Local database contents will be empty or synthetic.
- Production extensions, role ownership, default privileges and historical drift may not be reproduced automatically.
- Local PostgREST schema-cache behavior may differ until migrations/reloads complete.
- Local service processes share the host process table and file locks; unlike Docker, native projects do not get separate network namespaces and file systems.[1]
- The native stack is experimental and may change between CLI releases.[1]
- Studio requires the REST service and is not evidence that production authorization is correct.

The native runtime would improve the Phase A0 baseline substantially by adding real local Auth, PostgREST, Supabase role handling and service wiring. It would still not replace production read-only catalog inspection or a separate migration-verification procedure.

## 7. Experimental-runtime risks

1. **Compatibility risk:** `supabase stack` is outside the CLI compatibility promise.
2. **Artifact risk:** first start downloads service archives and depends on GitHub/S3 connectivity and checksum verification.
3. **Isolation risk:** native processes share host resources and are less isolated than containers when multiple projects run on one host.
4. **Credential risk:** careless use of environment files or hosted CLI commands could connect to a remote project; this must be prevented by using a clean disposable `SUPABASE_HOME` and work directory.
5. **Version drift:** unpinned CLI or service artifacts can change behavior between runs.
6. **Cleanup risk:** `stack destroy` removes local project data, but the shared native artifact cache remains unless it is manually removed.[1]
7. **Resource risk:** the sandbox has no swap and only one tested native project should run at a time.
8. **Production-equivalence risk:** passing local Auth/PostgREST tests does not prove production ACLs, defaults, migrations, extensions or deployment configuration are correct.

## 8. Conclusion

The sandbox is technically compatible with the documented native runtime and the current CLI supports the required experimental commands. The native runtime is therefore a viable next test path, but it is **CONDITIONALLY READY**, not production-ready and not yet operationally verified in this environment.

A future authorized phase should start one explicitly isolated native stack outside the tracked repository, pin the CLI version, preserve Auth and REST, run only synthetic data tests, verify the public projections through local PostgREST, inspect local role/default-privilege behavior, and destroy the stack afterward. Until that phase is separately authorized, no stack should be started and no repository or hosted Supabase changes should be made.

## References

[1]: https://supabase.com/docs/guides/local-development/docker-and-native-runtimes "Docker and native runtimes"
[2]: https://supabase.com/features/native-local-runtime "Native runtime for local development"
[3]: https://supabase.com/blog/local-supabase-project-per-agent-with-or-without-docker "A local Supabase project per agent, with or without Docker"
[4]: https://supabase.com/docs/guides/local-development/cli/getting-started "Supabase CLI"
[5]: https://github.com/supabase/cli/releases/tag/v3.0.0 "Supabase CLI v3.0.0 release"
