# Scholars — Phase 1.3.1 Audit Clarification Addendum

**Date:** 2026-11-08  
**Repository:** `ImperioKDB/Updates`  
**Application scope:** `ImperioKDB/Scholars`  
**Records reconciled:** 17  
**Status:** Documentation-only editorial and conceptual specification. No production or application changes were authorized or made.

## 1. Purpose and scope

This addendum clarifies the Phase 1.3 audience, eligibility, route, lifecycle, and catalogue decisions. It does not replace the Phase 1.3 report, change any Phase 1.3 B–E outcome, or authorize a database correction. It introduces an independent editorial model so that provider authenticity, audience fit, academic-level fit, current application status, route usability, evidence freshness, and publication treatment are recorded as separate facts.

The addendum reconciles the original Phase 1.3 report, all 17 evidence notes, the source register, the Phase 1.2 production correction specification, and the Phase 1.2.1 JG Afrika addendum. Evidence dates below distinguish source-review dates from production-snapshot dates and from provider publication/programme dates. Where the supplied material does not establish a fact, the state remains unresolved.

## 2. Two weaknesses requiring clarification

### Issue A — One classification combines different dimensions

The Phase 1.3 A–E classification is useful as a conservative editorial disposition, but it is not a substitute for an operational data model. In particular, **B — Include with restrictions** does not mean that a record is currently open, that its route accepts submissions, or that it is safe to display as an ordinary actionable listing.

For example, ASUU has Nigerian undergraduate relevance only through a participating branch, and the freshly reviewed FUK call is expired. Bode Amao has Nigerian undergraduate audience fit and a reachable provider form, but its official postal and email instructions conflict and current acceptance is unconfirmed. Decagon has a current Foundation route presented as open, but its related Institute route is a separate fee-paying programme and scholarship coverage remains unresolved. These three records may be retained as restricted leads, but none is automatically an actionable/open listing.

The old A–E result must therefore be read as a **publication disposition**, not as a combined truth about authenticity, eligibility, openness, route acceptance, or evidence freshness.

### Issue B — Evidence dates are not sufficiently distinguishable

A single “verified” or “last verified” date can incorrectly imply that a current application status was verified. The reviewed material contains at least five distinct dates: production inspection, official-source check, eligibility assessment, provider publication/programme date, and freshness mode. These must not be collapsed.

The source register’s earlier “carried forward” labels also need careful interpretation: a carried-forward production value or prior finding can remain useful, but it must never be described as a fresh provider verification. Where Phase 1.3 or the supplemental 2026-11-08 checks reopened a source, that source-check date should be distinguished from the date on which the underlying provider content was published.

## 3. Revised multidimensional classification model

The following dimensions are independent. A record may be authentic but outside the Nigerian undergraduate audience; current-looking but route-unverified; audience-eligible but historical; or route-reachable but not demonstrably accepting submissions.

### 3.1 `provider_authenticity`

**Purpose:** Establish whether the named provider and opportunity are supported by a provider-controlled or authoritative institutional source. This answers “does this opportunity genuinely exist?” It does not answer whether it is current, eligible for Scholars’ audience, or open.

**Allowed states:**

- `confirmed` — provider identity and the programme are supported by an official provider or authoritative institutional source, with a programme-specific page, announcement, or provider-controlled route.
- `partially_confirmed` — provider identity is credible, but the exact programme relationship, route, or current programme instance is incomplete.
- `unresolved` — sources exist but do not establish the provider/programme relationship with sufficient confidence.
- `not_established` — only unsupported secondary claims or untraceable routes were found.

**Evidence required:** provider-domain programme page, official provider announcement, official institutional page, or provider-controlled application destination; source URL; actual check date; and a note identifying any intermediary or route limitation. A generic platform home page alone is not sufficient to establish a current programme route.

### 3.2 `audience_eligibility`

**Purpose:** Establish whether the intended beneficiaries fit the initial Scholars audience: primarily Nigerian students, with the relevant nationality, residence, university-location, indigene, gender, geographic, or host-community restrictions.

