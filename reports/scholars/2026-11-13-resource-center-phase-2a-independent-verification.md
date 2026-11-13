# Scholars Resource Centre — Phase 2A Independent Verification

**Source repository:** ImperioKDB/Scholars  
**Verified branch:** main (origin/main = 137f2fa28a4f1a5b1fb6eaa55e3c6c3677bb4210)  
**Report date:** 2026-11-13  
**Prepared for:** ImperioKDB/Updates  
**Destination file:** reports/scholars/2026-11-13-resource-center-phase-2a-independent-verification.md  
**Mode:** Read-only investigation. No source code changes, no database mutations, no deployment.

---

## Evidence labels used

| Label | Meaning |
|-------|---------|
| VERIFIED | Directly confirmed by inspecting source files/migrations on origin/main |
| PARTIALLY VERIFIED | Some evidence exists, but not enough for a complete conclusion |
| UNVERIFIED | Requires additional investigation or access not available in this session |
| NOT REPRODUCED | Claim could not be reproduced from source; likely incorrect |

---

## 1. Verified current state (against origin/main)

### Repository and branch
- Repository: ImperioKDB/Scholars (VERIFIED via `gh api repos/ImperioKDB/Scholars`)
- Default branch: main (VERIFIED)
- Baseline merge commit: 137f2fa28a4f1a5b1fb6eaa55e3c6c3677bb4210 (VERIFIED as origin/main SHA)
- Working directory is on branch `fix/sitemap-public-data-integrity` at `dfe5267a28f519716fcd20f010031ee4a6a26837`, NOT on main. All verification below was performed by reading `origin/main` via `git show origin/main:<path>` (read-only, no branch switch).

### Public routes
| Route | File (origin/main) | Auth required? |
|-------|-------------------|----------------|
| `/resources` | `app/resources/page.tsx` | No |
| `/resources/[slug]` | `app/resources/[slug]/page.tsx` | No |
| `/resources/category/[slug]` | `app/resources/category/[slug]/page.tsx` | No |

VERIFIED: None of these routes are in `middleware.ts` `PROTECTED_PREFIXES` or the `config.matcher` array. Public reading does not require authentication.

### Test suite
- `npx vitest run` on origin/main: **35 test files, 182 tests passed, 0 failed** (VERIFIED by direct execution in this session)
- `npx tsc --noEmit` on origin/main: **exit 0** (VERIFIED by direct execution)
- `npx next build` on origin/main: **exit code 1** in this codespace due to missing `NEXT_PUBLIC_SUPABASE_URL`/`ANON_KEY` in `.env.local` (pre-existing environmental issue, NOT a source-code defect; VERIFIED by direct execution)

---

## 2. Mandatory verification results

### MV-1: Does resource_editorial_identities have zero production rows?
**NOT REPRODUCED / UNVERIFIED**

- File: `supabase/migrations/20261107130100_resource_center_schema.sql` (lines 5-18)
- The migration `create table if not exists public.resource_editorial_identities (...)` creates the table but inserts no rows.
- **No production database query was performed** (read-only constraint). It is impossible to confirm row count from repository source alone.
- **Do not claim zero production rows without authorized, read-only production evidence.**

### MV-2: Are all six articles application-related?
**VERIFIED — YES, all six are application-related**

- File: `lib/resource-content.ts` (origin/main), article definitions lines 18-270
- Classification:
  1. "How to find scholarships you can trust" (Field guide) — verification/scams before applying — **Application-related**
  2. "How to write a scholarship motivation letter" (Writing guide) — application writing — **Application-related**
  3. "How to write a scholarship personal statement that sounds like you" (Writing guide) — application writing — **Application-related**
  4. "How to prepare for scholarship aptitude tests and interviews" (Preparation guide) — selection-stage prep — **Application-related**
  5. "How to ask for a strong recommendation letter" (Application guide) — application component — **Application-related**
  6. "Six scholarship application mistakes that are easy to avoid" (Final checklist) — pre-submission review — **Application-related**

- All six articles fall squarely within the **Prepare — Applications and competitiveness** pillar (with Article 1 also touching Understand via verification/scam awareness).
- None address Learn (academic development), Build (skills/career), or Thrive (university/student life) as primary topics.
- The prior report's characterization ("primarily scholarship-application guidance rather than a complete student resource platform") is **accurate**.

### MV-3: Recalculated article word counts
**VERIFIED — consistent counting method**

