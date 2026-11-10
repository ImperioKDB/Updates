# Scholars — Phase 1.2 Production Correction Specification

**Audit date:** 7 November 2026  
**Prepared for:** Independent founder/editorial review  
**Application repository:** `ImperioKDB/Scholars`  
**Reporting repository:** `ImperioKDB/Updates`  
**Production project:** `cmdglabohpttgfofcmqc` (`scholarship-platform`, `eu-west-1`)  
**Scope:** Decision preparation only. No production, application, schema, configuration, deployment, or merge changes were made.

## 1. Executive decision summary

This specification reconciles the 17 target scholarship records against the latest read-only production snapshot and the Phase 1/Phase 1.1 evidence package. It does not authorize implementation. Evidence freshness is explicit: the three records **Light and Bells, Decagon, and NDDC** were freshly rechecked in the Phase 1.1 refresh; the other 14 records are carried forward from the completed Phase 1 evidence notes and were not independently re-opened during this Phase 1.2 preparation.

The conservative decision is **not ready for a broad correction batch**. One small, independent correction is technically ready: add provider-backed `how_to_apply` text to the JG Afrika record while leaving every lifecycle and verification field unchanged. All other proposed edits either require a founder/editorial decision, should preserve a closed historical cycle, or lack sufficiently unambiguous evidence for a safe database value.

Primary dispositions:

- **SAFE TO CORRECT — 1:** JG Afrika, instructions only.
- **CORRECT AFTER CLARIFICATION — 5:** ASUU, Bode Amao, Decagon, Mastercard Foundation at PAU, and NDDC.
- **HISTORICAL / CLOSED — PRESERVE AND QUALIFY — 7:** Ejiro M. Ukiri, Florence Bamidele Makanjuola, Light and Bells, Midwestern Oil & Gas, MTN Foundation, NNPC/Seplat JV, and Project 100 for 100.
- **INSUFFICIENT EVIDENCE — LEAVE UNCHANGED — 4:** KPMG, Lagos State Scholarship Board, NNPC–Renaissance, and PTDF.

No deadline, opening date, close marker, or `last_verified_at` value should be changed in the first batch. Unsupported future dates must not be silently treated as announced 2027 dates.

## 2. Audit provenance and evidence freshness

The production snapshot was refreshed read-only on **2026-11-07 at 16:56:34+00**. The targeted query returned all 17 expected UUIDs with the same stored values recorded in the Phase 1.1 audit.

The authoritative materials reconciled were:

