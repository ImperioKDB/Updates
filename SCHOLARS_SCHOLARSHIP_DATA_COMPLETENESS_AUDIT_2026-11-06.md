# SCHOLARS — SCHOLARSHIP DATA COMPLETENESS AUDIT

**Audit date:** 7 November 2026  
**Data source:** Read-only query against the connected production Supabase project `cmdglabohpttgfofcmqc`; current source inspection of `ImperioKDB/Scholars` at `67070cbbf93c31327c1bf311af631ad24a01a1a3`; safe HTTP checks of populated application destinations.  
**Report repository:** `ImperioKDB/Updates`  
**Production domain:** https://www.scholars.com.ng  
**Scope:** Verified scholarship records only; no student profiles, private matching data, authentication data, secrets, research notes, or personal information are included.

## 1. Executive Summary

**The historical baseline of 44 verified scholarships remains current, but completeness is uneven in the fields needed for trustworthy application handoff.** The production table contains 95 scholarship rows, of which 44 are verified and have non-empty slugs. Using the application’s UTC date predicates on 7 November 2026, 18 verified scholarships are active, 21 are closed, and five have not opened yet; four verified records have no deadline and 17 have past deadlines. All 44 descriptions exceed the audit’s 80-character usefulness floor, and all titles, providers, and slugs pass the basic presence/syntax checks. However, only 43/44 (97.7%) contain an application destination, 43/44 (97.7%) contain a syntactically valid URI, and 40/44 (90.9%) returned HTTP 200 in a safe no-form-submission check. One application URL is missing, one returned 404, and one official-looking portal returned 403. Application instructions are actionable for 26/44 (59.1%), partially informative for 7/44 (15.9%), and missing for 11/44 (25.0%). Only 29/44 (65.9%) have `last_verified_at`. Structured eligibility rules exist for 31/44 records, with no malformed rows or mechanically impossible numeric ranges detected; two rule rows use `academic_level`, which is not a direct inspected profile column. The smallest safe engineering scope is to expose existing reliable scholarship `application_url` and `how_to_apply` fields in the public template, while treating data correction, source rechecking, lifecycle cleanup, and eligibility-rule normalization as separate editorial work.

## 2. Audit Date, Data Source, and Safety Boundary

This was an investigation, not an implementation task. The database queries were read-only `SELECT` statements with explicit limits where applicable. No `INSERT`, `UPDATE`, `DELETE`, DDL, policy, storage, deployment, source-code, or production-content operation was performed. Application destinations were checked with safe HTTP `HEAD` requests and limited `GET` fallback where necessary; no forms were submitted, no authentication was attempted, and no suspicious files were downloaded.

The audited records were selected with `public.scholarships.verified = true`. The `verified` flag was treated as an inventory filter, not as proof that every individual fact is currently accurate. Individual source provenance and currentness still require editorial review.

## 3. Inventory Counts and Counting Methodology

### 3.1 Counts

| Metric | Count | Exact filter or definition |
|---|---:|---|
| Total scholarship rows | **95** | All rows in `public.scholarships`. |
| Verified scholarship rows | **44** | `verified = true`. |
| Verified rows with non-null usable slugs | **44** | `verified = true AND slug IS NOT NULL AND btrim(slug) <> ''`. |
| Verified active records | **18** | Verified; not closed by deadline or `last_cycle_closed_at`; and `opens_at IS NULL OR opens_at <= CURRENT_DATE`. |
| Verified closed records | **21** | Verified and (`deadline < CURRENT_DATE` OR `last_cycle_closed_at <= CURRENT_DATE`). This matches `isClosedListing` in `lib/dates.ts`. |
| Verified not-yet-open records | **5** | Verified, not closed, and `opens_at > CURRENT_DATE`. |
| Verified records with missing deadline | **4** | Verified and `deadline IS NULL`. |
| Verified records with past deadline | **17** | Verified and `deadline < CURRENT_DATE`. |
| Verified missing-or-past deadline | **21** | Verified and (`deadline IS NULL OR deadline < CURRENT_DATE`). |
| Verified descriptions below audit floor | **0** | Verified and description is null or shorter than 80 trimmed characters. All 44 were at least 80 characters; this does not prove editorial usefulness. |
| Verified missing `last_verified_at` | **15** | Verified and `last_verified_at IS NULL`. |

The earlier SEO audit’s historical figure of 44 verified scholarships with non-null slugs is therefore still correct. The total table population was not previously reported and is now 95.

### 3.2 Status interpretation

The active/closed logic follows the application code rather than an invented status field. `lib/dates.ts` defines a listing as closed when its deadline is before today or `last_cycle_closed_at` is today or earlier. `lib/discovery.ts` considers a listing currently open only when it is not closed and, if an opening date exists, that opening date has arrived. This creates three useful buckets: active, closed, and not-yet-open.

## 4. Database Field Completeness Table

The denominator for all percentages below is the 44-record verified inventory. “Present” does not mean correct; provider identity, source, deadline, and eligibility still require verification.

