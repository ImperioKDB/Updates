# Scholars Phase 1.1 — Production Snapshot and Technical Reference

**Snapshot query time:** `2026-11-07 15:11:23.338793+00`  
**Supabase project:** `cmdglabohpttgfofcmqc`  
**Access mode:** read-only

## Inventory counts

| Metric | Value |
|---|---:|
| Total scholarship rows | 95 |
| Verified scholarship rows | 44 |
| Verified rows with usable slugs | 44 |
| Verified rows missing or blank `how_to_apply` | 11 |
| Verified rows missing `last_verified_at` | 15 |
| Verified rows missing `deadline` | 4 |
| Verified rows with past deadlines | 17 |
| Verified rows with future deadlines and historical close markers | 4 |

## Inventory query

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

## 17 target UUID snapshot

The target query selected: `id`, `title`, `slug`, `verified`, `application_url`, `how_to_apply`, `opens_at`, `deadline`, `last_cycle_closed_at`, and `last_verified_at`. `how_to_apply` is shown as `NULL` or `NON-NULL` here; the complete current text is in the production database and was not copied into this package where the prior evidence notes already provide the relevant content.

| UUID | Title | Slug | Verified | URL | How-to-apply | Opens | Deadline | Last close | Last verified |
|---|---|---|---|---|---|---|---|---|---|
| `31cfebd0-100f-4b06-9250-52af820d74d4` | ASUU Scholarship Scheme for Indigent Students | `asuu-scholarship-scheme-for-indigent-students-31cfebd0` | true | NULL | NON-NULL | NULL | 2026-09-30 | NULL | NULL |
| `215ee2c9-28de-4609-b0b7-6898ae513a21` | Bode Amao Foundation Scholarship (BAF) | `bode-amao-foundation-scholarship-baf-215ee2c9` | true | `https://bodeamaofoundation.org/` | NON-NULL | NULL | 2026-12-31 | NULL | NULL |
| `769b1169-71af-4f55-9be4-63374a59faa8` | Decagon Undergraduate Honors Program | `decagon-undergraduate-honors-program` | true | `https://www.decagonfoundation.org/apply` | NON-NULL | NULL | 2026-10-15 | NULL | 2026-10-06 11:52:53.120101+00 |
| `4c469077-cd38-424c-8913-463c7068d304` | Ejiro M Ukiri International Scholarship Fund | `ejiro-m-ukiri-international-scholarship-fund-4c469077` | true | `https://form.jotform.com/230343573288055` | NON-NULL | NULL | NULL | NULL | NULL |
| `aaaaaaaa-0000-4000-8000-000000000023` | Florence Bamidele Makanjuola Scholarship | `florence-bamidele-makanjuola-scholarship-aaaaaaaa` | true | `https://opeketefoundation.org/apply` | NULL | 2027-05-01 | 2027-05-22 | NULL | NULL |
| `64790f70-f20a-4c9c-a1f4-2efabc087dcb` | JG Afrika Bursary 2027 | `jg-afrika-bursary-2027-64790f70` | true | `https://www.jgafrika.com/careers-offered-at-jg-afrika/bursary/` | NULL | NULL | NULL | NULL | NULL |
| `cccccccc-0000-4000-8000-000000000016` | KPMG Seyi Bickersteth Scholarship Programme | `kpmg-seyi-bickersteth-scholarship-programme-cccccccc` | true | `https://kpmg.seamlesshiring.com/job/view/181` | NULL | 2027-08-01 | 2027-08-13 | NULL | NULL |
| `d9c8ed08-35be-4fe8-aa9d-221909c39947` | Lagos State Scholarship Board Bursary & Scholarship Awards | `lagos-state-scholarship-board-bursary-scholarship-awards-d9c8ed08` | true | `https://www.lagosscholarship.org/` | NULL | 2027-01-19 | 2027-03-06 | NULL | NULL |
| `e93e25b7-46a5-4254-b1c5-91ad56a3abf0` | Light and Bells Health Foundation Scholarship 2026 | `light-and-bells-health-foundation-scholarship-2026-e93e25b7` | true | `https://lightandbellshealth.com/scholarships-and-grants` | NON-NULL | NULL | 2026-10-02 | NULL | NULL |
| `aaaaaaaa-0000-4000-8000-000000000021` | Mastercard Foundation Scholars Program at Pan-Atlantic University | `mastercard-foundation-scholars-program-at-pan-atlantic-university-aaaaaaaa` | true | `https://pau.edu.ng/mastercard-foundation/` | NULL | NULL | 2027-05-22 | 2026-05-22 | NULL |
| `cccccccc-0000-4000-8000-000000000015` | Midwestern Oil & Gas Host Community Scholarship | `midwestern-oil-gas-host-community-scholarship-cccccccc` | true | `https://candidate.scholastica.ng` | NULL | NULL | 2027-03-19 | 2026-03-19 | NULL |
| `aaaaaaaa-0000-4000-8000-000000000001` | MTN Foundation Science & Technology Scholarship | `mtn-foundation-science-technology-scholarship-aaaaaaaa` | true | `https://www.mtn.ng/scholarships/` | NULL | NULL | 2027-05-31 | 2026-05-31 | NULL |
| `107bccf4-a01e-4ac6-b4bc-beaa482e403e` | NDDC Local Post-Graduate (Master's Degree) Scholarship 2026/2027 | `nddc-local-post-graduate-master-s-degree-scholarship-2026-2027-107bccf4` | true | `https://scholarship.nddc.gov.ng/login` | NON-NULL | NULL | 2026-11-08 | NULL | 2026-10-13 09:54:32.204285+00 |
| `aaaaaaaa-0000-4000-8000-000000000006` | NNPC-Renaissance/TotalEnergies/AENR JV University Scholarship | `nnpc-renaissance-totalenergies-aenr-jv-university-scholarship-aaaaaaaa` | true | `https://candidate.scholastica.ng` | NULL | NULL | 2027-05-31 | 2026-05-31 | NULL |
| `aaaaaaaa-0000-4000-8000-000000000004` | NNPC/Seplat JV National Undergraduate Scholarship | `nnpc-seplat-jv-national-undergraduate-scholarship-aaaaaaaa` | true | `https://seplatgrowthacademy.com/scholarship/` | NULL | 2027-02-23 | 2027-03-13 | NULL | NULL |
| `7eae077d-8290-4c07-abe5-95d993a554fe` | Project 100 for 100 STEM Scholarship | `project-100-for-100-stem-scholarship-7eae077d` | true | `https://docs.google.com/forms/d/e/1FAIpQLSdIPjdJlAbyfkDEnxue9oV0BP339_v7S_Oj2BiveQJKQ_idWw/viewform` | NULL | NULL | 2026-09-25 | NULL | NULL |
| `aaaaaaaa-0000-4000-8000-000000000012` | PTDF In-Country Undergraduate Scholarship Scheme | `ptdf-in-country-undergraduate-scholarship-scheme-aaaaaaaa` | true | `https://scholarship.ptdf.gov.ng` | NULL | 2027-04-20 | 2027-05-29 | NULL | NULL |

## Cycle-event snapshot

The read-only cycle-event query showed backfilled events for the following target UUIDs: MTN closed 2026-05-31; NNPC/Seplat opened 2027-02-23; NNPC–Renaissance closed 2026-05-31; PTDF opened 2027-04-20; PAU closed 2026-05-22; Florence opened 2027-05-01; Midwestern closed 2026-03-19; KPMG opened 2027-08-01; and Lagos State opened 2027-01-19. These events were backfilled from scholarship date fields and have no source URL. Treat them as database lifecycle history, not independent official evidence.

## Technical findings

- `public.scholarships` supports `application_url`, `how_to_apply`, `research_notes`, `deadline`, `opens_at`, `last_cycle_closed_at`, `last_verified_at`, and `verified`.
- There is no structured source URL, uncertainty enum, portal-status field, historical-cycle entity, or paid-programme taxonomy.
- `last_verified_at` is displayed publicly as a verification claim and is set/cleared by the admin route when `verified` changes.
- `deadline` or `last_cycle_closed_at` at or before today makes a record closed.
- `opens_at` in the future makes a record upcoming; null means no opening restriction.
- Public catalogue queries filter verified rows by deadline and close-marker logic.
- Saved/tracked records can remain visible in a student’s personal workspace.
- Date changes can create `cycle_events` rows and alter lifecycle predictions.

## NDDC transport check

Unauthenticated `GET` checks on both `https://scholarship.nddc.gov.ng/` and `https://scholarship.nddc.gov.ng/login` returned HTTP `403`, a `Just a moment...` title, and a Cloudflare challenge. The page did not expose a usable public login, registration, or application form in the audit environment. No challenge was bypassed.

## Decagon classification check

`https://decagon.institute/apply` says “Applications Open” and links to a provider-controlled secure form. `https://decagon.institute/fees` says the participant pays ₦275,000 per year for the Honours Programme and also pays university tuition and school-related fees to Decagon. No official award or fee-waiver evidence was found. Hold the record for editorial classification.
