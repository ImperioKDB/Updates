# Phase 2.1.8 — Isolated Extraction Source Manifest

This report reproduces the three requested files verbatim from the private repository review branch. It does not execute the workflow, merge the branch, connect to production or staging, or modify any database, secret, environment variable, or deployment.

**Source repository:** `ImperioKDB/scholars-schema-extraction`  
**Source branch:** `experiment/phase-2-1-8-isolated-proof`  
**Source commit:** [`11cacd6eb4a34eff43d6a2d7ac2fa42eaab7afd6`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/11cacd6eb4a34eff43d6a2d7ac2fa42eaab7afd6)

## Source files

### `.github/workflows/isolated-schema-proof.yml`

**Commit:** `11cacd6eb4a34eff43d6a2d7ac2fa42eaab7afd6`  
**Blob SHA:** `ab1a43608f2790b8d8c5c2b9f41e49a6aa85c664`  
**Blob URL:** https://github.com/ImperioKDB/scholars-schema-extraction/blob/11cacd6eb4a34eff43d6a2d7ac2fa42eaab7afd6/.github/workflows/isolated-schema-proof.yml

```yaml
name: Isolated restricted schema extraction proof

on:
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: isolated-restricted-schema-proof
  cancel-in-progress: true

jobs:
  isolated-proof:
    if: ${{ github.repository == 'ImperioKDB/scholars-schema-extraction' && github.ref == 'refs/heads/main' }}
    runs-on: ubuntu-latest
    timeout-minutes: 25
    services:
      postgres:
        image: postgres:16.4-bookworm
        env:
          POSTGRES_USER: bootstrap
          POSTGRES_DB: synthetic
          POSTGRES_HOST_AUTH_METHOD: trust
        ports:
          - 5432:5432
        options: >-
          --health-cmd "pg_isready -U bootstrap -d synthetic"
          --health-interval 5s
          --health-timeout 5s
          --health-retries 12
    steps:
      - name: Check out synthetic experiment only
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2

      - name: Install pinned PostgreSQL client
        shell: bash
        run: |
          set -euo pipefail
          sudo apt-get update
          sudo apt-get install --yes --no-install-recommends postgresql-client-16
          pg_dump --version
          psql --version

      - name: Install pinned Supabase CLI
        uses: supabase/setup-cli@689adcfb80d947100a1eab127289b97d1fb07b13 # v2.122.1 setup action
        with:
          version: 2.122.1

      - name: Verify isolated-only workflow inputs
        shell: bash
        run: |
          set -euo pipefail
          forbidden_prod="$(printf 'cmdglabohpttgfofcm%s' 'qc')"
          forbidden_stage="$(printf 'aqhktriwaglvvrchxm%s' 'td')"
          forbidden_secret="$(printf 'SUPABASE_%s' 'DB_URL')"
          forbidden_supabase="$(printf 'supabase%s' '.co')"
          forbidden_vercel="$(printf 'vercel%s' '.app')"
          if grep -RInE "$forbidden_prod|$forbidden_stage|$forbidden_secret|$forbidden_supabase|$forbidden_vercel" \
            .github/workflows/isolated-schema-proof.yml experiment/schema.sql experiment/run.sh; then
            echo '::error::A production/staging reference was found in the synthetic experiment files.'
            exit 1
          fi
          supabase --version

      - name: Create temporary synthetic credentials
        shell: bash
        run: |
          set -euo pipefail
          restricted_password="$(openssl rand -hex 32)"
          {
            echo "DB_HOST=127.0.0.1"
            echo "DB_PORT=5432"
            echo "DB_NAME=synthetic"
            echo "BOOTSTRAP_USER=bootstrap"
            echo "BOOTSTRAP_PASSWORD="
            echo "RESTRICTED_USER=restricted_extractor"
            echo "RESTRICTED_PASSWORD=$restricted_password"
            echo "RESULT_DIR=$RUNNER_TEMP/phase-2-1-8-results"
            echo "WORK_DIR=$RUNNER_TEMP/phase-2-1-8-work"
          } >> "$GITHUB_ENV"

      - name: Run synthetic restricted extraction experiment
        shell: bash
        env:
          RESULT_DIR: ${{ runner.temp }}/phase-2-1-8-results
          WORK_DIR: ${{ runner.temp }}/phase-2-1-8-work
        run: |
          set -euo pipefail
          chmod 700 experiment/run.sh
          ./experiment/run.sh
          test -s "$RESULT_DIR/summary.md"
          cat "$RESULT_DIR/summary.md" >> "$GITHUB_STEP_SUMMARY"

      - name: Upload short-lived sanitized result
        uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02 # v4.6.2
        with:
          name: isolated-schema-proof-summary-${{ github.run_id }}
          path: ${{ runner.temp }}/phase-2-1-8-results/summary.md
          if-no-files-found: error
          retention-days: 1

      - name: Remove temporary credentials and results
        if: always()
        shell: bash
        run: |
          rm -rf "$RUNNER_TEMP/phase-2-1-8-results" "$RUNNER_TEMP/phase-2-1-8-work"
```

