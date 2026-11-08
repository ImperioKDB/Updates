# Scholars Resource Center — Phase A0.3 Migration and Schema Reconstruction Assessment

**Assessment date:** 2026-11-08 continuation of the 2026-11-07 audit  
**Repository:** `ImperioKDB/Scholars`  
**Pinned source commit:** `41573f5ec2985851ba118e8b39a47f9c54532302`  
**Reference branch:** `main`  
**Review mode:** strictly read-only static migration and schema reconstruction audit

## 1. Final assessment

**Recommendation: CONDITIONALLY READY FOR DEPENDENCY MAPPING; NOT READY FOR A SAFE CLEAN-LOCAL BASELINE.**

The migration history can now be mapped through the final Resource Center migrations without executing SQL, starting Supabase, accessing production, or modifying the Scholars source. The continuation review completed ordinals 92–129 and retried the previously failed `0035_add_retention_events.sql`, producing 39 new review artifacts.

The audit does not establish that the complete historical migration chain can be replayed safely into a fresh local Supabase project. The clean-local-baseline question remains blocked by the superseded `0001_init.sql`, incomplete authoritative schema provenance, unresolved `public.is_admin(uuid)` implementation and privilege assumptions, evolved `profiles` requirements, migration ordering/duplicate-prefix issues, and ownership/default-privilege assumptions.

The Resource Center migrations themselves are structurally understandable and can be mapped. They should not be executed blindly or treated as independently sufficient to construct the Scholars application schema.

## 2. Scope and safety boundary

This assessment is based on the pinned source snapshot and static SQL inspection only. No SQL was executed. No migration, seed, hosted database, Supabase project, `serena` project, PostgREST endpoint, local Supabase stack, or production credential was accessed. The source snapshot remained clean.

The audit did not:

- run `supabase link` or any hosted database command;
- start another Supabase stack;
- execute migrations or seed files;
- load production `.env` files, database URLs, JWT secrets, or API keys;
- modify Scholars source files or migrations;
- implement remediation, CMS/editorial work, deployment, merge, or push to Scholars.

Real-data seed migrations were reviewed as text only. Their embedded URLs, emails, dates, scholarship records, opportunity records, and research claims were not independently fetched or submitted.

## 3. Review coverage

The prior continuation checkpoint recorded 91 of 129 SQL migrations as successfully reviewed. Per instruction, those 91 were not re-reviewed in this continuation. This phase reviewed the remaining range from ordinal 92 through ordinal 129 and retried the previously failed migration review.

| Review set | Coverage | Result |
|---|---:|---|
| Prior checkpoint | Ordinals 1–91 | Carried forward; not re-reviewed |
| Continuation batch 1 | Ordinals 92–101 | 10 completed |
| Continuation batch 2 | Ordinals 102–111 | 10 completed |
| Continuation batch 3 | Ordinals 112–121 | 10 completed |
| Continuation batch 4 | Ordinals 122–129 | 8 completed |
| Failed-review retry | `0035_add_retention_events.sql` | 1 completed |
| **New review artifacts** | **38 ordinals + 1 retry** | **39 completed** |

The review files were written under `/tmp/scholars-a03-reviews/` as `092-migration.md` through `129-migration.md`, plus `0035-retention-events-retry.md`.

## 4. Migration inventory and broad patterns

The final continuation range contains four broad classes of migration:

1. **Real-data seeds and seed refreshes.** Most files from ordinals 93–94, 99, 101–103, 105–111, 115–118, and 120–122, 124–127 insert or update real-looking scholarship and opportunity records. They may be omitted from a schema-only synthetic reconstruction, but they are not safe to execute blindly against a data-bearing database without verifying tables, constraints, RLS, permissions, freshness, and duplicate behavior.

2. **Feature schema and behavior migrations.** Web Push, visitor analytics, prompt-action state, WhatsApp consent, opportunity applications, and confirmation-email analytics add tables, columns, triggers, constraints, indexes, policies, RPCs, or privileges. These are not equivalent to seed data and must be retained when the related application behavior is in scope.

