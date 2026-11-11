# OPENCODE_CAPABILITY_TEST.md — Engineering Investigation Report

**Repository:** ImperioKDB/Scholars  
**Investigation date:** Wed Nov 11 2026  
**Working directory:** /workspaces/Scholars  
**Mode:** Read-only investigation (no writes, no deploys, no DB mutations, no credential exposure)

---

## Executive Summary

This is a consolidated read-only capability test report for the ImperioKDB/Scholars repository (production domain: https://scholars.com.ng). The investigation verified the available tooling, service access, repository architecture, test suite, and inspection capabilities without modifying any source code, configuration, dependencies, database contents, Supabase/Vercel resources, or Git branches.

**Key verified results:**
- Git, Node.js (v24.22.2), npm, npx, GitHub CLI (`gh`), and Vercel CLI are installed and authenticated.
- TypeScript type-check (`npx tsc --noEmit`) passes with exit 0, no errors.
- Full Vitest suite: **19 test files, 100 tests, all passed, exit 0** (~6.7s).
- GitHub API access is verified (authenticated as `ImperioKDB`; repo `ImperioKDB/Scholars` accessible).
- Vercel access is verified (`vercel whoami` → `imperiokdb`; project `scholars` under org `imperiokdbs-projects`; production URL `https://scholars.com.ng`; Node 24.x; region `dub1`).

**Key limitations (verified, not assumed):**
- The Supabase CLI is **not installed**; no live Supabase connection was attempted or established. All RLS/schema findings are inferred from static migration files, not validated against the live database.
- `.env.local` contains only `VERCEL_OIDC_TOKEN`; Supabase URL/anon/service-role keys are not present locally and were not fetched from Vercel (to avoid secret exposure).
- ESLint (`next lint`) is interactive and did not run non-interactively.
- Production build (`next build`) was not run.
- No end-to-end (E2E) test framework is present.

**Security and safety posture:** The investigation was conducted strictly in read-only mode. No credentials, secrets, or private user data were read or exposed. No deployments, database mutations, or environment changes were performed. The report is not being pushed or published to any external repository.

---

## Environment and Configuration

### Tools Available and Verified

| Tool | Status | Version | How verified |
|------|--------|---------|--------------|
| `git` | ✅ Installed | — | `which git` |
| `node` / `npm` / `npx` | ✅ Installed | node v24.22.2 (via nvm) | `which`, `npx vitest --version` |
| `gh` (GitHub CLI) | ✅ Installed + authenticated | 2.103.3 (2026-10-26) | `gh --version`, `gh auth status` — logged in as `ImperioKDB` (GITHUB_TOKEN present) |
| `vercel` (Vercel CLI) | ✅ Installed + authenticated | 65.14.0 | `vercel --version`, `vercel whoami` → `imperiokdb` |
| `supabase` (Supabase CLI) | ❌ NOT installed | — | `supabase --version` → `command not found` |
| `typescript` (tsc) | ✅ Available via npx | 5.9.3 | `npx tsc --noEmit` → exit 0 |
| `vitest` | ✅ Available via npx | 2.1.9 | `npx vitest --version`, full suite ran |

**Note:** Although the `supabase` binary is absent, the repo contains `supabase/.temp/` artifacts from a prior CLI run (project ref, CLI version v3.1.0, Postgres 17.6.1.155), indicating the CLI was used previously in this environment.

### Services Successfully Accessed (Read-Only)

#### GitHub (via `gh` CLI) — VERIFIED
- `gh auth status`: authenticated to `github.com` as `ImperioKDB`, active account, HTTPS protocol.
- `gh repo view ImperioKDB/Scholars`: repository accessible, no description set.
- Remote: `https://github.com/ImperioKDB/Scholars` (fetch + push).
- Current local branch: `chore/opencode-agent-setup`.
- `git log --oneline -10`: most recent commit `b29e6d7 chore: add OpenCode agent setup`.
- `gh api repos/ImperioKDB/Scholars/commits`: recent commit history accessible (OTP migration, Airtel scholarship, etc.). Some commits GPG-signed/verified (e.g., by `Abolaji Bright`), others unsigned.
- Branch list: 40+ remote branches (`main`, many `feat/`, `fix/`, `dependabot/`, `seo/`, `motion/`, `refine/`).

#### Vercel (via `vercel` CLI) — VERIFIED
- `vercel whoami`: `imperiokdb`.
- `vercel project ls`: project `scholars` found under org `imperiokdbs-projects`, production URL `https://scholars.com.ng`, updated ~11h ago, Node 24.x.
- `vercel ls` (deployments for `imperiokdbs-projects/scholars`): 20+ deployments listed; mix of Production and Preview environments; latest production ~11h ago; one deployment in `Blocked` state.
- `.vercel/repo.json`: project ID `prj_n4Unq6wzjbjRT9TcRGKvFD9jIfBk`, org ID `team_xPAueGwV3MitbRK6JLWqWNcQ`, directory `.`.
- `.vercel/README.txt`: present (standard Vercel link documentation).
- `vercel.json`: regions `["dub1"]`, one cron (`/api/cron/deadline-check`, schedule `0 8 * * *`).
- `.gitignore`: `.env`, `.env.local`, `.vercel`, `supabase/.temp/` all ignored.

**Not attempted (read-only boundary preserved):** `vercel env ls` (would risk exposing secret names/values), `vercel pull`, `vercel deploy`, any project/settings mutation.

#### Supabase — PARTIAL (metadata only, no live connection)
- **No live Supabase connection was attempted or established.** No service-role or anon keys were read from `.env.local` (that file exists but contains only `VERCEL_OIDC_TOKEN`; app secrets are not stored locally).
- Local `supabase/.temp/` metadata (read-only files, not secrets):
  - `linked-project.json`: ref `cmdglabohpttgfofcmqc`, name `scholarship-platform`, org `xcygvuivzlascuarwqzl`.
  - `project-ref`: `cmdglabohpttgfofcmqc`.
  - `cli-latest`: `v3.1.0`.
  - `postgres-version`: `17.6.1.155`.
- These confirm a Supabase project exists and was previously linked via CLI, but the CLI itself is not installed so no `supabase` diagnostics (status, db diff, etc.) can be run.

### Stack (from `package.json`)
- **Framework:** Next.js 14.2.35 (App Router), React 18.3.1, React DOM 18.3.1.
- **Language:** TypeScript 5.5.4 (dev), strict mode (`tsconfig.json`: `"strict": true`, `"noEmit": true`).
- **Styling:** Tailwind CSS 3.4.9, PostCSS, Autoprefixer.
- **Database/Auth:** `@supabase/supabase-js` 2.45.0, `@supabase/ssr` 0.4.0.
- **Caching/rate limiting:** `@upstash/redis` 1.34.3, `@upstash/ratelimit` 2.0.3.
- **Background jobs:** `inngest` 4.20.0.
- **Push notifications:** `web-push` 3.6.7.
- **Validation:** `zod` 3.23.8.
- **Testing:** `vitest` 2.1.9.
- **Server-only marker:** `server-only` 0.0.1.

### Supabase client layer (`lib/supabase/`)
- `client.ts` — browser client (`createBrowserClient`), cookie-domain aware.
- `server.ts` — server client (`createServerClient`) using anon key, respects caller session (RLS applies). Notes that cookies cannot be HttpOnly due to Supabase SSR design; compensating controls are short-lived tokens + refresh rotation + RLS.
- `public.ts` — anon-key client with no session handling, for genuinely public routes; must query `*_public_preview_v1` views, not raw tables.
- `service.ts` — service-role client (`createServiceClient`), bypasses RLS entirely, for trusted system jobs (cron, `/api/xp/share`). Requires `SUPABASE_SERVICE_ROLE_KEY`.
- `currentUser.ts` — current user helpers.

### Middleware (`middleware.ts`, 364 lines)
- Production canonical-host redirect: `scholars.com.ng` / `scholars-eight.vercel.app` → `www.scholars.com.ng` (308).
- Referral/attribution cookie capture (`utm_*`, `ref`, `campaign_id`, `ambassador_code`).
- Protected route prefixes: `/dashboard`, `/onboarding`, `/discover`, `/opportunities`, `/saved`, `/applications`, `/admin`, `/scholarships`, `/settings`, `/achievements`, `/notifications`, `/community`, `/reviews`, plus short-link prefixes `/s/`, `/o/`, `/scholarship/`, `/opportunity/`.
- Auth pages: `/login`, `/signup`.
- Admin API (`/api/admin/*`): requires authenticated user + `profiles.is_admin === true` + optional MFA (AAL2) if `REQUIRE_ADMIN_MFA=true`.
- Transient auth error handling with 503 retry and `/connection-problem` rewrite.
- PWA session cookie scope migration (host-only → parent domain) in production.

### Route structure (`app/`)
- Public: `/` (landing), `/about`, `/legal`, `/resources`, `/scholarships-in-nigeria`, `/opportunities-for-students`.
- Auth: `app/(auth)/login`, `app/(auth)/signup`, `/reset-password`, `/auth/*`.
- Protected: `/dashboard`, `/onboarding`, `/discover`, `/opportunities`, `/saved`, `/applications`, `/scholarships`, `/settings`, `/achievements`, `/notifications`, `/community`, `/reviews`.
- Admin: `/admin/*` (sub-routes: active-users, analytics, broadcast, community-invitations, discovery, discussions, feedback, health, opportunities, resources, scholarships, testimonials, users).
- API: `/api/*` (achievements, admin, applications, auth, community, cron, csp-report, discussions, events, feedback, health, heartbeat, inngest, integrations, mascot, monitoring, notifications, onboarding, opportunities, presence, profile, push, reengagement, scholarships, xp).
- Short links: `/s/*`, `/o/*`; individual pages: `/scholarship/*`, `/opportunity/*`.

### Components (`components/`)
- 62 entries: auth screens (`AuthOtp`, `AuthConfirmation`, `AuthRescue`, `AuthShell`), scholarship cards, community, push notifications, WhatsApp consent, admin components, monitoring, SEO, etc.

### Security headers (`next.config.js`)
- Enforcing Content-Security-Policy (not report-only), `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy` (camera/mic/geolocation disabled), `Strict-Transport-Security`, `Reporting-Endpoints` + `/api/csp-report`.

### Environment template (`.env.example`)
- Public: `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `NEXT_PUBLIC_APP_URL`, `NEXT_PUBLIC_WEB_PUSH_VAPID_PUBLIC_KEY`.
- Server-only: `WEB_PUSH_VAPID_PRIVATE_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `UPSTASH_REDIS_REST_URL/TOKEN`, `BREVO_API_KEY`, `CRON_SECRET`, `INNGEST_EVENT_KEY/SIGNING_KEY`, `GEMINI_API_KEY`, feature flags (`REQUIRE_ADMIN_MFA`, `PROFILE_NUDGES_USE_INNGEST`, `DEADLINE_REMINDERS_USE_INNGEST`).

---

## Tests Performed

### Test suite (Vitest) — EXECUTED, ALL PASS
`npm test` → `vitest run`:
- **19 test files, 100 tests, all passed, exit 0** (duration ~6.7s).
- Test files:
  - `lib/matching/discipline.test.ts` (8)
  - `lib/sitemap-data.test.ts` (3)
  - `lib/whatsapp/communityInvitations.test.ts` (15)
  - `lib/discovery/safeFetch.test.ts` (5)
  - `lib/auth/return-destination.test.ts` (12)
  - `lib/matching/engine.test.ts` (3)
  - `lib/public-application.test.ts` (16)
  - `lib/admin/guard.test.ts` (4)
  - `lib/auth/pwa-session.test.ts` (4)
  - `lib/fetch.test.ts` (3)
  - `lib/onboarding-prompts.test.ts` (5)
  - `lib/push/broadcastContent.test.ts` (3)
  - `lib/auth/redirect-origin.test.ts` (5)
  - `lib/discovery/adapters.test.ts` (1)
  - `lib/public-pagination.test.ts` (4)
  - `lib/motion/spring.test.ts` (3)
  - `app/manifest.test.ts` (2)
  - `lib/email/batches.test.ts` (2)
  - `lib/auth/cookie-domain.test.ts` (2)
- One stderr warning in `sitemap-data.test.ts` ("network unavailable") is an expected simulated failure path within the test, not a suite failure.

**Note:** One sitemap test logs `[sitemap] failed to read public opportunities Error: network unavailable` to stderr — this is an intentional failure-mode test, not a real outage.

### TypeScript check — EXECUTED, PASSED
- `npx tsc --noEmit` → exit 0, no type errors.

### Lint — AVAILABLE, NOT EXECUTED
- `npm run lint` → `next lint`, but it is interactive (prompts "Strict / Base / Cancel") and did not run non-interactively. ESLint config status is unknown.

### Package scripts
- `dev`, `build`, `start`, `lint`, `test:profile-nudge` (runs `scripts/trigger-profile-nudge.mjs`), `test:discovery` (runs `vitest run lib/discovery/safeFetch.test.ts`), `test` (full vitest).

### Tests NOT present / gaps
- No end-to-end (E2E) test framework (no Playwright/Cypress) detected.
- No SQL test runner integration for Supabase migrations (the `.sql` test in `supabase/tests/` requires a live DB).
- No `vitest.config.*` file found at root (vitest uses defaults/package.json).
- `supabase/.temp/` is gitignored — local CLI state is not tracked.

### Tests Executed and Results (summary table)

| Command | Result | Details |
|---------|--------|---------|
| `npx tsc --noEmit` | ✅ PASS | exit 0, no type errors |
| `npm test` (`vitest run`) | ✅ PASS | 19 files, 100 tests, all passed, exit 0 |
| `npx vitest run lib/discovery/safeFetch.test.ts` | ✅ PASS | 5 tests (subset of full suite) |
| `npm run lint` (`next lint`) | ⚠ NOT RUN | Interactive prompt; no non-interactive execution |
| `next build` | ❌ NOT RUN | Not executed (would require env vars; read-only boundary) |
| Supabase SQL test (`supabase/tests/*.sql`) | ❌ NOT RUN | No live DB connection; executing would violate read-only |

---

## Results and Evidence

### Supabase Inspection Results

#### Migrations (read-only, 104+ files)
Located in `supabase/migrations/`. Numbered `0001_init.sql` through `20261111040808_add_computer_engineering_airtel_eligibility.sql`, plus timestamped 2026-11 migrations (`20261107130000_security_boundary_remediation.sql`, `20261107130100_resource_center_schema.sql`, `20261109130500_correct_airtel_afara_application_route.sql`, `20261109131500_reverify_kayode_and_nnpc_snepco_sources.sql`, `20261109132500_update_airtel_scholarship_eligibility.sql`, `20261111032810_global_opportunity_access_hardening.sql`, `20261111033130_revoke_legacy_preview_view_anon.sql`, `20261111040808_add_computer_engineering_airtel_eligibility.sql`).

**Key migrations inspected:**

- `0001_init.sql` — **Marked SUPERSEDED.** Header explicitly states it must not be run against the live project (`scholarship-platform`, ref `cmdglabohpttgfofcmqc`). Defines `profiles`, `scholarships`, `scholarship_rules`, `saved_scholarships`, `notifications`, RLS (owner-based for profiles/saved/notifications; authenticated-select for scholarships/rules), `handle_new_user()` trigger, `compute_profile_completeness()` trigger.
- `0026_harden_audited_rls.sql` — RLS for `waec_results`, `opportunities`, `saved_opportunities`; `opportunities_select_verified` (anon + authenticated, `verified = true`); `opportunities_admin_all` via `public.is_admin(auth.uid())`.
- `20261111032810_global_opportunity_access_hardening.sql` — Creates `SECURITY INVOKER` + `security_barrier` views `opportunities_public_preview_v1` and `scholarships_public_preview_v1` with fixed safe columns only; revokes base-table SELECT from `anon`/`PUBLIC`; grants narrow column-level SELECT to `anon` on source tables; converts anon policies to verified-only; removes anon discussion/prompt reads; revokes anon EXECUTE on `get_scholarship_discussions` and `get_scholarship_social_proof` (preserves authenticated); explicitly preserves public contributor-profile RPCs. Includes rollback warning.
- `20261111040808_add_computer_engineering_airtel_eligibility.sql` — Data migration adding "Computer Engineering" to an Airtel scholarship rule (defensive `DO $$` block with `RAISE EXCEPTION` if rule not found).

**Important discrepancy noted:** `lib/supabase/public.ts` references migration `20261110203400_global_opportunity_access_hardening.sql`, but no file with that exact timestamp exists in `supabase/migrations/` (the closest is `20261111032810_global_opportunity_access_hardening.sql`). This is an unverified assumption/stale reference worth noting.

#### RLS policies (inferred from migration files, not from live DB)
- `profiles`: owner-only select/update (`auth.uid() = id`).
- `scholarships`: authenticated select where `verified = true` OR admin OR saved OR applied; anon select where `verified = true`.
- `scholarship_rules`: authenticated select only.
- `saved_scholarships`: owner-only full CRUD.
- `notifications`: owner-only select.
- `opportunities`: anon + authenticated select verified-only; admin all via `is_admin()`.
- `waec_results`, `saved_opportunities`: owner-only.
- Admin writes to `scholarships`/`scholarship_rules` handled via service-role key in API routes, not RLS.

#### Supabase tests
- `supabase/tests/global_opportunity_access_hardening.sql` — A read-only PL/pgSQL validation script using `has_table_privilege`, `has_column_privilege`, `has_function_privilege`, and catalog checks. It verifies: anon cannot SELECT base tables (`opportunities`, `scholarships`, `scholarship_rules`, `scholarship_discussions`, `scholarship_prompts`); authenticated retains SELECT; anon can SELECT preview views; preview views are `SECURITY INVOKER` with no restricted columns; anon EXECUTE revoked on discussion RPCs but preserved for contributor-profile RPCs; legacy preview views revoked. **This is a diagnostic SQL script, not executed** (no live DB connection, and executing SQL against a live project would violate read-only restrictions).

#### Live Supabase project
- Not connected. No credentials available locally (`.env.local` only has `VERCEL_OIDC_TOKEN`; `.env` does not exist; secrets live in Vercel environment only). Cannot verify live schema, RLS enforcement, or row counts.

### Vercel Inspection Results

| Item | Result |
|------|--------|
| CLI auth | ✅ `vercel whoami` → `imperiokdb` |
| Project | ✅ `scholars` under org `imperiokdbs-projects` |
| Production URL | ✅ `https://scholars.com.ng` |
| Node version | ✅ 24.x |
| Region | ✅ `dub1` |
| Last production update | ✅ ~11h ago |
| Deployments observed | ✅ 20+ (Production + Preview + 1 Blocked) via `vercel ls` |
| Cron jobs | ✅ 1 configured: `/api/cron/deadline-check` at `0 8 * * *` (from `vercel.json`) |
| Local link files | `.vercel/repo.json` present (project ID, org ID); no `project.json`/`org.json` (not linked via `vercel link` locally, but CLI auth works via environment) |
| Deploy performed | ❌ No (read-only restriction) |
| Settings modified | ❌ No |

### Files Inspected (read-only)

**Root config:**
- `AGENTS.md`, `package.json`, `tsconfig.json`, `next.config.js`, `vercel.json`, `.env.example`, `.gitignore`, `middleware.ts`, `layout.tsx`, `manifest.ts`

**Supabase:**
- `supabase/migrations/` (listing + full reads of `0001_init.sql`, `0026_harden_audited_rls.sql`, `20261111032810_global_opportunity_access_hardening.sql`, `20261111040808_add_computer_engineering_airtel_eligibility.sql`)
- `supabase/tests/global_opportunity_access_hardening.sql`
- `supabase/.temp/linked-project.json`, `project-ref`, `cli-latest`, `postgres-version`

**Supabase client layer:**
- `lib/supabase/client.ts`, `server.ts`, `public.ts`, `service.ts`, `currentUser.ts`

**Auth layer:**
- `lib/auth/` (13 files including `cookie-domain.ts`, `pwa-session.ts`, `return-destination.ts`, `redirect-origin.ts`, `email.ts`, `password.ts`, `otp-error.ts`, `request-errors.ts`)

**Docs:**
- `docs/auth-email-otp-migration.md`, `docs/auth-otp-investigation-report-2026-11-10.md`, `docs/provider-analytics-audit.md`, `docs/verified-opportunities/`, `docs/verified-scholarships/`

**Other:**
- `app/api/` listing (25 API route groups), `app/admin/` listing, `components/` listing, `scripts/` listing, `.vercel/repo.json`, `.vercel/README.txt`

---

## Capabilities Confirmed

The following capabilities were **verified by executing commands** (not assumed):

1. **Git tooling** — `git` installed; remote `https://github.com/ImperioKDB/Scholars` accessible (fetch + push); current branch `chore/opencode-agent-setup`; latest commit `b29e6d7`; 40+ remote branches enumerated; commit history accessible via GitHub API (some GPG-signed/verified).
2. **Node.js runtime** — node v24.22.2 (via nvm), npm, npx all functional.
3. **GitHub CLI** — authenticated as `ImperioKDB`; `gh repo view` and `gh api` calls succeed.
4. **Vercel CLI** — authenticated as `imperiokdb`; project `scholars` visible under org `imperiokdbs-projects`; production URL `https://scholars.com.ng`; 20+ deployments observable.
5. **TypeScript type-check** — `npx tsc --noEmit` → exit 0, no errors (TypeScript 5.9.3 via npx; project tsconfig uses strict mode).
6. **Vitest test suite** — `npm test` → 19 test files / 100 tests, all passed, exit 0 (~6.7s).
7. **Supabase metadata files** — `supabase/.temp/` artifacts confirm a previously linked project (ref `cmdglabohpttgfofcmqc`, name `scholarship-platform`, CLI v3.1.0, Postgres 17.6.1.155).
8. **Read-only inspection of migrations, RLS policies, client layer, auth layer, middleware, routes, components, and docs** — all performed without modification.

### Tests Executed (verified)
- `npx tsc --noEmit` → exit 0.
- `npm test` (`vitest run`) → 19 files / 100 tests passed, exit 0.
- `npx vitest run lib/discovery/safeFetch.test.ts` → 5 tests passed.

---

## Limitations and Issues

### Confirmed limitations (verified by attempting the action)

1. **Supabase CLI not installed.** Cannot run `supabase status`, `supabase db diff`, `supabase migration list`, or any live-project diagnostic. Local `.temp/` files confirm prior CLI use but the binary is absent.
2. **No live Supabase connection possible.** `.env.local` contains only `VERCEL_OIDC_TOKEN`; `NEXT_PUBLIC_SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, and `NEXT_PUBLIC_SUPABASE_ANON_KEY` are not present locally (they live in Vercel environment variables). Per read-only restrictions, they were not fetched from Vercel (would risk exposing secrets).
3. **Cannot verify live RLS enforcement.** All RLS/policy findings are inferred from static migration files, not validated against the live database.
4. **Lint did not run** (interactive prompt). ESLint configuration/compliance is unverified.
5. **Production build (`next build`) was not run.** TypeScript type-check passed, but a full production build was not executed (and would require env vars).
6. **`supabase/.temp/` and `.env.local` are gitignored** — local environment/CLI state is not tracked in git; the working tree shows only one untracked file: `SCHOLARS_AUDIT_REPORT.md`.
7. **No deployment was performed or attempted.** Vercel settings untouched.
8. **No database modifications.** No SQL executed against any live DB.

### Unverified assumptions (labeled as such; NOT confirmed)

- The `public.ts` comment referencing migration `20261110203400_global_opportunity_access_hardening.sql` — no such file exists in `supabase/migrations/`; the closest match is `20261111032810_global_opportunity_access_hardening.sql`. This may be a stale comment or a migration applied out-of-band. **Unverified.**
- The live Supabase project (`cmdglabohpttgfofcmqc`) schema matches the tracked migrations — cannot be verified without a live connection. The `0001_init.sql` header explicitly warns the live schema differs from that file. **Unverified.**
- `SUPABASE_SERVICE_ROLE_KEY` and other server secrets are configured in Vercel for the `scholars` project — inferred from `.env.example` and `service.ts` requiring them, but not confirmed (would require `vercel env ls`, which risks secret exposure). **Unverified.**
- The production deployment at `scholars.com.ng` reflects the current `main` branch — Vercel shows latest production deploy ~11h ago, but the deployed commit SHA was not compared to local `main` (`b29e6d7`). **Unverified.**
- The `Blocked` deployment observed in `vercel ls` is not indicative of a system outage (could be a canceled/failed preview). **Unverified.**

### Test coverage gaps
- No end-to-end (E2E) test framework (no Playwright/Cypress) detected.
- No SQL test runner integration for Supabase migrations (requires a live DB).
- No `vitest.config.*` file found at root.

---

## Security and Safety Observations

### Investigation posture (verified)
- The entire capability test was conducted in **read-only mode**: no writes, no deploys, no DB mutations, no credential exposure.
- No credentials, secrets, or private user data were read or exposed. `.env.local` contents were not read beyond confirming it contains only `VERCEL_OIDC_TOKEN`.
- No deployments, database mutations, or environment changes were performed.
- The report is **not** being pushed or published to `ImperioKDB/Updates` (the PAT does not currently have the required access).

### Application security findings (from static inspection; RLS not verified live)

**Middleware (`middleware.ts`):**
- Production canonical-host redirect enforces `www.scholars.com.ng` (308).
- Protected route prefixes require authentication before access.
- Admin API routes (`/api/admin/*`) require authenticated user + `profiles.is_admin === true` + optional MFA (AAL2) if `REQUIRE_ADMIN_MFA=true`.
- Transient auth error handling with 503 retry and `/connection-problem` rewrite.
- PWA session cookie scope migration (host-only → parent domain) in production.

**Security headers (`next.config.js`):**
- Content-Security-Policy enforced (not report-only).
- `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy` (camera/mic/geolocation disabled), `Strict-Transport-Security`, `Reporting-Endpoints` + `/api/csp-report`.

**Supabase client layer:**
- `server.ts`: cookies cannot be HttpOnly due to Supabase SSR design; compensating controls are short-lived tokens + refresh rotation + RLS.
- `public.ts`: anon-key client with no session handling; must query `*_public_preview_v1` views, not raw tables.
- `service.ts`: service-role client bypasses RLS entirely, for trusted system jobs only; requires `SUPABASE_SERVICE_ROLE_KEY`.

**RLS policies (inferred from migrations, not verified against live DB):**
- `profiles`, `saved_scholarships`, `notifications`, `waec_results`, `saved_opportunities`: owner-only.
- `scholarships`: authenticated select where `verified = true` OR admin OR saved OR applied; anon select where `verified = true`.
- `scholarship_rules`: authenticated select only.
- `opportunities`: anon + authenticated select verified-only; admin all via `is_admin()`.
- Migration `20261111032810_global_opportunity_access_hardening.sql` hardens public access: revokes base-table SELECT from `anon`/`PUBLIC`, grants narrow column-level SELECT, uses `SECURITY INVOKER` + `security_barrier` preview views, revokes anon EXECUTE on discussion/social-proof RPCs while preserving contributor-profile RPCs.

**Git security:**
- Some commits GPG-signed/verified (e.g., by `Abolaji Bright`); others unsigned.

### Safety note
The `supabase/tests/global_opportunity_access_hardening.sql` validation script was **not executed** against any live database, both because no live connection exists and because executing SQL against a live project would violate the read-only restriction.

---

## Recommendations

1. **Install the Supabase CLI** (`npm install -g supabase` or via package manager) to enable `supabase status`, `supabase db diff`, and migration validation against the linked project (`cmdglabohpttgfofcmqc`). This requires project access tokens — obtain via approved channels only.
2. **Resolve the `public.ts` migration-reference discrepancy** (`20261110203400` vs `20261111032810`) — verify which timestamped migration was actually applied to the live project.
3. **Configure and run ESLint non-interactively** (add an ESLint config file or use a flag to skip the prompt) so `npm run lint` can run in CI.
4. **Run `next build` in a staging environment** with the correct env vars to confirm production build integrity beyond the type-check that passed.
5. **Add E2E test coverage** (e.g., Playwright) for critical auth flows (signup OTP, login, protected routes, admin MFA) — currently no E2E framework exists.
6. **Verify the live Supabase schema matches tracked migrations** by connecting to the project (with approved credentials) and comparing `pg_policies`/`information_schema` against migration files.
7. **Confirm the `Blocked` Vercel deployment** is benign (check deployment details via `vercel deployment ls` or the Vercel dashboard).
8. **Compare deployed commit SHA to local `main`** to confirm production reflects current code.

---

## Overall Assessment

The capability test confirms that the Scholars repository is a well-structured Next.js 14 (App Router) scholarship discovery platform with a mature testing setup. The verified results are strong:

- **TypeScript:** Clean type-check (`tsc --noEmit` → exit 0).
- **Unit tests:** Full Vitest suite passes (19 files, 100 tests, exit 0).
- **Tooling:** Git, Node.js, GitHub CLI, and Vercel CLI are all installed and authenticated, with successful read-only access to GitHub and Vercel services.
- **Architecture:** Clear separation of Supabase clients (browser/server/public/service), middleware-based route protection, security headers enforced in `next.config.js`, and RLS policies defined in migrations.

**Primary gaps are environmental, not code-related:** the Supabase CLI is not installed, no live Supabase connection or credential access is available locally, ESLint did not run (interactive), no production build was executed, and no E2E test framework exists. All RLS/security findings are inferred from static migration files and remain unverified against the live database.

**Security posture:** The investigation was conducted strictly read-only with no secret exposure. Application-layer security controls (middleware auth, CSP, RLS-inferred, service-role separation) appear well designed, but live verification of RLS enforcement and secret configuration requires approved access to the Vercel/Supabase environments.

**Readiness:** The codebase passes type-checking and unit testing. Before any production-facing change, the outstanding items are: live Supabase schema/RLS verification, non-interactive lint, a production build in staging, E2E test coverage, and confirmation that the deployed commit matches `main`. None of these are blockers for further read-only investigation, but they should be addressed before deployment-related work.

---

## Statement of Execution vs. Inference

**Actually executed (verified by running commands):**
- Read AGENTS.md, package.json, tsconfig.json, next.config.js, vercel.json, middleware.ts, layout.tsx, manifest.ts, .env.example, .gitignore.
- Read all inspected migration files, Supabase test SQL, client/auth/lib files, docs.
- `which`/`--version` for git, node, npm, npx, gh, vercel, supabase (supabase not found).
- `gh auth status`, `gh repo view`, `gh api repos/.../commits|branches`.
- `git remote -v`, `git branch -a`, `git status --short`, `git log --oneline -10`.
- `vercel whoami`, `vercel project ls`, `vercel ls`.
- Read `.vercel/repo.json`, `.vercel/README.txt`, `supabase/.temp/*` metadata files.
- `ls -la .env.local` (existence only; contents not read beyond confirming it has only `VERCEL_OIDC_TOKEN` name — values not exposed).
- `npx tsc --noEmit` → exit 0.
- `npm test` → 19 files / 100 tests passed, exit 0.
- `npm run lint` → interactive, did not run.

**Inferred (not directly verified against live systems):**
- Live Supabase schema, RLS enforcement, row counts (from migration files only).
- Vercel environment variable configuration (not read).
- Production deployment content matching local `main` (not compared).
- ESLint configuration/compliance (lint did not run).
- Production build integrity (`next build` not run).

---

**End of report.** No files were created, modified, or deleted in the workspace other than this report itself. No credentials, secrets, or private user data were exposed. No deployments, database mutations, or environment changes were performed. The report is not being pushed or published to `ImperioKDB/Updates`.
