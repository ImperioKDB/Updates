# Scholars Phase 2.1.7 — Capture Preflight Checklist

**Status:** Prepared for a separately authorized capture; not executed.
**Author:** Manus AI

Do not begin until every item below passes. This checklist does not itself authorize production access or extraction.

## Authorization and environment

- [ ] Project owner approved schema-only capture from production `cmdglabohpttgfofcmqc`; no data export, student-record query, RPC call, production change, or staging restore is included.
- [ ] Database administrator supplied a dedicated PostgreSQL login through approved secret injection. It is not `postgres`, `service_role`, or a role inheriting elevated privileges.
- [ ] Administrator verified effective role flags, memberships, `CONNECT`, schema visibility, and absence of effective write/ownership/role-creation/RLS-bypass privileges. Do not grant `pg_read_all_data` as a shortcut.
- [ ] A non-writing connection check reports the expected project/database and role, `transaction_read_only=on`, and no effective write privileges on approved schemas. It reads only role/catalog metadata. If the check fails, stop.
- [ ] PostgREST configuration was separately obtained for both project refs using `rest:read` plus `data_api_config_read` only. No secret-read scope was granted. Raw API output was filtered in memory; JWT fields were not printed or saved.
- [ ] Administrator approved the application schema scope list from current project inventory. Include required app schemas; account separately for pg-delta’s managed-schema customizations, since an overly narrow `--schema` can omit them. Do not assume `public` alone is complete. [1]
- [ ] Runner is private and isolated, has Supabase CLI exactly `2.122.1`, PostgreSQL 17 `psql` and `pg_dump` (prefer same or newer patch than server 17.6), SHA-256, and a working Docker/container runtime for the CLI dump/local Supabase stack.
- [ ] `supabase --version` outputs `2.122.1`; `pg_dump --version` and `psql --version` report PostgreSQL 17.x. PostgreSQL `pg_dump` must not be from an older major than the server. The Supabase CLI dump wrapper uses pg_dump in a container and requires Docker; independent native `pg_dump` uses the installed client. [2] [3]

## Secret handling and private workspace

- [ ] Inject credentials via the approved secret manager/environment or a mode-0600 password file. Do not put passwords or bearer tokens in shell history, CLI arguments, logs, reports, chat, GitHub, or process output. Disable shell tracing and HTTP debug logging.
- [ ] Use a private output directory outside the repository, mode `0700`, with encrypted storage and access restricted to named reviewers. Example: `umask 077; mkdir -m 700 -p "$HOME/private/scholars-schema-capture"`.
- [ ] Keep production database credentials distinct from the Management API token. Do not link the CLI in a way that records a production password in repository configuration.

## Planned checks and commands — run only after the gates pass

Inject `SCHEMA_DB_URL` as a password-free PostgreSQL URI and `PGPASSFILE` as a securely created mode-0600 file, or use an approved secret-aware equivalent. Do not embed the password in the URI. Set `APPROVED_SCHEMAS` to the administrator-approved comma-separated schema list. Do not echo any variables. Confirm installed CLI help still accepts these flags before use.

```bash
set +x
umask 077
OUT="$HOME/private/scholars-schema-capture"
mkdir -m 700 -p "$OUT" "$OUT/declarative"
test "$(supabase --version)" = "2.122.1"
pg_dump --version
psql --version
docker info >/dev/null
```

First verify the connected identity and no-write posture using catalog metadata only. The administrator must also validate inherited and `PUBLIC` ACLs for every object in the approved schemas; a role name or `default_transaction_read_only` setting alone is not proof of effective read-only access.

```bash
export PGOPTIONS='-c default_transaction_read_only=on'
psql "$SCHEMA_DB_URL" -X -v ON_ERROR_STOP=1 -Atc \
  "SELECT current_database(), current_user, current_setting('transaction_read_only'), r.rolsuper, r.rolcreatedb, r.rolcreaterole, r.rolreplication, r.rolbypassrls, has_database_privilege(current_user,current_database(),'CREATE'), has_database_privilege(current_user,current_database(),'TEMP') FROM pg_roles r WHERE r.rolname=current_user"
```

Stop unless the result confirms the intended production database and dedicated role, transaction read-only is `on`, all elevated role flags and database `CREATE`/`TEMP` are false, and the DBA has separately confirmed no effective write/ownership privileges in the allowlisted schemas. Do not query application rows.

Generate the declarative tree privately with strict coverage and pg-delta mode:

```bash
supabase db schema declarative generate \
  --db-url "$SCHEMA_DB_URL" \
  --schema "$APPROVED_SCHEMAS" \
  --strict-coverage --experimental \
  --output-dir "$OUT/declarative"
```

Generate an independent SQL schema-only dump. Native `pg_dump --schema` patterns are repeated, so expand the approved list into one argument per schema:

```bash
IFS=',' read -r -a SCHEMAS <<< "$APPROVED_SCHEMAS"
PG_SCHEMA_ARGS=()
for schema in "${SCHEMAS[@]}"; do PG_SCHEMA_ARGS+=(--schema="$schema"); done
pg_dump --schema-only --no-password \
  --dbname "$SCHEMA_DB_URL" \
  "${PG_SCHEMA_ARGS[@]}" \
  --file "$OUT/schema-only.sql"
```

For native `pg_dump`, authentication is supplied through the secure `PGPASSFILE` or an approved non-logging prompt. If a wrapper/container is used, verify the credential mechanism is available privately to the subprocess and is not mounted into a shared location. The standard Supabase CLI dump is an alternate wrapper, but it invokes pg_dump in a container and requires Docker. [2] [3]

## Verification and retention

- [ ] Confirm both commands targeted production ref `cmdglabohpttgfofcmqc`; record sanitized command arguments without host/password.
- [ ] Inspect SQL for data-bearing statements, `COPY`, `INSERT`, student/person identifiers, secrets, JWTs, Vault contents, and unexpected managed/platform data. Stop and quarantine unexpected content; do not publish it.
- [ ] Record success/failure, timestamp, CLI and pg_dump versions, approved schema list, object counts, strict-coverage warnings, and sanitized exclusions. Do not record credentials or raw API responses.
- [ ] Hash every private artifact with `sha256sum`; keep hashes only in a private manifest with the artifacts. Never push raw artifacts or their hashes to `ImperioKDB/Updates`.
- [ ] Restrict artifacts to approved reviewers; set a short retention deadline and securely delete them when review completes.
- [ ] Do not restore to existing staging. A restore requires separate artifact review and explicit authorization in a genuinely isolated environment.

## References

[1]: https://supabase.com/docs/guides/local-development/declarative-database-schemas "Supabase Declarative Schema Coverage and Managed Objects"
[2]: https://supabase.com/docs/reference/cli/introduction "Supabase CLI Database Dump"
[3]: https://www.postgresql.org/docs/current/app-pgdump.html "PostgreSQL pg_dump Reference"
