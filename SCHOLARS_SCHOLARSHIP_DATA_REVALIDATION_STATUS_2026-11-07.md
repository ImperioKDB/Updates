# Scholars Scholarship Data Revalidation — Interim Status Report

**Audit snapshot:** 7 November 2026
**Status:** **INCOMPLETE — continuation required. This is not the final Phase 1 revalidation report.**
**Reporting repository:** `ImperioKDB/Updates`
**Target application:** `ImperioKDB/Scholars`
**Production domain:** <https://www.scholars.com.ng>

> This checkpoint was prepared after the user asked to pause the source-review workflow to conserve remaining credits. It records work completed and work still required. It does not certify the affected records as correct, does not constitute an approved data change, and must not be used in place of the final 11-section report requested in the original Phase 1 brief.

## 1. Objective and expected work

The authorized task is a **read-only editorial revalidation** of scholarship records previously flagged for missing application instructions, missing verification timestamps, or questionable application destinations. The final deliverable is to be `SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_2026-11-07.md` in this repository. It must contain the 11 requested sections: executive summary; fresh inventory; record-by-record revalidation; proposed instructions; detailed ASUU, Decagon, and NDDC findings; deadline/lifecycle exceptions; verification-date recommendations; prioritized correction register; unresolved issues; a future implementation plan; and an audit-integrity declaration.

The correct workflow is to compare the fresh production snapshot with the prior completeness audit, recheck each affected record against official sources, distinguish known facts from inference and uncertainty, propose only source-backed values, synthesize record-level counts without double-counting fields, quality-check the report, and publish it to `Updates`. Production data, the Scholars codebase, and deployments must remain untouched.

## 2. Fresh production inventory — read-only snapshot

A new `SELECT`-only query against the existing production Supabase project (`cmdglabohpttgfofcmqc`) returned these values for 7 November 2026. The query used only public scholarship fields; it did not read student profiles or private matching data.

| Metric | All scholarship rows | Verified rows | Definition / qualification |
|---|---:|---:|---|
| Total records | 95 | — | All rows in `public.scholarships` |
| Verified records | — | 44 | `verified = true` |
| Verified usable slugs | — | 44 | All passed a lowercase alphanumeric/hyphen slug pattern |
| Missing/blank `application_url` | 24 | 1 | Blank means null or whitespace-only |
| Missing/blank `how_to_apply` | 56 | 11 | Blank means null or whitespace-only |
| Missing `last_verified_at` | 65 | 15 | Null timestamp |
| Missing deadline | — | 4 | Verified records only |
| Past deadline | — | 17 | Verified records only, relative to 2026-11-07 |
| Missing or past deadline | — | 21 | Verified records only |
| Malformed/unsupported URL string shape | — | 0 | Basic format heuristic only; **not** proof a destination is current or official |
| `opens_at` later than `deadline` | — | 0 | Simple date-order anomaly check |