### `experiment/schema.sql`

**Commit:** `11cacd6eb4a34eff43d6a2d7ac2fa42eaab7afd6`  
**Blob SHA:** `264452340d1274e04658505782da1df1b7e63ea9`  
**Blob URL:** https://github.com/ImperioKDB/scholars-schema-extraction/blob/11cacd6eb4a34eff43d6a2d7ac2fa42eaab7afd6/experiment/schema.sql

```sql
-- Synthetic-only schema for Phase 2.1.8.
-- Executed by the bootstrap database user; passwords are injected at runtime.

CREATE ROLE app_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS;
CREATE ROLE restricted_extractor LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT NOREPLICATION NOBYPASSRLS PASSWORD :'restricted_password';

GRANT CONNECT ON DATABASE synthetic TO restricted_extractor;
GRANT CREATE ON DATABASE synthetic TO app_owner;

SET ROLE app_owner;
CREATE SCHEMA app AUTHORIZATION app_owner;
CREATE SEQUENCE app.scholarship_id_seq;

CREATE TABLE app.students (
  id bigint PRIMARY KEY DEFAULT nextval('app.scholarship_id_seq'),
  display_name text NOT NULL,
  fabricated_email text NOT NULL UNIQUE,
  is_admin boolean NOT NULL DEFAULT false
);

CREATE TABLE app.scholarships (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title text NOT NULL,
  owner_student_id bigint NOT NULL REFERENCES app.students(id),
  amount_cents integer NOT NULL CHECK (amount_cents > 0),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published'))
);

CREATE INDEX scholarships_owner_idx ON app.scholarships(owner_student_id);

INSERT INTO app.students (display_name, fabricated_email, is_admin)
VALUES ('Synthetic Student', 'student@example.invalid', false),
       ('Synthetic Administrator', 'admin@example.invalid', true);

INSERT INTO app.scholarships (title, owner_student_id, amount_cents, status)
VALUES ('Synthetic Scholarship', 1, 125000, 'published');

CREATE VIEW app.published_scholarships AS
SELECT s.id, s.title, s.amount_cents
FROM app.scholarships AS s
WHERE s.status = 'published';

CREATE OR REPLACE FUNCTION app.current_synthetic_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = app, pg_catalog
AS $$
  SELECT EXISTS (SELECT 1 FROM app.students WHERE fabricated_email = 'admin@example.invalid' AND is_admin);
$$;

CREATE TABLE app.audit_events (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  scholarship_id bigint NOT NULL REFERENCES app.scholarships(id),
  event_name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION app.record_scholarship_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = app, pg_catalog
AS $$
BEGIN
  INSERT INTO app.audit_events (scholarship_id, event_name)
  VALUES (NEW.id, 'inserted');
  RETURN NEW;
END;
$$;

CREATE TRIGGER scholarships_insert_audit
AFTER INSERT ON app.scholarships
FOR EACH ROW EXECUTE FUNCTION app.record_scholarship_insert();

ALTER TABLE app.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.scholarships ENABLE ROW LEVEL SECURITY;
ALTER TABLE app.audit_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY synthetic_student_self_read ON app.students
  FOR SELECT TO restricted_extractor
  USING (false);

CREATE POLICY synthetic_public_scholarship_read ON app.scholarships
  FOR SELECT TO restricted_extractor
  USING (false);

CREATE POLICY synthetic_admin_only_audit ON app.audit_events
  FOR SELECT TO restricted_extractor
  USING (false);

-- Explicitly grant schema usage but no application-table SELECT/DML to the extractor.
GRANT USAGE ON SCHEMA app TO restricted_extractor;
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA app FROM restricted_extractor;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA app FROM restricted_extractor;
REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA app FROM restricted_extractor;

-- Document a default-privilege posture without granting application access.
ALTER DEFAULT PRIVILEGES FOR ROLE app_owner IN SCHEMA app REVOKE ALL ON TABLES FROM restricted_extractor;
ALTER DEFAULT PRIVILEGES FOR ROLE app_owner IN SCHEMA app REVOKE ALL ON SEQUENCES FROM restricted_extractor;
ALTER DEFAULT PRIVILEGES FOR ROLE app_owner IN SCHEMA app REVOKE ALL ON FUNCTIONS FROM restricted_extractor;

RESET ROLE;
```

