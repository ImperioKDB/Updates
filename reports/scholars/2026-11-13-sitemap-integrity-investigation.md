# Scholars Sitemap Integrity Investigation Findings

**Reporting repository:** ImperioKDB/Updates
**Report path:** reports/scholars/2026-11-13-sitemap-integrity-investigation.md
**Source repository (read-only):** ImperioKDB/Scholars
**Production domain:** https://www.scholars.com.ng
**Investigation date:** 13 November 2026

---

## 1. Executive summary

The production sitemap at `https://www.scholars.com.ng/sitemap.xml` was reported to return HTTP 200 while containing only ~20 URLs, versus 93 URLs recorded in Google Search Console's last submission.

Investigation of the Scholars repository confirmed the root cause. Two defects exist in the sitemap implementation:

1. `app/sitemap.ts` / `lib/sitemap-data.ts` query the raw `scholarships` and `opportunities` database tables (selecting an `updated_at` column) instead of the approved public catalogue views `scholarships_public_preview_v1` and `opportunities_public_preview_v1`. Migration `20261111032810_global_opportunity_access_hardening.sql` revoked `anon`/`PUBLIC` SELECT on those raw tables, and neither public view exposes `updated_at`.

2. `app/sitemap.ts` catches catalogue-query failures and substitutes empty arrays (`[[], []]`), so a failing query returns an incomplete sitemap with HTTP 200 instead of surfacing the error.

Root cause classification: **Confirmed** (both defects verified by reading source code and migrations).

A repair branch `fix/sitemap-public-data-integrity` (commit `dfe5267a28f519716fcd20f010031ee4a6a26837`, parent `de9b40695e8ebca26d14bcaae972f5c549cdd4f6`) has been prepared and PR #32 ("fix(seo): restore sitemap integrity and public catalogue access") is open against `main`. The repair has not been deployed or verified in production.

---

## 2. Investigation date and repository HEAD inspected

- Investigation date: 13 November 2026.
- Scholars repository HEAD inspected at the start of investigation:
  - Working tree branch: `feature/resource-center-public-forward`, commit `79456a0933eb27c6c848865cb35717c8b36ec0b5` ("feat: accessible mobile Resource Centre navigation + baseline audit report"), up to date with its remote.
  - `main` branch: commit `de9b40695e8ebca26d14bcaae972f5c549cdd4f6`.
- The fix was later authored on a new branch `fix/sitemap-public-data-integrity` based on `main` (`de9b406`), commit `dfe5267a28f519716fcd20f010031ee4a6a26837`.

Note: The working tree contained numerous pre-existing uncommitted modifications unrelated to the sitemap (auth/admin/resource-center files). These were not touched by this investigation and are not part of the fix branch.

---

## 3. Current SEO branch and PR status

- Dedicated branch: `fix/sitemap-public-data-integrity` (exists locally and on `origin`).
- Commit: `dfe5267a28f519716fcd20f010031ee4a6a26837`.
- PR: #32, "fix(seo): restore sitemap integrity and public catalogue access", state **open**, base `main`, head `ImperioKDB:fix/sitemap-public-data-integrity`.
- PR URL: https://github.com/ImperioKDB/Scholars/pull/32
- PR is **not merged or approved**. No deployment to Vercel was performed.
- PR contents (5 files, +368/-35): `app/sitemap.ts`, `lib/sitemap-data.ts`, `lib/sitemap-data.test.ts`, `app/sitemap.test.ts` (new), `vitest.config.js` (new).

---

## 4. Relevant files inspected

The following files were read directly during investigation:

