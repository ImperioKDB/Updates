# Scholars Scholarship Data Revalidation — Continuation Handoff

**Prepared:** 7 November 2026
**Purpose:** Resume the same Phase 1 revalidation in a new Manus session without repeating completed work or modifying production.

## Current state — read first

- The original user brief is a read-only editorial data-quality task for `ImperioKDB/Scholars`, reported to `ImperioKDB/Updates`; its required final report is `SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_2026-11-07.md`.
- The source-review workflow is **paused**, not complete: job ID **`ee30f0d0dab1`**. At the last check it had **14 completed record agents, 3 queued agents, 0 running agents**, and its reducer had not run. The workflow was created for 18 total calls (17 record reviews + one reducer); its reported effective call limit is 20. Do not create a second workflow for the same list.
- The completed public-source notes are preserved in [`SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/`](./SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/). They are evidence notes, not production changes or a final parent-validated report.
- Three records remain queued: **Light and Bells Health Foundation**, **Decagon Undergraduate Honors Program**, and **NDDC Local Post-Graduate Scholarship**. NDDC was time-sensitive on the 7 November snapshot (stored deadline 8 November 2026; previous audit saw HTTP 403), so refresh its status promptly if the continuation occurs after 7 November. Do not infer open/closed from the stored date or 403 alone.
- No production data, Scholars code, configuration, or deployment has been changed.

## How to resume

1. Read this handoff, the [interim status report](./SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_STATUS_2026-11-07.md), and the previous audit [`SCHOLARS_SCHOLARSHIP_DATA_COMPLETENESS_AUDIT_2026-11-06.md`](https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_SCHOLARSHIP_DATA_COMPLETENESS_AUDIT_2026-11-06.md).
2. Inspect the exact existing job with `job.info` for `ee30f0d0dab1`. If it remains paused and accessible, resume **that job** with `job.continue` and no higher `max_agent_calls`; the existing effective limit is 20. Wait for the three queued record reviews and the workflow’s planned reducer. Do not duplicate the 14 completed source reviews or start a new workflow.
3. If the paused job is no longer available to the new session, use the 14 preserved notes as completed evidence, research only the three missing records, and synthesize once. Do not claim the preserved notes are independently verified until their source links and supported facts pass final quality control.
4. Add the final three source notes to the evidence folder and update its README/manifest. Keep every note’s source title, publisher, URL, publication date when available, access date, supported facts, confidence, and unresolved points.
5. Reconcile the full set of 17 records against a **fresh** read-only Supabase snapshot and the 7 November snapshot recorded in the interim report. The original snapshot returned: 95 total rows; 44 verified; 44 usable verified slugs; 24 rows/1 verified row with missing `application_url`; 56/11 with missing `how_to_apply`; 65/15 with missing `last_verified_at`; 4 verified null deadlines; 17 verified past deadlines; derived lifecycle buckets 21 closed, 18 open, 5 not yet open. These are historical values as of 7 November, not a substitute for a later snapshot.
6. If resumed on a later date, re-run the read-only inventory and target-row queries, re-open time-sensitive official pages, and record the actual new access date. In particular, re-evaluate NDDC and all deadline/status values. Do not silently label later observations as if accessed on 7 November.
7. For every record, distinguish `ACTIONABLE`, `PARTIAL`, `MISSING`, `SOURCE_UNAVAILABLE`, or evidenced `NOT_APPLICABLE`; separate URL provenance/reachability from application availability; distinguish published facts, reasonable inference, and unknowns. Never infer a future cycle, deadline, opening date, requirements, or verification timestamp. Treat HTTP 200/403/404 as transport observations only.
8. Use sources in order: official provider page; official portal; official provider announcement/guidelines; official university/institution; other primary documentation; credible secondary sources only when primary sources are unavailable. Open/read sources, not snippets. Link every proposed instruction or date to evidence. Preserve conflicts (notably PAU’s cycle-specific closed notice versus the Foundation directory label, and Bode’s official postal-vs-email instructions) instead of choosing arbitrarily.
9. Deduplicate corrections at the **record** level. Count only supported proposed changes. Do not present “number requiring correction” until the 17 record results have been synthesized. Keep the inventory-wide lifecycle flags distinct from the 17-record source-revalidation set.
10. Produce the final report under `SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_2026-11-07.md` if the audit remains anchored to 7 November. Include all 11 sections specified in the user brief: executive summary; fresh inventory; record-by-record table; proposed application instructions; ASUU/Decagon/NDDC findings; deadline/lifecycle exceptions; verification-date recommendations; P0–P3 correction register; unresolved issues; recommended future implementation batches; audit-integrity declaration. If the audit date advances, use a filename/date that accurately reflects the new work and explain the 7 November baseline.
11. Run final QC: reconcile values to SQL; verify slug/title pairing; inspect all source citations; ensure every `SET_DATE` corresponds to a real source check; remove unsupported steps/deadlines; separate inaccessible from discontinued; confirm no private fields; confirm no production changes.
12. Commit and push **only** the report/evidence/handoff additions to `ImperioKDB/Updates`, using a conventional documentation commit, and verify the files exist on the remote. Do not modify `ImperioKDB/Scholars` or Supabase.

## The 17 target records

