# Scholars Phase 2.1.7 — Administrator Action Guide

**Purpose:** Remove the access and test-runner blockers for a later authorized schema-only capture. No action below was performed in this phase.

## 1. Approve a non-writing production connection

For production project `cmdglabohpttgfofcmqc`, identify or separately authorize provisioning a dedicated PostgreSQL login for schema inspection. The current phase explicitly did not authorize role creation or production privilege changes. Do not use the `postgres` password, service-role key, an unrestricted SQL executor, or the beta Management API query endpoint.

The database login must be incapable of modifying production: no superuser, `BYPASSRLS`, `CREATEDB`, `CREATEROLE`, schema/object `CREATE`, table/sequence writes, ownership, or inherited elevated role memberships. Grant only database `CONNECT` and catalog/schema visibility needed for the approved schema-only dump. Do not grant `pg_read_all_data` as a shortcut; that role exposes application rows, including student data. Validate its effective memberships and ACLs, not just the intended role name. If `pg_dump --schema-only` cannot enumerate the approved definitions with that narrow access, stop and obtain security review before broadening it. [1] [2] [3]

Use the Dashboard’s **Connect** panel to select a native-compatible connection method. Supabase recommends direct PostgreSQL connection for `pg_dump`; the shared session pooler is the fallback when the runner cannot reach the direct endpoint. Do not use transaction-pooler mode for schema tools. Supply only the dedicated login’s credential through a secret manager or the isolated runner’s protected environment/password file. [4]

Return a sanitized validation record only: project ref, timestamp, connected database and login role, role flags/membership result, read-only transaction setting, approved schemas, and confirmation that effective write privileges are absent. Do not send the password or full connection string.

## 2. Read PostgREST configuration separately

For each project—production `cmdglabohpttgfofcmqc` and staging `aqhktriwaglvvrchxmtd`—use the supported GET endpoint `/v1/projects/{ref}/postgrest` with a short-lived fine-grained token limited to those projects. Required authorization is OAuth scope `rest:read` and permission `data_api_config_read`. Do **not** grant `data_api_config_secret_read`. [5]

Inject the token into an administrator-controlled process through a secret manager/environment. Disable shell tracing and HTTP debug output. Filter the response in memory and emit only `db_schema`, `db_extra_search_path`, `max_rows`, and approved pool settings. The documented response example includes `jwt_secret`; never display, log, or save the unfiltered body. Obtain separate sanitized evidence for each project. Record values not available from the supported response as **UNKNOWN**—do not infer or change them.

## 3. Provide an isolated runner

Identify an existing private Docker-enabled workstation or CI runner with no production data mounts. It must support Supabase CLI `2.122.1`, PostgreSQL 17 client tooling, SHA-256, private encrypted artifact storage, and synthetic-fixture testing. The current authorized-device inventory lists only the Manus Sandbox, which has no Docker or PostgreSQL client. Do not create a Supabase project, modify staging, buy a runner, or install privileged system packages for this phase. If no existing runner is available, report that explicitly and request separate approval for an alternative.

## 4. Return only these items

1. Sanitized DB-role privilege validation and confirmation of secure credential injection, without the credential.
2. Sanitized PostgREST evidence for each project, excluding all secrets.
3. Runner name/type and confirmation of CLI/client versions, Docker availability, private artifact storage, and synthetic-only test plan.
4. The approved schema allowlist and the person who authorized capture.

Never share passwords, PATs, JWTs, API keys, student rows, raw dumps, raw PostgREST responses, or artifact hashes in chat or GitHub. Do not authorize a staging restore as part of these steps.

## References

[1]: https://supabase.com/docs/guides/database/postgres/roles "Supabase Postgres Roles"
[2]: https://www.postgresql.org/docs/current/predefined-roles.html "PostgreSQL Predefined Roles"
[3]: https://www.postgresql.org/docs/current/app-pgdump.html "PostgreSQL pg_dump Reference"
[4]: https://supabase.com/docs/guides/database/connecting-to-postgres "Supabase PostgreSQL Connection Methods"
[5]: https://supabase.com/docs/reference/api/v1-get-postgrest-service-config "Supabase Management API Get PostgREST Configuration"
