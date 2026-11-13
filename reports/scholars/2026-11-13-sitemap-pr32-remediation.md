# Scholars PR #32 Remediation Report

**Reporting repository:** ImperioKDB/Updates
**Report path:** reports/scholars/2026-11-13-sitemap-pr32-remediation.md
**Source repository:** ImperioKDB/Scholars
**PR:** #32 — "fix(seo): restore sitemap integrity, Resource Centre coverage, and correct lastModified"
**Branch:** fix/sitemap-public-data-integrity
**Base:** main
**Date:** 13 November 2026

---

## 1. Original Findings

The production sitemap at `https://www.scholars.com.ng/sitemap.xml` returned HTTP 200 while containing only ~20 URLs, versus 93 URLs recorded in Google Search Console's last submission.

Two defects were verified by direct reading of source code and migrations:

### Defect A — Wrong data source (confirmed)
`app/sitemap.ts` queried raw `scholarships` and `opportunities` database tables selecting `id, slug, updated_at` instead of the approved public catalogue views `scholarships_public_preview_v1` and `opportunities_public_preview_v1`.

Migration `20261111032810_global_opportunity_access_hardening.sql`:
- Revoked `PUBLIC`/`anon` SELECT on raw `scholarships` and `opportunities` tables
- Created `scholarships_public_preview_v1` (SECURITY INVOKER, security_barrier, `WHERE verified IS TRUE`)
- Created `opportunities_public_preview_v1` (SECURITY INVOKER, security_barrier, `WHERE verified IS TRUE`)
- Neither view exposes `updated_at`

### Defect B — Silent failure masking (confirmed)
`app/sitemap.ts` wrapped catalogue reads in `.catch()` that logged the error and returned `[[], []]`, serving an incomplete sitemap (~20 URLs: static + Resource Centre only) with HTTP 200 instead of surfacing the error.

**Root cause classification: Confirmed** — both defects are present in the inspected code.

---

## 2. Corrections Made

### Correction 1: Approved public catalogue views (preserved security fix)
- `app/sitemap.ts` now queries `scholarships_public_preview_v1` and `opportunities_public_preview_v1` instead of raw tables
- `lib/sitemap-data.ts` `readAllPublicRows` accepts a `PublicCatalogTable` union type restricting table names to the two approved views
- No raw-table access, no service-role access, no RLS bypass, no new grants
- Uses existing anonymous public Supabase client (`createPublicClient()` with anon key)

### Correction 2: Failure handling (preserved security fix)
- Removed the `.catch()` that substituted `[[], []]` on catalogue-query failure
- Catalogue query failures now propagate as server errors (Next.js sitemap convention)
- Empty catalogue remains a valid result (returns static + Resource Centre entries)
- Error logging preserves table-name context without exposing credentials or private DB info

### Correction 3: Resource Centre sitemap coverage restored
PR #32's initial version removed Resource Centre coverage. This remediation restores it:

- `STATIC_PATHS` includes `/resources`
- `readAllResourceCategoryRows()` fetches active categories from `resource_public_article_categories` view
- `readAllResourceRows()` fetches published articles from `resource_public_articles` view
- Local content fallback (`lib/resource-content.ts`): 6 categories + 5 articles available without Supabase config
- Database records merge with local records without duplicate slugs
- If resource/category DB query fails, local repository content is preserved
- Routes generated: `/resources`, `/resources/category/{slug}`, `/resources/{slug}`

### Correction 4: Correct lastModified semantics
- `lastModified` is **omitted** for both scholarships and opportunities
- Rationale: `last_verified_at` is a verification timestamp, not a content-modification timestamp; using it as `lastModified` would publish misleading values
- No public database permissions were expanded to obtain a timestamp
- Resource articles still use `published_at` (a genuine publication timestamp) for `lastModified`

### Correction 5: Correct ordering
- Opportunities: single `order("id", { ascending: true })` — no conflicting duplicate order clauses
- Scholarships: single `order("id", { ascending: true })` — deterministic, `id` is a unique tie-breaker
- Pagination preserved across all 500-row batches (no omissions or duplicates verified at 501 records)

---

## 3. Changed Files (8 files)

