# Scholars Phase 2.1.9 — Secure Schema Capture Enablement

**Verdict: BLOCKED — PRIVATE EXECUTION ENVIRONMENT REQUIRED**

This phase is enablement only. No production or staging database connection or SQL was used; no database settings, permissions, or application deployment were changed.

## Verified evidence

- GitHub identifies both `ImperioKDB/Updates` and `ImperioKDB/Scholars` as **public** repositories. Therefore neither repository is appropriate for production schema artifacts, hashes, credentials, or sensitive extraction logs.
- Workflow commit `04cb1e6d87ef5074a18a584cbb26d0a48c706b89` contains only `.github/workflows/scholars-runner-preflight.yml`. Synthetic Actions run [42838236003](https://github.com/ImperioKDB/Updates/actions/runs/42838236003) completed successfully. Its logs showed Ubuntu 24.04.5 x86_64, Docker 28.0.4, Supabase CLI 2.122.1, and PostgreSQL 17.11 client tools in a disposable PostgreSQL container. Synthetic schema-only object/row-exclusion assertions and cleanup passed. The host-installed `psql` and `pg_dump` were PostgreSQL 16.15; the workflow used the container’s PostgreSQL 17.11 clients for the synthetic dump. This test did **not** use a restricted database role or contact Supabase.
- The current authorized-device inventory lists only the online Manus Sandbox; no private Cloud Computer or other approved private runner is available. The sandbox’s existing access and retention are not verified as suitable for production schema artifacts.

## Least-privilege database access design (proposed, not provisioned)

Use a dedicated, temporary PostgreSQL login, separate from Supabase Management API credentials. Its required role attributes should be `LOGIN`, `NOSUPERUSER`, `NOCREATEDB`, `NOCREATEROLE`, `NOREPLICATION`, and `NOBYPASSRLS`; set a short, explicit validity window and connection limit if compatible with the selected connection method. It must have no role memberships, ownership, `SET ROLE` path, or inherited/grantable elevated privileges. Do not grant `pg_read_all_data`, `pg_write_all_data`, `pg_monitor`, file/program-access predefined roles, or broad database ownership. PostgreSQL 17 documents `pg_read_all_data` as SELECT-equivalent access to all tables, views and sequences across schemas; it is not an acceptable shortcut for schema capture. [1]

Candidate direct privileges are only database `CONNECT` and, if required by the selected catalog-reading method, schema `USAGE` on an administrator-approved allowlist. No table, view, sequence, large-object, or column `SELECT`; no DML, `EXECUTE`, `CREATE`, ownership, grant-option, or default privileges should be added without a demonstrated, separately reviewed need. PostgreSQL documents that schema `USAGE` enables lookup of contained objects and that object ACLs separately govern data access. [2]

**This is a privilege boundary, not a verified grant recipe.** PostgreSQL and Supabase’s published tool references do not specify a complete minimum ACL matrix for running `pg_dump --schema-only`, Supabase CLI `db dump`, and pg-delta declarative generation against a non-owner Supabase login. The successful synthetic test ran `pg_dump` as the disposable container’s database superuser and therefore proves no restricted-role compatibility. Do not provision this candidate until an isolated PostgreSQL 17/Supabase-compatible fixture tests each required object class with equivalent ACLs, and an administrator reviews any discrepancy. If a tool requires table `SELECT` or broad catalog privileges, document the data exposure and stop for explicit security approval; do not silently widen access.

### Tool-specific boundaries

- **`pg_dump --schema-only`:** PostgreSQL 17 defines `--schema-only` as object definitions rather than data. `--schema` limits the selected schema and its contained objects, but the manual does not promise a universal low-privilege catalog-access recipe. Multiple schemas require repeated `--schema` options; schema-filtered dumps may omit dependencies outside the selected schemas. [3]
- **Supabase `supabase db dump`:** the CLI runs `pg_dump` in a container; default behavior excludes Supabase-managed schemas including `auth`, `storage`, and extension-created schemas. It omits data and custom roles by default. It is therefore not, by itself, evidence of complete application customization coverage. Do not use `--data-only` or `--role-only`. [4]
- **Supabase declarative/pg-delta:** requires the pg-delta engine (`db schema declarative` commands do not run on legacy migra); use pinned CLI 2.122.1 and `--experimental` only after confirming supported flags/config. Supabase says pg-delta reads the catalog and needs direct connection for full catalog access where practical; session pooler may be needed for IPv4-only egress, and transaction pooler should not be used. Strict coverage should fail on unsupported object classes rather than conceal gaps. It excludes platform-owned objects inside managed schemas but captures some custom policies/triggers over auth/storage objects; it does not represent storage bucket rows or other DML. [5] [6]

Default privileges affect generated schema-state grant/revoke output; they are not a reason to grant extraction access. Record role memberships, ACLs, default ACLs and `PUBLIC` privileges during DBA review. Capture privilege definitions only if expressly in scope; never apply generated grants to production.

## Execution environment recommendation

Use a pre-existing, administrator-approved **private** Linux x86_64 runner or private repository/workspace with secure credential injection, private logs, encrypted private artifact storage, restricted reviewer access, no artifact publication to public repositories, and short retention. It must pin Supabase CLI exactly to 2.122.1, provide PostgreSQL 17-compatible `pg_dump`/`psql`, SHA-256, and support ephemeral test/cleanup. The public `Updates` workflow is approved for synthetic diagnostics only. Manual dispatch does not make a public repository private. No such private runner was found in the available-device inventory. Creating a new paid environment is out of scope.

## Non-executing capture procedure (after separate approvals)

1. Project owner authorizes one schema-only capture from production project `cmdglabohpttgfofcmqc`; staging `aqhktriwaglvvrchxmtd` remains excluded. Record approval, operator, scope, and retention period.
2. In the private runner, verify CLI `2.122.1`, PostgreSQL 17 client versions, SHA-256, clean ephemeral workspace, and private log/artifact controls. Inject a purpose-made short-lived DB credential only through a secret manager or protected file descriptor; never put it in CLI arguments, shell history, workflow output, or Git.
3. Connect using the administrator-approved native PostgreSQL connection method; verify server version, expected project/database identity, `current_user`, role flags and memberships, `transaction_read_only`, database/schema/object ACLs, ownership, default ACLs, and absence of effective write/owner/role-admin/RLS-bypass permissions. Check only catalog/role metadata. Stop on mismatch. `transaction_read_only` is an additional guard, not a substitute for correct privileges.
4. Agree an explicit schema/object inventory before capture. Do not assume `public` is complete. Handle `auth`, `storage`, extensions, `realtime`, `vault`, and other platform-managed schemas separately: identify custom policies, triggers and functions without exporting auth rows, storage objects, bucket rows, Vault contents, secrets, or platform-managed data. Any custom managed-schema object that a tool cannot faithfully capture must be recorded as a coverage limitation and handled in a separately reviewed migration inventory—not by widening extraction scope blindly.
5. Capture only reviewed schemas as plain-text `pg_dump --schema-only`; invoke `--schema` once per allowlisted schema. Separately run pg-delta declarative generation with `--strict-coverage` only if privilege-fixture results show the same narrow role can run it and current CLI help/config confirms flags. Treat both outputs as sensitive private artifacts.
6. Inspect privately for `INSERT`, `COPY`, row literals, auth/storage table data, Vault content, secrets, credentials, unexpected managed objects, and unsupported-object warnings. Stop and quarantine unexpected data; do not print dump content to logs.
7. Calculate SHA-256 locally and retain hashes only alongside the private artifacts. Record sanitized evidence: project ref, timestamp, DB/tool versions, selected schemas, Git commit, command modes, object counts, warnings, redacted artifact identifiers, and cleanup/retention result. Never disclose SQL or hashes in public `Updates`.
8. Revoke/expire the temporary login and remove memberships/grants through the approved change process; invalidate its credential through the secret manager. Confirm no session remains, securely delete temporary files and credentials, verify artifact access/retention, and retain only the sanitized report.

## Required administrator actions

1. **Provide/approve a private execution environment** with the controls above, or explicitly authorize another existing no-new-cost private runner. Do not use either public GitHub repository for capture.
2. **Have the database owner/security administrator validate** a least-privilege PostgreSQL 17 role on an isolated equivalent fixture for each selected extraction tool. Approve only the minimum grants that pass; no broad read roles. If exact tool needs cannot be met without table-data access or expanded catalog privileges, decide whether to exclude that tool or separately approve documented exposure.
3. **Separately authorize production capture and schema allowlist** after fixture and runner evidence is reviewed. This phase does not authorize credential creation, production connection, or extraction.

## References

[1]: https://www.postgresql.org/docs/17/predefined-roles.html "PostgreSQL 17 Predefined Roles"
[2]: https://www.postgresql.org/docs/17/ddl-priv.html "PostgreSQL 17 Privileges"
[3]: https://www.postgresql.org/docs/17/app-pgdump.html "PostgreSQL 17 pg_dump"
[4]: https://supabase.com/docs/reference/cli/introduction "Supabase CLI db dump"
[5]: https://supabase.com/docs/guides/local-development/declarative-database-schemas "Supabase Declarative Database Schemas"
[6]: https://supabase.com/docs/guides/local-development/cli-workflows "Supabase CLI Workflows and pg-delta"
[7]: https://supabase.com/docs/guides/database/connecting-to-postgres "Supabase PostgreSQL Connections"
