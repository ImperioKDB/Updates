# Serena Stage 2/3 Corrective Audit

**Date:** 2026-11-06  
**Scope:** Recovery-source reconstruction, atomic finalization, production migration alignment, backend-role access, security grants, Vercel runtime, and release-candidate preparation.  
**Execution boundary:** Investigation and local preparation only. No production database objects, Vercel settings, environment values, Git remotes, branches, or deployments were changed.

## Executive decision

**Status: BLOCKED — source artifact recovered and verified, but not release-ready.** The claimed recovery commit object could not be recovered, but the preserved full patch applies cleanly to the specified baseline and all 16 changed-file hashes match the supplied checksum manifest. The report contradiction is resolved: the recovered PostgreSQL path does **not** finalize an analysis attempt, the saved task result, and terminal lifecycle events in one transaction. Production migration effects are consistent with the five local migration definitions, but all five local version prefixes differ from the production migration ledger. The actual Vercel database username remains unverified. Do not deploy this recovery version or apply its migration until these blockers are resolved.

## 1. Recover and verify the implementation

**VERIFIED:** The patch `/home/ubuntu/projects/serena-4c43329d/Serena_Recovery_Engine_COMPLETE.patch` is 92,964 bytes and its SHA-256 is `563c58a0e21c139734ee5c2935c26899d99f89552713474bb3e52b96748346f5`, matching the supplied manifest. A clean clone of `ImperioKDB/serena` was checked out at baseline `6bb268b216b6250e4ae64b73b9f6c2a85f31e686`, parent `76a470a3fd8b1c2de2adadea5939db41311deb72`. `git apply --check` passed and the patch applied. Its 16 actual changed paths exactly equal the 16-file manifest; all 16 per-file SHA-256 values match `Serena_Recovery_Engine_CHECKSUMS.md`. The expected `supabase/migrations/20261103090000_research_analysis_attempts.sql` exists in the reconstructed tree and hashes to `3a39b15c898afdac156de31c39ec4bab4ee8f20e79922701c79408a09e4e16fe`. No unexpected patch paths or deleted files were found.

**NOT VERIFIED:** The claimed recovery commit `97ed7b913659d05b920da89477020e822484c671` is not present in the GitHub remote or the fetched Git object database (GitHub API returned no commit; `git cat-file` reports no such commit). Therefore the preserved patch's exact content is verified, but its claimed association with that commit is not. The patch applies to the exact stated parent baseline; that is the strongest available provenance here. Previous Milestone 2 verification evidence was not among the shared files or uploaded artifacts; the prior manifest is a summary, not the test-run log.

**VERIFIED:** “No unrelated changes” holds relative to the patch manifest: 16 listed files changed, exactly those same 16 paths present, no unexpected paths. `git diff --check` passed. Applying the patch reported five trailing-whitespace lines in its new handoff Markdown file; the supplied manifest says these are intentional Markdown hard-break spaces.

**Candidate status:** The reconstructed source is available locally in `/tmp/serena-corrective-audit`, with locked dependencies installed and browser test prerequisites added to the sandbox. This is a **review-only recovered candidate**, not a published branch and not a corrected release candidate. No remote commit, PR, or push was created.

## 2. Atomic finalization verification

**VERIFIED — atomicity is missing.** Direct inspection of `src/research/research-analysis-service.ts` shows that the success path separately awaits `updateAnalysisAttempt(...completed...)`, `updateResearchResult(...)`, then `appendEvent(...)` for `analysis_provider_succeeded` and `analysis_attempt_completed`. The failure path separately awaits `updateAnalysisAttempt(...failed...)`, `updateResearchResult(...)`, `appendEvent(...)` for `analysis_provider_failed`, and `appendEvent(...)` for `analysis_attempt_completed`.

