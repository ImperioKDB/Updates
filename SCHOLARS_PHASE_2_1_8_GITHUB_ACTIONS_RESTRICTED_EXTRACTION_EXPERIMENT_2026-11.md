# Scholars Phase 2.1.8 — GitHub Actions Restricted Extraction Experiment

**Status:** Prepared for review; experiment not yet executed
**Decision:** **NOT TESTED — awaiting review-branch approval and main-branch execution**
**Date:** 2026-11-10

## Summary

Phase 2.1.8 requested completion of the restricted schema-extraction capability experiment using a disposable PostgreSQL service container in GitHub Actions. The synthetic experiment was created in the private repository `ImperioKDB/scholars-schema-extraction` and pushed to a review branch.

The workflow has been inspected and passed local static checks, but it has not been merged to `main` or executed. The workflow intentionally runs only when manually dispatched from the repository’s `main` branch. Therefore, no pg_dump or pg-delta results exist yet, and this report does not classify either method as passing or failing.

## Private repository change

- **Repository:** `ImperioKDB/scholars-schema-extraction`
- **Review branch:** `experiment/phase-2-1-8-isolated-proof`
- **Commit:** [`11cacd6`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/11cacd6)
- **Review link:** [Open the private repository pull request](https://github.com/ImperioKDB/scholars-schema-extraction/pull/new/experiment/phase-2-1-8-isolated-proof)

Added files:

- `.github/workflows/isolated-schema-proof.yml`
- `experiment/schema.sql`
- `experiment/run.sh`

## Static security review

The workflow was read in full and checked for:

- Manual `workflow_dispatch` only.
- Execution restricted to `refs/heads/main` of the intended private repository.
- A temporary PostgreSQL `16.4-bookworm` service container.
- No production or staging URLs.
- No `SUPABASE_DB_URL` reference.
- No Supabase project connection or repository secret.
- Full commit-SHA-pinned third-party actions.
- `contents: read` permission only.
- Runtime-generated synthetic restricted-role password.
- One-day retention for the sanitized summary artifact only.
- No raw SQL extraction artifact uploaded.
- Cleanup of temporary credentials, results, and working files.
- No deployment, migration, import, or project-setting operation.

The experiment files passed shell syntax and forbidden production/staging reference checks. PyYAML was not installed in the Manus workspace, so local YAML parsing through PyYAML was unavailable; the complete YAML was manually inspected. GitHub Actions remains the authoritative workflow parser.

## Synthetic experiment design

The synthetic schema creates fabricated application-like objects only:

- `app.students` and `app.scholarships` tables.
- Fabricated student and scholarship records.
- Primary/foreign keys, indexes, sequences, and identity columns.
- A published-scholarships view.
- A synthetic administrator-related `app.current_synthetic_admin()` function.
- An audit table, trigger function, and trigger.
- RLS-enabled tables and policies.
- Explicit grants/revokes and default-privilege statements.

The restricted identity is generated inside the temporary database and is configured as `NOSUPERUSER`, `NOCREATEDB`, `NOCREATEROLE`, and `NOBYPASSRLS`, with no application-table SELECT/DML/DDL or privilege-management rights. The separate bootstrap/application-owner identities are used only for synthetic setup and owner-maintenance checks.

## Planned runtime measurements

Once the review branch is approved and the change is available on `main`, the manually dispatched workflow will record sanitized results for:

1. PostgreSQL and pg_dump versions.
2. Schema-only pg_dump exit code, warnings, permission errors, object count, and record-content scan.
3. Supabase CLI `2.122.1` declarative generation exit code, warnings, unsupported objects, and generated-file count.
4. Restricted-identity attempts to SELECT, INSERT, UPDATE, DELETE, create/alter tables or functions, change privileges, and assume the owner role.
5. A separate owner-controlled synthetic maintenance operation.
6. A pg_dump-versus-pg-delta comparison classified as PASS, PARTIAL, FAIL, or NOT TESTED.

No privilege escalation will be performed to force an extraction to succeed.

## Current result

| Capability | Status |
|---|---|
| Synthetic workflow created | PASS |
| Workflow static security review | PASS, with YAML parsing deferred to GitHub Actions |
| Synthetic PostgreSQL runtime | NOT TESTED — workflow not executed |
| Restricted role creation | NOT TESTED — workflow not executed |
| pg_dump | NOT TESTED |
| pg-delta | NOT TESTED |
| Forbidden-operation tests | NOT TESTED |
| Owner-operation test | NOT TESTED |
| Production/staging access | NOT ATTEMPTED |

## Safety statement

No production or staging database was connected to, queried, extracted from, or modified. No production or staging secret, role, privilege, setting, application code, migration, Vercel configuration, or deployment was changed. No raw schema artifact or synthetic credential was published to `Updates`.

The next permitted step is independent review of the private repository branch. After approval and merge to `main`, the workflow may be manually dispatched for the isolated synthetic experiment only. Production extraction remains unauthorized.
