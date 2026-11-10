# Scholars Resource Center — Post-Deployment Security Clarification

**Investigation date:** 2026-11-07  
**Repository:** https://github.com/ImperioKDB/Scholars  
**Reference commit:** `41573f5ec2985851ba118e8b39a47f9c54532302` (`feat: add resource center foundation`)  
**Production Supabase project:** `scholarship-platform` (`cmdglabohpttgfofcmqc`)  
**Production website:** https://scholars.com.ng  
**Scope:** Read-only investigation. No source, migration, database object, permission, record, environment variable, secret, deployment or dependency was changed.

## 1. Executive verdict

**IMPLEMENTATION READINESS: BLOCKED — FOUNDATION IS DEPLOYED, BUT THE EDITORIAL CMS IS NOT READY FOR AUTHORING OR PUBLISHING.**

The deployed Resource Center foundation is present and its five production migrations are recorded. The public projection views are queryable by `anon` and `authenticated`, and their SQL predicates expose only active identities/categories and articles whose status is `published` with a publication time no later than `now()`. No Resource Center rows currently exist, so no draft, scheduled, archived or future-dated content is exposed in the present database state.

The deployed view model is not the approved Phase 0.2 `security_invoker = true` model. All four live views are owned by `postgres`, have `security_barrier=true`, do not have `security_invoker=true`, and execute through an owner context that bypasses RLS. Explicit column projection and fixed publication predicates currently limit the exposed shape, but this is a different security assumption and has a different failure mode from invoker-context views backed by base-table RLS.

The base tables are protected from anonymous reads and from ordinary authenticated students by table ACLs plus RLS. Authenticated admins, however, have a broad `ALL` policy on the article/category/identity tables and can directly update article workflow fields, including `status`, `reviewer_identity_id`, `published_at` and `published_revision_id`. No database-enforced transition operation, reviewer-separation check, approval-freshness check, MFA/AAL2 check or immutable restoration operation exists yet. The current admin policy is therefore an access boundary, not the future editorial workflow boundary.

The security remediation functions are correctly restricted for all five functions inspected: `anon` and `authenticated` cannot execute them, while `service_role` can. However, the live default ACL catalog still contains broad `supabase_admin` defaults for functions, tables and sequences in `public`. The migration narrowed defaults for objects created by `postgres`; it did not eliminate the separate broad `supabase_admin` default rows. Future object-creation paths must be understood before the default-privilege remediation can be considered complete.

The sitemap returns successfully but does not include `/resources` in its static paths and does not generate category URLs. It generates only published article URLs from the public article view. The smallest additive SEO correction is to include the Resource Center index and active category URLs, preferably limiting categories to those with at least one published article if empty category pages should remain non-indexed.

## 2. Verified production state

### 2.1 Migrations and environment

**VERIFIED:** Supabase migration history contains:

- `20261107115338` — `security_boundary_remediation`
- `20261107115403` — `resource_center_schema`

**VERIFIED:** The production project has no Supabase development branches. The authorized project list contains the production project and a separate project named `serena`, but no evidence establishes `serena` as a staging environment. It must not be treated as staging without owner confirmation.

**VERIFIED:** Production Resource Center counts are all zero:

| Object | Count |
|---|---:|
| Articles | 0 |
| Categories | 0 |
| Editorial identities | 0 |
| Revisions | 0 |
| Publicly eligible articles | 0 |

**VERIFIED:** No production test article, category, identity or revision was inserted during this investigation.

## 3. Public-view security comparison

### 3.1 Live view metadata

**VERIFIED:** All four views have the same relevant security shape:

| View | Owner | Options | Owner bypasses RLS | `anon` SELECT | `authenticated` SELECT | `service_role` SELECT |
|---|---|---|---:|---:|---:|---:|
| `resource_public_editorial_identities` | `postgres` | `security_barrier=true` | Yes | Yes | Yes | Yes |
| `resource_public_categories` | `postgres` | `security_barrier=true` | Yes | Yes | Yes | Yes |
| `resource_public_articles` | `postgres` | `security_barrier=true` | Yes | Yes | Yes | Yes |
| `resource_public_article_categories` | `postgres` | `security_barrier=true` | Yes | Yes | Yes | Yes |