1. `SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_2026-11-07.md` — carried-forward Phase 1 report and 17 evidence notes.
2. `SCHOLARS_PHASE_1_1_IMPLEMENTATION_READINESS_AUDIT_2026-11-07.md` — exact production UUIDs, stored values, schema findings, and implementation-readiness decision.
3. `SCHOLARS_PHASE_1_1_REFRESH_AUDIT_2026-11-07.md` — Phase 1.1 refresh report published at commit [`70f0eb2679c64e249744a3aed929b838257632d0`](https://github.com/ImperioKDB/Updates/commit/70f0eb2679c64e249744a3aed929b838257632d0).

**Freshly rechecked in Phase 1.1:** Light and Bells, Decagon, and NDDC.  
**Carried forward from Phase 1 evidence:** ASUU, Bode Amao, Ejiro, Florence, JG Afrika, KPMG, Lagos State, PAU, Midwestern, MTN, NNPC–Renaissance, NNPC/Seplat, Project 100, and PTDF.

Carried-forward evidence remains usable for decision preparation, but it must not be described as independently reverified in this specification. Provider status, deadlines, and application routes can change; any implementation must repeat the relevant source check immediately before writing.

## 3. Production inventory

The latest inventory query returned:

- 95 total scholarship rows.
- 44 verified rows.
- 44 verified rows with usable slugs.
- 11 verified rows missing `how_to_apply`.
- 15 verified rows missing `last_verified_at`.
- 4 verified rows missing deadlines.
- 17 verified rows with past deadlines.
- 4 verified rows with future deadlines and historical close markers.

The application logic treats `deadline` and `last_cycle_closed_at` as closed-state inputs and `opens_at` as an upcoming-state input. Dates are therefore product behavior, not harmless metadata. The schema has no structured uncertainty field, portal-status field, historical-cycle entity, source URL field, or paid-programme taxonomy.

## 4. Seventeen-record decision matrix

| Record and exact UUID | Evidence freshness | Current relevant values | Primary disposition | Proposed decision | Safe for later batch? |
|---|---|---|---|---|---|
| ASUU — `31cfebd0-100f-4b06-9250-52af820d74d4` | Carried forward | URL `NULL`; instructions present; deadline `2026-09-30`; close `NULL`; verified `true`; last verified `NULL` | CORRECT AFTER CLARIFICATION | Preserve branch-qualified model; do not invent a national URL. Clarify whether the national record is acceptable and whether current text may remain historical/branch-specific. | No, until editorial decision |
| Bode Amao — `215ee2c9-28de-4609-b0b7-6898ae513a21` | Carried forward | URL official homepage; instructions present; deadline `2026-12-31`; last verified `NULL` | CORRECT AFTER CLARIFICATION | Preserve the homepage. Resolve the provider’s conflicting postal and email submission routes before changing instructions or deadline status. | No |
| Decagon — `769b1169-71af-4f55-9be4-63374a59faa8` | Freshly rechecked | URL `https://www.decagonfoundation.org/apply`; instructions present; deadline `2026-10-15`; last verified `2026-10-06` | CORRECT AFTER CLARIFICATION | Keep the Foundation scholarship route separate from the Institute paid route. Remove/qualify the stale deadline only after clarification of scholarship funding, fees, and route relationship. | No |
| Ejiro M. Ukiri — `4c469077-cd38-424c-8913-463c7068d304` | Carried forward | Jotform URL; instructions present; deadline/opens/close `NULL`; last verified `NULL` | HISTORICAL / CLOSED — PRESERVE AND QUALIFY | Preserve the provider route and cycle-qualified instructions only if clearly dated. Do not claim a current opening. | Only after current-cycle recheck |
| Florence Bamidele Makanjuola — `aaaaaaaa-0000-4000-8000-000000000023` | Carried forward | URL `https://opeketefoundation.org/apply`; instructions `NULL`; opens `2027-05-01`; deadline `2027-05-22` | HISTORICAL / CLOSED — PRESERVE AND QUALIFY | Preserve the provider page and closed 2026 facts. Do not present the stored 2027 dates as published. | No lifecycle batch; historical qualification only |
| JG Afrika — `64790f70-f20a-4c9c-a1f4-2efabc087dcb` | Carried forward | Official bursary URL; instructions `NULL`; all date fields `NULL`; verified `true`; last verified `NULL` | SAFE TO CORRECT | Add provider-backed application instructions only. Leave URL, dates, close marker, and verification timestamp unchanged. | **Yes — first batch** |
| KPMG — `cccccccc-0000-4000-8000-000000000016` | Carried forward | 2025 provider-linked URL; instructions `NULL`; opens `2027-08-01`; deadline `2027-08-13`; close `NULL` | INSUFFICIENT EVIDENCE — LEAVE UNCHANGED | Do not convert the expired 2026 evidence into 2027 instructions or accept the stored 2027 dates as published. | No |
| Lagos State Scholarship Board — `d9c8ed08-35be-4fe8-aa9d-221909c39947` | Carried forward | Official homepage; instructions `NULL`; opens `2027-01-19`; deadline `2027-03-06`; close `NULL` | INSUFFICIENT EVIDENCE — LEAVE UNCHANGED | Preserve the official homepage. Do not fill missing instructions or treat the stored 2027 dates as announced. | No |
| Light and Bells — `e93e25b7-46a5-4254-b1c5-91ad56a3abf0` | Freshly rechecked | Official page; detailed checklist present; deadline `2026-10-02`; close `NULL`; last verified `NULL` | HISTORICAL / CLOSED — PRESERVE AND QUALIFY | Qualify the 2026 cycle as closed by its published deadline while noting selection notification was still pending. Do not carry forward checklist items not supported by the current page. | Only after editorial approval of historical wording |
| Mastercard Foundation at PAU — `aaaaaaaa-0000-4000-8000-000000000021` | Carried forward | PAU page; instructions `NULL`; deadline `2027-05-22`; close `2026-05-22`; last verified `NULL` | CORRECT AFTER CLARIFICATION | Reconcile PAU’s cycle-specific closure statement with the Foundation directory’s undated “Admissions Open” label before changing status or adding instructions. | No |
| Midwestern Oil & Gas — `cccccccc-0000-4000-8000-000000000015` | Carried forward | Scholastica root; instructions `NULL`; deadline `2027-03-19`; close `2026-03-19` | HISTORICAL / CLOSED — PRESERVE AND QUALIFY | Preserve the legitimate platform URL but qualify the documented 2026/2027 cycle as closed. Do not treat `2027-03-19` as supported. | No lifecycle batch |
| MTN Foundation — `aaaaaaaa-0000-4000-8000-000000000001` | Carried forward | MTN page; instructions `NULL`; deadline `2027-05-31`; close `2026-05-31` | HISTORICAL / CLOSED — PRESERVE AND QUALIFY | Preserve programme existence and historical eligibility only. Do not treat the stored 2027 date as official. | No lifecycle batch |
| NDDC — `107bccf4-a01e-4ac6-b4bc-beaa482e403e` | Freshly rechecked | Official portal URL; instructions present; deadline `2026-11-08`; last verified `2026-10-13` | CORRECT AFTER CLARIFICATION | Retain the official deadline and route, but qualify portal status as unconfirmed because of Cloudflare/access and content-integrity anomalies. Obtain provider confirmation before changing instructions or verification. | No |
| NNPC–Renaissance — `aaaaaaaa-0000-4000-8000-000000000006` | Carried forward | Scholastica root; instructions `NULL`; deadline `2027-05-31`; close `2026-05-31` | INSUFFICIENT EVIDENCE — LEAVE UNCHANGED | Do not replace the generic platform root or populate future-cycle instructions without a new official announcement. | No |
| NNPC/Seplat JV — `aaaaaaaa-0000-4000-8000-000000000004` | Carried forward | Provider-linked page; instructions `NULL`; opens `2027-02-23`; deadline `2027-03-13`; close `NULL` | HISTORICAL / CLOSED — PRESERVE AND QUALIFY | Preserve dated 2026 eligibility only if labeled historical. Do not treat the shifted 2027 dates as official. | No lifecycle batch |
| Project 100 for 100 — `7eae077d-8290-4c07-abe5-95d993a554fe` | Carried forward | Google Form URL; instructions `NULL`; deadline `2026-09-25`; close `NULL` | HISTORICAL / CLOSED — PRESERVE AND QUALIFY | Preserve the 2026 cycle as closed and do not represent the form as currently accepting applications. | Only after editorial approval of historical wording |
| PTDF In-Country Undergraduate — `aaaaaaaa-0000-4000-8000-000000000012` | Carried forward | Official portal; instructions `NULL`; opens `2027-04-20`; deadline `2027-05-29`; close `NULL` | INSUFFICIENT EVIDENCE — LEAVE UNCHANGED | Preserve the official portal. Do not treat stored 2027 dates as published or write future-cycle requirements. | No |

## 5. Detailed evidence and proposed changes

### ASUU — `31cfebd0-100f-4b06-9250-52af820d74d4`

The carried-forward evidence confirms ASUU scholarship activity and a 2026 FUK branch call, but that call was explicitly branch-specific. It does not establish a national portal, universal requirements, or a nationwide deadline. The current instructions describe a branch-mediated process and should not be presented as a universal ASUU process without qualification.

**Proposed value:** no URL; retain only branch-qualified instructions after approval.  
**Must remain unchanged:** deadline `2026-09-30` unless separately classified as historical; all lifecycle fields; `last_verified_at`.  
**Student-facing implication:** a national-looking listing could mislead students into believing every university follows the FUK process.  
**Clarification required:** whether Scholars should keep one national ASUU record or split/label branch-specific opportunities.  
**Source:** [ASUU National](https://asuu.org.ng/) and the [FUK ASUU call](https://www.facebook.com/fukashere.edu.ng/posts/-2026-asuu-indigent-scholarship-scheme-call-for-applications-the-academic-staff-/1726142936182968/).  
**Batch status:** not ready.

### Bode Amao — `215ee2c9-28de-4609-b0b7-6898ae513a21`

The carried-forward review confirms the official homepage but found conflicting official submission channels. The stored checklist includes sensitive and consequential requirements, including medical/HIV documentation and registrar attestation. The conflict must not be silently resolved by selecting one channel.

**Proposed value:** retain the official homepage; make no instruction change until BAF confirms the authoritative channel and current cycle.  
**Must remain unchanged:** deadline `2026-12-31`, instructions, and `last_verified_at` pending provider confirmation.  
**Student-facing implication:** changing to one unconfirmed email could cause missed applications or privacy risk.  
**Clarification required:** which submission route is current, whether the 2026-12-31 date is officially published, and whether the full checklist remains current.  
**Source:** [Bode Amao Foundation](https://bodeamaofoundation.org/).  
**Batch status:** not ready.

### Decagon — `769b1169-71af-4f55-9be4-63374a59faa8`

The Phase 1.1 refresh freshly rechecked both official routes. The Foundation application page says applications are open for a scholarship and links to a provider-controlled form. Foundation pages support Nigerian citizenship, JAMB/UTME 250+, financial need, no loan/no repayment, and tuition paid directly to a partner university. The Institute route also says applications are open, but its official fees page states a ₦275,000 annual programme fee plus university tuition and school-related fees.

**Proposed value:** do not change the URL until written clarification confirms that the Foundation scholarship is a distinct funded route. If confirmed, the scholarship URL should remain `https://www.decagonfoundation.org/apply`; the paid Institute URL must not replace it.  
**Must remain unchanged:** the 2026-10-15 deadline must not remain an active deadline, but its removal/qualification is a separate approved lifecycle decision; do not set `last_verified_at` from this review alone.  
**Student-facing implication:** directing scholarship seekers to the paid route could expose them to an unexpected ₦275,000 annual charge and tuition costs.  
**Clarification required:** tuition-only versus accommodation/living support; whether scholarship recipients pay the Institute fee; whether the fee applies to scholarship recipients; confirmed partner universities; whether the two routes share selection; current funding and closing date.  
**Sources:** [Foundation homepage](https://www.decagonfoundation.org/), [Foundation apply](https://www.decagonfoundation.org/apply), [Foundation for students](https://www.decagonfoundation.org/for-students), [Foundation about](https://www.decagonfoundation.org/about), [Institute apply](https://decagon.institute/apply), and [Institute fees](https://decagon.institute/fees).  
**Batch status:** not ready.

### Ejiro M. Ukiri — `4c469077-cd38-424c-8913-463c7068d304`

The carried-forward evidence confirms the provider application page and a closed 2026 cycle. The relationship between the stored Jotform and the provider’s current `/apply` page was not fully established, so no route replacement should be made without a current recheck.

**Proposed value:** preserve the official provider destination and label any 2026 requirements as historical.  
**Must remain unchanged:** no deadline should be invented; do not set a future opening or `last_verified_at`.  
**Student-facing implication:** historical requirements must not appear to be current.  
**Clarification:** whether the provider has announced a subsequent cycle and which form is canonical.  
**Source:** [Ejiro official application page](https://www.ejirointernationalscholarshipfund.com/apply).  
**Batch status:** historical qualification only, after current-cycle recheck.

### Florence Bamidele Makanjuola — `aaaaaaaa-0000-4000-8000-000000000023`

The carried-forward evidence confirms the Opekete Foundation programme, the May 1–22, 2026 cycle, and a provider-linked form that was no longer accepting responses. The stored 2027-05-01 and 2027-05-22 dates were not supported.

**Proposed value:** retain the official `/apply` page and qualify the record as a closed 2026 cycle. Do not publish the stored 2027 dates as announced.  
**Must remain unchanged:** no invented close timestamp; no future-cycle instructions; `last_verified_at` until a consistent policy is approved.  
**Student-facing implication:** students must see that the linked form was closed and that no next-cycle dates were verified.  
**Source:** [Opekete application page](https://opeketefoundation.org/apply), [Opekete homepage](https://www.opeketefoundation.org/), and the provider-linked [2026/27 form](https://forms.gle/P13HSQaVUZoaoG8V7).  
**Batch status:** no lifecycle batch.

### JG Afrika — `64790f70-f20a-4c9c-a1f4-2efabc087dcb`

The carried-forward evidence supports the official 2027 bursary page and provider announcement as actionable on 7 November 2026. The provider lists BSc/BEng or MSc/MEng Civil Engineering, applicant/education/guardian sections, motivation, ID, Matric certificate, full transcript, funding disclosure, consent, and CAPTCHA. No closing deadline is published. The 1 January 2027 date is an unsuccessful-notification date, not a submission deadline.

**Safe proposed value:** add `how_to_apply` with the provider-backed instructions; retain the official URL; leave `opens_at`, `deadline`, `last_cycle_closed_at`, and `last_verified_at` unchanged.  
**Student-facing implication:** students receive actionable requirements without an invented deadline.  
**Source:** [JG Afrika bursary page](https://www.jgafrika.com/careers-offered-at-jg-afrika/bursary/), [JG Afrika provider announcement](https://www.linkedin.com/posts/jg-afrika-pty-ltd_jgafrika-bursaryopportunities-activity-7496086303910985729-x31d), and [provider link redirect](https://lnkd.in/dArVhsm).  
**Batch status:** safe as the smallest first batch, subject to a final same-day source recheck immediately before implementation.

### KPMG — `cccccccc-0000-4000-8000-000000000016`

The carried-forward evidence shows the stored route is a provider-linked 2025 listing and the latest authoritative 2026 listing was expired. No 2027 announcement, deadline, or current instructions were found.

**Proposed value:** none. Leave the URL, instructions, and lifecycle fields unchanged until a new official cycle is found.  
**Student-facing implication:** the listing should not suggest that the stale route is an open 2027 application.  
**Clarification:** whether KPMG has published a new cycle and whether the stored future dates are editorial predictions.  
**Source:** [KPMG 2026 listing](https://kpmg.seamlesshiring.com/job/view/247?utm_source=Direct), [stored 2025 listing](https://kpmg.seamlesshiring.com/job/view/181), and [KPMG announcement](https://www.facebook.com/kpmg.ng/posts/2026-seyi-bickersteth-scholarship-programme-applications-are-now-open-to-100-lev/1678766657587546/).  
**Batch status:** not ready.

### Lagos State Scholarship Board — `d9c8ed08-35be-4fe8-aa9d-221909c39947`

The carried-forward evidence confirms the Board and its 2025/2026 cycle, which had concluded. The official site and portal were reachable but did not provide substantive current-cycle instructions; a login screen is not proof that applications are open. The stored 2027 dates were unsupported.

**Proposed value:** none until a current official notice or complete portal guidance is available.  
**Must remain unchanged:** instructions, `opens_at`, `deadline`, and `last_verified_at`.  
**Student-facing implication:** invented requirements or future dates could cause missed or misdirected applications.  
**Source:** [Lagos State Scholarship Board](https://www.lagosscholarship.org/), [official portal](https://portal.lagosscholarship.org/), and [portal terms](https://portal.lagosscholarship.org/terms-and-condition).  
**Batch status:** not ready.

### Light and Bells — `e93e25b7-46a5-4254-b1c5-91ad56a3abf0`

The Phase 1.1 refresh confirms the 2026 window ended at 11:59 PM WAT on 2 October. The official page supports G&G medicine, JSI nursing, and Vision allied-health categories at government institutions, a $100 award, and notification by 18 December. It does not safely re-establish every item in the stored document checklist.

**Proposed value:** after approval, replace or qualify the detailed instructions with a dated closed-cycle note. Retain the official URL and deadline. Do not create a precise `last_cycle_closed_at`; the deadline is not an observed closure event.  
**Student-facing implication:** students should not submit a late 2026 application or rely on unsupported checklist items. Selection may still be pending as of the audit date.  
**Source:** [official scholarships page](https://lightandbellshealth.com/scholarships-and-grants) and [provider announcement](https://www.instagram.com/p/Dac4NHmlxK6/).  
**Batch status:** requires editorial approval of historical wording.

### Mastercard Foundation at PAU — `aaaaaaaa-0000-4000-8000-000000000021`

The carried-forward evidence found a conflict between PAU’s cycle-specific closed information and the Mastercard Foundation directory’s undated “Admissions Open” label. The conflict cannot be resolved by choosing the more favorable status.

**Proposed value:** no status, date, or instruction change until the provider and Foundation sources are reconciled for the same cycle.  
**Student-facing implication:** an incorrect open/closed label could cause students to miss a cycle or apply after closure.  
**Clarification:** which source governs the current cycle, whether “Admissions Open” is a stale directory label, and whether the 2027 date is supported.  
**Sources:** [PAU programme page](https://pau.edu.ng/mastercard-foundation/) and [Mastercard Foundation partner page](https://mastercardfdn.org/en/what-we-do/our-programs/mastercard-foundation-scholars-program/where-to-apply/pan-atlantic-university/).  
**Batch status:** not ready.

### Midwestern Oil & Gas — `cccccccc-0000-4000-8000-000000000015`

The carried-forward evidence confirms the 2026/2027 host-community scheme and a published 19 April 2026 deadline, with the direct Scholastica route showing the cycle closed. The stored 2027-03-19 date is not supported.

**Proposed value:** preserve the legitimate platform URL and qualify the documented cycle as closed. Do not write the unsupported future date or a new close timestamp.  
**Student-facing implication:** students must not be directed to a generic platform homepage as if it were a live programme-specific form.  
**Source:** [Midwestern official announcement](https://midwesternog.com/midwestern-2026-2027-jv-secondary-school-university-scholarship-award-scheme/) and [direct scheme route](https://candidate.scholastica.ng/schemes/2026midwesterncommunity).  
**Batch status:** no lifecycle batch.

### MTN Foundation — `aaaaaaaa-0000-4000-8000-000000000001`

The carried-forward evidence confirms the programme and historical eligibility but does not support the stored 2027-05-31 date as a published next-cycle deadline. The old close marker reflects a prior cycle and should not be blindly paired with the future date.

**Proposed value:** preserve historical programme information; do not change future dates or add current instructions without a new official announcement.  
**Student-facing implication:** unsupported 2027 dates could falsely imply an upcoming application window.  
**Source:** [MTN Nigeria scholarships](https://www.mtn.ng/scholarships/).  
**Batch status:** no lifecycle batch.

### NDDC — `107bccf4-a01e-4ac6-b4bc-beaa482e403e`

The Phase 1.1 refresh confirms the official 2026/2027 call, Niger Delta target population, free application statement, official portal route, and 8 November deadline. The portal login surface was readable, but public checks also produced Cloudflare 403 challenges and unrelated root content. This does not prove closure or successful submission acceptance.

**Proposed value:** retain the official URL and published deadline; add a source-unavailable/manual-review qualification only after approval. Do not fill missing requirements from inference.  
**Student-facing implication:** students should use only the official route and not pay intermediaries, while being warned that live registration/submission could not be confirmed.  
**Clarification:** confirm through NDDC whether the portal is the intended uncompromised service and whether new applicants can submit before the stated deadline.  
**Sources:** [NDDC homepage](https://nddc.gov.ng/), [NDDC scholarship page](https://nddc.gov.ng/WhatWeDo/Scholarship), [NDDC official announcement](https://www.facebook.com/OfficialNDDC/posts/nddc-20262027-local-post-graduate-scholarship-call-for-applicationsthe-niger-del/1509046547707715/), and [portal login](https://scholarship.nddc.gov.ng/login).  
**Batch status:** not ready.

### NNPC–Renaissance — `aaaaaaaa-0000-4000-8000-000000000006`

The carried-forward evidence confirms the 2026 scheme and its closed Scholastica listing. The stored generic platform URL is legitimate but not programme-specific, and the stored 2027-05-31 date is unsupported.

**Proposed value:** none until a new official cycle and programme-specific route are published.  
**Student-facing implication:** a generic platform homepage must not be presented as a live application route for this scholarship.  
**Source:** [Renaissance education page](https://renaissanceafrica.com/sustainability/education) and [2026 Scholastica listing](https://candidate.scholastica.ng/schemes/NNPCRENAISSANCEJV2026).  
**Batch status:** not ready.

### NNPC/Seplat JV — `aaaaaaaa-0000-4000-8000-000000000004`

The carried-forward evidence confirms the 2026 announcement, free application, 23 February–13 March 2026 window, and provider-linked destination. It does not establish a 2027 cycle. The stored 2027 dates resemble the prior dates shifted forward one year.

**Proposed value:** preserve the provider-linked URL and retain any requirements only as historical 2026 instructions. Do not present the 2027 dates as official.  
**Student-facing implication:** students should not infer that the same route is open in 2027.  
**Source:** [Seplat 2026 announcement](https://www.seplatenergy.com/news-insights/news/nnpcseplat-jv-national-undergraduate-scholarship-2026/) and [provider route](https://seplatgrowthacademy.com/scholarship/).  
**Batch status:** historical qualification only.

### Project 100 for 100 — `7eae077d-8290-4c07-abe5-95d993a554fe`

The carried-forward evidence supports the 2026 announcement and Google Form, with a 25 September 2026 deadline. No future cycle was established and the form should not be represented as open.

**Proposed value:** preserve the provider-linked form as historical evidence and qualify the record as closed. Do not invent a future cycle or close timestamp.  
**Student-facing implication:** students should not submit through a form that is not confirmed to accept responses.  
**Source:** [Afro-Tech Girls announcement](https://www.afrotechgirls.org/post/100-girls-100-000-each-one-big-step-forward) and [Project 100 form](https://docs.google.com/forms/d/e/1FAIpQLSdIPjdJlAbyfkDEnxue9oV0BP339_v7S_Oj2BiveQJKQ_idWw/viewform).  
**Batch status:** historical qualification only.

### PTDF In-Country Undergraduate — `aaaaaaaa-0000-4000-8000-000000000012`

The carried-forward evidence confirms the official PTDF portal and the 2026/2027 published window of 27 April–5 June 2026. The stored 2027 dates were not substantiated by the official sources.

**Proposed value:** preserve the official portal and historical 2026/2027 requirements only when clearly dated. Do not publish the stored 2027 opening/deadline or invent a close event.  
**Student-facing implication:** applicants must not mistake predicted dates for a published intake.  
**Source:** [PTDF guidelines](https://scholarship.ptdf.gov.ng/guidelines) and [PTDF portal](https://scholarship.ptdf.gov.ng/).  
**Batch status:** not ready.

## 6. Decagon coverage and fee questions requiring written confirmation

The following questions must be answered by Decagon Foundation/Decagon Services before any Decagon database correction:

1. Does the Foundation scholarship cover tuition only, or also accommodation and living costs? The Foundation FAQ is broader than the application and student pages.
2. Must Foundation scholarship recipients pay the Institute’s published ₦275,000 annual programme fee?
3. Does the ₦275,000 fee apply only to paid Institute applicants, or also to scholarship applicants?
4. Which partner universities are currently confirmed, and are Christopher University and Wellspring University the complete current list?
5. Are the Foundation scholarship form and Institute paid-programme form separate selection routes, linked routes, or two presentations of one process?
6. Is the Foundation scholarship currently funded and accepting applications on a rolling basis?
7. Is there a current closing date or only rolling review?
8. Does any current scholarship recipient receive a written fee waiver covering the Institute charge?

Until these are answered, Scholars should not direct scholarship applicants to the Institute paid route or describe the paid programme as a scholarship.

## 7. Verification timestamp policy recommendation

`last_verified_at` is publicly displayed as a verification claim. It should not mean merely that a researcher opened a page. The minimum standard should require all of the following:

1. An authoritative provider or official institutional source was read on the stated date.
2. The source is linked to the exact programme and current cycle.
3. The application destination and its provenance are understood.
4. The public status is established as actionable, explicitly closed, or otherwise clearly classified.
5. Stored dates and instructions are reconciled against the source.
6. Any conflict or access limitation is represented in the editorial record rather than hidden by an unqualified timestamp.

Under this stricter policy, **JG Afrika** is the only record currently suitable for an unqualified current-actionability verification candidate, and even it should be timestamped only in a separately approved verification batch. Decagon, NDDC, PAU, ASUU, and Bode require qualification or clarification. Historical records should not receive an unqualified “live” verification timestamp merely because a historical source was reviewed. A schema-level distinction between `source_reviewed_at` and `application_status_verified_at` would be safer, but schema changes are outside this phase.

## 8. Lifecycle-field risk assessment

The following fields are high risk:

- `deadline` can make a listing closed and can hide it from public catalogue queries.
- `opens_at` can make a listing upcoming and affect discovery or reminders.
- `last_cycle_closed_at` can override a future deadline and produce a closed state.
- `last_verified_at` is public-facing and may influence freshness or notification logic.
- `verified` controls whether the opportunity is publicly treated as verified.

No Phase 1.2 batch should change these fields. A lifecycle change requires a source-backed before/after decision, an explicit intended public status, a review of catalogue and reminder effects, and a post-change query against the exact UUID. Do not derive `last_cycle_closed_at` from a deadline alone. Do not shift a prior year’s dates forward into a new cycle. Do not bulk-clear or bulk-rewrite future dates.

## 9. Proposed correction batches

### Batch 1 — JG Afrika instructions only

**Record:** `64790f70-f20a-4c9c-a1f4-2efabc087dcb`  
**Field:** `how_to_apply` only  
**Before:** `NULL`  
**After:** Provider-backed instructions covering the official 2027 bursary form, eligible Civil Engineering qualifications, applicant/education/guardian sections, motivation, ID, Matric certificate, complete transcript, funding disclosure, consent, CAPTCHA, incomplete-application warning, and the fact that 1 January 2027 is an unsuccessful-notification date rather than a deadline.

**Risk:** Low-to-moderate. It changes student-facing instructions but not lifecycle or verification behavior.  
**Preconditions:** Same-day re-open of the JG Afrika provider page; explicit approval to write the exact text; use the existing authenticated admin route.  
**Exclusions:** No change to URL, `opens_at`, `deadline`, `last_cycle_closed_at`, `last_verified_at`, or `verified`.  
**Validation:** Query the exact UUID and requested field after the write; confirm all excluded fields are unchanged; run application tests/build; inspect the public details page; verify no notification or lifecycle state changed.  
**Rollback:** Restore the prior `NULL` value through the same authorized admin path if the provider page changes or the wording is rejected.

### Batch 2 — Historical qualification, record by record

Potential records: Ejiro, Florence, Light and Bells, Midwestern, MTN, NNPC/Seplat, and Project 100. This is not approved. Each record requires a separate editorial decision on whether the existing free-text instruction field may contain historical closed-cycle information and how the frontend should label it. Do not group these into a blind batch.

### Batch 3 — Clarification-dependent corrections

Potential records: ASUU, Bode Amao, Decagon, PAU, and NDDC. No field should be changed until the precise questions in this specification are answered and the relevant provider source is rechecked.

### Batch 4 — Lifecycle normalization

No records are ready for a lifecycle batch. KPMG, Lagos State, NNPC–Renaissance, and PTDF should remain unchanged pending new authoritative current-cycle evidence. The four future-deadline/old-close-marker cases require a separate product/data-model decision before any date field is edited.

## 10. Founder approval decisions required

1. Approve or reject the JG Afrika `how_to_apply`-only batch.
2. Confirm whether `last_verified_at` means “source reviewed” or “current application status verified.”
3. Decide whether historical closed-cycle instructions may remain in the public `how_to_apply` field and how they must be labeled.
4. Decide whether unsupported future dates may be nulled, retained as explicitly unverified editorial data, or moved to a future-cycle model. No implementation should guess.
5. Decide whether Decagon belongs in the scholarship catalogue when its related Institute route charges ₦275,000 per year plus tuition.
6. Obtain written Decagon clarification on tuition, accommodation/living support, the Institute fee, partner universities, and route relationship.
7. Decide how to represent ASUU’s branch-mediated model without implying a national route.
8. Resolve Bode Amao’s conflicting official submission channels.
9. Resolve PAU’s cycle-specific closure versus undated Foundation directory status.
10. Obtain a reliable NDDC confirmation of portal integrity and submission acceptance; do not infer status from HTTP 403 or unrelated root content.
11. Approve whether the 2026 Light and Bells cycle should be shown as closed while selection notification remained pending.
12. Confirm that no lifecycle or verification batch may proceed until the application’s public status and notification behavior are reviewed.

## 11. Records and fields that must remain unchanged now

Until the decisions above are made, do not change any of the following:

- All 17 `verified` values.
- All 17 `deadline` values.
- All 17 `opens_at` values.
- All 17 `last_cycle_closed_at` values.
- All 17 `last_verified_at` values.
- Decagon’s URL or classification.
- NDDC’s URL or deadline.
- PAU’s URL or lifecycle fields.
- ASUU’s missing URL.
- Bode Amao’s instructions and conflicting channels.
- KPMG, Lagos State, NNPC–Renaissance, and PTDF future dates.
- Any schema, RLS policy, function, configuration, application code, or deployment.

The only proposed value with a sufficiently bounded first-batch change is JG Afrika’s `how_to_apply`; it is still awaiting explicit approval and a same-day source recheck.

## 12. Final implementation recommendation

**Recommendation: READY FOR REVIEW, NOT APPROVED FOR IMPLEMENTATION.**

The smallest independently bounded candidate is a one-record JG Afrika instructions-only change. No production correction should be performed until the founder explicitly approves that exact field/value and the implementation phase separately confirms the current provider page. All lifecycle, verification, classification, schema, code, and deployment changes remain blocked pending the decisions listed above.

No production data, schema, application code, configuration, RLS policy, deployment, merge, or external application was changed while preparing this specification.

## References

[1]: https://github.com/ImperioKDB/Updates/blob/70f0eb2679c64e249744a3aed929b838257632d0/SCHOLARS_PHASE_1_1_REFRESH_AUDIT_2026-11-07.md "Phase 1.1 refreshed audit"
[2]: https://asuu.org.ng/ "ASUU National"
[3]: https://www.facebook.com/fukashere.edu.ng/posts/-2026-asuu-indigent-scholarship-scheme-call-for-applications-the-academic-staff-/1726142936182968/ "FUK ASUU call"
[4]: https://bodeamaofoundation.org/ "Bode Amao Foundation"
[5]: https://www.decagonfoundation.org/ "Decagon Foundation"
[6]: https://www.decagonfoundation.org/apply "Decagon Foundation application"
[7]: https://www.decagonfoundation.org/for-students "Decagon Foundation student information"
[8]: https://www.decagonfoundation.org/about "Decagon Foundation about and FAQ"
[9]: https://decagon.institute/apply "Decagon Institute application"
[10]: https://decagon.institute/fees "Decagon Institute fees"
[11]: https://www.ejirointernationalscholarshipfund.com/apply "Ejiro M Ukiri application"
[12]: https://opeketefoundation.org/apply "Opekete Foundation application"
[13]: https://forms.gle/P13HSQaVUZoaoG8V7 "Opekete 2026/27 form"
[14]: https://www.jgafrika.com/careers-offered-at-jg-afrika/bursary/ "JG Afrika bursary"
[15]: https://www.linkedin.com/posts/jg-afrika-pty-ltd_jgafrika-bursaryopportunities-activity-7496086303910985729-x31d "JG Afrika provider announcement"
[16]: https://kpmg.seamlesshiring.com/job/view/247?utm_source=Direct "KPMG 2026 listing"
[17]: https://kpmg.seamlesshiring.com/job/view/181 "KPMG 2025 listing"
[18]: https://www.lagosscholarship.org/ "Lagos State Scholarship Board"
[19]: https://portal.lagosscholarship.org/ "Lagos State Scholarship portal"
[20]: https://portal.lagosscholarship.org/terms-and-condition "Lagos State portal terms"
[21]: https://lightandbellshealth.com/scholarships-and-grants "Light and Bells scholarships"
[22]: https://www.instagram.com/p/Dac4NHmlxK6/ "Light and Bells 2026 announcement"
[23]: https://pau.edu.ng/mastercard-foundation/ "PAU Mastercard Foundation programme"
[24]: https://mastercardfdn.org/en/what-we-do/our-programs/mastercard-foundation-scholars-program/where-to-apply/pan-atlantic-university/ "Mastercard Foundation PAU partner page"
[25]: https://midwesternog.com/midwestern-2026-2027-jv-secondary-school-university-scholarship-award-scheme/ "Midwestern official announcement"
[26]: https://candidate.scholastica.ng/schemes/2026midwesterncommunity "Midwestern direct scheme route"
[27]: https://www.mtn.ng/scholarships/ "MTN Nigeria scholarships"
[28]: https://nddc.gov.ng/ "NDDC homepage"
[29]: https://nddc.gov.ng/WhatWeDo/Scholarship "NDDC Scholarships"
[30]: https://www.facebook.com/OfficialNDDC/posts/nddc-20262027-local-post-graduate-scholarship-call-for-applicationsthe-niger-del/1509046547707715/ "NDDC official announcement"
[31]: https://scholarship.nddc.gov.ng/login "NDDC Scholarship Portal"
[32]: https://renaissanceafrica.com/sustainability/education "Renaissance Africa education and scholarships"
[33]: https://candidate.scholastica.ng/schemes/NNPCRENAISSANCEJV2026 "NNPC–Renaissance scheme listing"
[34]: https://www.seplatenergy.com/news-insights/news/nnpcseplat-jv-national-undergraduate-scholarship-2026/ "Seplat 2026 announcement"
[35]: https://seplatgrowthacademy.com/scholarship/ "Seplat application page"
[36]: https://www.afrotechgirls.org/post/100-girls-100-000-each-one-big-step-forward "Project 100 for 100 announcement"
[37]: https://docs.google.com/forms/d/e/1FAIpQLSdIPjdJlAbyfkDEnxue9oV0BP339_v7S_Oj2BiveQJKQ_idWw/viewform "Project 100 for 100 form"
[38]: https://scholarship.ptdf.gov.ng/guidelines "PTDF guidelines"
[39]: https://scholarship.ptdf.gov.ng/ "PTDF portal"