- `app/sitemap.ts` — sitemap route generator.
- `lib/sitemap-data.ts` — `readAllPublicRows` data reader.
- `lib/sitemap-data.test.ts` — existing sitemap unit tests.
- `lib/supabase/public.ts` — `createPublicClient()` (anon-key public client).
- `supabase/migrations/20261111032810_global_opportunity_access_hardening.sql` — creates the two public preview views and revokes raw-table anon access.
- `supabase/migrations/20261111033130_revoke_legacy_preview_view_anon.sql` — revokes legacy preview views from anon.
- `supabase/migrations/20261107130100_resource_center_schema.sql` — Resource Centre public projection views.
- `lib/resource-content.ts` — `LOCAL_RESOURCE_CATEGORIES` (6 categories) and `LOCAL_RESOURCE_ARTICLES` (5 articles).
- `lib/dates.ts` — `isClosedListing()` deadline helper.
- `app/scholarship/[slug]/page.tsx` — public scholarship detail page (queries public preview view, renders CLOSED status).
- `app/opportunity/[slug]/page.tsx` — public opportunity detail page (queries public preview view, renders CLOSED status).
- `lib/resource-center.ts` — Resource Centre data access and canonical-URL helper (`APPROVED_CANONICAL_HOST = "www.scholars.com.ng"`).

---

## 5. Verified database public-view architecture

Migration `20261111032810_global_opportunity_access_hardening.sql` defines the approved public catalogue access path:

**View: `public.scholarships_public_preview_v1`**
- Source: `public.scholarships`, filter `WHERE verified IS TRUE`.
- Options: `WITH (security_barrier = true, security_invoker = true)`.
- Columns exposed: `id, slug, title, provider_name, amount, deadline, opens_at, last_cycle_closed_at, level, discipline, verified, last_verified_at`.
- Does NOT expose `updated_at`.

**View: `public.opportunities_public_preview_v1`**
- Source: `public.opportunities`, filter `WHERE verified IS TRUE`.
- Options: `WITH (security_barrier = true, security_invoker = true)`.
- Columns exposed: `id, slug, type, title, provider_name, duration, location, compensation, deadline, verified`.
- Does NOT expose `updated_at` or any timestamp.

**Grants and privileges (same migration):**
- `REVOKE ALL PRIVILEGES` on both views from `PUBLIC, anon, authenticated`; then `GRANT SELECT` on both views TO `anon, authenticated`.
- Raw tables `public.opportunities`, `public.scholarships`: `REVOKE ALL PRIVILEGES ... FROM PUBLIC, anon`; `GRANT SELECT ... TO authenticated` only.
- Column-level anon grants removed for restricted fields; narrower column grants kept for the safe fields each view projects.
- RLS policies: `opportunities_public_preview_verified` (anon, `verified IS TRUE`) and `scholarships_public_preview_verified` (anon, `verified IS TRUE`).

Migration `20261111033130_revoke_legacy_preview_view_anon.sql` revokes the legacy `opportunity_public_previews` / `scholarship_public_previews` views from `PUBLIC, anon`.

**Conclusion:** Anonymous catalogue access must go through the two `*_public_preview_v1` security-invoker views using the anon key. Raw `scholarships`/`opportunities` tables are not readable by `anon`. Neither view exposes `updated_at`.

**Resource Centre public views** (migration `20261107130100_resource_center_schema.sql`): `resource_public_categories`, `resource_public_articles`, `resource_public_article_categories`, `resource_public_editorial_identities` — security-barrier projection views, granted to `anon, authenticated`.

---

## 6. Verified sitemap data-source findings

**Q1. Which public views are approved for anonymous scholarship and opportunity catalogue access?**
`scholarships_public_preview_v1` and `opportunities_public_preview_v1` — **verified** from migration `20261111032810`.

**Q2. What columns do those views actually expose?**
- Scholarships: `id, slug, title, provider_name, amount, deadline, opens_at, last_cycle_closed_at, level, discipline, verified, last_verified_at`.
- Opportunities: `id, slug, type, title, provider_name, duration, location, compensation, deadline, verified`.
- **Verified** from migration source.

**Q3. Does the sitemap currently request columns unavailable to anonymous users?**
**Yes — confirmed.** `app/sitemap.ts` calls `readAllPublicRows<SitemapRow>("scholarships", "id, slug, updated_at")` and `readAllPublicRows<SitemapRow>("opportunities", "id, slug, updated_at")`. The raw tables are not readable by `anon`, and neither public view exposes `updated_at`.

