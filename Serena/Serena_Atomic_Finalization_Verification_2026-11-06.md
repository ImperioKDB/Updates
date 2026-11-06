# Atomic Finalization Verification — Serena Recovery Analysis

**Finding: NOT ATOMIC — VERIFIED from recovered implementation source.** The prior Milestone 2 claim that terminal finalization was transactional is contradicted by the exact source recovered from the checksum-verified patch.

## Source evidence

In `src/research/research-analysis-service.ts`:

- Success: `updateAnalysisAttempt(...completed...)`, then `updateResearchResult(...)`, then separate `appendEvent(...)` calls for `analysis_provider_succeeded` and `analysis_attempt_completed`.
- Failure: `updateAnalysisAttempt(...failed...)`, then `updateResearchResult(...)`, then separate `appendEvent(...)` calls for `analysis_provider_failed` and `analysis_attempt_completed`.

In `src/persistence/postgres-task-repository.ts`, these are separate `this.sql` tagged queries in separate methods. There is no `this.sql.begin(...)` wrapping them. The postgres.js pool option `max: 1` limits connections; it does not create a transaction. Event insertion also allocates sequence numbers using `max(sequence_number)+1`, which needs task-level serialization if writes can race.

## Failure windows

A process exit or SQL failure after the attempt update but before task-result update leaves a terminal attempt with stale result JSON. Failure during either event write leaves the attempt/result updated but only part of the terminal event stream persisted. The failure branch itself can encounter the same partial-write conditions while trying to record a provider error. The tests that ran here use the supplied application/repository test implementations; no integration test against PostgreSQL established atomic behavior.

## Required correction — not implemented here

Keep the model call outside a database transaction. Add a single repository contract, for example `finalizeAnalysisAttempt`, implemented in `src/persistence/postgres-task-repository.ts` with `this.sql.begin(async tx => ...)`. In that transaction:

1. Lock the owning task row `FOR UPDATE` to serialize terminal event sequence allocation.
2. Update exactly the expected active attempt to the desired terminal state and verify one row changed.
3. Update the task result JSON, preserving the existing guard that prevents an older attempt overwriting a newer attempt; verify the expected row changed.
4. Insert all required terminal events using the same `tx` and safe sequence allocation.
5. Throw on any unexpected row count or SQL failure so the entire terminal operation rolls back.

Change `src/persistence/task-repository.ts` and `src/research/research-analysis-service.ts` to call this method for both success and failure. Implement equivalent behavior in `src/persistence/in-memory-task-repository.ts`. If finalization itself fails, log only safe identifiers/error class and let stale-attempt reclamation handle recovery; do not return a falsely finalized result.

Add regression tests for successful commit, forced failure at each persistence step (all terminal effects must roll back), duplicate/concurrent sequence allocation, and the older-attempt overwrite guard. Re-run all checks and recompute checksums after the approved correction.

## Verification log

The preserved patch was applied to a clean checkout at baseline `6bb268b216b6250e4ae64b73b9f6c2a85f31e686`. The exact changed source files match the supplied SHA-256 manifest. Static inspection of the recovered source confirms separate SQL calls and no surrounding transaction. This audit did not modify source, create a commit, push, or touch production.


## Corrective implementation update — local branch only

After the verified discrepancy was reported, the local branch `serena/recovery-corrective-2026-11-06` now has the corrective implementation: a single `finalizeAnalysisAttempt(...)` repository method, a PostgreSQL `this.sql.begin(...)` transaction for attempt/result/terminal events, task-row locks for event-sequence allocation, and service control flow that no longer converts a commit error into a model failure. The in-memory repository mirrors the API. Added regression coverage proves a persistence error is propagated without a second failure-finalization attempt and that an unserializable event payload is rejected before in-memory terminal state mutates. The local full backend suite passes 131/131 tests.

This source-level correction is **not production-verified**. A dedicated failure-injection integration test against a real PostgreSQL transaction is still required before a production migration or deployment. No migration was applied and no remote branch/commit was created.
