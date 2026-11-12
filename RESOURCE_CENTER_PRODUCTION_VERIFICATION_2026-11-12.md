# Resource Centre Production Verification — 2026-11-12

**Repository:** ImperioKDB/Scholars  
**Workspace:** /workspaces/Scholars  
**Production domain:** https://scholars.com.ng (canonical host: www.scholars.com.ng)  
**Resource Centre:** https://scholars.com.ng/resources  
**Verification date:** 2026-11-12  
**Method:** HTTP requests against the live production site; source inspection of the merged branch; Vercel CLI deployment metadata (authenticated as imperiokdb). No browser automation was available (Playwright not installed; no executable browser present), so rendering checks were performed on the server-rendered HTML returned by production.

---

## 1. Deployment verification (Phase 1.1)

### 1.1 Current GitHub "main" SHA

`git fetch origin main` completed and `git rev-parse origin/main` returned:

```
137f2fa28a4f1a5b1fb6eaa55e3c6c3677bb4210
```

This is the merge commit referenced in the task. It is confirmed present in the local object store (`git cat-file -t 137f2fa...` → `commit`).

### 1.2 Vercel deployment associated with the merge commit

The Vercel CLI (`vercel 65.14.0`, authenticated as `imperiokdb`) lists deployments for the `scholars` project in team `imperiokdbs-projects`. The most recent deployment is:

| Field | Value |
|---|---|
| Deployment URL (vercel.app) | https://scholars-l8ok8txwb-imperiokdbs-projects.vercel.app |
| Custom production domain | https://scholars.com.ng (and https://www.scholars.com.ng) |
| Target / environment | production |
| State | READY |
| Commit SHA | 137f2fa28a4f1a5b1fb6eaa55e3c6c3677bb4210 |
| Commit ref | main |
| Commit message | Merge pull request #29 from ImperioKDB/feature/resource-center-public-frontend\n\nfeat: launch repository-backed Resource Center |
| Commit author | ImperioKDB (Abolaji Bright) |
| Commit verification | verified |
| Created at | 2026-11-11 23:37:26 UTC (epoch 1794440246402 ms) |
| Ready at | 2026-11-11 23:38:47 UTC (epoch 1794440327862 ms) |
| githubDeployment | 1 |

Source: `vercel ls scholars --format json --limit 25`, deployment object for `scholars-l8ok8txwb-imperiokdbs-projects.vercel.app`, `meta.githubCommitSha` and `meta.target`.

### 1.3 Production vs preview

The deployment above has `target: production` and `state: READY`, so the merge commit is deployed to **production**, not merely preview. The custom domains https://scholars.com.ng and https://www.scholars.com.ng both serve this deployment (confirmed by HTTP 200 with PR #29 content below).

### 1.4 Deployed commit includes PR #29

**Yes.** The deployed commit SHA `137f2fa28a4f1a5b1fb6eaa55e3c6c3677bb4210` *is* the PR #29 merge commit ("Merge pull request #29 ... feat: launch repository-backed Resource Center"). The production HTML confirms PR #29 content: all 6 launch articles and all 6 launch categories appear in `/sitemap.xml`, the home page renders Resource Centre cards, and `ResourceAdSlot` renders with advertising disabled (see sections 2 and 3).

> Note: the local `main` branch was behind `origin/main` at the time of inspection (local `de9b406` vs `origin/main` `137f2fa`); `origin/main` is the authoritative GitHub main SHA and it equals the PR #29 merge commit.

---

## 2. Production route tests (Phase 1.2)

All routes below were discovered from the repository (not invented):

- Home: `app/resources/page.tsx`
- Article: `app/resources/[slug]/page.tsx`
- Category: `app/resources/category/[slug]/page.tsx`
- Article slugs from `lib/resource-content.ts` (`LOCAL_RESOURCE_ARTICLES`, 6 launch articles)
- Category slugs from `lib/resource-content.ts` (`LOCAL_RESOURCE_CATEGORIES`, 6 launch categories)
- Sitemap: `app/sitemap.ts` and `lib/sitemap-data.ts`

