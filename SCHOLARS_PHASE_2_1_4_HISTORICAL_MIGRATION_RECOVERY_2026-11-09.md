# Scholars Phase 2.1.4 — Historical Migration Recovery

**Investigation date:** 2026-11-10
**Scope:** Read-only source recovery and strategy assessment. No migrations, database objects, roles, privileges, data, or secrets were changed.

## Finding

The historical production migration chain is **partly irrecoverable from the reachable repository and public GitHub artifacts**. Historical replay must not be used as the staging-baseline strategy.

The current production ledger contains 180 entries. The prior application baseline contains 129 SQL migration files, while current `main` contains 132. A search across all reachable Scholars branches and Git history found 137 distinct migration paths. The prior reconciliation identified 106 single normalized filename matches, 35 ambiguous candidates, and 39 entries with no candidate path. None of the 106 matches has been upgraded to exact or equivalent SQL content because the production migration bodies were not available for byte-level comparison. [1]

## Recovery work performed

All reachable remote branches, tags, deleted paths visible through Git history, migration commits, repository documentation, workflow files, and pull-request branch tips were inspected. The branch set includes the current main line and feature branches for discovery, analytics, notifications, opportunities, OTP, Resource Center, and verified scholarship work. No additional source tree containing the 74 unresolved or ambiguous entries was recovered.

The pull-request inventory did not reveal a separate migration archive or a production migration export. The relevant PRs and branches are application feature branches, dependency updates, deployment retriggers, or merges of work already represented in the reachable history. Repository history does contain migration-related notes such as “reference migration” and “mark migration applied,” plus duplicate numeric prefixes and overlapping historical migration themes. These are evidence of an untidy migration process, not a recoverable canonical execution chain.

The repository CI workflow runs type checking, tests, and a production build with placeholder public Supabase values. The scheduled workflows call deployed application endpoints using `CRON_SECRET`; they do not invoke `supabase db push`, `supabase db pull`, `supabase db diff`, `supabase db dump`, or a migration runner. Recent successful GitHub Actions runs therefore establish application-job or build success, not database migration execution. [2]

The repository has a deployment-trigger document explaining that commits trigger Vercel builds, but no checked-in deployment record maps the production migration ledger to an executor identity, source manifest, or SQL artifact. [3]

## Classification of the 74 entries

The 35 ambiguous entries have nearby repository candidates whose names or object themes overlap, but filename similarity, table presence, or current schema shape is not sufficient evidence of SQL equivalence. The 39 missing entries have no source path in reachable Git history. They include early authorization/profile changes, several scholarship verification batches, backfills, opportunity setup steps, and later application/opportunity adjustments.

The three latest ledger entries do have timestamped source paths in current `main`: the Airtel application-route correction, the Kayode/NNPC source re-verification, and the Airtel eligibility update. This makes their repository provenance traceable, but it still does not independently prove that the production file body is identical to the applied body without a production-side source export.

## Can more recovery realistically succeed?

Further recovery from public Git history is unlikely to materially improve the result. The reachable branch graph is broad and includes the feature branches most likely to contain the missing work. The remaining evidence needed is outside the repository: a migration-runner export containing source SQL, a CI/CD artifact archive, a Supabase project-admin audit export, or an immutable backup of the exact migration files used at execution time.

A project administrator may still recover additional evidence from private GitHub Actions logs, Vercel deployment metadata, Supabase Management API audit records, or local developer workstations. Those sources were not available through the authorized read-only connectors in this session. They should be treated as evidence collection, not an invitation to infer SQL from the live database.

## Decision

Strategy A, “recover and replay the historical migration chain,” is not a safe reproducible route. It fails the required source and content provenance test, and replaying the repository directory could create a schema that differs from production in both objects and security behavior. The historical chain should be declared **partly irrecoverable** unless a project administrator supplies the missing source artifacts.

The historical migration report from Phase 2.1.3 remains the row-level manifest. This report adds the recovery conclusion: stop spending operational risk on replay attempts and evaluate a separate reviewed schema-only baseline instead.

## References

[1]: https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_PHASE_2_1_3_MIGRATION_PROVENANCE_RECONCILIATION_2026-11-09.md "Phase 2.1.3 migration provenance reconciliation"
[2]: https://github.com/ImperioKDB/Scholars/tree/main/.github/workflows "Scholars GitHub Actions workflows"
[3]: https://github.com/ImperioKDB/Scholars/blob/main/DEPLOY_TRIGGER.md "Scholars deployment trigger record"
[4]: https://github.com/ImperioKDB/Scholars/commit/cf3682ce35912df7b9b9352193630fc404427c7c "Scholars application baseline"