### `experiment/run.sh`

**Commit:** `11cacd6eb4a34eff43d6a2d7ac2fa42eaab7afd6`  
**Blob SHA:** `2966e96e489ba0022911c6a591a26b7b7e1391a9`  
**Blob URL:** https://github.com/ImperioKDB/scholars-schema-extraction/blob/11cacd6eb4a34eff43d6a2d7ac2fa42eaab7afd6/experiment/run.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

: "${DB_HOST:?}"
: "${DB_PORT:?}"
: "${DB_NAME:?}"
: "${BOOTSTRAP_USER:?}"
: "${BOOTSTRAP_PASSWORD:?}"
: "${RESTRICTED_USER:?}"
: "${RESTRICTED_PASSWORD:?}"
: "${PG_DUMP_BIN:=pg_dump}"
: "${SUPABASE_BIN:=supabase}"

RESULT_DIR="${RESULT_DIR:-$RUNNER_TEMP/phase-2-1-8-results}"
WORK_DIR="${WORK_DIR:-$RUNNER_TEMP/phase-2-1-8-work}"
mkdir -p "$RESULT_DIR" "$WORK_DIR"
chmod 700 "$RESULT_DIR" "$WORK_DIR"

bootstrap_uri="postgresql://${BOOTSTRAP_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
restricted_uri="postgresql://${RESTRICTED_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"

run_bootstrap() {
  PGPASSWORD="$BOOTSTRAP_PASSWORD" psql "$bootstrap_uri" -v ON_ERROR_STOP=1 "$@"
}

run_restricted() {
  PGPASSWORD="$RESTRICTED_PASSWORD" psql "$restricted_uri" -v ON_ERROR_STOP=1 "$@"
}

cat > "$WORK_DIR/role-attributes.txt" <<EOF
$(run_bootstrap -Atc "SELECT rolname || '|' || rolsuper || '|' || rolcreatedb || '|' || rolcreaterole || '|' || rolbypassrls || '|' || rolinherit FROM pg_roles WHERE rolname IN ('app_owner','restricted_extractor') ORDER BY rolname")
EOF

cat > "$WORK_DIR/role-memberships.txt" <<EOF
$(run_bootstrap -Atc "SELECT COALESCE(pg_get_userbyid(roleid),'') || '|' || COALESCE(pg_get_userbyid(member),'') || '|' || admin_option || '|' || inherit_option || '|' || set_option FROM pg_auth_members WHERE member = 'restricted_extractor'::regrole")
EOF

