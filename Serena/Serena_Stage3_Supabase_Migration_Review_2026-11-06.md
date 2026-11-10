# Serena Recovery Engine — Stage 3 Supabase Migration Review

**Review time:** 2026-11-06, approximately 14:10–14:14 CET  
**Stage:** 3 — Review the production Supabase migration  
**Verdict:** **PASS WITH CONDITIONS — SQL reviewed, but production migration synchronization and backend-role identity are unresolved. Do not apply yet.**

## Scope and evidence

Target file: `supabase/migrations/20261103090000_research_analysis_attempts.sql` from the supplied `Serena_Recovery_Engine_COMPLETE.patch`. Its SHA-256 was recomputed from the patch and matches the supplied checksum manifest: `3a39b15c898afdac156de31c39ec4bab4ee8f20e79922701c79408a09e4e16fe`. The complete patch SHA-256 also matches the manifest: `563c58a0e21c139734ee5c2935c26899d99f89552713474bb3e52b96748346f5`.

The production target is Supabase project **`serena`**, ref **`nmlhcofasxsngmvjjxti`**, region **`eu-west-1`**. Supabase reports it `ACTIVE_HEALTHY` on PostgreSQL **17.11.0.003**. Production migration history lists five prior Serena migrations but does not list target version `20261103090000`; the live catalog also confirms `public.research_analysis_attempts` is absent. No production DDL or DML was run.

The shared project folder has the complete patch and manifest, but the manifest-referenced checkout `/home/ubuntu/review/serena-checkout` does not exist in this environment. The claimed recovery commit `97ed7b913659d05b920da89477020e822484c671` was not found in the current GitHub remote. The current remote `main` remains at baseline `6bb268b216b6250e4ae64b73b9f6c2a85f31e686`. Therefore this is a source-artifact review, not a review of a currently reachable release branch.

## What the migration does

It adds one table, `public.research_analysis_attempts`, without inserting, updating, or deleting application data and without altering existing tables.

The table stores a UUID primary key; `task_id` and `owner_id`; per-task `attempt_number`; status (`queued`, `running`, `completed`, `failed`, or `cancelled`); optional provider/model and idempotency key; start/completion timestamps and duration; optional failure kind, HTTP status, error code, retry count, and finding count; and a required evidence-passage count. `id` defaults to `gen_random_uuid()`. `started_at` and `created_at` default to `now()`; the other values are supplied by application code or nullable.

Checks require positive attempt numbers, nonnegative duration/retry/evidence/finding counts, and a nullable status code between 400 and 599. The primary key enforces unique attempt IDs. `UNIQUE (task_id, attempt_number)` prevents duplicate numbering within a task. `UNIQUE (task_id, idempotency_key)` prevents reuse of a non-null idempotency key for the same task; PostgreSQL permits multiple `NULL` keys under ordinary unique semantics [2]. Foreign keys point to `research_tasks(id)` and `auth.users(id)`, both with `ON DELETE CASCADE`, so task deletion or auth-user deletion cascades to attempt history.

Three additional indexes support task history ordered by creation time, owner/task history, and the active-attempt invariant. The partial unique index on `task_id WHERE status IN ('queued','running')` enforces at most one active attempt per task. No trigger, explicit grant/revoke, RLS policy, backfill, or other data operation is included. The migration enables RLS on the new table.

## Production compatibility, ownership, and security

PostgreSQL 17.11.0.003 supports the constructs used. The referenced production relations and columns exist: `public.research_tasks(id, owner_id)` and `auth.users(id)`. Production catalog metadata confirms `research_tasks.owner_id` references `auth.users(id)` with `ON DELETE CASCADE`; production source/evidence foreign keys also cascade from their parent task/source.

The new migration’s two foreign keys do **not** make `(task_id, owner_id)` a database-enforced matching pair. They independently prove that the task and owner exist. The supplied repository code provides the additional application boundary: `createAnalysisAttempt` selects from `research_tasks` with both `task.id = taskId` and `task.owner_id = ownerId`, and history reads filter by owner and task. This invariant is therefore enforced by the privileged API path, not by a composite FK. A privileged direct writer could otherwise pair a task with another valid user’s ID.