**VERIFIED:** No live view has `security_invoker=true` in its `reloptions`.

**VERIFIED:** The underlying five Resource Center tables have RLS enabled but `FORCE ROW LEVEL SECURITY` disabled. They are owned by `postgres`.

### 3.2 Deployed owner-executed model

**VERIFIED:** The migration uses explicit projections and fixed predicates. The article view selects approved public fields and filters on:

- `status = 'published'`
- `published_at IS NOT NULL`
- `published_at <= now()`
- active author identity

The category-link view also requires an active category and a currently published, time-eligible article. The identity and category views require `is_active = true`.

**VERIFIED:** Anonymous visitors can query the views directly through the normal PostgREST privilege path because `anon` has SELECT on each view. No base-table SELECT privilege is granted to `anon`.

**VERIFIED:** Anonymous visitors cannot select the Resource Center base tables directly through their table ACLs. Ordinary authenticated users have table-level SELECT/INSERT/UPDATE grants on the relevant content tables, but the only matching policies require `is_admin(auth.uid())`; ordinary students therefore receive no permitted rows or writes through RLS.

**INFERENCE:** With the current explicit projections and no rows, the deployed owner-context views do not expose private Resource Center columns or records. The safety property depends on every future view definition preserving explicit columns and correct fixed predicates. It does not come from base-table RLS, because the view owner bypasses RLS.

**FAILURE MODE:** A future view edit, join, predicate change or newly exposed column could disclose owner-readable data even if base-table RLS remains strict. `security_barrier` is not equivalent to `security_invoker`; it addresses predicate pushdown behavior, not which role’s permissions and RLS policies govern the underlying query.

### 3.3 Approved invoker model comparison

**RECOMMENDATION:** The Phase 0.2 architecture should either be implemented exactly with `security_invoker=true` and explicit published-only base-table policies, or the owner-context projection model should be explicitly approved as the intended alternative and covered by view-definition regression tests.

Under `security_invoker=true`, the querying role’s privileges and base-table RLS determine visibility. This makes row-level publication rules part of the database boundary, but requires carefully designed public RLS policies and PostgreSQL-version compatibility testing.

Under the deployed owner-context model, public roles need SELECT only on the projections and private base-table columns are omitted by construction. This can be a valid projection boundary, but it requires strict review of every view definition, explicit column-list tests and controls preventing future owner-context views from bypassing the intended publication boundary.

The two approaches should not be described interchangeably.

## 4. Base-table ACL and RLS matrix

**VERIFIED:**

| Table | RLS | FORCE RLS | `anon` SELECT | Authenticated table grants | Admin policy | Revision update/delete policy |
|---|---:|---:|---:|---|---|---|
| `resource_editorial_identities` | Yes | No | No | SELECT/INSERT/UPDATE | `ALL` for admins | Not applicable |
| `resource_categories` | Yes | No | No | SELECT/INSERT/UPDATE | `ALL` for admins | Not applicable |
| `resource_articles` | Yes | No | No | SELECT/INSERT/UPDATE | `ALL` for admins | Not applicable |
| `resource_article_categories` | Yes | No | No | SELECT/INSERT/UPDATE | `ALL` for admins | Not applicable |
| `resource_revisions` | Yes | No | No | SELECT/INSERT | Admin SELECT and admin INSERT only | No authenticated UPDATE or DELETE grant/policy |

The article/category/identity policies use `is_admin(auth.uid())` for both `USING` and `WITH CHECK`. The revision policies permit admin SELECT and admin INSERT only where `created_by = auth.uid()`.

**VERIFIED:** Anonymous users cannot select or mutate the base tables. Ordinary authenticated students have no RLS-allowed rows because they are not admins.

**VERIFIED:** An authenticated admin can directly change article status and other workflow-related fields using the normal authenticated data path, subject only to the broad admin policy and column/table constraints. The database does not currently require a valid transition sequence, separate author/reviewer identity, fresh approval, MFA/AAL2, matching revision snapshot or scheduled-time invariant for such updates.

**VERIFIED:** Authenticated admins cannot update or delete revision snapshots through the current authenticated table privileges and policies. Revisions have a unique `(article_id, revision_number)` constraint and an object-type check on `state`, but no complete snapshot contract.