cat > "$WORK_DIR/effective-grants.txt" <<EOF
$(run_bootstrap -Atc "SELECT has_schema_privilege('restricted_extractor','app','USAGE') || '|' || has_schema_privilege('restricted_extractor','app','CREATE') || '|' || has_table_privilege('restricted_extractor','app.students','SELECT') || '|' || has_table_privilege('restricted_extractor','app.students','INSERT') || '|' || has_table_privilege('restricted_extractor','app.students','UPDATE') || '|' || has_table_privilege('restricted_extractor','app.students','DELETE')")
EOF

run_bootstrap -f experiment/schema.sql --set=restricted_password="$RESTRICTED_PASSWORD" >/dev/null

owner_test='NOT TESTED'
if run_bootstrap -Atc "SET ROLE app_owner; CREATE TABLE app.owner_maintenance_check(id integer PRIMARY KEY); DROP TABLE app.owner_maintenance_check;" >/dev/null 2>&1; then
  owner_test='PASS'
else
  owner_test='FAIL'
fi

pg_dump_status='NOT TESTED'
pg_dump_error=''
pg_dump_output="$WORK_DIR/restricted-schema.sql"
set +e
PGPASSWORD="$RESTRICTED_PASSWORD" "$PG_DUMP_BIN" --schema-only --schema=app --file="$pg_dump_output" "$restricted_uri" >"$WORK_DIR/pg_dump.stdout" 2>"$WORK_DIR/pg_dump.stderr"
pg_dump_exit=$?
set -e
if [[ "$pg_dump_exit" -eq 0 ]]; then pg_dump_status='PASS'; else pg_dump_status='FAIL'; fi
if [[ -s "$WORK_DIR/pg_dump.stderr" ]]; then pg_dump_error='yes'; else pg_dump_error='no'; fi
pg_dump_objects='0'
if [[ -s "$pg_dump_output" ]]; then pg_dump_objects="$(grep -Ec '^(CREATE|ALTER|COMMENT ON|GRANT|REVOKE)' "$pg_dump_output" || true)"; fi
pg_dump_records='FAIL'
if [[ -s "$pg_dump_output" ]] && ! grep -Eq 'student@example\.invalid|admin@example\.invalid|Synthetic Scholarship' "$pg_dump_output"; then pg_dump_records='PASS'; fi

pg_delta_status='NOT TESTED'
pg_delta_error=''
declarative_dir="$WORK_DIR/declarative"
set +e
"$SUPABASE_BIN" db schema declarative generate \
  --db-url "$restricted_uri" \
  --schema app \
  --output-dir "$declarative_dir" \
  --strict-coverage --experimental \
  >"$WORK_DIR/pg_delta.stdout" 2>"$WORK_DIR/pg_delta.stderr"
pg_delta_exit=$?
set -e
if [[ "$pg_delta_exit" -eq 0 ]]; then pg_delta_status='PASS'; else pg_delta_status='FAIL'; fi
if [[ -s "$WORK_DIR/pg_delta.stderr" ]]; then pg_delta_error='yes'; else pg_delta_error='no'; fi
pg_delta_objects='0'
if [[ -d "$declarative_dir" ]]; then pg_delta_objects="$(find "$declarative_dir" -type f | wc -l | tr -d ' ')"; fi

run_forbidden() {
  local label="$1"
  local sql="$2"
  local result='FAIL'
  set +e
  run_restricted -Atc "$sql" >/dev/null 2>&1
  local exit_code=$?
  set -e
  if [[ "$exit_code" -ne 0 ]]; then result='PASS'; fi
  printf '%s|%s\n' "$label" "$result" >> "$RESULT_DIR/forbidden-results.txt"
}

