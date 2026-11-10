# Scholars Phase 2.1.4 — Schema-Only Baseline Feasibility

**Investigation date:** 2026-11-10
**Scope:** Read-only strategy design. No export, restore, migration, object creation, privilege change, or data copy was performed.

## Feasibility conclusion

A controlled schema-only baseline is **technically feasible and safer than historical replay**, provided it is treated as a new reviewed baseline rather than an exact reconstruction of historical migration execution.

Supabase documents `supabase db dump` as a remote database dump command that runs `pg_dump` with Supabase-specific filtering. Its default output excludes data and custom roles, and it excludes Supabase-managed schemas and extension-created objects. The CLI supports schema selection and writes the result to a file. [1] Raw `pg_dump` is not the preferred route because it can include Supabase internals and reserved roles that are unsafe or incompatible to restore. [2]

Supabase also documents `supabase db pull`. With the current `pg-delta` engine, an initial pull can diff the remote database against an empty shadow database and capture customizations such as triggers on `auth.users` and RLS policies on `storage.objects` and `storage.buckets`. The legacy `migra` path seeds from `pg_dump`, skips managed schemas, and then appends selected managed-schema trigger and policy changes. `pg-delta` can report objects it cannot manage; `--strict-coverage` turns those warnings into failures. [3]

## What a reviewed export can contain

A schema-only export can represent application tables and columns, primary and foreign keys, check constraints, indexes, enums and domains, views, functions, triggers, RLS policies, grants, and default privileges when those definitions are included in the selected dump and are not filtered as platform-managed objects. The export must be inspected rather than trusted as a complete contract: Supabase documents known diff limitations around publications, storage buckets, and view `security_invoker` attributes under the legacy engine. [1] [3]

The export should be separated into three review classes:

1. **Application-owned schema:** `public` tables, views, functions, triggers, policies, grants, defaults, and approved custom schemas.
2. **Approved customizations to managed schemas:** only project-owned triggers or policies in `auth` and `storage`, captured using the selected CLI diff engine and reviewed independently.
3. **Platform-managed baseline:** internal Auth, Storage, Realtime, GraphQL, Vault, migration, and extension objects that must not be copied blindly into a new project.

Storage bucket definitions and storage objects require special handling. Bucket configuration is not equivalent to application table DDL, and legacy schema diffing can miss storage bucket changes. The new baseline must define approved synthetic buckets and policies from an explicit review; it must not copy production objects or personal files. [3]

## Current dependency evidence

Production currently has five installed extensions: `pg_stat_statements` 1.11, `pgcrypto` 1.3, `plpgsql` 1.0, `supabase_vault` 0.3.1, and `uuid-ossp` 1.1. Staging has the same five installed extensions and versions. This is useful readiness evidence, but it does not prove that every application function, extension object, Vault configuration, or platform setting is equivalent. The production and staging projects are both `ACTIVE_HEALTHY`; staging has no Scholars application relations and no storage buckets in the read-only inventory. [4]

No production data should enter the baseline. That includes `auth.users`, profiles, scholarship rows, application rows, event logs, notification payloads, storage objects, Vault secrets, service credentials, JWT material, and any seed data containing real people or contact details. Supabase's documented default schema dump excludes data and custom roles, but the review must still scan the generated SQL for `COPY`, `INSERT`, secret-like literals, and function bodies containing embedded credentials. [1] [2]

## Controlled baseline procedure

The safest future procedure is:

1. Obtain an authorized, sanitized project configuration record for production and staging before exporting anything.
2. Pin the Supabase CLI version and diff engine in a temporary, access-controlled workspace.
3. Generate a schema-only dump or initial `db pull` from production using only approved schemas. Do not use a raw database password in files, shell history, reports, or commits.
4. Generate a second capture for approved `auth` and `storage` customizations using the selected `pg-delta` path or a separately reviewed diff. Use `--strict-coverage` where supported.
5. Inspect the SQL for data statements, platform-managed objects, roles, secrets, Vault material, storage objects, and unsupported statements. Fail closed if any are present.
6. Compare the export against read-only production catalog inventories for relations, routines, views, triggers, policies, grants, defaults, extensions, publications, and schemas. Record intentional exclusions.
7. Review the export with an independent application/security reviewer. The reviewer must compare the public API surface and service-role boundaries against the application dependency matrix.
8. Convert the approved export into a new version-controlled baseline migration or reviewed declarative schema tree. Give it a new baseline identifier; do not reuse historical migration versions.
9. Test the new baseline in an isolated local or disposable Postgres environment before any staging change. Check object creation order, function search paths, RLS behavior, grants, default privileges, and extension availability.
10. Only after explicit approval, apply the reviewed baseline to the empty staging project, then generate types and run role-specific application compatibility tests.

The resulting baseline must include a manifest with the production project ref, export timestamp, CLI version, diff engine, selected schemas, exclusion list, source dump hash, reviewed migration hash, extension list, PostgREST configuration evidence, reviewer, and approval record.

## What this strategy does not solve

A schema-only baseline does not reproduce historical migration order, transient data backfills, deleted rows, seed decisions, executor identity, or historical privilege mistakes. It captures an approved current state. Production seeds and data migrations require a separate decision: use synthetic fixtures for staging by default, and create a reviewed, de-identified seed package only if the application genuinely needs catalogue fixtures. Never copy production student or applicant data.

## Feasibility decision

Strategy B is feasible with conditions and is the preferred route. It is not authorized for execution in this phase. The strategy remains blocked until the schema export is reviewed, PostgREST settings are captured, application/security owners approve exclusions, and the founder authorizes the staging preparation window.

## References

[1]: https://supabase.com/docs/reference/cli/introduction "Supabase CLI reference"
[2]: https://supabase.com/docs/guides/self-hosting/restore-from-platform "Supabase restore from platform"
[3]: https://supabase.com/docs/guides/local-development/diff-engines "Supabase diff engines"
[4]: https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_PHASE_2_1_3_READINESS_AND_GOVERNANCE_DECISION_REGISTER_2026-11-09.md "Phase 2.1.3 readiness evidence"
