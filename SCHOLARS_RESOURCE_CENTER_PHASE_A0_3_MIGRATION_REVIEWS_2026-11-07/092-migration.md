# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0075_flag_expired_opportunities.sql`

This review is based exclusively on the specified migration file. No other migration, source file, database, hosted service, or SQL execution was inspected or used.

# Scope

The migration introduces the database-side support for flagging verified opportunities whose deadlines have passed and for notifying every administrator once per opportunity. The file contains three schema/data-definition changes, one stored procedure definition, and function privilege changes:

1. Add a value to `public.notification_type`.
2. Add a nullable timestamp column to `public.opportunities`.
3. Add a partial index on opportunity deadlines.
4. Create or replace `public.flag_expired_opportunities()`.
5. Revoke broad function execution and grant execution to `service_role`.

The opening comments state that a Vercel cron route calls the function daily, but this migration itself does not create or configure that route.

# Objects and mutations

## Enum alteration

Lines 4–5 execute:

```sql
ALTER TYPE public.notification_type
  ADD VALUE IF NOT EXISTS 'opportunity_deadline_passed';
```

This alters the existing `public.notification_type` enum by adding the literal `opportunity_deadline_passed`, using `IF NOT EXISTS` for migration-level idempotency. It does not remove or rename any enum value. The enum value is later required for casts in the function body.

## Table alteration

Lines 7–8 add this column to `public.opportunities` if it is absent:

```sql
deadline_passed_at timestamptz
```

The column is nullable and has no default, check constraint, foreign key, or explicit ownership/grant change in this file. The function populates it with `now()` when it first flags an eligible opportunity and also updates the existing `updated_at` column.

## Index creation

Lines 10–12 create, if absent, `public.idx_opportunities_deadline_passed` on `(deadline, deadline_passed_at)` with the predicate:

```sql
verified = true AND deadline IS NOT NULL
```

This is a partial index intended to support the function's candidate scan. It does not include `deadline_passed_at IS NULL` in the predicate, so already-flagged rows remain indexed when they satisfy the stated predicate. The index has no explicit concurrent option and therefore is a normal index build.

## Function definition and row mutations

Lines 14–67 create or replace `public.flag_expired_opportunities()` with return type `TABLE (flagged_count integer, notification_count integer)`. It is a `plpgsql` function marked `SECURITY DEFINER` and fixes its execution search path to `public`.

The function uses one statement with two common-table expressions:

- `flagged` updates `public.opportunities` where `verified = true`, `deadline IS NOT NULL`, `deadline < CURRENT_DATE`, and `deadline_passed_at IS NULL`. It sets `deadline_passed_at = now()` and `updated_at = now()`, returning `id`, `title`, `provider_name`, `deadline`, and `slug`.
- `inserted` inserts into `public.notifications` one row for every administrator profile (`public.profiles.is_admin = true`) crossed with each row returned by `flagged`, except when a matching notification already exists for the same `profile_id`, `opportunity_id`, and enum `type`. The inserted notification type is `opportunity_deadline_passed`; metadata contains the opportunity id, title, provider name, deadline, and slug. Inserted notification ids are returned only for counting.

The function returns the number of rows in `flagged` and the number of rows in `inserted`. It does not explicitly issue `COMMIT`; the updates and inserts are part of the caller's transaction. If the statement or transaction fails, the related mutations are rolled back normally.

## Privilege mutations

Lines 69–70 execute:

```sql
REVOKE ALL ON FUNCTION public.flag_expired_opportunities() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.flag_expired_opportunities() TO service_role;
```

This removes default/public execution privileges and grants execution to the `service_role` role. The file does not revoke privileges from any other role, alter table privileges, or grant access to anon/authenticated users.

# Dependencies

The following dependencies are directly visible or necessarily implied by the SQL. Their existence and exact definitions were not independently verified because the audit is restricted to this one file.

- An existing enum type `public.notification_type` that can be altered and used in casts. The enum must not already make the function's literal invalid; the `ADD VALUE IF NOT EXISTS` clause handles only the value's presence, not the type's absence.
- An existing table `public.opportunities` with at least `id`, `title`, `provider_name`, `deadline`, `slug`, `verified`, and `updated_at` columns. `deadline` must be compatible with comparison to `CURRENT_DATE` and with the `timestamptz`/JSON metadata usage; `updated_at` must be writable.
- An existing table `public.notifications` with writable columns `profile_id`, `opportunity_id`, `type`, and `metadata`, plus an `id` column because the insert uses `RETURNING id`. Its constraints and indexes must permit the inserted administrator/opportunity notification rows.
- An existing table `public.profiles` with `id` and `is_admin`, where `is_admin` is comparable to `true`.
- The `plpgsql` language, normally installed by default in PostgreSQL/Supabase but not created by this file.
- The `service_role` database role. The privilege grant fails if that role is absent.
- The `jsonb_build_object` built-in function and standard PostgreSQL `now()`, `CURRENT_DATE`, CTE, `UPDATE ... RETURNING`, and `INSERT ... RETURNING` behavior.
- A caller/integration outside the file, described only in the comment as a Vercel cron route, that invokes the function daily using a role with `EXECUTE` on the function, normally `service_role`. No cron scheduling or HTTP integration is defined here.