**Allowed states:**

- `confirmed_nigerian` — provider explicitly supports the relevant Nigerian audience and any material restrictions are known.
- `restricted_nigerian` — Nigerian fit exists only for a branch, state, host community, gender, course, or other explicit subset.
- `unresolved_nigerian` — Nigerian citizenship, residence, university location, or other essential audience rule is not stated or conflicts across sources.
- `non_nigerian_or_out_of_scope` — the verified audience is outside the initial Nigerian catalogue, or the opportunity is intentionally international/South Africa-specific.
- `mixed_or_not_applicable` — the programme combines audiences or academic levels and requires route-specific treatment before an audience conclusion can be made.

**Evidence required:** explicit provider wording about nationality, residence, university location, indigene status, host community, state, gender, or other restriction. Do not infer Nigerian eligibility from a Nigerian provider’s identity, a “Foreign National” form field, or a Nigerian-looking application URL.

### 3.3 `academic_level_fit`

**Purpose:** Establish whether the verified opportunity is for undergraduate students in the initial catalogue, and identify entry-level, enrolled-student, postgraduate, secondary-school, or mixed-scope constraints.

**Allowed states:**

- `undergraduate_confirmed` — provider expressly targets undergraduate/bachelor’s study and the relevant applicant stage is known.
- `undergraduate_restricted` — undergraduate fit is confirmed but limited by level, year, discipline, institution type, or entry status.
- `mixed_levels` — undergraduate and postgraduate or secondary-school routes are combined and must be separated.
- `postgraduate_only` — not eligible for the initial undergraduate catalogue.
- `secondary_or_entry_stage` — primarily secondary-school or pre-university/entry-stage, with undergraduate fit not established.
- `unresolved` — academic level or applicant stage is not sufficiently established.

**Evidence required:** provider’s stated level of study, current year/level, course/discipline, admission status, or programme route. A provider form’s available fields are supporting evidence, not permission to infer eligibility where the provider text is silent.

### 3.4 `application_status`

**Purpose:** State the current lifecycle of the exact cycle under review without turning a past or predicted date into a current cycle.

**Allowed states:**

- `open_publicly_presented` — an official source currently presents the exact cycle as open; this still does not guarantee end-to-end submission acceptance.
- `closed_or_historical` — the exact documented cycle ended, the provider marks it expired/closed, or a provider-controlled form no longer accepts responses.
- `unresolved` — the programme exists but no authoritative current cycle or acceptance state is established.
- `conflicting` — authoritative sources present materially different current states.
- `not_currently_actionable_due_scope` — current lifecycle may exist, but audience or academic scope independently prevents initial-catalogue actionability.

**Evidence required:** exact-cycle provider announcement or page, published opening/deadline/closure statement, explicit form-acceptance message, or a direct current status label. A reachable page, login screen, generic platform, or stored future date is not enough. A notification date is not a deadline.

### 3.5 `application_route_status`

**Purpose:** Establish whether the student-facing application destination is authentic, programme-specific, understandable, and demonstrably usable, while keeping route reachability separate from acceptance.

**Allowed states:**

- `provider_route_verified` — programme-specific provider route is identified and its provenance is clear.
- `provider_route_reachable_acceptance_unconfirmed` — route is reachable, but actual acceptance or submission success was not tested or established.
- `branch_or_restricted_route` — route is valid only for a named branch, institution, state, host community, or other restricted group.
- `conflicting_provider_instructions` — authoritative provider pages give materially different submission channels or requirements.
- `closed_provider_route` — provider-controlled form or route explicitly indicates closure/no longer accepting responses.
- `generic_or_non_programme_route` — destination is a platform root or generic page rather than the exact programme route.
- `source_unavailable_or_integrity_unresolved` — access challenge, unexpected content, or protected surface prevents safe route assessment.
- `paid_route_distinct` — route is a fee-paying programme and must not be represented as the scholarship route.
- `no_current_route_verified` — no current programme-specific route was established.

**Evidence required:** exact URL, route provenance, page/form content, check date, and an explicit statement about whether acceptance was tested. Never submit an application, bypass CAPTCHA, or infer acceptance from HTTP reachability.

