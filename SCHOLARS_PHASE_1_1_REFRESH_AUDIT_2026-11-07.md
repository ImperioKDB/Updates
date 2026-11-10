# Scholars Phase 1.1 — Resumed Read-Only Audit

**Audit date:** 7 November 2026  
**Production project:** `cmdglabohpttgfofcmqc` (`scholarship-platform`)  
**Application repository:** `ImperioKDB/Scholars`  
**Reporting repository:** `ImperioKDB/Updates`  
**Scope:** Read-only production snapshot and public-source revalidation. No production, code, schema, or deployment changes were made during the audit; this report is being published in a separate authorized documentation commit.

## Continuation status

The previous session’s workflow record (`ee30f0d0dab1`) was not available in the new session, so it could not be resumed by job ID. Following the handoff fallback, the 14 preserved record notes were treated as completed evidence and only the three unfinished records—Light and Bells, Decagon, and NDDC—were refreshed. A duplicate 17-record workflow briefly queued during the transition was stopped before completion and produced no audit result or external change.

## Fresh production snapshot

A new read-only Supabase query at `2026-11-07 16:00:15.384664+00` returned the same inventory as the handoff:

- 95 total scholarship rows.
- 44 verified rows.
- 44 verified rows with usable slugs.
- 11 verified rows missing `how_to_apply`.
- 15 verified rows missing `last_verified_at`.
- 4 verified rows missing deadlines.
- 17 verified rows with past deadlines.
- 4 verified rows with future deadlines and historical close markers.

The targeted query returned all 17 expected UUIDs with the same stored values as the previous snapshot. No private profiles, authentication records, matching data, or private research fields were queried.

## Three refreshed records

### Light and Bells Health Foundation Scholarship 2026

The official provider page confirms three 2026 tuition-support categories: G&G for medicine, JSI for nursing, and Vision for allied health at government institutions. It states that applications ran from 6 July through 11:59 PM WAT on 2 October 2026, with late or incomplete applications excluded. The cycle is therefore closed by its published deadline on the audit date, although the provider’s stated notification date of 18 December 2026 means selection was not necessarily complete.

The page supports the categories, two recipients per category, a $100 award normally paid to the institution, accurate/verifiable application information, and email notification by 18 December. It does not safely re-establish every item in the stored detailed document checklist. The official scholarship page remains the canonical URL. The safest disposition is **PARTIAL / closed-by-deadline**: retain the official page and published deadline, qualify the instructions, and do not describe the programme as cancelled or fully concluded.