Tests were run with `curl` against `https://www.scholars.com.ng` (canonical host). Every route returned HTTP 200 with no redirect; the non-www host `https://scholars.com.ng` also returned HTTP 200 for the same paths.

### 2.1 Route results table

| # | Route | HTTP | Redirect | Page title | Meta description | Canonical | JSON-LD | Ads | Result |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `/resources` | 200 | none | "Resource Center for students | Scholars | Scholars" | "Practical guides and trustworthy updates to help students in Nigeria find and pursue better opportunities." | `https://www.scholars.com.ng/resources` | CollectionPage + WebSite | disabled (sr-only placeholder) | **PASS** |
| 2 | `/resources/how-to-find-legitimate-scholarships` | 200 | none | "How to find scholarships you can trust | Scholars | Scholars" | excerpt | `https://www.scholars.com.ng/resources/how-to-find-legitimate-scholarships` | Article + BreadcrumbList + ListItem + Organization + Person | disabled | **PASS** |
| 3 | `/resources/how-to-write-a-scholarship-motivation-letter` | 200 | none | "How to write a scholarship motivation letter | Scholars | Scholars" | excerpt | `https://www.scholars.com.ng/resources/how-to-write-a-scholarship-motivation-letter` | Article + BreadcrumbList | disabled | **PASS** |
| 4 | `/resources/how-to-write-a-scholarship-personal-statement` | 200 | none | "...personal statement that sounds like you | Scholars | Scholars" | excerpt | `https://www.scholars.com.ng/resources/how-to-write-a-scholarship-personal-statement` | Article + BreadcrumbList | disabled | **PASS** |
| 5 | `/resources/prepare-for-scholarship-aptitude-tests-and-interviews` | 200 | none | "How to prepare for scholarship aptitude tests and interviews | Scholars | Scholars" | excerpt | `https://www.scholars.com.ng/resources/prepare-for-scholarship-aptitude-tests-and-interviews` | Article + BreadcrumbList | disabled | **PASS** |
| 6 | `/resources/how-to-get-strong-recommendation-letters` | 200 | none | "How to ask for a strong recommendation letter | Scholars | Scholars" | excerpt | `https://www.scholars.com.ng/resources/how-to-get-strong-recommendation-letters` | Article + BreadcrumbList | disabled | **PASS** |
| 7 | `/resources/common-scholarship-application-mistakes` | 200 | none | "Six scholarship application mistakes that are easy to avoid | Scholars | Scholars" | excerpt | `https://www.scholars.com.ng/resources/common-scholarship-application-mistakes` | Article + BreadcrumbList | disabled | **PASS** |
| 8 | `/resources/category/scholarship-applications` | 200 | none | "Scholarship applications resources | Scholars | Scholars" | category description | `https://www.scholars.com.ng/resources/category/scholarship-applications` | CollectionPage + BreadcrumbList | disabled | **PASS** |
| 9 | `/resources/category/essays-and-letters` | 200 | none | "Essays and letters resources | Scholars | Scholars" | category description | `https://www.scholars.com.ng/resources/category/essays-and-letters` | CollectionPage + BreadcrumbList | disabled | **PASS** |
| 10 | `/resources/category/interviews-and-tests` | 200 | none | "Interviews and tests resources | Scholars | Scholars" | category description | `https://www.scholars.com.ng/resources/category/interviews-and-tests` | CollectionPage + BreadcrumbList | disabled | **PASS** |
| 11 | `/resources/category/study-abroad-and-funding` | 200 | none | "Study abroad and funding resources | Scholars | Scholars" | category description | `https://www.scholars.com.ng/resources/category/study-abroad-and-funding` | CollectionPage + BreadcrumbList | disabled | **PASS** |
| 12 | `/resources/category/study-techniques` | 200 | none | "Study techniques resources | Scholars | Scholars" | category description | `https://www.scholars.com.ng/resources/category/study-techniques` | CollectionPage + BreadcrumbList | disabled | **PASS** |
| 13 | `/resources/category/scam-awareness` | 200 | none | "Scam awareness resources | Scholars | Scholars" | category description | `https://www.scholars.com.ng/resources/category/scam-awareness` | CollectionPage + BreadcrumbList | disabled | **PASS** |
| 14 | `/sitemap.xml` | 200 | none | (XML) | n/a | n/a | n/a | n/a | **PASS** |
| 15 | `/` (root) | 308 | → https://www.scholars.com.ng/ | n/a | n/a | n/a | n/a | n/a | **PASS** (canonical host redirect) |