### 3.6 `evidence_freshness`

**Purpose:** Describe when and how the evidence was checked, without claiming that a production inspection or historical source review verified current application status.

**Allowed states:**

- `fresh_provider_recheck_2026_11_07` — official/provider source reopened on 2026-11-07 for the relevant Phase 1.3 decision.
- `fresh_phase_1_1_recheck_reconciled_2026_11_08` — source freshly checked in Phase 1.1 and reconciled in the 2026-11-08 continuation.
- `supplemental_provider_recheck_2026_11_08` — official/provider source reopened directly on 2026-11-08 after the initial Phase 1.3 pass.
- `carried_forward` — finding or stored value came from a prior report and was not independently reopened for the relevant claim during the stated review.
- `mixed_freshness` — different claims within the record have different check modes and dates.

**Evidence required:** source URL, actual source-check date, scope of the check, and an explicit carried-forward/fresh label. “Checked” must not be used without saying what was checked. The production snapshot date and source-review date must remain separate.

### 3.7 `publication_disposition`

**Purpose:** State what Scholars may publish, independently of whether the provider is authentic or the audience is potentially eligible.

**Allowed states:**

- `restricted_lead_not_actionable` — may be retained as a clearly restricted lead, but not presented as an ordinary open/actionable listing.
- `actionable_open_candidate` — all minimum publication gates appear satisfied; none of the 17 records reaches this state on the evidence reviewed here.
- `manual_review_withhold` — withhold from actionable listings until a named ambiguity is resolved.
- `exclude_initial_nigerian_undergraduate_catalogue` — outside or unresolved for the initial audience/academic scope.
- `historical_archive_only` — preserve as dated historical evidence; do not present as current.

**Evidence required:** all seven dimensions, exact cycle, current route, audience/academic fit, status, freshness, and unresolved questions must be recorded. A–E is not a replacement for these fields.

## 4. Evidence-date and freshness model

Every record should distinguish the following date concepts:

1. **`production_snapshot_at`** — timestamp when the Scholars production row and stored fields were read. The Phase 1.2 specification records the 17-record read-only snapshot at **2026-11-07 16:56:34+00**. This proves what was stored then; it does not prove that an external source was current then.
2. **`official_source_checked_at`** — date, and time where available, when a named official/provider source was opened and read. Examples are 2026-11-07 for the Phase 1.3 workflow checks and 2026-11-08 for the supplemental checks.
3. **`audience_assessed_at`** — date when nationality, residence, university location, state/indigene, host-community, gender, or other audience fit was assessed. It may equal the source-check date but must remain conceptually separate because audience rules can be assessed from one source while route status comes from another.
4. **`application_status_assessed_at`** — date when the exact cycle’s open/closed/conflicting/unresolved state was assessed. Reviewing a historical eligibility page is not a current-status assessment.
5. **`evidence_published_at`** — date the provider source or announcement was published, if the source supplies one. If unavailable, record `unavailable`; never infer it from URL paths, access dates, relative labels, or stored year-shifted dates.
6. **`programme_cycle_dates`** — dates stated by the provider for the cycle, such as an opening date, deadline, or notification date. These are programme facts, not page publication dates. A notification/non-selection date must not be stored or displayed as a deadline.
7. **`last_verified_at` interpretation** — until the product model is changed, this field must not be treated as a universal current-actionability proof. An editorial source review can be fresh while submission acceptance remains unconfirmed, a cycle is closed, or audience eligibility is unresolved.
8. **`freshness_mode`** — one of the states in Section 3.6. A carried-forward claim must remain labelled carried forward even if the report was edited on a later date. A supplemental recheck may refresh only the claims actually reopened.

**Minimum recording rule:** every source-backed claim should have a source URL, source role, source publication date or `unavailable`, source checked date, claim type, and freshness mode. Do not overwrite a prior source date with the later editorial reconciliation date.

## 5. Revised 17-record decision matrix

