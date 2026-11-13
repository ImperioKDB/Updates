# Scholars — Supabase Initialization and Prerender Failure Investigation

**Repository:** ImperioKDB/Scholars  
**Working directory:** /workspaces/Scholars  
**Branch:** feature/resource-center-public-frontend  
**HEAD commit:** 79456a0933eb27c6c848865cb35717c8b36ec0b5 — "feat: accessible mobile Resource Centre navigation + baseline audit report"  
**Report date:** Fri Nov 13 2026  
**Source report referenced:** reports/scholars/2026-11-13-scholars-resource-center-phase2-release-readiness-correction.md  
**Nature:** Investigation only — no implementation performed.

---

## 1. Repository and Git State

**VERIFIED**

- Remote origin: https://github.com/ImperioKDB/Scholars (fetch and push)
- Current branch: feature/resource-center-public-frontend
- HEAD: 79456a0933eb27c6c848865cb35717c8b36ec0b5 — matches expected reported HEAD (79456a0)
- `git status --short` shows 6 modified tracked files, all Phase 2 Resource Centre files:
  - M app/layout.tsx
  - M app/resources/[slug]/page.tsx
  - M app/resources/page.tsx
  - M components/resource-center-interactions.test.tsx
  - M components/resource-center-interactions.tsx
  - M components/resource-center-search.tsx
- Untracked files present (all preserved): 23 pre-existing reports/artifacts plus 2 new Phase 2 test files. None deleted or modified.
- No branches switched. No application source files modified during this investigation.

---

## 2. Executive Summary

**VERIFIED**

`npx next build` exits with code 1 across ten prerendering paths. Every failure traces to Supabase client initialization reading `process.env.NEXT_PUBLIC_SUPABASE_URL` and `process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY` without first checking whether those variables exist. Both variables are absent from `.env.local`, which contains only `VERCEL_OIDC_TOKEN`.

Two distinct initialization families are implicated:

1. **Server client** (`lib/supabase/server.ts` `createClient()`): reads the two env vars directly with `!` non-null assertions, no guard. Called by all auth/login/signup/reset-password pages and onboarding during component-body execution, plus by `NetworkStatus` (rendered in the root layout on every route) via `useMemo`.

2. **Public client** (`lib/supabase/public.ts` `createPublicClient()`): reads the same two env vars with `!` assertions, no guard. Called independently by the home page (`app/page.tsx`) and the legacy share redirect (`app/o/[id]/page.tsx`).

The Resource Centre's `hasPublicSupabaseConfig()` guard (`lib/resource-center.ts:216-218`) protects only its own data-fetching functions (`getResourceHomeWithRepositoryContent`, `getResourceArticleWithRepositoryContent`, `getResourceCategoryWithRepositoryContent`). It does **not** guard the shared page shell. Because `NetworkStatus` is mounted inside `app/layout.tsx` and initializes `createClient()` unconditionally during prerender, every route that renders the root layout — including `/resources`, `/_not-found`, `/legal/*`, `/`, `/onboarding`, and the auth pages — fails at build time before any Resource Centre fallback logic can run.

---

## 3. Exact Source-Level Initialization Paths

**VERIFIED**

### 3.1 Server client factory — `lib/supabase/server.ts`

| Item | Detail |
|------|--------|
| File | `lib/supabase/server.ts` |
| Function | `createClient()` (exported, line 20) |
| Timing | Function execution time — called by callers; not module-scope |
| Env var usage | Line 36: `process.env.NEXT_PUBLIC_SUPABASE_URL!`<br>Line 37: `process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!` |
| Guarded? | NO — no environment-variable check before `createServerClient(...)` |
| Called during prerender? | YES, by callers below |

### 3.2 Public client factory — `lib/supabase/public.ts`

| Item | Detail |
|------|--------|
| File | `lib/supabase/public.ts` |
| Function | `createPublicClient()` (exported, line 9) |
| Timing | Function execution time — called by callers; not module-scope |
| Env var usage | Line 11: `process.env.NEXT_PUBLIC_SUPABASE_URL!`<br>Line 12: `process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!` |
| Guarded? | NO — no environment-variable check before `createSupabaseClient(...)` |
| Called during prerender? | YES, by callers below |