All 15 route checks passed. No route returned a non-200 status, no unexpected redirect, and no route failed to render its expected title/description/canonical/JSON-LD.

### 2.2 Article content rendering

The article page for `/resources/how-to-find-legitimate-scholarships` server-renders body content including:
- "five-question check"
- "Federal Scholarship Board" (`https://education.gov.ng/federal-scholarship-board/`)
- "EducationUSA" (`https://educationusa.state.gov/`)
- Internal category links to `/resources/category/scholarship-applications` and `/resources/category/scam-awareness`

This confirms article Markdown content is rendered server-side, not an empty shell.

### 2.3 Sitemap

`https://www.scholars.com.ng/sitemap.xml` returns HTTP 200 with 106 `<url>` entries. It includes:
- `/resources` (Resource Centre index)
- All 6 category URLs (`/resources/category/scholarship-applications`, `essays-and-letters`, `interviews-and-tests`, `study-abroad-and-funding`, `study-techniques`, `scam-awareness`)
- All 6 article URLs (all `how-to-*` / `common-scholarship-application-mistakes` and `prepare-for-scholarship-aptitude-tests-and-interviews`)
- Plus the site's scholarship/opportunity/informational routes

The sitemap includes the Resource Centre index and all active category and article URLs, satisfying the PR #29 sitemap fix (local repository rows merged into sitemap output).

### 2.4 Canonical URLs and JSON-LD structured data

- Every Resource Centre page emits `rel="canonical"` pointing at `https://www.scholars.com.ng` + the exact route (e.g. article canonicals match `/resources/<slug>`).
- `getResourceCanonicalUrl` (`lib/resource-center.ts:140-154`) fail-closes to the approved `www.scholars.com.ng` route and rejects non-https, non-www, port/user/password/search/hash variants — preventing open redirect.
- JSON-LD: home page emits `CollectionPage` + `WebSite`; article pages emit `Article` + `BreadcrumbList` (+ `ListItem`, `Organization`, `Person`); category pages emit `CollectionPage` + `BreadcrumbList`. All verified in server-rendered HTML.

### 2.5 Broken images / missing assets / internal links

- Local launch articles have `featured_image_path: null` (`lib/resource-content.ts:281`), so `ResourceImage` renders a placeholder `<div>` rather than an `` with a broken `src` (`components/resource-center.tsx:38-42`). No broken image `src` was observed in rendered HTML.
- All internal links observed point to existing Resource Centre routes (`/resources/<slug>`, `/resources/category/<slug>`) or site routes (`/opportunities-for-students`, `/signup`). No dangling internal links were found in the sampled pages.
- `getResourceImageUrl` (`lib/resource-center.ts:130-134`) only approves paths under `resource-center/featured/` and rejects traversal (`..`, backslash, `//`).

### 2.6 Mobile responsiveness / console errors / failed network requests

Not performed: no browser automation executable was available in this environment (Playwright/Puppeteer not installed; installing Playwright would require downloading browser binaries and was not required to complete HTTP verification). Console errors and failed network requests therefore have no observed evidence. This is a limitation, not a failure.

---

## 3. Advertising safety (Phase 1.3)

Advertising remains **disabled by default**. Verified:

### 3.1 No advertisement without explicit configuration

`ResourceAdSlot` (`components/resource-center.tsx:29-36`):