The set is the unique union of the 11 records previously missing application instructions, the 15 records previously missing verification dates, and the three destination exceptions (ASUU, Decagon, NDDC). All 17 target slugs existed and were verified in the 7 November targeted read-only query.

### Previously missing application instructions (11)

1. Florence Bamidele Makanjuola — `florence-bamidele-makanjuola-scholarship-aaaaaaaa`
2. JG Afrika Bursary 2027 — `jg-afrika-bursary-2027-64790f70`
3. KPMG Seyi Bickersteth Scholarship — `kpmg-seyi-bickersteth-scholarship-programme-cccccccc`
4. Lagos State Scholarship Board Bursary & Scholarship Awards — `lagos-state-scholarship-board-bursary-scholarship-awards-d9c8ed08`
5. Mastercard Foundation Scholars Program at PAU — `mastercard-foundation-scholars-program-at-pan-atlantic-university-aaaaaaaa`
6. Midwestern Oil & Gas Host Community Scholarship — `midwestern-oil-gas-host-community-scholarship-cccccccc`
7. MTN Foundation Science & Technology Scholarship — `mtn-foundation-science-technology-scholarship-aaaaaaaa`
8. NNPC-Renaissance/TotalEnergies/AENR JV University Scholarship — `nnpc-renaissance-totalenergies-aenr-jv-university-scholarship-aaaaaaaa`
9. NNPC/Seplat JV National Undergraduate Scholarship — `nnpc-seplat-jv-national-undergraduate-scholarship-aaaaaaaa`
10. Project 100 for 100 STEM Scholarship — `project-100-for-100-stem-scholarship-7eae077d`
11. PTDF In-Country Undergraduate Scholarship Scheme — `ptdf-in-country-undergraduate-scholarship-scheme-aaaaaaaa`

### Previously missing verification timestamps (15)

ASUU Scholarship Scheme for Indigent Students; Bode Amao Foundation Scholarship; Ejiro M Ukiri International Scholarship Fund; Florence Bamidele Makanjuola Scholarship; JG Afrika Bursary; KPMG Seyi Bickersteth Scholarship; Lagos State Scholarship Board; Light and Bells Health Foundation Scholarship; Mastercard Foundation Scholars Program at PAU; Midwestern Oil & Gas Host Community Scholarship; MTN Foundation Science & Technology Scholarship; NNPC-Renaissance/TotalEnergies/AENR JV Scholarship; NNPC/Seplat JV Scholarship; Project 100 for 100 STEM Scholarship; PTDF In-Country Undergraduate Scholarship Scheme.

### Destination exceptions

- **ASUU:** no stored URL; distinguish no verified national route from branch/institution-specific calls; never invent a central portal.
- **Decagon:** stored `https://www.decagonfoundation.org/apply`; previous audit observed 404. Establish whether the route moved, is temporarily unavailable, or status is unknown; a 404 alone does not establish program discontinuation.
- **NDDC:** stored `https://scholarship.nddc.gov.ng/login`; previous audit observed 403. Investigate official evidence and access restrictions without bypassing controls; 403 alone does not prove the portal is broken.

## Seven November database date flags

The current Scholars code (`lib/dates.ts`, `lib/discovery.ts`) has a derived date status, not an independent status column. As of 7 November, four records had a future deadline plus an old `last_cycle_closed_at` (PAU Mastercard, Midwestern, MTN, NNPC-Renaissance), which the code still treats as closed. Fifteen verified records had a past deadline but no close marker; the deadline still makes them closed. Eleven of those 15 are outside the 17 named source-revalidation records: AMIR Fund Medical; CBIAS Graduate; CBIAS Undergraduate; FAJIM Medicare; Liberty Career Academy; Osun Indigenes; Oyo State; Ruth Titilayo Polytechnic; Taiwo Bankole Prize; WVA/MSD Veterinary Student; Yinka & Pelumi Foundation. If the final report includes these inventory-wide exceptions, label them as date-only observations until separately source-checked; do not imply a source revalidation occurred.

## Existing source notes and their current interim takeaway

The 14 completed notes are linked from the [evidence-folder README](./SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/README.md). Early findings include: JG Afrika had an official 2027 call reported open with no deadline found; several other programs had only closed 2026 cycles and unsupported stored 2027 dates; PAU has a source-status conflict; Bode’s official submission channels conflict; ASUU evidence is branch-specific; Ejiro’s 2026 cycle closed and its exact Jotform linkage was not confirmed. Treat these as research results to synthesize and cite, not production edits.

## Safety boundary

This remains a read-only audit. Do not `INSERT`, `UPDATE`, `DELETE`, run migrations, change policies/storage/configuration, alter scholarship status or dates, modify application code, deploy, merge, or expose student/profile/matching data or private `research_notes`. Record proposed corrections in the final report only. Any later implementation requires a separate authorized phase.

## Reference documents

- [Interim status report](./SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_STATUS_2026-11-07.md)
- [Prior completeness audit](https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_SCHOLARSHIP_DATA_COMPLETENESS_AUDIT_2026-11-06.md)
- [Latest PR #28 production acceptance report](https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_PR28_PRODUCTION_ACCEPTANCE_VERIFICATION_2026-11-07.md)
- [Scholars lifecycle date helper at reviewed commit](https://github.com/ImperioKDB/Scholars/blob/cf3682ce35912df7b9b9352193630fc404427c7c/lib/dates.ts)
