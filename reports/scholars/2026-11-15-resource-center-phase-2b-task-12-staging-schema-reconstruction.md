# Scholars Resource Centre — Task 12 Staging Schema Reconstruction Report

**Assessment date:** 2026-11-15
**Source commit:** `ImperioKDB/Scholars` `142146a67cb21eeec8d74832bc326c1fcd5dd5f4`
**Target project:** `scholars-staging` / `aqhktriwaglvvrchxmtd`
**Status:** reconstruction not started; safe gate stopped the operation.

## Final result

**BLOCKED — STAGING BASELINE NOT RECONSTRUCTED.** The project identity and isolation audit passed, but the migration-history audit did not identify a reproducible, authoritative, privacy-safe ordered baseline that can be applied without unsupported assumptions. No migration was applied, no schema object was created, and no staging data was inserted.

## Actions performed

1. Refreshed `ImperioKDB/Scholars` and `ImperioKDB/Updates` from their `main` branches and recorded exact commits.
2. Retrieved and reviewed the complete Task 11 publication at `81ecdf6edc87a9cb491d77e3ff83541019f8a370`.
3. Retrieved the prior Task 9/10 reports, the A0.3 migration/schema assessment, and the prior staging-establishment report.
4. Verified the current `scholars-staging` project identity and compared it with production and `serena`.
5. Inventoried staging contents read-only before any possible change.
6. Inspected all 136 source migration files and created a per-file manifest with classifications, dependencies, safety notes, and application status.
7. Inspected the application `vercel.json` and read-only Vercel project/environment metadata without changing configuration.

## Why reconstruction did not proceed

The source repository contains 136 SQL files but no proven schema-only install artifact. `0001_init.sql` is explicitly marked superseded and says it differs from the live schema. The directory contains duplicate numeric prefixes, including `0002`, `0004`, `0021`, `0023`, `0035`, `0078`, `0087`, `0102`, and `0103`, so filename prefix order is not enough to establish historical order. Thirty-three files are real-looking business-data seeds that are unnecessary for a privacy-safe schema baseline. Other migrations are data-dependent or assume prior roles, tables, triggers, functions, Auth, Storage, or exact function signatures.

The final Resource Centre migration depends on `public.is_admin(uuid)` but does not define it. The security-boundary migration changes ACLs for five exact functions but does not create or prove their bodies, owners, search paths, or downstream prerequisites. Supplying those missing objects manually would create a deliberate reconstructed variant, not a source-derived baseline, and would need separate owner approval.

A partial replay of “non-seed” files would not prove schema parity: omission of a filename containing `seed` is not equivalent to omission of all DML, data-dependent DDL, reference data, or prerequisite functions. Replaying the entire directory would violate the no-production-data/no-unreviewed-business-fixture boundary and could fail or produce a misleading baseline. The correct safe result is to stop and document the exact blocker.

## Migration application results

| Operation | Result |
|---|---|
| Supabase migration application | Not attempted |
| `apply_migration` | Not called |
| Production SQL | None |
| Staging DDL/DML | None |
| Auth users created | None |
| Storage buckets/objects created | None |
| Task 11 administrator remediation | Not applied |
| Scholars source migration files | Unmodified |
| Vercel configuration/deployment | Unchanged/not triggered |

## Required reconstruction decision

Before a future staging-only implementation, the owner must approve one of two paths:

- **Authoritative baseline path:** provide a reviewed schema-only snapshot or migration bundle for the selected Scholars revision; or
- **Bounded reconstruction path:** approve a source-derived bundle that explicitly supplies prerequisites, omits/filters every business seed, defines role/ownership/default-privilege assumptions, records every deviation, and includes final-state parity checks.

Neither path was available in this task. This report therefore records a controlled no-change outcome rather than a fabricated “successful” staging reconstruction.
