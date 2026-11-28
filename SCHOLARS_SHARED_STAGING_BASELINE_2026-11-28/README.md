# SCHOLARS shared staging baseline qualification

**Status: reviewed packet — not executed; approval required before any staging DDL.**

Date: 2026-11-28. Target staging ref: `aqhktriwaglvvrchxmtd` (`scholars-staging`). Production ref inspected read-only: `cmdglabohpttgfofcmqc` (`scholarship-platform`).

## Verified provenance

The two requested open pull requests are in [`ImperioKDB/Scholars`](https://github.com/ImperioKDB/Scholars):

- PR #50, deadline notification system, verified commit [`bceeefb8517b99104a9ecb1d8930b2a12c4ea35b`](https://github.com/ImperioKDB/Scholars/commit/bceeefb8517b99104a9ecb1d8930b2a12c4ea35b).
- PR #51, durable admin broadcast execution, verified commit [`bf27021d7a35f5fc032f78463e6bee6a22c2f37c`](https://github.com/ImperioKDB/Scholars/commit/bf27021d7a35f5fc032f78463e6bee6a22c2f37c).

The exact SQL from those commits is preserved under `pinned-pr-sql/`; SHA-256 values are recorded in `SHA256SUMS`.

## Inventory and read-only evidence

The Supabase inventory calls found the staging project active and healthy, with only the managed Auth-side inventory and one applied migration (`20261125152047 create_better_auth_private_schema`). No public application tables, deadline objects, broadcast objects, or Edge Functions were present. The staging database therefore cannot accept either PR migration by itself.

Production read-only inspection found the shared application objects already present, including `profiles`, `scholarships`, `opportunities`, `applications`, `saved_scholarships`, `saved_opportunities`, `notifications`, `notification_deliveries`, `workflow_jobs`, `push_tokens`, `web_push_subscriptions`, `announcement_log`, and `broadcast_delivery_log`. It also confirmed the production deadline and broadcast function families, indexes, RLS-enabled private ledgers, service-role function grants, and the required `pgcrypto`, `uuid-ossp`, `pg_stat_statements`, and `plpgsql` extensions. No production rows or secrets are included in this packet.

Production contains application records and must never be used as a staging data source. The schema-extraction repository remains on HOLD because its current workflow does not enforce a provider- or role-enforced read-only source. This packet therefore does **not** run that workflow or request a database credential. An owner-approved schema-only baseline must be supplied separately after endpoint, role, TLS, and privilege verification.

## Shared dependency inventory

The dependency closure for both PR migrations is:

1. Managed prerequisites: `auth.users`, `auth.identities`, `pgcrypto`/`gen_random_uuid()`, and the existing Supabase migration bookkeeping.
2. Student/catalog foundation: `public.profiles`, `scholarships`, `opportunities`, `applications`, `saved_scholarships`, `saved_opportunities`, and the application enum types used by existing rows.
3. Notification foundation: `notifications`, `notification_deliveries`, the notification type enum, existing delivery constraints and indexes, and the service-role claim function.
4. Execution foundation: `workflow_jobs` with its lease/idempotency/correlation columns, plus `announcement_log` and `broadcast_delivery_log` for historical projections.
5. Device/audience foundation: `push_tokens`, `web_push_subscriptions`, profile-to-auth foreign keys, and the email identity lookup in `auth.users`.
6. PR #50 additions: profile channel flags; `opportunity_id`, `deadline_date`, and `deadline_stage` on `notification_deliveries`; `deadline_email_attempts`; `deadline_reminder_run`; the `deadline_tracked_listings` security-invoker view; deadline stage/prepare/claim/backlog/stats functions; indexes; RLS; and service-role-only execution grants.
7. PR #51 additions: locked `broadcast_private` schema; campaign/submission/target/provider-window/provider-state tables; RLS and service-role-only grants; broadcast indexes on `workflow_jobs`; private helper functions; public broadcast RPCs; and the public broadcast job/target state machine.

No production scheduled jobs, Edge Functions, provider allocations, API keys, webhook URLs, email credentials, push credentials, or rows are part of the baseline.

## Duplicate legacy migration versions

The source directory contains duplicate numeric prefixes (for example `0015`, `0021`, `0023`, `0034`, `0035`, `0045`, `0046`, `0052`, `0057`, `0061`, `0062`, `0063`, `0078`, `0087`, `0102`, and `0103`). Numeric filename ordering is not an authoritative applied order. The baseline must be reconstructed from the production catalog plus an explicit, reviewed dependency manifest; it must not blindly replay `supabase/migrations/`. The two PR migrations are applied exactly once, in dependency order, after the approved schema-only foundation.

## Procedure (approval gate)

1. Review this directory, the six pinned SQL/test files, and `SHA256SUMS`.
2. Produce or approve a schema-only foundational SQL artifact from a provider-enforced read-only source. Exclude `auth`, `storage`, extension-managed schemas, all `COPY`/`INSERT`/`UPDATE`/`DELETE` statements, secrets, integration configuration, cron jobs, and external destinations. Preserve DDL for types, tables, sequences, defaults, foreign keys, checks, indexes, triggers, functions, RLS, grants, and required extensions.
3. Run `00_preflight.sql` against staging and require: expected ref/endpoint; no public application objects; only the known managed migration; required extensions available; and zero rows from the cron/integration checks.
4. Obtain explicit approval of the exact schema-only artifact hash and target. Only then run `00_initialization.sql` transactionally with `ON_ERROR_STOP=1`, passing `target_ref=aqhktriwaglvvrchxmtd` and the absolute path to the approved foundation.
5. Run structural assertions and `tests/broadcast_staging_preflight.sql`. Do not start cron, Workers, Edge Functions, provider clients, or real notification paths.
6. Run the deadline window and broadcast window separately, never concurrently. Capture only synthetic IDs/statuses and before/after schema fingerprints.

The initialization wrapper refuses any non-empty public schema and will not run with an omitted target or omitted foundational artifact. It does not import records.

## Separate synthetic testing windows

**Window D — deadline only.** Use one synthetic user, one synthetic confirmed email, one synthetic profile with deadline flags, one synthetic push token, and two synthetic saved listings at distinct stages. Run `prepare_deadline_reminders` and claim email/push through the supplied compatibility test. Assert that only `deadline_reminder_v2` rows are created and that all broadcast tables, legacy broadcast rows, and broadcast jobs are byte-for-byte unchanged. Roll back the fixture transaction and verify zero synthetic rows remain.

**Window B — broadcast only.** After Window D has rolled back and the staging baseline is clean, use only the supplied `.invalid` email addresses and synthetic Expo/Web Push endpoints in `tests/broadcast_staging_fixtures.sql`. Run `tests/broadcast_staging_preflight.sql`, then the PR #51 qualification scripts with provider allocations set to zero or held. Do not configure Brevo, Resend, Expo, web push, Mailtrap, cron, Workers, or webhooks. Assert no network dispatch, no real recipient, no production URL, and no non-synthetic target. Roll back all fixtures and verify zero qualification rows remain.

The cross-compatibility SQL is a separate final check and must run only after both isolated windows have passed. It verifies deadline claims do not mutate broadcast records or enroll broadcast listings in deadline reminders.

## Non-destructive rollback

Before execution, rollback is simply to stop: nothing in staging has been changed. During initialization, any error triggers transaction rollback through `ON_ERROR_STOP=1`; do not use `--single-transaction` with external scripts that swallow errors. If the approved baseline is wrong, discard the staging project or restore from a pre-initialization snapshot rather than issuing ad-hoc `DROP` statements. For fixture tests, use transaction-scoped fixtures and `ROLLBACK`; never delete by broad predicates in a shared environment. Do not attempt to roll back production, and do not apply this packet to production.

## Files

- `00_preflight.sql` — read-only target and safety checks.
- `00_initialization.sql` — fail-closed transactional initializer; not executed.
- `pinned-pr-sql/` — exact SQL from the two verified commits.
- `tests/` — supplied compatibility, staging-preflight, and synthetic fixture SQL.
- `SHA256SUMS` — integrity record for the packet SQL.
