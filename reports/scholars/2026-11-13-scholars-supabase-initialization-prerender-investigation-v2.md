# Scholars — Supabase Initialization and Prerender Failure Investigation

**Repository:** ImperioKDB/Scholars  
**Working directory:** /workspaces/Scholars  
**Branch:** feature/resource-center-public-frontend  
**HEAD commit:** 79456a0933eb27c6c848865cb35717c8b36ec0b5 — "feat: accessible mobile Resource Centre navigation + baseline audit report"  
**Report date:** Fri Nov 13 2026  
**Source report referenced:** SCHOLARS_RESOURCE_CENTRE_PHASE2_RELEASE_READINESS_CORRECTION.md (local untracked file; reports/scholars/ path does not exist in this repo)  
**Nature:** Investigation only — no implementation performed. No application source files modified.

---

## 1. Repository and Git State

**VERIFIED**

- Remote origin: https://github.com/ImperioKDB/Scholars (fetch and push)
- Current branch: feature/resource-center-public-frontend (matches expected)
- HEAD: 79456a0933eb27c6c848865cb35717c8b36ec0b5 — matches expected reported HEAD (79456a0)
- `git status --short` shows 6 modified tracked files (all Phase 2 Resource Centre files) plus multiple untracked reports/artifacts. All preserved; none deleted or modified.
- No branches switched. No application source files modified during this investigation.

Modified tracked files:
- M app/layout.tsx
- M app/resources/[slug]/page.tsx
- M app/resources/page.tsx
- M components/resource-center-interactions.test.tsx
- M components/resource-center-interactions.tsx
- M components/resource-center-search.tsx

Note: `.env.local` exists and is gitignored/untracked. It contains only `VERCEL_OIDC_TOKEN`. `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` are absent (variable names enumerated; no values exposed). `.env.example` (tracked) declares both Supabase names plus `SUPABASE_SERVICE_ROLE_KEY`.

---

## 2. Executive Summary

**VERIFIED**

`npx next build` exits with code 1 across ten prerendering paths because Supabase client initialization reads `process.env.NEXT_PUBLIC_SUPABASE_URL` and `process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY` without first checking they exist. Both variables are absent from `.env.local`.

Two independent failure mechanisms exist:

1. **Mechanism A (shared page shell):** `NetworkStatus` (`components/NetworkStatus.tsx:68`) calls `useMemo(() => createClient(), [])` at render time. `NetworkStatus` is rendered in the root layout `app/layout.tsx:75`, so it runs during prerender of every route. `createClient()` resolves to `lib/supabase/client.ts` (browser client), which reads both env vars with `!` non-null assertions — unguarded. This alone explains all ten failures.

2. **Mechanism B (per-page direct calls):** Four auth pages (`/login`, `/signup`, `/reset-password`, `/reset-password/update`), `/onboarding`, `/` (home), `/o/[id]`, `/s/[id]`, and `/scholarship/[slug]` each call `createClient()` or `createPublicClient()` directly in their component/Server Component body during prerender.

The Resource Centre's `hasPublicSupabaseConfig()` guard (`lib/resource-center.ts:216-218`) protects only its own data-fetching functions (`getResourceHomeWithRepositoryContent`, `getResourceArticleWithRepositoryContent`, `getResourceCategoryWithRepositoryContent`). It does **not** guard the shared page shell (`NetworkStatus`), nor `getResourceImageUrl()` (`lib/resource-center.ts:132`), which calls `createClient()` unconditionally.

Routes `/_not-found`, `/legal/privacy`, `/legal/terms`, and `/resources` fail solely via mechanism A. Auth pages, onboarding, home, o/[id], s/[id], and scholarship/[slug] fail via both A and B.

Adding the two missing public env variables would let the build pass but would **not** fix the architectural fragility: any page/component calling `createClient()` during prerender still fails if credentials are missing or Supabase is unreachable.

---

## 3. Exact Source-Level Initialization Paths

**VERIFIED** (direct source inspection)

### 3.1 Server client factory — `lib/supabase/server.ts`

