# Scholars Phase 2.1.5 — Candidate Baseline Security Review

**Investigation date:** 2026-11-10
**Scope:** Read-only production catalog review of privileges, RLS, functions, views, storage, managed-schema triggers, extensions, and destination defaults. No RPC was invoked and no setting was modified.

## Executive finding

The live database has broad browser-role ACLs on many tables and 31 public security-definer functions, but RLS and function ACLs determine the effective path. These facts are confirmed configuration risks requiring deliberate review; they are not, by themselves, proof of an exploitable vulnerability. No blanket revocation is recommended.

## Tables, ownership, and privileges

All 45 public tables are owned by `postgres`, have RLS enabled, and have `relforcerowsecurity = false`. The public ACL inventory shows many application tables granting `arwdDxtm` to `anon` and `authenticated`; this includes high-value domains such as applications, profiles, notifications, discovery, and community data. Resource Center editorial tables are narrower, with service-role and authenticated access. Public Resource Center views have read-only browser ACLs.

The effective security boundary therefore depends on policy correctness and role context, not ACL inspection alone. `TRUNCATE`, `REFERENCES`, and `TRIGGER` capabilities must be explicitly checked in any future artifact review; the current sanitized ACL summary should not be interpreted as authorization to alter them.

Production `postgres` default privileges for public tables and functions are narrower than staging's `postgres` defaults. Staging's `postgres` defaults grant public, anonymous, authenticated, and service-role access on new public schemas, functions, and tables. Both environments also expose broad platform defaults under `supabase_admin`, and both have broad storage defaults. A restore executed under a different creator role can therefore produce materially different access behavior.

## RLS findings

| Finding | Status |
|---|---|
| Public application tables with RLS enabled | Confirmed: 45 |
| Tables with force RLS | Confirmed: 0 |
| Public policies | Confirmed through bounded `pg_policies` read |
| Policy roles | Mix of `{public}`, `{authenticated}`, `{anon,authenticated}`, and targeted roles |
| Permissive-policy combinations | Present in catalog; requires per-table logical review |
| Data-path exploitation | Not tested; no sensitive RPC or data access invoked |

Policies include own-row checks, admin checks through `is_admin(auth.uid())`, verified/public filters, and storage bucket/path checks. The presence of multiple permissive policies means a future reviewer must evaluate their OR-combination semantics table by table. No policy was changed.

## Functions and RPC exposure

The following previously identified functions were confirmed as security-definer functions owned by `postgres`:

| Function | Browser EXECUTE posture | Search path configuration | Confirmed concern |
|---|---|---|---|
| `is_admin(uuid)` | PUBLIC execute appears in ACL | Empty search path configuration | Privileged predicate is publicly callable; body not invoked or exposed |
| `get_admin_metrics_summary(timestamptz)` | `anon` and `authenticated` execute | `search_path=public` | Admin-summary RPC has browser grants; reachable behavior not tested |
| `run_achievement_checks(uuid)` | PUBLIC/anon/authenticated execute | Empty search path configuration | Privileged trigger/achievement path is publicly callable by ACL |

The database contains 31 public security-definer functions. Several use `search_path=public`; several older functions use an explicitly empty search path configuration. The catalog review did not retrieve function bodies, so dynamic SQL, qualification of every relation, and privileged operations remain unverified. No sensitive RPC was invoked.

## Views

The four Resource Center public views are owned by `postgres`, use `security_barrier=true`, and grant `SELECT` to `anon` and `authenticated`. Their definitions filter active, published, and time-valid content. The catalog evidence did not establish a `security_invoker=true` option; this must be verified in the extraction artifact or by an explicitly authorized catalog field. Underlying table access and view behavior must be tested without using production records.

## Storage and managed schemas

Production has two public buckets: `avatars` and `site`. The storage object policies allow public reads for both buckets; authenticated users can manage their own avatar path, and authenticated admins can manage site objects through `is_admin`. This is consistent with an intentionally public asset surface, but path and MIME controls require independent review.

A custom `auth.users` trigger, `on_auth_user_created`, calls `handle_new_user()`. Application triggers cover profiles, applications, scholarships, WAEC summaries, XP, discussions, notifications, and related achievements. Storage platform/custom triggers are present and must not be replayed blindly into a new environment.

## Extensions

Production and staging match on `pg_stat_statements` 1.11, `pgcrypto` 1.3, `plpgsql` 1.0, `supabase_vault` 0.3.1, and `uuid-ossp` 1.1. Vault is platform-managed; no Vault contents were read or copied.

## Confirmed facts versus inference

- **Confirmed:** ACLs, RLS flags, policy metadata, function security mode, function ACL summaries, view options, buckets, storage policies, triggers, extensions, and default-privilege records from bounded catalog reads.
- **Not confirmed:** exploitability, function-body safety, dynamic-SQL behavior, exact PostgREST exposure, or whether any public RPC returns sensitive rows.
- **Inference:** restoring under staging's broader `postgres` defaults could expose newly created objects unless restoration role and ACL overlays are explicitly controlled.

## Required security gates

1. Obtain and sanitize the actual schema artifacts.
2. Review every public/browser EXECUTE grant on security-definer functions.
3. Confirm fixed search paths and fully qualified references in privileged bodies.
4. Verify view invoker/definer behavior and API exposure.
5. Reconcile policy combinations against the application dependency matrix.
6. Restore only under an approved executor role with an explicit ACL plan; do not use staging defaults implicitly.

## References

- [Supabase declarative schema caveats](https://supabase.com/docs/guides/local-development/declarative-database-schemas)
- [Supabase diff engines](https://supabase.com/docs/guides/local-development/diff-engines)
