# Disposable validation evidence

Date 2026-11-28

## Staging inventory and scope

Independent hosted inspection supplied for this correction found zero public application objects, zero Auth users, zero Auth identities, and no `cron.job` catalog. This was sufficient for the correction. All database execution reported below used disposable local PostgreSQL. No hosted inspection was needed for this run.

The tests ran with native PostgreSQL 17.12 binaries on Debian, using a private Unix socket and TCP disabled. The fixture models managed Auth tables, the `auth.uid()` JWT lookup, the separate Auth owner, migration history, and optional cron metadata. Auth email is `varchar(255)`. The legacy grant fixture automatically grants table, sequence, and function access in `public` to `anon`, `authenticated`, and `service_role`. The opt-in fixture omits those automatic API-role grants.

## Local results

| Default grants | Cron catalog | Preflight | Initialization, role access and SQL smoke tests |
| --- | --- | --- | --- |
| Legacy Supabase defaults | Absent | `absent\|0` | Passed |
| Legacy Supabase defaults | Present, empty | `present\|0` | Passed |
| Opt-in grants | Absent | `absent\|0` | Passed |
| Opt-in grants | Present, empty | `present\|0` | Passed |

- An unchanged initializer refused the local endpoint. The harness then adapted the hostname guard in a temporary initializer copy to use the private socket. The checked-in guard still requires the staging host and ref.
- An inactive synthetic job appeared in preflight as `present\|1`. The initializer refused the database before any public relation was created.
- Every application table created by the packet had RLS. Both pinned migrations loaded after the foundation in all four successful cases.
- The Auth trigger created ordinary profiles, including when user-editable metadata supplied an admin flag. The role checks and synthetic deadline claims rolled back. The broadcast preflight passed on the empty state after rollback.

## Access behavior

| Role | Verified behavior |
| --- | --- |
| `anon` | Reads verified catalog rows in the preview projection. Drafts, opportunity research notes, profiles, scholarship rules, catalog writes and `is_admin` execution are denied. |
| `authenticated` student | Reads own profile and verified opportunities. Own-profile insert and upsert work, including a pinned deadline preference. Cross-profile writes, changing the profile ID, privileged fields, opportunity writes and private worker access are denied. Inbox updates can change only the owner's `read_at`. |
| `authenticated` administrator | `is_admin` evaluates successfully through RLS, enabling reads of other profiles and CRUD on draft opportunities. The profile column restrictions still apply. |
| `service_role` | Has explicit foundation DML and can store a delivery outcome and call both pinned worker APIs. Broadcast administration checks still reject a non-admin UUID. Direct deadline-internal and excess broadcast privileges are absent under both grant models. |

Both deadline claim paths processed synthetic due rows in the combined schema. The service role received the synthetic confirmed address for email and a null email for push. The supplied compatibility SQL confirmed the broadcast snapshot stayed unchanged during those claims.

The packet models the two notification workflows and their shared dependencies. The browser grant intentionally reserves `community_role` changes for a trusted database path. The app's separate member-role administration route uses a signed-in client and is outside this qualification. The local fixture checks PostgreSQL role behavior with simulated JWT claims. Hosted Auth, PostgREST and pg_cron runtime behavior remain outside the evidence.

## Reproduction and integrity

Run from the packet directory as an unprivileged local OS user with native PostgreSQL server and client binaries and the bundled `pgcrypto`, `uuid-ossp`, and `pg_stat_statements` extension files.

```sh
PG_BIN=/path/to/postgresql/bin bash tests/test-foundation.sh
```

From the repository root:

```sh
sha256sum -c SCHOLARS_SHARED_STAGING_BASELINE_2026-11-28/SHA256SUMS
git diff --check 19026a9f4c6e35ae4fa1f014919e219f193934a7
git diff --exit-code 19026a9f4c6e35ae4fa1f014919e219f193934a7 -- \
  SCHOLARS_SHARED_STAGING_BASELINE_2026-11-28/pinned-pr-sql
```

The hashes of the two pinned migration files match both the starting packet and their original Scholars commits. The foundation remains schema-only. Hosted execution remains subject to the approval gate in the [packet runbook](README.md).
