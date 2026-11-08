# Scholars Phase 1.3.1 — New-Session Handoff Report

**Handoff date:** 2026-11-08  
**Project:** Scholars (`V5pnVoSpnd3QzVBcpvJNZW`)  
**Application repository:** `ImperioKDB/Scholars`  
**Reporting repository:** `ImperioKDB/Updates`  
**Current remote commit:** [`2f90abf`](https://github.com/ImperioKDB/Updates/commit/2f90abfac0c06cfe512ab91d96fb86a3c5ca427e)  
**Current branch state:** `origin/main` at `2f90abf`; working tree was clean after publication.

## 1. Exact stopping point

Phase 1.3.1 is complete. The work stopped after publishing:

- The Phase 1.3 audience/eligibility/catalogue-scope audit for all 17 records.
- The companion evidence bundle containing 17 individual evidence notes and a source register.
- The Phase 1.3.1 clarification addendum separating the former combined A–E classification from seven independent editorial dimensions.
- The source-register freshness correction distinguishing production inspection, official-source checks, audience/status assessment, provider publication dates, and carried-forward evidence.

No Phase 2 implementation has started.

## 2. Published deliverables

1. [Phase 1.3.1 audit clarification addendum](../SCHOLARS_PHASE_1_3_1_AUDIT_CLARIFICATION_ADDENDUM_2026-11-08.md)
2. [Phase 1.3 audience/eligibility/catalogue audit](../SCHOLARS_PHASE_1_3_AUDIENCE_ELIGIBILITY_AND_CATALOGUE_SCOPE_AUDIT_2026-11-07.md)
3. [Phase 1.3 evidence bundle and source register](../SCHOLARS_PHASE_1_3_AUDIENCE_ELIGIBILITY_EVIDENCE_2026-11-07/)
4. [Phase 1.2.1 JG Afrika eligibility addendum](../SCHOLARS_PHASE_1_2_1_JG_AFRIKA_ELIGIBILITY_ADDENDUM_2026-11-07.md)
5. [Phase 1.2 production correction specification](../SCHOLARS_PHASE_1_2_PRODUCTION_CORRECTION_SPECIFICATION_2026-11-07.md)

The complete continuation package is in `SCHOLARS_PHASE_1_3_1_HANDOFF_EXPORT_2026-11-08/` and is also available as the accompanying `.tar.gz` archive with a SHA-256 file.

## 3. Current editorial outcome

The original Phase 1.3 A–E dispositions remain unchanged:

- **A = 0** — no unrestricted, current, Nigerian-undergraduate opportunity was established.
- **B = 3** — ASUU, Bode Amao, and Decagon Foundation, all restricted and not automatically actionable.
- **C = 2** — JG Afrika and NDDC are excluded from the initial Nigerian undergraduate catalogue for audience/academic-scope reasons.
- **D = 5** — Lagos State Scholarship Board, PAU Mastercard Foundation, Midwestern, MTN Foundation, and NNPC–Renaissance require manual review.
- **E = 7** — KPMG, Ejiro, Florence, Light and Bells, NNPC/Seplat, Project 100 for 100, and PTDF are historical/closed in the reviewed cycles.

The clarification addendum defines these independent dimensions:

1. `provider_authenticity`
2. `audience_eligibility`
3. `academic_level_fit`
4. `application_status`
5. `application_route_status`
6. `evidence_freshness`
7. `publication_disposition`

No record currently reaches `actionable_open_candidate` under the revised model.

## 4. Important decisions preserved

- **ASUU:** FUK evidence is branch-specific. Do not present it as a national ASUU route or as currently open.
- **Bode Amao:** Nigerian undergraduate fit is supported, but official postal and email submission instructions conflict and current acceptance is unresolved.
- **Decagon:** Keep the Foundation scholarship route separate from the fee-paying Decagon Institute route. The Institute fee is ₦275,000 annually plus university tuition/school-related fees; scholarship coverage and fee-waiver treatment are unresolved.
- **JG Afrika:** Authentic and publicly presented as open, but Nigerian citizenship and university-location eligibility remain unresolved. Do not publish it as a Nigerian-undergraduate listing.
- **NDDC:** Postgraduate only; keep outside the undergraduate catalogue. Portal 403/access anomalies are not proof of closure or submission success.
- **PAU Mastercard Foundation:** PAU says the 2026/27 cycle is closed while the external Foundation directory says “Admissions Open”; preserve the conflict.
- **Historical cycles:** Never shift prior dates into future years. Reachable pages, login screens, generic platforms, and stored future dates do not prove current acceptance.

## 5. Date model now adopted

The source register and addendum distinguish:

- **Production snapshot:** `2026-11-07 16:56:34+00` — what was stored in production at the read-only inspection.
- **Official-source checked date:** when the provider/authoritative source was actually opened and read.
- **Audience assessment date:** when nationality, residence, location, state, branch, host-community, gender, or other audience fit was assessed.
- **Application-status assessment date:** when open/closed/conflicting/unresolved status was assessed.
- **Provider publication/programme date:** date shown by the provider, or `unavailable`; never inferred from URL paths or access dates.
- **Freshness mode:** fresh, supplemental, mixed, or carried forward.

Do not interpret `verified = true` or `last_verified_at` as universal proof of current actionability.

## 6. Remaining unresolved questions

The detailed list is in the addendum, Section 7. The highest-priority clarifications are:

1. Decagon scholarship coverage, Institute fee relationship, partner universities, route relationship, and current closing rules.
2. ASUU national-record versus branch-record catalogue policy.
3. Bode Amao’s authoritative submission channel and current-cycle date.
4. PAU’s conflicting cycle-status sources.
5. JG Afrika citizenship and university-location eligibility.
6. NDDC portal integrity and submission acceptance.
7. Unsupported future dates and lifecycle behavior across all affected production records.

## 7. Recommended next action

The next session should begin with **Phase 2 editorial/data-model planning**, not a production correction. Use the Phase 1.3.1 addendum as the authoritative input. Define the conceptual cycle/source/status model, publication gates, manual-review behavior, historical archive behavior, paid-programme taxonomy, and timestamp semantics before deciding whether any schema or application work is authorized.

Any later production write requires:

- explicit founder/editorial approval;
- same-day provider-source recheck for the exact record and cycle;
- exact field/value approval;
- a read-only before snapshot;
- post-write validation of the exact UUID and excluded fields;
- application/build/deployment review if code is involved.

## 8. Safety state

This handoff is documentation-only. No Scholars application code, Supabase table, record, RLS policy, function, migration, storage bucket, configuration, deadline, application URL, instruction, verification status, deployment, or production data was changed. No application was submitted, no provider was contacted, and no CAPTCHA/protected workflow was bypassed.

A new session can continue from this report and the packaged source documents without relying on prior chat history.

## 9. Export integrity

- **Export directory:** `SCHOLARS_PHASE_1_3_1_HANDOFF_EXPORT_2026-11-08/`
- **Archive:** `SCHOLARS_PHASE_1_3_1_HANDOFF_EXPORT_2026-11-08.tar.gz`
- **Archive SHA-256:** `999e47613c185ca26e0020905f6f5d821ebfcbb3e3996415ef391f12c46f4bfd`
- **Archive members:** 38
- **Files in export directory:** 34, including 17 numbered Phase 1.3 evidence notes
- **Internal manifest:** `SCHOLARS_PHASE_1_3_1_HANDOFF_EXPORT_2026-11-08/SHA256SUMS.txt`

The archive was created from the exported directory and verified with `sha256sum -c` before publication.