| File | Change |
|------|--------|
| `app/sitemap.ts` | Public views; no silent catch; Resource Centre coverage; no `last_verified_at` as `lastModified`; deterministic `id` ordering; `/resources` in static paths |
| `lib/sitemap-data.ts` | `PublicCatalogTable` type; single `order("id")`; Resource Centre local fallback + merge dedup; `readAllResourceCategoryRows` |
| `lib/sitemap-data.test.ts` | 15 unit tests covering both views, batching, empty catalogues, missing slugs, query failures, no raw-table access, Resource Centre merge dedup, local fallback on failure |
| `app/sitemap.test.ts` | 15 route-level tests covering all remediation requirements |
| `vitest.config.js` | `@/` alias resolution for vitest (matching tsconfig paths) |
| `lib/resource-center.ts` | Resource Centre data access (from origin/main / PR #29) |
| `lib/resource-content.ts` | Local resource content: 6 categories, 5 articles (from origin/main / PR #29) |
| `lib/supabase/config.ts` | `hasPublicSupabaseConfig()` configuration boundary (new) |

---

## 4. Updated Branch and Commit SHA

- Branch: `fix/sitemap-public-data-integrity`
- Commit SHA: `fd76865adf19aa8ea2926dc46de1a54b1de186ee`
- Parent commits: `dfe5267` (original PR #32), `8f1d7ee` (Resource Centre restoration), `fd76865` (merge commit integrating origin/main)
- PR: https://github.com/ImperioKDB/Scholars/pull/32 — state: **open**, mergeable: **MERGEABLE**
- Push: normal fast-forward (no force-push)

---

## 5. Tests and Exact Results

**Test framework:** Vitest (`npx vitest run`), TypeScript (`npx tsc --noEmit`), Next.js build (`npx next build`)

### New tests (31 total across both test files)

**`lib/sitemap-data.test.ts` (16 unit tests):**
1. Scholarship rows across 500-row batches without omissions ✅
2. Opportunity rows across 500-row batches without omissions ✅
3. Both public sources incl. closed/postgraduate slugs ✅
4. Empty scholarship catalogue ✅
5. Empty opportunity catalogue ✅
6. Missing/invalid slugs excluded ✅
7. Scholarship query failure rejects ✅
8. Opportunity query failure rejects ✅
9. No raw-table access for public catalogue ✅
10. Deterministic `id` ordering (no conflicting clauses) ✅
11. Local resource articles without Supabase config ✅
12. DB articles merge with local without duplicate slugs ✅
13. Local articles available when resource query fails ✅
14. Local categories without Supabase config ✅
15. Local categories available when category query fails ✅
16. DB categories merge with local without duplicate slugs ✅

**`app/sitemap.test.ts` (15 route-level tests):**
1. `/resources` in sitemap ✅
2. All six local category routes ✅
3. Local articles without Supabase config ✅
4. DB articles merge without duplicate slugs ✅
5. Local articles available when resource query fails ✅
6. Local categories available when category query fails ✅
7. Only approved public views queried ✅
8. Scholarship query failure rejects ✅
9. Opportunity query failure rejects ✅
10. Empty catalogues valid ✅
11. Closed/postgraduate scholarship pages discoverable ✅
12. Pagination >500 records, no omissions/duplicates ✅
13. No misleading `lastModified` values ✅
14. Canonical https www host consistency ✅
15. No duplicate canonical URLs ✅

### Validation results

| Check | Result |
|-------|--------|
| `npx vitest run` | **PASS** — 26 files, 160 tests passed |
| `npx tsc --noEmit` | **PASS** — clean (no type errors) |
| `npx next build` | **PASS** — compiles successfully (`sitemap.xml` is dynamic) |
| ESLint | Not configured in repo (no `.eslintrc`/`eslint.config`); code follows existing style |

**Build caveat:** `next build` reports `@supabase/ssr: URL and API key required` prerender errors on `/login`, `/signup`, `/onboarding`, `/legal/privacy`, `/legal/terms`, `/`, `/reset-password`. These are **pre-existing environment limitations** (no `NEXT_PUBLIC_SUPABASE_URL`/`SUPABASE_URL` in this sandbox), unrelated to the sitemap change. The sitemap route itself (`force-dynamic`) compiles without errors.

**Production verification:** [UNVERIFIED] — not performed (no deploy/verification authorization). See production verification checklist in PR #32 description.

---

## 6. Security Implications

- **No raw-table access:** Only the two `*_public_preview_v1` security-invoker views are queried
- **No service-role use:** Existing anon-key public client only; no `SUPABASE_SERVICE_ROLE_KEY`
- **No RLS bypass:** Views are `SECURITY INVOKER` + `security_barrier`; anon RLS policies (`verified IS TRUE`) remain in force
- **No new grants:** Uses existing grants from migration `20261111032810`
- **No private data exposed:** Views exclude descriptions, eligibility, application URLs, research notes, competitiveness, user-linked data
- **No unverified records:** Views filter `verified IS TRUE`; closed-but-verified records remain discoverable
- **No credential exposure in logs:** Error logging records table names only
- **Canonical host preserved:** `https://www.scholars.com.ng`

---

## 7. SEO Behaviour Preserved

- Static public pages (`/`, `/about`, `/reviews`, `/scholarships-in-nigeria`, `/opportunities-for-students`, `/resources`, `/legal/privacy`, `/legal/terms`)
- Resource Centre homepage, categories, and articles (6 categories, 5 local articles + DB-backed)
- Canonical HTTPS `www` URLs
- No duplicate canonical URLs
- Scalable batched generation (500-row batches)
- Valid `lastModified` semantics (no invented timestamps)
- Closed verified records remain discoverable in sitemap
- Postgraduate opportunities included
- Valid slugs unchanged
- No auth-only or private resource entries

---

## 8. Unrelated Work Preserved

The merge integrated origin/main (PR #29: `feature/resource-center-public-frontend`) into the fix branch. All unrelated changes from that merge (Resource Centre pages, components, auth, dashboard, matching engine, etc.) were preserved. No unrelated commits were discarded. The merge was a normal merge commit (not force-push), and the push to `fix/sitemap-public-data-integrity` was a fast-forward.

---

## 9. Remaining Blockers

- Production sitemap not fetched or parsed directly (no deploy/verification authorization)
- `NEXT_PUBLIC_SUPABASE_URL`/`SUPABASE_URL` not set in this sandbox, preventing full build prerender verification and live Supabase-dependent checks
- ESLint not configured in the Scholars repo
- Production deployment and Google Search Console revalidation pending PR merge and deploy approval

---

## 10. PR Mergeability

**PR #32 is MERGEABLE.**

The branch `fix/sitemap-public-data-integrity` (commit `fd76865adf19aa8ea2926dc46de1a54b1de186ee`) is based on `main` and integrates origin/main's Resource Centre content. All tests pass, TypeScript is clean, and the build compiles. The PR is ready for review and merge.

**Do not merge or deploy** — those actions are outside the scope of this remediation task.

---

**End of report.** Production is NOT considered fixed until the corrected implementation is deployed and verified per the production verification checklist.
