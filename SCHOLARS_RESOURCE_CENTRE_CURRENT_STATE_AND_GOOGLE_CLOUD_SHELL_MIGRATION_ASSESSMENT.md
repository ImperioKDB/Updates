# SCHOLARS RESOURCE CENTRE — CURRENT STATE AUDIT & GOOGLE CLOUD SHELL MIGRATION ASSESSMENT

**Assessment date:** Tue Nov 17 2026  
**Mode:** Read-only audit and reporting. No implementation, no fixes, no installs, no destructive Git commands performed.  
**Classification legend:** COMPLETE | PARTIAL | BROKEN | NOT STARTED | UNVERIFIED

---

## 1. Executive summary

The Scholars Resource Centre backend (`ImperioKDB/Scholars-Resource-Centre`) exists as an independent repository and has been scaffolded with schema migrations, RLS, editorial capability functions, public projection views, a TypeScript client library, tests, and CI. The scaffolding is real code, not placeholder documentation. However, **the Task 2 backend repair (a 14-point security/authorization repair of this backend) has NOT been implemented in the source** — the same migration files that exist contain verified defects, and no execution evidence shows the repairs were applied.

Three defects are directly verifiable in the inspected source:

1. **Identity/UUID mismatch (BROKEN):** Editorial lifecycle functions in `0003_audit_ledger.sql` resolve an editorial *identity* UUID from `auth.uid()`, then insert that identity UUID into `resource_editorial_audit_events.actor_id`, which is declared as `references auth.users(id)`. Identity UUIDs and Auth user UUIDs are not consistent, so audit FK references and actor derivation are semantically wrong.
2. **No identity provisioning (NOT STARTED):** No trigger/function links a new Supabase Auth user to a `resource_editorial_identities` row. Editorial identities cannot self-register from Auth; `user_id` remains unset unless manually backfilled.
3. **Security tests are DDL-only, not executed (UNVERIFIED for runtime):** `supabase/tests/rls_policies.sql` contains executable `assert_*` functions and assertions, but CI never runs `supabase start`/`db reset`/tests (guarded behind `SUPABASE_ACCESS_TOKEN`), and there is no local/remote database to execute them against in this environment. Test executability cannot be verified without Docker + Supabase CLI + a live instance.

The frontend (`ImperioKDB/Scholars`) Resource Centre public pages exist and are functional using **local repository content** as the source of truth, with an optional read path against `resource_public_*` views. It does **not** currently depend on the independent Resource Centre backend; it depends on the original Scholars Supabase project config (env vars) only insofar as `hasPublicSupabaseConfig()` gates the optional DB read. Public reading works independently of student authentication.

Google Cloud Shell is **viable as a development host** for Git/Node/TypeScript/vitest work and for interacting with GitHub Actions and Supabase dashboard remotely, but **cannot run local Supabase/Docker-based database tests directly** (Docker availability in Cloud Shell is not guaranteed and was not verified here; psql and the Supabase CLI are not installed). TypeScript typecheck and vitest unit tests (DB-independent) can run directly.

The exact next implementation task is **Backend security repair of `supabase/migrations/0003_audit_ledger.sql`** (actor derivation from authenticated identity, FK consistency, capability enforcement, author self-approval, and direct-write blocking) followed by adding the missing editorial identity provisioning trigger.

---

## 2. Repository identities and exact commit SHAs

| Repository | Default branch | Commit SHA (HEAD) | Remote URL | Working tree clean? | Open PRs |
|---|---|---|---|---|---|
| `ImperioKDB/Scholars-Resource-Centre` (backend) | main | `3eef3c25fb332f9351c4f7e97397b74e34f2ab51` | https://github.com/ImperioKDB/Scholars-Resource-Centre.git | Clean | 0 |
| `ImperioKDB/Scholars` (frontend) | main | `b4d1ff91ad53e44741a15d17384bf480d2570524` | https://github.com/ImperioKDB/Scholars.git | Clean | ~12 (incl. dependabot) |
| `ImperioKDB/Updates` (reports target) | main | `791723ca8c1a89a9f6ed0a065119c22e7812643b` | https://github.com/ImperioKDB/Updates.git | Clean | ~17 |