| Item | Detail |
|------|--------|
| File | `lib/supabase/server.ts:20` |
| Function | `createClient()` (exported) |
| Timing | Function execution time — called by callers; not module-scope |
| Env var usage | Line 36: `process.env.NEXT_PUBLIC_SUPABASE_URL!`; Line 37: `process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!` |
| Guarded? | NO — no environment-variable check before `createServerClient(...)` |
| Called during prerender? | YES, by auth pages, onboarding, applications, etc. |

### 3.2 Browser client factory — `lib/supabase/client.ts`

| Item | Detail |
|------|--------|
| File | `lib/supabase/client.ts:5` |
| Function | `createClient()` (exported) |
| Timing | Function execution time — called by callers; not module-scope |
| Env var usage | Line 11: `process.env.NEXT_PUBLIC_SUPABASE_URL!`; Line 12: `process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!` |
| Guarded? | NO |
| Called during prerender? | YES — by NetworkStatus (render in root layout), login, signup, reset-password, reset-password/update, onboarding |

### 3.3 Public client factory — `lib/supabase/public.ts`

| Item | Detail |
|------|--------|
| File | `lib/supabase/public.ts:9` |
| Function | `createPublicClient()` (exported) |
| Timing | Function execution time — called by callers; not module-scope |
| Env var usage | Line 11: `process.env.NEXT_PUBLIC_SUPABASE_URL!`; Line 12: `process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!` |
| Guarded? | NO |
| Called during prerender? | YES — by home page (`app/page.tsx:106`), `/o/[id]/page.tsx:12`, `/s/[id]/page.tsx:12`, `/scholarship/[slug]/page.tsx:41` |

### 3.4 Service client — `lib/supabase/service.ts`

`createServiceClient()` **is** guarded (`service.ts:11-15`) — throws a clear error if `NEXT_PUBLIC_SUPABASE_URL` or `SUPABASE_SERVICE_ROLE_KEY` missing. Used only in API routes/cron (server-only, `server-only` directive). Not implicated in prerender failures. This shows the guarded pattern already exists in the codebase.

### 3.5 Resource Centre guard — `lib/resource-center.ts`

| Item | Detail |
|------|--------|
| File | `lib/resource-center.ts:216-218` |
| Function | `hasPublicSupabaseConfig()` — `Boolean(process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY)` |
| Guards | `getResourceHomeWithRepositoryContent()` (line 164), `getResourceArticleWithRepositoryContent()` (line 187), `getResourceCategoryWithRepositoryContent()` (line 193) |
| Does NOT guard | `getResourceImageUrl()` (line 132) — calls `createClient()` unconditionally |
| Does NOT guard | Shared page shell (`NetworkStatus` in root layout) |

### 3.6 `getResourceImageUrl()` unguarded call — `lib/resource-center.ts:130-134`

Calls `createClient()` unconditionally. Invoked by `ResourceImage` component (`components/resource-center.tsx:39`) during prerender when `featured_image_path` present. Also called in `generateMetadata` of `/resources/[slug]/page.tsx:39`.

---

## 4. Affected Routes and Dependency Chains

**VERIFIED**

The build output from `npx next build` (exit code 1) listed exactly these ten failing prerendering paths:

| # | Route | Output path | Failure mechanism |
|---|-------|-------------|-------------------|
| 1 | `/(auth)/login/page` | `/login` | A + B |
| 2 | `/(auth)/signup/page` | `/signup` | A + B |
| 3 | `/_not-found/page` | `/_not-found` | A only |
| 4 | `/legal/privacy/page` | `/legal/privacy` | A only |
| 5 | `/legal/terms/page` | `/legal/terms` | A only |
| 6 | `/onboarding/page` | `/onboarding` | A + B |
| 7 | `/page/` | `/` (home) | A + B |
| 8 | `/reset-password/page` | `/reset-password` | A + B |
| 9 | `/reset-password/update/page` | `/reset-password/update` | A + B |
| 10 | `/resources/page` | `/resources` | A + (B via ResourceImage) |

**Dependency chain per route**

