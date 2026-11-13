# SCHOLARS_CANONICAL_HOST_REDIRECT_FINAL_PR_READINESS_AUDIT_2026-11-13

**Date:** 2026-11-13
**Repository:** ImperioKDB/Scholars
**Updates repository:** ImperioKDB/Updates
**Pull request:** https://github.com/ImperioKDB/Scholars/pull/33
**Branch:** `audit/canonical-host-redirect-2026-11-13`
**Target branch:** `main`
**Latest commit:** `11f2ee9214ef1e692eb7744d6a14cf96744cff3f`
**Production canonical domain:** `https://www.scholars.com.ng`
**Apex domain:** `https://scholars.com.ng`
**Status:** PR open; not merged; not deployed.

---

## Final verdict

**READY TO MERGE** — the implementation is technically correct and safe. All
local validation passes. The change is NOT yet deployed, so the production
canonical-host issue is NOT considered fixed until deployment succeeds and the
production verification matrix (Section: Production readiness) passes.

---

## PR URL and latest commit SHA

- PR: https://github.com/ImperioKDB/Scholars/pull/33
- State: open, targets `main`, not a draft
- Latest commit SHA: `11f2ee9214ef1e692eb7744d6a14cf96744cff3f`
- Branch tip (remote): `11f2ee9214ef1e692eb7744d6a14cf96744cff3f`
- PR contains 3 commits: `680eb17` (redirect rule + contract test), `e91841b`
  (integration suite), `11f2ee9` (CI-reliability fix).
- Changed files (vs `main`): `next.config.js`,
  `lib/canonical-host-redirect.test.ts`,
  `lib/canonical-host-redirect.integration.test.ts`.
- Additions: 250; deletions: 0.

---

## Final diff assessment

### `next.config.js` (Audit A)

Added a single host-scoped permanent redirect:

```js
{
  source: "/:path*",
  has: [{ type: "host", value: "scholars.com.ng" }],
  destination: "https://www.scholars.com.ng/:path*",
  permanent: true,
}
```

Confirmed correct:

- **Applies only to `scholars.com.ng`**: Next.js `has: [{ type: 'host' }]`
  compares `req.headers.host` (port stripped, lowercased). Verified against
  Next.js 14.2.35 source (`prepare-destination.js`). `www.scholars.com.ng` does
  not match.
- **Redirects to `https://www.scholars.com.ng/:path*`**: path preserved via
  `:path*` interpolation.
- **Permanent / HTTP 308**: `permanent: true`; compiled
  `.next/routes-manifest.json` emits `statusCode: 308`.
- **Paths and query parameters preserved**: Next.js merges the original query
  into the redirect destination for `redirect` routes; verified live
  (`/resources?q=1` → `https://www.scholars.com.ng/resources?q=1`).
- **Canonical www not redirected**: live `www.scholars.com.ng/` returns `200`
  with no `Location` header.
- **No redirect loop / unnecessary chain**: apex → 308 → www → served (www
  host does not re-match). No domain-level redirect (see Audit D), so no
  double redirect.
- **Existing middleware compatible**: middleware host check (apex +
  `scholars-eight.vercel.app`) is a separate, unchanged rule for preview-host
  behaviour; not duplicated for apex at the middleware layer.
- **Headers/security/sitemap/robots unaffected**: `headers()` in next.config.js
  is separate; `app/sitemap.ts` and `app/robots.ts` default to
  `www.scholars.com.ng` via `NEXT_PUBLIC_APP_URL`; unchanged.

### Routes manifest verification

`.next/routes-manifest.json` (production build) contains:

```json
{
  "source": "/:path*",
  "has": [{ "type": "host", "value": "scholars.com.ng" }],
  "destination": "https://www.scholars.com.ng/:path*",
  "statusCode": 308
}
```

(The other redirect entry, `/:path+/` → `/:path+`, is Next.js's internal
trailing-slash normalization, unrelated to this change.)

### Test files (Audit B)

- `lib/canonical-host-redirect.test.ts` — existing contract test (kept,
  unchanged): asserts the redirect rule's `source`, `has`, `destination`,
  `permanent`.
- `lib/canonical-host-redirect.integration.test.ts` — NEW running-server
  integration suite asserting real initial HTTP responses (redirects NOT
  followed). Corrected during this audit for cold-CI reliability (see Audit B
  below).

No database, authentication, eligibility, sitemap-architecture, or
expired-content-policy changes.

---

## Integration-test reliability assessment (Audit B)

A genuine reliability issue was found and corrected:

- **Issue**: `waitForReady` checked only TCP connect, but Next.js dev compiles
  routes lazily on first HTTP request (~28s observed cold). With vitest's
  default 5s test timeout, the first cold request to an uncompiled route
  spuriously failed ("Test timed out in 5000ms") in a fresh CI environment.
- **Correction** (commit `11f2ee9`, smallest safe change, assertions unchanged):
  - `waitForReady` now performs an actual HTTP readiness request (`curl /`)
    instead of only TCP connect, proving the server can serve responses.
  - Each test opts into a 120s timeout to accommodate cold route compilation.
  - Added a port-in-use pre-flight check on port 3337 that fails fast instead
    of hanging on a failed bind.
  - `afterAll` terminates the dev server (`SIGTERM`); no orphan process
    remains when the suite passes, fails, or aborts.
- **Port 3337**: fixed port with pre-flight conflict detection; if another
  process holds it, the suite fails fast with a clear message.