The original Phase 1.3 A–E outcomes are retained in the final column for traceability. The new dimensions below are the controlling editorial facts for future publication decisions. “Evidence basis” identifies the specific evidence supporting the row; it is not a claim that every route was tested end-to-end.

| # / record and UUID | Provider authenticity; intended audience | Academic-level fit; audience state | Current application status; route status | Evidence freshness | Publication disposition | Evidence basis and outstanding questions |
|---|---|---|---|---|---|---|
| 1. ASUU Scholarship Scheme for Indigent Students  
`31cfebd0-100f-4b06-9250-52af820d74d4` | `confirmed`; Nigerian students only through a participating university/ASUU branch. | `undergraduate_restricted`; `restricted_nigerian` because branch participation and local rules control. | `unresolved` nationally; FUK’s reviewed call was closed. `branch_or_restricted_route`; no central national route. | `fresh_provider_recheck_2026_11_07`; FUK branch evidence was reopened. | `restricted_lead_not_actionable`; retain only with a branch warning, not as a national open listing. | Official ASUU sources plus the FUK 2026 call support branch activity, indigence, registration, and FUK requirements. Outstanding: participating branch, current call, national-vs-branch catalogue model, and any current deadline. Original A–E: **B**. |
| 2. Bode Amao Foundation Scholarship  
`215ee2c9-28de-4609-b0b7-6898ae513a21` | `confirmed`; registered Nigerian students in Nigerian universities, with indigence and current registration. | `undergraduate_restricted` (at least 200 level); `confirmed_nigerian` subject to the published conditions. | `unresolved`; official pages do not establish current acceptance. `conflicting_provider_instructions`; provider page says email while homepage says post. | `fresh_provider_recheck_2026_11_07`; the official homepage, form page, PDF, and third-party lead were reviewed, with the third-party source kept secondary. | `restricted_lead_not_actionable`; show only with unresolved-status and conflicting-route warnings. | Official BAF homepage/form/PDF establish audience and route conflict; no official current deadline, numeric CGPA, award amount, or authoritative submission channel. Original A–E: **B**. |
| 3. Decagon Undergraduate Honors Program  
`769b1169-71af-4f55-9be4-63374a59faa8` | `confirmed`; Foundation route targets Nigerian citizens residing in Nigeria and Nigerian university entry. Institute route is a separate paid offering. | `undergraduate_restricted`; Foundation is entry-stage/offer-based; already-enrolled eligibility needs care. `confirmed_nigerian` for the Foundation route. | `open_publicly_presented` for the Foundation and Institute pages, but current acceptance and funding coverage require qualification. `provider_route_verified` for scholarship route; `paid_route_distinct` for Institute route. | `fresh_phase_1_1_recheck_reconciled_2026_11_08`. | `restricted_lead_not_actionable`; publish only the Foundation route, separate the paid Institute route, and do not call the combined record fully funded. | Official Foundation pages/forms support Nigerian audience, UTME 250+, financial need, rolling review, and tuition-paid-to-institution language; Institute fees page states ₦275,000 annually plus university tuition/school fees. Outstanding: scholarship fee waiver, tuition-only versus living coverage, partner universities, route relationship, and current close date. Original A–E: **B**. |
| 4. Ejiro M. Ukiri International Scholarship Fund  
`4c469077-cd38-424c-8913-463c7068d304` | `confirmed`; Nigerian students/residents are within the documented 2026 audience, but wording emphasizes SS3/entry stage. | `mixed_levels` / `secondary_or_entry_stage`; university, college, polytechnic, and entry-stage wording is not a clean enrolled-undergraduate rule. | `closed_or_historical`; 2026 cycle ended 30 September and the Jotform was closed. `closed_provider_route` for the stored form; provider `/apply` linkage remains unresolved. | `fresh_provider_recheck_2026_11_07`. | `historical_archive_only`. | Official provider pages and 2026 announcements support Nigerian audience and dates; exact current form relationship and 2027 rules are unresolved. Original A–E: **E**. |
| 5. Florence Bamidele Makanjuola Scholarship  
`aaaaaaaa-0000-4000-8000-000000000023` | `confirmed`; female Nigerian citizens attending/intending public or federal-government-owned schools/universities. | `mixed_levels`; undergraduate fit is restricted to specified fields (Teaching, Science, Technology, Engineering, Mathematics, Nursing) and entry/study conditions. | `closed_or_historical`; 2026 window ended 22 May and the exact Google Form no longer accepted responses. `closed_provider_route`. | `fresh_provider_recheck_2026_11_07`. | `historical_archive_only`. | Opekete official page, homepage, and provider-created form establish audience, fields, amount ceilings, and closure. Outstanding: next cycle and refreshed route. Original A–E: **E**. |
| 6. JG Afrika Bursary 2027  
`64790f70-f20a-4c9c-a1f4-2efabc087dcb` | `confirmed`; Nigerian citizenship and university location are `unresolved_nigerian`. The provider does not establish that Nigerians or Nigerian-university students may apply. | `mixed_levels`; BSc/BEng and MSc/MEng Civil Engineering are listed. | `open_publicly_presented`; no deadline published. `provider_route_reachable_acceptance_unconfirmed`; official inline form and CAPTCHA were not submitted/tested. | `fresh_provider_recheck_2026_11_07`, with Phase 1.2.1 controlling the eligibility caution. | `exclude_initial_nigerian_undergraduate_catalogue`; do not publish as a Nigerian-undergraduate listing. | Official JG Afrika page and LinkedIn announcement support authenticity, open presentation, qualifications, and 1 January 2027 notification date. Outstanding: citizenship, university location, transcript rule for matric entrants, and end-to-end acceptance. Original A–E: **C**. |
| 7. KPMG Seyi Bickersteth Scholarship Programme  
`cccccccc-0000-4000-8000-000000000016` | `confirmed`; indigent Nigerian students admitted to Federal Universities. | `undergraduate_restricted`; 100 level and six named business/finance-related disciplines. | `closed_or_historical`; 2026 listing is expired. `closed_provider_route`; stored route is an older 2025 listing and no 2027 route was found. | `supplemental_provider_recheck_2026_11_08`. | `historical_archive_only`. | Official 2026 SeamlessHR listing supports audience and requirements and is marked expired. Outstanding: whether and when a 2027 cycle will exist. Original A–E: **E**. |
| 8. Lagos State Scholarship Board Bursary/Scholarship Awards  
`d9c8ed08-35be-4fe8-aa9d-221909c39947` | `confirmed`; Lagos State indigenes in higher education, not a general Nigerian audience. | `mixed_levels`; Board lists undergraduate, master’s, PhD, and other categories. | `unresolved`; official site is under maintenance and visible announcements are historical. `source_unavailable_or_integrity_unresolved` / login-only portal. | `supplemental_provider_recheck_2026_11_08`. | `manual_review_withhold`. | Official homepage supports Board identity and Lagos-indigene scope; portal only exposes a credentialed login and no current open cycle. Outstanding: current notice, exact undergraduate route, current requirements, and cycle status. Original A–E: **D**. |
| 9. Light and Bells Health Foundation Scholarship 2026  
`e93e25b7-46a5-4254-b1c5-91ad56a3abf0` | `confirmed`; provider’s 2026 audience is not fully resolved as Nigerian, so `unresolved_nigerian` for the initial catalogue. | `mixed_levels` / health-field restricted; medicine, nursing, and allied-health categories. | `closed_or_historical`; published deadline was 2 October 2026. `no_current_route_verified` after the cycle. | `fresh_phase_1_1_recheck_reconciled_2026_11_08`. | `historical_archive_only`. | Official scholarship page and 2026 announcement support categories and deadline; complete stored checklist and Nigerian audience remain unresolved. Original A–E: **E**. |
| 10. Mastercard Foundation Scholars Program at Pan-Atlantic University  
`aaaaaaaa-0000-4000-8000-000000000021` | `confirmed`; Nigerian audience and financial-need/priority groups are supported. | `mixed_levels` in the Foundation directory, while PAU’s scholarship page is an undergraduate admissions route; undergraduate fit is relevant but must be kept route-specific. | `conflicting`; PAU says 2026/27 applications are closed while Foundation directory says “Admissions Open.” `conflicting_provider_instructions/status`; no safe current CTA. | `supplemental_provider_recheck_2026_11_08`. | `manual_review_withhold`. | PAU official page supports UTME 220, O-Level, financial need, and closed 2026/27 cycle; Foundation directory supplies conflicting open label. Outstanding: which source governs the exact cycle and current route. Original A–E: **D**. |
| 11. Midwestern Oil & Gas Host Community Scholarship  
`cccccccc-0000-4000-8000-000000000015` | `confirmed`; Nigerian students restricted to host communities or Delta State depending on category. | `undergraduate_restricted`; University Community Award covers 100/200 level host-community students; Merit Award covers 200 level Delta indigenes. | `conflicting`; page title says 2026/27 while body/route state 2025/26 and deadline 19 April 2026. `conflicting_provider_instructions/status`; generic platform must not be used as a current CTA. | `supplemental_provider_recheck_2026_11_08`. | `manual_review_withhold`. | Official Midwestern announcement and Dragnet route support audience restrictions and category requirements, but the cycle contradiction prevents safe status. Outstanding: intended cycle, current deadline, and live route. Original A–E: **D**. |
| 12. MTN Foundation Science and Technology Scholarship  
`aaaaaaaa-0000-4000-8000-000000000001` | `confirmed`; Nigerian public-tertiary audience, with STEM, blind-student, and UTME categories. | `mixed_levels` / category-specific; the record is broader than a single undergraduate STEM route. | `unresolved`; official programme page confirms annual programme and 2026 expansion but no current application window. `no_current_route_verified`. | `supplemental_provider_recheck_2026_11_08`. | `manual_review_withhold`. | Official MTN Foundation page supports Nigerian public-tertiary categories and 2026 scholarship expansion, but no exact current undergraduate/STEM route or deadline. Original A–E: **D**. |
| 13. NDDC Local Post-Graduate Master’s Degree Scholarship 2026/2027  
`107bccf4-a01e-4ac6-b4bc-beaa482e403e` | `confirmed`; Niger Delta indigenes. | `postgraduate_only`; master’s scholarship and therefore outside the initial undergraduate catalogue. | `unresolved`; call is deadline-dated 8 November 2026 but live acceptance is unconfirmed. `source_unavailable_or_integrity_unresolved`; portal login/403/content anomalies prevent safe submission conclusion. | `fresh_phase_1_1_recheck_reconciled_2026_11_08`. | `exclude_initial_nigerian_undergraduate_catalogue`. | Official NDDC call supports postgraduate scope, Niger Delta audience, free application, and deadline; portal integrity/submission remains unresolved. Original A–E: **C**. |
| 14. NNPC–Renaissance/TotalEnergies AENR JV University Scholarship  
`aaaaaaaa-0000-4000-8000-000000000006` | `confirmed`; nationwide Nigerian category plus Bayelsa/Delta/Imo/Rivers operational-area category. | `undergraduate_restricted`; full-time 200-level Nigerian university students under the published 2026 criteria. | `closed_or_historical` for the evidenced 2026 listing, while the official education page does not expose a new route/date. `generic_or_non_programme_route`; stored Scholastica root is not programme-specific. | `supplemental_provider_recheck_2026_11_08`. | `manual_review_withhold`; no current CTA and no unsupported future date. | Renaissance official education page supports Nigerian undergraduate criteria; programme-specific 2026 listing is historical/closed. Outstanding: new cycle and route. Original A–E: **D**. |
| 15. NNPC/Seplat JV National Undergraduate Scholarship  
`aaaaaaaa-0000-4000-8000-000000000004` | `confirmed`; Nigerian students in Federal and State Universities. | `undergraduate_restricted`; second year or above, CGPA 3.5+, specified disciplines. | `closed_or_historical`; 2026 window ended 13 March. `provider_route_reachable_acceptance_unconfirmed` for the minimal provider-linked page; no 2027 cycle. | `supplemental_provider_recheck_2026_11_08`. | `historical_archive_only`. | Seplat official announcement supports audience, requirements, free application, and 2026 window; provider-linked page does not establish 2027 acceptance. Original A–E: **E**. |
| 16. Project 100 for 100 STEM Scholarship  
`7eae077d-8290-4c07-abe5-95d993a554fe` | `confirmed`; female Nigerian undergraduates in public tertiary institutions. | `undergraduate_restricted`; STEM, 2:2/equivalent, public institution. | `closed_or_historical` despite a live-looking page label; dated application window ended 25 September and disbursement timeline ended 6 November. `closed_provider_route` / conflicting live label. | `supplemental_provider_recheck_2026_11_08`. | `historical_archive_only`. | Afro-Tech Girls announcement and linked landing page support audience, award, deadline, and ended timeline. Outstanding: future cycle. Original A–E: **E**. |
| 17. PTDF In-Country Undergraduate Scholarship Scheme  
`aaaaaaaa-0000-4000-8000-000000000012` | `confirmed`; qualified Nigerians in Nigerian public universities. | `undergraduate_restricted`; full-time 200 level, sponsored oil/gas/energy/management courses, CGPA and document requirements. | `closed_or_historical`; 2026/27 window ended 5 June. `no_current_route_verified` for a future cycle; official portal retained as a historical source. | `supplemental_provider_recheck_2026_11_08`. | `historical_archive_only`. | PTDF official guidelines support audience, level, course, documents, and 2026/27 window. Stored 2027 dates are unsupported; no future cycle published. Original A–E: **E**. |

