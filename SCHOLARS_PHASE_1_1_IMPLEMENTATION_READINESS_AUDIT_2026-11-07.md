# Scholars — Phase 1.1 Implementation-Readiness and Data Reconciliation Audit

**Audit date:** 7 November 2026  
**Application repository:** `ImperioKDB/Scholars`  
**Reporting repository:** `ImperioKDB/Updates`  
**Production domain:** https://www.scholars.com.ng  
**Input revalidation report:** `SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_2026-11-07.md`  
**Input revalidation commit:** [`187621218ae89cfdb6b952d3edcf821715100776`](https://github.com/ImperioKDB/Updates/commit/187621218ae89cfdb6b952d3edcf821715100776)

## 1. Executive summary

This is a read-only implementation-readiness audit. It reconciles the 17 Phase 1 target records against the live Scholars production database, inspects the current schema and frontend lifecycle logic, and tests the two highest-risk cases: Decagon and NDDC. No production data, code, schema, configuration, account, or deployment was changed.

The live inventory matches the previous snapshot: 95 scholarship rows, 44 verified rows, 44 verified rows with usable slugs, 11 verified rows missing `how_to_apply`, 15 verified rows missing `last_verified_at`, four verified rows missing deadlines, 17 verified rows with past deadlines, and four verified rows with a future deadline plus a historical close marker. All 17 target UUIDs were retrieved directly from production.

The audit does **not** authorize a broad correction batch. Decagon is a paid Honours Programme: the official fees page says participants pay ₦275,000 per year plus university tuition and school-related fees. No official scholarship award or fee-waiver component was found. Its record must be held for editorial classification rather than simply receiving a corrected application URL. NDDC’s official announcement supports the programme, official portal, free application, and 8 November 2026 deadline, but the portal returned a Cloudflare `403` challenge and exposed no public login or application form content to an unauthenticated read. That is not proof of closure or acceptance.

A small batch is technically possible only after explicit editorial approval: source-backed `research_notes` and selected `last_verified_at` values can be written through the existing admin route, and Decagon’s URL can be corrected only if the programme is intentionally retained as a Scholars listing. The safest overall decision is **READY WITH CONDITIONS**, not READY FOR LIMITED IMPLEMENTATION.

## 2. Fresh production inventory and reproducible query evidence

### Query execution

The live read-only query ran against Supabase project `cmdglabohpttgfofcmqc`, the production project named `scholarship-platform`. The database returned `2026-11-07 15:11:23.338793+00` as `queried_at`.

The inventory query was:

```sql
WITH inventory AS (
  SELECT
    now() AS queried_at,
    count(*)::int AS total_rows,
    count(*) FILTER (WHERE verified)::int AS verified_rows,
    count(*) FILTER (
      WHERE verified AND slug IS NOT NULL AND btrim(slug) <> ''
    )::int AS verified_usable_slug_rows,
    count(*) FILTER (
      WHERE verified AND (how_to_apply IS NULL OR btrim(how_to_apply) = '')
    )::int AS verified_missing_how_to_apply_rows,
    count(*) FILTER (WHERE verified AND last_verified_at IS NULL)::int
      AS verified_missing_last_verified_rows,
    count(*) FILTER (WHERE verified AND deadline IS NULL)::int
      AS verified_missing_deadline_rows,
    count(*) FILTER (WHERE verified AND deadline < CURRENT_DATE)::int
      AS verified_past_deadline_rows,
    count(*) FILTER (
      WHERE verified AND deadline > CURRENT_DATE AND last_cycle_closed_at IS NOT NULL
    )::int AS verified_future_deadline_with_historical_close_rows
  FROM public.scholarships
)
SELECT
  queried_at,
  total_rows,
  verified_rows,
  verified_usable_slug_rows,
  verified_missing_how_to_apply_rows,
  verified_missing_last_verified_rows,
  verified_missing_deadline_rows,
  verified_past_deadline_rows,
  verified_future_deadline_with_historical_close_rows
FROM inventory
LIMIT 1;
```

The result was: **95 total**, **44 verified**, **44 verified with usable slugs**, **11 missing `how_to_apply`**, **15 missing `last_verified_at`**, **4 missing deadlines**, **17 past deadlines**, and **4 future deadlines with historical close markers**.

The target-row query was:

```sql
SELECT
  id,
  title,
  slug,
  verified,
  application_url,
  how_to_apply,
  opens_at,
  deadline,
  last_cycle_closed_at,
  last_verified_at
FROM public.scholarships
WHERE slug IN (
  'asuu-scholarship-scheme-for-indigent-students-31cfebd0',
  'bode-amao-foundation-scholarship-baf-215ee2c9',
  'decagon-undergraduate-honors-program',
  'ejiro-m-ukiri-international-scholarship-fund-4c469077',
  'florence-bamidele-makanjuola-scholarship-aaaaaaaa',
  'jg-afrika-bursary-2027-64790f70',
  'kpmg-seyi-bickersteth-scholarship-programme-cccccccc',
  'lagos-state-scholarship-board-bursary-scholarship-awards-d9c8ed08',
  'light-and-bells-health-foundation-scholarship-2026-e93e25b7',
  'mastercard-foundation-scholars-program-at-pan-atlantic-university-aaaaaaaa',
  'midwestern-oil-gas-host-community-scholarship-cccccccc',
  'mtn-foundation-science-technology-scholarship-aaaaaaaa',
  'nddc-local-post-graduate-master-s-degree-scholarship-2026-2027-107bccf4',
  'nnpc-renaissance-totalenergies-aenr-jv-university-scholarship-aaaaaaaa',
  'nnpc-seplat-jv-national-undergraduate-scholarship-aaaaaaaa',
  'project-100-for-100-stem-scholarship-7eae077d',
  'ptdf-in-country-undergraduate-scholarship-scheme-aaaaaaaa'
)
ORDER BY title
LIMIT 17;
```

This query selected only the requested public fields plus the database UUID. No profiles, authentication records, matching data, or private research fields were queried.

## 3. Exact 17-record reconciliation

The matrix below compares the current production values with the safest proposed disposition. “No change” means the audit does not establish a safe new value. A proposed text value is a recommendation only and was not applied.

| UUID | Record and current production values | Proposed correction or disposition | Classification | Confidence | Schema-compatible? |
|---|---|---|---|---|---|
| `31cfebd0-100f-4b06-9250-52af820d74d4` | ASUU; URL `NULL`; `how_to_apply` non-empty; opens `NULL`; deadline `2026-09-30`; close `NULL`; verified `true`; last verified `NULL` | Do not add a central URL. Replace or qualify the stored general instructions only after editorial approval because the verified call was branch-specific. Preserve the date only as a historical/unverified field decision. Add dated provenance in `research_notes`; optionally set `last_verified_at` to `2026-11-07`. | MANUAL REVIEW for text/date; CONDITIONAL for timestamp | Medium | Yes for existing fields; no native uncertainty enum |
| `215ee2c9-28de-4609-b0b7-6898ae513a21` | Bode Amao; URL `https://bodeamaofoundation.org/`; `how_to_apply` non-empty; opens `NULL`; deadline `2026-12-31`; close `NULL`; last verified `NULL` | Retain the official homepage. Do not replace the stored checklist until the provider’s postal and email routes are reconciled. Add conflict/provenance notes and set review date only if the editorial team accepts “source reviewed” as the timestamp meaning. | MANUAL REVIEW; timestamp CONDITIONAL | Medium | Yes for `research_notes`/`last_verified_at` |
| `769b1169-71af-4f55-9be4-63374a59faa8` | Decagon; URL `https://www.decagonfoundation.org/apply`; `how_to_apply` non-empty; opens `NULL`; deadline `2026-10-15`; close `NULL`; last verified `2026-10-06` | Hold. Official pages show a paid programme charging ₦275,000/year plus tuition and school fees; no scholarship award or fee waiver was found. Do not change the URL or keep it as a verified scholarship until editorial classification decides whether it belongs in Scholars or should be reclassified outside the scholarship catalogue. If retained, replace URL with `https://decagon.institute/apply` only after that decision and remove unsupported deadline/requirements. | MANUAL REVIEW | High | Fields are compatible; classification is not modelled |
| `4c469077-cd38-424c-8913-463c7068d304` | Ejiro; URL `https://form.jotform.com/230343573288055`; `how_to_apply` non-empty; opens `NULL`; deadline `NULL`; close `NULL`; last verified `NULL` | Conditional: prefer provider `/apply` only if editorial policy accepts a reachable-but-blank official route; otherwise retain the closed Jotform. Add a dated closed-cycle notice. Do not invent a 2027 deadline. | CONDITIONAL / MANUAL REVIEW | Medium | Yes |
| `aaaaaaaa-0000-4000-8000-000000000023` | Florence; URL `https://opeketefoundation.org/apply`; `how_to_apply` `NULL`; opens `2027-05-01`; deadline `2027-05-22`; close `NULL`; last verified `NULL` | Add cycle-qualified historical instructions stating the linked 2026/27 form is closed. Remove or null the unsupported 2027 `opens_at` and `deadline` only after editorial approval because those fields drive public lifecycle behavior. Retain URL. | CONDITIONAL for date removal; CONFIRMED for dated instructions | High for source facts | Yes |
| `64790f70-f20a-4c9c-a1f4-2efabc087dcb` | JG Afrika; URL `https://www.jgafrika.com/careers-offered-at-jg-afrika/bursary/`; `how_to_apply` `NULL`; opens `NULL`; deadline `NULL`; close `NULL`; last verified `NULL` | Add the provider-backed application instructions and set `last_verified_at` to `2026-11-07`. Keep URL, no deadline, and no invented close date. | CONFIRMED | High | Yes |
| `cccccccc-0000-4000-8000-000000000016` | KPMG; URL `https://kpmg.seamlesshiring.com/job/view/181`; `how_to_apply` `NULL`; opens `2027-08-01`; deadline `2027-08-13`; close `NULL`; last verified `NULL` | Retain only as a provider-linked historical destination if desired. Do not treat the 2027 dates as published. Add a dated note about the latest closed cycle; remove/qualify future dates after editorial approval. | MANUAL REVIEW / UNSUPPORTED future dates | Medium | Yes |
| `d9c8ed08-35be-4fe8-aa9d-221909c39947` | Lagos State; URL `https://www.lagosscholarship.org/`; `how_to_apply` `NULL`; opens `2027-01-19`; deadline `2027-03-06`; close `NULL`; last verified `NULL` | Retain official information URL. Do not add instructions from a login screen. Remove/qualify unsupported 2027 dates after editorial decision and add source-review notes/timestamp. | MANUAL REVIEW for dates; CONDITIONAL timestamp | Medium | Yes |
| `e93e25b7-46a5-4254-b1c5-91ad56a3abf0` | Light and Bells; URL `https://lightandbellshealth.com/scholarships-and-grants`; `how_to_apply` non-empty; opens `NULL`; deadline `2026-10-02`; close `NULL`; last verified `NULL` | Keep URL and historical deadline. Replace current text with a dated closed-cycle/category notice, or explicitly qualify the existing checklist as unverified for a future cycle. Set `last_verified_at` to `2026-11-07` only if the editorial meaning is “source reviewed,” not “open.” | CONFIRMED for status; CONDITIONAL for text/timestamp | High for displayed page | Yes |
| `aaaaaaaa-0000-4000-8000-000000000021` | PAU Mastercard; URL `https://pau.edu.ng/mastercard-foundation/`; `how_to_apply` `NULL`; opens `NULL`; deadline `2027-05-22`; close `2026-05-22`; last verified `NULL` | No change until the PAU “closed” statement and Mastercard Foundation “Admissions Open” label are reconciled. Do not trust the stored future deadline or convert the conflict into an open/closed boolean. | MANUAL REVIEW | High for conflict; low for resolution | Yes, but no conflict/status field |
| `7eae077d-8290-4c07-abe5-95d993a554fe` | Project 100 for 100 STEM; URL `https://docs.google.com/forms/d/e/1FAIpQLSdIPjdJlAbyfkDEnxue9oV0BP339_v7S_Oj2BiveQJKQ_idWw/viewform`; `how_to_apply` `NULL`; opens `NULL`; deadline `2026-09-25`; close `NULL`; last verified `NULL` | Retain the provider-linked form, but add a dated closed-cycle notice: the 2026 form no longer accepts responses and no later cycle is confirmed. Do not invent a close date. Set `last_verified_at` only if the editorial timestamp meaning is approved. | CONFIRMED for closed status; CONDITIONAL for text/timestamp | High | Yes |
| `cccccccc-0000-4000-8000-000000000015` | Midwestern; URL `https://candidate.scholastica.ng`; `how_to_apply` `NULL`; opens `NULL`; deadline `2027-03-19`; close `2026-03-19`; last verified `NULL` | Do not use the generic platform root as a current programme route. Do not treat 2027-03-19 as published. Add historical-source notes and resolve the future-date/old-close contradiction manually. | MANUAL REVIEW / UNSUPPORTED future date | High for contradiction | Yes |
| `aaaaaaaa-0000-4000-8000-000000000001` | MTN; URL `https://www.mtn.ng/scholarships/`; `how_to_apply` `NULL`; opens `NULL`; deadline `2027-05-31`; close `2026-05-31`; last verified `NULL` | Retain provider URL. Add only cycle-qualified historical instructions. Do not treat 2027-05-31 as announced; resolve future deadline against old close marker manually. | MANUAL REVIEW / UNSUPPORTED future date | High for contradiction | Yes |
| `107bccf4-a01e-4ac6-b4bc-beaa482e403e` | NDDC; URL `https://scholarship.nddc.gov.ng/login`; `how_to_apply` non-empty; opens `NULL`; deadline `2026-11-08`; close `NULL`; last verified `2026-10-13` | Retain official URL and deadline. Qualify instructions: official call and free-application warning confirmed, but portal form/requirements were not publicly verified. Do not mark open solely from deadline. Add source-unavailable note; timestamp is conditional. | CONDITIONAL / MANUAL REVIEW | High for announcement; low for portal availability | Yes |
| `aaaaaaaa-0000-4000-8000-000000000006` | NNPC–Renaissance; URL `https://candidate.scholastica.ng`; `how_to_apply` `NULL`; opens `NULL`; deadline `2027-05-31`; close `2026-05-31`; last verified `NULL` | Retain no generic current CTA. Add historical 2026 instructions only if clearly dated. Do not accept the future deadline; resolve old close/future deadline manually. | MANUAL REVIEW / UNSUPPORTED future date | High for contradiction | Yes |
| `aaaaaaaa-0000-4000-8000-000000000004` | NNPC/Seplat; URL `https://seplatgrowthacademy.com/scholarship/`; `how_to_apply` `NULL`; opens `2027-02-23`; deadline `2027-03-13`; close `NULL`; last verified `NULL` | Retain provider URL. Add cycle-qualified 2026 instructions only; do not represent the 2027 dates as official without a new announcement. | CONDITIONAL / UNSUPPORTED future dates | High for historical cycle | Yes |
| `aaaaaaaa-0000-4000-8000-000000000012` | PTDF; URL `https://scholarship.ptdf.gov.ng`; `how_to_apply` `NULL`; opens `2027-04-20`; deadline `2027-05-29`; close `NULL`; last verified `NULL` | Retain official portal. Add dated 2026/27 historical instructions if desired. Do not publish the 2027 dates as announced; remove/qualify them only after editorial approval. | CONDITIONAL / UNSUPPORTED future dates | High for historical cycle | Yes |
## 4. Schema and application-logic findings

The live `public.scholarships` table contains the fields relevant to this audit: `id`, `title`, `provider_name`, `description`, `amount`, `deadline`, `application_url`, `level`, `discipline`, `verified`, `research_notes`, `how_to_apply`, `opens_at`, `last_cycle_closed_at`, `last_verified_at`, and `slug`, among others. The schema has no dedicated `source_url`, `source_review_status`, `uncertainty_classification`, `portal_reachability`, or scholarship/programme taxonomy field.

`research_notes` is the existing admin-only free-text provenance field. It can hold source URLs, review dates, confidence, contradictions, and manual-review instructions, but it cannot be queried as a structured status without adding a schema design. That addition is outside this audit and must not be invented here.

`how_to_apply` is nullable fallback text. It is shown when no application URL exists; an application URL and fallback text can coexist, but the public detail page primarily exposes the provider button. The admin schema allows up to 2,000 characters for this field.

`last_verified_at` is a `timestamptz`. Migration comments and the admin route define it as the time an admin confirmed a listing as live and accurate. The current PATCH route stamps it when `verified` is set to `true` and clears it when `verified` is set to `false`. The current database values were not written through that route during this audit. The application can technically store 2026-11-07 as a review timestamp, but the existing public wording—“Verified by our team”—makes that semantically unsafe for unresolved portal states unless the note clearly qualifies what was checked.

`deadline` is used directly by `isClosedListing`: a deadline before today makes the listing closed. `last_cycle_closed_at` also makes a listing closed when it is today or earlier. `opens_at` controls the “Opens [date]” state when the listing is otherwise not closed. A null `opens_at` means no opening restriction. These fields are not historical-only metadata; changing or removing them changes public visibility and badges.

The general catalogue query filters verified undergraduate/both-level rows by deadline and `last_cycle_closed_at`. Retained/saved records can remain visible in a student’s personal workspace. The frontend’s `DeadlineBadge` displays “Closed” for past deadlines. `ScholarshipCard` can display an opening badge or a cycle label when `opens_at` or `last_cycle_closed_at` supports it. There is no `SOURCE_UNAVAILABLE` or `REQUIRES_MANUAL_REVIEW` enum in the scholarship table or frontend.

`cycle_events` is a separate table with `kind`, `event_date`, `source_url`, and `note`. The admin PATCH route writes event rows when an admin changes date fields. It does not provide a general source-review event for a record whose dates remain unchanged. A correction that changes `last_cycle_closed_at` or `opens_at` would therefore affect both listing visibility and future-cycle prediction logic.

A scholarship can be represented historically only indirectly: retain a verified row with a past deadline and optionally a close date, or remove its current-cycle date and explain the historical cycle in `how_to_apply`/`research_notes`. There is no first-class historical-cycle entity. Paid programmes are also not distinguishable from scholarships at the schema level; `level`, `amount`, and free-text description do not establish that a programme awards financial support.

## 5. Decagon classification investigation

Decagon’s official application page says “Applications Open,” asks applicants to prepare a JAMB score, preferred university, course choice, and parent/guardian contacts, and links to a secure provider form. The official programme page describes a four-year Honours Programme alongside a degree.

The official fees page materially changes the data decision. It states that applicants/students pay **₦275,000 per year** for the Honours Programme and also pay university tuition and school-related fees to Decagon, which remits the university portion to the institution. It describes the ₦275,000 amount as a programme fee, says fees are paid to Decagon Services Limited, and says the application review is rolling. No scholarship award, tuition grant, fee waiver, need-based assistance, or recipient payment was found on the reviewed official pages.

The current Scholars schema has no field that can represent “paid educational programme” or “fee waiver available.” The existing row is therefore not safe to correct as a scholarship merely because a form is open. The prior stored destination is a 404, but replacing it immediately would make a potentially misclassified paid programme easier for students to act on.

**Recommendation:** `MANUAL REVIEW`. Do not change the Decagon record in this phase. An editorial decision must first determine whether Scholars intentionally includes paid programmes, whether an official subsidy exists elsewhere, or whether the row should be reclassified outside the scholarship catalogue. If the decision is to retain it as a scholarship-equivalent listing, the application URL can then be changed to `https://decagon.institute/apply`, with a prominent fee disclosure and no unsupported deadline. That would be a separate approved correction.

## 6. NDDC application-availability investigation

The official NDDC announcement says the 2026/2027 Local Post-Graduate Master’s Scholarship is for qualified Niger Delta indigenes, directs applicants to `https://scholarship.nddc.gov.ng/login`, states that the application is free, and gives an 8 November 2026 deadline. This supports the stored URL and deadline at source level.

Unauthenticated checks of both `https://scholarship.nddc.gov.ng/` and `https://scholarship.nddc.gov.ng/login` returned HTTP `403`, a `Just a moment...` title, and a Cloudflare challenge page. The responses did not expose a usable public login, registration, current application form, programme-specific fields, or evidence that submissions were being accepted. No account was created, no challenge was bypassed, and no application was submitted.

This distinguishes three separate facts: the official portal domain is reachable at the network layer; the application interface is not publicly readable from this audit environment; and current acceptance of submissions is unconfirmed. The 8 November deadline remains supported by the official announcement, but the record must not be labelled “open” solely because that date has not passed.

**Recommendation:** retain the official URL and deadline, rewrite `how_to_apply` to state the official-call facts and portal-access limitation, and use a manual/source-unavailable editorial note. Do not add a closure date or mark the portal accepting submissions.

## 7. Proposed correction matrix and implementation classifications

The classifications are defined as follows:

- **CONFIRMED:** the exact value is supported by authoritative evidence and fits an existing field without changing semantics.
- **CONDITIONAL:** the value is supported only if an explicit unresolved condition is satisfied.
- **UNSUPPORTED:** evidence is insufficient; do not implement the proposed value.
- **MANUAL REVIEW:** a human editorial decision is required before any write.

### Confirmed candidates

The only clean confirmed content candidate is JG Afrika’s `how_to_apply` text plus a source note, because the provider page and current-cycle announcement support an actionable application route and no deadline. Light and Bells’ closed-cycle status and categories are also confirmed, but replacing its existing detailed checklist requires editorial approval because the stored checklist is not re-established by the current page.

### Conditional candidates

NDDC’s cycle-qualified `how_to_apply` text is conditional because it must preserve the distinction between official announcement evidence and inaccessible portal status. Ejiro’s provider `/apply` URL is conditional because the page was blank in the inspected view while the stored Jotform was closed. Florence, NNPC/Seplat, and PTDF can receive historical instructions only if the UI/editorial policy clearly labels them as historical rather than current.

### Unsupported candidates

The stored future dates for Florence, KPMG, Lagos State, NNPC–Renaissance, NNPC/Seplat, and PTDF are not supported by the reviewed sources. They must not be copied into a “new” value or silently shifted forward from a prior cycle. The four future-deadline/old-close-marker cases are particularly unsafe because the application treats both date fields as lifecycle inputs.

### Manual-review candidates

Decagon, ASUU, Bode Amao, PAU, Midwestern, MTN, NDDC, and the records with unsupported future dates require editorial decisions before writes. Decagon requires classification review. ASUU and Bode Amao require instruction-scope or route decisions. PAU requires conflict reconciliation. NDDC requires a portal-availability decision. The future-date cases require a policy decision about whether the database stores only current cycles or may retain an explicitly historical opportunity.

## 8. Verification timestamp and provenance assessment

The current database can store a review timestamp, but it cannot distinguish “source reviewed” from “application status confirmed.” The existing migration comments say `last_verified_at` means an admin confirmed the listing as live and accurate. The public detail page displays that timestamp as a verified claim. Therefore, blindly setting `last_verified_at = 2026-11-07` on unresolved records would overstate what was verified.

For JG Afrika, a timestamp is compatible with the evidence because the current provider source supports an open actionable route. For Light and Bells, a timestamp is technically possible but should be accompanied by a closed-cycle qualification. For NDDC, Decagon, PAU, ASUU, Bode Amao, and other conflicted records, the current schema cannot safely encode the review result without relying on `research_notes` and editorial conventions.

No dedicated provenance column exists on `public.scholarships`. `cycle_events.source_url` is useful only for a date event and should not be populated merely to simulate a general source review. A safe future schema decision would be to define separate structured review fields or a review-event table, but this audit does not design or apply that migration.

## 9. Batch-by-batch implementation plan

No batch below was executed.

### Batch A — confirmed application-destination corrections

**Current safe scope:** none for immediate production application.

Decagon’s old URL is confirmed broken, but the row’s scholarship classification is unresolved. Ejiro’s official `/apply` route is reachable but blank, so it is not a confirmed replacement. The other stored provider URLs are either official information destinations or generic portals whose current programme state is unconfirmed.

**Risk:** changing a URL can create a false application CTA and can direct students to a paid or closed service.  
**Frontend impact:** the detail page’s “Apply on provider’s site” button changes immediately.  
**Rollback:** restore the exact prior `application_url` by UUID through the admin route; do not delete rows.

### Batch B — confirmed application-instruction corrections

**Candidate UUID:** `64790f70-f20a-4c9c-a1f4-2efabc087dcb` (JG Afrika).  
**Field:** `how_to_apply` from `NULL` to the provider-backed actionable instructions in the JG Afrika evidence note.  
**Evidence:** official JG Afrika bursary page and current-cycle announcement.  
**Confidence:** high.  
**Schema compatibility:** confirmed; `how_to_apply` accepts nullable text up to 2,000 characters.  
**Risk:** low if the text is copied exactly and dated.  
**Frontend impact:** the fallback guidance becomes available where no URL or route detail is shown.  
**Rollback:** restore `NULL` or the prior exact text by UUID.

**Conditional candidates:** Light and Bells, NDDC, Florence, Ejiro, NNPC/Seplat, and PTDF. These require editorial approval because their instructions are historical, conflict-qualified, or source-unavailable. Do not batch them with JG Afrika without explicit approval.

### Batch C — verification timestamps and provenance

**Potential fields:** `research_notes`, and in selected cases `last_verified_at`.  
**Exact UUIDs:** all 17 are technically addressable, but no blanket write is safe.

The safest first candidates are JG Afrika and Light and Bells, provided the product owner accepts that the timestamp means “source review completed” rather than “application confirmed open.” NDDC must carry a source-unavailable qualification. Decagon should not receive a fresh scholarship verification timestamp while its classification is unresolved.

**Risk:** the public UI displays `last_verified_at` as a trust claim, and notification freshness logic uses it to identify current records.  
**Frontend impact:** “Verified by our team on…” appears on detail pages; push/new-match freshness may change.  
**Rollback:** restore each exact prior timestamp and research note by UUID.

### Batch D — deadline and lifecycle corrections

**Current safe scope:** none for immediate execution.

Removing unsupported dates or changing `last_cycle_closed_at` affects `isClosedListing`, catalogue filtering, opening badges, cycle labels, and next-cycle prediction. A future date can make a record appear upcoming; a null date can make it appear open by default. The four future-deadline/old-close-marker cases require a separate product decision before any write.

**Risk:** high. A date correction can expose expired opportunities or hide valid ones.  
**Frontend impact:** catalog visibility, “Closed,” “Opens,” cycle labels, deadline badges, saved-list behavior, and notifications can change.  
**Rollback:** restore the exact prior date fields and, if the admin route created them, review associated `cycle_events` rows. No delete-based rollback is recommended.

## 10. Manual decisions and unresolved questions

1. Does Scholars include paid educational programmes, or only awards, grants, tuition support, and fee waivers? Decagon cannot be safely retained as a scholarship until this is answered.
2. If a provider page confirms a historical cycle but not a current cycle, should the row remain in the verified catalogue, be marked historical through existing fields, or be unpublished? The schema has no explicit historical state.
3. May `last_verified_at` mean “official source reviewed” when application acceptance is unresolved? Current migrations and UI language suggest that it should mean a stronger confirmation.
4. Should unsupported future dates be nulled, retained as unverified editorial notes, or moved into a future-cycle data model? The current date fields directly affect visibility.
5. Should NDDC be shown with an official URL and a source-unavailable warning, or held until the portal is publicly readable? The announcement supports the programme, but the form state cannot be confirmed.
6. Which Bode Amao submission channel governs the current cycle: provider-hosted email submission or postal delivery through a registrar?
7. Which PAU status governs the current cycle: PAU’s closed notice or the Mastercard Foundation directory’s undated “Admissions Open” label?
8. Does ASUU’s national record intentionally represent branch-mediated calls? If yes, its current instructions must remain branch-qualified and must not claim a universal national process.

## 11. Audit-integrity declaration

This audit was read-only. It queried only the requested public scholarship fields and cycle-event fields. It did not query student profiles, authentication records, private matching data, or private research notes. It did not create accounts, submit external applications, bypass Cloudflare or other access controls, run migrations, execute DML, modify code, modify configuration, deploy, merge, delete, or change any Supabase object.

The only artifact created by this phase is this Markdown report in `ImperioKDB/Updates`. No implementation batch is authorized by this report.

## Final decision

# READY WITH CONDITIONS.

The database UUIDs, current values, schema compatibility, and frontend effects are established. Limited implementation remains conditional on three editorial decisions: Decagon’s classification, the meaning of `last_verified_at` for unresolved source states, and the treatment of unsupported future lifecycle dates. Until those decisions are made, do not apply the proposed corrections.

## References

[1]: https://decagon.institute/apply "Decagon official application page"
[2]: https://decagon.institute/fees "Decagon official fees page"
[3]: https://decagon.institute/ "Decagon official Honours Programme page"
[4]: https://www.facebook.com/OfficialNDDC/posts/nddc-20262027-local-post-graduate-scholarship-call-for-applicationsthe-niger-del/1509046547707715/ "NDDC official 2026/2027 local postgraduate scholarship announcement"
[5]: https://scholarship.nddc.gov.ng/login "NDDC official scholarship portal login"
[6]: https://www.jgafrika.com/careers-offered-at-jg-afrika/bursary/ "JG Afrika official bursary page"
[7]: https://lightandbellshealth.com/scholarships-and-grants "Light and Bells official scholarships page"
[8]: https://www.ejirointernationalscholarshipfund.com/apply "Ejiro official application page"
[9]: https://opeketefoundation.org/apply "Opekete Foundation official FBM application page"
[10]: https://pau.edu.ng/mastercard-foundation/ "Pan-Atlantic University Mastercard Foundation page"
[11]: https://mastercardfdn.org/en/what-we-do/our-programs/mastercard-foundation-scholars-program/where-to-apply/pan-atlantic-university/ "Mastercard Foundation PAU partner page"
[12]: https://www.lagosscholarship.org/ "Lagos State Scholarship Board official site"
[13]: https://www.mtn.ng/scholarships/ "MTN Nigeria official scholarships page"
[14]: https://renaissanceafrica.com/sustainability/education "Renaissance Africa official education page"
[15]: https://www.seplatenergy.com/news-insights/news/nnpcseplat-jv-national-undergraduate-scholarship-2026/ "Seplat official 2026 scholarship announcement"
[16]: https://www.afrotechgirls.org/post/100-girls-100-000-each-one-big-step-forward "Afro-Tech Girls Project 100 for 100 announcement"
[17]: https://scholarship.ptdf.gov.ng/guidelines "PTDF official scholarship guidelines"
[18]: https://github.com/ImperioKDB/Scholars/blob/main/lib/dates.ts "Scholars lifecycle date helpers"
[19]: https://github.com/ImperioKDB/Scholars/blob/main/lib/discovery.ts "Scholars discovery open-state logic"
[20]: https://github.com/ImperioKDB/Scholars/blob/main/lib/matching/getMatches.ts "Scholars scholarship query and lifecycle filtering"
[21]: https://github.com/ImperioKDB/Scholars/blob/main/app/api/admin/scholarships/%5Bid%5D/route.ts "Scholars admin scholarship update route"
[22]: https://github.com/ImperioKDB/Scholars/blob/main/supabase/migrations/0012_add_last_cycle_closed_at.sql "Scholars last-cycle-close schema migration"
[23]: https://github.com/ImperioKDB/Scholars/blob/main/supabase/migrations/0021_add_last_verified_at.sql "Scholars verification timestamp schema migration"