### 3.3 Browser client factory — `lib/supabase/client.ts`

| Item | Detail |
|------|--------|
| File | `lib/supabase/client.ts` |
| Function | `createClient()` (exported, line 5) |
| Timing | Function execution time |
| Env var usage | Line 11: `process.env.NEXT_PUBLIC_SUPABASE_URL!`<br>Line 12: `process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!` |
| Guarded? | NO — no environment-variable check before `createBrowserClient(...)` |
| Called during prerender? | YES, by auth pages and onboarding below |

### 3.4 Resource Centre guard — `lib/resource-center.ts`

| Item | Detail |
|------|--------|
| File | `lib/resource-center.ts` |
| Function | `hasPublicSupabaseConfig()` (line 216-218) |
| Logic | `Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY)` |
| Guards | `getResourceHomeWithRepositoryContent()` (line 164), `getResourceArticleWithRepositoryContent()` (line 187), `getResourceCategoryWithRepositoryContent()` (line 193) |
| Does NOT guard | `getResourceImageUrl()` (line 132) — calls `createClient()` unconditionally |
| Does NOT guard | Shared page shell (`NetworkStatus` in root layout) |

### 3.5 `getResourceImageUrl()` unguarded call — `lib/resource-center.ts:130-134`

Calls `createClient()` unconditionally (no `hasPublicSupabaseConfig()` check). Invoked by `ResourceImage` component (`components/resource-center.tsx:39`) during prerender when a `featured_image_path` is present.

---

## 4. Affected Routes and Dependency Chains

**VERIFIED**

The build output from `npx next build` (exit code 1) listed exactly these ten failing prerendering paths:

1. `/(auth)/login/page` → `/login`
2. `/(auth)/signup/page` → `/signup`
3. `/_not-found/page` → `/_not-found`
4. `/legal/privacy/page` → `/legal/privacy`
5. `/legal/terms/page` → `/legal/terms`
6. `/onboarding/page` → `/onboarding`
7. `/page/` → `/`
8. `/reset-password/page` → `/reset-password`
9. `/reset-password/update/page` → `/reset-password/update`
10. `/resources/page` → `/resources`

Plus one additional failure visible in build output but not listed in the summary table:
11. `/` (home) — second error via `app/o/[id]/page.js` → `app/page.js` (`supabaseUrl is required.`)

### Dependency chain per route

**Auth pages (`/login`, `/signup`, `/reset-password`, `/reset-password/update`):**
```
page.tsx ("use client")
  → imports createClient from "@/lib/supabase/client"
  → calls createClient() in component body during prerender
    → lib/supabase/client.ts:createClient()
      → reads NEXT_PUBLIC_SUPABASE_URL!, NEXT_PUBLIC_SUPABASE_ANON_KEY! (UNGUARDED)
  → PLUS root layout
    → app/layout.tsx renders <NetworkStatus />
      → components/NetworkStatus.tsx:68: useMemo(() => createClient(), [])
        → lib/supabase/client.ts:createClient() (UNGUARDED)
```

**Onboarding (`/onboarding`):**
```
app/onboarding/page.tsx ("use client")
  → line 121: const supabase = createClient() (component body)
    → lib/supabase/client.ts:createClient() (UNGUARDED)
  → PLUS root layout → NetworkStatus chain (same as above)
```

**Home page (`/`):**
```
app/page.tsx (Server Component)
  → line 106: const supabase = createPublicClient()
    → lib/supabase/public.ts:createPublicClient() (UNGUARDED)
  → PLUS root layout → NetworkStatus chain (same as above)
```

**Legacy share redirect (`/o/[id]/page`):**
```
app/o/[id]/page.tsx (Server Component)
  → line 12: const supabase = createPublicClient()
    → lib/supabase/public.ts:createPublicClient() (UNGUARDED)
  → PLUS root layout → NetworkStatus chain (same as above)
```