In `src/persistence/postgres-task-repository.ts`, these methods each issue an independent `this.sql` statement. The repository has no transaction wrapper around these terminal writes and does not call `this.sql.begin(...)`. `max: 1` in the postgres.js connection-pool options is not a transaction. Thus a process termination or database error after one statement can leave an attempt marked completed/failed while the task result and event history disagree, or leave only some terminal events persisted. The old Milestone 2 statement that terminal finalization was transactional is contradicted by the source and is **not supported**. Unit tests with a mock repository cannot establish database transaction behavior.

**Precise correction required before release:**

- `src/persistence/task-repository.ts`: replace or supplement the independent terminal-update/result-write interface with a `finalizeAnalysisAttempt(...)` operation carrying the attempt ID, terminal status and fields, task ID, final result JSON, and the terminal event payloads.
- `src/persistence/postgres-task-repository.ts`: implement that operation using one `this.sql.begin(async tx => ...)` transaction. Within it, lock the task row (`SELECT ... FOR UPDATE`) to serialize event-sequence assignment, update exactly the running attempt, update the task result with the existing newer-attempt guard, and insert both required terminal event rows. Verify each expected row was affected; throw on mismatch so the whole transaction rolls back. Reuse the transaction-scoped `tx` for every statement. The existing `appendEvent` uses `max(sequence_number)+1`; it must be made safe for concurrent writers by taking the task-row lock inside the transaction or using another sequence allocator with equivalent serialization.
- `src/research/research-analysis-service.ts`: invoke the repository’s atomic operation once for success and once for failure. Keep model execution outside the DB transaction. Define behavior if failure-finalization itself fails (log a safe, non-sensitive operational error; leave the attempt recoverable by stale-attempt reclamation rather than claiming it finalized).
- `src/persistence/in-memory-task-repository.ts` and `tests/research-analysis-service.test.ts`: implement and test the same contract. Add tests proving all terminal state/result/event changes commit together or none do, that the older-attempt guard is preserved, and that event sequence allocation is serialized.

No source fix was made during this audit. Implement it in a separately reviewed corrective change, then rerun the suite and all checks.

## 3. Migration-history comparison

Production project `serena` (`nmlhcofasxsngmvjjxti`) reports PostgreSQL 17.11.0.003. Its migration ledger contains these versions (read-only Supabase migration listing):

| Production version / name | Local candidate filename | Production effect comparison | Classification |
|---|---|---|---|
| `20261011185158 / initial_research_tasks` | `20261011195000_initial_research_tasks.sql` | **VERIFIED structurally** against current catalog: `research_tasks`, `execution_events`, primary/foreign keys, status check, sequence uniqueness, and indexes are present with the expected definitions. | Version mismatch |
| `20261012112654 / research_sources_evidence` | `20261012122500_research_sources_evidence.sql` | **VERIFIED structurally** against current catalog: source/evidence columns, cascading FKs, verification-status check, and task/created indexes match expected effects. | Version mismatch |
| `20261012113049 / enable_rls_on_research_tables` | `20261012123000_enable_rls_on_research_tables.sql` | **VERIFIED:** RLS is enabled for the four research tables; no policies were found. | Version mismatch |
| `20261012195728 / request_admission_limits` | `20261012204800_request_admission_limits.sql` | **VERIFIED:** window/lease table columns, constraints, indexes, RLS and function behavior match. `pg_get_functiondef` for both functions matches the checked-in logic (normalized PostgreSQL rendering); functions are `SECURITY DEFINER`, use `search_path=pg_catalog, public`, deny execute to `anon`/`authenticated`, and grant it to `service_role`/`postgres`. | Version mismatch |
| `20261012212648 / research_task_owner` | `20261012222000_research_task_owner.sql` | **VERIFIED structurally:** `research_tasks.owner_id` FK to `auth.users(id)` with cascade and the owner/created partial index exist. | Version mismatch |
| Not applied | `20261103090000_research_analysis_attempts.sql` | **VERIFIED absent:** `to_regclass(...)` returned null and no production migration-history row exists for version `20261103090000`. | Intended pending migration |

