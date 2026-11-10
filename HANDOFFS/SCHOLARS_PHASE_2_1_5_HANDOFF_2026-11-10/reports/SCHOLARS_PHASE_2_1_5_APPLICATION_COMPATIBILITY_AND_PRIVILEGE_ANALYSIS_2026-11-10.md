# Scholars Phase 2.1.5 — Application Compatibility and Privilege Analysis

**Investigation date:** 2026-11-10
**Scope:** Compare the current production catalog and repository state with the Phase 2.1.2 application dependency matrix. This is a compatibility assessment, not authorization to change privileges or deploy.

## Application and environment evidence

Production `cmdglabohpttgfofcmqc` and staging `aqhktriwaglvvrchxmtd` are healthy. Production contains 180 migration-ledger rows. Staging has no Scholars application relations and is therefore a clean destination in structural terms, but not yet a safe restoration target. The current application main SHA is `3deba708e146ceb2aa6846c4691d58ace93795b2`; the stated baseline is `cf3682ce35912df7b9b9352193630fc404427c7c`. Three migration files were added after the baseline.

## Feature compatibility matrix

| Feature | Representative objects | Required access model | Catalog evidence | Candidate-baseline status | Open issue |
|---|---|---|---|---|---|
| Authentication and profiles | `auth.users`, `profiles`, `handle_new_user()` | Auth trigger; own-row profile RLS; admin-only role changes | Confirmed | Structurally represented in live catalog | Function body and auth-managed replay need review |
| Scholarship browsing | `scholarships`, `scholarship_rules`, public filters | Public read for verified content; admin writes | Confirmed | Candidate-compatible in principle | Policy OR-combination and view/API exposure need test |
| Opportunity browsing | `opportunities` | Verified public read; admin mutation | Confirmed | Candidate-compatible in principle | Browser ACLs are broad; retain RLS behavior |
| Eligibility matching | WAEC/profile/rule objects and RPCs | Own-row access plus controlled computation | Confirmed catalog objects | Requires artifact/type verification | Privileged function bodies not captured |
| Saved opportunities | `saved_opportunities`, `saved_scholarships` | Own-row CRUD; admin visibility where present | Confirmed | Candidate-compatible in principle | Verify policy combinations and indexes |
| Applications | `applications` | Own-row CRUD; admin read; achievement triggers | Confirmed | Candidate-compatible in principle | Application route migrations changed after stated baseline |
| Notifications | `notifications`, delivery tables, claim RPCs | Own-row reads; worker/service claims | Confirmed | Candidate-compatible in principle | Worker grants and function bodies require review |
| Admin operations | `is_admin`, admin policies, metrics RPCs | Authenticated admin predicate; narrow RPC access | Confirmed but sensitive | Not approval-ready | Browser EXECUTE grants on privileged RPCs |
| Discovery | Candidate, verification, review, source tables | Admin/reviewer access; worker paths | Confirmed | Candidate-compatible in principle | Need generated types and function review |
| Resource Center | Four `resource_*` views and editorial tables | Public read views; admin editorial writes | Confirmed | Candidate-compatible in principle | Verify security-invoker behavior and API config |
| Background jobs | `workflow_jobs`, notification claims, cron-facing functions | Service/worker only | Confirmed | Requires controlled executor | Do not copy job state or grant browser execution |
| Storage/assets | `avatars`, `site`, `storage.objects` policies | Public reads; owner/admin writes | Confirmed | Separate managed-schema process | Bucket rows and files are not generic schema data |
| Realtime discussions | `scholarship_discussions` publication membership | Realtime publication plus RLS | Confirmed | Requires publication replay review | Publication membership must be captured explicitly |

## Privilege conclusions

The application depends on more than tables: it depends on triggers, RPCs, default privileges, storage policies, publication membership, and managed-schema hooks. Blanket browser-role revocation would likely break public browsing, own-row workflows, and resource delivery. The appropriate next step is object-specific review and test evidence, not indiscriminate hardening.

The most important compatibility risk is executor context. Production's `postgres` public defaults are narrower than staging's `postgres` public defaults. If a baseline is restored under a different executor, new tables/functions/sequences may receive different browser grants. The baseline must therefore carry an explicit ACL overlay and restoration-role plan.

## Current application delta

Three current-main migrations were not present at the stated baseline:

- `20261109130500_correct_airtel_afara_application_route.sql`
- `20261109131500_reverify_kayode_and_nnpc_snepco_sources.sql`
- `20261109132500_update_airtel_scholarship_eligibility.sql`

These are current application changes and should be included only if the chosen baseline targets current production state. They must not be misrepresented as historical recovery evidence.

## Capture and type-generation requirements

After an independently reviewed baseline artifact exists, generate database types from the approved destination and compare them against the committed application contract. Required checks include table/view names, nullable columns, enum/status types, RPC signatures, and resource/public view fields. No type generation was run in this phase because staging was intentionally not modified and no baseline was restored.

## Unresolved compatibility questions

1. What exact schemas are exposed through PostgREST?
2. Which browser EXECUTE grants are required by current routes versus legacy artifacts?
3. Are all function bodies safe under a controlled `search_path`?
4. Does the chosen artifact preserve publication membership and security-barrier/invoker view options?
5. Do generated types from the reviewed destination match the current application after the three post-baseline migration changes?

## Conclusion

The live catalog supports the major application feature families, but the absence of a captured artifact and staging type-generation result prevents a final compatibility sign-off. The next phase should build a synthetic, isolated candidate baseline and run application/RLS/API compatibility tests before any staging restoration.

## References

- [Phase 2.1.2 API object and application dependency matrix](https://github.com/ImperioKDB/Updates/blob/main/SCHOLARS_PHASE_2_1_2_API_OBJECT_AND_APPLICATION_DEPENDENCY_MATRIX_2026-11-09.md)
- [Supabase generated types](https://supabase.com/docs/guides/api/rest/generating-types)
- [Supabase database migrations](https://supabase.com/docs/guides/deployment/database-migrations)
