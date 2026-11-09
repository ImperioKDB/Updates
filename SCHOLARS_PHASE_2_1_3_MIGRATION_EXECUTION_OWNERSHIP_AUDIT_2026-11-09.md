# Scholars Phase 2.1.3 — Migration Execution Ownership Audit

**Investigation date:** 2026-11-09
**Status:** Read-only production ownership investigation; no roles, memberships, ACLs, defaults, or migrations were changed.

## Confirmed production ownership

The production `supabase_migrations.schema_migrations` relation is owned by `postgres`. The live application relation inventory shows 210 inspected relations owned by `postgres`; 36 storage relations are owned by `supabase_storage_admin`. The inspected 42 application functions in `public` are owned by `postgres`. The `public` schema is owned by `postgres`, `storage` by `supabase_admin`, and the migration schema by `pg_database_owner`.

The migration table itself has no application-visible executor, commit, or source-file column in the inspected metadata. Its current catalog estimate was stale at 168 rows, while the direct ordered migration query returned 180 rows. The ledger records applied versions and names, not which role or CI identity executed each entry.

## Role capability evidence

The inspected role metadata showed:

- `postgres`: login-capable, create-role/create-database capable, replication-capable, and bypasses RLS; not marked `rolsuper` in the returned catalog.
- `supabase_admin`: superuser, login-capable, create-role/create-database capable, replication-capable, and bypasses RLS.
- `service_role`: no login, no create-role/create-database capability, and bypasses RLS.
- `anon` and `authenticated`: no login, no role/database creation capability, no replication, and no RLS bypass.
- `dashboard_user`: can create roles/databases and replicate, but is not superuser and does not bypass RLS.

These are capability facts, not evidence that any one role ran the migration history.

## Membership evidence

The returned memberships show `postgres` has memberships in `anon`, `authenticated`, `authenticator`, `service_role`, and platform monitoring/privileged roles with the recorded admin options. `authenticator` is a member of `anon`, `authenticated`, and `service_role`; realtime platform roles have corresponding memberships. No application migration should change these platform-managed relationships.

## Default privilege evidence

Previously captured production default ACL metadata shows materially different defaults by creator and schema:

- `postgres` defaults in `public` grant sequence usage to `postgres` and `service_role`, routine EXECUTE to `postgres` and `service_role`, and table privileges to `postgres` and `service_role`.
- `supabase_admin` defaults in `public` grant schema usage, routine EXECUTE, and table privileges to `anon`, `authenticated`, and `service_role` in addition to `postgres`.
- Storage defaults include broader platform-managed grants than the public application defaults.

This difference is the main future-object risk: the same migration executed by different roles can create objects with different ownership/default ACL outcomes. The evidence does not establish that `supabase_admin` executed the application migrations; it establishes only that its default ACLs differ.

## What cannot be established

The available Supabase connector cannot answer which role, dashboard action, CI job, or personal access token executed each historical migration. `schema_migrations` has no executor field, and current role ownership is not historical execution evidence. `pg_stat_activity` would only describe current sessions and is not a migration audit log; it was not used as a substitute.

The expected future application migration executor is therefore unresolved. The exact evidence required is one of:

1. A supported Supabase migration-history/export record that includes executor identity and source revision.
2. CI/CD migration logs showing the project ref, ordered migration set, authenticated automation identity, and successful result.
3. Supabase Management API audit/log evidence accessible to an authorized project administrator.
4. A repository migration manifest signed or committed by the approved migration owner, mapped to the production ledger.

No database password, service-role key, PAT, JWT, or access token was requested or displayed.

## Safe governance recommendation

Until ownership is proven, treat the migration process as **not reproducible**. The founder should approve one supported application migration executor, preferably a dedicated CI identity with project-scoped permissions, and require every run to publish the ordered migration versions, source commit/blob hashes, project ref, and result. Do not grant application roles platform superuser or alter platform-managed memberships. Validate the process in staging only after the provenance reconciliation is complete.

## References

[1]: https://github.com/ImperioKDB/Scholars/commit/cf3682ce35912df7b9b9352193630fc404427c7c "Scholars application baseline"
[2]: https://supabase.com/docs/reference/api/introduction "Supabase Management API authentication"
[3]: https://github.com/ImperioKDB/Updates/commit/67ec2b5d84491607b13a6efcf1d68c1d1d93c931 "Phase 2.1.2 evidence baseline"
