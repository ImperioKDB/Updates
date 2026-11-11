# Scholars Repository — Engineering Audit Report

**Scope:** Read-only repository audit  
**Repository:** `/workspaces/Scholars`  
**Date:** Wed Nov 11 2026  
**Method:** Static source inspection only. No files modified, no dependencies installed, no database queries, no environment changes, no commits, no deploys.

---

## 1. Overall Application Architecture

**Product domain:** A scholarship discovery and application platform for students in Nigeria. Students create one profile, get eligibility-matched scholarship listings, track deadlines, save opportunities, and manage applications.

**Architecture style:** Full-stack Next.js 14 App Router application with Supabase as the backend (Auth + PostgreSQL + Storage + Realtime). Single-package monorepo layout with clear separation:

| Layer | Location | Responsibility |
|-------|----------|----------------|
| Frontend | `app/` (App Router), `components/` | React 18 server + client components, Tailwind UI |
| Auth/session | `middleware.ts`, `lib/auth/`, `lib/supabase/` | Supabase SSR session management, route guards |
| API / Route Handlers | `app/api/*` | REST-ish endpoints (Next.js Route Handlers) |
| Background jobs | `lib/inngest/`, `app/api/inngest/`, cron routes | Inngest durable functions (currently disabled) |
| Database | `supabase/migrations/` (135 SQL files) | Postgres schema via Supabase migrations, RLS |
| Edge config | `next.config.js`, `vercel.json` | CSP, security headers, Vercel cron, region |

**Routing model:** Next.js App Router with:
- Route group `(auth)` for login/signup layouts
- Standalone `app/auth/callback/` for Google OAuth & legacy email callbacks
- Dynamic segments: `[id]`, `[slug]`, `scholarship/[id]`, `opportunity/[id]`
- API routes under `app/api/` organized by domain (admin, applications, auth, community, cron, discussions, feedback, inngest, notifications, onboarding, opportunities, profile, push, reengagement, scholarships, xp, etc.)

**PWA orientation:** Web app manifest (`app/manifest.ts`), service worker (`public/sw.js`), offline fallback (`public/offline.html`), install prompts (`InstallAppPrompt`, `PushNotificationPrompt`), cookie-domain sharing across `scholars.com.ng` and `www.scholars.com.ng` for installed PWAs.

---

## 2. Frontend Framework and Programming Languages

| Technology | Version | Role |
|------------|---------|------|
| **Next.js** | `14.2.35` | App Router framework (React SSR/SSG/ISR) |
| **React** | `^18.3.1` | UI framework (React 18, strict mode) |
| **TypeScript** | `^5.5.4` | Language, strict mode (`strict: true`), path alias `@/*` |
| **Tailwind CSS** | `^3.4.9` | Utility-first styling, custom design tokens |
| **PostCSS** | `^8.4.41` | CSS processing with Tailwind + Autoprefixer |
| **Vitest** | `^2.1.9` | Unit test runner |
| **Zod** | `^3.23.8` | Runtime schema validation |

**Key frontend observations:**
- Mixed Server Components (default) and Client Components (`"use client"`).
- Self-hosted fonts via `next/font/local` (Fraunces display serif, Manrope sans) — noted in the frontend audit as a deliberate but potentially divergent typography choice.
- Custom design tokens in `tailwind.config.ts` (navy, parchment, ink, emerald, amber, rose, hairline) with documented WCAG AA contrast remediation.
- Security headers enforced via `next.config.js`: CSP (now enforcing, not report-only), `X-Content-Type-Options`, `X-Frame-Options: DENY`, `Referrer-Policy`, `Permissions-Policy`, `Strict-Transport-Security`.
- CSP still permits `script-src 'unsafe-inline'` (required by App Router inline flight data; nonce hardening deferred) and `connect-src` lacks `wss://` (Supabase Realtime not yet adopted by frontend).
- Error boundaries: `app/error.tsx` (route-level), `app/global-error.tsx` (root-level), `app/not-found.tsx` (404). Client errors reported to `/api/monitoring/errors` with dedupe and chunk-reload recovery.

