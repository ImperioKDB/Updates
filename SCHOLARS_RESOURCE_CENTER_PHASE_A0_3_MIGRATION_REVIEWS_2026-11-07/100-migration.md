# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/0082_harden_provider_analytics.sql`

This review covers only this migration file. No SQL was executed, no Supabase instance or hosted service was started or accessed, and the source snapshot was not modified.

# Scope

The migration hardens and replaces the `public.get_provider_analytics(timestamptz, timestamptz, uuid)` reporting function. The function accepts an optional time window and optional scholarship filter, verifies that the caller is an administrator, aggregates registration, activity, activation, retention, demographic, acquisition, and scholarship-funnel metrics, and returns the result as a single `jsonb` value.

The migration also changes routine privileges: it revokes all privileges on that exact function signature from `public` and grants `EXECUTE` to `authenticated`.

# Objects and mutations

## Created or altered

- `CREATE OR REPLACE FUNCTION public.get_provider_analytics(p_since timestamptz default now() - interval '30 days', p_until timestamptz default now(), p_scholarship_id uuid default null)`
  - Return type: `jsonb`.
  - Language: `plpgsql`.
  - Security mode: `SECURITY DEFINER`.
  - Execution search path: `public`.
  - The body computes and returns a JSON object containing:
    - the requested window;
    - growth metrics including total registered profiles, daily signups, WAU, MAU, and returning users;
    - activation metrics;
    - day-1, day-7, and day-30 retention metrics;
    - demographic distributions for institution, discipline, study level, state, and gender;
    - acquisition groupings by source, medium, and campaign, with signups, completed profiles, activated users, and applications;
    - a scholarship funnel with views, eligible students, saves, application starts, provider clicks, and application outcomes.
- `CREATE OR REPLACE` alters an existing routine if present and creates it if absent; it does not create a table, view, type, extension, trigger, index, policy, role, or schema.

## Privilege mutations

- `REVOKE ALL ON FUNCTION public.get_provider_analytics(timestamptz, timestamptz, uuid) FROM public`.
- `GRANT EXECUTE ON FUNCTION public.get_provider_analytics(timestamptz, timestamptz, uuid) TO authenticated`.

There are no explicit `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, or other persistent data mutations. The query uses CTEs and aggregate reads only. Its local variable `result` is assigned and returned, not stored in a table.

# Dependencies

The migration assumes the following earlier schema objects, extensions, roles, and runtime context exist:

- The `public` schema.
- The `public.profiles` table, with at least `id`, `created_at`, `profile_completeness`, `institution_name`, `discipline`, `year_of_study`, `state_of_origin`, `gender`, `utm_source`, `referral_source`, `utm_medium`, `utm_campaign`, and `campaign_id` columns.
- The `public.events` table, with at least `profile_id`, `created_at`, `event`, and `meta` columns. `meta` must support JSON/JSONB operators (`->>`), and the function expects event names such as `match_viewed` and `provider_clicked`.
- The `public.applications` table, with at least `id`, `profile_id`, `scholarship_id`, `created_at`, `updated_at`, and `status` columns.
- The `public.saved_scholarships` table, with at least `scholarship_id` and `saved_at` columns.
- The `public.scholarships` table, with at least `id`, `title`, and `provider_name` columns.
- The `public.is_admin(uuid)` function, callable as `public.is_admin(auth.uid())`, and an `auth.uid()` function supplied by the authentication environment. The function must return a boolean-compatible result.
- The PostgreSQL types and built-ins used by the body, including `timestamptz`, `uuid`, `jsonb`, PL/pgSQL, `date_trunc`, `to_char`, `greatest`, JSONB operators/functions, filtered aggregates, and `row_to_json`. No non-default extension is explicitly referenced by this file.
- The roles `public` and `authenticated`. The latter must exist for the final `GRANT` to succeed.

The function relies on existing permissions and row-level-security behavior for the `SECURITY DEFINER` owner. Because the body sets `search_path = public`, unqualified object lookup is constrained to `public` (while `auth.uid()` is explicitly schema-qualified only by its function name context as written and must be resolvable in the deployed environment). The function owner must be able to read all referenced tables and execute `public.is_admin`.

# Data/external-side-effect assessment

This migration contains no literal business records, seed rows, URLs, HTTP endpoints, file paths used as data, secrets, or other external references. It does not call an external service, send events, write files, or alter hosted data during migration application.

At invocation time, the resulting function reads live application data from the referenced tables and exposes aggregated analytics to callers who pass the administrator check. It does not itself insert, update, or delete application data. The event metadata is read defensively with JSON text extraction: malformed or absent `application_id` and `eligible` values do not require a JSON cast and therefore do not normally abort the report. The report can still fail if required tables, columns, types, functions, permissions, or data invariants are absent.

# Security/ordering implications

- The routine is `SECURITY DEFINER`, so it executes with the function owner's privileges. This is intentional for an admin report but makes ownership and execute-grant hygiene material.
- The body checks `public.is_admin(auth.uid())` before producing results and raises `Admin access required` for non-admin callers. The `authenticated` role receives `EXECUTE`, but authentication alone is not intended to authorize the report.
- Invalid or null bounds are rejected when `p_since` or `p_until` is null or when `p_since >= p_until`.
- `set search_path = public` reduces search-path hijacking risk for unqualified table and type references. The function should remain owned by a trusted, non-login role where possible, and referenced objects should not be made writable by untrusted users.
- The privilege statements target the exact three-argument signature. If an earlier migration created an overload with a different signature, that overload is unaffected.
- Ordering is significant: the referenced tables, columns, `public.is_admin`, `authenticated` role, and the function's supporting PostgreSQL capabilities must exist before this migration runs. The migration is naturally late-stage because it aggregates across profiles, events, applications, saved scholarships, and scholarships.
- Replacing an existing function may affect callers if the prior routine had materially different semantics, but the signature and return type are preserved here. Applying this file before its dependencies will fail at function creation or privilege application rather than silently creating a partial analytics implementation.
- No explicit `REVOKE` is issued against `authenticated` beyond the `REVOKE ALL ... FROM public`; the final grant is the effective intended permission for authenticated users, subject to role membership and any broader inherited privileges.

# Reconstruction recommendation

It is safe to omit this migration from a synthetic local schema reconstruction **when provider analytics is outside the reconstructed behavior** and the goal is to reproduce tables and core application flows only. Omitting it avoids recreating a reporting routine whose value depends on numerous application tables and on the real authentication/admin function.

It is not safe to omit it if local tests, routes, RPC calls, or downstream code invoke `public.get_provider_analytics` and expect the analytics JSON shape or admin authorization behavior. In that case, reconstruct the prerequisite tables and `public.is_admin` first, then apply this function and its exact privilege changes. A stub should preserve the signature and authorization contract rather than returning unrestricted data.

This recommendation concerns migration inclusion in a synthetic reconstruction, not execution against the source or a hosted database. The migration itself has no data-write or external-service side effect visible from the file and is structurally appropriate to apply after its dependencies are present.

# Verdict

**PASS** — Read-only audit completed. The migration is a deterministic function replacement and privilege adjustment with no literal data, external URLs, network calls, or direct DML. It is safe to apply only after the listed schema, function, role, and authentication dependencies are present; it is safe to omit from a synthetic local schema reconstruction only when provider analytics behavior is intentionally out of scope. No blocker was found in the file itself, and no SQL execution was performed.