**Resource Centre (`/resources`):**
```
app/resources/page.tsx (Server Component)
  → line 7: imports getResourceHomeWithRepositoryContent from "@/lib/resource-center"
  → line 20: await getResourceHomeWithRepositoryContent()
    → lib/resource-center.ts:164: hasPublicSupabaseConfig() returns FALSE (env vars missing)
    → getResourceHome() NOT called; local content used (FALLBACK WORKS)
  → BUT root layout → <ResourcePageFrame> → <ResourceMasthead>
    → components/resource-center.tsx:2: imports getResourceImageUrl from "@/lib/resource-center"
    → ResourceImage calls getResourceImageUrl(path) → lib/resource-center.ts:132: createClient() UNGUARDED
  → PLUS root layout → NetworkStatus chain (same as above)
```

**Legal pages (`/legal/privacy`, `/legal/terms`) and `/_not-found`:**
```
page.tsx (pure content, no direct Supabase call)
  → PLUS root layout → NetworkStatus chain (UNGUARDED createClient())
```

### Two independent failure mechanisms

| Mechanism | Trigger | Affected routes |
|-----------|---------|-----------------|
| A | Root-layout `NetworkStatus.useMemo(createClient())` | ALL ten routes (shared shell) |
| B | Direct page-component `createClient()`/`createPublicClient()` | Auth pages (4), onboarding, home, o/[id] |

Routes `/_not-found`, `/legal/privacy`, `/legal/terms`, and `/resources` fail solely via mechanism A (they have no direct Supabase call). Auth pages, onboarding, home, and o/[id] fail via both A and B (build reports one error per route, but both paths throw).

---

## 5. Real Failure Mechanism

**VERIFIED / INFERRED / UNVERIFIED** (classified per item)

### 5.1 Why do the ten reported routes fail?

**VERIFIED.** All ten routes fail because Supabase client initialization reads `process.env.NEXT_PUBLIC_SUPABASE_URL` and `process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY` without first checking they exist. Both variables are absent from `.env.local` (only `VERCEL_OIDC_TOKEN` is present). The initialization functions use TypeScript non-null assertions (`!`), so at runtime they pass `undefined` to the Supabase client constructor, which throws:

- `@supabase/ssr`: "Your project's URL and API key are required to create a Supabase client!" (from `lib/supabase/client.ts` and `lib/supabase/server.ts`)
- `@supabase/supabase-js`: "supabaseUrl is required." (from `lib/supabase/public.ts`)

Build output confirms both error messages across the ten paths.

### 5.2 Are they all failing from one shared dependency or multiple independent initialization paths?

**VERIFIED — both.** Two independent failure mechanisms exist:

- **Mechanism A (shared):** `NetworkStatus` component in `components/NetworkStatus.tsx:68` calls `useMemo(() => createClient(), [])`. Since `NetworkStatus` is rendered in `app/layout.tsx` (root layout), it runs during prerender of every route. This alone explains all ten failures.
- **Mechanism B (independent per-page):** Four auth pages, onboarding, home page, and `o/[id]` page each call `createClient()` or `createPublicClient()` directly in their component body during prerender.

Routes `/_not-found`, `/legal/privacy`, `/legal/terms`, and `/resources` fail solely via mechanism A. Auth pages, onboarding, home, and o/[id] fail via both A and B.

### 5.3 Why does `hasPublicSupabaseConfig()` not prevent the page-shell failure?

**VERIFIED.** `hasPublicSupabaseConfig()` (`lib/resource-center.ts:216-218`) guards only the Resource Centre's own data-fetching functions (`getResourceHomeWithRepositoryContent`, `getResourceArticleWithRepositoryContent`, `getResourceCategoryWithRepositoryContent`). It does not guard:

1. The shared root-layout shell (`NetworkStatus.useMemo(createClient())`), which runs on every route regardless of Resource Centre logic.
2. `getResourceImageUrl()` (`lib/resource-center.ts:132`), which calls `createClient()` unconditionally and is invoked by `ResourceImage` during prerender of `/resources` and article pages.

For `/resources`, the data layer correctly falls back to local content (guard works), but the page shell still fails via mechanism A before the fallback can render.