**Q4. Are the views accessible using the application's existing public Supabase client?**
**Yes — confirmed.** `lib/supabase/public.ts` `createPublicClient()` builds the anon-key client (`NEXT_PUBLIC_SUPABASE_URL` + `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `auth.persistSession: false`). Migration grants `SELECT` on both views to `anon` with matching column-level source-table grants and anon RLS policies. The public detail pages (`app/scholarship/[slug]/page.tsx`, `app/opportunity/[slug]/page.tsx`) already use `createPublicClient()` against these same views.

**Q5. Are closed scholarship and opportunity records still eligible for sitemap inclusion?**
**Yes — confirmed.** Views filter `verified IS TRUE` only; they do not exclude closed/expired records. The public detail pages render a CLOSED / "Applications closed" banner for closed listings (`lib/dates.ts` `isClosedListing()`), and those pages remain discoverable.

**Q6. Are expired records excluded where required?**
Closed/expired verified records remain in the sitemap source (their detail pages stay discoverable with a CLOSED status). Active public listings apply their own deadline filters elsewhere. Expiration is NOT used to remove records from the sitemap — **verified** from view definitions (`WHERE verified IS TRUE` only) and detail-page behavior.

**Q7. Are postgraduate opportunities included?**
**Yes — confirmed.** The scholarships view exposes `level` (which includes postgrad) and includes all verified rows regardless of level. No level filtering is applied in the sitemap.

**Q8. Does the sitemap include all six Resource Centre guides and their categories?**
The sitemap includes Resource Centre entries via `readAllResourceRows()` / `readAllResourceCategoryRows()`. `lib/resource-content.ts` defines 6 local categories and 5 local articles; public projection views exist for database-backed articles. All six categories (`scholarship-applications`, `essays-and-letters`, `interviews-and-tests`, `study-abroad-and-funding`, `study-techniques`, `scam-awareness`) are present in `LOCAL_RESOURCE_CATEGORIES`. **Verified** from `lib/resource-content.ts` and `lib/sitemap-data.ts`.

**Q9. Does the current error-handling logic conceal database failures?**
**Yes — confirmed (defect).** `app/sitemap.ts` wraps the catalogue reads in `.catch()` that logs the error and returns `[[], []]`, serving an incomplete sitemap with HTTP 200. `lib/sitemap-data.ts` `readAllPublicRows` throws on error, but the catch in `app/sitemap.ts` swallows it.

**Q10. What precisely explains the 20-URL production response, if determinable?**
The code logic explains it: when the catalogue query fails (raw-table access now blocked for `anon`), the `.catch()` substitutes `[[], []]`, so only static routes (~8) plus Resource Centre articles/categories render — approximately 20 URLs — returned with HTTP 200.
- **[INFERENCE, not directly production-verified]:** I did not fetch `https://www.scholars.com.ng/sitemap.xml` in this environment (no deployment/verification authorization, and production fetch was not performed). The ~20-URL count and 93-URL GSC figure come from the task brief / prior review, not from a direct production fetch I performed.

---

## 7. Verified error-handling findings

Current behavior (defective):
- `app/sitemap.ts` line ~32-35: `.catch((error) => { console.error(...); return [[], []] as [SitemapRow[], SitemapRow[]]; })`.
- `lib/sitemap-data.ts` `readAllPublicRows`: logs `[sitemap] failed to read public <table>` and throws `Unable to build sitemap from public <table>`.
- The catch converts a failed catalogue query into empty arrays, so the route returns a successful-but-incomplete sitemap (HTTP 200).
- No distinction is made between an empty catalogue (valid) and a failed query (error).

Required behavior (per repair):
- Distinguish empty catalogue from failed query.
- Preserve useful error details server-side (sanitized: no credentials/tokens/private DB info).
- Never silently represent an unsuccessful query as a complete sitemap.
- Follow Next.js sitemap conventions and the app's error-handling architecture (fail as a server error; do not hardcode fabricated fallback URLs).

---

## 8. Evidence explaining the production sitemap's 20-URL response

**Evidence (code-level, verified):** The sitemap route's `.catch()` substitutes `[[], []]` on catalogue-query failure. With raw-table reads blocked for `anon` (migration `20261111032810`), the catalogue query fails, empty arrays are substituted, and only static + Resource Centre URLs render (~20), with HTTP 200.

**Production verification status:** [UNVERIFIED] — I did not perform a live fetch of `https://www.scholars.com.ng/sitemap.xml` or parse the production XML. The ~20-URL and 93-URL figures are from the task brief / prior SEO review, not direct observation by me. This must be confirmed post-deploy per the production verification checklist.

---

## 9. Security implications

- **No raw-table access:** The repair reads only the two `*_public_preview_v1` security-invoker views, never the raw `scholarships`/`opportunities` tables.
- **No service-role use:** The existing `createPublicClient()` (anon key) is used; no `SUPABASE_SERVICE_ROLE_KEY` or elevated credentials are introduced for the sitemap.
- **No RLS bypass:** Views are `SECURITY INVOKER` + `security_barrier`; caller RLS and column privileges apply. Anon RLS policies (`*_public_preview_verified`, `verified IS TRUE`) remain in force.
- **No private data exposed:** Views exclude descriptions, eligibility, application URLs, research notes, competitiveness, and user-linked data. The sitemap selects only `id, slug` (and `last_verified_at` for scholarships).
- **No unpublished records:** Views filter `verified IS TRUE`; unverified/private records are excluded.
- **No credential exposure in logs:** Error logging records table names and generic messages only.
- **Canonical host preserved:** URLs use `NEXT_PUBLIC_APP_URL || "https://www.scholars.com.ng"` (HTTPS www).
- **robots.txt and auth protections unchanged.**

---

## 10. Existing SEO behaviour that must be preserved

- Static public pages (`/`, `/about`, `/reviews`, `/scholarships-in-nigeria`, `/opportunities-for-students`, `/resources`, `/legal/privacy`, `/legal/terms`).
- Resource Centre homepage, category, and article URLs (6 categories, 5 local articles; public projection views for DB-backed articles).
- Canonical HTTPS `www` URLs (`https://www.scholars.com.ng`).
- No duplicate canonical URLs.
- Scalable batched sitemap generation (500-row batches).
- Valid `lastModified` semantics (use existing permitted timestamp; do not invent timestamps).
- Closed verified records remain discoverable in the sitemap; detail pages render CLOSED status.
- Postgraduate opportunities included where eligible.
- Valid slugs unchanged (title-derived with UUID suffix, migration `0031_add_public_catalog_slugs`).
- No sitemap entries for authentication-only pages or private resources.
- Expired records excluded from active listings (applied elsewhere); closed records remain in sitemap.

---

## 11. Tests performed and actual results

Test framework: Vitest (`npx vitest run`), TypeScript (`npx tsc --noEmit`), Next.js build (`npx next build`).

**New tests added (in PR #32):**
- `lib/sitemap-data.test.ts`: 9 unit tests — both public views across 500-row batches, empty scholarship catalogue, empty opportunity catalogue, missing/invalid slugs excluded, scholarship query failure, opportunity query failure, no raw-table access.
- `app/sitemap.test.ts`: 4 route-level tests — full sitemap path (scholarship/opportunity/Resource Centre/static URLs, canonical https www host, no duplicates, valid lastModified), closed-record inclusion, failed scholarship query rejects, failed opportunity query rejects. The route-level test asserts a failed catalogue query does NOT produce a misleading complete sitemap.

**Actual results:**
- `npx vitest run`: **36 files, 192 tests passed** (includes the 13 new sitemap tests).
- `npx tsc --noEmit`: **clean** (no type errors).
- `npx next build`: **compiled successfully** (`sitemap.xml` is dynamic/server-rendered on demand).
- ESLint: not configured in this repo (no `.eslintrc`/`eslint.config`); `next lint` prompts interactively to create one, so it was not run. Code follows existing style.

**Build caveat:** `next build` reports `@supabase/ssr: Your project's URL and API key are required` prerender errors on `/login`, `/signup`, `/onboarding`, `/legal/privacy`, `/legal/terms`, `/`, `/reset-password`. These are **pre-existing environment limitations** (no `NEXT_PUBLIC_SUPABASE_URL`/`SUPABASE_URL` set in this sandbox), unrelated to the sitemap change. The sitemap route itself is `force-dynamic` and is not in the error list.

**Production verification:** [UNVERIFIED] — not performed (no deploy/verification authorization). See production verification checklist in PR #32 description.

---

## 12. Root cause classification

**Confirmed.**

Both defects were verified by direct reading of source code and migrations:

1. Sitemap queries raw `scholarships`/`opportunities` tables selecting `updated_at` (column unavailable to anon; tables not readable by anon) instead of the approved public views — **verified**.
2. `.catch()` substitutes `[[], []]` on catalogue failure, returning an incomplete sitemap with HTTP 200 — **verified**.

Neither defect is a hypothesis; both are present in the inspected code.

---

## 13. Recommended implementation

Implement the changes in PR #32 (branch `fix/sitemap-public-data-integrity`):

**A. Correct the data source**
- Switch `readAllPublicRows` to accept `PublicCatalogTable` = `scholarships_public_preview_v1` \| `opportunities_public_preview_v1`.
- Query `scholarships_public_preview_v1` (`id, slug, last_verified_at`, ordered by `last_verified_at`) and `opportunities_public_preview_v1` (`id, slug`, ordered by `id`).
- Do not query raw tables. `updated_at` is not exposed by either view; do not add it or invent timestamps.
- Scholarship `lastModified` = `last_verified_at` where present, else `undefined`. Opportunity `lastModified` = `undefined` (no permitted timestamp; omit rather than invent).

**B. Correct failure handling**
- Remove the `.catch()` that substitutes `[[], []]`.
- Catalogue query failures propagate as server errors (Next.js sitemap convention: an unsuccessful query must not yield HTTP 200 with an incomplete sitemap).
- Log sanitized error details server-side (no credentials/tokens/private DB info).
- Empty catalogue remains a valid result (static + Resource Centre entries only).

**C. Preserve approved SEO behaviour**
- Keep static pages, Resource Centre entries, canonical https://www URLs, no duplicates, batched pagination, `lastModified` semantics, closed-record inclusion, postgraduate inclusion, valid slugs.
- No hardcoded fabricated fallback URLs.

**D. Add regression tests** (already added in PR #32) — see section 11.

---

## 14. Outstanding questions and blockers

- [UNVERIFIED] Production sitemap not fetched or parsed. The ~20-URL / 93-URL figures are from the task brief, not direct observation. Must confirm post-deploy: fetch `https://www.scholars.com.ng/sitemap.xml`, confirm HTTP status, parse XML, count/group URLs, compare to eligible public records, check duplicates and canonical host.
- [UNVERIFIED] Exact production URL count at verification time cannot be hardcoded; completeness must be judged against eligible public records then.
- Environment limitation: no `NEXT_PUBLIC_SUPABASE_URL`/`SUPABASE_URL` in this sandbox, so full `next build` prerender verification and live Supabase-dependent checks could not be completed. The sitemap route compiles and is `force-dynamic`.
- ESLint is not configured in the Scholars repo; lint was not run. (Not a blocker.)
- Pre-existing uncommitted working-tree changes in Scholars (auth/admin/resource-center, 37 files) are unrelated to this fix and were not touched; they remain in the working tree/stash and are outside this repair's scope.
- The repair has not been deployed or merged. PR #32 is open and awaiting review/merge and production deployment approval.

---

## Distinction: facts vs hypotheses

**Facts (verified by reading code/migrations and running tests):**
- Public views exist and their columns (migration `20261111032810`).
- Raw-table anon access revoked (same migration).
- Current sitemap queries raw tables with `updated_at` and swallows failures via `.catch()`.
- `last_verified_at` exists on the scholarships view; opportunities view has no timestamp.
- Canonical host is `https://www.scholars.com.ng`.
- Tests passed: 192 vitest, tsc clean, next build compiled.

**Hypotheses / inferences (not directly production-verified):**
- The production ~20-URL response is explained by the `.catch()` empty-array substitution when raw-table reads fail for `anon`. This is a code-logic inference; production fetch not performed.
- The 93-URL GSC figure is from the task brief, not observed by me.

---

**End of report.** Production is NOT considered fixed until the corrected implementation is deployed and verified per the production verification checklist.
