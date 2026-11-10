# Scholars Phase 1.1 — New Manus Session Handoff

**Handoff date:** 2026-11-07  
**Purpose:** Continue the read-only implementation-readiness and data-reconciliation audit without losing source evidence, production snapshot context, or safety restrictions.

## Start here

Read these files in this order:

1. `SCHOLARS_PHASE_1_1_TASK_SPEC_2026-11-07.md` — the user-provided task specification and restrictions.
2. `SCHOLARS_PHASE_1_1_IMPLEMENTATION_READINESS_AUDIT_2026-11-07.md` — the completed Phase 1.1 report and current decision.
3. `SCHOLARS_PHASE_1_1_PRODUCTION_SNAPSHOT_2026-11-07.md` — the exact read-only inventory counts, UUID-backed target snapshot, queries, and application/schema findings.
4. `SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_2026-11-07.md` — the preceding Phase 1 revalidation report.
5. `SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/` — all 17 record-level source notes.
6. `EXPORT_MANIFEST.json` — package contents, commit references, and integrity metadata.

## Repositories and commits

- **Application repository:** `https://github.com/ImperioKDB/Scholars`
- **Application branch inspected:** `main`
- **Application commit inspected:** `cf3682c` (`feat: add scholarship application details`)
- **Reporting repository:** `https://github.com/ImperioKDB/Updates`
- **Reporting branch:** `main`
- **Latest reporting commit at export:** see `EXPORT_MANIFEST.json`; it includes the Phase 1.1 report and this export.
- **Supabase production project:** `cmdglabohpttgfofcmqc` (`scholarship-platform`, `eu-west-1`)
- **Production domain:** `https://www.scholars.com.ng`

## Current status

The Phase 1.1 audit is complete as a read-only report. Its final decision is:

> **READY WITH CONDITIONS.**

No production data, code, schema, RLS, policy, function, configuration, account, external application, deployment, or merge was changed. Do not interpret the report as authorization to implement corrections.

The live inventory at query time was:

- 95 total scholarship rows.
- 44 verified rows.
- 44 verified rows with usable slugs.
- 11 verified rows missing `how_to_apply`.
- 15 verified rows missing `last_verified_at`.
- 4 verified rows missing deadlines.
- 17 verified rows with past deadlines.
- 4 verified rows with future deadlines and historical close markers.

The 17 target UUIDs, current values, and proposed dispositions are in the Phase 1.1 report and the production snapshot. The matrix has been QC-checked to contain exactly 17 unique UUIDs.

## Critical conclusions

### Decagon is not yet safe to treat as a scholarship

The official application page says applications are open, but the official fees page states that participants pay ₦275,000 per year for the Honours Programme and also pay university tuition and school-related fees to Decagon. No official scholarship award, tuition grant, fee waiver, or recipient payment was found in the reviewed official pages.

Do not simply replace the stale `https://www.decagonfoundation.org/apply` URL with `https://decagon.institute/apply`. First obtain an editorial decision on whether Scholars includes paid educational programmes or whether an official subsidy exists elsewhere. The current schema cannot distinguish scholarships from paid programmes.

### NDDC is officially evidenced but its live portal state is unconfirmed

The official NDDC announcement supports the 2026/2027 Local Post-Graduate Master’s Scholarship, the official portal URL, a free application, and the 8 November 2026 deadline. Unauthenticated checks of the portal returned a Cloudflare HTTP 403 challenge with no public login, registration, or application form content. No access control was bypassed.

Keep the official route and deadline as source-backed facts, but do not claim that submissions are currently accepted. The report recommends a source-unavailable/manual-review qualification.

### Existing schema limitation

`public.scholarships` has `application_url`, `how_to_apply`, `research_notes`, `deadline`, `opens_at`, `last_cycle_closed_at`, `last_verified_at`, and `verified`, but no structured source URL, uncertainty classification, portal status, review-event status, historical-cycle entity, or paid-programme taxonomy. `research_notes` is the existing admin-only free-text provenance field.

The current frontend uses `deadline` and `last_cycle_closed_at` to determine closed visibility and uses `opens_at` for upcoming/open display. Changing or removing dates is a product-visible lifecycle change, not a harmless metadata edit. `last_verified_at` is displayed publicly and is also used by freshness-related notification logic, so it must not be set casually on unresolved records.

## Safe continuation path

If the next session is asked to implement corrections, stop and request the missing editorial decisions before writing production data:

1. Decide whether Decagon belongs in the Scholars scholarship catalogue.
2. Decide whether `last_verified_at` may mean “source reviewed” when application acceptance is unresolved.
3. Decide whether unsupported future dates should be nulled, retained as explicitly unverified editorial data, or represented through a future-cycle model.
4. Decide how to handle the PAU conflict between the provider’s closed statement and the Mastercard Foundation directory’s undated “Admissions Open” label.
5. Decide whether ASUU’s branch-mediated model should remain as one national record with branch-qualified instructions.
6. Resolve Bode Amao’s conflicting official postal and email submission channels.

Only after those decisions should a separate implementation phase be planned. Never apply the whole 17-record matrix as one blind update.

## If limited implementation is explicitly approved

The lowest-risk first candidate is the JG Afrika record:

- UUID: `64790f70-f20a-4c9c-a1f4-2efabc087dcb`
- Existing URL: `https://www.jgafrika.com/careers-offered-at-jg-afrika/bursary/`
- Existing `how_to_apply`: `NULL`
- Existing deadline: `NULL`
- Proposed change: add the provider-backed actionable instructions from `SCHOLARS_SCHOLARSHIP_DATA_REVALIDATION_EVIDENCE_2026-11-07/jg-afrika.md`
- Proposed `last_verified_at`: only if the user explicitly approves the interpretation that it records source review and current actionable status.

Even this limited change requires explicit approval because it writes production data. Use the existing authenticated admin route, not direct SQL, unless the user separately authorizes a controlled database operation. After any approved write, verify the exact UUID and fields, run the relevant tests/build, commit only code or documentation changes as appropriate, and report deployment status.

Do not implement Batch D date changes until their frontend impact has been approved. A date change can expose expired opportunities, hide valid opportunities, alter cycle predictions, change badges, affect catalogue visibility, and influence reminders.

## Required safety rules

- Read-only by default.
- Do not insert, update, delete, or create test scholarship rows without explicit approval.
- Do not run migrations or change schemas, RLS, policies, or functions.
- Do not modify application code or configuration for this audit.
- Do not create accounts or submit external applications.
- Do not bypass Cloudflare, login, CAPTCHA, or other access controls.
- Do not query student profiles, private matching data, authentication records, or private research notes unless a later task explicitly authorizes a minimum necessary read.
- Never force-push.
- Never delete tables, buckets, rows, or files.
- Do not treat a URL’s HTTP status as proof that an application is open or closed.
- Do not treat a verification timestamp as proof that applications are accepting submissions.
- Preserve unsupported dates as unresolved until an editorial decision is made.

## Deliverable expectation for the next session

For a read-only continuation, update the report only if a concrete material fact changes. For an implementation request, first produce a narrowly scoped change plan with exact UUIDs, fields, old values, new values, evidence, confidence, frontend impact, and rollback. Wait for explicit approval when the change touches production data or unresolved business rules.

The authoritative completed report is `SCHOLARS_PHASE_1_1_IMPLEMENTATION_READINESS_AUDIT_2026-11-07.md`. The authoritative source bundle is the 17-note evidence directory. This handoff package is a continuation aid, not a replacement for those files.
