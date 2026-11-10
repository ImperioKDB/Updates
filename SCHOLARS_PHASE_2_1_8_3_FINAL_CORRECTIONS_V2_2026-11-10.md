# Scholars Phase 2.1.8.3 — Final Synthetic Workflow Corrections

**Purpose:** Publish the exact corrected source files for independent review.

**Source repository:** [`ImperioKDB/scholars-schema-extraction`](https://github.com/ImperioKDB/scholars-schema-extraction)  
**Corrected experiment commit:** [`cb434df2f3e1c910751bb3390197551d5a3448ef`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/cb434df2f3e1c910751bb3390197551d5a3448ef)  
**Base commit:** [`428d44132b1775982a6a7301a738c325e2259d2e`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/428d44132b1775982a6a7301a738c325e2259d2e)

Each file below was retrieved directly from the corrected commit and reproduced byte-for-byte. Each Git blob SHA was read from Git and independently recomputed from the file bytes.

## Mandatory checks enforced

- **Dispatch mechanism: ENFORCED.** The workflow requires the exact `experiment/phase-2-1-8-isolated-proof` input, requires execution from `main`, and checks out that branch explicitly. The default-branch dispatcher candidate contains only the workflow and is published at [`ab0a14294dc82da47eeaaf19212bd3bc6858a138`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/ab0a14294dc82da47eeaaf19212bd3bc6858a138); it remains unmerged.
- **Password authentication: ENFORCED.** Trust authentication is removed. The disposable PostgreSQL service uses a synthetic bootstrap password; bootstrap and restricted connections verify `current_user` and `current_database()`.
- **Fail-closed gate: ENFORCED.** The runner requires PASS for restricted authentication, role attributes, memberships, effective privileges, default privileges, separate RLS, owner maintenance, both extraction commands, non-empty outputs, complete object inventories, PASS data exclusion, clean diagnostics, and all nine expected `42501` forbidden-operation results. Any unmet condition exits nonzero.
- **Unexpected diagnostics: ENFORCED.** Both stdout and stderr are captured and sanitized. Stderr output or warning/error/fatal/failure markers in stdout fail the corresponding extraction diagnostics check; diagnostics are preserved in the summary.

## Precise safe execution procedure

1. Independently review the corrected experiment branch and the dispatcher-only branch.
2. If execution is approved, merge only the dispatcher workflow file into `main` of `ImperioKDB/scholars-schema-extraction`; do not merge the experiment implementation or any Scholars application files. No merge has been performed.
3. From Actions on `main`, select **Isolated restricted schema extraction proof** and leave `experiment_ref` exactly as `experiment/phase-2-1-8-isolated-proof`. The repository, ref, and input guards reject other combinations.
4. Do not add secrets or environment variables. Review the sanitized summary and one-day artifact, then stop.

## Exact source files and Git blob verification

### `.github/workflows/isolated-schema-proof.yml`

- **Git blob SHA:** `7e80d6f85c2223ba99d71fe11ff20a6561127815`
- **Matches corrected commit `cb434df2f3e1c910751bb3390197551d5a3448ef`:** `YES`
- **Byte length:** `5159`

```yaml
name: Isolated restricted schema extraction proof

on:
  workflow_dispatch:
    inputs:
      experiment_ref:
        description: Exact synthetic experiment branch to execute
        required: true
        default: experiment/phase-2-1-8-isolated-proof
        type: string

permissions:
  contents: read

concurrency:
  group: isolated-restricted-schema-proof
  cancel-in-progress: true

env:
  EXPECTED_EXPERIMENT_REF: experiment/phase-2-1-8-isolated-proof
  SYNTHETIC_BOOTSTRAP_PASSWORD: synthetic-bootstrap-password-phase-2-1-8-3

jobs:
  isolated-proof:
    # This workflow file must be present on the default branch for manual
    # dispatch. It then checks out only the exact isolated experiment branch.
    if: ${{ github.repository == 'ImperioKDB/scholars-schema-extraction' && github.ref == 'refs/heads/main' && inputs.experiment_ref == 'experiment/phase-2-1-8-isolated-proof' }}
    runs-on: ubuntu-latest
    timeout-minutes: 25
    services:
      postgres:
        image: postgres:16.4-bookworm
        env:
          POSTGRES_USER: bootstrap
          POSTGRES_PASSWORD: synthetic-bootstrap-password-phase-2-1-8-3
          POSTGRES_DB: synthetic
        ports:
          - 5432:5432
        options: >-
          --health-cmd "pg_isready -U bootstrap -d synthetic"
          --health-interval 5s
          --health-timeout 5s
          --health-retries 12
    steps:
      - name: Check out exact synthetic experiment branch
        uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
        with:
          ref: ${{ inputs.experiment_ref }}
          fetch-depth: 1

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
        env:
          DISPATCHED_REF: ${{ inputs.experiment_ref }}
        run: |
          set -euo pipefail
          if [[ "$DISPATCHED_REF" != "$EXPECTED_EXPERIMENT_REF" ]]; then
            echo '::error::Only the exact synthetic experiment branch may be executed.'
            exit 1
          fi
          checked_out_ref="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
          if [[ "$checked_out_ref" != "$EXPECTED_EXPERIMENT_REF" ]]; then
            echo '::error::The checked-out ref did not match the exact synthetic experiment branch.'
            exit 1
          fi
          forbidden_prod="$(printf 'cmdglabohpttgfofcm%s' 'qc')"
          forbidden_stage="$(printf 'aqhktriwaglvvrchxm%s' 'td')"
          forbidden_secret="$(printf 'SUPABASE_%s' 'DB_URL')"
          forbidden_supabase="$(printf 'supabase%s' '.co')"
          forbidden_vercel="$(printf 'vercel%s' '.app')"
          if grep -RInE "$forbidden_prod|$forbidden_stage|$forbidden_secret|$forbidden_supabase|$forbidden_vercel"             .github/workflows/isolated-schema-proof.yml experiment/schema.sql experiment/run.sh; then
            echo '::error::A production/staging reference was found in the synthetic experiment files.'
            exit 1
          fi
          supabase --version

      - name: Create temporary synthetic credentials
        shell: bash
        env:
          BOOTSTRAP_PASSWORD: ${{ env.SYNTHETIC_BOOTSTRAP_PASSWORD }}
        run: |
          set -euo pipefail
          restricted_password="$(openssl rand -hex 32)"
          {
            echo "DB_HOST=127.0.0.1"
            echo "DB_PORT=5432"
            echo "DB_NAME=synthetic"
            echo "BOOTSTRAP_USER=bootstrap"
            echo "BOOTSTRAP_PASSWORD=$BOOTSTRAP_PASSWORD"
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
        if: always()
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
- **Matches corrected commit `cb434df2f3e1c910751bb3390197551d5a3448ef`:** `YES`
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

- **Git blob SHA:** `72f45e29c65f6d6be918e00145c9fcebb896bbd8`
- **Matches corrected commit `cb434df2f3e1c910751bb3390197551d5a3448ef`:** `YES`
- **Byte length:** `21142`

```bash
#!/usr/bin/env bash
set -euo pipefail

: "${DB_HOST:?}"
: "${DB_PORT:?}"
: "${DB_NAME:?}"
: "${BOOTSTRAP_USER:?}"
BOOTSTRAP_PASSWORD="${BOOTSTRAP_PASSWORD:?}"
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

# Both connections use password authentication against the disposable service.
bootstrap_identity="$(run_bootstrap -Atc "SELECT current_user || '|' || current_database()")"
if [[ "$bootstrap_identity" != "${BOOTSTRAP_USER}|${DB_NAME}" ]]; then
  echo 'Bootstrap password authentication identity did not match the synthetic service.' >&2
  exit 1
fi
run_bootstrap -f experiment/schema.sql --set=restricted_password="$RESTRICTED_PASSWORD" >/dev/null

# Inspect and assert role state only after schema.sql has created all roles and objects.
run_bootstrap -Atc "SELECT rolname || '|' || rolsuper || '|' || rolcreatedb || '|' || rolcreaterole || '|' || rolbypassrls || '|' || rolinherit FROM pg_roles WHERE rolname IN ('app_owner','restricted_extractor','rls_probe') ORDER BY rolname" > "$WORK_DIR/role-attributes.txt"
run_bootstrap -Atc "SELECT COALESCE(pg_get_userbyid(roleid),'') || '|' || COALESCE(pg_get_userbyid(member),'') || '|' || admin_option || '|' || inherit_option || '|' || set_option FROM pg_auth_members WHERE member IN ('restricted_extractor'::regrole, 'rls_probe'::regrole) ORDER BY member, roleid" > "$WORK_DIR/role-memberships.txt"
run_bootstrap -Atc "SELECT has_schema_privilege('restricted_extractor','app','USAGE') || '|' || has_schema_privilege('restricted_extractor','app','CREATE') || '|' || has_table_privilege('restricted_extractor','app.students','SELECT') || '|' || has_table_privilege('restricted_extractor','app.students','INSERT') || '|' || has_table_privilege('restricted_extractor','app.students','UPDATE') || '|' || has_table_privilege('restricted_extractor','app.students','DELETE')" > "$WORK_DIR/effective-grants.txt"

role_attributes_status='PASS'
while IFS= read -r expected; do
  if ! grep -Fqx "$expected" "$WORK_DIR/role-attributes.txt"; then role_attributes_status='FAIL'; fi
done <<'EXPECTED_ROLE_ATTRIBUTES'
app_owner|f|f|f|f|f
restricted_extractor|f|f|f|f|t
rls_probe|f|f|f|f|f
EXPECTED_ROLE_ATTRIBUTES

role_memberships_status='PASS'
if [[ -s "$WORK_DIR/role-memberships.txt" ]]; then role_memberships_status='FAIL'; fi

effective_grants_status='PASS'
if ! grep -Fqx 't|f|f|f|f|f' "$WORK_DIR/effective-grants.txt"; then effective_grants_status='FAIL'; fi

default_privilege_status='NOT TESTED'
default_privilege_effective='NOT TESTED'
default_privilege_create_exit='NOT TESTED'
default_privilege_drop_exit='NOT TESTED'
set +e
run_bootstrap -Atc "SET ROLE app_owner; CREATE TABLE app.default_privilege_check(id integer PRIMARY KEY);" >"$WORK_DIR/default-privilege-create.stdout" 2>"$WORK_DIR/default-privilege-create.stderr"
default_privilege_create_exit=$?
set -e
if [[ "$default_privilege_create_exit" -eq 0 ]]; then
  set +e
  default_privilege_effective="$(run_bootstrap -Atc "SELECT has_table_privilege('restricted_extractor','app.default_privilege_check','SELECT') || '|' || has_table_privilege('restricted_extractor','app.default_privilege_check','INSERT') || '|' || has_table_privilege('restricted_extractor','app.default_privilege_check','UPDATE') || '|' || has_table_privilege('restricted_extractor','app.default_privilege_check','DELETE') || '|' || has_table_privilege('restricted_extractor','app.default_privilege_check','TRUNCATE') || '|' || has_table_privilege('restricted_extractor','app.default_privilege_check','REFERENCES') || '|' || has_table_privilege('restricted_extractor','app.default_privilege_check','TRIGGER')" 2>"$WORK_DIR/default-privilege-query.stderr")"
  default_privilege_query_exit=$?
  run_bootstrap -Atc "SET ROLE app_owner; DROP TABLE app.default_privilege_check;" >"$WORK_DIR/default-privilege-drop.stdout" 2>"$WORK_DIR/default-privilege-drop.stderr"
  default_privilege_drop_exit=$?
  set -e
  if [[ "$default_privilege_query_exit" -eq 0 && "$default_privilege_effective" == 'f|f|f|f|f|f|f' && "$default_privilege_drop_exit" -eq 0 ]]; then default_privilege_status='PASS'; else default_privilege_status='FAIL'; fi
fi

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
  'table|app.students|CREATE[[:space:]]+TABLE[[:space:]]+(IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+)?app[.]students[[:space:]]*[(]'
  'table|app.scholarships|CREATE[[:space:]]+TABLE[[:space:]]+(IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+)?app[.]scholarships[[:space:]]*[(]'
  'sequence|app.scholarship_id_seq|CREATE[[:space:]]+SEQUENCE[[:space:]]+app[.]scholarship_id_seq([[:space:]]|;|$)'
  'index|scholarships_owner_idx|CREATE[[:space:]]+INDEX[[:space:]]+(IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+)?scholarships_owner_idx([[:space:]]|;|$)'
  'view|app.published_scholarships|CREATE[[:space:]]+VIEW[[:space:]]+(IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+)?app[.]published_scholarships([[:space:]]|;|$)'
  'function|app.current_synthetic_admin|CREATE[[:space:]]+(OR[[:space:]]+REPLACE[[:space:]]+)?FUNCTION[[:space:]]+app[.]current_synthetic_admin[[:space:]]*[(]'
  'table|app.audit_events|CREATE[[:space:]]+TABLE[[:space:]]+(IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+)?app[.]audit_events[[:space:]]*[(]'
  'function|app.record_scholarship_insert|CREATE[[:space:]]+(OR[[:space:]]+REPLACE[[:space:]]+)?FUNCTION[[:space:]]+app[.]record_scholarship_insert[[:space:]]*[(]'
  'trigger|app.scholarships_insert_audit|CREATE[[:space:]]+TRIGGER[[:space:]]+(IF[[:space:]]+NOT[[:space:]]+EXISTS[[:space:]]+)?scholarships_insert_audit([[:space:]]|;|$)'
  'policy|synthetic_student_self_read|CREATE[[:space:]]+POLICY[[:space:]]+synthetic_student_self_read[[:space:]]+ON[[:space:]]+app[.]students([[:space:]]|;|$)'
  'policy|synthetic_rls_probe_denied|CREATE[[:space:]]+POLICY[[:space:]]+synthetic_rls_probe_denied[[:space:]]+ON[[:space:]]+app[.]students([[:space:]]|;|$)'
  'policy|synthetic_public_scholarship_read|CREATE[[:space:]]+POLICY[[:space:]]+synthetic_public_scholarship_read[[:space:]]+ON[[:space:]]+app[.]scholarships([[:space:]]|;|$)'
  'policy|synthetic_admin_only_audit|CREATE[[:space:]]+POLICY[[:space:]]+synthetic_admin_only_audit[[:space:]]+ON[[:space:]]+app[.]audit_events([[:space:]]|;|$)'
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
  local object_type object_name definition_pattern
  : > "$RESULT_DIR/${label}-objects.tsv"
  while IFS='|' read -r object_type object_name definition_pattern; do
    if [[ -f "$target" ]]; then
      if grep -Eiq "$definition_pattern" "$target"; then printf '%s|%s|present\n' "$object_type" "$object_name" >> "$RESULT_DIR/${label}-objects.tsv"; else printf '%s|%s|missing\n' "$object_type" "$object_name" >> "$RESULT_DIR/${label}-objects.tsv"; fi
    elif [[ -d "$target" ]]; then
      if grep -RIlEq "$definition_pattern" "$target" >/dev/null 2>&1; then printf '%s|%s|present\n' "$object_type" "$object_name" >> "$RESULT_DIR/${label}-objects.tsv"; else printf '%s|%s|missing\n' "$object_type" "$object_name" >> "$RESULT_DIR/${label}-objects.tsv"; fi
    else
      printf '%s|%s|missing\n' "$object_type" "$object_name" >> "$RESULT_DIR/${label}-objects.tsv"
    fi
  done < "$WORK_DIR/expected-objects.txt"
}

