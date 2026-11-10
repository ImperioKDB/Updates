# Scholars Scholarship Data Revalidation — Final Phase 1 Report

**Audit date:** 7 November 2026
**Reporting repository:** `ImperioKDB/Updates`
**Target application:** `ImperioKDB/Scholars`
**Production domain:** https://www.scholars.com.ng
**Report status:** Final source-revalidation report for the 17-record target set. Editorial recommendations only; no production changes were applied.

## 1. Executive summary

This report completes the Phase 1 read-only revalidation of 17 verified scholarship records previously flagged for missing application instructions, missing verification timestamps, questionable application destinations, or lifecycle anomalies. The review used official provider pages, official portals, official announcements, and provider-linked application systems. It separates a destination’s provenance and reachability from whether applications are currently open.

The strongest correction is Decagon: the stored `decagonfoundation.org/apply` route returned 404, while the provider’s current official site says applications are open at `decagon.institute/apply` and links to a provider-controlled secure form. NDDC’s official 2026/2027 call confirms the stored portal route and an 8 November 2026 deadline, but the portal could not be substantively read in this review. JG Afrika is supported as open on the audit date with no published closing deadline. Light and Bells is confirmed as a closed 2026 cycle with a matching 2 October deadline.

For most remaining records, official sources confirm the programme but show that the latest evidenced cycle has ended. Stored future dates, especially dates shifted into 2027, are not accepted as published facts without a new official announcement. The recommended implementation is therefore conservative: correct the Decagon destination, add source-backed instructions where current and safe, qualify historical instructions, remove unsupported future dates, and use `SOURCE_UNAVAILABLE` or manual-review states where evidence cannot establish portal status.

## 2. Fresh inventory and scope

The production snapshot recorded in the continuation handoff was read-only and limited to public scholarship fields. It reported 95 total rows and 44 verified rows. Among verified rows, 11 lacked `how_to_apply`, 15 lacked `last_verified_at`, four lacked a deadline, and 17 had past deadlines as of 7 November 2026. Derived date logic classified 21 as closed, 18 as open by stored-date logic, and five as not yet open.

A fresh read-only query of the three queued rows confirmed that all three remain verified records:

- Decagon stored `https://www.decagonfoundation.org/apply`, deadline 2026-10-15, and a prior verification timestamp of 6 October.
- Light and Bells stored `https://lightandbellshealth.com/scholarships-and-grants`, deadline 2026-10-02, and no verification timestamp.
- NDDC stored `https://scholarship.nddc.gov.ng/login`, deadline 2026-11-08, and a prior verification timestamp of 13 October.

The complete target set is the unique union of 11 records missing application instructions, 15 records missing verification timestamps, and the ASUU, Decagon, and NDDC destination exceptions. It contains 17 unique records. All 17 were reviewed at evidence-note level. Every target has at least one editorial action, qualification, or manual decision; this does not mean every proposed action is a direct database value replacement.

## 3. Record-by-record revalidation