**Frontend audit (`FRONTEND_AUDIT_REPORT.md`):** 33 findings catalogued — 22 confirmed defects (severity HIGH through LOW), 11 hypotheses requiring live/device validation. Highest-leverage: lost auth return paths, onboarding mobile layout/write safety, form naming/ARIA contracts, combobox keyboard state, hidden drawer in tab order, confirmation dialog semantics, reduced-motion gaps.

---

## 3. Backend Architecture and Supabase Integration

**Backend:** Supabase (managed Postgres + Auth + Storage + Realtime). Connection via `@supabase/supabase-js` ^2.45.0 and `@supabase/ssr` ^0.4.0.

**Four Supabase client variants** (`lib/supabase/`):

| Client | File | Key characteristics |
|--------|------|---------------------|
| Browser | `client.ts` | `createBrowserClient`, cookie domain from window hostname, timeout fetch |
| Server (anon) | `server.ts` | `createServerClient` using `cookies()`/`headers()`, SameSite=lax/Secure hardened, cookie writes swallowed during Server Component render |
| Public (anon, no session) | `public.ts` | `createClient` from supabase-js, `persistSession: false`, read-only public preview views (`scholarships_public_preview_v1`) |
| Service role | `service.ts` | `server-only`, `SUPABASE_SERVICE_ROLE_KEY`, RLS bypass, `autoRefreshToken: false`, used by cron and `/api/xp/share` under their own auth checks |

**Schema:** 135 migration files in `supabase/migrations/` (numbered `0001` through `0106` plus timestamped `202611*` files). Notable migration naming collisions exist (same prefix reused multiple times): `0021` (×4), `0023` (×2), `0034` (×2), `0035` (×2), `0045` (×2), `0052` (×2), `0057` (×2), `0061` (×2), `0062` (×3), `0063` (×2), `0078` (×2), `0087` (×2), `0102` (×2), `0103` (×2). Most recent: `20261111040808_add_computer_engineering_airtel_eligibility.sql`.

**RLS & security:** Migration `20261111032810_global_opportunity_access_hardening.sql` and `20261111033130_revoke_legacy_preview_view_anon.sql` indicate recent access-hardening work. Public reads go through `*_public_preview_v1` views. `0026_harden_audited_rls.sql`, `0028/0029` fix profile update privileges, `0023_lock_admin_flag.sql` locks the admin flag.

**Auth schema:** `profiles` table linked 1:1 to `auth.users` via trigger `handle_new_user()` (idempotent profile creation on signup). Columns include `is_admin`, `profile_completeness`, `referred_by`, UTM/attribution fields, WhatsApp opt-in, XP total (trigger-maintained cache), and more.

**Other backend services integrated:**
- **Upstash Redis** (`@upstash/ratelimit`, `@upstash/redis`) — rate limiting (CSP report endpoint uses `checkRateLimit` with limit 60).
- **Inngest** (`^4.20.0`) — durable background jobs; both registered functions (`sendProfileNudge`, `sendDeadlineReminder`) currently return `skipped: true, automaticEmailDisabled: true` — email automation is paused.
- **Brevo** — SMTP email delivery (`BREVO_API_KEY`).
- **Gemini API** — AI draft generation (`GEMINI_API_KEY`).
- **web-push** — VAPID push notifications.

---

## 4. Authentication Implementation

**Provider:** Supabase Auth (GoTrue), email/password + Google OAuth, with email OTP verification.