**VERIFIED:** `service_role` has the required controlled server-side table privileges and bypasses RLS by design. The current schema does not itself ensure that all future service-role use is limited to narrow workflow operations.

**CONCLUSION:** The present admin policy controls who can access the tables. It does not implement the future editorial workflow. The direct admin update path is the principal operation that can bypass the intended future publishing sequence if authoring is built on top of the current broad `ALL` policy without adding guarded transitions.

## 5. Revision-integrity assessment

**VERIFIED:** `resource_revisions.state` is `jsonb NOT NULL` with only this structural check:

```sql
jsonb_typeof(state) = 'object'
```

The database does not enforce required keys, complete article fields, category associations, author/reviewer display snapshots, source metadata, review metadata, publication timestamps or canonical URL consistency.

| Requirement | Current status |
|---|---|
| Complete article-state snapshots | **UNVERIFIED / NOT ENFORCED** — arbitrary JSON object is accepted |
| Historical category reconstruction | **NOT ENFORCED** — no required category snapshot contract |
| Author/reviewer display snapshots | **NOT ENFORCED** |
| Source/review metadata preservation | **NOT ENFORCED** |
| Immutable revision records | **PARTIALLY PRESENT** — no authenticated update/delete path, but no dedicated immutable database operation or owner-level protection was verified |
| Restoration creates a new revision | **NOT IMPLEMENTED** |
| Obsolete approvals cannot be reused | **NOT IMPLEMENTED** |

The schema links an article to an optional `published_revision_id`, but does not guarantee that the referenced revision contains the complete published article state or that it belongs to the current approved workflow. No correction, restore, approval-freshness or revision-identity operation exists.

## 6. Non-production environment status

**VERIFIED:** The production project has no development branches.

**UNVERIFIED:** No genuine non-production Scholars Supabase target was established by the available project metadata. The separate `serena` project cannot be classified as staging from its name alone.

**UNVERIFIED:** The evidence reviewed does not prove that the already-applied production migrations were preceded by a documented non-production validation pass.

**RECOMMENDATION:** Before authoring or publishing work, create or designate a disposable isolated Supabase/Postgres target with synthetic identities, articles, categories and revisions. Validate view security options, PostgREST behavior, RLS policies, workflow transitions and regression tests there before any production migration.

## 7. Security-remediation verification

**VERIFIED:** All five functions addressed by the remediation migration have the intended current execution privileges:

| Function | `anon` execute | `authenticated` execute | `service_role` execute |
|---|---:|---:|---:|
| `claim_notification_delivery(uuid,timestamptz)` | No | No | Yes |
| `claim_workflow_job(text,timestamptz)` | No | No | Yes |
| `complete_workflow_job(uuid,boolean,jsonb,jsonb,timestamptz)` | No | No | Yes |
| `flag_expired_opportunities()` | No | No | Yes |
| `seed_scholarship_prompts()` | No | No | Yes |

All five are `SECURITY DEFINER` functions owned by `postgres`.

**VERIFIED:** The live `pg_default_acl` catalog contains narrow defaults for objects created by `postgres`, but also broad defaults for objects created by `supabase_admin`:

- `supabase_admin` default functions: `anon` and `authenticated` have EXECUTE.
- `supabase_admin` default tables: `anon` and `authenticated` have broad table privileges.
- `supabase_admin` default sequences: `anon` and `authenticated` have broad sequence privileges.

**CONCLUSION:** The five function ACL corrections are verified. The broader default-privilege correction is incomplete or at least not universal across object-creation roles. The owner must determine which roles can create production objects and explicitly remediate or constrain every relevant role before calling the default-privilege boundary complete.

## 8. Remaining SECURITY DEFINER findings

**VERIFIED:** The following remaining public-schema `SECURITY DEFINER` functions still allow `anon` and/or `authenticated` execution:

- Trigger/achievement functions: `check_achievements`, `check_application_submitted`, `check_community_discussion_achievements`, `check_community_reaction_achievements`, `check_first_action_achievements`, `check_referral_completion`, `notify_discussion_helpful`, `notify_discussion_reply`, `run_achievement_checks`, `sync_scholarship_discussion_helpful_count`, `sync_waec_summary_fields`.
- Admin or analytics reads: `get_admin_metrics_summary`, `get_auth_confirmation_email_analytics`, `get_daily_visitor_metrics`, `get_provider_analytics`.
- Public/community reads: `get_community_contributor_profile`, `get_public_contributor_profile`, `get_scholarship_discussions`, `get_scholarship_social_proof`, `get_trending_scholarship_ids`.
- Administrative mutation: `publish_discovery_candidate`.
- Role/helper function: `is_admin`.