| Record | Instruction result | Destination result | Cycle/deadline result | Verification recommendation |
|---|---|---|---|---|
| ASUU | Partial; branch evidence must not be generalized | No central route verified; do not invent one | FUK 2026 call closed; stored national date unsupported | Set review date with branch-specific qualification |
| Bode Amao | Partial; official postal and email channels conflict | Official homepage retained | 2026-12-31 unsupported | Set review date, preserve conflict |
| Decagon | Actionable current route | Replace stale 404 with `decagon.institute/apply` | Current page says applications open; no deadline published | Set 2026-11-07 |
| Ejiro M. Ukiri | Partial and cycle-qualified | Provider `/apply` preferred; stored Jotform closed and exact linkage unresolved | 2026 cycle closed 2026-09-30; no 2027 date | Set 2026-11-07 |
| Florence Bamidele Makanjuola | Partial; current linked form closed | Provider `/apply` retained | 2026 cycle ended; stored 2027 dates unsupported | Set 2026-11-07 |
| JG Afrika | Actionable | Stored provider page retained | 2027 round supported as open; no closing date | Set 2026-11-07 |
| KPMG Seyi Bickersteth | Missing for a future cycle | Stored route is provider-linked but stale 2025 listing; latest 2026 listing closed | Stored 2027 dates unsupported | Set 2026-11-07 |
| Lagos State Scholarship Board | Missing | Provider homepage retained; portal login is not proof of an open cycle | 2025/2026 cycle concluded; stored 2027 dates unsupported | Set 2026-11-07 |
| Light and Bells | Partial; 2026 status and categories supported | Official provider page retained | 2026 window ended 2026-10-02; no separate closure event | Set 2026-11-07 |
| Mastercard Foundation at PAU | Partial; current-cycle process incomplete | Official PAU page retained | PAU says closed; Foundation directory says undated “Admissions Open” | Manual reconciliation required before unqualified timestamp |
| Midwestern Oil & Gas | Partial; detailed cycle ended | Platform root legitimate but generic; direct 2026 route closed | Published 2026/2027 deadline was 2026-04-19; stored 2027 date unsupported | Set 2026-11-07 |
| MTN Foundation STS | Partial; eligibility supported, current process incomplete | Official MTN page retained; linked portal says closed | 2027 date unsupported; 2026 closure date unverified | Set 2026-11-07 |
| NNPC–Renaissance | Missing for future cycle | Generic Scholastica root legitimate but not programme-specific; no live route | 2026 cycle closed 2026-05-31; stored 2027 date unsupported | Set 2026-11-07 |
| NNPC/Seplat | Partial; historical 2026 instructions supported | Stored provider-linked destination retained | 2026 cycle closed 2026-03-13; no 2027 date | Set 2026-11-07 |
| NDDC Local Post-Graduate | Source unavailable/partial; official call details accessible, portal detail unavailable | Stored portal is confirmed by official call; accessibility unresolved | Official deadline 2026-11-08; no closure event | Record 2026-11-07 with source-unavailable qualification |
| Project 100 for 100 | Partial; closed 2026 instructions only | Stored provider-linked Google Form retained but closed | 2026 deadline 2026-09-25; no future cycle | Set 2026-11-07 |
| PTDF In-Country Undergraduate | Partial; historical 2026/27 instructions supported | Official PTDF portal retained | 2026/27 window ended 2026-06-05; stored 2027 dates unsupported | Set 2026-11-07 |

The individual evidence notes are stored in `SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/`.

## 4. Proposed application instructions

The implementation should not copy historical requirements into a future cycle without labelling them. The records with safe current instructions are JG Afrika and Decagon. JG Afrika’s provider form supports Civil Engineering BSc/BEng or MSc/MEng applicants and requests the applicant sections, motivation, ID, Matric certificate, complete transcript, funding disclosure, consent, and CAPTCHA. No deadline is published; 1 January 2027 is an unsuccessful-notification date, not an application deadline.

Decagon’s current provider route supports Nigerian citizens with JAMB/UTME of at least 250 who have not yet started university. Applicants should prepare their JAMB score, preferred university, course choice, and parent/guardian contacts. The official page names Christopher University and Wellspring University and links to the secure provider form. The current page says applications are open, but it does not publish a closing date.

For Light and Bells, the safe current text is cycle-qualified: the 2026 window ran from 6 July through 2 October, covered the G&G medicine, JSI nursing, and Vision allied-health categories at government institutions, and stated a $100 award and 18 December notification target. The stored detailed document checklist was not re-established from the current page and should not be carried forward as current requirements.

For NDDC, the official call supports only that qualified Niger Delta indigenes could apply for the 2026/2027 local master’s programme free of charge through the official portal by 8 November 2026. Full requirements should remain unavailable until the portal or an official guideline can be read. Similar historical qualification applies to the closed-cycle notes for ASUU, Bode Amao, Ejiro, Florence, KPMG, Lagos State, Midwestern, MTN, NNPC–Renaissance, NNPC/Seplat, PAU, Project 100, and PTDF.

## 5. Detailed ASUU, Decagon, and NDDC findings

### ASUU

ASUU scholarship activity is confirmed through ASUU National and official university sources. The current FUK branch call was explicitly local to FUK students, required a minimum CGPA of 3.0 and specified five documents, with a 24 September 2026 deadline. Those conditions cannot be generalized to every ASUU branch or treated as a national application process. No central current portal, universal requirements, or nationwide deadline was verified. The record should not receive an invented URL.

### Decagon

The prior 404 is materially corrected by the current official Decagon domain. The stable public destination should be `https://decagon.institute/apply`; its button links to the provider-controlled secure form. The programme page says applications are open and publishes the JAMB threshold, citizenship requirement, not-yet-started-university requirement, preparation checklist, partner universities, and review sequence. The stored 15 October deadline is unsupported and should be removed or marked historical/unverified.