### 5.4 Is the root layout importing a provider or component that initializes Supabase?

**VERIFIED.** `app/layout.tsx` imports and renders `<NetworkStatus />` (line 75). `NetworkStatus` (`components/NetworkStatus.tsx:68`) calls `useMemo(() => createClient(), [])` at module/render time. `createClient()` resolves to `lib/supabase/client.ts` (browser client), which reads the two env vars unguarded. This runs during server-side prerender because `NetworkStatus` is a `"use client"` component that still executes its render function during SSR/prerender.

Other root-layout components (`AuthRescue`, `CookieConsent`, `Monitoring`, `InstallAppPrompt`) do **not** initialize Supabase at prerender time:
- `AuthRescue` (`components/AuthRescue.tsx`) is `"use client"` but only calls `createClient()` inside `useEffect`, not during initial render/prerender.
- `CookieConsent`, `Monitoring`, `InstallAppPrompt` — no Supabase calls.

### 5.5 Does the home page have an independent initialization path?

**VERIFIED.** Yes. `app/page.tsx:106` calls `createPublicClient()` directly in the async Server Component body. `createPublicClient()` (`lib/supabase/public.ts:9`) reads both env vars unguarded. This is mechanism B, independent of mechanism A. The build output confirms a second error for `/` via `app/o/[id]/page.js → app/page.js` (`supabaseUrl is required.`).

### 5.6 Are any other routes affected but not included in the previous report?

**INFERRED.** Any route that renders the root layout (`app/layout.tsx`) and thus `<NetworkStatus />` would fail prerender when Supabase env vars are absent. This includes ALL routes in the app directory, not just the ten reported. However, the build output only reported ten paths because Next.js stops collecting errors after a threshold or because other routes were not reached in this build run. Routes not in the reported ten but sharing the root layout (e.g., `/about`, `/dashboard`, `/settings`, `/scholarship/[slug]`) are likely equally affected but were not enumerated in this build's output. This is **INFERRED**, not directly verified by a full build enumeration.

### 5.7 Would adding the two missing public environment variables merely hide the problem, or is the current initialization pattern valid when configured?

**VERIFIED / INFERRED.** Adding `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` would allow `createClient()` / `createPublicClient()` to construct successfully, so the build would pass — **IF** the Supabase project is reachable and credentials are valid. This is the standard, valid Supabase SSR pattern when configured. However:

- It does not fix the architectural fragility: any page or component that calls `createClient()` during prerender will still fail if credentials are missing or the Supabase service is unreachable.
- The `NetworkStatus` component initializes a Supabase client on every route, even for purely static public pages (legal, 404) that have no auth or data needs. This couples the entire application shell to Supabase availability at build time.
- `getResourceImageUrl()` remains unguarded even though the Resource Centre data layer has a guard — an inconsistent protection boundary.

So adding the variables would resolve the build failure in this environment, but the underlying pattern (unguarded client creation during prerender, shared shell dependency) remains a latent risk. This is **INFERRED** — adding credentials and rebuilding was not performed (no credentials available, and strictly out of scope per boundaries).

---

## 6. Evaluation of Correction Strategies

**INFERRED** — evaluated analytically; none implemented.

### Strategy A — Guard server-client creation and ensure callers handle missing configuration

| Criterion | Assessment |
|-----------|------------|
| Failures addressed | All ten routes (mechanism A via NetworkStatus; mechanism B via page components) |
| Routes affected | All routes rendering root layout; auth pages; onboarding; home; o/[id] |
| Security implications | LOW — no credentials exposed; no auth weakened; RLS unchanged |
| Potential regressions | MEDIUM — callers must handle null client gracefully; components expecting a live client may degrade |
| Preserves authenticated functionality? | YES — when credentials present, behavior unchanged |
| Preserves Resource Centre fallback? | YES — guard is additive |
| Compatible with Next.js + Supabase SSR? | YES |
| Additional tests required | Unit tests for createClient wrapper returning null when env missing; component tests for null-client handling |

### Strategy B — Move Supabase initialization from module scope into functions that actually need it

