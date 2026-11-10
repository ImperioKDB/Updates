# SCHOLARS_A0_8_2_EXTRACTION_WORKFLOW_SECURITY_REFINEMENT_2026-11

**Prepared by:** Manus AI  
**Date:** 10 November 2026  
**Status:** Review complete; no production or staging database was accessed.

## 1. Executive summary

**Decision: NO-GO. Do not create or populate `SUPABASE_DB_URL`, and do not run the current workflow.** The workflow is correctly scoped to a schema-only `supabase db dump` by default, but neither that command nor its input secret enforces read-only database privileges. The production-reference check is only a substring test, so it does not prove which endpoint, database, or role the supplied connection string selects. These gaps are material because a successful schema dump can expose functions, security logic, object names, and grants, and the connection credential could otherwise be used for operations beyond the intended dump.

Supabase does offer a provider-managed read-only Postgres endpoint through Read Replicas. This is the strongest documented way to prevent writes to the connected database, but it still allows SQL reads of application rows and can lag behind the primary. It must therefore be paired with a dedicated, non-owner login with no application-table `SELECT`, no privileged role memberships, and no indirect data-exposing functions or views. Supabase’s public documentation does not give a certified privilege recipe for running the pinned CLI dump with that role. That compatibility and access boundary must be demonstrated away from production before the workflow is revised.

No production or staging connection, query, role change, secret inspection, workflow run, or artifact generation was performed. The existing workflow YAML is left unchanged. The private extraction README should be amended to place the owner on hold; the previous A0.8.1 instruction to add the secret and run the job is superseded by this report.

## 2. Exact A0.8.1 workflow findings

