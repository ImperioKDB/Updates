# Scholars PR #27 Final Validation and Merge Report

**Date:** 2026-11-06  
**Repository:** https://github.com/ImperioKDB/Scholars  
**Pull request:** [#27 — feat: implement approved technical SEO remediation](https://github.com/ImperioKDB/Scholars/pull/27)  
**Final branch:** `seo/remediation-2026-11`  
**Final reviewed branch HEAD:** `b5c4252094d35366b6c40aa88a29a182ca4e5932`  
**Merge method:** Squash merge  
**Merge commit:** `67070cbbf93c31327c1bf311af631ad24a01a1a3`  
**Merged at:** 2026-11-06T19:19:12Z

## 1. Final status

PR #27 was independently validated and merged into `main` only after the final branch commit passed local checks, GitHub Actions, and the Vercel preview check. The final branch HEAD was `b5c4252`, not an earlier corrective commit.

The post-merge GitHub Actions run also passed on the merge commit. No production database mutation, schema change, authentication change, robots change, or unrelated production modification was made.

## 2. Files changed in the final corrective pass

Only two files changed after the prior corrective commit `7d12350`:

- `.github/workflows/ci.yml` — corrected comments to explain that CI runs type checking, tests, and a production build; placeholder public Supabase values are used only for build-time client initialization; request-time data routes do not require production database availability during the build; and no production credentials are required in CI.
- `lib/sitemap-data.test.ts` — renamed the 501-record test and clarified its comment so it does not claim to test deduplication. The assertion now verifies that all unique fixture rows are retained in order.

The existing dynamic sitemap implementation was preserved, including `dynamic = "force-dynamic"`, 500-row pagination, verified and non-null-slug filters, stable ordering, fail-closed errors, historical closed-record inclusion, canonical `www` URL generation, and postgraduate inclusion.

## 3. Database slug uniqueness verification

The current repository contains the required unique indexes in:

`supabase/migrations/0031_add_public_catalog_slugs.sql`

```sql
create unique index if not exists scholarships_slug_key on public.scholarships (slug);
create unique index if not exists opportunities_slug_key on public.opportunities (slug);
```

The full migration directory was inspected. No later migration contains a reference that drops, weakens, or removes either slug uniqueness constraint. No redundant application-level deduplication and no new migration were added.

A separate schema test was not added because the repository has no database-test harness connected to an isolated schema, and a test that searches migration text would be brittle rather than a true schema-level regression test. The index verification above is direct repository evidence.

## 4. Validation evidence for final branch HEAD `b5c4252`

| Check | Result | Evidence |
|---|---|---|
| TypeScript | Passed | `npx tsc --noEmit` completed successfully. |
| Full test suite | Passed | 17 test files and 69 tests passed. |
| Sitemap-focused tests | Passed | 3 sitemap data-reader tests passed, including 501 records across two batches, stable ranges, both sources, filter assertions, postgraduate/closed slugs, and fail-closed errors. |
| Production build | Passed | `npm run build` passed with the CI-equivalent placeholder public Supabase values. |
| Sitemap route architecture | Passed | Build output classified `/sitemap.xml` as dynamic/server-rendered. |
| GitHub Actions for final branch HEAD | Passed | [Run 42278297803](https://github.com/ImperioKDB/Scholars/actions/runs/42278297803) completed successfully for `b5c4252`. |
| PR checks for final branch HEAD | Passed | Vercel, Vercel Preview Comments, and `ci/build` were all successful. |
| PR merge state | Passed | GitHub reported the PR clean and mergeable before merge. |

The test suite intentionally logs a simulated Supabase error in the fail-closed test; the test itself passed and asserted that the error propagates.

## 5. Vercel preview validation

The final PR Vercel check was successful, and the preview deployment was reported deployment-ready for the corrective branch before merge. The preview hostname was protected by Vercel SSO, so anonymous fetching of `/sitemap.xml` was not possible. An unauthenticated request returned HTTP 302 to the Vercel SSO endpoint with `x-robots-tag: noindex`; no authentication bypass was attempted.

Therefore, preview sitemap XML content is **not independently verified** from an unauthenticated request. The successful Vercel check and deployment-ready status are verified; the protected preview endpoint’s generated XML is not claimed as inspected.

## 6. Production sitemap verification

After merge, the public production endpoint was requested:

`https://www.scholars.com.ng/sitemap.xml`

Observed response:

- HTTP status: `200`
- Content type: `application/xml`
- XML parsing: valid
- URL count: 57
- Duplicate URLs: 0
- Canonical-host mismatches: 0
- Protected plural route matches: 0

The production response was successfully validated as a live sitemap. Because the response contained the prior 57-URL inventory and Vercel post-merge deployment status could not be queried after the Vercel connector session required reauthentication, this report does not claim that the production response had already been replaced by the merge deployment at the moment of testing.

## 7. Merge and post-merge status

PR #27 is confirmed merged:

- PR state: `MERGED`
- Final reviewed head: `b5c4252094d35366b6c40aa88a29a182ca4e5932`
- Merge commit: `67070cbbf93c31327c1bf311af631ad24a01a1a3`
- `main` points to: `67070cbbf93c31327c1bf311af631ad24a01a1a3`

The post-merge main-branch CI run passed:

- [Run 42278572377](https://github.com/ImperioKDB/Scholars/actions/runs/42278572377)
- Commit: `67070cbbf93c31327c1bf311af631ad24a01a1a3`
- Result: success

The run emitted only existing infrastructure annotations about the future `ubuntu-latest` image migration and Node.js action runtime notices; no build or test failure occurred.

## 8. Production deployment status

A post-merge Vercel production deployment was not independently confirmed because the Vercel connector required reauthentication when queried after the merge. No production deployment was manually created or promoted by this task.

The public production sitemap was reachable and valid as described above. Remaining operational verification is to inspect the Vercel project’s authenticated deployment history and confirm that the production deployment corresponding to merge commit `67070cbbf93c31327c1bf311af631ad24a01a1a3` completed successfully and is serving the final dynamic sitemap implementation.

## 9. Remaining risks and follow-up

The main remaining risk is deployment provenance: the live production sitemap was valid, but its 57-URL response was not sufficient to prove that the post-merge Vercel deployment had already propagated. The owner should verify the authenticated Vercel production deployment for the merge commit and, once confirmed, repeat the production sitemap checks for closed historical and postgraduate URLs.

No production data, Supabase schema, permissions, secrets, or protected-route rules were changed during this final pass.