| Criterion | Assessment |
|-----------|------------|
| Failures addressed | Mechanism B (direct page-component calls); partially mechanism A if NetworkStatus refactored |
| Routes affected | Auth pages, onboarding, home, o/[id]; NetworkStatus if also refactored |
| Security implications | LOW — no credential exposure |
| Potential regressions | MEDIUM — lazy initialization changes timing of auth state checks; may affect components that rely on client being available at mount |
| Preserves authenticated functionality? | YES — when credentials present, behavior unchanged |
| Preserves Resource Centre fallback? | YES |
| Compatible with Next.js + Supabase SSR? | YES |
| Additional tests required | Verify lazy init doesn't break auth flows; prerender tests |

### Strategy C — Make affected routes dynamically rendered where appropriate

| Criterion | Assessment |
|-----------|------------|
| Failures addressed | Build errors suppressed for dynamic routes (skipped at prerender) |
| Routes affected | Only routes changed to dynamic |
| Security implications | LOW |
| Potential regressions | HIGH — loses static optimization; affects SEO, performance, ISR; **not recommended** merely to suppress build errors |
| Preserves authenticated functionality? | YES |
| Preserves Resource Centre fallback? | YES |
| Compatible with Next.js + Supabase SSR? | YES, but defeats static generation benefits |
| Additional tests required | Build still passes; runtime behavior unchanged |

**RECOMMENDED AGAINST** per task instructions ("Do not recommend making every route dynamic merely to suppress build errors").

### Strategy D — Separate Supabase-dependent providers from the shared application shell

| Criterion | Assessment |
|-----------|------------|
| Failures addressed | Mechanism A (NetworkStatus in root layout) — most impactful |
| Routes affected | All routes rendering root layout |
| Security implications | LOW |
| Potential regressions | MEDIUM — NetworkStatus provides connection monitoring and offline sync; decoupling must preserve this for authenticated users |
| Preserves authenticated functionality? | YES — if NetworkStatus still loads for authenticated routes (lazy or conditional) |
| Preserves Resource Centre fallback? | YES |
| Compatible with Next.js + Supabase SSR? | YES — load NetworkStatus dynamically or only when Supabase config present |
| Additional tests required | Verify NetworkStatus loads correctly on authenticated routes; verify static pages build without it |

### Strategy E — Introduce a clear server-side configuration boundary that prevents accidental client creation during prerender

| Criterion | Assessment |
|-----------|------------|
| Failures addressed | All mechanisms — central guard prevents client creation without config |
| Routes affected | All routes |
| Security implications | LOW — prevents accidental Supabase calls without credentials |
| Potential regressions | LOW — single boundary; fail-closed behavior |
| Preserves authenticated functionality? | YES — when configured, full functionality preserved |
| Preserves Resource Centre fallback? | YES |
| Compatible with Next.js + Supabase SSR? | YES |
| Additional tests required | Boundary unit tests; prerender with missing config; prerender with valid config |

### Comparison summary

| Strategy | Addresses A | Addresses B | Regression risk | Recommended? |
|----------|-------------|-------------|-----------------|--------------|
| A (guard + caller handling) | YES | YES | MEDIUM | Partial |
| B (lazy init) | NO (unless NetworkStatus refactored) | YES | MEDIUM | Partial |
| C (dynamic routes) | YES (suppressed) | YES (suppressed) | HIGH | NO |
| D (separate shell) | YES | NO | MEDIUM | Partial |
| E (config boundary) | YES | YES | LOW | **YES (primary)** |

**Recommended minimal correction:** Strategy E as the primary correction (central configuration boundary that prevents `createClient()`/`createPublicClient()` from throwing during prerender when env vars are absent), combined with Strategy A (callers handle null/missing client gracefully). Strategy D should be considered for NetworkStatus specifically (load only when Supabase config present, or lazy-load on authenticated routes). Strategy C is explicitly not recommended.

---

## 7. Recommended Minimal Correction

**INFERRED** — not implemented.

The smallest safe correction:

1. **Add a guarded client factory wrapper** in `lib/supabase/` (e.g., `createClientSafe()` / `createPublicClientSafe()`) that checks `hasPublicSupabaseConfig()`-equivalent before constructing the client and returns `null` (or throws a clear, catchable error) when credentials are absent.
2. **Refactor `NetworkStatus`** (`components/NetworkStatus.tsx:68`) to not initialize `createClient()` during prerender when config is absent — either lazy-initialize on first interaction or conditionally render.
3. **Guard `getResourceImageUrl()`** (`lib/resource-center.ts:132`) with `hasPublicSupabaseConfig()` to match the existing Resource Centre data-layer guard pattern.
4. **Update callers** (auth pages, onboarding, home, o/[id]) to handle a null client gracefully (degrade to unauthenticated/static behavior).

This preserves:
- Existing authenticated functionality when credentials are configured
- Resource Centre local-content fallback
- RLS, CSP, and all security controls
- Next.js + Supabase SSR architecture

---

## 8. Security and Regression Risks

**INFERRED**

Security risks:
- **None introduced** by the recommended correction — no credentials exposed, no auth weakened, RLS unchanged, CSP unchanged.
- **Risk of over-guarding:** If the guard is too aggressive, authenticated features could degrade when config is present but transiently unavailable. Mitigation: guard only the *construction* throw, not runtime behavior when credentials exist.

Regression risks:
- **NetworkStatus decoupling:** Offline sync and connection monitoring for authenticated users must continue to work. If NetworkStatus is lazy-loaded or conditionally rendered, verify it still mounts on dashboard/settings/authenticated routes.
- **Auth page behavior:** Login/signup/reset-password pages that call `createClient()` directly must handle null client (show unauthenticated form, not crash). Verified pattern: these pages already have fallback UI states.
- **Home page:** `createPublicClient()` failure should degrade to example scholarships (already has `showingExamples` fallback path).

---

## 9. Detailed Verification Plan

**NOT TESTED** — plan only, not executed.

Tests that can run **without credentials**:

| # | Test | Command | Expected |
|---|------|---------|----------|
| 1 | TypeScript type-check | `npx tsc --noEmit --pretty false` | Exit 0 |
| 2 | Existing unit tests | `npx vitest run` | 162/162 pass |
| 3 | Guarded client factory unit test | New vitest test | Returns null when env vars absent; returns client when present |
| 4 | NetworkStatus null-config behavior | New vitest test | Does not throw during prerender simulation without config |
| 5 | `getResourceImageUrl` guard | New vitest test | Returns null without throwing when config absent |
| 6 | Auth page null-client degradation | New vitest test | Renders unauthenticated form without Supabase client |
| 7 | Build with missing config | `npx next build` | Exit 0 (prerender succeeds without Supabase) |

Tests requiring **staging Supabase credentials**:

| # | Test | Command | Expected |
|---|------|---------|----------|
| 8 | Prerender/build with valid staging config | `npx next build` (with staging env vars) | Exit 0; all routes prerender |
| 9 | Authenticated routes with valid config | `npx next build` + runtime check | Login/signup/dashboard prerender and function |
| 10 | Unauthenticated access behavior | Runtime test against staging | Public routes accessible; protected routes redirect |
| 11 | No service-role key in browser code | Code audit + build output check | `SUPABASE_SERVICE_ROLE_KEY` not in client bundle |
| 12 | No production database for Preview | Config audit | Preview env vars point to staging Supabase project, not production |

---

## 10. Files That Would Need Modification (if implementation approved)

**INFERRED** — no files modified in this investigation.

| File | Change |
|------|--------|
| `lib/supabase/server.ts` | Add guarded wrapper or null-return behavior for missing config |
| `lib/supabase/client.ts` | Add guarded wrapper or null-return behavior for missing config |
| `lib/supabase/public.ts` | Add guarded wrapper or null-return behavior for missing config |
| `lib/resource-center.ts` | Guard `getResourceImageUrl()` with `hasPublicSupabaseConfig()` |
| `components/NetworkStatus.tsx` | Lazy-initialize or conditionally create Supabase client; handle null |
| `app/(auth)/login/page.tsx` | Handle null client gracefully |
| `app/(auth)/signup/page.tsx` | Handle null client gracefully |
| `app/reset-password/page.tsx` | Handle null client gracefully |
| `app/reset-password/update/page.tsx` | Handle null client gracefully |
| `app/onboarding/page.tsx` | Handle null client gracefully |
| `app/page.tsx` | Handle null public client gracefully |
| `app/o/[id]/page.tsx` | Handle null public client gracefully |