Potential ordering constraints are significant: the enum value must exist before the function body is parsed/used; the `deadline_passed_at` column must exist before function creation; and the referenced tables and columns must exist before the function is created. In a normal migration sequence, the enum, column, and referenced base tables must therefore precede this migration. The index can be created after the column and table exist, before or after the function definition.

# Data/external-side-effect assessment

This file contains no seed rows, literal user records, or precomputed real-world data. It does contain a semantic event label (`opportunity_deadline_passed`) and runtime-generated notification metadata derived from live table rows.

It contains no external URLs. The phrase “Vercel cron route” is a comment-only integration reference; no URL, HTTP request, webhook, or network call is present. The function performs database-side runtime writes: it updates eligible opportunities and inserts notifications for administrators. These are real data mutations when the function is invoked, even though migration application itself only defines the function and schema objects.

The operation is designed to be repeatable for already-flagged opportunities because `deadline_passed_at IS NULL` gates the update and the notification insert has a matching `NOT EXISTS` check. However, the intended “once” behavior depends on the notification table's constraints and concurrent execution behavior. Two concurrent invocations could potentially race between the `NOT EXISTS` check and insert unless an appropriate unique constraint exists; no such constraint is created here. The update CTE also only returns rows newly flagged by that invocation.

The deadline comparison is `deadline < CURRENT_DATE`, not a timestamp comparison against the current instant. Exact behavior therefore depends on the `deadline` column type and PostgreSQL's date coercion/time-zone semantics. Opportunities due later on the current calendar date are not flagged by this predicate.

# Security/ordering implications

`SECURITY DEFINER` means the function runs with the privileges of its owner rather than the invoking role. The explicit `SET search_path = public` reduces object-resolution risk from attacker-controlled schemas, and all referenced application objects are schema-qualified. Nevertheless, the owner must have the required update/insert/select privileges, and ownership/role configuration is external to this file. A secure owner role and controlled function ownership remain important.

The explicit `REVOKE ALL ... FROM PUBLIC` prevents arbitrary public invocation through the default function privilege. Execution is granted only to `service_role`, which is normally a highly privileged Supabase backend role and must not be exposed to untrusted clients. The file does not grant execution to `authenticated` or `anon`.

The function can write notifications for every administrator profile and update all matching verified opportunities in one call. It should therefore be called only by a trusted backend scheduler and monitored for transaction size and lock duration. The cross join means notification volume is approximately eligible opportunities multiplied by administrator profiles, subject to duplicate suppression.

The migration is not safe to execute blindly in an arbitrary or incomplete local schema: missing enum/table/column/role dependencies, incompatible constraints, or an unsuitable function owner can cause failure or unsafe privilege behavior. Within a correctly ordered Supabase schema with those prerequisites present, the DDL is guarded in several places (`IF NOT EXISTS`, `CREATE OR REPLACE`, and repeatable row predicates), but the normal index build and enum alteration still have deployment/locking considerations.

# Reconstruction recommendation

For a synthetic local schema reconstruction, this migration may be omitted if the goal is only to reproduce static/base table shape and the reconstruction does not exercise deadline processing, notification generation, or the application path that calls this function. It is not safe to omit if compatibility includes the `deadline_passed_at` column, the `opportunity_deadline_passed` enum value, the partial index, the backend function, or the associated notification behavior.

Recommended classification: **conditionally omittable**. Preserve the column and enum value when reconstructing the data model consumed by application code; preserve the function and privilege policy when reconstructing backend behavior or security boundaries. If omitted, document that expired-opportunity flagging and admin notifications are intentionally out of scope rather than silently treating the local schema as behaviorally equivalent.

# Verdict

**PARTIALLY VERIFIED — NOT SAFE TO EXECUTE BLINDLY.** The migration's mutations and visible dependencies are clear from the inspected file, and there are no external URLs or static real-data inserts. It is plausibly valid in the intended, correctly ordered Supabase schema, but this single-file, strictly read-only audit cannot verify the prerequisite enum, tables, columns, language, role, constraints, function owner, or external cron caller. Therefore it should not receive an unconditional PASS for execution. For a minimal synthetic schema, it is conditionally safe to omit only when deadline-expiry processing and its notification contract are explicitly outside scope.