`award_xp`, `check_rate_limit` and `record_visitor_page_view` were observed as restricted from `anon` and `authenticated`.

These findings are not all equivalent vulnerabilities. Some functions are intentionally public reads or trigger functions, while others are sensitive analytics or mutations. Each requires call-site, parameter-bound, output-projection and trigger-dependency review before any grant change.

## 9. Sitemap and SEO findings

### 9.1 Current source behavior

**VERIFIED:** `app/sitemap.ts` statically includes the site root, informational pages, reviews, scholarship discovery pages and opportunity discovery pages. It does **not** include `/resources` in `STATIC_PATHS`.

**VERIFIED:** Resource sitemap generation reads `resource_public_articles` and emits article URLs only. Because the public article view currently has zero rows, no Resource Center article URL is currently emitted.

**VERIFIED:** Active public category URLs are not read or emitted by `app/sitemap.ts` or `lib/sitemap-data.ts`.

**VERIFIED:** Resource route metadata is present:

- `/resources` has canonical `/resources`.
- `/resources/[slug]` derives canonical metadata from `canonical_url` or the article URL and uses Article JSON-LD.
- `/resources/category/[slug]` derives canonical metadata from the category slug and returns `notFound()` for missing categories.

**INFERENCE:** The live sitemap endpoint can return HTTP 200 while still omitting the Resource Center index and category surfaces. This is an SEO completeness gap, not an availability failure.

### 9.2 Smallest additive correction

**RECOMMENDATION:**

1. Add `${base}/resources` as a static sitemap entry.
2. Add active category rows to the sitemap from `resource_public_categories`.
3. Decide whether empty categories should be included. The safer indexation policy is to include only categories associated with at least one published article, or to keep category pages out until they contain content.
4. Continue deriving article URLs from the published-only projection view.

No source change was made during this investigation.

## 10. Outstanding owner decisions

1. Approve either the exact `security_invoker=true` architecture or the owner-executed explicit-projection architecture as a deliberate alternative.
2. Decide which database roles can create production objects and remediate broad `supabase_admin` default privileges.
3. Confirm or create a real non-production Supabase/Postgres target.
4. Approve the database-enforced editorial workflow boundary before enabling authoring.
5. Define the complete canonical revision snapshot contract and restoration semantics.
6. Define reviewer separation, approval freshness, scheduled publication and MFA/AAL2 requirements.
7. Decide whether `/resources` and active/occupied categories should be included in the sitemap.
8. Review the remaining SECURITY DEFINER functions independently; do not revoke grants without trigger and route regression tests.

## 11. Recommended next implementation phase

Do not add authoring or publishing to the current broad admin table-write path. After owner approval and non-production setup, implement in this order:

1. Resolve and test the public-view security model.
2. Add public sitemap index/category coverage.
3. Add editorial identity and category management with explicit capability checks.
4. Add draft editing with constrained RLS writes.
5. Add immutable complete revision snapshots and revision-number allocation.
6. Add guarded submit, return, approve, schedule, publish, archive and correction operations.
7. Enforce reviewer separation, revision identity, approval freshness, schedule validation and MFA/AAL2 where required.
8. Add public revalidation only after a successful guarded publication transition.
9. Add regression tests for public projection columns, draft leakage, direct admin status changes, obsolete approvals, revision restoration and PostgREST access.

## 12. Explicit implementation-readiness classification

**CLASSIFICATION: C. BLOCKED BY SECURITY AND WORKFLOW GAPS.**

The public foundation is deployed and has no current Resource Center rows. The five targeted worker-function grants are corrected. The system is not ready for Resource Center authoring, review, scheduling, publishing, archiving or correction until the view security model, default-privilege scope, non-production validation, revision contract, guarded transitions and sitemap completeness are resolved or explicitly accepted by the owner.

No implementation or production mutation was performed. Wait for explicit owner approval before proceeding.