**Limits:** Production catalogs verify current effects and the deployed function definitions; they do not retain the original historical SQL bytes for an exact source-to-source hash comparison. The claim above is structural/effect equivalence, not cryptographic proof that historical SQL text exactly equals current repository text.

**Migration safety finding:** Supabase migration reconciliation uses migration version IDs, not matching human-readable names. Because all five local versions differ from the five remote versions, an unchanged local tree would show five local migrations whose versions are absent remotely, alongside five remote-only versions. Thus the current tree cannot safely establish that only the recovery migration is pending. The Supabase CLI is not installed here, and no CLI `migration list` or `db push` command was run. The attached absolute restrictions expressly prohibit running `db push`; no `db push --dry-run` was invoked. This leaves CLI status behavior **NOT VERIFIED**, while the version mismatch itself is **VERIFIED**.

**Safe reconciliation proposal:** In a dedicated corrective branch, rename the five existing local migration files to these production version prefixes while preserving the corresponding name suffix and byte-identical SQL: `20261011185158_initial_research_tasks.sql`, `20261012112654_research_sources_evidence.sql`, `20261012113049_enable_rls_on_research_tables.sql`, `20261012195728_request_admission_limits.sql`, and `20261012212648_research_task_owner.sql`. Do not edit the remote history. Then, using a linked approved checkout, run only the read-only `supabase migration list --remote` and verify that all five versions pair as applied and only `20261103090000` is pending. Stop if any other version appears. Because migration-list CLI execution was unavailable in this audit, this reconciliation remains proposed and unexecuted.

## 4. Backend database role and table privileges

**VERIFIED:** The Vercel backend project is `serena`, project ID `prj_isitPHfi6fA9dHXAM10InktZsa9H`. A production-target `DATABASE_URL` variable exists in Vercel and is marked sensitive. The deployment source reads `process.env.DATABASE_URL` and passes it to `PostgresTaskRepository`. The Vercel environment listing was requested with decryption disabled; this report does not reproduce any environment-variable values.

**NOT VERIFIED / BLOCKED:** The actual database username/role in that URL could not be determined from Vercel’s non-decrypted environment metadata. The Supabase MCP SQL session returned `postgres`, but that is its administrative connection and is not evidence of the Vercel backend role. Do not assume `postgres` or `service_role` is used by the backend. Consequently, actual effective privileges for the backend cannot yet be confirmed.

Production role attributes show `service_role` has `BYPASSRLS`; `anon` and `authenticated` do not. Existing default ACLs grant table privileges to client roles as well as server roles for public tables. The proposed recovery migration enables RLS but creates no policies. RLS default-deny prevents ordinary row access without a policy, but it is not a substitute for table ACLs (e.g. table-wide operations such as `TRUNCATE` are not governed by RLS).

**Decision:** Explicitly revoke client/public table privileges in the migration. Then grant only the required table operations to the confirmed server role if it is not the owning role. The role itself must be confirmed by an owner-controlled, secret-safe procedure that outputs only `current_user`/`session_user`; never print or paste `DATABASE_URL` or its password.

**Proposed SQL for review only — not applied:**

```sql
alter table public.research_analysis_attempts enable row level security;
revoke all privileges on table public.research_analysis_attempts
  from public, anon, authenticated, service_role;
-- If the confirmed application database role is service_role:
grant select, insert, update on table public.research_analysis_attempts
  to service_role;
```

If the backend connects as a distinct non-owner role, replace or supplement the grant with `SELECT, INSERT, UPDATE` to that exact verified role. If migrations run as `postgres`, it will own the table and retain owner privileges regardless of ACL revokes; do not use that owner connection as the application role if a least-privilege runtime role is available. Do not add RLS policies. Do not grant DELETE/TRUNCATE unless a separate reviewed use case requires it. The grant statements should be finalized only after confirming role ownership and connection behavior; the above block is not an instruction to execute now.

## 5. Stage 2 runtime reassessment