Source pages reviewed: [Light and Bells scholarships](https://lightandbellshealth.com/scholarships-and-grants), [Light and Bells homepage](https://lightandbellshealth.com/), and the provider’s [2026 Instagram announcement](https://www.instagram.com/p/Dac4NHmlxK6/).

### Decagon Undergraduate Honors Program

The refresh found two related but materially different official routes. The Foundation’s [application page](https://www.decagonfoundation.org/apply) says applications are open for a Decagon scholarship and links to a provider-controlled form. The Foundation’s student-facing material supports a tuition scholarship for Nigerian applicants with a JAMB/UTME threshold of 250+, financial-need criteria, no loan/no repayment, and tuition paid directly to a university. No current closing date is published.

Separately, [decagon.institute/apply](https://decagon.institute/apply) describes an Honours Programme and the official [fees page](https://decagon.institute/fees) states that participants pay ₦275,000 per year to Decagon in addition to university tuition and school-related fees. No official fee waiver for that paid route was found. The stored 15 October 2026 deadline is not present on the current official pages and should be treated as stale or unsupported.

The safe disposition is **MANUAL REVIEW / conflicting official routes**. Keep the record only as a Foundation scholarship lead if the editorial definition allows it; use the Foundation URL as the scholarship destination; do not replace it with the Institute paid-programme URL; and add a prominent qualification separating the paid route from the Foundation tuition scholarship. Do not assert accommodation or living-cost coverage without further confirmation.

### NDDC Local Post-Graduate Master’s Degree Scholarship 2026/2027

The official NDDC homepage and [scholarship page](https://nddc.gov.ng/WhatWeDo/Scholarship) continue to identify the 2026/2027 Local Post-Graduate Master’s Degree Scholarship, invite Niger Delta indigenes to apply, link to `https://scholarship.nddc.gov.ng/login`, and state an 8 November 2026 deadline. The official announcement supports that the application is free.

The `/login` page was readable as a login surface, but that does not prove that new applicants can register or submit. Direct requests returned Cloudflare HTTP 403 challenges, and the portal root exposed unrelated router-support content in public extraction. These are transport and content-integrity observations, not proof of closure. The safe disposition is **SOURCE_UNAVAILABLE / PARTIAL**: retain the official route and deadline, warn applicants not to pay intermediaries, record the access/integrity anomaly, and do not claim that submissions are currently accepted or that the programme is closed.

## Preserved 14-record findings

The 14 preserved evidence notes and completed report remain the source basis for the other records. Their dispositions are:

- **ASUU:** Partial; branch-specific evidence must not be generalized into a national route. Do not invent a central URL.
- **Bode Amao:** Partial; retain the official homepage but preserve the conflict between postal and email submission channels.
- **Ejiro M. Ukiri:** Partial and cycle-qualified; the 2026 cycle was closed and the exact relationship of the stored Jotform remains unresolved.
- **Florence Bamidele Makanjuola:** Partial; the provider-linked form was closed and stored 2027 dates were unsupported.
- **JG Afrika:** Actionable; the official 2027 bursary page and provider announcement supported an open cycle with no published closing date.
- **KPMG:** Missing for a future cycle; the stored provider-linked listing was stale and the latest 2026 listing was expired.
- **Lagos State Scholarship Board:** Missing; the latest confirmed 2025/2026 cycle had concluded and stored 2027 dates were unsupported.
- **Mastercard Foundation at PAU:** Partial/manual review; PAU’s cycle-specific closure information conflicted with an undated Foundation directory label.
- **Midwestern:** Partial; the documented cycle had ended and the stored 2027 date was unsupported.
- **MTN Foundation:** Partial; the official programme exists, but the stored 2027 date and complete current process were unsupported.
- **NNPC–Renaissance:** Missing for a future cycle; the 2026 scheme was closed and the stored 2027 date was unsupported.
- **NNPC/Seplat:** Partial; 2026 instructions were supported historically, but no 2027 cycle was verified.
- **Project 100 for 100:** Partial; the 2026 form/cycle was closed and no future cycle was verified.
- **PTDF:** Partial; the 2026/2027 window had ended and the stored 2027 dates were unsupported.

## Overall conclusion

The database snapshot remains stable, but the audit does not support a blind correction batch. The strongest current evidence is for a qualified Decagon separation between a Foundation tuition scholarship and a paid Institute programme, a deadline-qualified Light and Bells record, and an NDDC record that retains its official deadline while remaining source-unavailable for live submission status.

The audit remains **READY WITH CONDITIONS**, not ready for production implementation. Any write phase still requires explicit editorial decisions about Decagon’s catalogue eligibility, the meaning of `last_verified_at`, unsupported future dates, PAU’s conflicting status, ASUU’s branch-specific model, and Bode Amao’s conflicting submission channels. No production update, migration, schema change, code change, or deployment was performed; this report is being published in this authorized documentation commit.

## References

[1]: https://lightandbellshealth.com/scholarships-and-grants "Scholarships and Grants — Light and Bells Health Foundation"
[2]: https://lightandbellshealth.com/ "Light and Bells Health Foundation"
[3]: https://www.instagram.com/p/Dac4NHmlxK6/ "Light and Bells 2026 scholarship announcement"
[4]: https://www.decagonfoundation.org/apply "Decagon Foundation application page"
[5]: https://www.decagonfoundation.org/for-students "Decagon Foundation student information"
[6]: https://decagon.institute/apply "Decagon Institute application page"
[7]: https://decagon.institute/fees "Decagon Institute fees"
[8]: https://nddc.gov.ng/ "NDDC homepage"
[9]: https://nddc.gov.ng/WhatWeDo/Scholarship "NDDC Scholarships"
[10]: https://scholarship.nddc.gov.ng/login "NDDC Scholarship Portal login"