scan_data_exclusion() {
  local target="$1"
  local data_pattern='^[[:space:]]*(COPY|INSERT[[:space:]]+INTO)([[:space:]]|$)|student@example[.]invalid|admin@example[.]invalid|Synthetic Student|Synthetic Administrator|Synthetic Scholarship'
  if [[ -f "$target" && -s "$target" ]]; then
    if grep -Eiq "$data_pattern" "$target"; then printf 'FAIL'; else printf 'PASS'; fi
  elif [[ -d "$target" ]] && find "$target" -type f -size +0c -print -quit | grep -q .; then
    if grep -RIlEq "$data_pattern" "$target" >/dev/null 2>&1; then printf 'FAIL'; else printf 'PASS'; fi
  else
    printf 'NOT TESTED'
  fi
}

pg_dump_output="$WORK_DIR/restricted-schema.sql"
set +e
PGPASSWORD="$RESTRICTED_PASSWORD" "$PG_DUMP_BIN" --schema-only --schema=app --file="$pg_dump_output" "$restricted_uri" >"$WORK_DIR/pg_dump.stdout" 2>"$WORK_DIR/pg_dump.stderr"
pg_dump_exit=$?
set -e
pg_dump_status='FAIL'
if [[ "$pg_dump_exit" -eq 0 && -s "$pg_dump_output" ]]; then pg_dump_status='PASS'; fi
pg_dump_stdout_diagnostic="$(extract_diagnostic "$WORK_DIR/pg_dump.stdout")"
pg_dump_stderr_diagnostic="$(extract_diagnostic "$WORK_DIR/pg_dump.stderr")"
pg_dump_object_count='0'
if [[ -s "$pg_dump_output" ]]; then pg_dump_object_count="$(grep -Ec '^[[:space:]]*CREATE[[:space:]]+(TABLE|SEQUENCE|INDEX|VIEW|FUNCTION|TRIGGER|POLICY)' "$pg_dump_output" || true)"; fi
pg_dump_data_statements="$(scan_data_exclusion "$pg_dump_output")"
record_object_inventory 'pg-dump' "$pg_dump_output"
pg_dump_missing_objects="$(awk -F'|' '$3 == "missing" {count++} END {print count+0}' "$RESULT_DIR/pg-dump-objects.tsv")"
pg_dump_objects_status='FAIL'
if [[ "$pg_dump_exit" -eq 0 && -s "$pg_dump_output" && "$pg_dump_missing_objects" -eq 0 ]]; then pg_dump_objects_status='PASS'; fi
pg_dump_diagnostics_status='PASS'
if [[ -s "$WORK_DIR/pg_dump.stderr" ]] || grep -Eiq '(warning|warn|error|fatal|failed|failure)' "$WORK_DIR/pg_dump.stdout"; then pg_dump_diagnostics_status='FAIL'; fi

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
pg_delta_nonempty_files='0'
if [[ -d "$pg_delta_output" ]]; then pg_delta_nonempty_files="$(find "$pg_delta_output" -type f -size +0c | wc -l | tr -d ' ')"; fi
pg_delta_status='FAIL'
if [[ "$pg_delta_exit" -eq 0 && "$pg_delta_nonempty_files" -gt 0 ]]; then pg_delta_status='PASS'; fi
pg_delta_stdout_diagnostic="$(extract_diagnostic "$WORK_DIR/pg_delta.stdout")"
pg_delta_stderr_diagnostic="$(extract_diagnostic "$WORK_DIR/pg_delta.stderr")"
pg_delta_object_count='0'
if [[ -d "$pg_delta_output" ]]; then pg_delta_object_count="$(find "$pg_delta_output" -type f | wc -l | tr -d ' ')"; fi
pg_delta_data_statements="$(scan_data_exclusion "$pg_delta_output")"
record_object_inventory 'pg-delta' "$pg_delta_output"
pg_delta_missing_objects="$(awk -F'|' '$3 == "missing" {count++} END {print count+0}' "$RESULT_DIR/pg-delta-objects.tsv")"
pg_delta_objects_status='FAIL'
if [[ "$pg_delta_exit" -eq 0 && "$pg_delta_nonempty_files" -gt 0 && "$pg_delta_missing_objects" -eq 0 ]]; then pg_delta_objects_status='PASS'; fi
pg_delta_diagnostics_status='PASS'
if [[ -s "$WORK_DIR/pg_delta.stderr" ]] || grep -Eiq '(warning|warn|error|fatal|failed|failure)' "$WORK_DIR/pg_delta.stdout"; then pg_delta_diagnostics_status='FAIL'; fi

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
| Bootstrap password authentication | PASS | Identity/database: $bootstrap_identity |
| Restricted identity connection | $restricted_connection_status | Identity/database: restricted_extractor/synthetic; exit: $restricted_connection_exit |
| RLS probe has SELECT privilege | $rls_select_privilege | Checked independently for rls_probe |
| RLS probe sees protected rows | $rls_status | rls_probe SELECT exit: $rls_exit; visible rows: $rls_visible_rows |
| Separate owner maintenance operation | $owner_test | Synthetic owner-only create/drop test |
| Role attributes asserted | $role_attributes_status | $(tr '\n' ';' < "$WORK_DIR/role-attributes.txt") |
| Role memberships asserted | $role_memberships_status | $(if [[ -s "$WORK_DIR/role-memberships.txt" ]]; then tr '\n' ';' < "$WORK_DIR/role-memberships.txt"; else printf 'none'; fi) |
| Effective restricted privileges asserted | $effective_grants_status | $(cat "$WORK_DIR/effective-grants.txt") |
| New-table default privileges | $default_privilege_status | restricted_extractor privileges: $default_privilege_effective; create exit: $default_privilege_create_exit; drop exit: $default_privilege_drop_exit |