**VERIFIED:** The Vercel project is the Fastify backend `serena`; the current production deployment is still the baseline commit, so it has no recovery-analysis endpoint. Runtime is Node.js `24.x`; framework metadata is Fastify; Vercel reports one Lambda deployment in `iad1`. There is no `vercel.json` or `vercel.ts` override in the baseline or recovered patch. The Fastify source entrypoint is `src/server.ts`, and Vercel’s Fastify deployment model treats the app as a single Function. The relevant Vercel dashboard setting is **Settings → Functions → Function Max Duration → Default Max Duration**. Official Vercel duration documentation also allows applicable function-level config, depending on the framework/runtime entrypoint.

The project API and deployment metadata do not expose the saved Function Max Duration or generated function override. The previous report’s 300-second screenshot claim is not current evidence. Vercel’s official documentation describes the Hobby ceiling as up to 300 seconds under the applicable configuration, but a plan ceiling is not proof of this project’s effective function value.

**Verified budget in the recovered code:** `evidenceAnalysisTimeoutMs` defaults to 15,000 ms. `ResearchAnalysisService` wraps the model/provider chain in one 15-second bounded timeout and passes an abort signal. The Gemini provider allows at most two network attempts, each capped at 6,000 ms, with a 250 ms first retry delay (maximum nominal provider work 12.25 seconds) and the outer 15-second abort budget. A provider chain, including fallback providers, shares that same outer signal/deadline. Therefore the bounded model operation itself is designed to fit inside 15 seconds.

**Not enough to prove full handler fit:** SQL material loads, three pre-model lifecycle writes, time to serialize/send the response, and the failure/success terminal persistence sequence occur outside that 15-second model budget. In particular, terminal DB/event writes currently have no separate deadline and are non-atomic. Thus a 15-second effective Vercel limit is insufficient; a verified limit comfortably above 15 seconds is required. A 60-second effective limit would leave 45 seconds for non-model work; 300 seconds would leave 285 seconds, but neither value is presently verified for this deployed configuration. The code currently constructs Fastify with `requestTimeout: 15_000`; this source setting should not be mistaken for Vercel’s function `maxDuration`.

**Safest verification:** Before authorizing production deploy, inspect the exact deployment’s effective per-function configuration from Vercel’s deployment detail/CLI or dashboard and capture `maxDuration`, runtime, region, and the project Default Max Duration setting. Confirm there is no function-level override. After any separately approved deployment, verify the generated Function configuration again and run an authenticated, owner-approved canary against a task with saved evidence; record measured wall time and terminal persistence events. No Vercel settings were changed and no deployment was triggered.

## 6. Local verification performed

All checks below were performed in the isolated reconstructed worktree against the exact baseline plus preserved patch; no production endpoint was called.

| Check | Result |
|---|---|
| `git apply --check` | **PASS** |
| Patch application to exact baseline | **PASS**, 16 changed paths |
| Per-file SHA-256 vs supplied manifest | **PASS**, 16/16 |
| Manifest path set vs actual changed path set | **PASS**, 16/16 exact |
| `git diff --check` | **PASS** |
| Backend typecheck (`pnpm typecheck`) | **PASS** |
| Backend build (`pnpm build`) | **PASS** |
| Backend ESLint (`pnpm lint`) | **PASS** |
| Frontend typecheck | **PASS** |
| Frontend production build | **PASS** |
| Backend tests | **PASS**, 20 files / 129 tests after installing pinned Playwright Chromium and setting `--maxWorkers=1 --minWorkers=1` |
| Focused Prettier check | **FAIL** for `frontend/src/components/ResearchHistory.tsx` and `src/api/app.ts` under locked-resolved Prettier 3.9.10; those same clean-baseline versions pass with the same Prettier, so formatting differences were introduced by the patch. Other supported changed text/source files passed. The SQL migration was excluded because this Prettier configuration has no SQL parser. |
| Full repository `pnpm format:check` | **FAIL**, reports formatting warnings in 15 repository files |
| Supabase CLI migration list | **NOT RUN** — Supabase CLI not installed; no authenticated local CLI link available |
| `db push`, `migration repair`, migration application | **NOT RUN** — expressly prohibited |
| Production Vercel configuration/role tests | **NOT RUN** |