I reviewed the current [`schema-only.yml`](https://github.com/ImperioKDB/scholars-schema-extraction/blob/main/.github/workflows/schema-only.yml), its [`README.md`](https://github.com/ImperioKDB/scholars-schema-extraction/blob/main/README.md), and the [A0.8.1 setup report](https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_A0_8_1_PRIVATE_SCHEMA_EXTRACTION_WORKFLOW_SETUP_2026-11.md).

The workflow’s safeguards are worth retaining: `workflow_dispatch` is the only trigger; the job checks the exact repository and `main` ref; the operator must type the expected production project reference; the Supabase CLI version and both actions are pinned; no checkout is performed; `GITHUB_TOKEN` has `contents: read` only; output from the dump is suppressed; runner temporary files are cleaned up; the artifact retention is one day; and there is no migration, deployment, import, or explicit data/role dump step. The CLI documentation confirms that a default `supabase db dump` is schema-only, with no row data or custom roles, and that it applies additional exclusions for managed schemas.[1]

Specifically, CLI `2.122.1` is installed using `supabase/setup-cli@689adcfb80d947100a1eab127289b97d1fb07b13`, and `actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02` is pinned to an immutable commit.

Two current checks do not establish the safety properties claimed in the README. First, the workflow checks whether the entire secret string contains `cmdglabohpttgfofcmqc`. This can match a username, password, query parameter, or unrelated text and does not establish an exact host, port, database, or login role. The operator’s typed confirmation only checks their input against a constant; it is not a check of the database endpoint. Second, nothing verifies that the connection uses a restricted PostgreSQL role, lacks table privileges, or connects to a read-only replica. The command is schema-only, but the credential itself is not constrained by that command.

The secret was reported as absent in A0.8.1. This review did not list, create, populate, or retrieve it. The earlier A0.8.1 report’s “Exact next owner action” and the current README’s invitation to add the secret and start the workflow must not be followed until the blockers below are resolved.

## 3. Safe database-access options and limitations

### Supabase Read Replica

Supabase documents Read Replicas as read-only Postgres databases with dedicated database endpoints. The replica accepts reads but not writes, while replication from the primary is asynchronous and can lag.[2] A connection to a replica is therefore the best provider-enforced control against accidental DML or DDL against the primary, provided the connection string is for the replica endpoint selected in the Supabase Dashboard and not the primary.

A replica is **not schema-only**. Its login can still issue `SELECT` against any application tables and views for which it has privileges. It may also expose data through callable `SECURITY DEFINER` routines or views even when direct table access is absent. A replica also represents the schema as of its replication state, so the owner must accept and account for lag. Supabase’s documentation describes the endpoints and read-only behavior, but does not certify this exact `supabase db dump` version/role combination. Prove compatibility using a disposable non-production database or local test before relying on it. Provisioning a replica may have cost and is not authorized by this task.

### Dedicated restricted role on the primary

A PostgreSQL login with no object ownership, no elevated role attributes, no membership in privileged roles, and no write privileges can be prevented by PostgreSQL grants from directly changing database objects or table rows. A carefully restricted role can also lack `SELECT` on user tables. However, a primary connection is not provider-enforced read-only: a missed grant, inherited membership, object ownership, or executable data-exposing routine can defeat the intended boundary. A0.8.1 did not establish that such a role exists or that the workflow uses one.

Using a dedicated role on the primary is only a candidate if the owner has verified all its effective memberships and grants, and if tests show the pinned schema-only dump works without granting user-table `SELECT`. Do not use the project `postgres` login, `service_role`, an owner role, or a role that can become one of them.

### `READ ONLY` transactions and Supabase SQL Editor

A transaction-level `READ ONLY` flag is not a substitute for least-privilege credentials. PostgreSQL documents that it restricts listed SQL write commands in that transaction, but calls this a high-level notion that does not prevent all writes to disk. Session defaults can be overridden by transaction characteristics.[3] It does not constrain later transactions or prevent a client that controls the session from choosing a different mode. A transaction flag alone therefore does not enforce a read-only credential.

Supabase’s SQL Editor should not be treated as a low-privilege extraction identity. Supabase documents that Dashboard SQL Editor queries execute as `postgres`, which is an administrator role.[4] It is not a safe replacement for a dedicated least-privilege connection.

## 4. Minimum PostgreSQL privileges and what they can prevent

There is no single built-in PostgreSQL “schema-only dump” role attribute. The design should start from a dedicated login, not from a broad read-only role that has `SELECT` on every table.

For a schema-only `pg_dump`, the expected minimum is a login able to connect to the target database and read the catalog metadata needed to enumerate and render the selected schema objects. PostgreSQL’s system catalogs store schema metadata, and `pg_dump` uses `SELECT` statements internally.[5] The upstream PostgreSQL and Supabase CLI documentation do not publish a complete grant-by-grant matrix for this exact Supabase CLI release. Therefore, the exact requirement—especially whether any schema `USAGE` or non-catalog privilege is required—must be tested in a disposable non-production database. Do **not** respond to a permission error by granting `SELECT` on all application tables in production.

A candidate account should have `LOGIN` and `CONNECT` only, plus narrowly scoped metadata access demonstrated to be necessary. It should have no ownership of database objects, no schema or database `CREATE`, no `TEMPORARY`, and no table, view, materialized-view, foreign-table, sequence, or large-object privileges that enable row or payload access. It should have no `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`, `REFERENCES`, or `TRIGGER` privileges. PostgreSQL makes object-altering and object-destruction rights inherent in ownership; ordinary grants do not make an unprivileged role an owner.[6]

The login must be `NOSUPERUSER`, `NOCREATEDB`, `NOCREATEROLE`, `NOREPLICATION`, and `NOBYPASSRLS`, and must not be a member of any privileged role. `CREATEROLE` is particularly inappropriate because it grants role-administration powers; role membership can also convey inherited permissions or permit `SET ROLE` when the membership’s `SET` option is enabled.[7] [8] With no membership chain, the login cannot use `SET ROLE` to become a more privileged role. Do not grant `ADMIN`, `SET`, or `INHERIT` membership options to this login.

These controls address the requested risks as follows:

- **Direct DML:** absent table and sequence write privileges prevent direct inserts, updates, deletes, truncates, and sequence changes. A read replica independently prevents writes to the replicated database.
- **DDL and grants:** no object ownership, schema/database `CREATE`, grant options, `CREATEROLE`, or privileged membership prevents ordinary DDL and privilege changes. Ownership cannot be replaced by an ordinary grant.[6]
- **Role escalation:** no `SUPERUSER`, `CREATEROLE`, `BYPASSRLS`, or membership/`SET` path prevents switching into a more privileged role.[7] [8] [9]
- **Application rows:** no `SELECT` on tables and table-like objects prevents ordinary row reads, regardless of whether RLS is enabled. RLS is not a replacement for the privilege boundary: without a policy, RLS defaults to deny only after SQL privileges permit access; table owners, superusers, and `BYPASSRLS` roles normally bypass policies.[10]
- **Indirect data exposure:** absence of table `SELECT` is not by itself proof that no rows can be read. Before the credential is used, review any views, `SECURITY DEFINER` functions/procedures, foreign-data objects, and `PUBLIC`/role `EXECUTE` grants that could expose rows or cause writes. Avoid global revokes of `PUBLIC` privileges on production objects as a workaround; those could alter application behavior.
- **Auth and Storage data:** absence of `SELECT` on managed schemas/tables prevents direct catalog-table row reads by this login, but any relevant indirect access path must also be excluded. The schema dump’s managed-schema exclusion is a separate output filter, not a database authorization boundary.

The constraints are enforceable only if they are applied to the effective role and its accessible objects. No such production role or grant audit was performed here.

## 5. Reliable production-target verification

Substring matching must be replaced with pre-connection validation of the parsed connection URI. The validator must parse the secret without printing or logging it and compare the **entire endpoint tuple** against independently approved values copied from the production project’s Supabase Dashboard **Connect** panel: connection mode/source (primary or named replica), host, port, database name, and username. It must reject any mismatch before invoking `supabase db dump`.

For a direct connection, the standard Supabase form embeds the project reference in `db.<project-ref>.supabase.co`; for a shared pooler connection, the pooler host is regional and the username includes the project reference. Supabase instructs users to copy the actual host, port, and username from the Dashboard rather than reconstructing them.[11] Thus, compare all those fields exactly. If the chosen endpoint supports it, require TLS certificate and hostname verification with Supabase’s database root certificate (`sslmode=verify-full` and `sslrootcert`), not encryption-only `sslmode=require`; Supabase warns that `require` does not verify server identity.[11]

A complete endpoint comparison is a preflight guard, not a provider-signed project identity assertion. Do not use a database name such as `postgres` alone as project proof; that name is shared across projects. No documented built-in SQL identity field that independently returns the Supabase project reference was found. The authoritative starting point is the Dashboard connection string for the intended source, combined with exact URI-field validation and TLS verification. Never emit the URI, password, or parsed secret fields to Actions logs.

The workflow should also reject known administrator login names and require the intended dedicated dump role. Where a replica is selected, the expected hostname/source must be for that replica, not simply any hostname containing the production reference. Because the existing workflow does none of these checks and the current secret is absent, target verification is not currently adequate.

## 6. Schema extraction coverage and exclusions

The Supabase CLI documents `db dump` as invoking `pg_dump` with extra filters for Supabase-managed schemas. The default command produces schema definitions, not row data, and does not include custom roles. By default it ignores `auth`, `storage`, and schemas created by extensions.[1] In addition, PostgreSQL describes `--schema-only` as object definitions without data or statistics.[5]

For included, non-filtered application schemas, expect definitions such as tables, columns, constraints, indexes, sequences, functions/procedures, triggers, views, materialized-view definitions, and RLS policies. Definitions can expose implementation and security logic. The dump will not contain table rows, materialized-view contents, large-object contents, Storage object bytes, or custom PostgreSQL role definitions. PostgreSQL’s `pg_dump` normally includes object access-control statements unless `--no-acl` is used; the current command does not request that exclusion.[5] Supabase’s public `db dump` reference does not promise a complete preservation contract for every grant/default-privilege edge case after its managed-schema and role filters. Inspect any future private artifact before treating its ACL or default-privilege statements as complete.

Important omissions and qualifications are:

- **Auth and Storage:** the managed `auth` and `storage` schemas are excluded by default, so their definitions, records, and policies are not represented by this dump. Supabase specifically calls out custom triggers and RLS policies on those schemas as needing separate treatment. A trigger on an Auth/Storage object may be absent even when its function is in an included application schema, because the trigger definition belongs to the excluded schema.[1] [12]
- **Extensions:** extension-created schemas are excluded. The result is not a reliable inventory of all enabled extensions, their versions, configuration, or extension-owned objects; confirm those separately through authorized project configuration and the appropriate database metadata process.[1] [13]
- **Roles and grants:** custom role definitions are excluded unless the separate `--role-only` mode is used, which this workflow intentionally does not invoke. Object ACLs and default ACLs must not be assumed to reconstruct all role memberships, role attributes, inherited rights, or project-wide defaults. Supabase documents a separate role-only dump step in its backup guide.[1] [5] [12]
- **Views and materialized views:** schema definitions may be present for included schemas, but materialized-view data is not. A view definition is still a potential data-disclosure path when granted to a role.
- **Project configuration and service data:** the SQL schema dump is not a backup of Auth provider and redirect settings, API keys, project secrets, Storage objects, all bucket records/configuration, Edge Function secrets, or other Dashboard settings. Database schema alone is not a complete Supabase project export.

For those reasons, the output is a bounded schema snapshot only, not a full backup or a complete staging-reconstruction package. Do not compensate by adding data-only or role-only flags to this workflow without separate scope and authorization.

## 7. Artifact confidentiality assessment

The extraction repository was confirmed `PRIVATE`; the A0.8.1 report says no collaborators were added during setup. The current effective collaborator/team access was not inventoried in this task. GitHub states that an authenticated person with repository read access can download workflow artifacts. Artifact access therefore follows the repository’s reader boundary; the workflow cannot grant artifact access only to the person who manually launched it.[14] [15]

A one-day retention setting is appropriate and is the minimum configurable per-artifact retention in GitHub’s documented range. It reduces exposure time but does not prevent an authorized repository reader from downloading the artifact during that day. Delete it earlier after review if no longer needed. Keep repository access limited to the owner and explicitly trusted maintainers, keep `main` write access tightly controlled, and do not put the SQL in commits, PRs, Issues, public file hosts, or the public Updates repository. The public A0.8.2 report contains no schema artifact, connection string, secret, or production data.

The current workflow’s generic error messages, suppressed dump output, and cleanup steps are appropriate static safeguards. They do not change who can download an uploaded artifact. Runtime behavior has not been tested and must not be described as verified.

## 8. Recommended changes

1. **Immediately amend the private README with a HOLD notice.** It currently tells the owner to add `SUPABASE_DB_URL` and run the workflow. Replace that instruction with the NO-GO conditions in this report. This documentation-only correction is justified; it does not touch the workflow, secret, database, or artifact.
2. **Do not change the workflow YAML yet.** Before implementing a new target guard, the owner must choose a documented source (preferably an existing read replica if write prevention is required), decide the exact expected connection tuple, and verify TLS behavior and the candidate role against a disposable non-production database using the pinned CLI. The test must demonstrate success without table-row privileges and must not rely on production access.
3. **Before any future production run,** use a dedicated role with no ownership or privileged membership and no direct or indirect application-row access; require an exact connection-field preflight and TLS server verification; confirm the target source and the private repository reader list; and keep the artifact one-day or shorter by manual deletion. No work in this task grants permission to create the role, provision a replica, populate a secret, or run the workflow.

## 9. Explicit remaining blockers

- `SUPABASE_DB_URL` remains absent, and its existence/value was not inspected.
- No dedicated restricted role, its membership graph, effective grants, or current Auth/Storage access paths have been confirmed.
- Read Replica availability for this project, the target replica endpoint, and the owner’s acceptance of replication lag or possible provisioning cost are unknown.
- No non-production test has shown that CLI `2.122.1` completes the schema-only dump with no user-table `SELECT` privilege.
- The workflow’s current substring check does not securely validate the target or privilege level; no workflow change was implemented because the correct endpoint/mode and tested role are not yet established.
- Current repository readers and write access were not independently reviewed in this investigation.
- This dump intentionally omits managed schemas, row data, custom role definitions, and project/service configuration; it cannot alone satisfy a complete reconstruction requirement.

## 10. GO/NO-GO decision

**NO-GO: the owner cannot safely configure `SUPABASE_DB_URL` and run the workflow in its current form.** The safe next step is owner review of this report and the README HOLD correction, followed by a separately authorized non-production design test. Reconsider GO only after a supported read-only source is selected, a zero-row-access role is shown to work with the pinned CLI, the endpoint tuple and TLS identity are verified before connection, the private repository access boundary is confirmed, and the workflow is updated and reviewed. No production action is authorized by this report.

## References

[1]: https://supabase.com/docs/reference/cli/supabase-db-dump "Supabase CLI db dump reference"
[2]: https://supabase.com/docs/guides/platform/read-replicas "Supabase Read Replicas"
[3]: https://www.postgresql.org/docs/current/sql-set-transaction.html "PostgreSQL SET TRANSACTION"
[4]: https://supabase.com/docs/guides/database/postgres/roles "Supabase Postgres Roles"
[5]: https://www.postgresql.org/docs/current/app-pgdump.html "PostgreSQL pg_dump"
[6]: https://www.postgresql.org/docs/current/ddl-priv.html "PostgreSQL Privileges"
[7]: https://www.postgresql.org/docs/current/role-attributes.html "PostgreSQL Role Attributes"
[8]: https://www.postgresql.org/docs/current/role-membership.html "PostgreSQL Role Membership"
[9]: https://www.postgresql.org/docs/current/sql-set-role.html "PostgreSQL SET ROLE"
[10]: https://www.postgresql.org/docs/current/ddl-rowsecurity.html "PostgreSQL Row Security Policies"
[11]: https://supabase.com/docs/guides/database/connecting-to-postgres "Supabase Connecting to Postgres"
[12]: https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore "Supabase Backup and Restore using the CLI"
[13]: https://supabase.com/docs/guides/database/extensions "Supabase Postgres Extensions Overview"
[14]: https://docs.github.com/actions/managing-workflow-runs/downloading-workflow-artifacts "GitHub Downloading Workflow Artifacts"
[15]: https://docs.github.com/actions/tutorials/store-and-share-data "GitHub Store and Share Data with Workflow Artifacts"
