# Scholars — Canonical Host Redirect Audit and Remediation

**Date:** 2026-11-13
**Production host:** `https://www.scholars.com.ng`
**Repositories:** [Scholars](https://github.com/ImperioKDB/Scholars), [Updates](https://github.com/ImperioKDB/Updates)
**Status:** Audited; remediation committed and pushed to a non-main branch; not merged or deployed.

## Initial findings

The approved canonical hostname is `https://www.scholars.com.ng`. The initial production checks found that the apex HTTPS root redirected permanently, but the apex HTTPS versions of the other tested public routes—including `/resources`, `/sitemap.xml`, and `/robots.txt`—returned `200` directly with no `Location` header. This meant equivalent apex URLs could remain indexable as a separate host.

The existing public-page metadata was also inconsistent with the approved host. Live www pages returned canonical and Open Graph URLs using `https://www.scholars.com.ng`, and the sitemap and robots output used the www host. The gap was specifically host canonicalization at the HTTP response layer, not sitemap architecture or page metadata generation.

## Existing redirect architecture

The repository had one application-level host check in `middleware.ts`:

- In production, `scholars.com.ng` and `scholars-eight.vercel.app` were redirected to `https://www.scholars.com.ng` with status `308`.
- The redirect preserved pathname and query string by constructing the destination from `request.nextUrl.pathname + request.nextUrl.search`.
- The middleware matcher covered `/`, protected routes, legacy share routes, and `/reviews`, but did not cover general public routes such as `/resources`, `/resources/*`, `/sitemap.xml`, `/robots.txt`, `/about`, or the two public landing pages.
- `vercel.json` contained the region and cron configuration only; it contained no canonical-domain redirect rule.
- `next.config.js` contained headers only; it contained no host-scoped redirect rule.
- Root metadata, sitemap, and robots generation defaulted to `https://www.scholars.com.ng` unless overridden by `NEXT_PUBLIC_APP_URL`.

The matcher exclusion was the confirmed gap. It explains why `/` and legacy share routes were redirected while ordinary public routes were not.

## Mandatory production URL evidence before remediation

Tests used requests with redirects disabled for the initial response, then a second request with redirects enabled to count the chain and record the final URL.

| Requested URL | Initial | Initial `Location` | Redirects | Final URL/status | Result |
|---|---:|---|---:|---|---|
| `https://scholars.com.ng/` | 308 | `https://www.scholars.com.ng/` | 1 | `https://www.scholars.com.ng/` / 200 | Redirected |
| `https://scholars.com.ng/resources` | 200 | none | 0 | apex URL / 200 | **Gap** |
| `https://scholars.com.ng/resources/scholarship-application-guide` | 404 | none | 0 | apex URL / 404 | **Gap; example slug absent** |
| `https://scholars.com.ng/resources/category/scholarship-guides` | 404 | none | 0 | apex URL / 404 | **Gap; example slug absent** |
| `https://scholars.com.ng/scholarships-in-nigeria` | 200 | none | 0 | apex URL / 200 | **Gap** |
| `https://scholars.com.ng/opportunities-for-students` | 200 | none | 0 | apex URL / 200 | **Gap** |
| `https://scholars.com.ng/legal/terms` | 200 | none | 0 | apex URL / 200 | **Gap** |
| `https://scholars.com.ng/sitemap.xml` | 200 | none | 0 | apex URL / 200 | **Gap** |
| `https://scholars.com.ng/robots.txt` | 200 | none | 0 | apex URL / 200 | **Gap** |
| `https://www.scholars.com.ng/` | 200 | none | 0 | www URL / 200 | Canonical host |
| `https://www.scholars.com.ng/resources` | 200 | none | 0 | www URL / 200 | Canonical host |
| `https://www.scholars.com.ng/scholarships-in-nigeria` | 200 | none | 0 | www URL / 200 | Canonical host |
| `https://www.scholars.com.ng/opportunities-for-students` | 200 | none | 0 | www URL / 200 | Canonical host |
| `https://www.scholars.com.ng/legal/terms` | 200 | none | 0 | www URL / 200 | Canonical host |
| `https://www.scholars.com.ng/sitemap.xml` | 200 | none | 0 | www URL / 200 | Canonical host |
| `https://www.scholars.com.ng/robots.txt` | 200 | none | 0 | www URL / 200 | Canonical host |

HTTP-to-HTTPS checks showed Vercel-issued `308` redirects for both apex and www HTTP URLs. However, HTTP apex requests first redirected to HTTPS apex, then—where the application matcher did not apply—served the apex URL. Thus HTTP enforcement was present, but it did not establish a single canonical host for all paths.

Query and trailing-slash checks showed that the existing platform behavior preserved query strings and normalized trailing slashes on both hosts, but apex URLs such as `https://scholars.com.ng/resources?utm_source=a&ref=abc` still returned `200` on the apex host. The legacy share route checks for nonexistent UUIDs did redirect apex-to-www in one hop and then returned the expected `404`; valid-ID legacy share verification requires a known public record ID and was not claimed from nonexistent fixtures.

## Remediation

The smallest reliable application-level correction was added to `next.config.js`:

```js
{
  source: '/:path*',
  has: [{ type: 'host', value: 'scholars.com.ng' }],
  destination: 'https://www.scholars.com.ng/:path*',
  permanent: true,
}
```

This emits a `308` redirect for every apex path, including public pages and metadata endpoints, while leaving the existing auth middleware, protected-route behavior, share attribution handling, database access, sitemap architecture, and expired-content policy unchanged. Next.js preserves the incoming query string for this redirect. The existing middleware rule remains responsible for its separate preview-host behavior and is not duplicated for the apex host at the middleware layer.

A focused regression test was added to assert the host condition, permanent behavior, and path-preserving destination.

## Files changed

In `ImperioKDB/Scholars`:

- `next.config.js` — added the host-scoped permanent apex-to-www redirect.
- `lib/canonical-host-redirect.test.ts` — added the redirect contract regression test.

No database records, tables, storage buckets, authentication behavior, eligibility logic, or sitemap data sources were changed.

## Validation performed

The remediation branch passed all local checks:

- `npx tsc --noEmit` — **PASS**.
- `npm test` — **PASS**, 26 test files and 133 tests.
- `NEXT_PUBLIC_SUPABASE_URL=https://placeholder.supabase.co NEXT_PUBLIC_SUPABASE_ANON_KEY=placeholder-anon-key npm run build` — **PASS**.
- `git diff --check` — **PASS**.
- Compiled `.next/routes-manifest.json` inspection — **PASS**; it contains the expected host condition, destination, and status code `308`.

Live www SEO checks also passed for the tested public pages:

- Resource Center index: `200`; canonical and `og:url` use the www host.
- Actual Resource Center category: `/resources/category/scholarship-applications`; `200`; canonical and `og:url` use the www host.
- Actual Resource Center article: `/resources/how-to-find-legitimate-scholarships`; `200`; canonical and `og:url` use the www host.
- Scholarship and opportunity landing pages: `200`; canonical, Open Graph, and observed JSON-LD URLs use the www host.
- `sitemap.xml`: all observed `<loc>` values use `https://www.scholars.com.ng`.
- `robots.txt`: sitemap directive is `https://www.scholars.com.ng/sitemap.xml`; protected-route disallows remain present.

## Commit and branch references

Scholars remediation commit:

- Branch: `audit/canonical-host-redirect-2026-11-13`
- Commit: `680eb174a2d051f4ba13ae0e188ac5904f17ebcb`
- Commit message: `fix: redirect apex host to canonical www domain`
- Branch URL: https://github.com/ImperioKDB/Scholars/tree/audit/canonical-host-redirect-2026-11-13
- Pull request URL generated by GitHub: https://github.com/ImperioKDB/Scholars/pull/new/audit/canonical-host-redirect-2026-11-13

The branch was pushed to GitHub. `main` was not modified.

## Production verification and blockers

The fix has **not** been deployed, so the after-deployment production redirect matrix is intentionally not claimed as passed. A deployment or merge requires explicit authorization under the task brief.

Vercel domain configuration was not inspectable in this session because the Vercel integration requires an interactive login. The exact dashboard action, if domain-level configuration is preferred, is to confirm that `scholars.com.ng` is configured to permanently redirect to `www.scholars.com.ng` for all paths and query strings. If that is confirmed and reliable, the application rule could be reconsidered to avoid overlapping canonical-host mechanisms; no such dashboard change was made here.

Before declaring completion, an authorized deployment should repeat the full matrix and verify that every apex HTTPS route returns an initial `308` with a www `Location`, that HTTP apex reaches the canonical www host without an unnecessary chain, and that query strings survive. A valid existing `/s/{id}` and `/o/{id}` record should also be tested for legacy share behavior. No claim is made about Google indexing improvements because Search Console evidence was not available.

## References

[1]: https://github.com/ImperioKDB/Scholars "Scholars source repository"
[2]: https://github.com/ImperioKDB/Scholars/blob/audit/canonical-host-redirect-2026-11-13/middleware.ts "Scholars middleware source"
[3]: https://github.com/ImperioKDB/Scholars/blob/audit/canonical-host-redirect-2026-11-13/next.config.js "Scholars Next.js configuration"
[4]: https://www.scholars.com.ng/sitemap.xml "Scholars production sitemap"
[5]: https://www.scholars.com.ng/robots.txt "Scholars production robots file"
[6]: https://www.scholars.com.ng/resources "Scholars Resource Center"