Notes:
- Backend HEAD commit message: `fix: correct RLS privilege migration, fix SQL privilege function signatures, fix RLS test files, add unit tests for editorial capabilities` (3eef3c2, 2026-11-15).
- Frontend HEAD commit message: `feat(scholars): implement official logo as website favicon` (b4d1ff9).
- No uncommitted changes in any of the three cloned working trees. No local-only branches or uncommitted work detected in these clones.

---

## 3. Verified current project status (Part 1 & 4)

### Backend — `ImperioKDB/Scholars-Resource-Centre`

Structure:
```
supabase/
  config.toml
  migrations/
    0001_init.sql              # 5 base tables + 4 public views + RLS + grants
    0002_editorial_capabilities.sql  # capability table + helper function + RLS
    0003_audit_ledger.sql      # audit ledger + lifecycle functions + RLS
  tests/
    seed.sql                   # synthetic author/reviewer/publisher identities
    rls_policies.sql           # RLS/security test assertions
lib/
  editorial/auth.ts, capabilities.ts, audit.ts
  content/articles.ts, categories.ts, revisions.ts
  storage/images.ts
  editorial/*.test.ts, content/*.test.ts
.github/workflows/ci.yml
.env.example, package.json, tsconfig.json, README.md
reports/scholars/docs/frontend-backend-migration-map.md
```

Component status table (evidence = file paths + commit references):

| Component | Status | Evidence | Remaining work |
|---|---|---|---|
| Repository scaffold (package.json, tsconfig, README, .env.example, .gitignore) | COMPLETE | `package.json`, `tsconfig.json`, `README.md`, `.env.example`; commit 9254a8e | None |
| Supabase config (config.toml) | COMPLETE | `supabase/config.toml` (external_url placeholders empty) | Wire real project URL at provisioning |
| Base schema migration 0001_init.sql (identities, categories, articles, joins, revisions, capabilities, audit ledger, RLS, grants, public views) | COMPLETE (DDL present) | `supabase/migrations/0001_init.sql`; commit 9254a8e | None for DDL; verify against live project at provisioning |
| Editorial capabilities migration 0002 (helper `resource_identity_is_owner`, RLS policies, grants) | COMPLETE (DDL present) | `supabase/migrations/0002_editorial_capabilities.sql`; commits 9254a8e + 3eef3c2 | None for DDL |
| Audit ledger migration 0003 (lifecycle functions, RLS, append-only) | BROKEN | `supabase/migrations/0003_audit_ledger.sql`; commits 9254a8e + 3eef3c2 | **Repair actor/identity UUID mismatch; derive actor from authenticated identity; enforce capability checks; prevent author self-approval; block direct writes; add identity provisioning trigger** |
| Seed data `supabase/tests/seed.sql` | COMPLETE (fixtures) | `supabase/tests/seed.sql`; synthetic author/reviewer/publisher identities | None |
| RLS/security tests `supabase/tests/rls_policies.sql` | PARTIAL (assertions exist, not executed in CI) | `supabase/tests/rls_policies.sql`; contains executable `assert_no_rows`/`assert_has_rows` assertions | Execute against a live local Supabase instance; CI does not run them (guarded by `SUPABASE_ACCESS_TOKEN`) |
| Editorial auth library `lib/editorial/auth.ts` | COMPLETE | `lib/editorial/auth.ts`; `EditorialAuth.getCurrentIdentity()` links `auth.users` → `resource_editorial_identities` via `user_id` | None |
| Editorial capabilities library `lib/editorial/capabilities.ts` | COMPLETE | `lib/editorial/capabilities.ts`; role-based checks incl. reviewer≠author | None |
| Editorial audit library `lib/editorial/audit.ts` | COMPLETE | `lib/editorial/audit.ts`; service-role insert, append-only | None |
| Public content queries `lib/content/articles.ts`, `categories.ts` | COMPLETE | `lib/content/articles.ts`, `lib/content/categories.ts`; read `resource_public_*` views via anon key | None |
| Revision store `lib/content/revisions.ts` | COMPLETE | `lib/content/revisions.ts`; service-role read/insert | None |
| Image storage library `lib/storage/images.ts` | COMPLETE | `lib/storage/images.ts`; MIME/size/path validation, bucket `resource-center-images` | Bucket not yet created in a Supabase project |
| Vitest unit tests (editorial capabilities, auth, audit, content) | PARTIAL | `lib/editorial/*.test.ts`, `lib/content/*.test.ts`; capabilities tests are DB-independent; auth/audit/content tests require a live Supabase instance | Run capabilities tests directly; DB-dependent tests need local Supabase |
| CI workflow `.github/workflows/ci.yml` | PARTIAL | `npx tsc --noEmit`, `npm test`, `npm ci`; Supabase CLI steps **commented out** and gated behind `SUPABASE_ACCESS_TOKEN` | Enable DB migration tests if a Supabase instance/token is provisioned |
| Migration ordering | UNVERIFIED | 0001 → 0002 → 0003; helper functions created before policies that reference them within 0002/0003 | Verify ordering against a live instance; no execution evidence |
| Environment config | COMPLETE (template) | `.env.example`; `SUPABASE_SERVICE_ROLE_KEY` server-only, `REQUIRE_EDITOR_MFA` | Real values never committed; provision at setup |
| Identity provisioning (Auth user → editorial identity trigger) | NOT STARTED | No trigger/function found in any migration; `grep` for trigger/signup/identity provisioning returned none | Add trigger to create `resource_editorial_identities` row on Auth signup |