| Field or check | Present/usable | Percentage | Audit definition |
|---|---:|---:|---|
| Title meaningful | 44/44 (100.0%) | 100.0% | Non-empty and at least eight trimmed characters; no generic title detected by this rule. |
| Provider identifiable | 44/44 (100.0%) | 100.0% | Non-empty `provider_name`; all 44 populated. |
| Slug present and syntactically suitable | 44/44 (100.0%) | 100.0% | Lowercase URL-safe hyphen form; all 44 passed. Uniqueness is supported by the sitemap/database route inventory but should remain tested. |
| Description at least 80 characters | 44/44 (100.0%) | 100.0% | Non-empty and at least 80 trimmed characters. |
| Application destination populated | 43/44 (97.7%) | 97.7% | Any non-empty `application_url`, including `mailto:`. |
| Application URI syntactically valid | 43/44 (97.7%) | 97.7% | HTTP(S) URL with host or a `mailto:` route. This is not official-provenance proof. |
| HTTP application URL | 42/44 | 95.5% | Non-empty HTTP(S) URLs; the remaining populated destination is `mailto:`. |
| HTTP 200 after safe check | 40/44 (90.9%) | 90.9% | 40 returned 200; some 200 responses were login/closed-form destinations after redirects. |
| Likely provider/official or explicit official platform | 38/44 (86.4%) | 86.4% | Conservative URL-host classification: provider-like domains, recognised application platforms, or provider email route. Requires source review. |
| Actionable `how_to_apply` | 26/44 (59.1%) | 59.1% | Includes a concrete route/action plus meaningful requirements or timing language. |
| Partially informative `how_to_apply` | 7/44 (15.9%) | 15.9% | Some route or action information, but insufficient detail for a consistent application handoff. |
| Missing `how_to_apply` | 11/44 (25.0%) | 25.0% | Null or empty. |
| Amount/benefit text populated | 42/44 (95.5%) | — | `amount` is populated; null may mean unknown or not applicable and cannot be distinguished from the column alone. |
| Discipline populated | 14/44 (31.8%) | — | No inference made for the 30 missing values. |
| Deadline populated | 40/44 (90.9%) | 90.9% | Non-null date column. Four records are rolling/no-deadline or otherwise missing a date. |
| `last_verified_at` populated | 29/44 (65.9%) | 65.9% | Non-null timestamp. |
| `verified = true` | 44/44 (100.0%) | — | Inventory filter confirmed by query. |
| Structured rules present | 31/44 (70.5%) | — | At least one `scholarship_rules` row. |

### 4.1 Combined completeness score

A diagnostic score was calculated only to show weighted trade-offs; it is not a claim that the records are 84.4% trustworthy. Weighting: valid application destination 25%; application instructions 20% (`actionable = 1.0`, `partial = 0.6`, missing = 0); description 15%; structured rules 15%; deadline 10%; verification date 10%; basic identity fields (provider/title/slug) 5%. The resulting aggregate is **84.4/100**.

The score must not hide critical defects. A collection can score highly while still containing a missing application destination, a broken destination, outdated deadlines, or no freshness timestamp. Those defects are therefore reported separately and prioritised above the aggregate.

## 5. Application URL Verification Results

### 5.1 Aggregate results

Of the 44 verified scholarships, 43 have a populated application destination. Forty-two are HTTP(S) URLs and one is a provider email route. Safe checks returned HTTP 200 for 40 records, HTTP 404 for Decagon, and HTTP 403 for the NDDC portal. A 200 after a redirect does not prove that the application form is open or anonymously accessible: several Google Forms redirected to Google sign-in or a closed-form page.

The conservative classification found 21 likely provider/official domains, 16 recognised third-party application platforms, one provider email route, and five destinations whose official provenance cannot be established from the URL alone. The third-party category is not automatically untrustworthy; it includes platforms such as Google Forms, Scholastica, Jotform, and SmarterSelect that may be official routes linked by providers. Source-by-source confirmation is still needed.

### 5.2 Every populated URL