3. **Security and privilege migrations.** The security-boundary remediation narrows five exact RPC ACLs and future default privileges. It does not create the functions or inspect their bodies, ownership, `SECURITY DEFINER` settings, search paths, or downstream table privileges.

4. **Resource Center schema migration.** The final Resource Center file creates the editorial, category, article, join, and revision schema, RLS, grants/revokes, admin policies, and four public projection views. It contains no seed DML and depends on pre-existing Auth and admin-function infrastructure.

## 5. Ordinals 92–129: review summary

### Ordinal 92 — `0075_flag_expired_opportunities.sql`

Adds an enum value, a deadline flag timestamp, a partial index, and a `SECURITY DEFINER` function that updates expired verified opportunities and inserts deduplicated admin notifications. It narrows function execution to `service_role`. It contains no static seed data or external calls, but runtime invocation performs DML and depends on opportunity, notification, profile, enum, role, and function-owner state. **Classification: PARTIALLY VERIFIED; conditionally omittable only when expiry processing is out of scope.**

### Ordinals 93–94 — scholarship and opportunity seeds

`0076_seed_prince_ukeme_ukpong_scholarship_2026.sql` conditionally inserts one scholarship and three rules. `0077_seed_verified_user_supplied_scholarships_and_mentorship_2026.sql` conditionally inserts scholarship, rules, and mentorship opportunity data. Both are DML-only real-data seeds with external URLs stored as text and no direct network calls. **They are omittable from a schema-only reconstruction but not safe to execute without the full schema and permissions.**

### Ordinals 95–98 — Web Push, analytics, notification channel, prompt state

`0078_add_web_push_subscriptions.sql` creates a Web Push subscription table, index, RLS, grants, and owner-scoped policies. `0078_scope_provider_analytics_to_reporting_window.sql` replaces a `SECURITY DEFINER` analytics function and changes execute privileges. `0079_enable_push_channel_for_notification_outbox.sql` replaces a notification channel check constraint to include `push`. `0080_add_prompt_action_state.sql` adds two profile timestamps and a column-scoped authenticated update grant. These migrations have no seed DML or external calls, but depend on the evolved profile, event, notification, analytics, and role/RLS state. **They must be retained for feature/security fidelity and may be omitted only from an intentionally reduced reconstruction.**

### Ordinals 99–103 — additional catalog seeds and visitor metrics

`0081_seed_fajim_scholarship_2026_2027.sql`, `0083_seed_helwa_npw_and_wva_2026.sql`, `0084_seed_nddc_local_postgraduate_scholarship_2026_2027.sql`, and `0085_seed_verified_user_requested_scholarships_2026.sql` are real-data scholarship/opportunity seed or refresh migrations. `0082_harden_provider_analytics.sql` replaces the provider analytics function and restricts execution to authenticated users. `0086_add_daily_visitor_metrics.sql` is materially different: it creates a daily visitor metrics table, enables RLS, changes privileges, backfills aggregate data from `public.events`, and creates security-definer RPCs. The seed files are generally omittable from a synthetic schema; the metrics migration is omittable only if visitor analytics and its RPC behavior are outside scope.

### Ordinals 104–111 — catalog seeds

`0087_seed_oyo_state_2025_2026_bursary.sql`, `0087_seed_taiwo_bankole_scholarship_2026.sql`, `0088_seed_sande_poetry_prize_2026.sql`, `0089_seed_yale_yyas_2027.sql`, `0090_seed_au_theme_2027_logo_competition.sql`, `0091_seed_kawef_scholarship_2026.sql`, and `0092_seed_verified_user_requested_opportunities_2026.sql` are DML-only real-data seeds or conditional upserts. They depend on the mature `scholarships`, `scholarship_rules`, and `opportunities` schemas and may contain time-sensitive deadlines, external URLs, email/contact information, and verification notes. **They should be excluded from a synthetic schema baseline and retained only as separately governed fixtures if needed.**

### Ordinals 112–114 — WhatsApp consent security chain