### Frontend — `ImperioKDB/Scholars`

Resource Centre pages/components that exist:
- `app/resources/page.tsx` — public homepage
- `app/resources/[slug]/page.tsx` — article detail
- `app/resources/category/[slug]/page.tsx` — category listing
- `components/resource-center.tsx` (ResourcePageFrame, ResourceMasthead, ResourceCard, ResourceImage, ResourceAdSlot)
- `components/resource-center-search.tsx`, `resource-center-interactions.tsx`, `ResourceArticleBody.tsx`
- `lib/resource-center.ts`, `lib/resource-content.ts` (local launch content: 6 articles, 6 categories)
- `lib/supabase/server.ts`, `public.ts`, `config.ts` (anon-key clients)

Status:
- Public Resource Centre reading is **functional** using local repository content as source of truth; optional Supabase `resource_public_*` view read is gated behind `hasPublicSupabaseConfig()`.
- No editorial write routes exist for Resource Centre (`app/api/admin/resources/*` does not exist; admin resources page is read-only).
- Frontend depends on `NEXT_PUBLIC_SUPABASE_URL`/`NEXT_PUBLIC_SUPABASE_ANON_KEY` (pointing at the **original Scholars Supabase project**) only for the optional DB read path; local content works without any Supabase config.
- Public reading works independently of student authentication (anon key, no session required).
- When the independent backend becomes operational, `lib/resource-center.ts` must be repointed to the new backend's URL/anon key; `getResourceImageUrl()` reads from bucket `site` currently and would need to target the new backend bucket `resource-center-images`. No frontend changes are required now (per migration map, this is a future task).

---

## 4. Task 2 completion assessment (Part 2)

**Verdict: NOT STARTED (not implemented in source).**

The 14-point Task 2 investigation maps to defects that remain in the inspected source:

| # | Task 2 check | Status in source | Evidence |
|---|---|---|---|
| 1 | Editorial identities reference Supabase Auth users | PARTIAL (schema only) | `resource_editorial_identities.user_id references auth.users(id)` exists, but no provisioning trigger populates it |
| 2 | Identity UUIDs and Auth user UUIDs handled consistently | **BROKEN** | Lifecycle functions insert editorial `identity_id` into `actor_id` (FK → `auth.users(id)`); mismatch |
| 3 | Migration execution ordering correct | UNVERIFIED | 0001→0002→0003 present; helpers before policies within files; no execution evidence |
| 4 | DB functions exist before dependent policies | COMPLETE (within files) | `resource_identity_is_owner` created before policies in 0002; `resource_article_is_editor` before use in 0003 |
| 5 | Lifecycle functions derive actors from authenticated identities | PARTIAL (defective) | Functions derive `actor_id = auth.uid()`, then resolve identity — but insert identity UUID into actor_id FK column |
| 6 | Actor impersonation prevented | COMPLETE (design) | Functions use `auth.uid()`, never caller-supplied actor IDs; `security definer` + `set search_path = public` |
| 7 | Capability checks enforced | COMPLETE (design) | Each function checks `resource_editorial_capabilities` for required role |
| 8 | Author self-approval prevented | COMPLETE (design) | `return_resource_article` and `approve_resource_article` reject `article_author_identity_id = actor_identity_id` |
| 9 | Unauthorized direct writes blocked | COMPLETE (design) | Base tables revoked from `anon, authenticated`; RLS enabled; only service_role has table grants |
| 10 | Revision integrity and audit immutability enforced | PARTIAL | No UPDATE/DELETE policies on revisions/audit events in migrations; tests assert this but are not executed |
| 11 | Public content access separated from editorial access | COMPLETE | Public projection views (`resource_public_*`) with explicit column projection; base tables not readable by public roles |
| 12 | SQL security tests contain executable assertions | COMPLETE (assertions present) | `assert_no_rows`/`assert_has_rows` functions + assertions in `rls_policies.sql` |
| 13 | Tests actually execute successfully | **UNVERIFIED / NOT EXECUTED** | CI Supabase steps commented out, gated by `SUPABASE_ACCESS_TOKEN`; no local/remote DB available here |
| 14 | CI installs deps and runs required checks correctly | PARTIAL | `npm ci`, `tsc --noEmit`, `npm test` run; DB tests not run |

Critical defect confirmed by reading source (not by report claim): in `0003_audit_ledger.sql`, every lifecycle function resolves `actor_identity_id` (an editorial identity UUID) but then inserts it into `actor_id`, whose FK target is `auth.users(id)`. For example `return_resource_article` line 194 inserts `actor_identity_id`; `approve_resource_article` line 271; `publish_resource_article` line 335; `archive_resource_article` line 397; `correct_resource_article` line 460. Only `submit_resource_article` (line 122) correctly inserts `actor_id` (the auth.users UUID). This is an inconsistent, defect-ridden implementation.

No comments, documentation, or previous reports constitute proof that these defects were repaired. The source still contains them. Therefore **Task 2 is NOT STARTED** in the inspected repository state.

---

## 5. Security and technical blockers

1. **Actor/identity UUID mismatch in audit FK** (`0003_audit_ledger.sql`): `actor_id` references `auth.users(id)` but receives editorial `identity_id` values from 5 of 6 lifecycle functions. Breaks referential semantics and audit attribution. **Must fix before editorial write path is enabled.**
2. **No editorial identity provisioning**: No trigger/function creates a `resource_editorial_identities` row when a Supabase Auth user signs up. `user_id` cannot be populated automatically; editorial accounts cannot be created through the normal Auth flow.
3. **Security tests not executed in CI or locally**: `supabase/tests/rls_policies.sql` assertions are never run (CI Supabase steps are commented out and gated behind `SUPABASE_ACCESS_TOKEN`; no local Supabase instance available here). RLS effectiveness is unverified against a live database.
4. **No independent Supabase project provisioned**: `supabase/config.toml` has empty `external_url` fields; no project URL/anon/service-role keys exist. `.env.local` is not committed and must be created by the owner.
5. **Service-role key never committed**: Correct by design, but means all editorial write operations require server-side credentials that must be provisioned out-of-band.
6. **No recovery operator / break-glass identity**: Migration map flags this as a blocker; no editorial admin lockout recovery path defined.
7. **Image bucket `resource-center-images` not created**: Storage library references a bucket that does not yet exist in any project.

