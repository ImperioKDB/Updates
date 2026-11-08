# File

- **Path:** `/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0086_add_daily_visitor_metrics.sql`
- **Migration purpose:** Add day-level visitor/page-view metrics, backfill those metrics from existing first-party page-view events, and expose narrowly controlled RPC functions for recording and retrieving metrics.
- **Audit mode:** Strictly read-only. Only this migration was inspected. No SQL was executed, no Supabase instance or hosted service was started or accessed, and the snapshot was not modified.

# Scope

This migration defines the storage and RPC surface for daily visitor monitoring. It creates `public.visitor_daily_metrics`, enables row-level security on that table, changes table/function privileges, performs a backfill from `public.events`, and creates or replaces two PL/pgSQL functions:

- `public.record_visitor_page_view(text, timestamptz)`, for inserting or incrementing a visitor/day counter.
- `public.get_daily_visitor_metrics(timestamptz, timestamptz)`, for returning an administrator-gated JSONB report.

The migration is not limited to schema-only DDL: its `insert ... select` statement reads existing application data and writes derived aggregate rows.

# Objects and mutations

## DDL

1. Creates table `public.visitor_daily_metrics` if it does not already exist, with:
   - `day date not null`.
   - `visitor_key text not null`.
   - `page_views integer not null default 1 check (page_views > 0)`.
   - `first_seen timestamptz not null default now()`.
   - `last_seen timestamptz not null default now()`.
   - Composite primary key `(day, visitor_key)`.
2. Enables row-level security on `public.visitor_daily_metrics`.
3. Creates or replaces `public.record_visitor_page_view(text, timestamptz)`, returning `void`, written in PL/pgSQL, marked `security definer`, and fixed to `set search_path = public`.
4. Creates or replaces `public.get_daily_visitor_metrics(timestamptz, timestamptz)`, returning `jsonb`, written in PL/pgSQL, marked `security definer`, and fixed to `set search_path = public`.

## DML

The migration backfills `public.visitor_daily_metrics` from `public.events` where `event = 'page_viewed'` and `profile_id is not null`. It groups by the UTC calendar date and a prefixed profile identifier (`profile:` plus `profile_id`), computes the count and minimum/maximum timestamps, and inserts the result. On a primary-key conflict it updates `page_views`, `first_seen`, and `last_seen` using the incoming aggregate and the existing row. This is a data mutation against existing rows and can create a potentially substantial number of derived records.

The recording function also performs DML: it validates the visitor key, converts the supplied timestamp to a UTC date, then inserts one row or increments `page_views` and advances `last_seen` on conflict. It does not update `first_seen` on an existing row.

The reporting function performs read-only query work and constructs JSONB containing the requested window, total distinct visitor keys, total page views, and daily visitor/page-view aggregates.

## Grants and revokes

- Revokes all table privileges on `public.visitor_daily_metrics` from `anon` and `authenticated`.
- Grants `select`, `insert`, and `update` on that table to `service_role`.
- Revokes all privileges on `record_visitor_page_view(text, timestamptz)` from `public`, `anon`, and `authenticated`.
- Grants execute on `record_visitor_page_view(text, timestamptz)` to `service_role`.
- Revokes all privileges on `get_daily_visitor_metrics(timestamptz, timestamptz)` from `public`.
- Grants execute on `get_daily_visitor_metrics(timestamptz, timestamptz)` to `authenticated`.

There is no explicit grant to `service_role` for the reporting function, although service-role behavior may depend on the platform role configuration and function ownership. There are no table policies defined in this migration; RLS is enabled but direct access for `anon` and `authenticated` is removed.

# Dependencies

- **`public.events` table:** Required by the backfill. The migration expects at least `created_at`, `event`, and `profile_id` columns with compatible types. Existing `page_viewed` rows with non-null profiles are read and aggregated.
- **`public.is_admin(uuid)` function:** Required when `get_daily_visitor_metrics` is called. The function invokes `public.is_admin(auth.uid())` and raises `Admin access required` if false. This dependency is not created here.
- **`auth.uid()` function/context:** Required for the reporting authorization check. It is normally supplied by the Supabase authentication environment; an absent authenticated request produces a null identity and fails the admin check.
- **PostgreSQL/Supabase roles:** The migration assumes `anon`, `authenticated`, `service_role`, and `public` exist and that the stated grant/revoke operations are permitted.
- **PL/pgSQL and JSONB support:** Both functions require PL/pgSQL; the reporting function uses JSONB construction and aggregation functions.
- **Ordering:** The `events` table and its relevant columns must exist before this migration runs because the backfill executes immediately. The `is_admin` function must exist before the reporting RPC is successfully invoked; it is referenced in the function body rather than created here. The authentication helper and expected roles must be available in the target environment. Application callers should use the recording RPC only after the table and function are installed.