**Mechanism A (shared shell) — all ten routes:**
```
app/layout.tsx:75 renders <NetworkStatus />
  → components/NetworkStatus.tsx:68: useMemo(() => createClient(), [])
    → lib/supabase/client.ts:createClient()
      → reads NEXT_PUBLIC_SUPABASE_URL!, NEXT_PUBLIC_SUPABASE_ANON_KEY! (UNGUARDED, throws)
```

**Mechanism B (direct page calls):**
- `/login` — `app/(auth)/login/page.tsx:69`: `const supabase = createClient()` in `LoginForm` component body
- `/signup` — `app/(auth)/signup/page.tsx:35`: `const supabase = createClient()` in `SignupForm` component body
- `/reset-password` — `app/reset-password/page.tsx:38`: `const supabase = createClient()` in component body
- `/reset-password/update` — `app/reset-password/update/page.tsx:31`: `const supabase = createClient()` in component body
- `/onboarding` — `app/onboarding/page.tsx:121`: `const supabase = createClient()` in `OnboardingForm` component body
- `/` (home) — `app/page.tsx:106`: `const supabase = createPublicClient()` in `loadLiveScholarships()` async function (Server Component body)
- `/o/[id]` — `app/o/[id]/page.tsx:12`: `const supabase = createPublicClient()` in Server Component body
- `/resources` — `components/resource-center.tsx:39`: `getResourceImageUrl(path)` → `lib/resource-center.ts:132`: `createClient()` UNGUARDED (when featured_image_path present)

**Additional routes not in the report but sharing Mechanism A** (INFERRED from shared root layout): any route rendering `app/layout.tsx` — e.g., `/s/[id]`, `/scholarship/[slug]`, `/dashboard`, `/settings`, etc. Also `/s/[id]` and `/scholarship/[slug]` directly call `createPublicClient()` (Mechanism B).

### Error messages (from Supabase client libraries)
- `@supabase/ssr` (`lib/supabase/client.ts`, `lib/supabase/server.ts`): "Your project's URL and API key are required to create a Supabase client!"
- `@supabase/supabase-js` (`lib/supabase/public.ts`): "supabaseUrl is required."

---

## 5. Real Failure Mechanism

### 5.1 Why do the ten reported routes fail?
**VERIFIED.** All ten fail because Supabase client initialization reads `process.env.NEXT_PUBLIC_SUPABASE_URL` and `process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY` without first checking they exist. Both variables are absent from `.env.local` (only `VERCEL_OIDC_TOKEN` present). The initialization functions use TypeScript non-null assertions (`!`), so at runtime they pass `undefined` to the Supabase client constructor, which throws the errors listed above.

### 5.2 One shared dependency or multiple independent paths?
**VERIFIED — both.** Mechanism A (shared root-layout `NetworkStatus`) alone explains all ten failures. Mechanism B (direct per-page calls) independently affects auth pages, onboarding, home, o/[id], s/[id], scholarship/[slug].

### 5.3 Why does `hasPublicSupabaseConfig()` not prevent the page-shell failure?
**VERIFIED.** `hasPublicSupabaseConfig()` guards only the Resource Centre's own data-fetching functions. It does not guard:
1. The shared root-layout shell (`NetworkStatus.useMemo(createClient())`), which runs on every route regardless of Resource Centre logic.
2. `getResourceImageUrl()` (`lib/resource-center.ts:132`), which calls `createClient()` unconditionally.

For `/resources`, the data layer correctly falls back to local content (guard works), but the page shell still fails via mechanism A before the fallback can render.

### 5.4 Is the root layout importing a provider/component that initializes Supabase?
**VERIFIED.** `app/layout.tsx` imports and renders `<NetworkStatus />` (line 75). `NetworkStatus` (`components/NetworkStatus.tsx:68`) calls `useMemo(() => createClient(), [])` at render time. It is a `"use client"` component that still executes its render function during SSR/prerender.

Other root-layout components do NOT initialize Supabase at prerender:
- `AuthRescue` (`components/AuthRescue.tsx`): `"use client"` but only calls `createClient()` inside `useEffect` (line 92), not during initial render — guarded from prerender throw by the `rescuing` state check and `pathname !== "/"` early return.
- `CookieConsent`, `Monitoring`, `InstallAppPrompt`: no Supabase calls.