- **Environment isolation**: `NEXT_PUBLIC_SUPABASE_URL`/`ANON_KEY` set to
  placeholders; `PORT` overridden to 3337.
- **Genuine initial-response inspection**: `curl` is invoked without `-L`, so
  redirects are not followed; tests assert status 308 and the `Location`
  header directly.
- **Consistency**: re-verified cold — all 10 integration tests pass; full suite
  27 files / 143 tests pass.

---

## TypeScript, test, build, lint and diff-check results

All commands run on branch `audit/canonical-host-redirect-2026-11-13` at
`11f2ee9`, with
`NEXT_PUBLIC_SUPABASE_URL=https://placeholder.supabase.co`
`NEXT_PUBLIC_SUPABASE_ANON_KEY=placeholder-anon-key`:

| Check | Command | Result | Exit code |
|---|---|---|---|
| TypeScript | `npx tsc --noEmit` | PASS | 0 |
| Unit + integration tests | `npm test` (`vitest run`) | PASS — 27 files, 143 tests | 0 |
| Production build | `npm run build` (`next build`) | PASS; routes manifest has host 308 | 0 |
| Diff cleanliness | `git diff --check` (changed files) | PASS | 0 |
| Routes manifest | `.next/routes-manifest.json` | PASS — host-scoped 308 present | — |
| Live production server | `next start` + `curl` (no -L) | PASS — apex 308→www, query preserved, www 200 no Location | — |

### Lint limitation

The project has **no ESLint configuration file** (no `.eslintrc*`,
`eslint.config.*`). The only lint script is `"lint": "next lint"`, which is
interactive (prompts for ESLint setup when none exists) and cannot run
non-interactively in CI. Creating a new ESLint config would be an unnecessary
project-wide change outside the scope of this remediation. **Lint could not be
run reliably; this is a documented limitation, not a failure of the changed
files.** The new files follow the existing code style and pass TypeScript.

---

## Vercel domain configuration findings (Audit D)

Inspected read-only via the authenticated Vercel CLI (`imperiokdb`) and the
Vercel REST API. Token was read programmatically and never printed or logged.

Scholars project `prj_n4Unq6wzjbjRT9TcRGKvFD9jIfBk`:

| Domain | Attached to scholars project | Verified | Domain-level redirect |
|---|---|---|---|
| `scholars.com.ng` (apex) | Yes | Yes | `null` (none) |
| `www.scholars.com.ng` (canonical) | Yes | Yes | `null` (none) |
| `scholars-eight.vercel.app` (preview) | Yes | Yes | N/A |

Findings:

- `scholars.com.ng` is attached to the correct production project. ✓
- `www.scholars.com.ng` is attached to the correct production project. ✓
- `www.scholars.com.ng` is a verified domain on the project and is the
  intended canonical host targeted by the redirect rule. ✓
- **No domain-level redirect** is configured on either domain (`redirect:
  null`), so there is **no conflict or duplicate redirect** with the
  application-level rule, and no redirect loop risk at the domain level. ✓
- Production deployment: `READY`, `target=production`, latest
  2026-11-13 (~2h ago). ✓

No Vercel domains, DNS records, deployment settings, environment variables,
or project configuration were modified (not authorized).

---

## Outstanding risks and limitations

1. **Not deployed.** The PR is open and not merged; the change is not live.
   The canonical-host issue is not fixed in production until deployed and the
   production verification matrix passes.
2. **Lint not runnable non-interactively** (no ESLint config; `next lint`
   prompts). Documented limitation only.
3. **Production verification matrix pending** (must be executed post-deploy,
   see below).
4. **Vercel domain canonicality**: both apex and www are attached and
   verified; the application rule performs canonicalization. No domain-level
   redirect conflict exists. Recommended: confirm in the Vercel dashboard that
   `www.scholars.com.ng` is the intended primary production domain before
   deploy.
5. **No new dependencies, refactoring, or unrelated product changes** were
   introduced.

---

## Production readiness (Audit E)

Local tests (dev server and `next start`) are **not** production verification.
The fix is not deployed; all checks below are **pending production
verification** and must be repeated after deployment with redirect-following
disabled on the initial request.

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
6. Whether the canonical URL is correct (`https://www.scholars.com.ng...`).

Also test:
- Query-string preservation.
- Trailing-slash behaviour.
- HTTP apex → HTTPS www.
- HTTP www → HTTPS www.
- Redirect loops.
- Unnecessary multi-hop redirect chains.
- www requests remaining on the canonical hostname (no redirect).
- Valid legacy `/s/{id}` scholarship share URL (if an actual public record ID
  is available; do not invent IDs).
- Valid legacy `/o/{id}` opportunity share URL (if an actual public record ID
  is available; do not invent IDs).

Clearly label these checks as pending production verification until performed
after deployment.

---

## Exact next action required

1. Authorized reviewer reviews and approves PR #33
   (https://github.com/ImperioKDB/Scholars/pull/33).
2. (Optional but recommended) Confirm in the Vercel dashboard that
   `www.scholars.com.ng` is the intended primary production domain and that no
   domain-level redirect conflicts; make no changes without authorization.
3. Upon approval, merge the PR and deploy (only the authorized reviewer may
   merge/deploy).
4. After deployment, execute the production verification matrix above and
   record initial status, `Location`, redirect count, final URL, final status,
   and canonical-URL correctness for every matrix URL.
5. Only after successful post-deployment verification may the issue be
   considered fixed in production.