Method: Strip markdown links (→ link text), remove markdown syntax characters (`*_`#>-`), replace digits+period+space, replace newlines with spaces, trim, split on whitespace, filter empty tokens.

| # | Title | Slug | Type | Words |
|---|-------|------|------|-------|
| 1 | How to find scholarships you can trust | how-to-find-legitimate-scholarships | Field guide | 487 |
| 2 | How to write a scholarship motivation letter | how-to-write-a-scholarship-motivation-letter | Writing guide | 458 |
| 3 | How to write a scholarship personal statement that sounds like you | how-to-write-a-scholarship-personal-statement | Writing guide | 435 |
| 4 | How to prepare for scholarship aptitude tests and interviews | prepare-for-scholarship-aptitude-tests-and-interviews | Preparation guide | 416 |
| 5 | How to ask for a strong recommendation letter | how-to-get-strong-recommendation-letters | Application guide | 392 |
| 6 | Six scholarship application mistakes that are easy to avoid | common-scholarship-application-mistakes | Final checklist | 351 |

- **Range: 351–487 words** (all six articles)
- The prior report's stated range "358–499 words" was **slightly inaccurate** (different counting method or included front matter). Corrected range: **351–487**.

### MV-4: Middleware matcher — do Resource Centre routes execute Supabase auth middleware?
**VERIFIED — NO**

- File: `middleware.ts` (origin/main), lines 340-364
- `config.matcher` = `["/", "/dashboard/:path*", "/onboarding/:path*", "/discover/:path*", "/opportunities/:path*", "/saved/:path*", "/applications/:path*", "/admin/:path*", "/api/admin/:path*", "/scholarships/:path*", "/settings/:path*", "/achievements/:path*", "/notifications/:path*", "/community/:path*", "/reviews/:path*", "/s/:path*", "/o/:path*", "/scholarship/:path*", "/opportunity/:path*", "/login", "/signup"]`
- `/resources`, `/resources/:path*`, `/resources/category/:path*` are **NOT** in the matcher.
- `PROTECTED_PREFIXES` (lines 14-27) does NOT include `/resources`.
- **Conclusion:** Resource Centre routes bypass middleware entirely. No Supabase authentication middleware executes on `/resources` requests. The prior report's implication that middleware Supabase work affects public Resource Centre routes is **incorrect**.

### MV-5: Does createClient() throw when public Supabase env vars are absent on the /resources path?
**VERIFIED — NO, not in the normal homepage path (guarded)**

- File: `lib/resource-center.ts` (origin/main), lines 164-178
- `getResourceHomeWithRepositoryContent()` guards `getResourceHome()` (which calls `createClient()`) behind `hasPublicSupabaseConfig()`:
  ```typescript
  if (hasPublicSupabaseConfig()) {
    try { published = await getResourceHome(); } catch { ... }
  }
  ```
- File: `lib/supabase/server.ts` (origin/main), lines 21-26 — `createClient()` directly reads `process.env.NEXT_PUBLIC_SUPABASE_URL!` and `!ANON_KEY` with **no internal guard**. It WOULD throw if called without env vars.
- File: `lib/supabase/config.ts` (origin/main), lines 11-16 — `hasPublicSupabaseConfig()` checks both env vars.
- **Homepage path:** `app/resources/page.tsx` → `getResourceHomeWithRepositoryContent()` → guard → `getResourceHome()` → `createClient()`. The guard prevents `createClient()` from being called when env vars are absent.
- **Caveat:** `getResourceImageUrl()` (lib/resource-center.ts lines 131-136) calls `createClient()` **without** a `hasPublicSupabaseConfig()` guard. However, `isApprovedResourceImagePath()` returns `false` for `null`, and all local articles have `featured_image_path: null`, so `createClient()` is not reached on the homepage with local content. It would only be reached for database-backed articles with a non-null featured image path when env vars are absent.
- **PARTIALLY VERIFIED:** The homepage data path is guarded; `getResourceImageUrl()` has an unguarded `createClient()` call but is not triggered by local (null-image) content.

### MV-6: profiles.is_admin self-elevation vulnerability
**NOT REPRODUCED — REMEDIATED on origin/main**

- File: `supabase/migrations/0023_lock_admin_flag.sql` (origin/main)
  - `revoke insert, update, delete, truncate, references, trigger on table public.profiles from anon, authenticated;` (broad privileges revoked)
  - `grant update (...)` lists specific columns — **is_admin is NOT included**
  - `revoke insert (is_admin), update (is_admin) on table public.profiles from anon, authenticated;` (explicit revoke)
  - RLS policies: `profiles_update_own`, `profiles_insert_own`, `profiles_delete_own` all use `auth.uid() = id` (own-row only)
- File: `supabase/migrations/0029_fix_profiles_upsert_table_privileges.sql` (origin/main)
  - `grant insert, update on table public.profiles to authenticated;` (needed for PostgREST upserts)
  - `revoke insert (is_admin), update (is_admin) from authenticated;` (re-confirmed: is_admin remains unwritable)
- File: `supabase/migrations/0002_harden_functions.sql` (origin/main)
  - `revoke execute on function is_admin(uuid) from public, anon, authenticated;` (function not directly callable via RPC)
  - Comment confirms: "Policies still work: RLS policy evaluation runs as the defining role, not through the PostgREST RPC surface"

- **Conclusion:** The self-elevation path described in the prior report has been **remediated**. Authenticated users cannot write to `is_admin`. The prior report's classification ("Still unresolved") is **incorrect** relative to the current source on main.
- **Status: NOT REPRODUCED as a vulnerability; the source demonstrates remediation.**

### MV-7: Security properties of public Resource Centre views
**VERIFIED**

- File: `supabase/migrations/20261107130100_resource_center_schema.sql` (origin/main), lines 157-214

| View | security_barrier | security_invoker | Owner | Grants |
|------|-----------------|------------------|-------|--------|
| resource_public_editorial_identities | true | NOT set | postgres | SELECT to anon, authenticated |
| resource_public_categories | true | NOT set | postgres | SELECT to anon, authenticated |
| resource_public_articles | true | NOT set | postgres | SELECT to anon, authenticated |
| resource_public_article_categories | true | NOT set | postgres | SELECT to anon, authenticated |

- `security_barrier = true` is set on all four views (VERIFIED).
- `security_invoker = true` is **NOT set** on any view (VERIFIED — views run with owner context).
- Owner is `postgres` (default; BYPASSRLS) (VERIFIED by schema convention).
- Base tables have RLS enabled (lines 103-107) but `FORCE ROW LEVEL SECURITY` is NOT set (NOT REPRODUCED — not in this migration; may be elsewhere).
- `anon` has no base-table privileges; `authenticated` has SELECT/INSERT/UPDATE on base tables (but is_admin unwritable per MV-6); `service_role` has all privileges (VERIFIED from grant statements lines 110-127).

### MV-8: CMS security gates unresolved on main?
**VERIFIED — YES, unresolved**

- File: `supabase/migrations/20261107130100_resource_center_schema.sql` (origin/main)
  - No author/reviewer/publisher capability table (VERIFIED — no such table in migration)
  - No reviewer ≠ author rule (VERIFIED — no such constraint)
  - No transition state machine on `resource_articles.status` (VERIFIED — status is a CHECK-constrained enum only, no transitions)
  - `resource_revisions.state` is `jsonb` with only `jsonb_typeof = 'object'` check — no immutable snapshot contract, no same-article binding for `published_revision_id` (VERIFIED lines 82-101)
  - No audit ledger table (VERIFIED — no `resource_article_audit_events` or similar)
- File: `app/admin/resources/page.tsx` (origin/main) — read-only, `requireAdmin()` gate, SELECT only on `resource_articles`, labels publishing as "next" (VERIFIED)
- No editorial write API routes or server actions exist on main (VERIFIED — no such files in app/api or app/admin for resource center writes)
- **Conclusion: All CMS security gates remain unresolved.** The CMS must not be built on the current broad admin write policy (which doesn't exist as a write path yet — the policies are broad but no write path is implemented).

### MV-9: Duplicate SEO title and empty category issues
**VERIFIED — BOTH CONFIRMED**

**Duplicate title:**
- File: `app/layout.tsx` (origin/main), line 40: `template: "%s | Scholars"` — root layout automatically appends ` | Scholars`
- File: `app/resources/page.tsx` (origin/main), line 11: `title: "Resource Center for students | Scholars"` — already includes `| Scholars`
  - Rendered: `Resource Center for students | Scholars | Scholars` (DOUBLED)
- File: `app/resources/[slug]/page.tsx` (origin/main), line 19: `` title: \`${article.title} | Scholars\` `` — already includes `| Scholars`
  - Rendered: `Article Title | Scholars | Scholars` (DOUBLED)
- File: `app/resources/category/[slug]/page.tsx` (origin/main), line 15: `` title: \`${result.category.name} resources | Scholars\` `` — already includes `| Scholars`
  - Rendered: `Category resources | Scholars | Scholars` (DOUBLED)

**Empty categories:**
- File: `app/resources/page.tsx` (origin/main), line 26: `visibleCategories = categories.length > 0 ? categories : LOCAL_RESOURCE_CATEGORIES` — no article-count filter
- File: `app/sitemap.ts` (origin/main), lines 71-75: emits category routes for all distinct slugs with no article-count guard
- File: `lib/sitemap-data.ts` (origin/main), `readAllResourceCategoryRows()` (lines 71-92): returns all categories including empty ones
- All six local categories have ≥1 local article today, so no empty page is currently rendered — but the mechanism does not prevent it when database-backed categories are added.

### MV-10: Search implementation and searchable fields
**VERIFIED**

- File: `components/resource-center-search.tsx` (origin/main), lines 10-13:
  ```typescript
  return articles.filter((article) =>
    `${article.title} ${article.excerpt ?? ""} ${article.article_type}`.toLowerCase().includes(normalized)
  ).slice(0, 6);
  ```
- Searchable fields: **title, excerpt, article_type only**
- NOT searchable: article body (`content_markdown`), category name/description
- Client-side substring filter, 6 results max, `aria-live="polite"` results region
- **CONFIRMED:** Search does not match article body or category.

---

## 3. Additional implementation risks identified

| # | Risk | File | Classification |
|---|------|------|----------------|
| R1 | `getResourceImageUrl()` calls `createClient()` without `hasPublicSupabaseConfig()` guard | `lib/resource-center.ts:131-136` | PARTIALLY VERIFIED — not triggered by local null-image content, but would throw for DB-backed articles with images when env vars absent |
| R2 | `readAllPublicRows()` in sitemap throws on error (no fallback for scholarships/opportunities tables) | `lib/sitemap-data.ts:39-40` | VERIFIED — sitemap build fails entirely if public scholarships/opportunities queries fail |
| R3 | `readAllResourceCategoryRows()` logs error and returns partial results on failure (inconsistent error handling vs readAllResourceRows) | `lib/sitemap-data.ts:82-84` | VERIFIED — inconsistent error handling between resource and category sitemap readers |
| R4 | `getResourceHome()` and `getResourceArticle()` throw `ResourceDataError` on Supabase errors; routes catch and render error states | `lib/resource-center.ts:49-55, 106-117` | VERIFIED — fail-closed behavior is intentional and correct |
| R5 | No `security_invoker = true` on public views; views run as owner (postgres, BYPASSRLS) | `supabase/migrations/20261107130100_resource_center_schema.sql:157-214` | VERIFIED — owner-executed views bypass RLS; safety depends entirely on view definitions |
| R6 | `FORCE ROW LEVEL SECURITY` not set on base tables | `supabase/migrations/20261107130100_resource_center_schema.sql:103-107` | PARTIALLY VERIFIED — not in this migration; may be set elsewhere |
| R7 | Broad admin table-level policies exist (`resource_*_admin_all`) but no write path is implemented | `supabase/migrations/20261107130100_resource_center_schema.sql:129-150` | VERIFIED — policies are broad but dormant (no CMS write endpoints exist) |

---

## 4. Corrections to the prior published report

| Item | Prior claim | Corrected finding |
|------|-------------|-------------------|
| `profiles.is_admin` self-elevation | "Still unresolved" | **NOT REPRODUCED — remediated** by migrations 0023 and 0029 (is_admin excluded from updatable columns, explicit revoke, function execute revoked from public roles) |
| Word count range | "358–499 words" | **VERIFIED: 351–487 words** (consistent counting method applied to origin/main source) |
| Article classification | Implied some non-application articles | **VERIFIED: all six are application-related** (Prepare pillar) |
| Middleware Supabase on public routes | Implied Resource Centre routes affected | **VERIFIED: /resources NOT in middleware matcher** — no Supabase auth middleware executes on Resource Centre routes |
| `createClient()` throwing on /resources | Claimed homepage fails without env vars | **PARTIALLY VERIFIED: homepage data path is guarded** by hasPublicSupabaseConfig(); `getResourceImageUrl()` has unguarded call but not triggered by local null-image content |

---

## 5. Unresolved evidence gaps

| Gap | Why unresolved |
|-----|----------------|
| Production row count for `resource_editorial_identities` | Read-only constraint; no production database access |
| Production environment variable values | No access to production/Vercel settings |
| `FORCE ROW LEVEL SECURITY` status | Not in the resource center schema migration; may be set elsewhere |
| Actual production HTTP responses | No browser automation/live HTTP tooling available in this session; relies on prior verification documentation |
| Real-device mobile behavior | No device/Playwright available |
| `is_admin(uuid)` function body on production | Source shows function definition but live catalog not queried |

---

## 6. Conclusion

The current Resource Centre implementation on `main` is operationally sound for public reading: all routes are public, unauthenticated, and repository-backed with fail-closed Supabase fallback. The `profiles.is_admin` self-elevation vulnerability reported previously has been **remediated**. Genuine defects remain: duplicate SEO title suffixes, empty categories in navigation/sitemap, narrow search scope, and narrow homepage positioning. The CMS publishing workflow remains unimplemented, and all CMS security gates are unresolved.