The first test attempt failed because Chromium was absent; after installing the pinned Playwright Chromium, one parallel-run browser fixture timed out. A subsequent bounded-worker full run passed all 129 tests. A separate test invocation with inconsistent worker bounds produced a Vitest configuration error and did not execute tests. Only the final 20/129 run is the successful backend-suite result.

## 7. Release-candidate readiness and blockers

**BLOCKED — not safe to publish as a release candidate yet:**

1. Fix atomic terminal finalization in the three identified persistence/service files and both repository implementations; add transactional failure-injection tests.
2. Correct the two changed-file Prettier issues (`frontend/src/components/ResearchHistory.tsx`, `src/api/app.ts`) without broad unrelated formatting changes; re-run focused format and lint/tests.
3. Reconcile the five old local migration version prefixes in a reviewed local branch and run the read-only Supabase migration-list comparison; verify only the recovery migration remains pending. Do not repair production history.
4. Confirm the actual Vercel backend database role without exposing credentials; determine whether the final migration must grant access to `service_role` or another role.
5. Approve the proposed explicit revocations and precise server-role grant.
6. Capture current project-level Function Max Duration and future deployed function-level duration; the current deployment cannot verify the recovery endpoint.
7. The recovery SHA itself remains unavailable; use the verified patch and checksum provenance rather than claiming the missing commit has been restored.
8. The previous Milestone 2 detailed evidence file remains unavailable; this new test run supersedes its status for the checks actually rerun here.

No source code was altered to fix any of these issues. No branch, commit, PR, or remote update was created.

## 8. Proposed sequence for Stage 4 onward

1. **Owner review:** accept or amend the atomicity correction, migration-renaming plan, revocation/grant SQL, and verified-role acquisition method.
2. **Corrective local implementation:** make the atomic-finalization and focused-format corrections on a dedicated local branch from the verified baseline; add and run regression tests.
3. **Migration alignment:** rename the five existing migration prefixes to production versions in that branch, preserving SQL bytes; run the read-only CLI status command and confirm precisely one pending migration (`20261103090000`). Do not run `db push` or repair.
4. **Release-candidate checks:** rerun complete backend/frontend test, typecheck, build, lint, format, patch/path/checksum verification, static SQL/security review, and capture logs. Recompute the full checksum manifest for the corrected source; do not reuse old patch hashes.
5. **Stage 4 production migration:** only after a separate exact approval of the migration file/checksum, project ref, grants/RLS behavior and backup/forward-fix plan, apply through the approved tracked migration mechanism, then perform read-only post-apply schema/history checks.
6. **Stage 5 review/publishing:** prepare a named branch/PR containing only reviewed recovery changes and migration filename reconciliation. Publishing that branch/PR requires separate explicit authorization; no push is approved by this audit.
7. **Stage 6 deployment/runtime:** verify project setting and generated function configuration, then deploy only after separate explicit approval. Confirm deployed SHA, endpoint presence, runtime, region, effective duration, health/log behavior, and least-privilege database role.
8. **Stage 7 live validation:** after deployment approval, use an owner-approved authenticated test task with saved evidence; verify attempt/result/event transaction consistency, idempotency, failure handling, duration, and no unauthorized client database access. Require separate confirmation before any consequential external actions.

## Sources and evidence references

- Supabase production project/migration metadata and bounded catalog reads, inspection time 2026-11-06.
- Vercel project/deployment metadata and non-decrypted environment-name listing, inspection time 2026-11-06. No environment values are reproduced here.
- Supabase official migration guidance: https://supabase.com/docs/guides/deployment/database-migrations
- Vercel official function-duration guidance: https://vercel.com/docs/functions/configuring-functions/duration
- PostgreSQL 17 row security: https://www.postgresql.org/docs/17/ddl-rowsecurity.html
- PostgreSQL 17 constraints: https://www.postgresql.org/docs/17/ddl-constraints.html


