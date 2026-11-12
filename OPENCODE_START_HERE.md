# OpenCode Start Here — Scholars Phase 2.1.8

You are continuing the Scholars synthetic-only schema extraction task. Read [`OPENCODE_HANDOFF.md`](./OPENCODE_HANDOFF.md) completely before doing anything. Do not rely on memory or on earlier completion claims; independently verify the current GitHub repository state and actual Actions evidence.

## Objective

Complete exactly one execution of the already-reviewed synthetic-only restricted schema extraction experiment, then provide a factual evidence report and GO/NO-GO recommendation. Do not restart the investigation or invent a new phase.

## Authoritative source versions

- Source repository: `ImperioKDB/scholars-schema-extraction`
- Main reference: `40e36dbf9e0d2921433694d5a63c0a10ecdef295`
- Experiment branch: `experiment/phase-2-1-8-isolated-proof`
- Reviewed experiment tip: `44ed6c1dceeb09aad0ec0c82c792a362cdfa381a`
- Reviewed runner blob: `4746b410754d5b839c520bf7d40585f2b8eaaa87`
- Reviewed workflow blob: `cec5deaf2d887834850f42f18495ab9d330ee0a7`
- Reviewed schema blob: `338261db6d6b2388f23a6a3a738bb6e0f5900433`

## Mandatory safety rules

Do not connect to production Supabase or staging Supabase. Do not populate or use `SUPABASE_DB_URL`. Do not extract production schema/data, import to staging, modify database objects, merge unrelated pull requests, modify the Scholars application repository, change secrets/permissions/settings, run unrelated workflows, or publish credentials/raw dumps/sensitive artifacts. The only authorized operation is the synthetic-only experiment described in the handoff.

## Pre-dispatch gate

Before dispatching, verify all of the following from GitHub:

1. `.github/workflows/isolated-schema-proof.yml` exists on `main` and is registered by the Actions API.
2. It is manual `workflow_dispatch` only.
3. Its input and job guard accept exactly `experiment/phase-2-1-8-isolated-proof`.
4. Its contents match the reviewed workflow and use only the disposable PostgreSQL service.
5. It contains no production/staging references or Supabase credentials.
6. The experiment branch still points to `44ed6c1dceeb09aad0ec0c82c792a362cdfa381a` and the three reviewed blob hashes match.
7. There is no active or prior successful exact experiment run.

If any condition fails, stop. Do not improvise a workaround, copy a different workflow, run the production workflow, or modify `main` without an explicit owner decision.

## Execution, only after every gate passes

Dispatch the isolated workflow from `main` exactly once with:

```text
experiment_ref=experiment/phase-2-1-8-isolated-proof
```

Monitor that one run until completion. Retrieve the sanitized summary artifact and inspect the job logs. Never expose passwords, raw dumps, connection strings, or sensitive output.

## Required evidence report

Report the run URL and ID, workflow source commit, final status, job results, artifact name/location, and sanitized contents. Distinguish `PASS`, `FAIL`, `NOT TESTED`, and `INCONCLUSIVE`. Do not call the run successful merely because the GitHub job is green.

The evidence must separately cover bootstrap/restricted authentication; role attributes/memberships/effective privileges; default privileges; separate RLS; owner maintenance; `pg_dump --schema-only`; Supabase declarative generation and strict coverage; object inventories; stdout/stderr diagnostics; data exclusion; every forbidden-operation SQLSTATE; cleanup; skipped/failed checks; and artifact retention.

A successful result would establish only that this synthetic disposable fixture and the reviewed extraction commands behave as observed. It would not authorize production or staging extraction. If the experiment passes, recommend closing the extraction investigation and moving toward the Resource Center implementation, subject to the separate private-environment and least-privilege requirements documented in the handoff.
