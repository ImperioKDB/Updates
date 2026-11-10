# Scholars PR #28 Production Acceptance Verification

**Audit date:** 2026-11-07 (Africa/Lagos)
**Scope:** Read-only production acceptance verification of the public scholarship application-details feature merged by PR #28.
**Production domain:** [https://www.scholars.com.ng](https://www.scholars.com.ng)
**Merged PR:** [ImperioKDB/Scholars #28](https://github.com/ImperioKDB/Scholars/pull/28)

## 1. Executive Summary

**Final status: ACCEPTED WITH LIMITATIONS.** The production deployment is confirmed to use the expected PR #28 merge commit and is Ready with `www.scholars.com.ng` assigned as a production alias. The live public pages for four real, verified records passed the applicable presentation checks: both instructions and URL, URL only, instructions only, and closed listing with a URL. Link labels, the closed notice, public access, and signup/login links were observed as expected. The URL allowlist and whitespace handling are also supported by the merged source and automated tests.

Case D could not be tested against a live record: a read-only query found no verified public scholarship with both application fields null or blank. A second query found 11 verified records with blank instructions and populated URLs; all 11 used HTTPS and had a basic URL shape, so none supplied a URL that was unusable under the tested scheme/shape checks. No record was created or altered. Consequently, the audit does not claim live-page verification of the empty-section behavior, although the merged helper tests cover a whitespace-only instruction and unsafe URL as yielding no usable details, and the page conditionally renders the section only when at least one usable field exists.

No production, application code, configuration, schema, or database changes were made during this audit. External application destinations were not opened or submitted to; their rendered anchor destinations were checked on the Scholars pages.

## 2. Merge Commit Verification

**Verified facts**

- PR #28 is merged, not merely closed. GitHub reports merge time `2026-11-07T13:20:20Z` and merge commit [`cf3682ce35912df7b9b9352193630fc404427c7c`](https://github.com/ImperioKDB/Scholars/commit/cf3682ce35912df7b9b9352193630fc404427c7c).
- The merge commit's first parent is `41573f5ec2985851ba118e8b39a47f9c54532302`.
- The PR changes exactly three files: `app/scholarship/[slug]/page.tsx`, `lib/public-application.ts`, and `lib/public-application.test.ts` ([changed-files view](https://github.com/ImperioKDB/Scholars/pull/28/files)). No migration, schema, RLS, or database files are in the PR diff.
- GitHub Actions run [42376498693](https://github.com/ImperioKDB/Scholars/actions/runs/42376498693) ran against the merge commit and completed successfully. Its `npm test` and `npm run build` steps passed.

**Inference:** The successful merge-commit CI run and the exact-commit source inspection support the implementation identity; CI alone is not treated as proof of production behavior.

## 3. Production Deployment Verification

**Verified facts from Vercel deployment metadata**

- Deployment ID: `dpl_DDLQWb52e9G5jEei3ouNfJWok4BA` ([deployment details](https://vercel.com/imperiokdbs-projects/scholars/dpl_DDLQWb52e9G5jEei3ouNfJWok4BA)).
- Target: `production`; state: **READY**.
- Source branch: `main`; source SHA: `cf3682ce35912df7b9b9352193630fc404427c7c`, exactly the expected merge commit.
- Production aliases assigned to the deployment include `www.scholars.com.ng`, `scholars.com.ng`, and the project's production Vercel aliases.
- Created: `2026-11-07T13:20:22.848Z` (**14:20:22.848 Africa/Lagos**). Ready: `2026-11-07T13:21:32.591Z` (**14:21:32.591 Africa/Lagos**).
- A public request to the Carewave detail URL on `www.scholars.com.ng` returned HTTP 200 and contained the scholarship title, `Application details`, the open link label, and the expected Carewave application destination. The rendered page was also inspected in the public browser.

**Observation and qualification:** The generated deployment's `*.vercel.app` URL redirects to Vercel SSO. The production custom domain is not behind that SSO gate; its Vercel alias assignment and successful live-domain response establish the production route used for this audit. The generated SSO-protected URL was not used as evidence of student-facing behavior.

**Conclusion:** The production deployment corresponds to the expected merge commit, and Vercel metadata plus the live custom-domain response confirm the production alias is serving the deployed site.

## 4. Representative Scholarship Records

Records below were selected from a read-only query of `public.scholarships`, restricted to verified rows and the minimum public fields needed for this audit. Open/closed status is assessed as of 2026-11-07 using the application's existing rule: a listing is closed when its deadline is before the current UTC date or `last_cycle_closed_at` is on/before that date. URLs are reported by scheme and, in live test evidence, by destination.

| Case | Scholarship | Slug | Verified | Status on audit date | Application URL populated / scheme | Instructions populated |
|---|---|---|---|---|---|---|
| A | Carewave ASPIRE Scholarship Programme (CASP) 2026 | `carewave-aspire-scholarship-programme-casp-32c773ba` | Yes | Open; deadline 2026-11-09 | Yes / `https:` | Yes |
| B | JG Afrika Bursary 2027 | `jg-afrika-bursary-2027-64790f70` | Yes | Open; no deadline or closed-cycle marker | Yes / `https:` | No (null) |
| C | ASUU Scholarship Scheme for Indigent Students | `asuu-scholarship-scheme-for-indigent-students-31cfebd0` | Yes | Closed; deadline 2026-09-30 | No | Yes |
| D | No suitable verified record found | — | — | — | — | — |
| E | 2025 Grooming Centre University Grant Scheme | `2025-grooming-centre-university-grant-scheme` | Yes | Closed; deadline and last-cycle date 2025-10-10 | Yes / `https:` | Yes |

No private profile data, matching data, internal research notes, or student records were selected or included.

## 5. Live Production Test Results

All page tests used the production `www.scholars.com.ng` domain, not a preview deployment.

| Case | Live page | Expected result | Actual result / evidence | Status |
|---|---|---|---|---|
| A — URL and instructions | [Carewave ASPIRE 2026](https://www.scholars.com.ng/scholarship/carewave-aspire-scholarship-programme-casp-32c773ba) | Application details section, meaningful instructions, clickable correct destination, open-listing label. | Page rendered the section and instructions; anchor label was “Open application destination” and its href was `https://portal.carewavefoundation.org/scholarships/apply?scholarshipId=SCH-2026-946543`. The page showed the title, description, deadline, and no closed notice. Signup and login links were present. | **PASS** |
| B — URL only | [JG Afrika Bursary 2027](https://www.scholars.com.ng/scholarship/jg-afrika-bursary-2027-64790f70) | Application details section and clickable destination; no empty instructions paragraph or placeholder. | Section rendered with only the anchor “Open application destination” to `https://www.jgafrika.com/careers-offered-at-jg-afrika/bursary/`. No instructions paragraph or placeholder appeared. Title and description rendered; signup and login links were present. | **PASS** |
| C — Instructions only | [ASUU Scholarship Scheme](https://www.scholars.com.ng/scholarship/asuu-scholarship-scheme-for-indigent-students-31cfebd0) | Application details and instructions, no empty/broken link; closed notice remains if applicable. | Instructions appeared in Application details with no application-link anchor. The page showed “Applications closed” and “This page is kept for historical reference. It is not an active application opportunity.” Title, description, deadline, signup and login links were present. | **PASS** |
| D — Neither field usable | No verified record available. | Application details section absent. | **BLOCKED / NOT TESTABLE WITH CURRENT DATA.** No verified record had both fields null or blank. A separate scan of the 11 verified records with blank instructions and a populated URL found only HTTPS destinations with a basic valid URL shape; no candidate had an unsupported scheme or obvious malformed URL to make both fields unusable. No live record was modified or synthesized. The helper test covers whitespace-only instructions plus an unsafe URL as no usable details; the page's conditional rendering is visible in the source, but this is not a substitute for a real live record. | **BLOCKED** |
| E — Closed with valid URL | [2025 Grooming Centre University Grant Scheme](https://www.scholars.com.ng/scholarship/2025-grooming-centre-university-grant-scheme) | Closed notice, historical label, and no implication the application is currently accepting submissions. | Page displayed “Applications closed” and explicitly said it is not an active application opportunity. Application details included the historical note; the anchor label was “View application destination for historical information” and href was `https://groominggrant.org/`. Title, description, deadline, signup and login links were present. | **PASS** |

The public scholarship index also loaded at [scholarships-in-nigeria](https://www.scholars.com.ng/scholarships-in-nigeria) and exposed public detail links without requiring login.

## 6. URL Safety Verification

**Verified in merged source and tests**

- [`lib/public-application.ts`](https://github.com/ImperioKDB/Scholars/blob/cf3682ce35912df7b9b9352193630fc404427c7c/lib/public-application.ts#L1-L47) allows only `http:`, `https:`, and `mailto:` after parsing with `URL`; empty, malformed, and unsupported values return `null`.
- The production page renders an application anchor only when the helper returns a usable URL ([page source, lines 127–130 and 183–198](https://github.com/ImperioKDB/Scholars/blob/cf3682ce35912df7b9b9352193630fc404427c7c/app/scholarship/%5Bslug%5D/page.tsx#L127-L198)).
- [`lib/public-application.test.ts`](https://github.com/ImperioKDB/Scholars/blob/cf3682ce35912df7b9b9352193630fc404427c7c/lib/public-application.test.ts#L4-L63) covers valid HTTP, HTTPS, and mailto; rejects `javascript:`, `data:`, `ftp:`, and malformed URLs; tests open and closed labels; and treats whitespace-only instructions as missing.
- The same tests exercise instructions-only, URL-only, both-fields, and neither-usable helper outcomes.

No unsafe URL was written to production data. This safety conclusion is based on source and automated tests, not on injecting test data into the live site.

## 7. Regression Test Results

| Check | Evidence | Result |
|---|---|---|
| Scholarship titles and public descriptions render | Cases A, B, C, and E live pages | **PASS** |
| Deadline/open/closed indicators remain coherent | A showed its Nov 9, 2026 deadline without a closed notice; C and E displayed the closed notice and their expired deadlines | **PASS** |
| Public detail pages accessible without login | Direct public production navigation to all four pages loaded their contents without login redirect | **PASS** |
| Signup/login navigation preserved | Signup and login links were rendered on each inspected detail page | **PASS** |
| No private matching/profile data exposed by this feature | Merged page selects public scholarship fields only; visible copy says eligibility is not shown yet and no match score is rendered | **PASS** |
| No schema or migration change in PR #28 | Exact parent-to-merge diff contains only the detail page and two helper/test files; no migration/schema path changed | **PASS** |
| No production or database changes made during this audit | All record queries were SELECT-only; no writes, migrations, or deployment actions were performed | **PASS** |
| Empty-section behavior for a real record with neither field usable | No such verified record exists in current data | **BLOCKED** |

The page's public select list does not include `research_notes`, profile rows, or match-score fields. Public routes were accessed unauthenticated; no student information was queried.

## 8. Blocked or Untestable Cases

- **Case D:** Not testable with current verified public scholarship data because no record has both `application_url` and `how_to_apply` missing/blank. Per instruction, no record was created or altered. The unit-level helper behavior for a whitespace-only instruction plus unsafe URL passed in the existing test suite, but live page integration for a genuine empty-record case remains unverified.
- **External application workflows:** Destination anchors and exact hrefs were inspected, but the external provider sites/forms were not opened, and no application was submitted. Their current availability and acceptance of submissions are outside this audit's verified scope.
- **Generated Vercel URL:** It redirects to SSO. Production behavior was verified via the public custom domain and Vercel production alias metadata instead.

## 9. Defects and Risk Assessment

**Defects found:** None in the testable feature behavior.

**Residual risk:** Case D has no live data-backed test. Existing unit tests plus the source-level render condition reduce, but do not eliminate, that coverage gap. External provider links may change or become unavailable after this audit; no claim is made about external form uptime or application eligibility.

**Observations versus inference:**

- **Verified facts:** Merge SHA, Vercel production target/state/aliases, HTTP 200 and expected content on the public domain, database field states for the selected verified records, and the observed rendered page content/links.
- **Observation:** The generated deployment URL is SSO-protected; the public custom domain is not.
- **Inference:** Since Vercel lists the custom domain as an alias of the Ready production deployment and the domain returns the expected deployed application content, the production domain is serving the deployment associated with the expected merge SHA.
- **Untested assumptions:** External provider destination availability; behavior for a real verified record with both application fields absent (none exists in the inspected data).

## 10. Final Acceptance Decision

### ACCEPTED WITH LIMITATIONS

The expected merge commit is confirmed on a Ready production deployment, the production domain is assigned to that deployment and serves the expected public feature behavior, and all four available live cases pass. The URL-scheme protections and whitespace normalization are supported by the exact-commit implementation and tests. No blocking regression or privacy issue was found.

The decision is limited because Case D cannot be exercised against a real verified record in the current dataset. It is therefore not reported as a fully passing live test. No production, database, code, configuration, or deployment changes were made as part of this verification.