## Corrective follow-up — local-only work completed at 2026-11-06 16:18 CET

This section supersedes the earlier sections’ statements that no corrective code or migration filename changes had been made. After reporting the discrepancy and proposing the fix, I continued the user-authorized local work on the dedicated local Git branch `serena/recovery-corrective-2026-11-06` in `/tmp/serena-corrective-audit`. This branch has no commit and no remote tracking/push.

**Atomic finalization corrected in the local candidate:** Added `TaskRepository.finalizeAnalysisAttempt(...)`, implemented it in the in-memory and Postgres repositories, and refactored the service so only model/validation errors become analysis failures. A terminal persistence/commit failure now propagates rather than being misreported as a model failure or retried as a failed finalization. Postgres finalization uses `this.sql.begin(...)` for the active-attempt status, guarded task-result update, and terminal event inserts. It locks the task row and verifies affected rows; all SQL uses the transaction handle. `appendEvent` now locks the task row and inserts the event (and `task_started` status, when applicable) inside one transaction, serializing the existing `max(sequence_number)+1` allocator among repository writers. The in-memory implementation serializes payloads and validates preconditions before mutating state. Added service-level regression coverage for persistence-error propagation and an in-memory test for payload-prevalidation atomicity.

**Verification limitation:** The source-level transaction path and unit behavior are verified, but a failure-injection integration test against a real PostgreSQL transaction was not run; no writable development database was made available, and production remains read-only. Transaction rollback semantics therefore still need the dedicated Postgres integration test in a safe non-production database before approval to migrate/deploy.

**Migration alignment completed locally:** Renamed the five historical local migration files to the exact five production version prefixes recorded in the Supabase ledger. Each renamed file’s bytes are identical to the corresponding original `HEAD` file (five `SAME_SQL` comparisons). The read-only Supabase production migration listing still returns exactly those five versions. The local migration directory now has those five matched versions plus `20261103090000_research_analysis_attempts.sql`; this yields the intended single-new-version set by version comparison. The Supabase CLI itself remains unavailable, so `supabase migration list --remote` was not executed. No `db push`, migration repair, apply, or production write was run.

**Privilege update:** The local recovery migration now explicitly revokes all table privileges from `PUBLIC`, `anon`, and `authenticated`, in addition to RLS with no policies. It intentionally does not yet set the precise server-role ACL: the Vercel `DATABASE_URL` role remains unknown. `service_role` defaults and a non-owner runtime grant cannot be safely finalized until the actual runtime role is confirmed. The server-role grant and any revoke/regrant to `service_role` remain a stop condition before applying the migration.

**Current local checks:** Focused Prettier check on all supported recovery-touched Markdown/TS/TSX files **PASS**; backend typecheck **PASS**; backend build **PASS**; backend ESLint **PASS**; backend tests **PASS — 20 files, 131 tests**; frontend typecheck **PASS**; frontend production build **PASS**; `git diff --check` **PASS**. No real-Postgres transaction integration test or Vercel setting verification was performed. The prior full repository `pnpm format:check` failure was on 15 files before fixing the two patch-introduced warnings; full-repo format was not rerun because it also includes unrelated baseline files. The changed-file formatting check is clean.

**Candidate delivery:** The separate `Serena_Recovery_Corrective_Candidate_Manifest_SHA256_2026-11-06.md` records the corrected local candidate’s current changed-path hashes and archive checksum. The archive `Serena_Recovery_Candidate_CORRECTED_LOCAL_2026-11-06.tar.gz` contains the exact baseline plus the recovery patch, the local atomicity/format/security changes, and the five filename-only historical migration renames. This is a locally verified **corrective candidate**, not a deployable release: role-specific database grants, a safe PostgreSQL rollback integration test, Supabase CLI status, Vercel duration, and separate production/publishing approvals remain pending.