`0093_add_whatsapp_community_invitation_consent.sql` adds four profile consent columns and a check constraint. `0094_guard_community_invitation_consent.sql` creates a trigger function and revokes direct execution so non-service-role callers cannot alter protected consent fields. `0095_revoke_invitation_consent_on_number_change.sql` defines a trigger function that clears consent when a WhatsApp number changes, but the file itself does not attach the trigger. These files contain no seed data or external calls. **They must be retained for consent-feature and security fidelity; omission is safe only if the feature is intentionally excluded and all related references are removed.**

### Ordinals 115–118 — catalog seeds

`0096_seed_lca_scholarship_2026.sql`, `0097_seed_verified_tech_opportunities_2026.sql`, `0098_seed_verified_user_supplied_opportunities_2026.sql`, and `0099_seed_user_verified_tpac_kapp_snepco_2026.sql` perform conditional inserts or updates against the mature catalog tables. They contain real-world content and external URLs but no DDL or privilege changes. **They are omittable from schema reconstruction and unsafe to execute without the complete catalog schema and data-policy review.**

### Ordinal 119 — `0100_support_opportunity_applications.sql`

Makes `applications.scholarship_id` nullable, adds a check requiring exactly one of scholarship or opportunity IDs, and creates a partial unique index on `(profile_id, opportunity_id)`. It is DDL-only and has no external or real-data content. Existing invalid rows or duplicate profile/opportunity pairs can cause application failure. **It is required for faithful opportunity-application behavior and should not be silently omitted when that feature is in scope.**

### Ordinals 120–122 — catalog seeds and WAAW rule repair

`0101_seed_waaw_and_fisayo_soyombo_2026.sql` conditionally inserts or updates scholarship and opportunity rows. `0102_fix_waaw_gender_age_rules.sql` conditionally inserts WAAW rules and intentionally fails if no matching scholarship is found. `0102_seed_tka_solid_foundations_2027.sql` conditionally inserts or updates one scholarship. These contain real, time-sensitive content and external URLs but no DDL. **They are omittable from a schema-only reconstruction and should not be executed as synthetic setup.**

### Ordinal 123 — `0103_add_confirmation_email_analytics.sql`

Creates `auth_confirmation_email_events` with identity, foreign key, check constraints, timestamp, indexes, RLS, an admin-only select policy, and a security-definer JSONB analytics function. It explicitly revokes and grants function execution. It contains no data seed or external call. **Retain when confirmation-email analytics or its security surface is in scope; otherwise it is conditionally omittable.**

### Ordinals 124–127 — final catalog seeds

`0103_seed_scholarshipair_10277_10287_2026.sql`, `0104_seed_dcma_coas_literary_competitions_2027.sql`, `0105_seed_unhcr_kectil_unwomen_wit_2026.sql`, and `0106_seed_airtel_africa_tech_scholarship_nigeria_2026_2027.sql` are conditional real-data inserts or upserts into `scholarships` and/or `opportunities`. They include external URLs, deadlines, application guidance and research notes but perform no HTTP requests. **Exclude from a synthetic schema baseline unless separately sanitized and approved as fixture data.**

## 6. Ordinal 128 — security-boundary remediation

Actual filename:

```text
supabase/migrations/20261107130000_security_boundary_remediation.sql
```

The migration changes ACLs for these exact function signatures:

- `public.claim_notification_delivery(uuid, timestamptz)`
- `public.claim_workflow_job(text, timestamptz)`
- `public.complete_workflow_job(uuid, boolean, jsonb, jsonb, timestamptz)`
- `public.flag_expired_opportunities()`
- `public.seed_scholarship_prompts()`

For each, it revokes all privileges from `PUBLIC`, `anon`, and `authenticated`, then grants `EXECUTE` to `service_role`. It also revokes future default privileges for functions, tables, and sequences created by role `postgres` in schema `public` from `anon` and `authenticated`.

Important limitations:

- The five functions must already exist with exact signatures.
- Function bodies, ownership, search paths, `SECURITY DEFINER` status, and downstream privileges are not changed or verified.
- Default privileges are future-facing and apply only to objects created by `postgres` in `public`; they do not retroactively repair existing ACLs or objects created by other roles.
- Unlisted overloads and creator roles remain outside scope.

**Verdict:** retain for production authorization/default-privilege fidelity; it may be omitted only from a synthetic schema reconstruction that explicitly excludes security behavior.

