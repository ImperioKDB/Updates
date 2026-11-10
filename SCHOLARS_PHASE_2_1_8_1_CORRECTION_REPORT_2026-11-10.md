# Scholars Phase 2.1.8.1 — Correct Synthetic Extraction Experiment

**Status:** Corrections prepared and pushed for independent review; workflow not executed
**Repository:** `ImperioKDB/scholars-schema-extraction`
**Branch:** `experiment/phase-2-1-8-isolated-proof`
**Corrected commit:** [`1621ec09875489dd6aab99bc30ea8197f5fb7984`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/1621ec09875489dd6aab99bc30ea8197f5fb7984)

## Corrections applied

Only the permitted experiment files were changed. The workflow architecture and isolation boundaries were preserved.

1. **Bootstrap authentication contract:** `experiment/run.sh` now treats `BOOTSTRAP_PASSWORD` as intentionally empty under the workflow’s `POSTGRES_HOST_AUTH_METHOD=trust` configuration and exits if a non-empty bootstrap password is supplied.
2. **Post-setup inspection:** role attributes, memberships, and effective restricted-role privileges are collected only after `experiment/schema.sql` creates the roles and objects.
3. **Restricted connection gate:** the runner establishes and verifies `restricted_extractor|synthetic` before any forbidden-operation test.
4. **SQLSTATE-aware denial tests:** every forbidden operation is recorded independently. A PASS requires exit failure with expected privilege-denial SQLSTATE `42501`; connection failures, unexpected success, syntax errors, missing-object errors, and other SQLSTATEs fail the test.
5. **Separate RLS probe:** a distinct `rls_probe` identity has SELECT privilege on `app.students` but is denied rows by an explicit false RLS policy. This separates RLS behavior from missing table privileges on `restricted_extractor`.
6. **Extraction validation:** both methods record exit codes and sanitized diagnostics, scan for expected schema objects, detect SQL data-loading statements and fabricated values, and report present/missing objects. Successful command exit is not treated as complete coverage.
7. **Expected inventory expanded:** tables, sequence, index, view, functions, trigger, and all synthetic RLS policies are checked.

## Exact source manifest

| Path | Corrected commit | Git blob SHA |
|---|---|---|
| `.github/workflows/isolated-schema-proof.yml` | `1621ec09875489dd6aab99bc30ea8197f5fb7984` | `ab1a43608f2790b8d8c5c2b9f41e49a6aa85c664` |
| `experiment/schema.sql` | `1621ec09875489dd6aab99bc30ea8197f5fb7984` | `338261db6d6b2388f23a6a3a738bb6e0f5900433` |
| `experiment/run.sh` | `1621ec09875489dd6aab99bc30ea8197f5fb7984` | `b915a67d24bb60b5328d79648341a8741c6ef0dd` |

The workflow blob is unchanged from the prior reviewed commit; the schema and runner contain the corrections above.

## Validation completed

- `bash -n experiment/run.sh` — passed.
- Prettier YAML check on `.github/workflows/isolated-schema-proof.yml` — passed.
- Production/staging URL, credential, `SUPABASE_DB_URL`, Supabase-project, and Vercel-reference scan of the three experiment files — passed with no matches.
- `git diff --check` — passed.
- Complete updated workflow, schema, and runner files — reviewed.

## Not executed

The GitHub Actions workflow was not executed and the branch was not merged. No production or staging URL, credential, database, secret, environment variable, application repository, deployment, or Supabase project was accessed or modified. No extraction result is claimed.