### Matrix interpretation

The three original B records are not actionable by default. ASUU is branch-specific and its reviewed call is closed; Bode Amao has unresolved current status and conflicting official routes; Decagon is the strongest current candidate but must be split into a Foundation scholarship route and a separate paid Institute route, with coverage and fee questions unresolved. No record reaches `actionable_open_candidate` in this addendum.

## 6. Revised publication eligibility rules

### Initial Nigerian undergraduate catalogue rule

A record may receive an **actionable/open presentation** only when all of the following are independently satisfied:

1. **Authenticity:** the exact opportunity is supported by a provider or authoritative institutional source.
2. **Audience:** Nigerian nationality/residence/location and any state, branch, host-community, gender, or other restrictions are explicit and satisfied by the listing’s scope.
3. **Academic level:** undergraduate fit and the relevant applicant stage are explicit; postgraduate and secondary-school routes are separated.
4. **Current cycle:** the exact cycle is currently presented as open or its current acceptance state is otherwise established. Historical deadlines and shifted stored dates do not qualify.
5. **Route:** a programme-specific provider route is identified, its provenance is clear, and no material route conflict remains. Reachability alone is insufficient.
6. **Evidence:** official-source check date, audience assessment date, application-status assessment date, publication/programme dates, and freshness mode are recorded separately.
7. **Editorial safety:** unresolved claims, access anomalies, funding ambiguity, paid-programme risk, and route limitations are visible; no unsupported deadline, “verified” claim, or funding promise is displayed.