---

## 11. Explicit List of Uncertainties

**UNVERIFIED**

1. Whether routes beyond the ten reported (`/about`, `/dashboard`, `/settings`, `/scholarship/[slug]`, etc.) also fail prerender — inferred from shared root layout, not verified by full build enumeration.
2. Whether adding Supabase credentials and rebuilding would result in exit code 0 — not performed (no credentials available, out of scope).
3. Whether `NetworkStatus` decoupling would break offline sync for authenticated users — not tested.
4. Whether any module-scope Supabase initialization exists that was not discovered via grep — grep covered `app/`, `lib/`, `components/`, but other directories (e.g., `scripts/`, `config/`) were not exhaustively searched.
5. Whether the `.next` build chunks (`7495.js`, `556.js`, `8188.js`) map precisely to the source modules identified — chunk-to-source mapping was inferred from stack traces and import analysis, not verified via source maps.

---


---

## 12. Classification Summary

| Item | Label | Basis |
|------|-------|-------|
| Repository identity confirmed | VERIFIED | `git remote -v` matches ImperioKDB/Scholars |
| Branch and HEAD confirmed | VERIFIED | `git branch --show-current` = feature/resource-center-public-frontend; HEAD = 79456a0933eb27c6c848865cb35717c8b36ec0b5 |
| Git status recorded | VERIFIED | `git status --short` — 6 modified tracked files, untracked preserved |
| `npx tsc --noEmit --pretty false` exit code 0 | VERIFIED | Direct command execution |
| `npx next build` exit code 1 | VERIFIED | Direct command execution; 10 prerendering paths failed |
| `.env.local` contains only `VERCEL_OIDC_TOKEN` | VERIFIED | Variable-name enumeration (values not exposed) |
| `NEXT_PUBLIC_SUPABASE_URL` missing from `.env.local` | VERIFIED | Variable-name enumeration |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` missing from `.env.local` | VERIFIED | Variable-name enumeration |
| `NetworkStatus` calls `createClient()` unconditionally during prerender | VERIFIED | Source: `components/NetworkStatus.tsx:68` |
| Root layout renders `NetworkStatus` on every route | VERIFIED | Source: `app/layout.tsx:75` |
| `hasPublicSupabaseConfig()` guards only Resource Centre data layer | VERIFIED | Source: `lib/resource-center.ts:164,187,193` |
| `getResourceImageUrl()` unguarded | VERIFIED | Source: `lib/resource-center.ts:132` |
| Two independent failure mechanisms (shared shell + per-page) | VERIFIED | Build output + source trace |
| `/resources` data layer falls back correctly | VERIFIED | Source: `lib/resource-center.ts:162-176`; guard returns false |
| `/resources` page shell still fails | VERIFIED | Build output: `/resources/page` failed |
| Other routes likely affected but not enumerated | INFERRED | Shared root layout; not verified by full build |
| Adding credentials would fix build | INFERRED | Not performed; no credentials available |
| Recommended minimal correction (Strategy E + A + D) | INFERRED | Analytical evaluation; not implemented |
| No security regression from correction | INFERRED | Analytical; no credentials exposed, RLS/CSP unchanged |
| New guarded-client factory unit test | NOT TESTED | Plan only |
| Build with valid staging credentials | NOT TESTED | Requires staging credentials |
| Authenticated routes with valid config | NOT TESTED | Requires staging credentials |
| No service-role key in browser code | NOT TESTED | Code audit pending |
| No production database for Preview | NOT TESTED | Config audit pending |

**Stopping here.** Awaiting explicit approval before implementing any correction. No application source files were modified during this investigation.

**Report location:** /workspaces/Scholars/SCHOLARS_SUPABASE_INITIALIZATION_PRERENDER_INVESTIGATION.md