**Auth flow details:**
- **Signup:** `supabase.auth.signUp()` with `full_name` metadata; DB trigger creates `profiles` row. Email confirmation uses OTP (migrated from confirmation-link flow — see `docs/auth-email-otp-migration.md`).
- **Login:** `signInWithPassword()`. Existing unconfirmed accounts attempting password login are routed through the OTP screen.
- **OTP:** 8-digit email OTP (production Supabase setting is 8 digits; frontend matches). `AuthOtp.tsx` shared component supports 6→8 input boxes, paste, auto-focus movement, backspace navigation, 60s resend cooldown, duplicate-submit prevention. Distinct expired vs. invalid messages via `otpVerificationMessage()`.
- **Password reset:** `resetPasswordForEmail()` → OTP verification (`type: "recovery"`) → password update form. Legacy `/reset-password/update` retained for already-issued links.
- **Google OAuth:** Handled by `app/auth/callback/route.ts` (exchanges PKCE code via `exchangeCodeForSession`), applies referral + campaign attribution, clears cookies after consumption.
- **Middleware (`middleware.ts`):** 364 lines. Protects 16 route prefixes (`/dashboard`, `/onboarding`, `/discover`, `/opportunities`, `/saved`, `/applications`, `/admin`, `/scholarships`, `/settings`, `/achievements`, `/notifications`, `/community`, `/reviews`, plus share paths `/s/`, `/o/`, `/scholarship/`, `/opportunity/`). Refreshes sessions with retry on transient errors, canonical-host redirect (scholars.com.ng → www.scholars.com.ng in production), attribution cookie capture, referral cookie capture, admin MFA enforcement (`REQUIRE_ADMIN_MFA`), PWA session cookie domain migration (host-only → `.scholars.com.ng`).
- **Cookie domain:** `.scholars.com.ng` shared across apex and www in production only; host-only elsewhere.
- **Security note (from server.ts comments):** Session cookies cannot be HttpOnly because the browser client (`@supabase/ssr`) needs to read the access token for authenticated page-side calls — a Supabase SSR design constraint. Compensating controls: short-lived tokens, refresh rotation, SameSite=lax, Secure, RLS.
- **Client-side brute-force brake:** `localStorage`-based progressive lockout on login (UX-level only; real brakes are Supabase server-side rate limits).

**Known auth gaps (from frontend audit):** Auth return paths are lost — password login, Google OAuth, and signup all push to `/dashboard` regardless of original intent. Landing catalogue links into protected `/scholarships/*` and `/discover` lose user intent post-auth.

---

## 5. Existing Testing Infrastructure

**Test runner:** Vitest `^2.1.9`. No `vitest.config.ts` exists — defaults used. Test files match `*.test.ts`.

**Package scripts:**
- `test` → `vitest run` (full suite)
- `test:discovery` → `vitest run lib/discovery/safeFetch.test.ts`
- `test:profile-nudge` → `node scripts/trigger-profile-nudge.mjs` (manual Inngest trigger)
- `lint` → `next lint`
- `build` → `next build`

**Test inventory (19 files):**

| Test file | What it covers |
|-----------|---------------|
| `lib/auth/cookie-domain.test.ts` | Auth cookie domain sharing logic |
| `lib/auth/redirect-origin.test.ts` | OAuth redirect origin preservation |
| `lib/auth/return-destination.test.ts` | Return-path resolution, open-redirect rejection |
| `lib/auth/pwa-session.test.ts` | Supabase session cookie chunking/merging |
| `lib/admin/guard.test.ts` | Admin access guard |
| `lib/discovery/safeFetch.test.ts` | SSRF-safe fetch URL policy + structured extraction |
| `lib/discovery/adapters.test.ts` | Discovery source adapters |
| `lib/fetch.test.ts` | Timeout fetch wrapper |
| `lib/public-pagination.test.ts` | Public pagination helpers |
| `lib/public-application.test.ts` | Public application submission |
| `lib/sitemap-data.test.ts` | Sitemap data readers |
| `lib/email/batches.test.ts` | Email batching |
| `lib/whatsapp/communityInvitations.test.ts` | WhatsApp invitation consent |
| `lib/push/broadcastContent.test.ts` | Push broadcast content |
| `lib/motion/spring.test.ts` | Motion spring physics |
| `lib/onboarding-prompts.test.ts` | Onboarding prompt eligibility rules |
| `lib/matching/engine.test.ts` + `discipline.test.ts` | Matching engine |
| `app/manifest.test.ts` | PWA manifest origin behavior |

