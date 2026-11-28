# Disposable validation evidence

Date: 2026-11-28

## Scope

The validation was performed against a disposable local PostgreSQL 16 database. No production or hosted staging write was performed. The local database used mocked Supabase prerequisites only: `auth.users`, `auth.identities`, `auth.uid()`, `auth.role()`, `supabase_migrations.schema_migrations`, and an empty `cron.job` catalog. The mock Auth table included `email_confirmed_at`, which is read by the pinned deadline migration.

The exact pinned SQL files were copied unchanged into the temporary validation directory and executed only after `01_foundational_schema.sql`. The temporary validator copy of `00_initialization.sql` changed only the expected endpoint string from the real staging host to the local Unix-socket host so the local connection could exercise the complete DDL sequence. The repository initializer itself was also run once unchanged against the local socket and correctly failed closed with:

```text
ERROR: refusing unexpected connection host: /var/run/postgresql
```

## Commands and results

The validator was created with PostgreSQL 16 from the Ubuntu package repository, then the following sequence was run from the packet directory:

```sh
sudo pg_ctlcluster 16 main start
# create disposable scholars_validation database and mocked Auth/migration/cron prerequisites
# copy foundation and the two pinned SQL files to /tmp/scholars-validation/
sed 's/db\.aqhktriwaglvvrchxmtd\.supabase\.co/\/var\/run\/postgresql/g' \
  SCHOLARS_SHARED_STAGING_BASELINE_2026-11-28/00_initialization.sql \
  > /tmp/scholars-validation/00_initialization.sql
sudo -u postgres psql -v ON_ERROR_STOP=1 \
  -f /tmp/scholars-validation/00_initialization.sql \
  -v target_ref=aqhktriwaglvvrchxmtd \
  -v schema_only_baseline=/tmp/scholars-validation/01_foundational_schema.sql \
  scholars_validation
```

Result: **PASS**. The outer transaction completed and printed `Baseline initialized transactionally.` The post-DDL checks returned:

```text
profiles | deadline | broadcast | tracked_view | private_schema
---------+----------+-----------+--------------+---------------
t        | t        | t          | t            | t

public_object_count: 24
profile_rows: 0
```

The 24 public catalog objects include tables, indexes/sequences, the deadline view, and the broadcast-private schema objects expected after the pinned migrations. No rows were imported or seeded.

The scheduled-job fail-closed check was then exercised by inserting one synthetic row into the disposable `cron.job` table before initialization. Result: **PASS**. The initializer returned exit code 3 with `ERROR: refusing database with scheduled jobs`, and the post-failure public object count was `0`, proving no partial DDL committed.

## Static safety checks

`git diff --check` passed. The foundational file contains no transaction-control statement, seed/data statement, cron creation, webhook destination, API key, provider allocation, or secret. The following PR-owned objects were confirmed absent from the foundation and present only in the pinned files:

- `deadline_email_attempts`
- `deadline_reminder_run`
- `deadline_tracked_listings`
- `broadcast_campaigns`
- `broadcast_submissions`
- `broadcast_targets`
- `broadcast_provider_windows`
- `broadcast_provider_state`

The foundation contains the pre-existing `claim_notification_delivery` function because PR #50 replaces it with `CREATE OR REPLACE FUNCTION`; it does not contain the PR #50 deadline columns or the PR #51 broadcast tables.

## Limitations and permission result

No indispensable schema definition was blocked by the available read-only metadata connection. The foundation was reconstructed from the production catalog inventory and verified repository DDL. The local validator did not attempt to reproduce Supabase-managed Auth internals, extension-owned schemas, or production data; those remain managed prerequisites and are checked by the initializer/preflight rather than recreated.

Hosted staging execution was intentionally **not performed**.