---

## 6. Remaining implementation roadmap (dependency-ordered)

| Stage | Current status | Outstanding work | Dependencies | Deliverable | Verification | Environment |
|---|---|---|---|---|---|---|
| 1. Backend scaffold completion & security repair | Scaffold present; security defects in 0003 | Repair actor/identity UUID mismatch; add identity provisioning trigger; enforce capability checks; prevent self-approval; block direct writes | None (source-only) | Corrected `0003_audit_ledger.sql` (+ new migration if needed) | tsc + vitest (DB-independent); SQL review | Cloud Shell / local |
| 2. Local DB migration & testing | Not runnable here (no Supabase CLI/Docker/psql verified) | Apply migrations to local Supabase; run `rls_policies.sql` and vitest DB tests | Stage 1 complete; Supabase CLI + Docker | Local DB passing security tests | `supabase db reset` + test assertions green | Local with Docker (not Cloud Shell verified) |
| 3. Independent Supabase project setup | Not started | Provision new Supabase project; obtain URL/anon/service-role keys | Owner action (Supabase dashboard) | New project with credentials | Dashboard project active | Supabase dashboard |
| 4. Remote DB migration & verification | Not started | Push migrations to remote project; verify schema | Stage 3; `SUPABASE_ACCESS_TOKEN` | Remote schema applied | `supabase db push` success; dashboard schema inspect | Cloud Shell (CLI) or dashboard |
| 5. Editorial auth & role setup | Not started | Create editorial identities; grant author/reviewer/publisher capabilities; optional MFA | Stage 4; seed data | Editorial accounts with capabilities | Identities + capabilities queryable | Supabase dashboard / SQL Editor |
| 6. Editorial content management backend | Not started (defects in stage 1 block) | Wire lifecycle functions to editorial UI/API; revision create; publish flow | Stage 1 + 5 | Functional editorial write path | End-to-end submit/review/publish | Cloud Shell + remote project |
| 7. Frontend integration with new backend | Not started | Repoint `lib/resource-center.ts` to new backend URL/anon key; image bucket `resource-center-images` | Stage 4; frontend change (separate repo) | Frontend reads from new backend | Public pages load published articles | Codespaces/Cloud Shell (frontend repo) |
| 8. Public publishing & lifecycle verification | Not started | Verify published-only public view; scheduling; archiving; correction immutability | Stage 6 + 7 | Public reads show only published content | Anon reads return published only; drafts hidden | Remote project + frontend |
| 9. Production deployment & monitoring | Not started | Set production env vars; monitoring | All prior stages | Live independent backend | Production smoke tests | Supabase dashboard + Vercel |

Only genuinely necessary stages are included; no phases repeat completed work (e.g., repository creation, migration map, initial scaffold are done).

---

## 7. Google Cloud Shell feasibility assessment (Part 5)

| Capability | Present in this environment? | Cloud Shell viability | Category (A/B/C/D) |
|---|---|---|---|
| Git + GitHub auth | `git` available; `gh` logged in as ImperioKDB (GITHUB_TOKEN) | Clone/push both repos directly | A |
| Node.js + npm | Node v24.22.2, npm 11.19.1 available | `npm install`, `npm test`, `tsc` run directly | A |
| TypeScript + vitest unit tests | `typescript`, `vitest` in devDependencies | `npx tsc --noEmit`, `npm test` (DB-independent tests) run directly | A |
| GitHub Actions interaction | `gh` available; can view runs, trigger via push | CI can be triggered by pushing to main | A/C |
| OpenCode installation & execution | `opencode` available at `/home/codespace/.opencode/bin/opencode` | Can run OpenCode directly | A |
| AI model/provider config | Not inspected (no install) | Depends on provider keys; not a Cloud Shell limitation | D (provider-dependent) |
| Environment variables & secrets | `.env.local` not committed; must be created by owner | Owner creates `.env.local` with real keys | A (manual, out-of-band) |
| Session persistence / filesystem | Cloud Shell home is persistent within session; idle timeouts apply | Work persists across sessions within the same VM; not guaranteed across VM rebuilds | B (session limits) |
| Docker / local Supabase | `docker` binary present (v29.9.2); **Supabase CLI NOT installed**; `psql` NOT installed | Cannot run `supabase start`/`db reset`/local DB tests without installing (prohibited in this assessment; install not confirmed possible) | B |
| Supabase dashboard interaction | Web-based; accessible via browser | Remote project provisioning, SQL Editor, migration application | C |

