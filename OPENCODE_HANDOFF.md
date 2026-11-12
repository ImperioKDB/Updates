# OpenCode Handoff — Scholars Synthetic Schema Extraction

**Prepared for continuation by OpenCode**  
**Evidence publication repository:** [`ImperioKDB/Updates`](https://github.com/ImperioKDB/Updates)  
**Source repository:** [`ImperioKDB/scholars-schema-extraction`](https://github.com/ImperioKDB/scholars-schema-extraction)  
**Main reference commit:** [`40e36dbf9e0d2921433694d5a63c0a10ecdef295`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/40e36dbf9e0d2921433694d5a63c0a10ecdef295)  
**Latest reviewed synthetic branch tip:** [`44ed6c1dceeb09aad0ec0c82c792a362cdfa381a`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/44ed6c1dceeb09aad0ec0c82c792a362cdfa381a)  
**Scope:** documentation handoff only; no workflow was run while preparing this document.

## 1. Executive state

The intended next step is to execute one already-reviewed, synthetic-only restricted extraction experiment. That execution is currently blocked by a concrete GitHub registration condition: the isolated workflow is present on the experiment branch but is **not present on the default `main` branch**, so GitHub does not register it as a manually dispatchable workflow. The current `main` branch contains only the unrelated production schema-only workflow, and the repository README explicitly places that workflow on hold.

The actual Phase 2.1.8 restricted experiment has **not run**. There is no run URL, run ID, job result, sanitized summary artifact, or experiment log for it. A different, earlier synthetic runner-capability preflight did run successfully in `ImperioKDB/Updates` as run [`42838236003`](https://github.com/ImperioKDB/Updates/actions/runs/42838236003); that run tested generic Ubuntu/Docker/PostgreSQL/Supabase CLI mechanics and a simple synthetic schema-only dump. It did **not** run the restricted-role Phase 2.1.8 experiment and must not be treated as evidence that the current experiment passed.

**Current recommendation: NO-GO for dispatch until the owner explicitly registers the exact reviewed isolated workflow on `scholars-schema-extraction/main` or selects another approved execution path.** Do not dispatch the production `schema-only.yml` workflow. Do not connect to Supabase.

## 2. Mandatory safety restrictions

The following restrictions are hard boundaries for OpenCode:

- Do not connect to production Supabase.
- Do not connect to staging Supabase.
- Do not populate or use `SUPABASE_DB_URL`.
- Do not extract production schema or application data.
- Do not import anything into staging.
- Do not modify production or staging database objects.
- Do not merge unrelated pull requests.
- Do not modify the Scholars application repository during this experiment.
- Do not change repository secrets, permissions, or settings.
- Do not run unrelated GitHub Actions workflows.
- Do not publish credentials, passwords, raw database dumps, or sensitive artifacts.
- Do not alter the isolated experiment source while executing it.

The authorization is limited to the previously reviewed **synthetic-only** experiment. It does not authorize production extraction, staging restoration, deployment, credential creation, or database changes.

## 3. Repository and branch state verified

### Source repository

At the inspected remote state:

- `main` tip is [`40e36dbf9e0d2921433694d5a63c0a10ecdef295`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/40e36dbf9e0d2921433694d5a63c0a10ecdef295), titled `docs: hold schema extraction pending read-only controls`.
- `main` contains `.github/workflows/schema-only.yml` only; it has no `experiment/` directory and no `.github/workflows/isolated-schema-proof.yml`.
- The README at `main` says `HOLD`, prohibits creating/populating `SUPABASE_DB_URL`, and says not to run the production workflow because its current design does not enforce a read-only database role.
- The isolated branch `experiment/phase-2-1-8-isolated-proof` points to [`44ed6c1dceeb09aad0ec0c82c792a362cdfa381a`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/44ed6c1dceeb09aad0ec0c82c792a362cdfa381a), titled `fix: enforce dollar quote token boundaries`.
- No pull requests were returned for the source repository at inspection time.

### Exact reviewed experiment files

At source commit `44ed6c1dceeb09aad0ec0c82c792a362cdfa381a`:

| Path | Purpose | Git blob SHA |
|---|---|---|
| `.github/workflows/isolated-schema-proof.yml` | Manual dispatcher, disposable PostgreSQL service, exact branch checkout, runner invocation, sanitized one-day artifact upload, cleanup | `cec5deaf2d887834850f42f18495ab9d330ee0a7` |
| `experiment/schema.sql` | Synthetic schema, roles, grants/revokes, RLS policies, functions, trigger, and fabricated rows used only in the disposable database | `338261db6d6b2388f23a6a3a738bb6e0f5900433` |
| `experiment/run.sh` | Password-authenticated setup/assertions, extraction commands, object inventories, diagnostics, lexical data exclusion, forbidden-operation tests, sanitized summary, fail-closed aggregate | `4746b410754d5b839c520bf7d40585f2b8eaaa87` |

Direct source links: [workflow](https://github.com/ImperioKDB/scholars-schema-extraction/blob/44ed6c1dceeb09aad0ec0c82c792a362cdfa381a/.github/workflows/isolated-schema-proof.yml), [schema](https://github.com/ImperioKDB/scholars-schema-extraction/blob/44ed6c1dceeb09aad0ec0c82c792a362cdfa381a/experiment/schema.sql), [runner](https://github.com/ImperioKDB/scholars-schema-extraction/blob/44ed6c1dceeb09aad0ec0c82c792a362cdfa381a/experiment/run.sh).

> Note: the schema URL above should be checked by OpenCode before use; the authoritative source identifier is the exact commit and blob SHA in the table. If a copied URL contains a typographical path error, use the commit/path URL generated directly from GitHub rather than guessing.

### Workflow properties at the reviewed branch tip

The isolated workflow is `workflow_dispatch` only. It accepts `experiment_ref` and requires the exact value `experiment/phase-2-1-8-isolated-proof`. Its job condition also requires the workflow to be running from `refs/heads/main` and the expected repository. It uses `postgres:16.4-bookworm` with synthetic `bootstrap`/`synthetic` service settings, injects a generated restricted password, and does not use Supabase credentials or production/staging URLs.

The workflow checks out only the exact experiment branch, then compares the checked-out `HEAD` SHA to the remote tip of that exact branch. It scans the three experiment files for prohibited production/staging references, installs pinned PostgreSQL client 16 and Supabase CLI `2.122.1`, runs `experiment/run.sh`, publishes only the sanitized `summary.md` for one day, and removes temporary credentials/results. The dispatcher file itself is not registered on `main`.

## 4. Actual execution evidence

### Restricted Phase 2.1.8 experiment

**Status: NOT RUN.** GitHub API inspection found no registered `isolated-schema-proof.yml` workflow on the source repository and no isolated-workflow run or artifact. All recent workflow-run queries for the source repository returned no runs. Therefore the following are unverified for the restricted experiment:

- restricted bootstrap authentication;
- restricted-role authentication and privilege assertions;
- default-privilege test;
- separate RLS test;
- owner-maintenance test;
- `pg_dump --schema-only` output and coverage;
- Supabase declarative/pg-delta output and strict coverage;
- data-exclusion results against real extraction output;
- forbidden-operation SQLSTATE results;
- sanitized summary artifact and job logs.

Do not convert the earlier static fixture results into execution results.

### Separate generic synthetic preflight

A separate workflow in `ImperioKDB/Updates` did run:

- Run: [`42838236003`](https://github.com/ImperioKDB/Updates/actions/runs/42838236003)
- Workflow source commit: [`04cb1e6d87ef5074a18a584cbb26d0a48c706b89`](https://github.com/ImperioKDB/Updates/commit/04cb1e6d87ef5074a18a584cbb26d0a48c706b89)
- Workflow: `scholars-runner-preflight.yml`
- Event: `workflow_dispatch`
- Result: completed/success
- Job: `Synthetic runner capability check`, job URL [`129906115563`](https://github.com/ImperioKDB/Updates/actions/runs/42838236003/job/129906115563)
- Artifact: none reported

The retrieved log showed Ubuntu 24.04, host PostgreSQL 16.15, container PostgreSQL 17.11 clients, Docker availability, `synthetic_schema_setup=PASS`, schema-only definitions/row exclusion PASS, non-empty dump, redacted SHA-256 calculation, and cleanup PASS. This is useful capability evidence only. It did not use a restricted database role, did not run the current `experiment/run.sh`, and did not contact Supabase.

## 5. Chronological technical history

### Original production extraction investigation

Commit [`f1394d1f68492dee43f461fdd83ab259bab37ad1`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/f1394d1f68492dee43f461fdd83ab259bab37ad1) added `.github/workflows/schema-only.yml`, a manually dispatched production schema-only workflow using `SUPABASE_DB_URL` and a typed production project reference. The workflow still does not prove a read-only PostgreSQL role, exact endpoint, or effective privileges. It can upload a schema artifact and is therefore not the synthetic experiment.

Commit [`40e36dbf9e0d2921433694d5a63c0a10ecdef295`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/40e36dbf9e0d2921433694d5a63c0a10ecdef295) replaced the README with an explicit HOLD. The production workflow was not improved or executed. This is the current `main` reference state.

Earlier investigation reports concluded that production extraction was unsafe without a provider-enforced or otherwise verified read-only source, a dedicated non-owner login, exact endpoint/identity checks, private artifact handling, and an isolated compatibility fixture. The staging project was not a trustworthy baseline because inspected application schemas/migrations did not provide a reliable equivalent application schema; the reports explicitly kept staging restoration and production access out of scope.

### Decision to use an isolated synthetic experiment

Because production credentials and staging restoration were not authorized and the public repositories are unsuitable for sensitive production schema artifacts, the work moved to a disposable PostgreSQL fixture. The synthetic design creates fabricated `app` objects, roles, RLS policies, functions, trigger, sequence, view, default privileges, and deliberately inserted synthetic rows. Extraction must be schema-only and must prove that row data is absent.

### Phase 2.1.8 source evolution

| Commit | Correction |
|---|---|
| [`11cacd6`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/11cacd6eb4a34eff43d6a2d7ac2fa42eaab7afd6) | Added the isolated restricted extraction experiment. |
| [`1621ec0`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/1621ec09875489dd6aab99bc30ea8197f5fb7984) | Corrected object-type-specific validation, role/privilege assertions, data exclusion, default privileges, diagnostics, and branch execution documentation. |
| [`428d441`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/428d44132b1775982a6a7301a738c325e2259d2e) | Completed synthetic validation corrections. |
| [`af5ff5e`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/af5ff5e23581517b60bc4689fc92adc48d6d0d6d) | Finalized password-authenticated disposable service and fail-closed workflow behavior. |
| [`cb434df`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/cb434df2f3e1c910751bb3390197551d5a3448ef) | Made extraction stdout/stderr diagnostics fail closed rather than silently treating warnings as success. |
| [`30eb165`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/30eb1654203bd5597bd545fc5803148ed26365c8) | Replaced generic object-name/data checks with definition-aware scanning and fixtures. |
| [`cb51ed3`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/cb51ed345c5f2ba614317aa44d86a040977bbaa4) | Added lexical fixtures for escaped strings/comments/dollar quotes and exact remote-tip checkout verification. |
| [`69e1142`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/69e11421afdeb7c01765e189fbaeaf75747b19b9) | Corrected PostgreSQL ordinary-string versus `E'...'` escape-string handling under `standard_conforming_strings`. |
| [`e486fd2`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/e486fd2f42fc05cd85f99fcf7ce4aa784a4f2616) | Added EOF failure for unterminated single/double quotes, nested comments, and dollar-quoted strings. |
| [`44ed6c1`](https://github.com/ImperioKDB/scholars-schema-extraction/commit/44ed6c1dceeb09aad0ec0c82c792a362cdfa381a) | Enforced PostgreSQL dollar-quote token boundaries so `$tag$` inside an identifier cannot conceal a later `INSERT`. |

Static fixture checks and shell/YAML checks were run during review. They are not substitutes for the not-yet-run GitHub Actions experiment.

## 6. Scanner coverage and known limitations

The runner's scanner masks ordinary/escape strings, doubled quotes, double-quoted identifiers, dollar-quoted strings with tags, line comments, and nested block comments. It fails closed on unsupported/ambiguous string settings and unterminated lexical constructs. The Phase 2.1.8.8 regression fixture contains an identifier with `$tag$`, a real `INSERT`, and a later valid `$tag$...$tag$`; its scanner-only result is `FAIL` because the `INSERT` is detected.

Known limitations remain:

- This is a custom lexical scanner, not PostgreSQL's parser. It is targeted to the tested constructs and can still have edge cases outside the fixture set.
- Tag and boundary recognition uses the implementation's explicit ASCII identifier grammar; OpenCode should not expand scope into a general parser redesign unless a concrete failing PostgreSQL case is found.
- The data check looks for data-loading statements and known fabricated values; it is not a formal proof that arbitrary sensitive values cannot appear in every possible tool output.
- A successful command exit is not sufficient: the runner also requires non-empty output, definition inventories, diagnostics checks, data-exclusion PASS, role/privilege checks, and every forbidden-operation SQLSTATE assertion.
- The current source has never been exercised end-to-end in the intended restricted-role workflow, so tool privilege compatibility and actual object coverage remain unverified.

## 7. Reports and provenance

The exact source publication and correction reports are in `Updates` review branches. These are evidence of reviewed source/static work, not execution evidence:

- [Phase 2.1.8.1 handoff](https://github.com/ImperioKDB/Updates/tree/docs/phase-2-1-8-1-handoff) — branch tip [`438297a`](https://github.com/ImperioKDB/Updates/commit/438297a1d5b1ea9792daa9055b65c0ea8c9ab36b).
- [Phase 2.1.8.1 source manifest](https://github.com/ImperioKDB/Updates/tree/docs/phase-2-1-8-1-source-manifest) — tip [`02a496b`](https://github.com/ImperioKDB/Updates/commit/02a496be1cac7f390a2166bb291c46f17a4c2b52).
- [Phase 2.1.8.2 validation corrections](https://github.com/ImperioKDB/Updates/tree/docs/phase-2-1-8-2-validation-corrections) — tip [`263b81b`](https://github.com/ImperioKDB/Updates/commit/263b81b34022e78d8e15af3770ffa398f53948eb).
- [Phase 2.1.8.3 final corrections](https://github.com/ImperioKDB/Updates/tree/docs/phase-2-1-8-3-final-corrections-v2) — tip [`e301a34`](https://github.com/ImperioKDB/Updates/commit/e301a34512096062627850e7271e092c20f93b18).
- [Phase 2.1.8.4 review fixes](https://github.com/ImperioKDB/Updates/tree/docs/phase-2-1-8-4-final-review-fixes) — tip [`b870643`](https://github.com/ImperioKDB/Updates/commit/b870643981fbd099a83f45e625b4c209f800a290).
- [Phase 2.1.8.5 scanner/checkout report](https://github.com/ImperioKDB/Updates/blob/docs/phase-2-1-8-5-scanner-checkout-verification/SCHOLARS_PHASE_2_1_8_5_SCANNER_CHECKOUT_VERIFICATION_2026-11-10.md) — tip [`9d36bd1`](https://github.com/ImperioKDB/Updates/commit/9d36bd1f520478b40e0bbc0f6eaa1e3aa971a157).
- [Phase 2.1.8.6 report](https://github.com/ImperioKDB/Updates/blob/docs/phase-2-1-8-6-runner-publication/PHASE_2_1_8_6_UPDATED_COMPLETION_REPORT.md) — tip [`aaf8fc5`](https://github.com/ImperioKDB/Updates/commit/aaf8fc58c241018f98a016056cf66436b2b08bcd).
- [Phase 2.1.8.7 report](https://github.com/ImperioKDB/Updates/blob/docs/phase-2-1-8-7-unterminated-sql-constructs/PHASE_2_1_8_7_UPDATED_COMPLETION_REPORT.md) — tip [`0ea2ad0`](https://github.com/ImperioKDB/Updates/commit/0ea2ad07c71728b3ab448eb1146fe47afddc589c).
- [Phase 2.1.8.8 report](https://github.com/ImperioKDB/Updates/blob/docs/phase-2-1-8-8-dollar-quote-boundary/PHASE_2_1_8_8_UPDATED_COMPLETION_REPORT.md) — tip [`8856534`](https://github.com/ImperioKDB/Updates/commit/8856534937d113be3242ba28545af32833cd981e).
- [Final decision / execution blocker](https://github.com/ImperioKDB/Updates/blob/docs/phase-2-1-8-1-source-manifest/SCHOLARS_PHASE_2_1_8_FINAL_DECISION_2026-11-10.md).
- [Runner diagnostic result](https://github.com/ImperioKDB/Updates/blob/docs/phase-2-1-8-1-source-manifest/SCHOLARS_PHASE_2_1_8_RUNNER_DIAGNOSTIC_RESULTS_2026-11-10.md).
- [Phase 2.1.9 secure capture enablement](https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_PHASE_2_1_9_SECURE_SCHEMA_CAPTURE_ENABLEMENT_2026-11-10.md) — production capture remains blocked pending a private environment and separately approved least-privilege fixture.

## 8. Exact next action

There is one incomplete technical gate before dispatch:

> **Register the exact reviewed `.github/workflows/isolated-schema-proof.yml` on the source repository's `main` branch, or explicitly select an approved execution mechanism that does not require default-branch registration.**

This requires owner approval because it changes the default branch. Do not copy the production workflow, weaken the exact branch/ref guard, change permissions, add secrets, or merge unrelated work. After registration, independently verify that the workflow on `main` has the reviewed blob/source, that the experiment branch still points to `44ed6c1dceeb09aad0ec0c82c792a362cdfa381a`, and that no prior exact successful or active run exists. Then dispatch exactly once with `experiment_ref=experiment/phase-2-1-8-isolated-proof`.

## 9. Conditions before dispatch

1. The isolated workflow exists on `main` and is recognized by the Actions API.
2. It is `workflow_dispatch` only and accepts exactly the intended experiment ref.
3. The workflow source matches the reviewed version and has no production/staging/Supabase secret references.
4. The experiment branch tip and checked-out source hashes match the reviewed source.
5. No exact experiment run is active or already successful; do not duplicate.
6. No production/staging credentials or `SUPABASE_DB_URL` are present or used.
7. The run is dispatched from `main`, exactly once, with the exact experiment ref.

## 10. Evidence required for a successful execution

OpenCode must retrieve the run URL/ID, source commit, job status, sanitized summary artifact, and relevant logs. It must report PASS/FAIL/NOT TESTED/INCONCLUSIVE separately for:

- bootstrap and restricted password authentication;
- role attributes, memberships, effective privileges;
- default privileges on a newly created owner table;
- separate RLS probe;
- owner-maintenance operation;
- `pg_dump --schema-only` exit/non-empty output/diagnostics/object inventory/data exclusion;
- Supabase declarative generation exit/non-empty output/strict coverage/diagnostics/object inventory/data exclusion;
- every forbidden operation and observed SQLSTATE `42501`;
- cleanup and artifact retention.

A green GitHub check alone is insufficient. Missing artifact, missing summary, warnings/errors, skipped mandatory tests, incomplete object inventories, `FAIL`, or `NOT TESTED` in a mandatory check means the recommendation is **NO-GO** or **INCONCLUSIVE**, not PASS.

## 11. Files and links to inspect first

1. This file: `OPENCODE_HANDOFF.md`.
2. `OPENCODE_START_HERE.md`.
3. Source `main` README and production workflow: [README](https://github.com/ImperioKDB/scholars-schema-extraction/blob/40e36dbf9e0d2921433694d5a63c0a10ecdef295/README.md), [schema-only workflow](https://github.com/ImperioKDB/scholars-schema-extraction/blob/40e36dbf9e0d2921433694d5a63c0a10ecdef295/.github/workflows/schema-only.yml).
4. Reviewed experiment [workflow](https://github.com/ImperioKDB/scholars-schema-extraction/blob/44ed6c1dceeb09aad0ec0c82c792a362cdfa381a/.github/workflows/isolated-schema-proof.yml), [schema](https://github.com/ImperioKDB/scholars-schema-extraction/blob/44ed6c1dceeb09aad0ec0c82c792a362cdfa381a/experiment/schema.sql), and [runner](https://github.com/ImperioKDB/scholars-schema-extraction/blob/44ed6c1dceeb09aad0ec0c82c792a362cdfa381a/experiment/run.sh).
5. [Phase 2.1.8 final decision](https://github.com/ImperioKDB/Updates/blob/docs/phase-2-1-8-1-source-manifest/SCHOLARS_PHASE_2_1_8_FINAL_DECISION_2026-11-10.md).
6. [Phase 2.1.8.8 report](https://github.com/ImperioKDB/Updates/blob/docs/phase-2-1-8-8-dollar-quote-boundary/PHASE_2_1_8_8_UPDATED_COMPLETION_REPORT.md).
7. [Actual separate preflight run](https://github.com/ImperioKDB/Updates/actions/runs/42838236003), clearly distinguished from the restricted experiment.

## 12. OpenCode continuation rule

Do not restart the production investigation, invent another scanner phase, redesign the experiment, or treat static reports as runtime evidence. Continue from the single unresolved default-branch registration gate. If that condition is not satisfied, stop and report the exact failure. If it is satisfied, run only the exact synthetic experiment once and report evidence.
