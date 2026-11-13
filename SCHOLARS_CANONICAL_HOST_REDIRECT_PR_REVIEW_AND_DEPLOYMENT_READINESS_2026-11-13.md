# SCHOLARS_CANONICAL_HOST_REDIRECT_PR_REVIEW_AND_DEPLOYMENT_READINESS_2026-11-13

**Date:** 2026-11-13
**Repository:** ImperioKDB/Scholars (remediation), ImperioKDB/Updates (this report)
**Production host:** `https://www.scholars.com.ng`
**Status:** PR opened; not merged or deployed.

---

## 1. Original problem

Requests to the apex host `https://scholars.com.ng/*` were not consistently
redirecting to the canonical `https://www.scholars.com.ng/*`. While `/` and
legacy share routes were redirected apex→www, ordinary public routes
(`/resources`, `/sitemap.xml`, `/robots.txt`, `/legal/terms`, Resource Center
articles/categories, scholarship/opportunity landing pages, etc.) returned
`200` directly on the apex host, making them indexable as a separate host and
splitting canonical signals.

---

## 2. Root cause

The repository had a single application-level host check in `middleware.ts`:
in production, `scholars.com.ng` and `scholars-eight.vercel.app` were redirected
to `https://www.scholars.com.ng` with status `308`, preserving pathname and
query string. However, the middleware only covered `/`, protected routes,
legacy share routes, and `/reviews`. It did **not** cover general public routes
such as `/resources`, `/resources/*`, `/sitemap.xml`, `/robots.txt`, `/about`,
or the two public landing pages. That matcher exclusion was the confirmed gap.

`vercel.json` contained only region/cron config (no canonical-domain redirect),
and `next.config.js` contained headers only (no host-scoped redirect rule).

---

## 3. Existing implementation reviewed

Branch `audit/canonical-host-redirect-2026-11-13`, commit
`680eb174a2d051f4ba13ae0e188ac5904f17ebcb`
("fix: redirect apex host to canonical www domain"), already pushed to GitHub;
`main` was not modified.

Reviewed files on that branch:

- `next.config.js` — hosts an `async redirects()` returning one host-scoped
  permanent rule:
  ```js
  {
    source: "/:path*",
    has: [{ type: "host", value: "scholars.com.ng" }],
    destination: "https://www.scholars.com.ng/:path*",
    permanent: true,
  }
  ```
- `middleware.ts` — production host redirect for apex +
  `scholars-eight.vercel.app` → `https://www.scholars.com.ng` (308), limited
  matcher scope; left unchanged (not duplicated at the middleware layer for the
  apex host).
- `vercel.json` — regions + crons only; no domain-level redirect.
- `lib/canonical-host-redirect.test.ts` — existing contract test asserting the
  redirect rule (`permanent: true`, path-preserving destination).
- `app/sitemap.ts`, `app/robots.ts` — already default to `www.scholars.com.ng`
  via `NEXT_PUBLIC_APP_URL`; unchanged.
- `package.json` — Next.js `14.2.35`; vitest test runner.

Independent review of the proposed rule against Next.js 14.2.35 (source read of
`prepare-destination.js`/`resolve-routes.js`) confirmed:

- **Host matching**: `has: [{ type: 'host' }]` compares `req.headers.host`
  (port stripped, lowercased) against `scholars.com.ng`. Only the apex host
  matches; `www.scholars.com.ng` is not affected.
- **Path preservation**: `/:path*` maps to `:path*` in the destination.
- **Query-string preservation**: Next.js merges the original request query into
  the redirect destination for `redirect` routes (verified in source and live).
- **Trailing slash**: trailing-slash apex URLs hit Next.js default
  trailing-slash normalization first, then resolve to canonical www (standard
  2-hop; documented, not a loop).
- **Redirect ordering**: single rule; no conflict with existing rules.
- **HTTP→HTTPS**: Vercel issues 308s for HTTP apex/www; the application rule
  handles host canonicalization on HTTPS.
- **Vercel domain-level redirects**: not inspected (no authenticated Vercel
  access); potential overlap must be checked manually in the Vercel dashboard
  before deployment.
- **Static files / metadata endpoints**: `/sitemap.xml`, `/robots.txt` are
  covered by the `/:path*` rule.

Conclusion: the rule is correct for Next.js 14.2.35 and the Vercel deployment
architecture. No change to the rule was required; no additional redirect
mechanism was introduced.

---

## 4. Changes made

On branch `audit/canonical-host-redirect-2026-11-13`:

1. Verified the existing committed implementation
   (`next.config.js` redirect rule + `lib/canonical-host-redirect.test.ts`)
   against Next.js 14.2.35 source and live HTTP behavior. No change to the
   redirect rule was needed.
2. Added `lib/canonical-host-redirect.integration.test.ts` — a running-server
   integration suite that spins up a real Next.js dev server and asserts actual
   initial HTTP responses with redirect-following disabled (not source-string
   grep).
3. Committed and pushed the branch (new commit `e91841b` on top of
   `680eb174`).
4. Opened Pull Request #33 into `main`.

No database, authentication, eligibility, sitemap-architecture, or
expired-content-policy changes.

---

## 5. Changed files

In `ImperioKDB/Scholars`, branch `audit/canonical-host-redirect-2026-11-13`
(relative to `main`):

- `next.config.js` — added host-scoped permanent apex→www redirect
  (committed in `680eb174`).
- `lib/canonical-host-redirect.test.ts` — existing redirect contract test
  (committed in `680eb174`).