## 7. Ordinal 129 — Resource Center schema

Actual filename:

```text
supabase/migrations/20261107130100_resource_center_schema.sql
```

The migration creates five base tables:

1. `resource_editorial_identities`
2. `resource_categories`
3. `resource_articles`
4. `resource_article_categories`
5. `resource_revisions`

It creates indexes, constraints, the deferred `resource_articles_published_revision_fk`, enables RLS on all five base tables, revokes `anon`/`authenticated` base-table access, grants service-role and authenticated privileges, and creates six authenticated admin policies. The policies rely on pre-existing `public.is_admin(auth.uid())`.

It creates four `security_barrier` public projection views:

- `resource_public_editorial_identities`
- `resource_public_categories`
- `resource_public_articles`
- `resource_public_article_categories`

The article projections filter for active, published, non-future content and intentionally omit administrative fields such as draft status, scheduling timestamps, creator IDs, reviewer IDs, revision IDs and inactive flags. The migration contains no row DML, seed content, URL fetch, storage operation, trigger, scheduled job, or external service call.

Critical dependencies and uncertainties:

- `auth.users(id)` must exist.
- `gen_random_uuid()` must be available.
- `public.is_admin(uuid)` must exist and be safe in policy evaluation.
- The file does not define `public.is_admin`.
- The views are not explicitly assigned an owner and do not set `security_invoker`; the comments describe owner-based projection behavior, but effective runtime behavior was not verified.
- `create table if not exists` does not reconcile an incompatible pre-existing table definition.
- Several policies and the deferred foreign key are not guarded for partial reruns.
- Publication visibility is time-sensitive because views use `published_at <= now()`.
- Revisions have select/insert admin policies but no authenticated update/delete policy in this file.

**Verdict:** structurally mappable and required for Resource Center functionality, but not independently executable as a complete Scholars baseline. Runtime security behavior remains unverified.

## 8. Retried migration — `0035_add_retention_events.sql`

The retry reviewed the previously failed file:

```text
supabase/migrations/0035_add_retention_events.sql
```

It drops and recreates the `public.events.events_event_whitelist` check constraint with 25 allowed event literals. It contains no DML, grants, revokes, functions, triggers, policies, URLs or external calls.

The migration is not safe to execute blindly because:

- `public.events` and its `event` column must already exist;
- existing event values may violate the replacement whitelist;
- the old constraint definition was not available for comparison;
- the drop/add sequence can leave an intermediate gap if not protected by the runner’s transaction behavior;
- a same-name constraint collision can still cause the add to fail;
- adding the constraint can scan and lock existing data.

For a final-state synthetic schema, the desired final check constraint can be represented directly without replaying the historical drop/add sequence. **Verdict: PARTIALLY VERIFIED.**

## 9. Schema-reconstruction blockers

### 9.1 Superseded initial migration

`0001_init.sql` is explicitly marked superseded and retained for reference only. Its own comments state that it differs from the live project schema and must not be run against the live project. It cannot be accepted as the authoritative clean baseline without a reviewed reconstruction decision.

### 9.2 Authoritative `public.is_admin(uuid)` unresolved

The Resource Center policies depend on `public.is_admin(auth.uid())`, but the Resource Center migration does not create it. The implementation, owner, `SECURITY DEFINER` status, search path, grants, and behavior are not resolved by this audit. This is a hard dependency for both migration application and authorization testing.

### 9.3 Evolved `profiles` and application schema

The surrounding migration history shows a mature and repeatedly evolved application schema. Feature migrations assume columns, privileges, triggers, roles, and policies that are not supplied by the two Resource Center files. A fresh project cannot safely infer those objects from the final Resource Center migration alone.

### 9.4 Ownership and default privileges

The security remediation changes defaults only for future objects created by role `postgres` in schema `public`. It does not prove that production objects were created by `postgres`, nor does it repair objects created by another role or existing broad ACLs. A local reconstruction must explicitly choose and document its role/ownership model.

### 9.5 Duplicate numeric migration prefixes

The migration directory contains repeated numeric prefixes such as `0078`, `0087`, `0102`, and `0103`. The two actual Resource Center filenames are timestamped `20261107130000` and `20261107130100`. Any reconstruction process must use the repository’s actual migration ordering mechanism and must not assume filename prefix uniqueness.