**Category A (direct in Cloud Shell):** Git/GitHub, Node/npm, TypeScript, vitest (DB-independent), OpenCode, GitHub Actions via push, env var setup, Supabase dashboard via browser.
**Category B (limited/restricted in Cloud Shell):** Docker/local Supabase execution (CLI not installed, psql missing, install not confirmed/permitted), session persistence limits.
**Category C (better via GitHub Actions / Supabase dashboard):** CI with DB tests (needs `SUPABASE_ACCESS_TOKEN` + runner with Docker), remote project provisioning, migration push, SQL execution.
**Category D (paid/separately provisioned service):** Independent Supabase project (free tier available but must be provisioned), AI model provider keys.

**Verdict:** Cloud Shell is a **viable replacement for Codespaces** for source editing, TypeScript typecheck, DB-independent vitest tests, Git/GitHub workflow, and OpenCode. It is **not** a direct substitute for local Supabase/Docker-based database migration testing unless Docker + Supabase CLI can be installed (not verified, not permitted to install during this assessment). Database work should be done against a remote Supabase project via the Supabase dashboard/SQL Editor or via GitHub Actions with a Docker-capable runner.

**Cheapest reliable workflow:** Develop source in Cloud Shell (Node/TS/vitest/git), provision a free-tier Supabase project via the dashboard, apply migrations and seed via the Supabase dashboard SQL Editor or `supabase db push` if CLI can be added, run DB security tests against the remote project or in GitHub Actions, keep Codespaces only if Docker-based local Supabase testing is strictly required.

---

## 8. Safe migration procedure (Part 6)

Do NOT run `git reset`, `rebase`, `force-push`, or discard uncommitted work.

1. In Cloud Shell, `git clone` the three repos (fresh clones, no history rewriting):
   - `ImperioKDB/Scholars-Resource-Centre` (default branch `main`, SHA `3eef3c25fb332f9351c4f7e97397b74e34f2ab51`)
   - `ImperioKDB/Scholars` (default branch `main`, SHA `b4d1ff91ad53e44741a15d17384bf480d2570524`)
   - `ImperioKDB/Updates` (default branch `main`, SHA `791723ca8c1a89a9f6ed0a065119c22e7812643b`)
2. Verify `git status` is clean in each clone before branching.
3. Create a new feature branch off `main` in the backend repo for the security repair (e.g., `fix/resource-centre-task-2-security-repair`). Do not touch `main`.
4. Commit only source changes to the backend repo; push the branch; open a PR against `main`. Do not merge without review.
5. Create `.env.local` in the backend repo from `.env.example` with real Supabase credentials (never commit it). Same for frontend if repointing later.
6. No uncommitted work exists in the current clones; no local-only branches; no unfinished work detected outside committed history.
7. GitHub remote URLs in the local working tree `/workspaces/Scholars` contain embedded PATs (`x-access-token`/`github_pat`) — this is a pre-existing credential exposure in remote config, not something to change during this read-only task.

---

## 9. Exact next task

**Backend security repair of `supabase/migrations/0003_audit_ledger.sql`:**

1. Fix the actor/identity UUID mismatch: lifecycle functions must insert the authenticated `auth.uid()` (Auth user UUID) into `actor_id` (FK → `auth.users(id)`), not the editorial `identity_id`. Track `actor_identity_id` separately if editorial-identity attribution is needed (add a nullable column or use `revision_id`/`article_id` linkage).
2. Add an Auth signup trigger/function that provisions a `resource_editorial_identities` row (populating `user_id`) so editorial identities derive from Auth users.
3. Confirm capability checks, author self-approval prevention, and direct-write blocking remain enforced (they are present in design; verify after repair).
4. Add a migration ordering verification step and enable execution of `supabase/tests/rls_policies.sql` against a live instance.