### 5.5 Does the home page have an independent initialization path?
**VERIFIED.** Yes. `app/page.tsx:106` calls `createPublicClient()` directly in the async Server Component body. Independent of mechanism A.

### 5.6 Are any other routes affected but not included in the previous report?
**INFERRED.** Any route rendering `app/layout.tsx` (thus `<NetworkStatus />`) would fail prerender when Supabase env vars are absent. This includes all routes in the app directory. Also `/s/[id]` and `/scholarship/[slug]` directly call `createPublicClient()` (Mechanism B) and would fail. Not verified by full build enumeration — build output only reported ten paths.

### 5.7 Would adding the two missing public env variables merely hide the problem?
**VERIFIED / INFERRED.** Adding `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` would allow `createClient()`/`createPublicClient()` to construct successfully, so the build would pass — IF the Supabase project is reachable and credentials valid. This is the standard, valid Supabase SSR pattern when configured.

However:
- It does not fix architectural fragility: any page/component calling `createClient()` during prerender still fails if credentials missing or Supabase unreachable.
- `NetworkStatus` initializes a Supabase client on every route, even for purely static public pages (legal, 404) with no auth/data needs — couples entire shell to Supabase availability at build time.
- `getResourceImageUrl()` remains unguarded despite the Resource Centre data-layer guard — inconsistent protection boundary.

So adding the variables resolves the build failure in this environment, but the underlying pattern remains a latent risk. **INFERRED** — adding credentials and rebuilding was not performed (no credentials available, out of scope per boundaries).

---

## 6. Evaluation of Correction Strategies

**INFERRED** — evaluated analytically; none implemented.

### Strategy A — Guard server-client creation; callers handle missing configuration

| Criterion | Assessment |
|-----------|------------|
| Failures addressed | All ten routes (mechanism A via NetworkStatus; mechanism B via page components) |
| Routes affected | All routes rendering root layout; auth pages; onboarding; home; o/[id]; s/[id]; scholarship/[slug] |
| Security implications | LOW — no credentials exposed; no auth weakened; RLS unchanged |
| Potential regressions | MEDIUM — callers must handle null client gracefully; components expecting a live client may degrade |
| Preserves authenticated functionality? | YES — when credentials present, behavior unchanged |
| Preserves Resource Centre fallback? | YES — guard is additive |
| Compatible with Next.js + Supabase SSR? | YES |
| Additional tests required | Unit tests for guarded factory returning null when env missing; component tests for null-client handling |

### Strategy B — Move Supabase initialization from module scope into functions that actually need it

| Criterion | Assessment |
|-----------|------------|
| Failures addressed | Mechanism B (direct page-component calls); partially mechanism A if NetworkStatus refactored |
| Routes affected | Auth pages, onboarding, home, o/[id], s/[id], scholarship/[slug]; NetworkStatus if also refactored |
| Security implications | LOW — no credential exposure |
| Potential regressions | MEDIUM — lazy initialization changes timing of auth state checks; may affect components relying on client at mount |
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
| Potential regressions | HIGH — loses static optimization; affects SEO, performance, ISR |
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

**Recommended minimal correction:** Strategy E as primary (central configuration boundary preventing `createClient()`/`createPublicClient()` from throwing during prerender when env vars absent), combined with Strategy A (callers handle null/missing client gracefully). Strategy D should be considered for NetworkStatus specifically (load only when Supabase config present, or lazy-load on authenticated routes). Strategy C is explicitly not recommended.

---

## 7. Recommended Minimal Correction

**INFERRED** — not implemented.

The smallest safe correction:

