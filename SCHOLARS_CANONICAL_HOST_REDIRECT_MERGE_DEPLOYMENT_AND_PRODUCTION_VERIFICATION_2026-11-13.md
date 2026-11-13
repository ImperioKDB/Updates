# SCHOLARS_CANONICAL_HOST_REDIRECT_MERGE_DEPLOYMENT_AND_PRODUCTION_VERIFICATION_2026-11-13

**Date:** 2026-11-13
**Repository:** ImperioKDB/Scholars
**Updates repository:** ImperioKDB/Updates
**Pull request:** https://github.com/ImperioKDB/Scholars/pull/33
**Branch:** `audit/canonical-host-redirect-2026-11-13`
**Target branch:** `main`
**Production canonical domain:** `https://www.scholars.com.ng`
**Apex domain:** `https://scholars.com.ng`
**Final verdict:** FIXED

---

## 1. PR and Merge Summary

| Field | Value |
|---|---|
| PR number | 33 |
| PR URL | https://github.com/ImperioKDB/Scholars/pull/33 |
| PR title | `fix: enforce canonical www hostname redirects` |
| PR state | MERGED |
| Original PR commit | `680eb174a2d051f4ba13ae0e188ac5904f17ebcb` |
| Final PR commit (merged) | `11f2ee9214ef1e692eb7744d6a14cf96744cff3f` |
| Merge commit SHA | `e6fccf591131148e4516865ddd16422992ff3f1c` |
| Merge strategy | Merge commit (history preserved, no squash/rebase) |
| Merged to | `main` (remote `origin/main`) |

---

## 2. Pre-Merge Verification (All Passed)

All checks run on branch `audit/canonical-host-redirect-2026-11-13` at `11f2ee9`:

| Check | Command | Result | Exit code |
|---|---|---|---|
| TypeScript | `npx tsc --noEmit` | PASS | 0 |
| Unit + integration tests | `npm test` (`vitest run`) | PASS — 27 files, 143 tests | 0 |
| Production build | `npm run build` (`next build`) | PASS | 0 |
| Diff cleanliness | `git diff --check` (changed files) | PASS | 0 |
| Routes manifest | `.next/routes-manifest.json` | PASS — host-scoped 308 present | — |
| CI status checks | GitHub Actions (build, Vercel, Vercel Preview Comments) | All SUCCESS | — |

**Routes manifest verified** — contains the host-scoped redirect:
```json
{
  "source": "/:path*",
  "has": [{"type": "host", "value": "scholars.com.ng"}],
  "destination": "https://www.scholars.com.ng/:path*",
  "statusCode": 308
}
```

---

## 3. Production Deployment

| Field | Value |
|---|---|
| Vercel project | scholars (`prj_n4Unq6wzjbjRT9TcRGKvFD9jIfBk`) |
| Team | imperiokdbs-projects |
| Production branch | `main` |
| Deployment ID | `scholars-drboyk3pc-imperiokdbs-projects` |
| Deployment URL | https://scholars-drboyk3pc-imperiokdbs-projects.vercel.app |
| Environment | Production |
| Status | Ready |
| Triggered by | Merge of PR #33 to `main` |
| Corresponds to merge commit | `e6fccf591131148e4516865ddd16422992ff3f1c` |

The normal production deployment triggered automatically from the merge to `main` and reached a successful Ready state. No manual deployment was required. No Vercel settings, DNS records, environment variables, or project configuration were modified.

---

## 4. Production Redirect Verification Matrix

All production tests performed against the live domains with redirect-following disabled on the initial request (to capture initial status and `Location` header), then with redirect-following enabled to capture chain details.

### A. Apex host (`https://scholars.com.ng`) — all return 308 to www

| URL | Initial Status | Initial Location | Redirects (follow) | Final URL | Final Status | Canonical? |
|---|---|---|---|---|---|---|
| `/` | 308 | https://www.scholars.com.ng/ | 1 | https://www.scholars.com.ng/ | 200 | Yes |
| `/resources` | 308 | https://www.scholars.com.ng/resources | 1 | https://www.scholars.com.ng/resources | 200 | Yes |
| `/resources/how-to-find-legitimate-scholarships` | 308 | https://www.scholars.com.ng/resources/how-to-find-legitimate-scholarships | 1 | https://www.scholars.com.ng/resources/how-to-find-legitimate-scholarships | 200 | Yes |
| `/resources/category/scholarship-applications` | 308 | https://www.scholars.com.ng/resources/category/scholarship-applications | 1 | https://www.scholars.com.ng/resources/category/scholarship-applications | 200 | Yes |
| `/scholarships-in-nigeria` | 308 | https://www.scholars.com.ng/scholarships-in-nigeria | 1 | https://www.scholars.com.ng/scholarships-in-nigeria | 200 | Yes |
| `/opportunities-for-students` | 308 | https://www.scholars.com.ng/opportunities-for-students | 1 | https://www.scholars.com.ng/opportunities-for-students | 200 | Yes |
| `/legal/terms` | 308 | https://www.scholars.com.ng/legal/terms | 1 | https://www.scholars.com.ng/legal/terms | 200 | Yes |
| `/sitemap.xml` | 308 | https://www.scholars.com.ng/sitemap.xml | 1 | https://www.scholars.com.ng/sitemap.xml | 200 | Yes |
| `/robots.txt` | 308 | https://www.scholars.com.ng/robots.txt | 1 | https://www.scholars.com.ng/robots.txt | 200 | Yes |