**CI (`.github/workflows/ci.yml`):** Runs on push/PR to `main` — `npm install`, `npx tsc --noEmit`, `npm test`, `npm run build`. Uses placeholder Supabase values (public client only) — no production credentials. Node 20, 15-minute timeout.

**Gaps:** No E2E/integration tests (no Cypress, Playwright, or similar). No test for middleware (364-line auth gate is untested directly). No vitest workspace/config customization.

---

## 6. Package Dependencies and Scripts

**package.json** (`name: scholarship-platform`, `version: 0.1.0`, private):

**Production dependencies (12):**
- `@supabase/ssr` ^0.4.0 — Supabase SSR cookie bridge
- `@supabase/supabase-js` ^2.45.0 — Supabase JS client
- `@upstash/ratelimit` ^2.0.3 — Rate limiting
- `@upstash/redis` ^1.34.3 — Redis client
- `inngest` ^4.20.0 — Durable functions
- `next` 14.2.35 — Framework
- `react` ^18.3.1 / `react-dom` ^18.3.1 — UI
- `server-only` ^0.0.1 — Server-only module enforcement
- `web-push` ^3.6.7 — VAPID push notifications
- `web-vitals` ^4.2.4 — Web vitals collection
- `zod` ^3.23.8 — Schema validation

**Dev dependencies (10):**
- `@types/node`, `@types/react`, `@types/react-dom`, `@types/web-push`
- `autoprefixer`, `postcss`, `tailwindcss`
- `typescript`
- `vitest`

**Notable dependency observations:**
- Next.js 14 (not 15) — a major upgrade path exists but is deliberately ungrouped in Dependabot for manual review.
- No form library (react-hook-form, etc.) — custom form handling.
- No ORM — raw supabase-js/PostgREST + SQL migrations.
- No dedicated HTTP client wrapper beyond `lib/fetch.ts` (custom timeout/retry).
- `server-only` used to enforce the service-role client boundary.

---

## 7. Vercel Deployment Configuration

**`vercel.json`:**
- Region: `dub1` (Dublin, EU) — single region
- Cron: `/api/cron/deadline-check` at `0 8 * * *` (daily 08:00 UTC)

**`next.config.js`:**
- No custom webpack, redirects, or rewrites beyond headers
- Security headers applied globally (`/`):
  - CSP (enforcing): `default-src 'self'`, `script-src 'self' 'unsafe-inline'`, `style-src 'self' 'unsafe-inline'`, `img-src 'self' data: blob: https://*.supabase.co`, `font-src 'self' data:`, `connect-src 'self' https://*.supabase.co`, `object-src 'none'`, `base-uri 'self'`, `form-action 'self'`, `frame-ancestors 'none'`, `upgrade-insecure-requests`, `report-uri /api/csp-report`, `report-to csp-endpoint`
  - `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy`, `Strict-Transport-Security`
  - `Reporting-Endpoints: csp-endpoint="/api/csp-report"`
- `app/api/csp-report/route.ts`: POST-only CSP violation collector, rate-limited (60), 4KB body cap, logs to Vercel Logs, returns 204.

**GitHub workflows (8):**
- `ci.yml` — typecheck + test + build on push/PR
- `digest-cron.yml`, `notification-worker.yml`, `reengagement-enrollment.yml`
- `scholarship-discovery.yml`, `scholarship-eligibility.yml`, `scholarship-quality.yml`, `scholarship-verification.yml` — discovery pipeline workflows

**Dependabot (`.github/dependabot.yml`):** Weekly npm updates, minor+patch grouped, major versions separate for manual review.

**Deployment model:** GitHub → Vercel automatic deployment on merge to `main`. `DEPLOY_TRIGGER.md` exists to force a fresh build when a deploy gets stuck.

**Environment variables** (`.env.example`): Supabase URL/anon key, app URL, VAPID keys, service role key, `REQUIRE_ADMIN_MFA`, Upstash Redis, Brevo API, CRON secret/webhook, Inngest keys, Gemini API key.

---

## 8. Potential Technical Debt and Architectural Risks

### High-severity / architectural risks