### NDDC

The official NDDC Facebook announcement confirms the current call, official stored portal route, free application, and 8 November 2026 deadline. The portal could not be substantively read, and the earlier 403 should be recorded as an access observation rather than interpreted as closure or discontinuation. The record should retain the official route while clearly warning that complete live requirements were not independently verified. No intermediary or payment instruction should be added beyond the official free-application warning.

## 6. Deadline and lifecycle exceptions

The report accepts only dates directly supported by the reviewed sources. The most important unsupported-date pattern is the use of future dates that resemble prior-year dates. Examples include the stored KPMG, Lagos State, Midwestern, MTN, NNPC–Renaissance, NNPC/Seplat, PAU, and PTDF dates. They should not be presented as published 2027 dates.

The four records identified in the inventory with future deadlines and old cycle-close markers—PAU, Midwestern, MTN, and NNPC–Renaissance—need separate data-model treatment. Their old close markers may refer to an earlier cycle while the future deadline refers to an unverified next cycle. The evidence does not justify simply deleting or overwriting those fields without an editorial decision.

For records with a past deadline and no close marker, the past deadline already drives the current closed predicate. A missing close marker is therefore a provenance/completeness issue, not proof that the public lifecycle state is wrong. Do not infer an exact closure timestamp from a past deadline.

## 7. Verification-date recommendations

Set `last_verified_at` to 2026-11-07 for ASUU, Bode Amao, Decagon, Ejiro, Florence, JG Afrika, KPMG, Lagos State, Light and Bells, Midwestern, MTN, NNPC–Renaissance, NNPC/Seplat, Project 100, and PTDF. These dates record a substantive source review and should not be interpreted as an open-status field.

For NDDC, record the 2026-11-07 source-review date with a `SOURCE_UNAVAILABLE` or equivalent qualification because the official announcement was read but the portal’s substantive state could not be confirmed. For PAU, retain `REQUIRES_MANUAL_REVIEW` or an equivalent conflict flag until the PAU cycle-specific closure statement and the Mastercard Foundation’s undated directory label are reconciled.

## 8. Prioritized correction register

### P0 — critical destination correction

1. **Decagon:** replace the stored 404 destination with the official `decagon.institute/apply` landing page and link its secure application form from the instructions.

### P1 — material instruction, status, or access correction

1. Add current, source-backed instructions for Decagon and JG Afrika.
2. Add cycle-qualified status instructions for Light and Bells and NDDC.
3. Remove or qualify unsupported detailed instructions for ASUU, Bode Amao, and any record where the current provider route conflicts with the stored checklist.
4. Preserve the NDDC official deadline while flagging portal requirements as unavailable.
5. Reconcile PAU’s conflicting current-status labels before presenting it as open or closed.

### P2 — provenance and verification correction

1. Add the 2026-11-07 review date to the 15 records supported by substantive source checks.
2. Add source provenance for every proposed instruction and date.
3. Preserve `SOURCE_UNAVAILABLE` for NDDC rather than treating transport failure as programme closure.
4. Keep historical-cycle requirements visibly dated.

### P3 — lifecycle and future-date cleanup

1. Remove or mark unsupported 2027 dates for the affected records.
2. Do not create precise `last_cycle_closed_at` values when only a published deadline is known.
3. Review the four future-deadline/old-close-marker cases as a separate lifecycle-data task.
4. Keep the 11 inventory-wide date-only flags outside this 17-record source-revalidation result set until separately researched.

## 9. Unresolved issues

The review does not establish whether ASUU has a central national application route. Bode Amao’s official postal and email instructions remain inconsistent. PAU’s provider page and Foundation directory disagree on current status. NDDC’s portal accessibility and complete current requirements remain unresolved. Decagon’s live landing page says applications are open but publishes no closing date. JG Afrika also publishes no closing date. Light and Bells’ current page does not verify the stored document checklist or the exact response status of its linked form.

The review also does not establish whether any provider will run a subsequent cycle, whether eligibility will change, or whether a closed-cycle application route will be reused. Those unknowns should remain explicit in the database or editorial workflow.

## 10. Recommended future implementation batches

**Batch 1 — urgent destination and time-sensitive status:** correct Decagon’s broken route; preserve NDDC’s 8 November deadline and source-unavailable warning; add current Decagon/JG Afrika instructions; verify the NDDC portal through an approved public access path without bypassing controls.

