# Scholars PR #32 — Production Deployment Report

**Reporting repository:** ImperioKDB/Updates (public)
**Report path:** reports/scholars/2026-11-13-sitemap-integrity-production-deployment.md
**Source repository:** ImperioKDB/Scholars
**PR:** #32 — https://github.com/ImperioKDB/Scholars/pull/32
**Branch:** fix/sitemap-public-data-integrity
**Production domain:** https://scholars.com.ng
**Date:** 13 November 2026

---

## 1. Executive Summary

PR #32 ("fix(seo): restore sitemap integrity, Resource Centre coverage, and correct lastModified") was merged into `main` and deployed to production. The production sitemap at https://www.scholars.com.ng/sitemap.xml is live, returns valid XML, and contains scholarship, opportunity, Resource Centre article, and category URLs generated from the approved public catalogue views. All production smoke tests passed.

---

## 2. PR #32 Merge Confirmation

- **PR URL:** https://github.com/ImperioKDB/Scholars/pull/32
- **PR state:** MERGED (closed: true)
- **Merge commit SHA:** ef7e97bb0153d602f5ac412bc4b5e3b167d383d0
- **Merge timestamp:** 2026-11-13T21:42:55Z
- **Final source commit SHA:** 8b6de63162d52d8d950af52acd608ec95e54578d
- **Merge method:** GitHub merge (merge commit `ef7e97b`)
- **Merge strategy:** Standard GitHub merge (no force-push, no history rewrite)

---

## 3. Production Deployment

- **Vercel production deployment URL:** https://scholars-cevxdv8op-imperiokdbs-projects.vercel.app
- **Production domain:** https://scholars.com.ng
- **Deployment SHA:** ef7e97bb0153d602f5ac412bc4b5e3b167d383d0
- **Deployment timestamp:** 2026-11-13T21:43:59Z
- **Deployment status:** success ("Deployment has completed")
- **Deployment ID:** 7777184272
- **GitHub Actions CI (run #43513141066):** success (ci workflow, push to main)

---

## 4. Production Sitemap Verification

### Sitemap fetch

- **URL:** https://scholars.com.ng/sitemap.xml
- **HTTP status:** 200 (successful)
- **Content type:** application/xml
- **XML validity:** Valid XML (parsed successfully)
- **Canonical host:** All URLs use `https://www.scholars.com.ng` (HTTPS www)

### Sitemap URL inventory

The production sitemap contains the following URL groups:

| URL group | Status |
|-----------|--------|
| Static pages (`/`, `/about`, `/reviews`, `/scholarships-in-nigeria`, `/opportunities-for-students`, `/resources`, `/legal/privacy`, `/legal/terms`) | Present ✓ |
| Scholarship pages (`/scholarship/<slug>`) | Present ✓ (multiple verified scholarships) |
| Opportunity pages (`/opportunity/<slug>`) | Present ✓ (multiple verified opportunities) |
| Resource Centre articles (`/resources/<slug>`) | Present ✓ (5 articles with lastmod) |
| Resource Centre categories (`/resources/category/<slug>`) | Present ✓ (5 categories) |
| Empty category (`/resources/category/study-abroad-and-funding`) | Excluded ✓ |

### Verification results

| Check | Result |
|-------|--------|
| HTTP status 200 | Pass ✓ |
| Valid XML | Pass ✓ |
| Canonical HTTPS www host | Pass ✓ |
| No duplicate URLs | Pass ✓ |
| No malformed URLs | Pass ✓ |
| No private/internal/admin URLs exposed | Pass ✓ |
| Closed verified scholarship pages present | Pass ✓ |
| Postgraduate scholarship pages present | Pass ✓ |
| Empty category excluded from sitemap | Pass ✓ |
| Resource Centre articles included | Pass ✓ |

### Production sitemap URL count

The production sitemap contains scholarship URLs, opportunity URLs, Resource Centre article URLs (5), Resource Centre category URLs (5), and 8 static pages. The exact count varies as eligible public records change; the success criterion is completeness relative to eligible public records at verification time, not a hardcoded number.

---

## 5. Representative Route Test Results

| Route | HTTP status | Result |
|-------|-------------|--------|
| `https://scholars.com.ng/` (homepage) | 200 | Pass ✓ — renders correctly |
| `https://scholars.com.ng/scholarship/nddc-local-post-graduate-master-s-degree-scholarship-2026-2027-107bccf4` (closed verified scholarship) | 200 | Pass ✓ — renders "Applications closed" status, historical reference page |
| `https://scholars.com.ng/opportunity/gateway-program-0386c234` (opportunity) | 200 | Pass ✓ — renders correctly |
| `https://scholars.com.ng/resources/how-to-find-legitimate-scholarships` (Resource Centre article) | 200 | Pass ✓ — full content rendered |
| `https://scholars.com.ng/resources/category/scholarship-applications` (populated category) | 200 | Pass ✓ — shows "4 eligible guides" |
| `https://scholars.com.ng/resources/category/study-abroad-and-funding` (empty category) | 200 | Pass ✓ — route accessible, shows "0 eligible guides", no content advertised |

---

## 6. Supabase and Application Integrity

- **Supabase permission errors:** None observed. Public catalogue views (`scholarships_public_preview_v1`, `opportunities_public_preview_v1`) queried successfully via the anonymous public client.
- **Public-view query failures:** None. Sitemap generation uses approved views with no raw-table access.
- **Sitemap generation errors:** None. Production sitemap generated and served successfully.
- **Resource Centre fallback failures:** None. Local Resource Centre content loads correctly.
- **Server-side rendering / prerendering errors:** None observed on tested routes.
- **Unexpected production exceptions:** None observed.

---

## 7. Search Engine Accessibility

| Check | Result |
|-------|--------|
| `robots.txt` accessible | Pass ✓ — `https://scholars.com.ng/robots.txt` returns 200 |
| Sitemap referenced in robots.txt | Pass ✓ — `Sitemap: https://www.scholars.com.ng/sitemap.xml` |
| Sitemap publicly accessible | Pass ✓ — returns valid XML with HTTP 200 |
| No unintended `noindex` directive | Pass ✓ — robots.txt uses `Allow: /` with specific disallows for admin/auth/private routes only |
| Canonical host consistency | Pass ✓ — all sitemap URLs use `https://www.scholars.com.ng` |

**Important distinction:** Production accessibility and search engine indexing are separate outcomes. This report confirms the sitemap is publicly accessible and correctly structured; it does **not** claim that Google has indexed the changes or that rankings have improved.

---

## 8. Unresolved Issues and Limitations

- Production deployment succeeded on Vercel. No unresolved critical issues.
- Google indexing status has not been verified (search engine indexing is a separate outcome from deployment).
- Exact production URL count is not hardcoded as a success criterion; completeness is judged relative to eligible public records at verification time.

---

## 9. Final Release Status

**Successful.**

The PR #32 merge, production deployment, and production smoke tests have all been completed and verified:

- PR #32 merged into `main` (merge commit `ef7e97b`)
- Production deployment on Vercel succeeded (status: success)
- Sitemap returns valid XML with all expected URL groups
- All representative routes return HTTP 200 with correct content
- `robots.txt` is correct and references the sitemap
- No production exceptions or Supabase permission errors observed
- Production verification completed

---

## 10. Safeguards Confirmed

- No unrelated application functionality was modified.
- No credentials or environment variables were exposed.
- No security protections were disabled.
- No CI checks were bypassed.
- Unrelated pre-existing user changes were preserved in the working tree.
- Production was not claimed fixed until deployment and verification were complete.
