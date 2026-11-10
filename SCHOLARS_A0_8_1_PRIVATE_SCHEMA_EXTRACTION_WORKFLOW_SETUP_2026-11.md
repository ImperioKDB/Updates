# Scholars A0.8.1 — Private Production Schema Extraction Workflow Setup

**Status:** Prepared and pushed; awaiting owner review. The workflow was not run.

## Outcome

A separate private repository now contains a manually triggered, schema-only extraction workflow and an owner-facing README. This completes infrastructure preparation only. It does not authorize or perform extraction, production access, staging reconstruction, or import.

**Explicit confirmation:** No production or staging database connection was made during setup, and no database objects or permissions were modified.

## Repository and pushed files

- **Repository:** [ImperioKDB/scholars-schema-extraction](https://github.com/ImperioKDB/scholars-schema-extraction)
- **Visibility:** `PRIVATE`, verified from GitHub repository metadata after creation.
- **Repository ID:** `1451843391` (REST/database ID); GraphQL node ID `R_kgDOVolfPw`.
- **Default branch:** `main`.
- **Setup commit:** `f1394d1f68492dee43f461fdd83ab259bab37ad1`.
- **Files:** `.github/workflows/schema-only.yml` and `README.md` only. No SQL output, credentials, connection string, or database artifact is in Git. No collaborators were added by this setup; Issues and Wiki were disabled.

## Workflow configuration

The workflow file is `.github/workflows/schema-only.yml`. Its sole event is `workflow_dispatch`; the job is additionally restricted to this repository's `main` branch. There are no push, pull-request, fork, schedule, or external-event triggers. It uses a GitHub-hosted `ubuntu-latest` runner, and requires the operator to type the expected production project reference before the job can proceed.

Workflow `GITHUB_TOKEN` permission is `contents: read`; all unspecified scopes are `none`, with no write permission. The workflow does not check out repository code. Its only database operation is the requested schema-only command:

```bash
supabase db dump \
  --db-url "$SUPABASE_DB_URL" \
  --file scholars-production-schema-only.sql
```

The command writes from the runner's temporary directory, not the Git workspace. The workflow does not invoke `--data-only`, `--role-only`, `db push`, `db reset`, migrations, DDL, `psql`, staging import, or deployment commands.

The CLI is fixed at **Supabase CLI 2.122.1**, installed with the official `supabase/setup-cli` action pinned to commit `689adcfb80d947100a1eab127289b97d1fb07b13`. The current maintained v2 channel resolved to 2.122.1 when checked. This version is pinned because A0.8.1 specifies the v2 `--db-url` form; the official v3 migration guide documents `--remote=<postgres-url>` as its replacement. The upload step uses GitHub's official `actions/upload-artifact` action pinned to commit `ea165f8d65b6e75b540449e92b4886f43607fa02`.

## Owner secret and artifact handling

Manus did **not** create, populate, list, or retrieve the `SUPABASE_DB_URL` secret. After reviewing the workflow, the owner should add it in the private repository under **Settings → Secrets and variables → Actions → New repository secret**, using the exact name `SUPABASE_DB_URL`. Enter the production database connection string only in GitHub's secret field; do not send it in chat or place it in Git, workflow inputs, issues, or logs. The workflow fails before CLI installation or database access if the secret is absent, the typed confirmation is wrong, or the URL does not contain the expected project reference. Secret-bearing command output is redirected to a temporary log and deleted rather than printed.

If a future owner-triggered run succeeds, the SQL file is uploaded only as a GitHub Actions artifact in this private repository, with **one-day retention** (the shortest supported per-artifact setting), and the temporary runner copy is removed. Artifact download requires authentication; access follows the private repository's authorized-reader boundary. The file remains sensitive even though it is schema-only: inspect it privately, do not commit or publish it, and delete it sooner if no longer needed. Static review was performed; because the workflow was not run, log redaction and artifact behavior have not been runtime-tested.

## Expected exclusions and reconstruction limits

Supabase documents that the default schema dump excludes Supabase-managed schemas, including `auth` and `storage`, and schemas created by extensions. The default dump contains neither table row data nor custom roles. Customizations within `auth` or `storage`, extension-owned objects, role definitions, Auth/Storage records, and project-level configuration may therefore be absent or require separate decisions. The workflow intentionally performs no production catalog query or additional export to compensate for these exclusions. Treat any eventual output as an incomplete reconstruction input, not a complete backup or a complete staging baseline.

## Security verification checklist

| Requirement | Result | Evidence |
|---|---|---|
| New repository is private | **PASS** | GitHub metadata reports `PRIVATE`; no existing repository visibility was changed. |
| Manual-only workflow | **PASS** | Static YAML review found `workflow_dispatch` as the only trigger; job is main-branch-only. |
| Credentials embedded in files | **PASS** | No connection string, password, token, or database credential is present; the workflow references only the secret name. |
| Secret logging | **PASS — static review** | Shell tracing is disabled; dump output is captured and deleted; failure messages are generic. No workflow run was used to test logs. |
| Generated SQL committed to Git | **PASS** | Remote `main` contains only the workflow and README. Output path is runner temporary storage. |
| Artifact retention | **PASS** | `retention-days: 1` is explicitly set; temporary runner files are cleaned up. |
| Minimal permissions | **PASS** | `contents: read`; no token write scopes. |
| Automatic deploy/migration/import | **PASS** | Static review found none of these commands or triggers. |
| Production/staging access during setup | **PASS — not performed** | No database connection, SQL query, workflow run, or artifact generation occurred. GitHub reports no Actions runs. |
| Database object changes | **PASS — none** | No production or staging DDL, privileges, migrations, Auth, Storage, or other objects were changed. |
| Missing secret fails safely | **PASS — static review** | Validation exits before CLI installation or the dump step; no runtime test was performed. |
| Unnecessary collaborators | **PASS** | No collaborator access was granted by this setup. |

## Exact next owner action

Review [`schema-only.yml`](https://github.com/ImperioKDB/scholars-schema-extraction/blob/main/.github/workflows/schema-only.yml) and the repository README. If satisfied, add `SUPABASE_DB_URL` through that repository's secure Actions settings. Only when ready, manually start **Actions → Manual production schema-only extraction** on `main`, enter the expected production project reference, and review any resulting private one-day artifact. Do not proceed to staging import or reconstruction without a separate explicit authorization.

## External references

1. [Supabase CLI `db dump` reference](https://supabase.com/docs/reference/cli/supabase-db-dump) — default schema-only behavior and managed-schema exclusions.
2. [Supabase backup and restore guide](https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore) — dump workflow and special considerations for `auth` and `storage` customizations.
3. [Supabase CLI v2-to-v3 migration guide](https://supabase.com/docs/guides/local-development/cli/migrating-to-v3) and [v2.122.1 release](https://github.com/supabase/cli/releases/tag/v2.122.1) — target-flag transition and maintained v2 release.
4. [`supabase/setup-cli`](https://github.com/supabase/setup-cli) — official setup action and fixed version input.
5. [GitHub Actions secure-use guidance](https://docs.github.com/en/actions/reference/security/secure-use) — minimum permissions, secret handling, and full-SHA action pinning.
6. [GitHub workflow syntax](https://docs.github.com/actions/using-workflows/workflow-syntax-for-github-actions) and [manual workflow runs](https://docs.github.com/actions/managing-workflow-runs/manually-running-a-workflow) — dispatch requirements and token permissions.
7. [GitHub artifact storage guide](https://docs.github.com/en/actions/tutorials/store-and-share-data) and [`upload-artifact` action](https://github.com/actions/upload-artifact) — retention configuration and artifact handling.
