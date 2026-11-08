# File

`/tmp/scholars-a03-snapshot/scholars-41573f5/supabase/migrations/20261107130100_resource_center_schema.sql`

The file is labeled “Resource Center Phase 1 schema” and describes itself as additive. This review is based solely on the SQL text in this file. No SQL was executed, no Supabase instance or hosted service was accessed, and no runtime behavior, ownership, policy evaluation, or deployment state was verified.

# Scope

This migration creates the Resource Center’s editorial, categorization, article, join, and revision schema; adds indexes and one deferred foreign key; enables row-level security; revokes and grants table/view privileges; creates authenticated-admin policies; and creates four public projection views. It contains no `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `COPY`, seed data, or other row-changing DML. It also does not create triggers, trigger functions, stored procedures, materialized views, sequences explicitly, storage buckets, HTTP calls, extensions, or scheduled jobs.

The file uses `if not exists` for tables and indexes and `create or replace view` for projections, but the later `alter table ... add constraint` and `create policy` statements are not guarded. Re-running against an already-partially-created installation may therefore fail on the unguarded constraint or policies, and the view replacement remains subject to PostgreSQL’s normal compatibility rules.

# Objects and mutations

## Tables and columns

1. **`public.resource_editorial_identities`** is created if absent. It has:
   - `id uuid primary key default gen_random_uuid()`;
   - nullable `user_id uuid` referencing `auth.users(id)` with `on delete set null`;
   - required, trimmed-length-bounded `display_name` (1–160 characters);
   - nullable `bio` capped at 1,000 characters;
   - nullable `avatar_path` rejecting path components matching `..` or backslashes;
   - `is_active boolean not null default true`;
   - `created_at` and `updated_at` as non-null `timestamptz` values defaulting to `now()`.

2. **`public.resource_categories`** is created if absent. It has:
   - UUID primary key with `gen_random_uuid()` default;
   - unique, required slug constrained to lowercase alphanumeric hyphenated form;
   - required name trimmed to 1–100 characters;
   - nullable description capped at 500 characters;
   - nonnegative `display_order` defaulting to 0;
   - `is_active` defaulting true;
   - `created_at` and `updated_at` defaulting to `now()`.

3. **`public.resource_articles`** is created if absent. It has:
   - UUID primary key and unique, lowercase-hyphenated slug;
   - required title, 1–220 trimmed characters;
   - nullable excerpt capped at 500 characters;
   - required `content_markdown`, default empty string, capped at 500,000 characters;
   - `article_type` default `guide`, limited to `guide`, `news`, `deadline`, or `opportunity`;
   - `status` default `draft`, limited to `draft`, `in_review`, `scheduled`, `published`, or `archived`;
   - scheduling/publication/archive/review timestamps;
   - nullable `canonical_url` accepted only when it begins with `https://`;
   - nullable `featured_image_path` with the same traversal/backslash rejection pattern as the avatar path;
   - nullable `reading_time_minutes`, constrained to 1–240 when present;
   - required `author_identity_id` referencing editorial identities with `on delete restrict`;
   - nullable `reviewer_identity_id` referencing editorial identities with `on delete restrict`;
   - nullable `created_by` and `updated_by` references to `auth.users(id)` with `on delete set null`;
   - nullable `published_revision_id`, later constrained to revisions with `on delete restrict`;
   - non-null `created_at` and `updated_at` defaults;
   - `resource_articles_scheduled_requires_time`: scheduled articles require `scheduled_for`;
   - `resource_articles_published_requires_time`: published articles require `published_at`;
   - `resource_articles_published_requires_reviewer`: `in_review`, `scheduled`, and `published` articles require a reviewer identity.

4. **`public.resource_article_categories`** is created if absent. It is a many-to-many join table with required `article_id` and `category_id`, `created_at`, and composite primary key `(article_id, category_id)`. Article deletion cascades to the join rows; category deletion is restricted.

5. **`public.resource_revisions`** is created if absent. It has:
   - UUID primary key with `gen_random_uuid()` default;
   - required article reference with `on delete cascade`;
   - positive `revision_number`;
   - required JSONB `state` which must be a JSON object;
   - `schema_version` default 1 and constrained to exactly 1;
   - nullable change summary capped at 1,000 characters;
   - nullable creator reference to `auth.users(id)` with `on delete set null`;
   - `created_at` defaulting to `now()`;
   - unique `(article_id, revision_number)`.

## Indexes

The migration creates these indexes if absent:

- `resource_editorial_identities_user_uidx`: unique partial index on `resource_editorial_identities(user_id)` where `user_id is not null`.
- `resource_editorial_identities_active_idx`: `(is_active, display_name)`.
- `resource_categories_active_idx`: `(is_active, display_order, slug)`.
- `resource_articles_public_idx`: `(status, published_at desc)`.
- `resource_articles_scheduled_idx`: `(status, scheduled_for)`.
- `resource_articles_author_idx`: `(author_identity_id)`.
- `resource_articles_reviewer_idx`: `(reviewer_identity_id)`.
- `resource_article_categories_category_idx`: `(category_id, article_id)`.
- `resource_revisions_article_idx`: `(article_id, revision_number desc)`.

Primary keys and declared unique constraints also create their normal unique indexes, although the file does not name those implicit indexes.

## Constraint mutation and dependency closure

After creating the article and revision tables, the file adds `resource_articles_published_revision_fk` to `resource_articles.published_revision_id`, referencing `resource_revisions(id)` with `on delete restrict`. This ordering intentionally resolves the otherwise circular design dependency: articles reference identities during table creation, revisions reference articles during table creation, and the article-to-revision foreign key is added only after revisions exist.

## RLS, revokes, grants, and policies

Row-level security is enabled on all five base tables: editorial identities, categories, articles, article categories, and revisions.

For the five base tables, `revoke all` is issued from both `anon` and `authenticated`. `service_role` receives `all` on all five tables. `authenticated` receives `select, insert, update` on the first four tables, while revisions receive only `select, insert`.

The following policies are created for `authenticated`:

- `resource_editorial_admin_all`: `for all` on editorial identities, with both `using` and `with check` requiring `public.is_admin(auth.uid())`.
- `resource_categories_admin_all`: same all-operation admin predicate for categories.
- `resource_articles_admin_all`: same all-operation admin predicate for articles.
- `resource_article_categories_admin_all`: same all-operation admin predicate for the join table.
- `resource_revisions_admin_insert`: insert only when `public.is_admin(auth.uid())` and `created_by = auth.uid()`; the same expression is the `with check` predicate.
- `resource_revisions_admin_select`: select only when `public.is_admin(auth.uid())`.

The SQL text does not create `public.is_admin`; it assumes that function already exists and is callable in the policy context. The policy/grant combination means ordinary authenticated users receive table privileges but are intended to pass only the admin policies; the file itself does not establish any non-admin access path to base tables.

## Views

Four views are created or replaced, each with `security_barrier = true`:

1. **`public.resource_public_editorial_identities`** selects `id`, `display_name`, `bio`, and `avatar_path` from active editorial identities only (`is_active = true`).
2. **`public.resource_public_categories`** selects `id`, `slug`, `name`, `description`, and `display_order` from active categories only.
3. **`public.resource_public_articles`** selects an explicit publication projection: article id, slug, title, excerpt, markdown content, type, canonical URL, featured image path, reading time, publication/review timestamps, and author display/bio/avatar fields. It joins only active authors and filters to `status = 'published'`, non-null `published_at`, and `published_at <= now()`.
4. **`public.resource_public_article_categories`** selects article/category linkage plus category display fields, joining the join table to active categories and articles that are published with non-null publication timestamps not later than `now()`.

The views explicitly omit administrative fields such as draft status, scheduling timestamps, creator IDs, reviewer IDs, revision IDs, and the inactive flag. The comments state that projections are intended to run with the view owner rather than the visitor’s base-table privileges, but that owner/security behavior is not runtime-verified here.

For all four views, `revoke all` is issued from `public`, and `select` is granted to both `anon` and `authenticated`. No view-specific grant is given to `service_role` because the broad base-table grant already covers that role’s underlying access; no explicit view-owner change is present in the file.

# Dependencies

Direct external/schema dependencies declared or referenced by this file are:

- `auth.users(id)`, required for the user foreign keys on editorial identities, articles, and revisions. This is an external/auth schema dependency, not data inserted by this migration.
- `gen_random_uuid()`, required by UUID defaults. The function is assumed to be available; the file does not create or enable the extension that might provide it.
- `public.is_admin(uuid)` (invoked as `public.is_admin(auth.uid())`), required by every authenticated base-table policy. The function is assumed to pre-exist; the file does not define it.
- PostgreSQL built-ins `now()`, `auth.uid()`, `char_length`, `btrim`, `jsonb_typeof`, and regex operators.
- Internal object ordering: identities and categories precede articles; articles precede the article-category and revision tables; revisions must exist before the article-to-revision foreign key is added; all base tables must exist before their RLS, privilege, and policy statements; all source tables must exist before the views.
- View dependencies: the editorial and category projection views depend on their corresponding base tables; the public articles view depends on articles plus editorial identities; the public article-categories view depends on article categories, categories, and articles.

