# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0078_scope_provider_analytics_to_reporting_window.sql`

# Scope

This review covers only migration `0078_scope_provider_analytics_to_reporting_window.sql`. The file contains one `CREATE OR REPLACE FUNCTION` statement and two privilege statements. It changes the implementation and privileges of `public.get_provider_analytics(timestamptz, timestamptz, uuid)` so that provider analytics are calculated against an explicit reporting window and, optionally, one scholarship.

No SQL was executed, no Supabase instance or hosted service was contacted, and the source snapshot was not modified. The assessment is therefore source-based; runtime behavior, catalog state, and installation success are not independently verified.

# Objects and mutations

## Function creation/replacement

Lines 2–112 create or replace the following function:

```sql
public.get_provider_analytics(
  p_since timestamptz default now() - interval '30 days',
  p_until timestamptz default now(),
  p_scholarship_id uuid default null
) returns jsonb
```

The function is written in `plpgsql`, is marked `SECURITY DEFINER`, and sets `search_path = public`. It first checks `public.is_admin(auth.uid())` and raises `Admin access required` unless the caller's authenticated user is an administrator.

The function reads and aggregates, without changing, data from:

- `public.profiles`: signup cohort, profile completeness, demographics, attribution fields, and creation timestamps.
- `public.events`: activity days, activation, retention, match views, provider clicks, and overall activity.
- `public.applications`: acquisition applications, scholarship application starts, provider-click linkage, and outcome statuses.
- `public.saved_scholarships`: scholarship saves.
- `public.scholarships`: scholarship identity, title, provider name, and funnel rows.

It returns one JSONB document containing `window`, `growth`, `activation`, `retention`, `demographics`, `acquisition`, and `scholarship_funnel` sections. The scholarship funnel is capped at 200 rows and can be narrowed using `p_scholarship_id`.

The function does not contain `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, DDL beyond its own definition, sequence changes, or transaction-control statements. The apparent `count`, joins, and JSON construction are read-only queries. It does not create tables, views, types, indexes, triggers, policies, extensions, or roles.

## Privilege mutations

- Line 114: `REVOKE ALL` on the exact three-argument function from `public`.
- Line 115: `GRANT EXECUTE` on the exact three-argument function to `authenticated`.

These are access-control changes only. They do not grant table-level access, alter row-level security policies, or modify data. The effective application-level restriction remains the `public.is_admin(auth.uid())` check inside the security-definer function.

# Dependencies

The migration depends on the following earlier schema objects and runtime context:

- The `public` schema.
- The exact function identity `public.get_provider_analytics(timestamptz, timestamptz, uuid)` for replacement and privilege targeting. `CREATE OR REPLACE FUNCTION` can create the function if that exact signature is absent, but any callers relying on a prior implementation will receive the new behavior.
- `public.profiles` with at least `id`, `created_at`, `profile_completeness`, `institution_name`, `discipline`, `year_of_study`, `state_of_origin`, `gender`, `utm_source`, `referral_source`, `utm_medium`, `utm_campaign`, and `campaign_id` columns.
- `public.events` with at least `profile_id`, `created_at`, `event`, and JSON/JSONB `meta` containing values such as `scholarship_id`, `eligible`, and `application_id`.
- `public.applications` with at least `id`, `profile_id`, `scholarship_id`, `created_at`, `updated_at`, and `status` columns.
- `public.saved_scholarships` with at least `scholarship_id` and `saved_at` columns.
- `public.scholarships` with at least `id`, `title`, and `provider_name` columns.
- `public.is_admin(uuid)`, called with `auth.uid()`.
- The Supabase-style `auth.uid()` function and an `authenticated` database role. The function also assumes authenticated callers have a meaningful auth context; an unauthenticated/null UID will fail the admin check unless the helper has unusual behavior.
- PostgreSQL built-ins and types including `plpgsql`, `jsonb`, `timestamptz`, `uuid`, `interval`, `date_trunc`, `to_char`, JSON aggregation/build functions, filtered aggregates, and casts. No non-core extension is explicitly referenced by this file.

Ordering implications are significant: the referenced tables and columns, `public.is_admin(uuid)`, `auth.uid()`, and the `authenticated` role must already exist before this migration is installed or before the function is invoked successfully. Existing grants or ownership may also affect whether the migration runner can replace the function and alter its privileges. The function body is mostly evaluated at call time by PL/pgSQL, so a missing relation may not be exposed until invocation, but that does not make the dependency optional.

# Data/external-side-effect assessment

The migration contains no literal business records, seed rows, URLs, HTTP calls, storage references, webhooks, external service identifiers, or other external destinations. It contains only SQL source and privilege changes.

At runtime, calling the function performs read-only aggregation over potentially sensitive user/profile, event, scholarship, and application data and returns the results as JSONB. The migration itself does not run those reads merely by being applied. There are no writes to real data and no external side effects in the migration text.

# Security/ordering implications

The security boundary is deliberate but important. `SECURITY DEFINER` makes the function execute with its owner’s privileges, while `REVOKE ALL FROM public` followed by `GRANT EXECUTE TO authenticated` exposes the callable interface to authenticated users. The function then requires `public.is_admin(auth.uid())`, which is the primary per-caller authorization check. If that helper is incorrect, mutable, absent, or not safe under the function’s execution context, an authenticated caller could receive aggregate data beyond the intended administrator audience.

`SET search_path = public` reduces search-path hijacking for unqualified names in the function body, and most application objects are explicitly schema-qualified. The function still calls `auth.uid()` using the `auth` schema and relies on the `public.is_admin` helper, so both must resolve as intended. The function owner and ownership/privilege model should be treated as part of the security design. The migration does not itself enable or disable RLS.

The function accepts arbitrary `p_since` and `p_until` values and does not reject a reversed, null, or unusually broad window. Defaults are a 30-day window ending at `now()`, but callers can provide other ranges. That is an analytics correctness/performance consideration and potentially a data-minimization concern, not a write-side effect. Several metrics intentionally use different time relationships: profile creation is windowed, activation looks up events through seven days after signup, and retention checks day 1/7/30 after signup. The `wau` and `mau` expressions are identical in this implementation, so they currently return the same count; this is a semantic behavior to preserve or review, not a migration-ordering issue.

Installation should follow creation of all referenced schema objects and helper functions. Privilege statements should be applied after the function exists with the exact signature. Re-running the migration is intended to be idempotent for the function body and grants/revokes, subject to ownership and role availability.

# Reconstruction recommendation

For a synthetic local schema reconstruction whose goal is tables, representative data, or basic application flows, this migration is **safe to omit** if provider analytics are out of scope. It performs no data migration and does not establish tables or relationships required by ordinary CRUD behavior.

It is **not safe to omit** when reproducing the provider-analytics RPC/API contract, administrator reporting screens, or permission behavior. In that case, recreate the function only after the dependent tables, columns, `auth.uid()`, `public.is_admin(uuid)`, and `authenticated` role are present, and preserve the explicit revoke/grant plus administrator check. A lightweight synthetic substitute may return fixture JSON, but that would not be behaviorally equivalent to this migration.

# Verdict

**PASS — safe to omit from a synthetic local schema reconstruction when provider analytics are not required; conditionally required for analytics/API parity.**

This is a source-level PASS for the requested omission assessment, not a claim that execution has been tested. The migration is read-only with respect to application data and has no external URLs or external side effects. Its principal caveats are the extensive earlier-schema dependencies, the security-definer/admin authorization boundary, exact function-signature privilege targeting, and the need to install it after the referenced objects and roles/functions exist.
