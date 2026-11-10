# New Manus Session Continuation Prompt — Scholars Phase 1.3.1

You are continuing the Scholars scholarship-data quality and catalogue-governance project.

## Read first

Read these files completely from the handoff export or the `Updates` repository:

1. `SCHOLARS_PHASE_1_3_1_HANDOFF_REPORT_2026-11-08.md`
2. `SCHOLARS_PHASE_1_3_1_AUDIT_CLARIFICATION_ADDENDUM_2026-11-08.md`
3. `SCHOLARS_PHASE_1_3_AUDIENCE_ELIGIBILITY_AND_CATALOGUE_SCOPE_AUDIT_2026-11-07.md`
4. All 17 files in `SCHOLARS_PHASE_1_3_AUDIENCE_ELIGIBILITY_EVIDENCE_2026-11-07/`
5. `SCHOLARS_PHASE_1_2_1_JG_AFRIKA_ELIGIBILITY_ADDENDUM_2026-11-07.md`
6. `SCHOLARS_PHASE_1_2_PRODUCTION_CORRECTION_SPECIFICATION_2026-11-07.md`
7. The included Phase 1.1 production snapshot, readiness audit, refresh audit, and revalidation handoff files.

Current `Updates` commit: `2f90abfac0c06cfe512ab91d96fb86a3c5ca427e`.

## Where work stopped

Phase 1.3.1 is complete. The work produced a documentation-only clarification model with seven independent dimensions:

- provider_authenticity
- audience_eligibility
- academic_level_fit
- application_status
- application_route_status
- evidence_freshness
- publication_disposition

The old A–E classifications remain as historical publication outcomes. They do not mean that a record is open, actionable, route-verified, or current.

All 17 records were reconciled. No record currently qualifies as an unrestricted actionable/open listing.

## Next task boundary

Do not modify Scholars production, application code, Supabase, RLS, storage, configuration, or deployments unless the user explicitly authorizes a later implementation phase. Do not contact providers or submit applications.

The recommended next step is Phase 2 editorial/data-model planning based on the Phase 1.3.1 addendum. Define the conceptual model for cycles, source evidence, audience/academic constraints, application status, route status, freshness, publication gates, manual review, historical archive, paid-programme taxonomy, and separate timestamps before proposing implementation.

If a future task requests a production write, require explicit approval of the exact record, field, value, public behavior, and validation plan. Repeat the relevant official-source check immediately before any write. Never shift historical dates into future years and never treat route reachability or `verified = true` as proof of current acceptance.

## Reporting requirement

For any continuation, report the exact files changed, commit SHA, deployment status if applicable, unresolved questions, and confirmation that production remained unchanged. Documentation-only changes belong in `ImperioKDB/Updates`.