1. **CSP `unsafe-inline` for scripts** — Required by Next.js App Router inline flight data; nonce hardening is a documented deferred pass (audit Gap 1). `connect-src` lacks `wss://*.supabase.co` — must be added if Supabase Realtime is adopted (audit Gap 2).

2. **Session cookies cannot be HttpOnly** — Acknowledged architectural constraint of `@supabase/ssr` in the browser. Compensating controls exist (short-lived tokens, SameSite=lax, Secure, RLS), but XSS exfiltration of access tokens remains possible.

3. **Inngest email automation fully disabled** — Both `sendProfileNudge` and `sendDeadlineReminder` return `skipped: true, automaticEmailDisabled: true`. Feature flagged off (`PROFILE_NUDGES_USE_INNGEST=false`, `DEADLINE_REMINDERS_USE_INNGEST=false`) until the Inngest endpoint is synced and tested in staging. Dead code path risk if never enabled.

4. **135 migrations with numbering collisions** — Multiple migrations share the same numeric prefix (e.g., `0021` ×4, `0062` ×3). While Supabase sorts by filename, this is confusing and error-prone for manual schema reasoning and could cause issues if migrations are ever reordered or replayed outside Supabase's tooling.

5. **Middleware auth complexity** — `middleware.ts` is 364 lines with intricate cookie mutation logic (host-only → domain migration, pending cookie mutations, replay on every set). It is **not directly covered by unit tests**. This is the central auth gate; a regression here silently breaks all protected routes.

6. **Auth return paths lost** — Frontend audit Finding #1 (HIGH): password login, Google OAuth, and signup all redirect to `/dashboard`, discarding the original destination. Users following deep links lose intent.

7. **No E2E testing** — Only unit tests exist. Critical user journeys (signup → onboarding → dashboard → apply) are not end-to-end tested.

8. **Optional migration schema-drift fallback** — `currentUser.ts` has a `select("*")` fallback for deployments where migration 0010 (`avatar_url`) hasn't landed. This is cold-path only but indicates schema drift tolerance that could mask deployment issues.

9. **Dead code removal notes** — `server.ts` documents that a `createAdminClient()` service-role export was removed (was dead code, used `require()` in ESM). Service-role access now confined to `service.ts`.

10. **Production domain coupling** — Middleware hardcodes `scholars.com.ng` and `scholars-eight.vercel.app` hostnames for canonical redirect. `cookie-domain.ts` hardcodes the two Scholars hostnames. This is intentional but reduces portability.

### Medium / moderate concerns

- **Frontend audit findings:** 21 additional confirmed defects (MEDIUM/LOW) covering accessibility (FormField/Combobox ARIA contracts, combobox listbox state, drawer focus trap, ConfirmDialog naming/focus restore, step indicator semantics, binary choice radio semantics, notification disclosure), mobile layout (onboarding step 0 width, admin mobile header/touch targets, saved section dead end), motion (reduced-motion gaps for smooth scroll, spin, confetti, drawer transforms), and form UX (onboarding skip write safety, Enter-key flow, rejection filter handoff, saved-query error visibility).
- **Next.js 14 → 15 upgrade path** — Dependabot deliberately isolates major versions; a Next 15 migration will require App Router caching behavior review.
- **Vercel single region (dub1)** — No multi-region redundancy configured.
- **Rate limiting only on CSP report** — `checkRateLimit` used in `csp-report` route; unclear if other mutation endpoints (events, feedback, applications) are rate-limited at the route level.

---

## Summary

The Scholars platform is a **well-engineered, production-grade Next.js 14 + Supabase application** with thoughtful security hardening (CSP enforcement, RLS, input validation layer, cookie domain migration, service-role boundaries), a substantial migration history (135 files), and a reasonable unit test suite (19 files) backed by CI.

The most significant risks are: **untested complex auth middleware**, **lost auth return paths**, **disabled Inngest email automation**, **CSP `unsafe-inline`**, and **the absence of E2E tests**. The frontend audit report provides a detailed remediation roadmap for the 33 identified UI/accessibility findings.