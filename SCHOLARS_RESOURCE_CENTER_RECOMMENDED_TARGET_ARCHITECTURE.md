# Scholars Resource Centre
## Recommended Target Architecture

**Architecture date:** 2026-11-15  
**Scholars commit assessed:** `142146a67cb21eeec8d74832bc326c1fcd5dd5f4`  
**Target:** Public Resource Centre at `/resources`, administrative surface at `/admin/resources`  
**Decision:** Same Scholars application, logically isolated content module, repository-backed public baseline, optional dedicated Supabase editorial backend.

> This is a target design, not an implementation or migration authorization.

## 1. Architectural decision

Build the Resource Centre as a **logical module within `ImperioKDB/Scholars`**. Do not create a second application or pursue full Scholars database reconstruction. Keep the public launch resilient through repository-backed content. Add a dedicated Resource Centre schema only when non-technical editorial management, drafts, scheduled publishing, revisions and database-backed content volume justify it.

The module has two compatible content sources:

1. **Repository source:** approved launch content in `lib/resource-content.ts`; always sufficient for the public MVP.
2. **Database source:** published rows exposed through `resource_public_*` projection views; optional until the bounded staging and production gates pass.

The public route contract remains stable regardless of source.

## 2. Boundary diagram

```mermaid
flowchart LR
  Visitor[Anonymous visitor] --> Next[Scholars Next.js App Router]
  Next --> PublicRoutes[/resources routes]
  PublicRoutes --> Local[Repository-approved local content]
  PublicRoutes --> Views[Supabase public projection views]
  Views --> RDB[(Dedicated Resource Centre tables)]

  Editor[Authenticated administrator] --> AdminRoutes[/admin/resources]
  AdminRoutes --> Guard[requireAdmin / assertAdmin / optional AAL2]
  Guard --> Writes[Server-only editorial mutations]
  Writes --> RDB
  Writes --> Revisions[Immutable resource_revisions]

  PublicRoutes --> SEO[Metadata, JSON-LD, sitemap]
  PublicRoutes --> Catalogue[Links to public scholarship/opportunity pages]

  RDB -. must not touch .-> Unrelated[(Profiles, applications, matching, XP, community, discovery)]
```

This diagram expresses logical separation, not a separate physical database project. The same Supabase project may host the dedicated tables, but public roles must not receive base-table access.

## 3. Module structure

```text
app/resources/page.tsx
app/resources/[slug]/page.tsx
app/resources/category/[slug]/page.tsx
app/admin/resources/page.tsx
app/api/admin/resources/*                 # future guarded mutations
components/resource-center.tsx
components/resource-center-search.tsx
components/ResourceArticleBody.tsx
lib/resource-center.ts
lib/resource-content.ts                    # repository fallback/source
lib/sitemap-data.ts
supabase/migrations/<unique-resource-version>.sql
```

The current public routes and components already establish most of this boundary. The missing product capability is the editorial mutation workflow, not public route architecture.

## 4. Public data flow

1. A visitor requests `/resources`, an article, or a category.
2. The server component loads the local approved source and, when public Supabase configuration is present, attempts a read from the relevant `resource_public_*` view.
3. Local content remains available if the optional public projection is unavailable. Database-backed rows are merged by slug without changing the public URL contract.
4. The server renders crawler-visible HTML, metadata, canonical URL, structured data and internal links.
5. The sitemap reads only approved public resource rows/categories plus static routes.
6. No profile, matching, application, XP, community or private base-table data is needed.

Public query rules:

- Use the normal server Supabase client, never the service-role client in public route code.
- Query only `resource_public_articles`, `resource_public_categories`, `resource_public_article_categories`, and optionally the editorial identity projection.
- Keep explicit column lists.
- Depend on fixed view predicates for `status = 'published'`, non-null publication time, `published_at <= now()`, active categories and active authors.
- Preserve the local fallback and explicit error states; never fall back from a database error to unreviewed or private content.

## 5. Dedicated data model

The approved source migration proposes five tables:

- `resource_editorial_identities`: public display name/bio/avatar path, optional private user link, active flag.
- `resource_categories`: stable URL slug, name, description, order and active flag.
- `resource_articles`: slug, title, excerpt, controlled Markdown, article type, status, schedule/publication/review dates, canonical/image fields, author/reviewer identity links and actor fields.
- `resource_article_categories`: many-to-many article taxonomy.
- `resource_revisions`: immutable revision number, JSON state, schema version, change summary and creator.

Required invariants:

- Unique lowercase URL-safe slugs.
- Explicit lifecycle: `draft`, `in_review`, `scheduled`, `published`, `archived`.
- Published rows have publication time and reviewer identity.
- Scheduled rows have schedule time.
- Public reads exclude future publication and inactive identities/categories.
- Revision state is an object and revision numbers are unique per article.
- Public identity projection excludes `user_id`, actor IDs, timestamps not approved for display and other private fields.
- Hard deletion is not part of the first editorial workflow; archive and revision history are preferred.

The schema in `supabase/migrations/20261107130100_resource_center_schema.sql` is a design/input artifact for gated staging validation. It is not proof that the live project has identical objects or grants.

## 6. Authorization model

### Public

No authentication. Public roles receive `SELECT` only on projection views. They receive no base-table privileges and no write capability.

### Administrator/editor

Use the existing layered Scholars controls:

- `requireAdmin()` for `/admin/resources` server components.
- `assertAdmin()` for `/api/admin/resources/*` or server actions.
- Existing middleware protection for `/api/admin/*`.
- Optional explicit AAL2 for publish/schedule operations.
- Server-side validation and actor attribution on every mutation.