If any gate fails, the record must not receive an actionable/open presentation. The appropriate outcome is restricted lead, manual review, exclusion from the initial catalogue, or historical archive, depending on the independent dimensions.

### Additional catalogue rules

- An authentic provider is not automatically audience-eligible.
- Audience eligibility and academic-level fit are separate decisions.
- A currently open-looking page is not actionable if route acceptance or exact-cycle identity is unresolved.
- A reachable URL, login screen, or generic platform page is not proof that submissions are accepted.
- An inaccessible URL or HTTP 403 challenge is not proof that a programme is closed.
- Historical opportunities must retain cycle labels and must not be year-shifted into future dates.
- Unresolved records are withheld from actionable listings and routed to manual review.
- Paid training or direct-pay programmes must not be represented as scholarships or silently merged with scholarship routes.
- Branch, state, host-community, gender, course, and level restrictions must appear in the listing title or warning, not only in internal notes.
- `verified = true` or `last_verified_at` must not by itself produce an open/actionable badge.
- Selection, notification, and disbursement dates must not be presented as application deadlines.

## 7. Outstanding provider clarifications

The following questions remain open and are not answered by this addendum:

1. **ASUU:** Is Scholars keeping a national ASUU record or separate branch records? Which branches have current calls, and can a FUK route be shown only to FUK students?
2. **Bode Amao:** Which official submission channel is authoritative—postal or email? Is the stored 31 December 2026 date provider-approved? Are the PDF requirements and award amount current?
3. **Decagon:** Does the Foundation scholarship cover tuition only or also accommodation/living support? Must scholarship recipients pay the Institute’s ₦275,000 annual fee? Are Foundation and Institute forms separate selection routes? Which partner universities and closing rules are current?
4. **Ejiro:** Will a future cycle accept currently enrolled undergraduates, and which route is canonical after the closed Jotform?
5. **Florence:** When will the next cycle open, and will the current female/Nigerian/public-institution/field rules continue?
6. **JG Afrika:** Are Nigerian citizens eligible? Must applicants attend a South African university? Does the full-transcript requirement apply to all applicants including Matric entrants? Is the form accepted end-to-end?
7. **KPMG:** Will a 2027 cycle exist, and what will its official route and dates be?
8. **Lagos State:** What is the current undergraduate notice, eligibility, route, and cycle status while the site is under maintenance?
9. **Light and Bells:** Does the next cycle include Nigerian applicants and currently enrolled undergraduates, and what is the canonical route?
10. **PAU/Mastercard Foundation:** Which source governs the 2026/27 status, and is the Foundation directory label current for the PAU route?
11. **Midwestern:** Is the intended cycle 2025/26 or 2026/27, and what is the current deadline and active programme-specific route?
12. **MTN:** What is the current undergraduate/STEM call, exact route, level requirement, and deadline for the record?
13. **NDDC:** Is the portal an uncompromised intended service, and can new applicants submit before the stated deadline? This requires provider confirmation; 403/access anomalies must not be interpreted as closure.
14. **NNPC–Renaissance:** When will the next programme-specific route and cycle be published, and does the nationwide category remain unchanged?
15. **NNPC/Seplat:** Will a 2027 cycle run, and what are its authoritative dates and route?
16. **Project 100 for 100:** Will a next cycle be announced, and should the landing page be corrected before any future listing?
17. **PTDF:** When is the next in-country undergraduate call, and what are its official dates and current route?