## Extraction validation

| Capability | Result | Evidence |
|---|---|---|
| pg_dump schema-only extraction | $pg_dump_status | Exit: $pg_dump_exit; object statements: $pg_dump_object_count; stdout: $pg_dump_stdout_diagnostic; stderr: $pg_dump_stderr_diagnostic |
| pg_dump expected objects | $pg_dump_objects_status | Missing definitions: $pg_dump_missing_objects |
| pg_dump diagnostics are empty | $pg_dump_diagnostics_status | stdout: $pg_dump_stdout_diagnostic; stderr: $pg_dump_stderr_diagnostic |
| pg_dump contains no data statements or fabricated values | $pg_dump_data_statements | Output scan |
| pg-delta declarative generation | $pg_delta_status | Exit: $pg_delta_exit; files: $pg_delta_object_count; stdout: $pg_delta_stdout_diagnostic; stderr: $pg_delta_stderr_diagnostic |
| pg-delta expected objects | $pg_delta_objects_status | Missing definitions: $pg_delta_missing_objects |
| pg-delta diagnostics are empty | $pg_delta_diagnostics_status | stdout: $pg_delta_stdout_diagnostic; stderr: $pg_delta_stderr_diagnostic |
| pg-delta contains no data statements or fabricated values | $pg_delta_data_statements | Output scan |