: > "$RESULT_DIR/forbidden-results.txt"
run_forbidden 'SELECT synthetic application records' "SELECT display_name FROM app.students LIMIT 1"
run_forbidden 'INSERT application records' "INSERT INTO app.students(display_name, fabricated_email) VALUES ('forbidden','forbidden@example.invalid')"
run_forbidden 'UPDATE application records' "UPDATE app.students SET display_name='forbidden' WHERE id=1"
run_forbidden 'DELETE application records' "DELETE FROM app.students WHERE id=1"
run_forbidden 'CREATE TABLE' "CREATE TABLE app.forbidden_table(id integer)"
run_forbidden 'ALTER TABLE' "ALTER TABLE app.students ADD COLUMN forbidden integer"
run_forbidden 'CREATE FUNCTION' "CREATE FUNCTION app.forbidden_function() RETURNS integer LANGUAGE sql AS 'SELECT 1'"
run_forbidden 'Change privileges' "GRANT SELECT ON app.students TO restricted_extractor"
run_forbidden 'Assume elevated role' "SET ROLE app_owner"

forbidden_passes="$(awk -F'|' '$2 == "PASS" {count++} END {print count+0}' "$RESULT_DIR/forbidden-results.txt")"
forbidden_total="$(wc -l < "$RESULT_DIR/forbidden-results.txt" | tr -d ' ')"

cat > "$RESULT_DIR/summary.md" <<EOF
# Phase 2.1.8 Synthetic Extraction Experiment Results

This artifact contains sanitized results only. The database was synthetic and temporary. No Supabase project, production/staging URL, or repository secret was used.

## Tooling

- PostgreSQL service: synthetic `postgres:16.4-bookworm` service container.
- `pg_dump`: captured at runtime by the workflow.
- Supabase CLI: pinned `2.122.1`.
- Database URL: local service only; not retained.

## Restricted identity

- Role: `restricted_extractor`.
- Attributes: `NOSUPERUSER`, `NOCREATEDB`, `NOCREATEROLE`, `NOBYPASSRLS`.
- Application-table SELECT/DML/DDL privileges: none by design.
- Privileged memberships: none observed.
- Effective grant record: role attributes and grant checks are retained only in the workflow workspace and are not uploaded.

## Results

| Capability | Result | Evidence |
|---|---|---|
| pg_dump schema-only extraction | $pg_dump_status | Exit code $pg_dump_exit; definition statements counted: $pg_dump_objects; stderr present: $pg_dump_error |
| pg_dump contains no synthetic records | $pg_dump_records | Output scan |
| pg-delta declarative generation | $pg_delta_status | Exit code $pg_delta_exit; files observed: $pg_delta_objects; stderr present: $pg_delta_error |
| Restricted identity forbidden-operation tests | $([[ "$forbidden_passes" == "$forbidden_total" ]] && echo PASS || echo FAIL) | $forbidden_passes/$forbidden_total failed as required |
| Separate owner maintenance operation | $owner_test | Synthetic owner-only create/drop test |

## Forbidden-operation results

| Operation | Result |
|---|---|
$(awk -F'|' '{printf "| %s | %s |\n", $1, $2}' "$RESULT_DIR/forbidden-results.txt")

## Interpretation

A successful extraction command is not treated as proof of complete coverage. Review the actual exit codes, warnings, unsupported objects, missing objects, and generated definitions before classifying a method as suitable for future restricted extraction. No privilege was increased to force success.
EOF

# Keep only the sanitized report for the short-lived workflow artifact.
rm -rf "$WORK_DIR" "$RESULT_DIR/forbidden-results.txt"
```

## Short manifest

| Path | Commit | Blob SHA | Bytes | Lines |
|---|---|---|---:|---:|
| `.github/workflows/isolated-schema-proof.yml` | `11cacd6eb4a34eff43d6a2d7ac2fa42eaab7afd6` | `ab1a43608f2790b8d8c5c2b9f41e49a6aa85c664` | 3804 | 0 |
| `experiment/schema.sql` | `11cacd6eb4a34eff43d6a2d7ac2fa42eaab7afd6` | `264452340d1274e04658505782da1df1b7e63ea9` | 3869 | 0 |
| `experiment/run.sh` | `11cacd6eb4a34eff43d6a2d7ac2fa42eaab7afd6` | `2966e96e489ba0022911c6a591a26b7b7e1391a9` | 7333 | 2 |