## 8. Implications for Phase 2

Phase 2 should implement the evidence model conceptually before considering database fields. At minimum, the future model should support an opportunity/cycle distinction, source records with source role and publication date, separate source-review and application-status timestamps, audience and academic-level constraints, route provenance and route-status state, freshness mode, historical-cycle data, uncertainty/manual-review state, and paid-programme taxonomy.

Phase 2 should also define the frontend policy for each publication disposition: actionable/open, restricted lead, manual review/withheld, excluded from initial catalogue, and historical archive. It should specify how lifecycle fields affect public queries and reminders, and it should prevent a single `verified` flag from generating current-actionability claims.

No Phase 2 implementation should begin from the original B labels alone. The revised matrix must be treated as the editorial input, with same-day source rechecks required for any later production write. Decagon, ASUU, Bode Amao, PAU, NDDC, JG Afrika, and all records with unsupported future dates require explicit decisions or provider evidence before implementation.

## 9. Production-safety statement

This addendum is read-only with respect to Scholars production. No Scholars application repository, code, Supabase table, record, RLS policy, function, migration, storage bucket, configuration, verification status, deadline, application URL, instruction, deployment, or production data was changed. No application was submitted, no provider was contacted, and no CAPTCHA or protected workflow was bypassed.

The only artifact created by this phase is this documentation addendum, with a narrowly scoped source-register freshness correction if published alongside it. The addendum is ready to serve as the **authoritative editorial input for Phase 2 planning**, but it is **not implementation authorization** and does not authorize any production write.