| Scholarship | Slug | Stored destination | Classification | Safe result | Final destination | Note |
|---|---|---|---|---|---|---|
| 2025 Grooming Centre University Grant Scheme | `2025-grooming-centre-university-grant-scheme` | https://groominggrant.org/ | Likely provider/official domain | 200 | https://groominggrant.org/ | No obvious transport failure in this safe check |
| AfriSEED Foundation Root Initiative 2026 | `afriseed-foundation-root-initiative-2026-cabfa816` | https://forms.gle/kJSMdxUGbv45PwjM6 | Third-party application platform | 200 after 3 redirect(s) | https://accounts.google.com/v3/signin/identifier | redirected; final destination may be login/closed form |
| AMIR Fund Medical Scholarship Program 2026/2027 | `amir-fund-medical-scholarship-program-2026-2027-755a09d6` | https://forms.gle/fT1brX6sW2D2ENFF9 | Third-party application platform | 200 after 2 redirect(s) | https://docs.google.com/forms/d/e/1FAIpQLSdXNz8muViYRrivLCedD99ZsSs-sXY-9mrrcg4f16qNRRcbgA/closedform | redirected; final destination may be login/closed form |
| Anthony Udokwu's Foundation-Yahweh 2027/2028 University Scholarship | `anthony-udokwu-s-foundation-yahweh-2027-2028-university-scholarship-ccc7a033` | https://anthonyudokwufoundationyahweh.co.uk/2028-Scholarship/ | Likely provider/official domain | 200 | https://anthonyudokwufoundationyahweh.co.uk/2028-Scholarship/ | No obvious transport failure in this safe check |
| Bode Amao Foundation Scholarship (BAF) | `bode-amao-foundation-scholarship-baf-215ee2c9` | https://bodeamaofoundation.org/ | Likely provider/official domain | 200 | https://bodeamaofoundation.org/ | No obvious transport failure in this safe check |
| Carewave ASPIRE Scholarship Programme (CASP) 2026 | `carewave-aspire-scholarship-programme-casp-32c773ba` | https://portal.carewavefoundation.org/scholarships/apply | Likely provider/official domain | 200 | https://portal.carewavefoundation.org/scholarships/apply | No obvious transport failure in this safe check |
| CBIAS Graduate Scholarship | `cbias-graduate-scholarship-d015e1ba` | https://docs.google.com/forms/d/e/1FAIpQLSdw971PP13HZUYWKtAZhntzlfaSGswqgqM3E_43z2LN4G1oGg/viewform | Third-party application platform | 200 after 2 redirect(s) | https://accounts.google.com/v3/signin/identifier | redirected; final destination may be login/closed form |
| CBIAS Undergraduate Scholarship | `cbias-undergraduate-scholarship-a374fc5b` | https://docs.google.com/forms/d/e/1FAIpQLSdw971PP13HZUYWKtAZhntzlfaSGswqgqM3E_43z2LN4G1oGg/viewform | Third-party application platform | 200 after 2 redirect(s) | https://accounts.google.com/v3/signin/identifier | redirected; final destination may be login/closed form |
| Decagon Undergraduate Honors Program | `decagon-undergraduate-honors-program` | https://www.decagonfoundation.org/apply | Likely provider/official domain | 404 | https://www.decagonfoundation.org/apply | destination returned 404 |
| EARTH University Mastercard Foundation Scholarship 2027 | `earth-university-mastercard-foundation-scholarship-2027-82516cc2` | https://admissions.earth.ac.cr/Application | Likely provider/official domain | 200 | https://admissions.earth.ac.cr/Application | No obvious transport failure in this safe check |
| Ejiro M Ukiri International Scholarship Fund | `ejiro-m-ukiri-international-scholarship-fund-4c469077` | https://form.jotform.com/230343573288055 | Third-party application platform | 200 | https://form.jotform.com/230343573288055 | No obvious transport failure in this safe check |
| Émile Boutmy Scholarship 2027 — Undergraduate | `mile-boutmy-scholarship-2027-undergraduate-526cb7ea` | https://www.sciencespo.fr/students/en/fees-funding/bursaries-financial-aid/emile-boutmy-scholarship/ | Likely provider/official domain | 200 | https://www.sciencespo.fr/students/en/fees-funding/bursaries-financial-aid/emile-boutmy-scholarship/ | No obvious transport failure in this safe check |
| FAJIM Medicare Foundation Scholarship 2026/2027 | `fajim-medicare-foundation-scholarship-2026-2027-86b94efd` | https://docs.google.com/forms/d/e/1FAIpQLSfQI0lLkaDkBhruftNHxkSXhvqtibLFpl1Eef9y7od2KqZirg/viewform | Third-party application platform | 200 after 1 redirect(s) | https://docs.google.com/forms/d/e/1FAIpQLSfQI0lLkaDkBhruftNHxkSXhvqtibLFpl1Eef9y7od2KqZirg/closedform | redirected; final destination may be login/closed form |
| Female Scholars Foundation University Scholarship 2026 | `female-scholars-foundation-university-scholarship-960fdc68` | https://docs.google.com/forms/d/e/1FAIpQLScsMy5sPWa7bi1XCxPHSRZ-g6YcCvnGkhPLC6nbf_VG26Knvw/viewform | Third-party application platform | 200 after 2 redirect(s) | https://accounts.google.com/v3/signin/identifier | redirected; final destination may be login/closed form |
| Florence Bamidele Makanjuola Scholarship | `florence-bamidele-makanjuola-scholarship-aaaaaaaa` | https://opeketefoundation.org/apply | Likely provider/official domain | 200 | https://opeketefoundation.org/apply | No obvious transport failure in this safe check |
| Gabriel Ezenri Foundation Scholarship 2026 | `gabriel-ezenri-foundation-scholarship-2026-2505b664` | https://gabrielezenrifoundation.org/apply/form | Likely provider/official domain | 200 | https://gabrielezenrifoundation.org/apply/form | No obvious transport failure in this safe check |
| JG Afrika Bursary 2027 | `jg-afrika-bursary-2027-64790f70` | https://www.jgafrika.com/careers-offered-at-jg-afrika/bursary/ | Likely provider/official domain | 200 | https://www.jgafrika.com/careers-offered-at-jg-afrika/bursary/ | No obvious transport failure in this safe check |
| KPMG Seyi Bickersteth Scholarship Programme | `kpmg-seyi-bickersteth-scholarship-programme-cccccccc` | https://kpmg.seamlesshiring.com/job/view/181 | Third-party application platform | 200 | https://kpmg.seamlesshiring.com/job/view/181 | No obvious transport failure in this safe check |
| Kunle Ade Wahab Educational Foundation Scholarship 2026 | `kunle-ade-wahab-educational-foundation-scholarship-2026-856b3014` | mailto:kawefscholarship@gmail.com | Official/provider email route | Not checked (non-HTTP or missing) | — | No obvious transport failure in this safe check |
| Lagos State Scholarship Board Bursary & Scholarship Awards | `lagos-state-scholarship-board-bursary-scholarship-awards-d9c8ed08` | https://www.lagosscholarship.org/ | Likely provider/official domain | 200 | https://www.lagosscholarship.org/ | No obvious transport failure in this safe check |
| Liberty Career Academy (LCA) Scholarship Program 2026 | `liberty-career-academy-lca-scholarship-program-2026-fabbe4a8` | https://lcaglobal.org/scholarship-application-form/ | Unclear provenance; source review required | 200 | https://lcaglobal.org/scholarship-application-form/ | provenance not established from URL alone |
| Light and Bells Health Foundation Scholarship 2026 | `light-and-bells-health-foundation-scholarship-2026-e93e25b7` | https://lightandbellshealth.com/scholarships-and-grants | Likely provider/official domain | 200 | https://lightandbellshealth.com/scholarships-and-grants | No obvious transport failure in this safe check |
| M. Kukoyi Foundation (MKF) Scholarship 2026 | `m-kukoyi-foundation-mkf-scholarship-2026-a06f2b07` | https://docs.google.com/forms/d/e/1FAIpQLSdBIS_G50LSI211HmPOXUFZG1UMtSgnzUZmpe47tVUuT4ufvQ/viewform | Third-party application platform | 200 after 2 redirect(s) | https://accounts.google.com/v3/signin/identifier | redirected; final destination may be login/closed form |
| Mastercard Foundation Scholars Program at Pan-Atlantic University | `mastercard-foundation-scholars-program-at-pan-atlantic-university-aaaaaaaa` | https://pau.edu.ng/mastercard-foundation/ | Unclear provenance; source review required | 200 | https://pau.edu.ng/mastercard-foundation/ | provenance not established from URL alone |
| Midwestern Oil & Gas Host Community Scholarship | `midwestern-oil-gas-host-community-scholarship-cccccccc` | https://candidate.scholastica.ng | Third-party application platform | 200 | https://candidate.scholastica.ng/ | No obvious transport failure in this safe check |
| MTN Foundation Science & Technology Scholarship | `mtn-foundation-science-technology-scholarship-aaaaaaaa` | https://www.mtn.ng/scholarships/ | Unclear provenance; source review required | 200 | https://www.mtn.ng/scholarships/ | provenance not established from URL alone |
| NDDC Local Post-Graduate (Master's Degree) Scholarship 2026/2027 | `nddc-local-post-graduate-master-s-degree-scholarship-2026-2027-107bccf4` | https://scholarship.nddc.gov.ng/login | Unclear provenance; source review required | 403 | https://scholarship.nddc.gov.ng/login | destination returned 403; access may be restricted; provenance not established from URL alone |
| NNPC - SNEPCo National University Scholarship 2026 | `nnpc-snepco-national-university-scholarship-2026-4a8ab8cd` | https://candidate.scholastica.ng/schemes/NNPCLTDSNEPCo26 | Third-party application platform | 200 | https://candidate.scholastica.ng/schemes/NNPCLTDSNEPCo26 | No obvious transport failure in this safe check |
| NNPC-Renaissance/TotalEnergies/AENR JV University Scholarship | `nnpc-renaissance-totalenergies-aenr-jv-university-scholarship-aaaaaaaa` | https://candidate.scholastica.ng | Third-party application platform | 200 | https://candidate.scholastica.ng/ | No obvious transport failure in this safe check |
| NNPC/Seplat JV National Undergraduate Scholarship | `nnpc-seplat-jv-national-undergraduate-scholarship-aaaaaaaa` | https://seplatgrowthacademy.com/scholarship/ | Likely provider/official domain | 200 | https://seplatgrowthacademy.com/scholarship/ | No obvious transport failure in this safe check |
| Osun Indigenes Scholarship 2026/2027 | `osun-indigenes-scholarship-2026-2027-aebb4bad` | https://osunindigenes.net/wp-content/uploads/2026/09/SCHOLARSHIP_FORM_YEAR-2026-27.pdf | Likely provider/official domain | 200 | https://osunindigenes.net/wp-content/uploads/2026/09/SCHOLARSHIP_FORM_YEAR-2026-27.pdf | No obvious transport failure in this safe check |
| Oyo State Scholarship Bursary Award 2026 | `oyo-state-scholarship-bursary-award-2026-b5b07e70` | https://app.bursary.oyostate.gov.ng/bursary/apply | Likely provider/official domain | 200 | https://app.bursary.oyostate.gov.ng/bursary/apply | No obvious transport failure in this safe check |
| Prince Ukeme Ukpong Mega Foundation 2026 Tertiary Scholarship | `prince-ukeme-ukpong-mega-foundation-2026-tertiary-scholarship-e1a3002d` | https://tinyurl.com/PUUMF2026 | Third-party application platform | 200 after 3 redirect(s) | https://docs.google.com/forms/d/e/1FAIpQLScne1KUZltRziF7w9cjt8u1fkNf_TVHwdnfvdFIR6UJbLSZFg/closedform | redirected; final destination may be login/closed form |
| Pro. Dr. Gabriel Olubunmi Fakeye Scholarship & Bursary Award 2027 | `pro-dr-gabriel-olubunmi-fakeye-scholarship-bursary-award-2027-bac0bbc9` | https://gofscholarship.candsyf.org/ | Likely provider/official domain | 200 | https://gofscholarship.candsyf.org/ | No obvious transport failure in this safe check |
| Project 100 for 100 STEM Scholarship | `project-100-for-100-stem-scholarship-7eae077d` | https://docs.google.com/forms/d/e/1FAIpQLSdIPjdJlAbyfkDEnxue9oV0BP339_v7S_Oj2BiveQJKQ_idWw/viewform | Third-party application platform | 200 after 1 redirect(s) | https://docs.google.com/forms/d/e/1FAIpQLSdIPjdJlAbyfkDEnxue9oV0BP339_v7S_Oj2BiveQJKQ_idWw/closedform | redirected; final destination may be login/closed form |
| PTDF In-Country Undergraduate Scholarship Scheme | `ptdf-in-country-undergraduate-scholarship-scheme-aaaaaaaa` | https://scholarship.ptdf.gov.ng | Unclear provenance; source review required | 200 | https://scholarship.ptdf.gov.ng/ | provenance not established from URL alone |
| Ruth Titilayo Polytechnic Scholarship 2027 | `ruth-titilayo-polytechnic-scholarship-2027` | https://ruthtitilayofoundation.org/scholarships/2027-polytechnic-scholarship-application/ | Likely provider/official domain | 200 | https://ruthtitilayofoundation.org/scholarships/2027-polytechnic-scholarship-application/ | No obvious transport failure in this safe check |
| Taiwo Bankole Prize 2026 | `taiwo-bankole-prize-2026-e88fd675` | https://taiwobankole.com/application-form/ | Likely provider/official domain | 200 | https://taiwobankole.com/application-form/ | No obvious transport failure in this safe check |
| TKA Solid Foundations 2027 Nigerian College/University Scholarship | `tka-solid-foundations-2027-nigerian-college-university-scholarship-18be3db9` | https://tkasolidfoundations.org/scholarships/2027-nigerian-scholarship | Likely provider/official domain | 200 | https://tkasolidfoundations.org/scholarships/2027-nigerian-scholarship | No obvious transport failure in this safe check |
| WAAW Foundation Scholarship 2026/2027 | `waaw-foundation-scholarship-2026-2027-b41bc410` | https://waawfoundation.org/scholarship/ | Likely provider/official domain | 200 | https://waawfoundation.org/scholarship/ | No obvious transport failure in this safe check |
| White Avenue Group ICON Scholarship for Undergraduates 2026 | `the-icon-scholarship-2026` | https://forms.gle/1nDZZxm3khrqJMMh9 | Third-party application platform | 200 after 3 redirect(s) | https://accounts.google.com/v3/signin/identifier | redirected; final destination may be login/closed form |
| WVA/MSD Veterinary Student Scholarship 2026 | `wva-msd-veterinary-student-scholarship-2026-123d6213` | https://app.smarterselect.com/programs/112061 | Third-party application platform | 200 after 1 redirect(s) | https://app.ui3.smarterselect.com/programs/112061-World-Veterinary-Association-Wva | redirected; final destination may be login/closed form |
| Yinka & Pelumi Foundation Undergraduate Scholarship 2026 | `yinka-pelumi-foundation-undergraduate-scholarship-2026-2e99eba7` | https://ypscholarshipfoundation.com/apply | Likely provider/official domain | 200 | https://ypscholarshipfoundation.com/apply | No obvious transport failure in this safe check |

**Specific transport exceptions:**

- **ASUU Scholarship Scheme for Indigent Students:** no `application_url`. The instructions describe a university ASUU branch process rather than a central portal; this needs an explicit “no central online portal” presentation, not an invented URL.
- **Decagon Undergraduate Honors Program:** `https://www.decagonfoundation.org/apply` returned HTTP 404. Recheck the provider’s current application route before displaying it as an application CTA.
- **NDDC Local Post-Graduate (Master's Degree) Scholarship 2026/2027:** `https://scholarship.nddc.gov.ng/login` returned HTTP 403. This may be access control rather than a broken link; source and portal status require editorial recheck.

## 6. Application Instruction Quality Assessment

The classification is deterministic and intentionally conservative: “actionable” requires a concrete action/route plus meaningful requirements or timing; “partial” contains some useful route/action but lacks enough detail; “missing” is null/empty. No record was rewritten.

- **26/44 (59.1%)** actionable and sufficiently detailed.
- **7/44 (15.9%)** partially informative.
- **11/44 (25.0%)** missing.

The 11 missing-instruction records are listed in the exception register: Florence Bamidele Makanjuola, JG Afrika, KPMG Seyi Bickersteth, Lagos State Scholarship Board, Mastercard Foundation at Pan-Atlantic University, Midwestern Oil & Gas, MTN Foundation, NNPC-Renaissance/TotalEnergies/AENR JV, NNPC/Seplat JV, Project 100 for 100 STEM, and PTDF In-Country Undergraduate.

A missing instruction field is not automatically a frontend defect. If the official source does not publish a reliable process, the correct editorial output may be “application instructions not stated by the provider; check the official page” rather than invented steps. Future policy should distinguish provider absence from Scholars research omission.

## 7. Structured Eligibility-Rule Assessment

### 7.1 Aggregate rule coverage

- **31/44 (70.5%)** verified scholarships have at least one `scholarship_rules` row.
- **13/44 (29.5%)** have no structured rules.
- **0 malformed rule rows** were detected under the structural check: no null/blank field, null operator, null value, or null gating value among returned rows.
- **0 records** had multiple `eq` rules on the same field in the structural check.
- **0 records** had a numerically impossible `gte`/`lte` interval under the structural check.

Rule-field coverage includes nationality (21 rows), institution type (13), financial need (10), discipline (9), GPA (9), year of study (12), state of origin (6), gender (4), age (4), JAMB score (4), WAEC credit count (4), English/Maths credit (3), and academic level (2).

### 7.2 Matching and public-explanation risks

The absence of structural contradiction does not prove semantic correctness. Several rule values use variants that require normalization before safe public explanation or reliable matching, including `Nigeria` versus `Nigerian`, `Female` versus `female`, and discipline labels that may not exactly match profile values. Two rule rows use `academic_level`; the inspected `profiles` schema contains `year_of_study` but no direct `academic_level` column. That may be intentionally derived, but it should not be presented as a directly captured profile field without confirming matching behavior.

The 13 records without structured rules are not necessarily defective. Some eligibility conditions may be sufficiently described in `description`, `how_to_apply`, or research evidence but cannot currently be matched automatically. The next editorial decision should classify each as one of: safely matchable, publicly explainable but manual, or insufficiently supported.

Private profile values and match results were not queried or included. Any public implementation should describe rule categories without revealing a visitor’s profile, score, or inferred eligibility.

## 8. Complete Record-Level Exception Register

The register below contains every verified scholarship with at least one audit exception. The safe identifier is the public slug; no private research notes or profile information are reproduced. “Severity” is record-level triage, not a claim about provider legitimacy.

| Scholarship | Public slug | Severity | Exceptions | Evidence | Recommended action |
|---|---|---|---|---|---|
| AMIR Fund Medical Scholarship Program 2026/2027 | `amir-fund-medical-scholarship-program-2026-2027-755a09d6` | Medium | past_deadline_without_last_cycle_closed_at | URL status 200 after 2 redirect(s); instructions Actionable and sufficiently detailed; deadline 2026-10-30; last verified 2026-10-08 08:20:09.210812+00 | Confirm lifecycle status and set the cycle-close state through normal editorial process. |
| ASUU Scholarship Scheme for Indigent Students | `asuu-scholarship-scheme-for-indigent-students-31cfebd0` | Critical | missing_application_url, missing_last_verified_at, past_deadline_without_last_cycle_closed_at | URL status Not checked (non-HTTP or missing); instructions Partially informative; deadline 2026-09-30; last verified missing | Confirm whether the provider has a current application route; otherwise label as no central portal and do not invent a URL. Confirm lifecycle status and set the cycle-close state through normal editorial process. Recheck the source and record a dated verification event. |
| Bode Amao Foundation Scholarship (BAF) | `bode-amao-foundation-scholarship-baf-215ee2c9` | Medium | missing_last_verified_at | URL status 200; instructions Actionable and sufficiently detailed; deadline 2026-12-31; last verified missing | Recheck the source and record a dated verification event. |
| CBIAS Graduate Scholarship | `cbias-graduate-scholarship-d015e1ba` | Medium | past_deadline_without_last_cycle_closed_at | URL status 200 after 2 redirect(s); instructions Partially informative; deadline 2026-09-30; last verified 2026-09-28 11:07:34.278386+00 | Confirm lifecycle status and set the cycle-close state through normal editorial process. |
| CBIAS Undergraduate Scholarship | `cbias-undergraduate-scholarship-a374fc5b` | Medium | past_deadline_without_last_cycle_closed_at | URL status 200 after 2 redirect(s); instructions Partially informative; deadline 2026-09-30; last verified 2026-09-28 11:07:34.278386+00 | Confirm lifecycle status and set the cycle-close state through normal editorial process. |
| Decagon Undergraduate Honors Program | `decagon-undergraduate-honors-program` | Critical | past_deadline_without_last_cycle_closed_at | URL status 404; instructions Actionable and sufficiently detailed; deadline 2026-10-15; last verified 2026-10-06 11:52:53.120101+00 | Recheck the official source and update or retire the destination after editorial verification. Confirm lifecycle status and set the cycle-close state through normal editorial process. |
| Ejiro M Ukiri International Scholarship Fund | `ejiro-m-ukiri-international-scholarship-fund-4c469077` | Medium | missing_deadline, missing_last_verified_at | URL status 200; instructions Partially informative; deadline missing; last verified missing | Confirm rolling/no-deadline status from the provider and document the evidence. Recheck the source and record a dated verification event. |
| FAJIM Medicare Foundation Scholarship 2026/2027 | `fajim-medicare-foundation-scholarship-2026-2027-86b94efd` | Medium | past_deadline_without_last_cycle_closed_at | URL status 200 after 1 redirect(s); instructions Actionable and sufficiently detailed; deadline 2026-10-11; last verified 2026-10-09 11:39:30.684367+00 | Confirm lifecycle status and set the cycle-close state through normal editorial process. |
| Florence Bamidele Makanjuola Scholarship | `florence-bamidele-makanjuola-scholarship-aaaaaaaa` | High | missing_how_to_apply, missing_last_verified_at | URL status 200; instructions Missing; deadline 2027-05-22; last verified missing | Research and store concise, source-backed application instructions or explicitly mark instructions unavailable. Recheck the source and record a dated verification event. |
| JG Afrika Bursary 2027 | `jg-afrika-bursary-2027-64790f70` | High | missing_how_to_apply, missing_deadline, missing_last_verified_at | URL status 200; instructions Missing; deadline missing; last verified missing | Research and store concise, source-backed application instructions or explicitly mark instructions unavailable. Confirm rolling/no-deadline status from the provider and document the evidence. Recheck the source and record a dated verification event. |
| KPMG Seyi Bickersteth Scholarship Programme | `kpmg-seyi-bickersteth-scholarship-programme-cccccccc` | High | missing_how_to_apply, missing_last_verified_at | URL status 200; instructions Missing; deadline 2027-08-13; last verified missing | Research and store concise, source-backed application instructions or explicitly mark instructions unavailable. Recheck the source and record a dated verification event. |
| Lagos State Scholarship Board Bursary & Scholarship Awards | `lagos-state-scholarship-board-bursary-scholarship-awards-d9c8ed08` | High | missing_how_to_apply, missing_last_verified_at | URL status 200; instructions Missing; deadline 2027-03-06; last verified missing | Research and store concise, source-backed application instructions or explicitly mark instructions unavailable. Recheck the source and record a dated verification event. |
| Liberty Career Academy (LCA) Scholarship Program 2026 | `liberty-career-academy-lca-scholarship-program-2026-fabbe4a8` | Medium | past_deadline_without_last_cycle_closed_at | URL status 200; instructions Actionable and sufficiently detailed; deadline 2026-11-03; last verified 2026-10-23 11:26:01.009613+00 | Confirm lifecycle status and set the cycle-close state through normal editorial process. |
| Light and Bells Health Foundation Scholarship 2026 | `light-and-bells-health-foundation-scholarship-2026-e93e25b7` | Medium | missing_last_verified_at, past_deadline_without_last_cycle_closed_at | URL status 200; instructions Actionable and sufficiently detailed; deadline 2026-10-02; last verified missing | Confirm lifecycle status and set the cycle-close state through normal editorial process. Recheck the source and record a dated verification event. |
| Mastercard Foundation Scholars Program at Pan-Atlantic University | `mastercard-foundation-scholars-program-at-pan-atlantic-university-aaaaaaaa` | High | missing_how_to_apply, missing_last_verified_at | URL status 200; instructions Missing; deadline 2027-05-22; last verified missing | Research and store concise, source-backed application instructions or explicitly mark instructions unavailable. Recheck the source and record a dated verification event. |
| Midwestern Oil & Gas Host Community Scholarship | `midwestern-oil-gas-host-community-scholarship-cccccccc` | High | missing_how_to_apply, missing_last_verified_at | URL status 200; instructions Missing; deadline 2027-03-19; last verified missing | Research and store concise, source-backed application instructions or explicitly mark instructions unavailable. Recheck the source and record a dated verification event. |
| MTN Foundation Science & Technology Scholarship | `mtn-foundation-science-technology-scholarship-aaaaaaaa` | High | missing_how_to_apply, missing_last_verified_at | URL status 200; instructions Missing; deadline 2027-05-31; last verified missing | Research and store concise, source-backed application instructions or explicitly mark instructions unavailable. Recheck the source and record a dated verification event. |
| NNPC-Renaissance/TotalEnergies/AENR JV University Scholarship | `nnpc-renaissance-totalenergies-aenr-jv-university-scholarship-aaaaaaaa` | High | missing_how_to_apply, missing_last_verified_at | URL status 200; instructions Missing; deadline 2027-05-31; last verified missing | Research and store concise, source-backed application instructions or explicitly mark instructions unavailable. Recheck the source and record a dated verification event. |
| NNPC/Seplat JV National Undergraduate Scholarship | `nnpc-seplat-jv-national-undergraduate-scholarship-aaaaaaaa` | High | missing_how_to_apply, missing_last_verified_at | URL status 200; instructions Missing; deadline 2027-03-13; last verified missing | Research and store concise, source-backed application instructions or explicitly mark instructions unavailable. Recheck the source and record a dated verification event. |
| Osun Indigenes Scholarship 2026/2027 | `osun-indigenes-scholarship-2026-2027-aebb4bad` | Medium | past_deadline_without_last_cycle_closed_at | URL status 200; instructions Actionable and sufficiently detailed; deadline 2026-10-22; last verified 2026-10-14 08:55:10.908083+00 | Confirm lifecycle status and set the cycle-close state through normal editorial process. |
| Oyo State Scholarship Bursary Award 2026 | `oyo-state-scholarship-bursary-award-2026-b5b07e70` | Medium | past_deadline_without_last_cycle_closed_at | URL status 200; instructions Actionable and sufficiently detailed; deadline 2026-11-02; last verified 2026-10-15 21:03:59.334829+00 | Confirm lifecycle status and set the cycle-close state through normal editorial process. |
| Prince Ukeme Ukpong Mega Foundation 2026 Tertiary Scholarship | `prince-ukeme-ukpong-mega-foundation-2026-tertiary-scholarship-e1a3002d` | Medium | missing_deadline | URL status 200 after 3 redirect(s); instructions Actionable and sufficiently detailed; deadline missing; last verified 2026-10-14 08:55:26.380845+00 | Confirm rolling/no-deadline status from the provider and document the evidence. |
| Project 100 for 100 STEM Scholarship | `project-100-for-100-stem-scholarship-7eae077d` | High | missing_how_to_apply, missing_last_verified_at, past_deadline_without_last_cycle_closed_at | URL status 200 after 1 redirect(s); instructions Missing; deadline 2026-09-25; last verified missing | Research and store concise, source-backed application instructions or explicitly mark instructions unavailable. Confirm lifecycle status and set the cycle-close state through normal editorial process. Recheck the source and record a dated verification event. |
| PTDF In-Country Undergraduate Scholarship Scheme | `ptdf-in-country-undergraduate-scholarship-scheme-aaaaaaaa` | High | missing_how_to_apply, missing_last_verified_at | URL status 200; instructions Missing; deadline 2027-05-29; last verified missing | Research and store concise, source-backed application instructions or explicitly mark instructions unavailable. Recheck the source and record a dated verification event. |
| Ruth Titilayo Polytechnic Scholarship 2027 | `ruth-titilayo-polytechnic-scholarship-2027` | Medium | past_deadline_without_last_cycle_closed_at | URL status 200; instructions Partially informative; deadline 2026-10-31; last verified 2026-10-12 10:58:47.56099+00 | Confirm lifecycle status and set the cycle-close state through normal editorial process. |
| Taiwo Bankole Prize 2026 | `taiwo-bankole-prize-2026-e88fd675` | Medium | past_deadline_without_last_cycle_closed_at | URL status 200; instructions Actionable and sufficiently detailed; deadline 2026-11-06; last verified 2026-10-16 17:01:31.888782+00 | Confirm lifecycle status and set the cycle-close state through normal editorial process. |
| WAAW Foundation Scholarship 2026/2027 | `waaw-foundation-scholarship-2026-2027-b41bc410` | Medium | missing_deadline | URL status 200; instructions Partially informative; deadline missing; last verified 2026-10-28 11:41:57.216594+00 | Confirm rolling/no-deadline status from the provider and document the evidence. |
| WVA/MSD Veterinary Student Scholarship 2026 | `wva-msd-veterinary-student-scholarship-2026-123d6213` | Medium | past_deadline_without_last_cycle_closed_at | URL status 200 after 1 redirect(s); instructions Actionable and sufficiently detailed; deadline 2026-10-15; last verified 2026-10-09 11:47:57.929991+00 | Confirm lifecycle status and set the cycle-close state through normal editorial process. |
| Yinka & Pelumi Foundation Undergraduate Scholarship 2026 | `yinka-pelumi-foundation-undergraduate-scholarship-2026-2e99eba7` | Medium | past_deadline_without_last_cycle_closed_at | URL status 200; instructions Actionable and sufficiently detailed; deadline 2026-10-25; last verified 2026-10-14 08:39:58.337468+00 | Confirm lifecycle status and set the cycle-close state through normal editorial process. |

**Severity counts:** 2 Critical records, 12 High records, and 16 Medium records. These counts are unique records under the definitions below; one record can have several underlying defects.

- **Critical:** missing application destination or confirmed HTTP 404 destination.
- **High:** HTTP 403/access-gated destination or missing application instructions on a verified record.
- **Medium:** missing freshness date, missing deadline requiring confirmation, or past-deadline lifecycle state without `last_cycle_closed_at`.
- **Low:** no unique Low record was created by the present checks; the next editorial pass may downgrade or upgrade records after source review.

The status exceptions should be reviewed carefully. A past deadline without `last_cycle_closed_at` is not necessarily a bad record because the application code can already infer closure from the deadline; it is a lifecycle-data consistency issue that affects freshness and future-cycle handling.

## 9. Database-to-Public-Template Comparison

### 9.1 Scholarship template

**Source:** `app/scholarship/[slug]/page.tsx`, audited current source [1].

The scholarship page selects:

```text
id, slug, title, provider_name, description, amount, deadline,
last_cycle_closed_at, level, discipline, verified, last_verified_at
```

It renders or uses:

- title;
- provider name;
- amount;
- deadline;
- closed status based on deadline/cycle data;
- level;
- discipline;
- last verified date or a generic verified message;
- description;
- a generic eligibility/matching explanation;
- profile signup/login CTA;
- WebPage and BreadcrumbList JSON-LD.

It does **not** select or render:

- `application_url`;
- `how_to_apply`;
- structured `scholarship_rules` summaries;
- `opens_at` as a public opening label;
- `awards_available`;
- competitiveness fields;
- source/provenance text from `research_notes`.

The scholarship template’s omission of `application_url` and `how_to_apply` is a confirmed frontend presentation gap. Both columns already exist in the database, so exposing them does not require a schema migration. It does require product/editorial approval for link labeling, closed-cycle behavior, safe external-link attributes, and the handling of missing or stale values.

### 9.2 Opportunity template

**Source:** `app/opportunity/[slug]/page.tsx`, audited current source [2].

The opportunity page selects:

```text
id, slug, type, title, provider_name, description, duration, location,
compensation, discipline, deadline, application_url, how_to_apply, verified
```

It renders:

- type and provider;
- title;
- compensation;
- deadline or rolling/no-deadline label;
- location and discipline;
- description;
- duration;
- `how_to_apply` inside an Application details panel;
- `application_url` as “Visit the official application page” for open records or a historical-details link for closed records;
- save/track CTA;
- WebPage and BreadcrumbList JSON-LD.

This provides the smallest safe presentation model for the scholarship page: select existing verified fields, add a status-aware Application details section, and render only populated values. No schema change is needed for the core application-information gap.

### 9.3 Smallest safe implementation scope

The smallest safe future implementation, after founder approval, is:

1. Add `application_url` and `how_to_apply` to the scholarship public select list and TypeScript type.
2. Add a status-aware Application details block modeled on the opportunity template.
3. Render the outbound link only when populated, with an accurate label for open versus closed records.
4. Preserve the generic matching CTA and do not expose private profile data or match scores.
5. Add tests for missing URL/instructions, closed records, and safe escaping/URL rendering.

This scope should not include a schema migration, bulk data rewrite, automatic URL “repair,” or an assumption that every `verified = true` record is currently accurate.

## 10. Critical Risks and Privacy Considerations

The largest trust risk is not description length. It is a user clicking a missing, broken, stale, or access-gated application destination after Scholars presents the listing as verified. The second risk is stale lifecycle information: 21 verified records have missing or past deadlines under the audit filter, and 15 lack `last_verified_at`.

Structured rules also require care. Rules may be technically well formed but use inconsistent labels or fields that are not direct profile columns. Public pages should not reveal private student attributes, infer a visitor’s gender, financial need, nationality, institution, GPA, or other profile values, and should not expose internal match scores.

Application links can contain Google Forms, Jotform, Scholastica, SmarterSelect, or other third-party platforms. A third-party platform is not automatically unsafe or unofficial. The correct display should identify the route accurately and rely on source-backed provenance; it should not imply that Scholars operates or guarantees the external platform.

The safe link check did not authenticate, submit, upload, download, or interact with forms. HTTP 200 after redirect was recorded as transport success, not application availability or open status.

## 11. Recommended Remediation Priorities

### Data remediation

1. Recheck the two Critical records first: ASUU’s missing central URL/process status and Decagon’s 404 destination.
2. Recheck NDDC’s 403 portal and distinguish access control from a broken route.
3. Recheck every missing `how_to_apply` record, beginning with records that are active or upcoming.
4. Resolve the 15 missing `last_verified_at` values through a dated source-check workflow; do not populate dates without a real check.
5. Reconcile past deadlines and `last_cycle_closed_at`, especially where future-cycle or recurring-programme behavior is intended.
6. Classify null amounts as unknown, not applicable, or not published; the current text column cannot distinguish these states.
7. Normalize rule value vocabulary and determine how `academic_level` is derived or matched.

### Frontend remediation

1. After approval, expose existing scholarship `application_url` and `how_to_apply` fields using the opportunity template’s status-aware pattern.
2. Show the source/application state honestly: official page, third-party application platform, provider email route, or source requiring confirmation.
3. Display structured, source-backed eligibility summaries without exposing private profile values or match scores.
4. Keep closed records available for history but make their closed status and historical-link label unmistakable.

### Schema remediation

No schema migration is currently justified for the primary gap. `application_url`, `how_to_apply`, `amount`, `deadline`, `level`, `discipline`, `last_verified_at`, and matching-rule relationships already exist.

A future schema proposal may be justified only after editorial review if Scholars needs separate normalized fields for source URL, source-checked timestamp, required documents, award-coverage type, country restrictions, or application-status provenance. That would be a separate decision, not part of the smallest safe implementation.

### Editorial policy

Define a minimum verified-listing standard with required distinctions between: provider-published fact, Scholars interpretation, unknown/not published, and manual applicant confirmation. A record should not receive a timeless “verified” impression when its source check is stale or its application route is broken.

## 12. Explicit Limitations and Unavailable Evidence

- The `verified` boolean was used to define the audit inventory but was not treated as independent proof of factual accuracy.
- The description completeness threshold of 80 characters is an operational audit rule, not a universal quality standard. All 44 records passed it, but usefulness and factual accuracy still require human review.
- Official provenance was not proven from URLs alone. The URL classification is conservative and heuristic.
- Safe HTTP checks were performed without authentication or form interaction. Login redirects, closed forms, robots restrictions, and provider-side conditional access can make a 200 response non-actionable.
- The report does not reproduce research notes or private data, so some source-by-source discrepancy reasoning is intentionally omitted.
- Rule contradiction checks were structural: missing values, duplicate equality fields, and impossible numeric ranges. Semantic contradictions and provider-source disagreements require editorial comparison.
- No Search Console, analytics, backlink, Core Web Vitals, or conversion data was needed for this completeness audit and none is claimed.
- No application source, database, deployment, configuration, or production content was modified.

## 13. Evidence References

[1] Scholarship public template: https://github.com/ImperioKDB/Scholars/blob/67070cbbf93c31327c1bf311af631ad24a01a1a3/app/scholarship/%5Bslug%5D/page.tsx  
[2] Opportunity public template: https://github.com/ImperioKDB/Scholars/blob/67070cbbf93c31327c1bf311af631ad24a01a1a3/app/opportunity/%5Bslug%5D/page.tsx  
[3] Status predicate: `lib/dates.ts`, especially `isClosedListing`; source repository at the audited commit.  
[4] Active discovery predicate: `lib/discovery.ts`, especially `isCurrentlyOpen`; source repository at the audited commit.  
[5] Live production domain: https://www.scholars.com.ng  
[6] Current scholarship sitemap inventory: https://www.scholars.com.ng/sitemap.xml  
[7] Current production robots: https://www.scholars.com.ng/robots.txt  
[8] Prior SEO audit report: https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_CORRECTIVE_SEO_GROWTH_AUDIT_AND_EXECUTION_PLAN_2026-11-06.md  
[9] Database project inspected read-only: Supabase project `cmdglabohpttgfofcmqc`; queries selected only scholarship content fields and aggregate rule metadata.  
[10] Repository commit audited: https://github.com/ImperioKDB/Scholars/tree/67070cbbf93c31327c1bf311af631ad24a01a1a3