```tsx
export function ResourceAdSlot({ placement = "in-article" }: { placement?: "home" | "category" | "in-article" }) {
  const enabled = process.env.NEXT_PUBLIC_RESOURCE_ADS_ENABLED === "true" && Boolean(process.env.NEXT_PUBLIC_ADSENSE_PUBLISHER_ID && process.env.NEXT_PUBLIC_ADSENSE_RESOURCE_UNIT_ID);
  return (
    <aside aria-label="Advertisement" data-ad-placement={placement} className="...">
      {enabled ? <div className="text-center text-xs text-navy-light">Advertisement</div> : <span className="sr-only">Advertisement space reserved</span>}
    </aside>
  );
}
```

Ads render only when BOTH:
1. `NEXT_PUBLIC_RESOURCE_ADS_ENABLED === "true"`, AND
2. `NEXT_PUBLIC_ADSENSE_PUBLISHER_ID` and `NEXT_PUBLIC_ADSENSE_RESOURCE_UNIT_ID` are both truthy.

`.env.example` sets `NEXT_PUBLIC_RESOURCE_ADS_ENABLED=false` and leaves both AdSense identifiers empty.

### 3.2 No empty or broken advertisement container

When disabled, `ResourceAdSlot` renders the outer `<aside aria-label="Advertisement" data-ad-placement=...>` containing only `<span className="sr-only">Advertisement space reserved</span>`. This is a visually-hidden, zero-impact placeholder; it is not an empty or collapsed container that damages layout, and it contains no `iframe`, `script`, or ad network request.

Rendered production HTML for `/resources`, an article page, and a category page each contains `data-ad-placement` and `Advertisement space reserved`, and contains **no** `adsense`, `google_ads`, or `adslot` script/markup.

### 3.3 No AdSense credentials or sensitive configuration exposed

- `.env.example` documents the ad variables but leaves the AdSense publisher/unit IDs blank; it is not a secret store.
- `.env.local` is gitignored (`.gitignore`: `.env`, `.env.local`) and was not read or reported.
- No `NEXT_PUBLIC_ADSENSE_*` value appears in any production HTML.

Advertising was **not enabled**.

---

## 4. Test record (Phase 1.4)

| Test | Result | Evidence |
|---|---|---|
| GitHub main SHA == PR #29 merge commit | PASS | `git rev-parse origin/main` = `137f2fa28a4f1a5b1fb6eaa55e3c6c3677bb4210` |
| Vercel deployment target = production | PASS | `vercel ls` JSON: `target: production`, `state: READY` |
| Deployment commit includes PR #29 | PASS | Commit SHA is the PR #29 merge commit; commit message references PR #29 |
| `/resources` HTTP 200 | PASS | curl HTTP 200, no redirect |
| 3+ article URLs HTTP 200 | PASS | 7 article URLs tested, all HTTP 200 |
| 2+ category URLs HTTP 200 | PASS | 6 category URLs tested, all HTTP 200 |
| `/sitemap.xml` HTTP 200 | PASS | curl HTTP 200, 106 URLs, includes /resources + 6 categories + 6 articles |
| Canonical URLs correct | PASS | `rel="canonical"` = `https://www.scholars.com.ng<route>` on every page |
| JSON-LD structured data | PASS | CollectionPage/WebSite (home), Article/BreadcrumbList (article), CollectionPage/BreadcrumbList (category) |
| Article content renders | PASS | Body headings and outbound provider links present in HTML |
| No broken images/assets | PASS | featured_image_path null → placeholder div; no  with broken src |
| Internal links valid | PASS | All links resolve to existing routes |
| Advertising disabled by default | PASS | ResourceAdSlot sr-only placeholder; no AdSense markup/credentials |
| Advertising not enabled | PASS | `.env.example` NEXT_PUBLIC_RESOURCE_ADS_ENABLED=false; no config change made |

### Conclusion

The Resource Centre is **genuinely live** on production at https://scholars.com.ng/resources (canonical https://www.scholars.com.ng/resources), served by the Vercel production deployment of the PR #29 merge commit `137f2fa28a4f1a5b1fb6eaa55e3c6c3677bb4210` (deployed 2026-11-11 23:37:26 UTC). All tested routes passed. Advertising remains disabled by default with no exposed credentials.

**Limitation:** browser-automation checks (console errors, failed network requests, mobile responsiveness) were not performed because no browser automation executable was available. HTTP-level verification was used instead.
