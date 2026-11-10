# Scholars Phase 2.1.4 — Migration Execution Ownership and CI/CD Governance

**Investigation date:** 2026-11-10
**Scope:** Read-only repository and workflow governance review. No deployment or database operation was executed.

## Current evidence

The Scholars repository has a CI workflow that runs type checking, tests, and a production build using placeholder public Supabase values. The scheduled workflows authenticate to deployed application routes with `CRON_SECRET`; they do not call the Supabase CLI or execute SQL migrations. A repository-wide search found no checked-in `supabase db push`, `supabase db pull`, `supabase db diff`, `supabase db dump`, or migration-runner command in the current workflow set. [1]

Recent GitHub Actions runs for the current main commit are successful, but their workflow names are application-job workflows such as source verification, eligibility review, discovery quality scoring, and CI. They are not database deployment attestations. Vercel deployment is represented in repository history by deployment-trigger commits and a document stating that Vercel builds new commits rather than retroactively deploying old ones. [2] [3]

The production migration ledger therefore has no repository-backed execution manifest tying each version to an executor, CLI version, project ref, source blob, approval, or deployment run. Prior reports found 180 production ledger entries and partial Git reconciliation, but no authoritative executor record. [4]

## Ownership model required for the new baseline

One named release owner should own database deployment for each environment. Developers may author migrations and run them locally; only the protected staging or production deployment job may apply the reviewed migration artifact. The job must use a project-scoped, least-privilege deployment identity held in GitHub environment secrets or an equivalent CI secret store. It must not use a browser publishable key, `service_role` key, a developer's personal token, or a password embedded in a repository.

The baseline deployment job should be pinned to a reviewed Supabase CLI version and an immutable commit SHA. It should accept only the selected project ref from a protected environment, use an explicit concurrency group so two migration deployments cannot overlap, and require environment approval before production. Supabase recommends coordinated migration deployment through reviewed migration files and warns that direct remote changes bypass migration history and cause sync errors. [5]

## Required execution manifest

Every migration release should publish a machine-readable manifest with the following fields: migration version, filename, SHA-256 of the SQL file, dependency or ordering note, data-affecting classification, target project ref, source commit SHA, CLI version, diff engine, reviewer, approval timestamp, deployment run ID, start and finish status, and rollback or forward-fix note. The manifest must be immutable after deployment.

The job should archive the exact generated SQL or migration bundle, sanitized command metadata, CLI output, and post-deployment verification results. It must never archive database passwords, access tokens, JWT secrets, Vault keys, user data, or storage object contents. A failed migration must stop the job and preserve logs; it must not silently mark the ledger applied.

## Staging-to-production control sequence

The safe sequence is: create or update the reviewed baseline in a branch; run local reset or disposable-database validation; generate and review database types; apply to empty staging after explicit approval; run role-specific security and application smoke tests; record the staging migration ledger and schema hash; obtain production approval; apply the same immutable artifact to production; and record the production ledger, schema hash, and deployment run.

No production deployment should be inferred from a green Vercel build. Vercel proves the application artifact was built and deployed; it does not prove that Supabase schema changes were applied. Likewise, a successful cron job proves only that the deployed route responded successfully under its application contract.

## Ownership gaps that remain

The historical executor identity is unknown. The repository does not contain an authoritative migration deployment workflow. Supabase Management API audit data, private GitHub Actions logs beyond the public run metadata, Vercel deployment details, and any developer-local migration archives were not available through the authorized read-only connectors. These gaps are evidence gaps, not permission to recreate history by assumption.

## Governance decision

Do not replay the historical directory. Establish the new baseline through an explicitly approved, schema-only artifact and introduce a dedicated, protected migration deployment job before any future schema change. Until that job, manifest, identity, and approval gate exist, staging preparation may be designed but not executed.

## References

[1]: https://github.com/ImperioKDB/Scholars/tree/main/.github/workflows "Scholars GitHub Actions workflows"
[2]: https://github.com/ImperioKDB/Scholars/actions "Scholars GitHub Actions runs"
[3]: https://github.com/ImperioKDB/Scholars/blob/main/DEPLOY_TRIGGER.md "Scholars deployment trigger record"
[4]: https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_PHASE_2_1_3_MIGRATION_EXECUTION_OWNERSHIP_AUDIT_2026-11-09.md "Phase 2.1.3 migration ownership audit"
[5]: https://supabase.com/docs/guides/deployment/database-migrations "Supabase database migration deployment"