Expected object presence is recorded separately for each method. Missing objects remain missing; successful exit does not imply complete extraction.

### pg_dump expected-object inventory

| Type | Object | Definition status |
|---|---|---|
$(awk -F'|' '{printf "| `%s` | `%s` | %s |\n", $1, $2, $3}' "$RESULT_DIR/pg-dump-objects.tsv")

### pg-delta expected-object inventory

| Type | Object | Definition status |
|---|---|---|
$(awk -F'|' '{printf "| `%s` | `%s` | %s |\n", $1, $2, $3}' "$RESULT_DIR/pg-delta-objects.tsv")

## Restricted forbidden-operation tests

Each row was run after a successful restricted-identity connection. A PASS requires the expected privilege-denial SQLSTATE `42501`; connection failures, syntax errors, missing-object errors, unexpected success, and other SQLSTATEs are failures.

| Operation | Result | Expected SQLSTATE | Observed SQLSTATE | Exit | Classification |
|---|---|---:|---:|---:|---|
$(awk -F'\t' '{printf "| %s | %s | `%s` | `%s` | %s | %s |\n", $1, $2, $3, ($4 == "" ? "none" : $4), $5, $6}' "$RESULT_DIR/forbidden-results.tsv")

**Forbidden-operation aggregate:** $forbidden_passes/$forbidden_total passed the explicit denial assertion.