Deliverable: corrected migration file(s) committed to a feature branch in `ImperioKDB/Scholars-Resource-Centre`, with a PR opened against `main`.

**Do not begin implementation. Wait for my review and explicit approval.**

---

## 10. Evidence links, file paths and commit SHAs

Backend repo (`ImperioKDB/Scholars-Resource-Centre`, SHA `3eef3c25fb332f9351c4f7e97397b74e34f2ab51`):
- https://github.com/ImperioKDB/Scholars-Resource-Centre
- Migrations: `supabase/migrations/0001_init.sql`, `0002_editorial_capabilities.sql`, `0003_audit_ledger.sql`
- Tests: `supabase/tests/seed.sql`, `supabase/tests/rls_policies.sql`
- Lib: `lib/editorial/auth.ts`, `capabilities.ts`, `audit.ts` (+ `.test.ts`); `lib/content/articles.ts`, `categories.ts`, `revisions.ts` (+ `.test.ts`); `lib/storage/images.ts`
- CI: `.github/workflows/ci.yml`
- Config: `.env.example`, `package.json`, `tsconfig.json`, `supabase/config.toml`
- Migration map: `reports/scholars/docs/frontend-backend-migration-map.md`
- Head commit: 3eef3c2 `fix: correct RLS privilege migration, fix SQL privilege function signatures, fix RLS test files, add unit tests for editorial capabilities`
- Prior commit: 9254a8e `docs: publish Phase 2B Task 1 migration map and initial backend scaffolding`

Frontend repo (`ImperioKDB/Scholars`, SHA `b4d1ff91ad53e44741a15d17384bf480d2570524`):
- https://github.com/ImperioKDB/Scholars
- Pages: `app/resources/page.tsx`, `app/resources/[slug]/page.tsx`, `app/resources/category/[slug]/page.tsx`
- Components: `components/resource-center.tsx`, `resource-center-search.tsx`, `resource-center-interactions.tsx`, `ResourceArticleBody.tsx`
- Data: `lib/resource-center.ts`, `lib/resource-content.ts`
- Supabase clients: `lib/supabase/server.ts`, `public.ts`, `config.ts`
- Head commit: b4d1ff9 `feat(scholars): implement official logo as website favicon`

Updates repo (`ImperioKDB/Updates`, SHA `791723ca8c1a89a9f6ed0a065119c22e7812643b`):
- https://github.com/ImperioKDB/Updates
- Target report path (proposed): `SCHOLARS_RESOURCE_CENTRE_CURRENT_STATE_AND_GOOGLE_CLOUD_SHELL_MIGRATION_ASSESSMENT.md`
- Related reports: `reports/scholars/2026-11-13-scholars-supabase-authorization-hardening.md`, `reports/scholars/2026-11-14-resource-center-phase-2b-security-readiness-audit.md`

---

## Verified facts vs assumptions vs recommendations

**Verified facts:** repository SHAs, branch states, file contents (migrations, lib, tests, CI), presence/absence of provisioning triggers, UUID mismatch in `0003_audit_ledger.sql`, frontend Resource Centre page/component list, frontend local-content source of truth, CI Supabase steps commented out, tool availability (node/npm/docker/gh/opencode/psql absent/supabase CLI absent), no uncommitted changes, no open backend PRs.

**Assumptions:** Cloud Shell Docker availability (not verified; `docker` binary present but Supabase CLI/psql not installed), Supabase free-tier project provisioning is possible, owner will create `.env.local` out-of-band.

**Recommendations:** Cloud Shell for source/TS/vitest/git work; Supabase dashboard for project provisioning and SQL; GitHub Actions or a Docker-capable runner for DB migration/security tests; do not implement roadmap until this report is approved; exact next task is the `0003_audit_ledger.sql` security repair.
