# NDDC Local Post-Graduate (Master’s Degree) Scholarship 2026/2027 — revalidation evidence

**Audit/access date:** 2026-11-07
**Record slug:** `nddc-local-post-graduate-master-s-degree-scholarship-2026-2027-107bccf4`
**Scope:** Public scholarship information only; no access controls were bypassed and no production data was changed.

## Findings

The programme and current call are officially evidenced. NDDC’s official Facebook announcement invites suitably qualified Niger Delta indigenes to apply for the 2026/2027 Local Post-Graduate (Master’s Degree) Scholarship Programme. It directs applicants to `https://scholarship.nddc.gov.ng/login`, states that the application is free, and gives an application deadline of 8 November 2026.

The stored URL is therefore provider-linked and correct as the official application route. However, the portal could not be substantively read in this review: the prior audit recorded HTTP 403 for the stored `/login` route, and the current public fetch of the portal root returned only an ellipsis. This is an accessibility/transport observation, not proof that the programme is closed or that the portal is permanently broken. The official call itself supports a live/current application opportunity as of the announcement, but the actual form’s availability and full requirements remain SOURCE_UNAVAILABLE from the accessible review.

NDDC’s official announcements index also contains a prior 2025/2026 local master’s scholarship notice, confirming that NDDC publishes this type of programme through its official channels, but that older notice is not used to infer 2026/2027 requirements. A public comment on the 2026/2027 official announcement reports a possible discrepancy between advertised fields and portal fields; this is an applicant report, not an independently verified portal defect.

**Instructions classification:** SOURCE_UNAVAILABLE/PARTIAL. The official call supports the programme name, target population, deadline, free-application warning, and official route. It does not expose the full current eligibility, document, or workflow instructions in the accessible sources reviewed.

## Record values supplied for comparison

- **URL:** `https://scholarship.nddc.gov.ng/login`
- **Instructions:** stored text directs applicants to the official NDDC portal before 8 November 2026
- **Deadline:** `2026-11-08`
- **Opens at:** `NULL`
- **Last cycle closed at:** `NULL`
- **Last verified at:** `2026-10-13 09:54:32.204285+00`

## Proposals — editorial only; no production changes made

- **Instructions:** “NDDC’s official 2026/2027 call invites qualified Niger Delta indigenes to apply for the Local Post-Graduate (Master’s Degree) Scholarship. Applications are free and the published deadline is 8 November 2026. Use only the official NDDC application portal at `https://scholarship.nddc.gov.ng/login`; do not pay an intermediary. Full eligibility and document requirements could not be verified because the portal was inaccessible in this review. Recheck the official portal and NDDC announcement before relying on any additional requirements.”
- **URL:** Retain the stored official portal URL; no replacement is proposed. Record the accessibility issue separately from URL provenance.
- **Deadline/lifecycle:** Retain 2026-11-08 as the official published deadline. Do not add a closure timestamp or claim the portal was open/closed based solely on HTTP 403 or an empty fetch.
- **Verification date:** Because the official call was read on 2026-11-07 but the portal’s substantive state could not be confirmed, set the source-review date to 2026-11-07 with a `SOURCE_UNAVAILABLE` qualification rather than treating it as an unqualified portal verification.
- **Priority:** P1 time-sensitive accessibility and instruction gap; P2 source/provenance recording. No P0 URL replacement is supported because the official NDDC announcement points to the stored route.

## Sources

1. **NDDC 2026/2027 Local Post-Graduate Scholarship: Call for Applications**, official NDDC Facebook page, https://www.facebook.com/OfficialNDDC/posts/nddc-20262027-local-post-graduate-scholarship-call-for-applicationsthe-niger-del/1509046547707715/. Accessed 2026-11-07. Supports the programme, eligible-population description, official portal route, free-application statement, and 8 November 2026 deadline.
2. **NDDC Scholarship Portal**, https://scholarship.nddc.gov.ng/. Accessed 2026-11-07. The public fetch returned no substantive text; the prior audit observed HTTP 403 on `/login`. Supports only the transport/accessibility observation, not programme status.
3. **Scholarships — NDDC**, official NDDC page, https://www.nddc.gov.ng/WhatWeDo/Scholarship. Accessed 2026-11-07. Confirms NDDC’s official scholarship section and provider identity, but the extracted page did not expose the 2026/2027 call details.

## Unresolved

- Whether the portal accepted applications at the exact audit time and whether the 403 was caused by access control, rate limiting, or another temporary condition.
- The complete 2026/2027 eligibility, approved-discipline, document, and application-step requirements.
- Whether the portal’s advertised fields matched the official call; this was raised in a public comment but not independently verified.
- The exact cycle closure event after the 8 November deadline.