The current migration’s RLS policies call `public.is_admin(auth.uid())`. Treat this as a required security review item, not an implicit trust anchor. Before staging use, verify function definition, owner, search path, effective grants, profile lookup behavior, RLS interaction and MFA expectations. Do not create a replacement function without an approved comparison to the existing model.

### Editorial workflow

```text
Draft -> In review -> Scheduled or Published -> Archived
             |              |
             +--------------+--> Revision + audit record
```

Recommended rules:

- Author may create/edit a draft.
- Reviewer must be a separate approved editorial identity for normal publication.
- Publish/schedule is an explicit server-side action.
- Self-approval is rejected by default.
- Unpublish/archive preserves the revision and audit record.
- Preview is authenticated, protected and `noindex`; it is never part of public projection or sitemap.
- AI-assisted drafts remain unpublished until human review.

## 7. Database and infrastructure options

| Option | Fit | Security/isolation | Operations | Decision |
|---|---|---|---|---|
| Same Supabase project, dedicated tables/views | Strong fit for maintained CMS | Logical isolation; reuse existing auth/admin; requires RLS/grant validation | Lowest additional operational burden | **Recommended with conditions** |
| Separate Supabase project | Technically strong but heavy | Physical isolation; independent credentials/auth/backup | Two systems, cross-project integration, more cost and failure modes | Reserve for a future product/security requirement |
| Repository/file content only | Strong fit for public MVP | Smallest attack surface, no DB dependency | Git-based editorial process; weak non-technical CMS | **Required baseline / fallback** |

A separate project is not required merely because the full Scholars staging history is difficult to reconstruct. The Resource Centre’s public functionality is already independent of that history.

## 8. Deployment and routing

Keep the existing GitHub-to-Vercel deployment and `scholars.com.ng` domain. The current production verification recorded the Resource Centre serving from the production deployment, with route metadata, JSON-LD and sitemap coverage. Future changes should run the existing CI typecheck, tests and build, then a Preview deployment bound to staging-only Supabase configuration.

Required environment behavior:

- `NEXT_PUBLIC_APP_URL` supplies canonical base configuration, with the existing approved fallback.
- `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` are public values for normal reads.
- `SUPABASE_SERVICE_ROLE_KEY` remains server-only and is not needed for the repository-backed public baseline.
- Ad variables remain disabled/blank until separate consent and policy approval.
- Preview must not use production service credentials.

No new deployment or domain is required. No middleware change is required for public routes; preserve their position outside protected route groups.

## 9. Staging target

Use `scholars-staging` only for a bounded Resource Centre baseline:

1. Review and approve a standalone bundle for the five tables, indexes, RLS, grants, views and minimum authorization dependency.
2. Apply only that bundle after an authorized staging change window; never replay all 136 Scholars migrations.
3. Verify object inventory, grants, view predicates and policies read-only.
4. Seed only synthetic editorial identities, categories, one published article, one draft, one future-scheduled article, one inactive identity and one inactive category.
5. Create synthetic anonymous/non-admin/admin/MFA test identities only after the base passes.
6. Run route and direct Supabase access tests.
7. Bind Vercel Preview to staging-only values and run CI/Preview verification.

The empty staging project is an asset for isolation, not evidence of application parity. It must not be treated as production-like until the bounded baseline is explicitly established.

## 10. Files and systems to keep untouched

Unless a separate change is approved, do not modify:

- `middleware.ts` authentication/session and protected-route semantics.
- `app/auth/callback/route.ts`, onboarding, password recovery and MFA implementation.
- `profiles` schema and profile mutation flows, except a separately reviewed optional editorial identity link.
- `lib/matching/`, eligibility scoring and explanation logic.
- Applications, saved scholarships, deadlines, XP, achievements, community, notifications and generic workflow workers.
- Scholarship/discovery tables, publication flows and RLS.
- Production environment variables and deployment configuration.
- Existing public scholarship URLs and JSON-LD semantics.

Resource articles may link to public catalogue pages, but they must not become matching inputs, application state, notification targets or profile-derived recommendations without a separate product/security decision.

## 11. Observability and recovery

Log editorial mutation failures using existing server logging conventions without logging article secrets or student data. Monitor public route error rates, sitemap generation, projection query errors, publish/unpublish outcomes and stale review dates. Keep the repository source as a known-good public fallback during the transition.

For production schema work, take an owner-approved schema/data backup or provider snapshot of the new Resource Centre objects, record migration checksum and expected object inventory, deploy backward-compatible code, verify, and retain a reviewed reverse migration. Roll back the Resource Centre feature or schema only; never use a reset/drop strategy that risks unrelated Scholars objects.

## 12. Target acceptance criteria

The target architecture is ready for the next implementation phase only when:

- Public routes work without login and without database-backed student records.
- Public queries use only explicit projection views or repository content.
- Draft/future/inactive content is absent from routes and sitemap.
- Base-table reads and all public writes are denied.
- Non-admin authenticated users cannot mutate editorial rows.
- Admin reads work through the existing guard.
- Publish/schedule requires the approved reviewer/MFA rules.
- Revisions preserve prior state and actor attribution.
- No service-role value is present in browser bundles or public responses.
- Preview uses staging-only credentials and does not share production secrets.
- Existing auth, matching, application and catalogue regression tests pass.
- Ads remain disabled unless the separate privacy/monetization gate passes.

**Target conclusion:** same repository, same domain, dedicated logical content schema when needed, repository-backed public baseline always retained, existing admin boundary reused only after explicit security verification, and no full Scholars database reconstruction.