# Data/external-side-effect assessment

This migration does access and mutate real database data if run against a populated database. The backfill reads first-party page-view history from `public.events` and persists derived daily aggregates. It does not delete or update `public.events`; its only mutation of pre-existing application data is the creation or conflict-update of rows in the new metrics table.

The data written includes opaque or prefixed visitor keys, day-level counts, and first/last timestamps. For the backfilled records, the visitor key is derived from a profile ID (`profile:<id>`), so it is pseudonymous/derived rather than an anonymous random key. The comments explicitly state that IP addresses, user agents, and raw personal identifiers are not persisted by this table. The function accepts `profile:` and `cookie:` keys containing only ASCII letters, digits, underscores, and hyphens, with a maximum key payload length of 128 characters.

There are no external URLs, HTTP calls, file operations, network calls, hosted-service calls, or other non-database external side effects in the SQL text. The `now()` defaults and supplied timestamps affect recorded temporal values but do not themselves create an external side effect.

# Security/ordering implications

- The metrics table has RLS enabled and no policies are added here. Direct `anon` and `authenticated` table privileges are revoked, while `service_role` receives the required table privileges. This intentionally routes writes through the service role/RPC boundary rather than direct client table access.
- `record_visitor_page_view` is `security definer`, has a fixed `search_path = public`, and is executable only by `service_role` after the explicit revokes. Its visitor-key validation prevents arbitrary key formats, but callers with service-role access can still record arbitrary valid keys and timestamps, including timestamps outside the current day.
- `get_daily_visitor_metrics` is also `security definer` and fixes its search path. It grants execution to `authenticated`, then performs an explicit `public.is_admin(auth.uid())` check. The authorization control therefore depends on the correctness and security of `is_admin`, the authentication context, and the function owner/privilege configuration.
- The reporting function's `security definer` status means its queries run with definer privileges after the admin check. The migration does not explicitly revoke execute from `anon`/`authenticated` for the reporting function beyond revoking from `public`; in PostgreSQL, revoking from `public` removes the inherited default, while the explicit `authenticated` grant enables intended access.
- The backfill occurs during migration execution and may be expensive on a large `events` table. It requires sufficient privileges to read `public.events` and write the new table. It is grouped by UTC day, while report range filtering also converts bounds to UTC dates and includes the entire ending UTC date (`< until-date + 1`), so callers should understand that reports are day-granular rather than exact timestamp windows.
- The composite primary key makes the backfill and recording operation conflict-safe for a given day/key pair. The backfill's `page_views = excluded.page_views` replaces an existing aggregate with the recalculated event-derived count on conflict, whereas the recording function increments the existing count. Re-running the migration is therefore not purely a no-op if rows have subsequently been recorded: the backfill can reset counts for keys represented by qualifying event history.
- No explicit indexes beyond the composite primary key are created. The reporting predicates on `day` can use the primary-key leading column, but the distinct visitor and aggregate queries may still be costly as the table grows.

# Reconstruction recommendation

For a **synthetic schema reconstruction focused only on structural entities and avoiding real-data behavior**, this migration may be omitted, provided the reconstruction does not claim to reproduce visitor analytics, the two RPCs, or application flows that call them. Omitting it avoids the real-data backfill and avoids introducing a derived analytics table whose contents cannot be meaningfully synthesized from absent event history.

For a reconstruction intended to preserve application behavior or RPC compatibility, it should not be omitted wholesale. Recreate the table, key constraints, relevant RLS/privilege boundary, and both functions, but seed no real historical data. A safe synthetic alternative is to create the table and functions without executing the backfill, or to use explicitly synthetic `events` data only if test behavior requires it. The `public.events` dependency and `public.is_admin` dependency must be represented or stubbed in the reconstruction before exercising the affected functions.

# Verdict

**Conditional omission recommended for a synthetic schema reconstruction; retain as a behavior-critical migration when visitor metrics or its RPC endpoints are in scope.** This is not a pure DDL migration: it performs a real-data backfill and establishes security-sensitive, definer-rights RPCs. It has no external URL or network side effects, but it has material database data and privilege effects. The migration can be omitted from a minimal synthetic schema only when analytics storage/reporting is explicitly out of scope and no dependent application code is expected to call these objects.