- `lib/canonical-host-redirect.integration.test.ts` — NEW running-server
  integration suite (committed in `e91841b`, this review).

---

## 6. PR URL and status

- **PR:** https://github.com/ImperioKDB/Scholars/pull/33
- **Title:** `fix: enforce canonical www hostname redirects`
- **Base:** `main`
- **Head:** `audit/canonical-host-redirect-2026-11-13`
- **Commit:** `e91841b` (branch tip), built on `680eb174`
- **State:** OPEN (not merged). Not authorized to merge.

---

## 7. Test commands and actual results

All commands run on branch `audit/canonical-host-redirect-2026-11-13`
with `NEXT_PUBLIC_SUPABASE_URL=https://placeholder.supabase.co`
`NEXT_PUBLIC_SUPABASE_ANON_KEY=placeholder-anon-key`:

| Command | Result |
|---|---|
| `npx tsc --noEmit` | PASS (exit 0) |
| `npm test` (vitest run) | PASS — 27 files, 143 tests passed |
| `npm run build` | PASS (exit 0); `.next/routes-manifest.json` contains the host redirect with `statusCode: 308` |
| `git diff --check` on changed files | PASS (exit 0); trailing-whitespace hits are all in pre-existing branch docs, not changed files |
| `npx next lint` | Script exists but is interactive (prompts for ESLint config); could not run non-interactively in this session |
| Live dev server + `curl` with `redirect: manual` | All scenarios passed (308 + www Location, query preserved, www unaffected) |

Integration suite (`lib/canonical-host-redirect.integration.test.ts`): 10/10 passed —
apex homepage, `/resources`, `sitemap.xml`, `robots.txt`, `/legal/terms`,
resource article, resource category, unknown route, query preservation, www
not redirected.

No unrelated dependency upgrades or refactoring were introduced.

---

## 8. Vercel domain configuration findings / access limitations

Vercel domain configuration was **not inspectable** in this session. The
Vercel CLI/integration requires an interactive login, and no authenticated
Vercel access was available. Therefore:

- Whether `scholars.com.ng` is attached to the correct production project:
  **not verified** (manual dashboard check required).
- Whether `www.scholars.com.ng` is the intended production domain:
  **not verified** (manual dashboard check required).
- Whether the apex domain has a domain-level redirect configured:
  **not verified** (manual dashboard check required).
- Whether any existing Vercel redirect conflicts with the application-level
  rule: **not verified** (manual dashboard check required).

No Vercel settings, DNS records, or domain configuration were altered (not
authorized). Exact dashboard action: confirm `scholars.com.ng` permanently
redirects to `www.scholars.com.ng` for all paths/query strings, and reconcile
any domain-level redirect with the application rule to avoid duplicate
redirects or loops. Never claim Vercel settings were inspected without access.

---

## 9. Production verification matrix

The fix is **not deployed**; all production checks below are **pending
production verification** and must be repeated after deployment with
redirect-following disabled on the initial request.

For each of apex (`https://scholars.com.ng`) and www
(`https://www.scholars.com.ng`), test:
`/`, `/resources`, one real Resource Center article, one real Resource Center
category, `/scholarships-in-nigeria`, `/opportunities-for-students`,
`/legal/terms`, `/sitemap.xml`, `/robots.txt`.

For every URL record:
1. Initial HTTP status.
2. Initial `Location` header.
3. Number of redirects.
4. Final URL.
5. Final HTTP status.
6. Whether the canonical URL is correct.

Also test:
- Query-string preservation.
- Trailing-slash behaviour.
- HTTP apex → HTTPS www.
- HTTP www → HTTPS www.
- Redirect loops.
- Unnecessary redirect chains.
- A valid existing `/s/{id}` legacy scholarship share URL (if a public record
  is available; do not invent IDs).
- A valid existing `/o/{id}` legacy opportunity share URL (if a public record
  is available).

Do not invent IDs or use nonexistent fixtures as proof of valid legacy share
behaviour. Label all production checks as pending until verified post-deploy.

---

## 10. Remaining blockers

1. **Deployment not authorized** — the PR must not be merged and the change
   must not be deployed without explicit approval.
2. **Vercel domain configuration unverified** — no authenticated Vercel access
   in this session; manual dashboard confirmation required before deployment
   (apex domain attachment, www as production domain, domain-level redirect,
   conflicts).
3. **Production redirect matrix not executed** — post-deployment verification
   with redirect-following disabled is pending for all matrix URLs and edge
   cases (query strings, trailing slashes, HTTP→HTTPS, loops, chains, legacy
   share URLs).
4. **Lint** — `next lint` is interactive in this environment; non-interactive
   lint run not completed.

---

## 11. Exact next action required

An authorized reviewer should:
1. Review and approve Pull Request #33
   (https://github.com/ImperioKDB/Scholars/pull/33).
2. Manually verify Vercel domain settings in the dashboard (apex attached to
   the correct project, www as production domain, domain-level redirect status,
   conflicts with the application rule) — no changes without authorization.
3. Upon approval, merge the PR and deploy.
4. After deployment, execute the production redirect matrix (Section 9) with
   redirect-following disabled and record initial status, Location header,
   redirect count, final URL, final status, and canonical-URL correctness for
   apex and www across all matrix URLs, plus query-string, trailing-slash,
   HTTP→HTTPS, loop, chain, and legacy share checks.
5. Only after successful post-deployment verification may the issue be
   considered fixed in production.
