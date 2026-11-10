# Scholars Phase 2.1.8.1 — Corrected Source Manifest

**Purpose:** Publish the complete, exact contents of the corrected Phase 2.1.8.1 source files for independent code review.

**Source repository:** [`ImperioKDB/scholars-schema-extraction`](https://github.com/ImperioKDB/scholars-schema-extraction)  
**Corrected commit:** [`1621ec09875489dd6aab99bc30ea8197f5fb7984`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/1621ec09875489dd6aab99bc30ea8197f5fb7984)

The three files below were retrieved directly from the corrected commit. Their contents are reproduced verbatim, including comments, shell logic, whitespace, and trailing newlines. No source file was modified, executed, or committed to the source repository.

## Source files and Git blob verification

### `.github/workflows/isolated-schema-proof.yml`

- **Git blob SHA:** `ab1a43608f2790b8d8c5c2b9f41e49a6aa85c664`
- **Corrected commit:** `1621ec09875489dd6aab99bc30ea8197f5fb7984`
- **Byte length:** `3804`

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

- **Git blob SHA:** `338261db6d6b2388f23a6a3a738bb6e0f5900433`
- **Corrected commit:** `1621ec09875489dd6aab99bc30ea8197f5fb7984`
- **Byte length:** `4156`

```sql
-- Synthetic-only schema for Phase 2.1.8.
-- Executed by the bootstrap database user; passwords are injected at runtime.

CREATE ROLE app_owner NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS;
CREATE ROLE restricted_extractor LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT NOREPLICATION NOBYPASSRLS PASSWORD :'restricted_password';
CREATE ROLE rls_probe NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT NOREPLICATION NOBYPASSRLS;

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

CREATE POLICY synthetic_rls_probe_denied ON app.students
  FOR SELECT TO rls_probe
  USING (false);

CREATE POLICY synthetic_public_scholarship_read ON app.scholarships
  FOR SELECT TO restricted_extractor
  USING (false);

CREATE POLICY synthetic_admin_only_audit ON app.audit_events
  FOR SELECT TO restricted_extractor
  USING (false);

-- Explicitly grant schema usage but no application-table SELECT/DML to the extractor.
GRANT USAGE ON SCHEMA app TO restricted_extractor;
GRANT USAGE ON SCHEMA app TO rls_probe;
GRANT SELECT ON app.students TO rls_probe;
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

- **Git blob SHA:** `b915a67d24bb60b5328d79648341a8741c6ef0dd`
- **Corrected commit:** `1621ec09875489dd6aab99bc30ea8197f5fb7984`
- **Byte length:** `12949`

```bash
#!/usr/bin/env bash
set -euo pipefail

: "${DB_HOST:?}"
: "${DB_PORT:?}"
: "${DB_NAME:?}"
: "${BOOTSTRAP_USER:?}"
BOOTSTRAP_PASSWORD="${BOOTSTRAP_PASSWORD:-}"
if [[ -n "$BOOTSTRAP_PASSWORD" ]]; then
  echo 'BOOTSTRAP_PASSWORD must be empty when the synthetic service uses trust authentication.' >&2
  exit 1
fi
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

# The service uses POSTGRES_HOST_AUTH_METHOD=trust, so the bootstrap password is
# intentionally empty. The restricted role still receives a generated password.
run_bootstrap -f experiment/schema.sql --set=restricted_password="$RESTRICTED_PASSWORD" >/dev/null

# Inspect role state only after schema.sql has created all roles and objects.
run_bootstrap -Atc "SELECT rolname || '|' || rolsuper || '|' || rolcreatedb || '|' || rolcreaterole || '|' || rolbypassrls || '|' || rolinherit FROM pg_roles WHERE rolname IN ('app_owner','restricted_extractor','rls_probe') ORDER BY rolname" > "$WORK_DIR/role-attributes.txt"
run_bootstrap -Atc "SELECT COALESCE(pg_get_userbyid(roleid),'') || '|' || COALESCE(pg_get_userbyid(member),'') || '|' || admin_option || '|' || inherit_option || '|' || set_option FROM pg_auth_members WHERE member IN ('restricted_extractor'::regrole, 'rls_probe'::regrole) ORDER BY member, roleid" > "$WORK_DIR/role-memberships.txt"
run_bootstrap -Atc "SELECT has_schema_privilege('restricted_extractor','app','USAGE') || '|' || has_schema_privilege('restricted_extractor','app','CREATE') || '|' || has_table_privilege('restricted_extractor','app.students','SELECT') || '|' || has_table_privilege('restricted_extractor','app.students','INSERT') || '|' || has_table_privilege('restricted_extractor','app.students','UPDATE') || '|' || has_table_privilege('restricted_extractor','app.students','DELETE')" > "$WORK_DIR/effective-grants.txt"

# Establish a successful restricted-identity connection before any denial test.
restricted_connection_status='FAIL'
restricted_connection_identity=''
set +e
restricted_connection_identity="$(run_restricted -Atc "SELECT current_user || '|' || current_database()" 2>"$WORK_DIR/restricted-connection.stderr")"
restricted_connection_exit=$?
set -e
if [[ "$restricted_connection_exit" -eq 0 && "$restricted_connection_identity" == "restricted_extractor|synthetic" ]]; then
  restricted_connection_status='PASS'
fi
if [[ "$restricted_connection_status" != 'PASS' ]]; then
  echo 'Restricted identity connection could not be established; stopping before denial tests.' >&2
  exit 1
fi

owner_test='NOT TESTED'
if run_bootstrap -Atc "SET ROLE app_owner; CREATE TABLE app.owner_maintenance_check(id integer PRIMARY KEY); DROP TABLE app.owner_maintenance_check;" >/dev/null 2>&1; then
  owner_test='PASS'
else
  owner_test='FAIL'
fi

# Demonstrate RLS separately: rls_probe has SELECT privilege, but its false policy
# must return zero rows. This is not the restricted identity and not a privilege test.
rls_select_privilege='false'
rls_visible_rows='NOT TESTED'
if [[ "$(run_bootstrap -Atc "SELECT has_table_privilege('rls_probe','app.students','SELECT')")" == 't' ]]; then
  rls_select_privilege='true'
fi
set +e
rls_visible_rows="$(run_bootstrap -Atc "SET ROLE rls_probe; SELECT count(*) FROM app.students" 2>"$WORK_DIR/rls.stderr")"
rls_exit=$?
set -e
rls_status='FAIL'
if [[ "$rls_select_privilege" == 'true' && "$rls_exit" -eq 0 && "$rls_visible_rows" == '0' ]]; then
  rls_status='PASS'
fi

expected_objects=(
  'app.students'
  'app.scholarships'
  'app.scholarship_id_seq'
  'scholarships_owner_idx'
  'app.published_scholarships'
  'app.current_synthetic_admin'
  'app.audit_events'
  'app.record_scholarship_insert'
  'app.scholarships_insert_audit'
  'synthetic_student_self_read'
  'synthetic_rls_probe_denied'
  'synthetic_public_scholarship_read'
  'synthetic_admin_only_audit'
)
printf '%s\n' "${expected_objects[@]}" > "$WORK_DIR/expected-objects.txt"

extract_diagnostic() {
  local file="$1"
  if [[ ! -s "$file" ]]; then
    printf 'none'
    return
  fi
  # Keep only diagnostic words; never emit connection strings or raw output.
  tr '\n' ' ' < "$file" | sed -E 's/[[:space:]]+/ /g; s/[^[:alnum:]_.: -]//g' | cut -c1-400
}

record_object_inventory() {
  local label="$1"
  local target="$2"
  local name
  : > "$RESULT_DIR/${label}-objects.tsv"
  while IFS= read -r name; do
    if [[ -f "$target" ]]; then
      if grep -Eq "${name//./\\.}" "$target"; then
        printf '%s|present\n' "$name" >> "$RESULT_DIR/${label}-objects.tsv"
      else
        printf '%s|missing\n' "$name" >> "$RESULT_DIR/${label}-objects.tsv"
      fi
    elif [[ -d "$target" ]]; then
      if grep -RIlEq "${name//./\\.}" "$target" >/dev/null 2>&1; then
        printf '%s|present\n' "$name" >> "$RESULT_DIR/${label}-objects.tsv"
      else
        printf '%s|missing\n' "$name" >> "$RESULT_DIR/${label}-objects.tsv"
      fi
    else
      printf '%s|missing\n' "$name" >> "$RESULT_DIR/${label}-objects.tsv"
    fi
  done < "$WORK_DIR/expected-objects.txt"
}

pg_dump_output="$WORK_DIR/restricted-schema.sql"
set +e
PGPASSWORD="$RESTRICTED_PASSWORD" "$PG_DUMP_BIN" --schema-only --schema=app --file="$pg_dump_output" "$restricted_uri" >"$WORK_DIR/pg_dump.stdout" 2>"$WORK_DIR/pg_dump.stderr"
pg_dump_exit=$?
set -e
pg_dump_status='FAIL'
if [[ "$pg_dump_exit" -eq 0 ]]; then pg_dump_status='PASS'; fi
pg_dump_diagnostic="$(extract_diagnostic "$WORK_DIR/pg_dump.stderr")"
pg_dump_object_count='0'
if [[ -s "$pg_dump_output" ]]; then pg_dump_object_count="$(grep -Ec '^(CREATE|ALTER|COMMENT ON|GRANT|REVOKE)' "$pg_dump_output" || true)"; fi
pg_dump_data_statements='PASS'
if [[ -s "$pg_dump_output" ]] && grep -Eiq '^(COPY|INSERT INTO)|student@example\.invalid|admin@example\.invalid|Synthetic Scholarship' "$pg_dump_output"; then
  pg_dump_data_statements='FAIL'
fi
record_object_inventory 'pg-dump' "$pg_dump_output"

pg_delta_output="$WORK_DIR/declarative"
set +e
"$SUPABASE_BIN" db schema declarative generate \
  --db-url "$restricted_uri" \
  --schema app \
  --output-dir "$pg_delta_output" \
  --strict-coverage --experimental \
  >"$WORK_DIR/pg_delta.stdout" 2>"$WORK_DIR/pg_delta.stderr"
pg_delta_exit=$?
set -e
pg_delta_status='FAIL'
if [[ "$pg_delta_exit" -eq 0 ]]; then pg_delta_status='PASS'; fi
pg_delta_diagnostic="$(extract_diagnostic "$WORK_DIR/pg_delta.stderr")"
pg_delta_object_count='0'
if [[ -d "$pg_delta_output" ]]; then pg_delta_object_count="$(find "$pg_delta_output" -type f | wc -l | tr -d ' ')"; fi
pg_delta_data_statements='PASS'
if [[ -d "$pg_delta_output" ]] && grep -RIlEq '^(COPY|INSERT INTO)|student@example\.invalid|admin@example\.invalid|Synthetic Scholarship' "$pg_delta_output" >/dev/null 2>&1; then
  pg_delta_data_statements='FAIL'
fi
record_object_inventory 'pg-delta' "$pg_delta_output"

# Each denial test has its own SQLSTATE assertion. Connection failures, syntax
# errors, and missing-object errors are failures, never passes.
run_forbidden() {
  local label="$1"
  local sql="$2"
  local expected_sqlstate="$3"
  local key
  key="$(printf '%s' "$label" | tr '[:upper:] ' '[:lower:]_')"
  local stderr_file="$WORK_DIR/forbidden-${key}.stderr"
  local stdout_file="$WORK_DIR/forbidden-${key}.stdout"
  local observed_sqlstate='none'
  local result='FAIL'
  local reason='command_or_connection_failure'
  set +e
  run_restricted -v VERBOSITY=verbose -Atc "$sql" >"$stdout_file" 2>"$stderr_file"
  local exit_code=$?
  set -e
  observed_sqlstate="$(grep -Eo 'ERROR:[[:space:]]+[0-9A-Z]{5}:' "$stderr_file" | head -n1 | grep -Eo '[0-9A-Z]{5}' || true)"
  if [[ "$exit_code" -eq 0 ]]; then
    reason='unexpected_success'
  elif [[ "$observed_sqlstate" == '42P01' || "$observed_sqlstate" == '42601' ]]; then
    reason='missing_object_or_syntax_error'
  elif [[ "$observed_sqlstate" == "$expected_sqlstate" ]]; then
    result='PASS'
    reason='expected_privilege_denial'
  else
    reason='unexpected_sqlstate_or_connection_failure'
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$label" "$result" "$expected_sqlstate" "${observed_sqlstate:-none}" "$exit_code" "$reason" >> "$RESULT_DIR/forbidden-results.tsv"
}

: > "$RESULT_DIR/forbidden-results.tsv"
run_forbidden 'SELECT synthetic application records' "SELECT display_name FROM app.students LIMIT 1" '42501'
run_forbidden 'INSERT application records' "INSERT INTO app.students(display_name, fabricated_email) VALUES ('forbidden','forbidden@example.invalid')" '42501'
run_forbidden 'UPDATE application records' "UPDATE app.students SET display_name='forbidden' WHERE id=1" '42501'
run_forbidden 'DELETE application records' "DELETE FROM app.students WHERE id=1" '42501'
run_forbidden 'CREATE TABLE' "CREATE TABLE app.forbidden_table(id integer)" '42501'
run_forbidden 'ALTER TABLE' "ALTER TABLE app.students ADD COLUMN forbidden integer" '42501'
run_forbidden 'CREATE FUNCTION' "CREATE FUNCTION app.forbidden_function() RETURNS integer LANGUAGE sql AS 'SELECT 1'" '42501'
run_forbidden 'Change privileges' "GRANT SELECT ON app.students TO restricted_extractor" '42501'
run_forbidden 'Assume elevated role' "SET ROLE app_owner" '42501'

forbidden_passes="$(awk -F'\t' '$2 == "PASS" {count++} END {print count+0}' "$RESULT_DIR/forbidden-results.tsv")"
forbidden_total="$(wc -l < "$RESULT_DIR/forbidden-results.tsv" | tr -d ' ')"

cat > "$RESULT_DIR/summary.md" <<EOF
# Phase 2.1.8.1 Synthetic Extraction Correction Results

This artifact contains sanitized results only. The database was synthetic and temporary. No Supabase project, production/staging URL, or repository secret was used.

## Connection and RLS separation

| Check | Result | Evidence |
|---|---|---|
| Restricted identity connection | $restricted_connection_status | Identity/database: restricted_extractor/synthetic; exit: $restricted_connection_exit |
| RLS probe has SELECT privilege | $rls_select_privilege | Checked independently for rls_probe |
| RLS probe sees protected rows | $rls_status | rls_probe SELECT exit: $rls_exit; visible rows: $rls_visible_rows |
| Separate owner maintenance operation | $owner_test | Synthetic owner-only create/drop test |

## Extraction validation

| Capability | Result | Evidence |
|---|---|---|
| pg_dump schema-only extraction | $pg_dump_status | Exit: $pg_dump_exit; object statements: $pg_dump_object_count; diagnostic: $pg_dump_diagnostic |
| pg_dump contains no data statements or fabricated values | $pg_dump_data_statements | Output scan |
| pg-delta declarative generation | $pg_delta_status | Exit: $pg_delta_exit; files: $pg_delta_object_count; diagnostic: $pg_delta_diagnostic |
| pg-delta contains no data statements or fabricated values | $pg_delta_data_statements | Output scan |

Expected object presence is recorded separately for each method. Missing objects remain missing; successful exit does not imply complete extraction.

### pg_dump expected-object inventory

| Object | Status |
|---|---|
$(awk -F'|' '{printf "| `%s` | %s |\n", $1, $2}' "$RESULT_DIR/pg-dump-objects.tsv")

### pg-delta expected-object inventory

| Object | Status |
|---|---|
$(awk -F'|' '{printf "| `%s` | %s |\n", $1, $2}' "$RESULT_DIR/pg-delta-objects.tsv")

## Restricted forbidden-operation tests

Each row was run after a successful restricted-identity connection. A PASS requires the expected privilege-denial SQLSTATE `42501`; connection failures, syntax errors, missing-object errors, unexpected success, and other SQLSTATEs are failures.

| Operation | Result | Expected SQLSTATE | Observed SQLSTATE | Exit | Classification |
|---|---|---:|---:|---:|---|
$(awk -F'\t' '{printf "| %s | %s | `%s` | `%s` | %s | %s |\n", $1, $2, $3, ($4 == "" ? "none" : $4), $5, $6}' "$RESULT_DIR/forbidden-results.tsv")

**Forbidden-operation aggregate:** $forbidden_passes/$forbidden_total passed the explicit denial assertion.

## Interpretation

This experiment distinguishes missing object privileges from RLS. The restricted role has no application-table SELECT, so its SELECT failure is a privilege test. The separate `rls_probe` role has SELECT privilege but is denied all rows by an RLS policy, demonstrating RLS independently. Review warnings, SQLSTATEs, expected-object inventories, and omitted/unsupported objects before classifying a method as suitable for future restricted extraction.
EOF

# Keep only the sanitized report and inventories for the short-lived artifact.
rm -rf "$WORK_DIR" "$RESULT_DIR/forbidden-results.tsv"
```

## Review-scope confirmation

- This manifest is documentation-only and is intended for independent review.
- The source workflow was not executed.
- The source branch was not merged.
- No Supabase project was accessed.
- No secrets, permissions, source files, production/staging systems, or deployments were changed.