### B. Canonical www host (`https://www.scholars.com.ng`) — all return 200, no redirect

| URL | Initial Status | Initial Location | Redirects | Final URL | Final Status | Canonical? |
|---|---|---|---|---|---|---|
| `/` | 200 | none | 0 | https://www.scholars.com.ng/ | 200 | Yes |
| `/resources` | 200 | none | 0 | https://www.scholars.com.ng/resources | 200 | Yes |
| `/resources/how-to-find-legitimate-scholarships` | 200 | none | 0 | https://www.scholars.com.ng/resources/how-to-find-legitimate-scholarships | 200 | Yes |
| `/resources/category/scholarship-applications` | 200 | none | 0 | https://www.scholars.com.ng/resources/category/scholarship-applications | 200 | Yes |
| `/scholarships-in-nigeria` | 200 | none | 0 | https://www.scholars.com.ng/scholarships-in-nigeria | 200 | Yes |
| `/opportunities-for-students` | 200 | none | 0 | https://www.scholars.com.ng/opportunities-for-students | 200 | Yes |
| `/legal/terms` | 200 | none | 0 | https://www.scholars.com.ng/legal/terms | 200 | Yes |
| `/sitemap.xml` | 200 | none | 0 | https://www.scholars.com.ng/sitemap.xml | 200 | Yes |
| `/robots.txt` | 200 | none | 0 | https://www.scholars.com.ng/robots.txt | 200 | Yes |

### C. Additional production checks

| Check | Result | Details |
|---|---|---|
| Query-string preservation | PASS | `https://scholars.com.ng/resources?utm_source=a&ref=abc` → 308 → `https://www.scholars.com.ng/resources?utm_source=a&ref=abc` |
| Trailing-slash behaviour | PASS | `https://scholars.com.ng/resources/` → 308 → `https://scholars.com.ng/resources` (Next.js trailing-slash normalization) → 308 → `https://www.scholars.com.ng/resources` (standard 2-hop, not a loop) |
| HTTP apex → HTTPS www | PASS | `http://scholars.com.ng/` → 308 → `https://scholars.com.ng/` (Vercel HTTPS enforcement) → 308 → `https://www.scholars.com.ng/` (app host canonicalization) |
| HTTP www → HTTPS www | PASS | `http://www.scholars.com.ng/` → 308 → `https://www.scholars.com.ng/` |
| Redirect loops | PASS | No loops detected on any tested URL |
| Unnecessary redirect chains | PASS | Apex → www is a single hop on HTTPS; no redundant redirects |
| WWW stays on canonical host | PASS | All www URLs return 200 with no `Location` header |
| Sitemap on www | PASS | `<loc>` values use `https://www.scholars.com.ng/` |
| Robots on www | PASS | `Sitemap: https://www.scholars.com.ng/sitemap.xml` |

### D. Legacy share URLs

**Not tested.** The task requires valid legacy `/s/{id}` and `/o/{id}` share URLs with actual public record IDs. No actual public legacy share record IDs are available in the repository seed data, and Supabase/database access is not authorized. No IDs were invented. Legacy share route canonicalization relies on the same `/:path*` host-scoped redirect rule, which is verified for all other paths.

---

## 5. SEO Regression Status

All canonical metadata continues to use `https://www.scholars.com.ng`:
- Sitemap `<loc>` values use the www host ✓
- Robots.txt sitemap directive uses the www host ✓
- No changes to canonical metadata, Open Graph URLs, JSON-LD URLs, or indexing policy ✓
- Resource Center public pages remain accessible (200 on www) ✓
- Protected-route behaviour unchanged ✓
- Expired-content policy unchanged ✓

---

## 6. Outstanding Items

| Item | Status | Notes |
|---|---|---|
| Legacy share URL testing | Not tested | No actual public record IDs available; not invented |
| Lint (non-interactive) | Not runnable | No ESLint config; `next lint` is interactive-only |

---

## 7. Conclusion

**Verdict: FIXED**

The canonical hostname redirect remediation has been:
1. Implemented in `next.config.js` as a host-scoped permanent (308) redirect from `scholars.com.ng` to `www.scholars.com.ng/:path*`
2. Peer-reviewed and merged via PR #33 (merge commit `e6fccf591131148e4516865ddd16422992ff3f1c`)
3. Deployed to production on Vercel (deployment `scholars-drboyk3pc`, Ready state)
4. Verified against the live production domains — all apex URLs return 308 to the matching www URL with paths and query strings preserved; all www URLs return 200 without redirect; no loops or unnecessary chains detected

The production canonical-host issue is fixed. Every request to `https://scholars.com.ng/*` now permanently redirects to the corresponding URL on `https://www.scholars.com.ng/*`, while requests already on `www.scholars.com.ng` are unaffected.