The current Scholars source at commit [`cf3682ce35912df7b9b9352193630fc404427c7c`](https://github.com/ImperioKDB/Scholars/tree/cf3682ce35912df7b9b9352193630fc404427c7c) derives listing status from dates; it has no independent stored lifecycle-status field. `lib/dates.ts` marks a record closed when `deadline < today` **or** `last_cycle_closed_at <= today`; `lib/discovery.ts` marks it not-yet-open only when it is not closed and a future `opens_at` exists. Applying that logic to the fresh snapshot gives:

| Derived bucket | Count |
|---|---:|
| Closed | 21 |
| Open by stored-date logic | 18 |
| Not yet open | 5 |

Two date/lifecycle patterns require attention:

1. **Four verified records have a future deadline but an old-cycle close marker on or before 7 November 2026.** The current application predicate therefore marks each closed despite the future deadline: Mastercard Foundation Scholars Program at PAU; Midwestern Oil & Gas Host Community Scholarship; MTN Foundation Science & Technology Scholarship; and NNPC-Renaissance/TotalEnergies/AENR JV University Scholarship. Official-source notes exist for all four, but the cross-record correction decision has not yet been made.
2. **Fifteen verified records have a past deadline and no `last_cycle_closed_at`.** The deadline itself still makes them closed under the current code, so the missing marker does not by itself prove that the public closed state is wrong. Their date provenance and editorial lifecycle treatment need follow-up. Four intersect the present 17-record source-review set (ASUU, Decagon, Light and Bells, and Project 100); the other eleven are a separate inventory-wide flag set: AMIR Fund Medical; CBIAS Graduate; CBIAS Undergraduate; FAJIM Medicare; Liberty Career Academy; Osun Indigenes; Oyo State; Ruth Titilayo Polytechnic; Taiwo Bankole Prize; WVA/MSD Veterinary Student; and Yinka & Pelumi Foundation.

The fresh counts reconcile to the previous completeness audit’s headline figures: **95 total rows, 44 verified, 11 verified records missing `how_to_apply`, 15 verified records missing `last_verified_at`, four verified records without a deadline, and 17 with past deadlines.** The prior report file is named [`SCHOLARS_SCHOLARSHIP_DATA_COMPLETENESS_AUDIT_2026-11-06.md`](https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_SCHOLARSHIP_DATA_COMPLETENESS_AUDIT_2026-11-06.md); its header records an audit date of 7 November 2026. No count difference was found in these fields.

A targeted read-only query also confirmed that **all 17 requested target slugs currently resolve to verified records** and captured each record’s URL, instruction text, deadline, opening date, cycle-close date, and verification timestamp. Presence or a syntactically acceptable URL is not a claim that the destination is active, current, or provider-authorized.

## 3. Source revalidation progress

The paused research workflow is `ee30f0d0dab1`. Its original plan was 17 independent record reviews plus one reducer (18 planned agent calls; the workflow reported an effective limit of 20). At the latest status check, **14 record reviews were complete, three were queued, and none was running. The reducer had not started.** The workflow remains paused at the user’s request.

The 14 completed source-evidence notes are preserved in [`SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/`](./SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/). Their findings are interim agent research, not yet the final cross-record analysis:

| Record | Interim evidence result (not a production correction) | Note |
|---|---|---|
| Florence Bamidele Makanjuola | Provider-linked 2026/27 form was closed; reviewed official pages did not substantiate the stored May 2027 opening/deadline or a next cycle. | [florence.md](./SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/florence.md) |
| JG Afrika Bursary 2027 | Provider page and provider announcement support a current 2027 application round as open on the audit date; no closing deadline was found. | [jg-afrika.md](./SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/jg-afrika.md) |
| KPMG Seyi Bickersteth | Stored application route identifies an expired 2025 listing; latest official 2026 listing was also expired. No 2027 cycle was found; stored 2027 dates are unsupported by reviewed sources. | [kpmg.md](./SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/kpmg.md) |
| Lagos State Scholarship Board | Official Board material says the 2025/26 cycle concluded; the inspected portal terms lack actionable steps. No official source supported the stored 2027 dates. | [lagos-state.md](./SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/lagos-state.md) |
| Mastercard Foundation at PAU | PAU’s cycle-specific page says 2026/27 applications are closed; a Foundation directory shows an undated “Admissions Open” label. Conflict requires manual resolution; 2027-05-22 is unsupported in reviewed pages. | [pau-mastercard.md](./SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/pau-mastercard.md) |
| Midwestern Oil & Gas Host Community | Provider-linked 2026/27 route states the cycle ended 19 April 2026; the stored root URL is a generic platform home, and the stored 2027 deadline is unsupported. | [midwestern.md](./SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/midwestern.md) |
| MTN Foundation Science & Technology | Official page describes the program and a 2026 edition; linked official portal says submissions are closed. The reviewed sources do not support the stored 2027 deadline. | [mtn.md](./SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/mtn.md) |
| NNPC-Renaissance/TotalEnergies/AENR JV | Official provider and scheme pages establish a closed 2026 cycle; the stored platform root is generic, and no 2027 date or live route was confirmed. | [nnpc-renaissance.md](./SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/nnpc-renaissance.md) |
| NNPC/Seplat JV | Official provider materials establish a closed 23 February–13 March 2026 cycle; stored 2027 dates are unsupported by the reviewed evidence. | [nnpc-seplat.md](./SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/nnpc-seplat.md) |
| Project 100 for 100 STEM | Provider-linked 2026 campaign dates had elapsed and its form said closed; a stale campaign banner still said applications were open. No next cycle was confirmed. | [project-100.md](./SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/project-100.md) |
| PTDF In-Country Undergraduate | Official 2026/27 window (27 April–5 June 2026) had passed; the official portal was identified, but stored 2027 dates were not substantiated. | [ptdf.md](./SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/ptdf.md) |
| ASUU Scholarship | Official evidence supports national/branch scholarship activity and a closed, FUK-specific 2026 call, but not a universal current process, deadline, or central application route. FUK conditions must not be generalized. | [asuu.md](./SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/asuu.md) |
| Bode Amao Foundation | Official pages conflict between postal and email submission; the full current document list and stored 31 December 2026 deadline were not substantiated. | [bode-amao.md](./SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/bode-amao.md) |
| Ejiro M Ukiri International Scholarship Fund | Official evidence supports a 1–30 September 2026 cycle that closed. The stored Jotform says closed; the provider-published `/apply` page was blank in the inspected view, and linkage of the exact Jotform ID was not established. | [ejiro.md](./SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/ejiro.md) |

**Three queued reviews remain:** Light and Bells Health Foundation; Decagon Undergraduate Honors Program; and NDDC Local Post-Graduate Scholarship. As of the 7 November database snapshot, NDDC’s stored deadline was 8 November 2026 and its prior audit observation was HTTP 403. This makes it time-sensitive, but neither the previous 403 nor the stored date alone proves the application is open or the portal is broken. Decagon’s prior 404 and its 15 October stored deadline likewise do not prove that the program ended. These cases require the official-source checks described in the original brief.

The targeted set is the union of 11 records with missing instructions, 15 with missing verification dates, and the ASUU/Decagon/NDDC destination exceptions: **17 unique records**. A final unique count of records requiring correction has **not** been calculated. Do not add field-level issue counts together as a record count. The 14 notes include proposed editorial dispositions, but those are not approved edits and need cross-record source/citation quality control.

## 4. What remains before the final report

1. Resume the existing paused workflow rather than creating a duplicate one. Complete the three queued record reviews and allow the planned reducer to run.
2. Preserve the new Light and Bells, Decagon, and NDDC notes in the evidence folder, and inspect the structured results plus each note for conflicts, unsupported claims, and source-quality issues.
3. Reconcile each of the 17 current records against the snapshot and the previous audit. For any delay after 7 November, rerun the read-only snapshot and recheck time-sensitive pages; do not treat 7 November status as current.
4. Finalize a record-by-record table with instruction classification, URL assessment, current-cycle/deadline state, verification-date recommendation, exact proposed change (if supported), linked source evidence, and confidence.
5. Deduplicate proposed changes by record and calculate the exact number of unique records requiring correction. Keep “unknown” and “no provider-published step/date” distinct from a proposed value.
6. Explicitly resolve or retain the unresolved cases: ASUU’s lack of a central route; Decagon’s destination versus program status; NDDC’s 403/accessibility and deadline; the PAU conflicting status labels; Bode’s conflicting submission channels; and any unsupported future dates.
7. Produce the final file under the required name `SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_2026-11-07.md`, with the original 11 sections, then commit and push it to `ImperioKDB/Updates` and verify the remote file.

## 5. Audit integrity

No production database record was inserted, updated, or deleted. No migration, schema, policy, storage, or permission change was made. No Scholars application code or configuration was modified, and no deployment or merge was performed. No student profile, match score, authentication record, secret, or private `research_notes` field was queried or included. All proposed values remain editorial recommendations only.

## References

- Prior completeness audit: [SCHOLARS_SCHOLARSHIP_DATA_COMPLETENESS_AUDIT_2026-11-06.md](https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_SCHOLARSHIP_DATA_COMPLETENESS_AUDIT_2026-11-06.md)
- Latest feature acceptance report: [SCHOLARS_PR28_PRODUCTION_ACCEPTANCE_VERIFICATION_2026-11-07.md](https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_PR28_PRODUCTION_ACCEPTANCE_VERIFICATION_2026-11-07.md)
- Current lifecycle code: [`lib/dates.ts`](https://github.com/ImperioKDB/Scholars/blob/cf3682ce35912df7b9b9352193630fc404427c7c/lib/dates.ts) and [`lib/discovery.ts`](https://github.com/ImperioKDB/Scholars/blob/cf3682ce35912df7b9b9352193630fc404427c7c/lib/discovery.ts)