The Supabase MCP SQL session reports `current_user = session_user = postgres`; this is an administrative inspection session and does **not** establish the role used by Vercel’s `DATABASE_URL`. Role attributes in production show `service_role` has `BYPASSRLS`, while `anon` and `authenticated` do not. Existing public research tables have RLS enabled and no policies. Project default ACLs grant normal table privileges to `anon`, `authenticated`, and `service_role` for new public tables. Since the proposed migration only enables RLS and creates no policies, row access by `anon`/`authenticated` remains denied by PostgreSQL’s default-deny RLS behavior [3]; `service_role` bypasses RLS and receives table privileges. However, the migration does not explicitly revoke client-role table privileges. For defense in depth and to match the stated intent that clients cannot access attempt history, add explicit revocations from `PUBLIC`, `anon`, and `authenticated` before applying, or document why relying solely on no-policy RLS is accepted. Do not add client policies.

The actual backend connection role remains **unverified** because the environment value was not inspected and the Supabase MCP role is not equivalent evidence. Confirm only the database username/role, without displaying a connection string or password, using an approved safe mechanism before applying. This is necessary to ensure the server-side role can write/read the table and that least privilege is preserved.

## Idempotency, locks, and failure behavior

The migration is additive and does not rewrite or scan the existing research tables. On a fresh apply, it creates a new empty relation and builds indexes on that relation, so expected data-lock impact is low. Foreign-key metadata operations still take brief locks; no large existing table is altered. There is no migration-time backfill.

`IF NOT EXISTS` makes the table/index creation tolerant of objects with the same names, but it does not verify those objects have the intended columns or definitions. A same-named but divergent existing table or index could be silently accepted at that statement and fail later or leave incorrect semantics. RLS enabling is repeatable. The file contains no explicit transaction wrapper, so confirm the approved migration runner’s failure/transaction behavior and inspect schema/history after any error. If a statement fails, stop; do not rerun or manually apply fragments.

The unique constraints and partial index implement the intended key and one-active-attempt invariants. On race conditions, the application catches PostgreSQL `23505` and queries the existing active/idempotent attempt; this behavior is in the exported persistence patch, not independently tested here.

## Migration-history mismatch — blocking issue

The production ledger contains these version/name pairs: `20261011185158/initial_research_tasks`, `20261012112654/research_sources_evidence`, `20261012113049/enable_rls_on_research_tables`, `20261012195728/request_admission_limits`, and `20261012212648/research_task_owner`. The current remote repository’s migration directory has the same names but different version prefixes: `20261011195000`, `20261012122500`, `20261012123000`, `20261012204800`, and `20261012222000` respectively. Version IDs are not an exact match.

