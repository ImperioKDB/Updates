# PR #31 — GitHub Actions Queue Diagnosis and Independent Verification

**Repository:** ImperioKDB/Scholars  
**PR:** https://github.com/ImperioKDB/Scholars/pull/31  
**PR head SHA:** f176ac62b21651e8217ceeade091ae39380ef9ed  
**PR run #505:** 43097688631  
**Main-branch run #504:** 43097057680  
**Comparison run #503:** 43093834073  
**Report date:** 2026-11-11  
**Merge/deploy performed:** None (per task restrictions)

---

## 1. Exact cause (established)

**GitHub-hosted runner queue/capacity issue — not source code, not concurrency, not workflow configuration.**

Both the PR run (#505) **and** the main-branch push run (#504) are simultaneously in `queued` status with **zero jobs assigned**. Because a main-branch run (unrelated to PR #31's code) is also stuck queued, the blockage cannot be attributed to PR #31's source code, its CI configuration, or a repository-specific concurrency lock. The shared factor is GitHub's hosted-runner pool (the workflow's `runs-on: ubuntu-latest`), which is backed up and has not yet assigned a runner to either job.

This is consistent with Stage 1 guidance: do not assume the source code is responsible for a run that has no jobs assigned.

---

## 2. GitHub run and job statuses

Inspected via authenticated `gh api` against the live repository.

### Run #505 — PR #31 (the queued run under investigation)

| Field | Value |
|---|---|
| Run number / ID | 505 / 43097688631 |
| Event | pull_request |
| Head branch | fix/combobox-preserve-controlled-value-clean |
| Head SHA | f176ac62b21651e8217ceeade091ae39380ef9ed |
| Status | **queued** |
| Conclusion | null (not yet run) |
| Created / updated | 2026-11-11T20:43:05Z / 2026-11-11T20:43:05Z |
| Run attempt | 1 |
| Jobs assigned | **none** (empty jobs array) |
| HTML URL | https://github.com/ImperioKDB/Scholars/actions/runs/43097688631 |

### Run #504 — main-branch push (also queued; intentionally NOT cancelled)

| Field | Value |
|---|---|
| Run number / ID | 504 / 43097057680 |
| Event | push |
| Head branch | main |
| Head SHA | de0eab425634443129be500e409a5fb82a0a4611 |
| Status | **queued** |
| Conclusion | null (not yet run) |
| Created / updated | 2026-11-11T20:36:32Z / 2026-11-11T20:36:32Z |
| Jobs assigned | **none** (empty jobs array) |
| HTML URL | https://github.com/ImperioKDB/Scholars/actions/runs/43097057680 |

### Run #503 — recent successful main push (comparison)

| Field | Value |
|---|---|
| Run number / ID | 503 / 43093834073 |
| Event | push |
| Head branch | main |
| Status / conclusion | completed / **success** |
| Job | `build` — ran on `ubuntu-latest`, GitHub Actions runner group, runner id 1000005501 |
| Started / completed | 2026-11-11T20:09:28Z / 2026-11-11T20:10:57Z |

### Concurrency / repository configuration checks

- Workflow `.github/workflows/ci.yml` uses `runs-on: ubuntu-latest`, `node-version: 20`, `timeout-minutes: 15`, and concurrency group `ci-${{ github.ref }}` with `cancel-in-progress: true`.
- Concurrency is **not** blocking either run: run #503 (main) already completed, so the `ci-refs/heads/main` group is free; the PR run uses its own group `ci-refs/pull/31/merge` with no in-progress sibling.
- Repository is not archived or disabled (`disabled: false`, default branch `main`). Actions runs are being triggered, so Actions is enabled at the repo level.
- Could not read `actions/permissions` or self-hosted runners (HTTP 403) — a token-permission limitation, not evidence of misconfiguration; run #503 proves the hosted `ubuntu-latest` runner path works.
- No production credentials used anywhere; CI placeholder Supabase values match `ci.yml`.

---

## 3. Node version used

**Node.js v20.20.2 (npm v10.8.2)** — matching `.github/workflows/ci.yml` (`node-version: 20`). Installed via nvm in an isolated environment solely for verification; the host shell otherwise defaults to Node v24.22.2.

---

## 4. Results of all four verification commands

Executed in an **isolated detached worktree** at `/tmp/opencode/pr31-verification` checked out at the exact PR head SHA `f176ac6`. The existing working branch and `main` were not touched (see section 6).

| # | Command | Exit code | Result |
|---|---|---|---|
| 1 | `npm ci` | **0** | Success. 446 packages added. Non-fatal `EBADENGINE` warnings only (for `@supabase/*` requiring Node ≥22); they do not fail the install. |
| 2 | `npx tsc --noEmit` | **0** | Passed — no type errors. |
| 3 | `npm test` (`vitest run`) | **0** | **Test Files 20 passed (20); Tests 108 passed (108).** Includes `components/Combobox.test.tsx` 8/8. The `lib/sitemap-data.test.ts` stderr line (`[sitemap] failed to read public opportunities Error: network unavailable`) is the intentional "fails closed" case, not a failure. |
| 4 | `npm run build` | **0** | Production build completed successfully with CI placeholder Supabase values (`NEXT_PUBLIC_SUPABASE_URL=https://placeholder.supabase.co`, `NEXT_PUBLIC_SUPABASE_ANON_KEY=placeholder-anon-key`). All static pages prerendered; sitemap.xml emitted. |

No production credentials were used; only the placeholder Supabase values defined in CI.

---

## 5. Recommended recovery action

**The queued PR run #505 can be safely cancelled and retriggered.** Because it is a pull-request run (not a main-branch run), cancelling and re-running its CI job will not affect `main` or deploy anything. The main-branch run #504 must **not** be cancelled (per restrictions).

Proposed sequence (to be performed only after this diagnosis is reported):
1. Cancel run #505 (PR #31) via the GitHub Actions UI or `gh api -X POST repos/ImperioKDB/Scholars/actions/runs/43097688631/cancel`.
2. Re-trigger CI for PR #31 (e.g., "Re-run jobs" / re-run the `build` job, or push nothing new — simply re-run the existing workflow run).
3. Monitor until a hosted runner is assigned and the job completes.

If runner capacity remains exhausted, an alternative is to wait for GitHub's hosted-runner queue to clear rather than force a retrigger. Do **not** push an empty commit solely to retrigger without first reporting this diagnosis and the proposed action (done here).

**Do not** modify application code or `ci.yml` as part of recovery — neither is the cause.

---

## 6. Whether any repository files or branches were changed

**No.**

- Did not modify `main` (still at `de9b40695e8ebca26d14bcaae972f5c549cdd4f6`).
- Did not alter the existing working branch `fix/combobox-preserve-controlled-value-clean` (still at `f176ac6`, matching the PR head SHA).
- Did not push, merge, delete branches/commits, or rewrite history.
- Did not deploy or change Supabase/Vercel settings or production data.
- The only artifact created outside the repository is an **isolated detached worktree** at `/tmp/opencode/pr31-verification` (HEAD `f176ac6`, detached), used exclusively for Stage 2 verification. It does not affect any existing branch or uncommitted work.
- No files in `/workspaces/Scholars` were created or modified by this investigation other than this report file itself.

---

**Bottom line:** PR #31's CI is stuck because GitHub's hosted-runner queue is backed up (run #504 on main is equally stuck). The PR's code independently verifies cleanly on Node 20 (all four commands pass, 108 tests). Recommended recovery: cancel + retrigger PR run #505 only; leave main run #504 alone.