### 9.6 Real-data seed volume

The reviewed history contains numerous real-data seeds with time-sensitive deadlines, external URLs, emails, application instructions and verification notes. These should not be executed merely to construct a synthetic security test environment. They should be excluded or transformed into explicitly approved synthetic fixtures.

## 10. Required dependency map for a future safe local baseline

A future reconstruction phase should establish, in a separate approved local-only bundle:

1. Supabase Auth schemas and local roles.
2. The authoritative `profiles`, `events`, `scholarships`, `scholarship_rules`, `opportunities`, `applications`, notification, analytics and community tables required by the selected application scope.
3. Required extensions and functions, including UUID generation and Auth helpers.
4. A reviewed and safe `public.is_admin(uuid)` implementation with explicit owner, search path and grants.
5. The exact function signatures required by the security-boundary remediation.
6. Role ownership and default-privilege behavior for the local test environment.
7. The Resource Center tables, constraints, RLS, policies and public projections.
8. Synthetic editorial identities, categories, articles, revisions and Auth users only after the schema is known to be safe.

This should be a reviewed local-only migration bundle or schema reconstruction. It should not be created by silently executing the full production-oriented seed history.

## 11. Timestamp discrepancy

The task materials referenced older or incorrect migration timestamps in some places. The actual filenames in the pinned source snapshot are:

```text
supabase/migrations/20261107130000_security_boundary_remediation.sql
supabase/migrations/20261107130100_resource_center_schema.sql
```

These actual filenames must be used in all future reports, dependency maps, migration commands and review references. The timestamp discrepancy is documentation/provenance drift; it does not change the static findings above.

## 12. Runtime verification status

This assessment intentionally performed no runtime verification. In particular, it does not prove:

- that all referenced tables, roles, functions or extensions exist in a fresh local stack;
- that the full migration sequence applies successfully;
- that the five security-remediated functions exist with exact signatures;
- that `public.is_admin` has safe behavior;
- that the public views execute with the intended owner/security semantics;
- that RLS and PostgREST requests produce the intended Resource Center results;
- that production ACLs/default privileges match the SQL assumptions.

The prior A0.2 native-stack validation separately proved that local PostgreSQL, Auth, PostgREST, local JWTs and generic RLS could work in an isolated native stack. It did not apply Scholars migrations and therefore does not close these Resource Center-specific gaps.

## 13. Next-phase recommendation

Do not apply the two Resource Center migrations directly to a fresh local stack yet. The next safe phase should be a read-only/reconstruction decision followed by a separately authorized local-only implementation of a reviewed baseline.

The recommended order is:

1. Resolve the authoritative baseline and `public.is_admin(uuid)` contract.
2. Define the minimum synthetic schema required for Resource Center security tests.
3. Exclude all real-data seed migrations unless transformed into approved synthetic fixtures.
4. Produce a reviewed local-only migration bundle with explicit role/ownership/default-privilege assumptions.
5. Start one disposable native stack only after that bundle is approved.
6. Apply the bundle locally, create synthetic Auth identities and Resource Center fixtures, and run SQL- and HTTP-level tests.
7. Keep production and hosted Supabase out of the dependency-resolution loop.

## 14. Final status

**A0.3 static migration-history and schema-reconstruction audit: COMPLETE for the requested continuation range.**

- Prior 91 reviews: carried forward per instruction; not re-reviewed.
- Ordinals 92–129: reviewed successfully.
- Previously failed `0035_add_retention_events.sql`: retried successfully.
- SQL/migrations executed: none.
- Supabase stack started: none.
- Production/hosted access: none.
- Scholars source modified: no.
- Clean local baseline established: no; blocked by the dependencies and provenance issues documented above.

## References

[1]: https://supabase.com/docs/guides/local-development/docker-and-native-runtimes "Docker and native runtimes"
[2]: https://supabase.com/docs/guides/local-development/running-multiple-local-projects "Running multiple local projects"
[3]: https://supabase.com/docs/guides/local-development/cli/getting-started "Supabase CLI"
