# Scholars Phase 2.1.7 — Database Access Readiness

**Status:** BLOCKED — administrator action required
**Evidence date:** 2026-11-10
**Author:** Manus AI

## Finding

No suitable PostgreSQL connection for production schema capture is available in this session. The Supabase connector exposes dedicated read-only metadata inventories, but no database connection string. No verified database-read-only credential has been supplied, and its effective privileges cannot be inspected without connecting as that credential. We did not use the unrestricted SQL executor, service-role credentials, or any production SQL connection.

Current production project reference is `cmdglabohpttgfofcmqc`; staging is `aqhktriwaglvvrchxmtd`. These identities were confirmed in the prior approved inventory. The database is PostgreSQL 17.6 in production. No role, grant, password, or project configuration was changed.

## Supported paths and limits

Supabase documents PostgreSQL direct connections and a shared session pooler as connection methods for native PostgreSQL commands such as `pg_dump`. The Dashboard’s **Read-Only** team role is a platform access role, available on Team and Enterprise plans; it is not itself a PostgreSQL login credential. Supabase documents that Read-Only SQL snippets run as `supabase_read_only_user` and are limited to `SELECT`. The separate Management API read-only query endpoint is explicitly experimental/beta and accepts individual SQL queries; it is not a PostgreSQL connection that `pg_dump` can use. [1] [2] [3]

A `pg_read_all_data` membership is not an acceptable default for this capture: PostgreSQL defines it as broad read access across all data, which would be unnecessary exposure of student records for a schema-only operation. Do not substitute `postgres`, `service_role`, the project database password, a Dashboard query role, or an experimental query API for a restricted native connection. [2] [4]

## Required administrator action

The production project owner or database administrator must, under a separate explicit authorization, provision or identify a dedicated PostgreSQL login for schema-only inspection. Scope it to database connection and the minimum catalog/schema visibility necessary for the approved application schemas. It must have no superuser, role/database creation, RLS bypass, write, ownership, or inherited elevated privileges. Do not grant broad `pg_read_all_data` merely to make a dump succeed. If the minimum catalog access is insufficient, stop and obtain a reviewed privilege design rather than widening access. This phase did not authorize or perform that privilege change.

Deliver the credential only through an approved secret-injection mechanism into the chosen isolated runner. The account owner must provide a sanitized privilege-validation result showing the actual login role, role flags/memberships, `transaction_read_only`, database/schema access, and absence of effective write privileges. No credentials or connection strings should be pasted into chat, terminal transcripts, report files, or GitHub.

## Readiness decision

Database access is **not ready**. The admin must approve and provision the least-privilege credential and securely inject it before a non-writing connection test. No production data was queried or exported in this phase.

## References

[1]: https://supabase.com/docs/guides/database/connecting-to-postgres "Supabase PostgreSQL Connection Methods"
[2]: https://supabase.com/docs/guides/platform/access-control "Supabase Platform Access Control"
[3]: https://supabase.com/docs/reference/api/v1-read-only-query "Supabase Management API Read-Only Query Endpoint"
[4]: https://www.postgresql.org/docs/current/predefined-roles.html "PostgreSQL Predefined Roles"