**Batch 2 — instruction and provenance cleanup:** apply cycle-qualified instructions for Light and Bells and the closed-cycle records; add source links and 2026-11-07 verification dates where approved; resolve Bode Amao’s submission-channel conflict and PAU’s status conflict manually.

**Batch 3 — lifecycle normalization:** decide how the application model represents historical cycles, next-cycle dates, and old close markers; remove unsupported future dates; avoid generating dates by shifting last year’s dates forward.

**Batch 4 — inventory-wide follow-up:** separately source-check the 11 verified records with past deadlines and no close marker that are outside the 17-record set. Do not combine that work with this report’s record count.

All implementation batches require a separate authorized production-change phase. This report does not authorize database updates, schema changes, application changes, or deployment.

## 11. Audit-integrity declaration

This revalidation queried only public scholarship fields for the three queued records and used public provider sources for the 17-record review. No scholarship record was inserted, updated, or deleted. No migration, RLS policy, storage bucket, authentication setting, application code, configuration, deployment, or merge was changed. No student profile, match score, authentication record, secret, or private `research_notes` field was queried or included. The proposed values and priorities in this report remain editorial recommendations until separately approved and implemented.

## References

[1]: https://lightandbellshealth.com/scholarships-and-grants "Scholarships and Grants — Light and Bells Health Foundation"
[2]: https://decagon.institute/ "Decagon Honours Program"
[3]: https://decagon.institute/apply "Apply — Decagon Honours Program"
[4]: https://zfrmz.com/pDDZpINUoiQo2eSg4ifu "Decagon provider-linked application form"
[5]: https://www.facebook.com/OfficialNDDC/posts/nddc-20262027-local-post-graduate-scholarship-call-for-applicationsthe-niger-del/1509046547707715/ "NDDC 2026/2027 Local Post-Graduate Scholarship call"
[6]: https://scholarship.nddc.gov.ng/login "NDDC Scholarship Portal login"
[7]: https://www.nddc.gov.ng/WhatWeDo/Scholarship "NDDC Scholarships"
[8]: https://asuu.org.ng/ "ASUU National"
[9]: https://www.facebook.com/fukashere.edu.ng/posts/-2026-asuu-indigent-scholarship-scheme-call-for-applications-the-academic-staff-/1726142936182968/ "FUK ASUU Indigent Scholarship call"
[10]: https://www.ejirointernationalscholarshipfund.com/apply "Ejiro M Ukiri official application page"
[11]: https://opeketefoundation.org/apply "Opekete Foundation FBM Scholarship"
[12]: https://www.jgafrika.com/careers-offered-at-jg-afrika/bursary/ "JG Afrika bursary application"
[13]: https://kpmg.seamlesshiring.com/job/view/247?utm_source=Direct "KPMG 2026 scholarship listing"
[14]: https://www.lagosscholarship.org/ "Lagos State Scholarship Board"
[15]: https://candidate.scholastica.ng/schemes/2026midwesterncommunity "Midwestern 2026/2027 scheme listing"
[16]: https://www.mtn.ng/scholarships/ "MTN Nigeria scholarships"
[17]: https://renaissanceafrica.com/sustainability/education "Renaissance Africa Education and Scholarships"
[18]: https://candidate.scholastica.ng/schemes/NNPCRENAISSANCEJV2026 "NNPC–Renaissance 2026 scheme listing"
[19]: https://www.seplatenergy.com/news-insights/news/nnpcseplat-jv-national-undergraduate-scholarship-2026/ "Seplat 2026 scholarship announcement"
[20]: https://pau.edu.ng/mastercard-foundation/ "PAU Mastercard Foundation Scholars Program"
[21]: https://mastercardfdn.org/en/what-we-do/our-programs/mastercard-foundation-scholars-program/where-to-apply/pan-atlantic-university/ "Mastercard Foundation PAU partner page"
[22]: https://www.afrotechgirls.org/post/100-girls-100-000-each-one-big-step-forward "Afro-Tech Girls Project 100 for 100 announcement"
[23]: https://docs.google.com/forms/d/e/1FAIpQLSdIPjdJlAbyfkDEnxue9oV0BP339_v7S_Oj2BiveQJKQ_idWw/viewform "Project 100 for 100 application form"
[24]: https://scholarship.ptdf.gov.ng/guidelines "PTDF scholarship guidelines"
[25]: https://scholarship.ptdf.gov.ng/ "PTDF Scholarship Portal"