1. **Add a guarded client factory wrapper** in `lib/supabase/` (e.g., `createClientSafe()` / `createPublicClientSafe()`) that checks `hasPublicSupabaseConfig()`-equivalent before constructing the client and returns `null` (or throws a clear, catchable error) when credentials are absent.
2. **Refactor `NetworkStatus`** (`components/NetworkStatus.tsx:68`) to not initialize `createClient()` during prerender when config is absent — either lazy-initialize on first interaction or conditionally render.
3. **Guard `getResourceImageUrl()`** (`lib/resource-center.ts:132`) with `hasPublicSupabaseConfig()` to match the existing Resource Centre data-layer guard pattern.
4. **Update callers** (auth pages, onboarding, home, o/[id], s/[id], scholarship/[slug]) to handle a null client gracefully (degrade to unauthenticated/static behavior).

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
- **Auth page behavior:** Login/signup/reset-password pages that call `createClient()` directly must handle null client (show unauthenticated form, not crash).
- **Home page:** `createPublicClient()` failure should degrade to example scholarships (already has `showingExamples` fallback path).
- **s/[id] and scholarship/[slug]:** `createPublicClient()` failure should degrade to notFound/redirect appropriately.

---

## 9. Detailed Verification Plan

**NOT TESTED** — plan only, not executed.

Tests that can run **without credentials**:

| # | Test | Command | Expected |
|---|------|---------|----------|
| 1 | TypeScript type-check | `npx tsc --noEmit --pretty false` | Exit 0 |
| 2 | Existing unit tests | `npx vitest run` | All pass |
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
| `app/s/[id]/page.tsx` | Handle null public client gracefully |
| `app/scholarship/[slug]/page.tsx` | Handle null public client gracefully |

---

## 11. Explicit List of Uncertainties

**UNVERIFIED**

1. Whether routes beyond the ten reported (`/about`, `/dashboard`, `/settings`, `/scholarship/[slug]`, `/s/[id]`, etc.) also fail prerender — inferred from shared root layout, not verified by full build enumeration.
2. Whether adding Supabase credentials and rebuilding would result in exit code 0 — not performed (no credentials available, out of scope).
3. Whether `NetworkStatus` decoupling would break offline sync for authenticated users — not tested.
4. Whether any module-scope Supabase initialization exists that was not discovered via grep — grep covered `app/`, `lib/`, `components/`, but other directories were not exhaustively searched.
5. Whether the `.next` build chunks map precisely to the source modules identified — chunk-to-source mapping was inferred from stack traces and import analysis, not verified via source maps.

---

## 12. Classification Summary

| Item | Label | Basis |
|------|-------|-------|
| Repository identity confirmed | VERIFIED | `git remote -v` matches ImperioKDB/Scholars |
| Branch and HEAD confirmed | VERIFIED | `git branch --show-current`; HEAD = 79456a0933eb27c6c848865cb35717c8b36ec0b5 |
| Git status recorded | VERIFIED | `git status --short` — 6 modified tracked files, untracked preserved |
| `.env.local` contains only VERCEL_OIDC_TOKEN | VERIFIED | Variable-name enumeration (values not exposed) |
| `NEXT_PUBLIC_SUPABASE_URL` missing from `.env.local` | VERIFIED | Variable-name enumeration |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` missing from `.env.local` | VERIFIED | Variable-name enumeration |
| `npx next build` exits code 1 | VERIFIED | Direct command execution |
| 10 prerendering paths failed | VERIFIED | Build output |
| `NetworkStatus` calls `createClient()` unconditionally during prerender | VERIFIED | Source: `components/NetworkStatus.tsx:68` |
| Root layout renders `NetworkStatus` on every route | VERIFIED | Source: `app/layout.tsx:75` |
| `hasPublicSupabaseConfig()` guards only Resource Centre data layer | VERIFIED | Source: `lib/resource-center.ts:164,187,193` |
| `getResourceImageUrl()` unguarded | VERIFIED | Source: `lib/resource-center.ts:132` |
| Two independent failure mechanisms | VERIFIED | Build output + source trace |
| `/resources` data layer falls back correctly | VERIFIED | Source: `lib/resource-center.ts:162-176` |
| `/resources` page shell still fails | VERIFIED | Build output: `/resources/page` failed |
| Service client `createServiceClient()` is guarded | VERIFIED | Source: `lib/supabase/service.ts:11-15` |
| AuthRescue calls `createClient()` only in `useEffect` | VERIFIED | Source: `components/AuthRescue.tsx:92` |
| Other routes likely affected but not enumerated | INFERRED | Shared root layout; not verified by full build |
| `/s/[id]`, `/scholarship/[slug]` fail via Mechanism B | INFERRED | Source inspection; not in build output |
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