Supabase documents that `db push` compares local migration versions with `supabase_migrations.schema_migrations` and applies files it considers unapplied. It also warns that a mismatched local/remote history can cause synchronization errors; `migration repair` changes history records but does not execute SQL. [Supabase migration deployment guidance](https://supabase.com/docs/guides/deployment/database-migrations)

Do **not** run `db push` or `migration repair` until a read-only status/dry-run in a restored, exact release checkout establishes that only the intended target migration is pending. Otherwise previously applied schema migrations may be misclassified as unapplied. The absent recovery commit and missing checkout mean that exact release checkout is not presently available here.

## Preflight and apply plan (not authorization to apply)

1. Restore the reviewed recovery patch to a dedicated release branch or pull request based on the verified baseline, and confirm the migration file is tracked at exactly the path above with the checksum stated here. Do not push or deploy in this stage.
2. In that exact checkout, run the Supabase migration status comparison (`supabase migration list --remote`) and a non-applying `supabase db push --dry-run --remote`. The plan must show only `20261103090000_research_analysis_attempts` as pending. If older local/remote version IDs still diverge, stop and propose a separately reviewed history reconciliation; do not repair production history automatically.
3. Confirm the active backend database role safely, compare its effective privileges with the table’s default ACL and RLS plan, and settle whether the migration should explicitly revoke `PUBLIC`, `anon`, and `authenticated` privileges.
4. Recheck the production migration ledger and table absence immediately before a separately approved application. Present the exact file path, checksum, project ref, migration-history findings, grants/RLS effect, and rollback plan for explicit approval.
5. Only after approval, apply once through the tracked Supabase migration workflow and approved integration. Capture execution output and the resulting ledger row. On any error or unexpected difference, stop and report; do not retry or hand-edit production.

## Post-apply verification plan

Use read-only catalog queries to verify: the table exists; exact column types, nullability, defaults and checks; primary/unique constraints and both cascading FKs; the three named indexes and their predicates; `relrowsecurity = true`; no RLS policies exist; intended table privileges for `anon`, `authenticated`, `service_role`, and the confirmed backend role; the backend role’s required table access; and the single expected migration version in `supabase_migrations.schema_migrations`. Confirm no unrelated schema objects changed. No production test row is needed for these checks.

Useful queries (run only after approved application, each with a bounded result):

```sql
select column_name, data_type, is_nullable, column_default
from information_schema.columns
where table_schema = 'public' and table_name = 'research_analysis_attempts'
order by ordinal_position limit 50;

select conname, contype, pg_get_constraintdef(oid) as definition
from pg_constraint
where conrelid = 'public.research_analysis_attempts'::regclass
order by conname limit 50;

select indexname, indexdef
from pg_indexes
where schemaname = 'public' and tablename = 'research_analysis_attempts'
order by indexname limit 50;

select c.relrowsecurity, c.relforcerowsecurity
from pg_class c
where c.oid = 'public.research_analysis_attempts'::regclass limit 1;

select schemaname, tablename, policyname, roles, cmd, qual, with_check
from pg_policies
where schemaname = 'public' and tablename = 'research_analysis_attempts' limit 50;
```

## Rollback and forward-fix

Before the analysis code writes attempts, the migration is additive and contains no existing-row transformations. A rollback by dropping the table would nevertheless remove attempt history if any rows were written, so do not prepare or execute a destructive rollback without a separate approval and verified backup. Prefer a forward-fix migration for schema defects. If the first application fails, inspect catalog state and migration history before any corrective action; never rerun blindly. The normal operational rollback for the application is to keep the endpoint disabled or roll application code back while retaining the additive table.

## Checks, changes, and remaining work

**Checks run:** Supabase project/migration listing; verbose public-table inventory; bounded SQL reads of current role, grants, RLS policies, FK delete actions, role attributes, default ACLs, and target-table existence; GitHub read-only inspection of current `main` migration files and prior migration source; static inspection of the supplied patch; SHA-256 comparison with its manifest; official Supabase migration guidance.

**Tests run:** None. This was a read-only production/source review. The recovery commit is not available in the current remote and no working checkout exists here, so the exported test suite was not executable from this environment. Do not infer test success from the older manifest.

**Changed:** None. No production schema, rows, migration history, grants, policies, repository, branches, environment variables, or deployments were changed.

**Risks / gates:** Migration history version drift must be reconciled or proven safe before any tracked push. The backend role must be established. Decide whether explicit client-role revokes are needed. Recovery code is an uncommitted/exported artifact in this environment. The recovery implementation’s success/failure finalization updates the attempt, task result, and lifecycle events through separate repository calls rather than one visible database transaction; that does not meet the roadmap’s later atomic-finalization release criterion and should be corrected or explicitly resolved before release. The repository also calls for a decision on separately loaded task/source/evidence snapshots.

**Next action requiring owner input:** Review this report and, if you want to proceed, authorize only the exact Stage 4 migration application after the migration-history mismatch, backend role, and client-grant question are resolved. This report itself is not approval to change production. Stage 5 review preparation may be performed separately; push/merge/deploy and live-task validation require their own exact approvals.

## References

[1]: https://supabase.com/docs/guides/deployment/database-migrations "Supabase database migrations and deployment"
[2]: https://www.postgresql.org/docs/17/ddl-constraints.html "PostgreSQL 17 constraints"
[3]: https://www.postgresql.org/docs/17/ddl-rowsecurity.html "PostgreSQL 17 row security policies"