## Mandatory fail-closed gate

The runner exits unsuccessfully unless bootstrap and restricted authentication, role attributes, memberships, effective privileges, default privileges, separate RLS, owner maintenance, both extraction commands, non-empty outputs, complete object inventories, empty diagnostics, PASS data-exclusion checks, and all forbidden-operation SQLSTATE assertions pass.

## Interpretation

This experiment distinguishes missing object privileges from RLS. The restricted role has no application-table SELECT, so its SELECT failure is a privilege test. The separate `rls_probe` role has SELECT privilege but is denied all rows by an RLS policy, demonstrating RLS independently. Review warnings, SQLSTATEs, expected-object inventories, and omitted/unsupported objects before classifying a method as suitable for future restricted extraction.
EOF

validation_failed=0
for status in   "$restricted_connection_status"   "$role_attributes_status"   "$role_memberships_status"   "$effective_grants_status"   "$default_privilege_status"   "$owner_test"   "$rls_status"   "$pg_dump_status"   "$pg_dump_objects_status"   "$pg_dump_diagnostics_status"   "$pg_dump_data_statements"   "$pg_delta_status"   "$pg_delta_objects_status"   "$pg_delta_diagnostics_status"   "$pg_delta_data_statements"; do
  if [[ "$status" != 'PASS' ]]; then validation_failed=1; fi
done
if [[ "$forbidden_total" -ne 9 || "$forbidden_passes" -ne "$forbidden_total" ]]; then
  validation_failed=1
fi

# Keep only the sanitized report and inventories for the short-lived artifact.
rm -rf "$WORK_DIR" "$RESULT_DIR/forbidden-results.tsv"
if [[ "$validation_failed" -ne 0 ]]; then
  exit 1
fi
```

## Scope confirmation

- The workflow was not executed.
- Nothing was merged.
- No Supabase project, production/staging system, production credential, secret, permission, or deployment was accessed or changed.
- `experiment/schema.sql` remains unchanged from the base commit.
