# Scholars Phase 2.1.8.1 — Manus Session Handoff

**Prepared:** 2026-11-10
**Purpose:** Continue the isolated synthetic extraction experiment from the exact stopping point of the previous Manus session.
**Current decision:** Awaiting independent review. Do not execute or merge yet.

## User/project operating rules

The user builds from a phone using Next.js, Supabase, and Vercel. Always push development changes to a review branch before merging to `main`. Never force-push. Never delete tables, buckets, data, or secrets. Never rotate or expose secrets without explicit approval. Do not make production/staging changes, application changes, deployments, or irreversible schema changes unless separately authorized.

This handoff concerns only the private synthetic experiment and sanitized documentation. Production extraction, staging reconstruction, administrator remediation, application changes, Supabase project settings, Vercel settings, and deployment remain unauthorized.

## Exact stopping point

The previous session corrected the Phase 2.1.8 synthetic GitHub Actions experiment in the private repository and published a concise correction report to `Updates`. The workflow was **not executed** and the private branch was **not merged**.

### Corrected private repository

- **Repository:** `ImperioKDB/scholars-schema-extraction`
- **Branch:** `experiment/phase-2-1-8-isolated-proof`
- **Original experiment commit:** [`11cacd6`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/11cacd6)
- **Corrected commit:** [`1621ec09875489dd6aab99bc30ea8197f5fb7984`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/1621ec09875489dd6aab99bc30ea8197f5fb7984)
- **Review link:** [Open the private experiment pull request](https://github.com/ImperioKDB/scholars-schema-extraction/pull/new/experiment/phase-2-1-8-isolated-proof)

The corrected commit changes only:

- `experiment/schema.sql`
- `experiment/run.sh`

The workflow YAML is unchanged from the original reviewed commit.

### Corrected source blob SHAs

| Path | Commit | Git blob SHA |
|---|---|---|
| `.github/workflows/isolated-schema-proof.yml` | `1621ec09875489dd6aab99bc30ea8197f5fb7984` | `ab1a43608f2790b8d8c5c2b9f41e49a6aa85c664` |
| `experiment/schema.sql` | `1621ec09875489dd6aab99bc30ea8197f5fb7984` | `338261db6d6b2388f23a6a3a738bb6e0f5900433` |
| `experiment/run.sh` | `1621ec09875489dd6aab99bc30ea8197f5fb7984` | `b915a67d24bb60b5328d79648341a8741c6ef0dd` |

### Updates documentation

- **Correction report commit:** [`a1ebfcf`](https://github.com/ImperioKDB/Updates/commit/a1ebfcf)
- **Updates branch:** `docs/phase-2-1-8-1-corrections`
- **Review link:** [Open the Updates correction-report pull request](https://github.com/ImperioKDB/Updates/pull/new/docs/phase-2-1-8-1-corrections)
- **Report:** `SCHOLARS_PHASE_2_1_8_1_CORRECTION_REPORT_2026-11-10.md`
- **Local report path:** `/tmp/updates-review/SCHOLARS_PHASE_2_1_8_1_CORRECTION_REPORT_2026-11-10.md`

Earlier relevant documentation commits:

- [`f7ff01b`](https://github.com/ImperioKDB/Updates/commit/f7ff01b) — Phase 2.1.8 prepared/not-executed report.
- [`966554a`](https://github.com/ImperioKDB/Updates/commit/966554a) — verbatim source manifest for the original experiment files.
- [`98c51b3`](https://github.com/ImperioKDB/Updates/commit/98c51b3) — Phase 2.1.7 unavailable-runtime report.
- [`adacf48`](https://github.com/ImperioKDB/Updates/commit/adacf48) — Phase 2.1.6 extraction-readiness specification.

## Corrections made in `1621ec0`

1. **Bootstrap authentication:** The workflow uses `POSTGRES_HOST_AUTH_METHOD=trust` and writes an empty `BOOTSTRAP_PASSWORD`. `experiment/run.sh` now defaults the bootstrap password to empty and exits if it is non-empty, making the runner contract explicit.
2. **Correct ordering:** Role attributes, role memberships, and effective privileges are inspected only after `experiment/schema.sql` creates roles and objects.
3. **Restricted connection gate:** The runner confirms a successful `restricted_extractor|synthetic` connection before running denial tests.
4. **SQLSTATE-aware denial tests:** Each forbidden operation is independently recorded. A PASS requires a nonzero exit and expected privilege-denial SQLSTATE `42501`; connection failures, unexpected success, syntax errors, missing-object errors, and other SQLSTATEs fail.
5. **Independent RLS probe:** `rls_probe` has SELECT privilege on `app.students` but an explicit false RLS policy. This tests RLS separately from the restricted role’s missing table privilege.
6. **Extraction validation:** Both pg_dump and pg-delta record exit codes and sanitized diagnostics, check an expected object inventory, detect data-loading statements and fabricated values, and report present/missing objects. Success is not treated as complete coverage.
7. **Expected inventory:** Tables, sequence, index, view, functions, trigger, and all synthetic RLS policies are included.

## Experiment isolation controls

The workflow is manually dispatched and restricted by job condition to:

```text
github.repository == ImperioKDB/scholars-schema-extraction
github.ref == refs/heads/main
```

It uses:

- GitHub-hosted `ubuntu-latest`.
- Disposable `postgres:16.4-bookworm` service container.
- Synthetic database `synthetic` and bootstrap user only.
- Runtime-generated restricted-role password.
- No Supabase project access.
- No production/staging URLs or credentials.
- No `SUPABASE_DB_URL`.
- Third-party actions pinned to full commit SHAs.
- `contents: read` permission only.
- One-day retention for the sanitized summary artifact.
- No raw SQL artifact upload.
- Cleanup of temporary results and credentials.

## Validation already completed

The corrected files were read in full and validated:

- `bash -n experiment/run.sh` — passed.
- `npx --yes prettier@3.5.3 --check .github/workflows/isolated-schema-proof.yml` — passed.
- Forbidden production/staging, Supabase-project, `SUPABASE_DB_URL`, and Vercel-reference scan — passed with no matches.
- `git diff --check` — passed.
- Private working tree was clean after commit/push.
- Updates working tree was clean after report commit/push.

The local workspace does not have Ruby or PyYAML. YAML formatting was validated with Prettier; the complete YAML was manually inspected. GitHub Actions remains the authoritative workflow parser.

## What has not happened

- The corrected GitHub Actions workflow has not been executed.
- The private branch has not been merged to `main`.
- No PostgreSQL service experiment has run.
- No pg_dump or pg-delta result exists.
- No production or staging connection was made.
- No Supabase project, database, secret, environment variable, application code, migration, Vercel setting, or deployment was changed.
- No raw extraction artifact was generated or published.

## Required next steps

1. Wait for independent review of the private branch and the `Updates` correction report.
2. Do not merge automatically. Merge the private branch only after the user/independent reviewer approves it, following the review-branch workflow.
3. After approval and merge to `main`, manually dispatch `Isolated restricted schema extraction proof` from `main` in the private repository.
4. Confirm the run is synthetic-only before dispatch; do not add secrets or change environment variables.
5. Review the workflow summary and short-lived artifact. Check actual exit codes, diagnostics, object inventories, missing/unsupported objects, data-statement scans, SQLSTATEs, all nine forbidden-operation results, RLS probe, and owner-maintenance result.
6. If the workflow fails because of an experiment defect, correct only the relevant permitted experiment file on a new review commit; do not weaken restrictions. If GitHub Actions cannot provide the runtime, stop and report the exact blocker.
7. Publish a sanitized Phase 2.1.8 experiment-results report to `ImperioKDB/Updates`. Do not publish raw SQL, credentials, or raw artifacts.
8. Stop after the isolated experiment and report publication. Wait for independent review before proposing any production extraction.

## Hard prohibitions for continuation

Do not:

- Connect to production or staging.
- Create or populate `SUPABASE_DB_URL`.
- Run the existing production extraction workflow.
- Modify production/staging roles, privileges, RLS, schemas, data, buckets, or settings.
- Import anything into staging.
- Modify the Scholars application repository or migrations.
- Modify Vercel settings or deploy.
- Begin administrator remediation.
- Merge without review approval.
- Claim experiment results before the workflow actually runs.

## Useful local paths from the prior session

These paths exist only in the prior Manus sandbox and may not exist in the next session:

- Private repository checkout: `/tmp/scholars-schema-extraction`
- Updates repository checkout: `/tmp/updates-review`
- This handoff source: `/home/ubuntu/SCHOLARS_PHASE_2_1_8_1_HANDOFF_2026-11-10.md`

The next session should clone/fetch the repositories and verify the listed commit/blob SHAs rather than assuming these temporary paths persist.