No dependency on another migration was inspected or inferred beyond the symbols named in this file. In particular, this audit does not establish whether the `auth` schema, `public.is_admin`, or UUID function are actually present in the target installation.

# Data/external-side-effect assessment

There is no data mutation in the file. It creates schema metadata, indexes, constraints, RLS state, policies, privileges, and views only. Consequently, it does not seed editorial identities, categories, articles, revisions, URLs, image paths, or markdown content, and it does not contact an external URL or service.

The only URL-like content is a column-level validation rule requiring `resource_articles.canonical_url` to start with `https://`; this validates future stored values but does not fetch them. `avatar_path` and `featured_image_path` are path-like text fields with checks rejecting `..` path components and backslashes; no files are read, written, uploaded, or deleted. The views expose `canonical_url`, content markdown, and image paths for qualifying published rows, but the migration creates no rows to expose.

# Security/ordering implications

The intended security boundary is clear in the SQL comments and statements: base tables are admin/editor surfaces, public roles have no base-table `SELECT`, and anonymous/authenticated readers use explicit projections. RLS is enabled before the base-table grants and policies are declared. `security_barrier = true` is specified on every public view to reduce unsafe predicate-reordering concerns at the publication boundary. Explicit column lists reduce accidental disclosure if source tables later gain columns, although replacing a view still requires compatible view-column semantics.

The base-table `revoke all` statements are important because the later authenticated grants are broader than the policies’ effective admin condition; privileges alone do not bypass enabled RLS. The revision policy is deliberately narrower than the other admin policies: authenticated admins may insert only revisions whose `created_by` is their own UID and may select only rows for which they are admins. There is no authenticated update/delete policy for revisions in this file, despite the service role’s full access.

The policy predicates depend on `public.is_admin(auth.uid())`; if that function is absent, has incompatible behavior, or is not safely defined, policy creation or intended authorization may fail. Because the function body is outside this file, its security properties cannot be assessed here.

The public views are not explicitly assigned an owner and the file does not set `security_invoker`. The comments assert owner-based projection behavior, but effective view access and interaction with underlying RLS depend on PostgreSQL/Supabase version, object ownership, grants, and deployment defaults. This is a material point requiring runtime or installation-level verification, which was intentionally not performed. The `public` role is revoked from the views and `anon`/`authenticated` are granted `select`; this is explicit but should be checked against the platform’s role model in any real deployment.

The publication predicates are time-sensitive (`published_at <= now()`), so rows can enter or leave a public projection as time advances without a migration. The schema does not enforce all possible state/timestamp relationships: for example, it requires timestamps for scheduled/published states but does not require them to be absent in other states or enforce consistency among archive/review timestamps. It also does not enforce a unique revision ID as the article’s published revision beyond the foreign key; revision-number uniqueness is per article.

Ordering hazards include the required pre-existence of the auth and admin-function dependencies, the deliberate delayed article-to-revision foreign key, and the fact that unguarded policy/constraint statements can fail on partial reruns. `create table if not exists` does not reconcile an existing table’s definition with this file, so a pre-existing object with incompatible columns or constraints can leave a superficially successful but semantically divergent installation. No runtime verification was performed.

# Reconstruction recommendation

For a synthetic schema reconstruction whose scope intentionally excludes the Resource Center feature, this migration can be omitted, provided no reconstructed object references its tables or public views and the reconstruction does not claim to reproduce the full application schema or authorization surface. Omitting it is especially reasonable when the goal is a minimal synthetic schema and no Resource Center rows or behavior are needed; the file contains no seed data whose absence would affect synthetic records.

If the reconstruction aims to preserve Resource Center functionality, public read projections, or security semantics, it should not be omitted. Recreate the five tables, their constraints and indexes, the deferred published-revision foreign key, RLS enablement, exact grants/revokes, six policies, and four security-barrier views. Also provide compatible stand-ins for `auth.users`, `gen_random_uuid()`, and `public.is_admin`, or explicitly document those as external prerequisites. Preserve the table-creation order and add the article-to-revision foreign key only after revisions exist. Do not synthesize real editorial content, canonical URLs, image paths, or markdown unless separately authorized; this migration itself supplies none.

# Verdict

**Read-only assessment: structurally additive Resource Center DDL plus security metadata; no DML or external side effects.** The migration is omissible from a narrowly scoped synthetic reconstruction that excludes Resource Center objects, but omission removes the complete Resource Center schema, public projections, and associated authorization boundary. If included, treat `auth.users`, `gen_random_uuid()`, and especially `public.is_admin` as unresolved prerequisites and treat the view-owner/security-invoker behavior as unverified deployment-sensitive behavior. The audit makes no runtime claims.
