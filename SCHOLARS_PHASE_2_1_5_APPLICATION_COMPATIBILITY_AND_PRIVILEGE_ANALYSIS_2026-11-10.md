# Scholars Phase 2.1.5 — Application Compatibility and Privilege Analysis

**Evidence window:** 2026-11-10, 10:25–10:32 CET (UTC+01:00)
**Scope:** Compare the stated application baseline and current repository delta with the Phase 2.1.2 API dependency matrix. No application code, database object, privilege, type file, or deployment was changed.

## Methodology and repository state

The database environments are production `cmdglabohpttgfofcmqc` and staging `aqhktriwaglvvrchxmtd`; only dedicated read-only project, migration, table, and extension inventories were used. The application source comparison used the public GitHub compare API.

The application repository `ImperioKDB/Scholars` was compared at the exact supplied baseline `cf3682ce35912df7b9b9352193630fc404427c7c` and current `main` `3deba708e146ceb2aa6846c4691d58ace93795b2`. The compare is three commits ahead and contains three added migration files only. No application-source path changed in the comparison. The current app `main` commit predates the Phase 2.1.4 report publication, so no later application change was observed at the current head. [1] [2]

The three migration files add later Airtel/Afara application-route, Kayode/NNPC-SNEPCO source-verification, and Airtel eligibility updates. They are current-state changes, not proof that the historical production chain can be reconstructed. The Phase 2.1.3 provenance report remains authoritative for the unresolved historical migration gaps. [2] [3]

The API-object dependency matrix is the compatibility reference. It identifies current direct table and RPC dependencies, execution contexts, and the application behavior that would break under a blanket browser-grant revoke. No production query or sensitive RPC was used to test those paths in this review. [4]

## Compatibility matrix

| Feature and object group | Application dependency and expected privilege boundary | Candidate-capture status | Compatibility risk and required test |
|---|---|---|---|
| Scholarship catalogue and eligibility: `scholarships`, `scholarship_rules`, `cycle_events` | Anonymous/public browse plus authenticated matching; public fields should be allowlisted while internal notes and actor metadata remain private | Not verified in a portable artifact; live catalog names are in prior reports | A blanket SELECT revoke breaks browse, matching, details, and sitemap readers. Test projections, verified-row rules, and internal-field denial with synthetic rows. |
| Opportunity catalogue and saves: `opportunities`, `saved_opportunities` | Public catalogue read plus owner-scoped save operations | Not verified in a portable artifact; the three new migrations concern current scholarship records/eligibility, not new application routes | Test public projection and Student A/Student B save isolation. Preserve required direct reads until replacement routes or projections are tested. |
| Authentication, profile, WAEC: `profiles`, `waec_results`, `replace_waec_results`, `auth.users` trigger | Authenticated self-service; privileged service client remains server-only; the auth trigger is a managed-schema customization | No DDL artifact; trigger and function definitions not re-captured | Test self-target equality, profile ownership, signup trigger, and denial of cross-profile WAEC replacement. Do not include Auth user data. |
| Applications and drafts: `applications` and related RPC/route calls | Owner-scoped reads/writes with admin paths kept server-side | No artifact or generated types | Test own-row access, Student A denial against Student B, forged profile IDs, and private-column boundaries. |
| Notifications and background jobs: `notifications`, `notification_deliveries`, `workflow_jobs`, worker claim/complete functions | Session users may perform only owner-scoped/mark-read actions; worker operations remain service-side | No artifact; worker function bodies/grants not captured | Revoke no browser privilege until all route and worker call sites are replaced and tested; assert worker RPC denial from browser roles. |
| Admin and discovery/editorial: metrics RPCs, candidates/claims/snapshots/review events, `publish_discovery_candidate` | Admin/editorial capabilities must be server-checked and separated from ordinary browser roles | No artifact; sensitive RPCs not invoked | Test researcher/reviewer/approver separation and admin denial before data-bearing work, using synthetic staging identities only. |
| Resource Center: four `resource_public_*` views and editorial tables | Public reads limited to published, allowlisted content; administrative changes remain restricted | Prior catalog inventory records the views; definitions and invoker/definer behavior not captured here | Test unpublished-row denial, field allowlists, view owner semantics, and underlying RLS in isolation. |
| Storage and uploads: `avatars`, `site`, Storage policies | Public reads only for intentionally public assets; authenticated writes must be owner/path constrained | Prior catalog inventory reports two buckets; bucket rows/policies are not represented by generic schema DDL | Test synthetic object paths and policy denials; never copy production file bytes or user objects. |
| TypeScript database contract | Baseline has no generated `Database` type artifact according to the Phase 2.1.3 compatibility review | No approved staging schema exists to generate from | Generate types only after the candidate is reviewed and applied to an authorized isolated target; compare with all application call sites. |

The detailed API dependency matrix notes that broad `REVOKE ALL` from `anon` and `authenticated` would break catalogue browsing, matching, details, saves, applications, notifications, profile/WAEC, community, admin pages, Resource Center, and session-aware server routes. Preserve functionality through an additive migration sequence: create the reviewed projection or route, update every caller, regenerate types, test role behavior, then remove only grants proven unnecessary. [4]

## Privilege and type-generation constraints

Generated TypeScript types are a compatibility aid, not a security proof. They do not prove RLS correctness, function `SECURITY DEFINER` safety, effective ACLs, view execution semantics, or deployed PostgREST settings. The prior type-generation plan calls for generating against the approved staging schema with an explicit schema list and comparing the output in CI. That work cannot proceed while staging has no Scholars tables and PostgREST exposure remains unverified. [5] [6]

The current code uses distinct public, session-aware server, and service-role Supabase clients. Any eventual type integration must preserve those boundaries and must never move service credentials to a browser bundle. The three migrations added after the stated baseline do not change application call sites, so no new application source dependency was found in this compare. [2] [5]

## Evidence classification

**Confirmed in this pass:** current application `main` SHA; three added migration filenames; no changed app-source paths in the exact compare; staging has no tables in the inspected application schemas and no migration entries; no generated types or application deployment were created by this review.

**Inherited from the dependency matrix and prior audit:** feature-to-object relationships, known direct table access, and the expected breakage from blanket revocation. Those remain the planning baseline; they were not re-executed as production API tests.

**Inference:** blanket browser-role revocation would likely break documented application paths; this is a dependency-based risk assessment, not a runtime failure observed in this phase.

**Unverified:** candidate DDL coverage, current per-object grants and policies, full function bodies, route-level RLS behavior, PostgREST schema exposure, and compatibility of a restored schema. No exploitability claim is made.

## Required isolated compatibility suite

After authorized artifact capture and independent review, test a synthetic local/disposable schema first. Then, only with separate approval, test staging using anonymous, Student A, Student B, admin, and worker contexts. Include catalogue projections; cross-user saves and applications; profile/WAEC self-target checks; notification column limits; admin/editorial RPC denial; worker-only functions; Resource Center publication filters; Storage path ownership; and trigger behavior. Record only sanitized status, response shape, and synthetic identifiers. Do not use production rows or run sensitive production RPCs.

## Security implications, limitations, and unresolved questions

The primary risk is changing privileges without understanding all direct-client and server-side call paths. Do not blanket-revoke browser grants, invoke sensitive production RPCs, move service credentials to client code, or infer RLS behavior from type generation. Candidate object definitions and per-object grants were not captured; actual PostgREST exposure, function-body safety, destination defaults, and type compatibility remain unresolved. The matrix above is a test plan derived from prior dependency evidence, not a claim that a current-state schema artifact has been validated.

## References

[1]: https://github.com/ImperioKDB/Scholars/commit/3deba708e146ceb2aa6846c4691d58ace93795b2 "Scholars Current Main Commit"
[2]: https://github.com/ImperioKDB/Scholars/compare/cf3682ce35912df7b9b9352193630fc404427c7c...3deba708e146ceb2aa6846c4691d58ace93795b2 "Scholars Baseline-to-Main Compare"
[3]: https://github.com/ImperioKDB/Updates/blob/3d3da285f1b076fbfebb1fdf1adbaadeb178d71f/SCHOLARS_PHASE_2_1_3_MIGRATION_PROVENANCE_RECONCILIATION_2026-11-09.md "Phase 2.1.3 Migration Provenance Reconciliation"
[4]: https://github.com/ImperioKDB/Updates/blob/3d3da285f1b076fbfebb1fdf1adbaadeb178d71f/SCHOLARS_PHASE_2_1_2_API_OBJECT_AND_APPLICATION_DEPENDENCY_MATRIX_2026-11-09.md "Phase 2.1.2 API Object and Application Dependency Matrix"
[5]: https://github.com/ImperioKDB/Updates/blob/3d3da285f1b076fbfebb1fdf1adbaadeb178d71f/SCHOLARS_PHASE_2_1_3_APPLICATION_BASELINE_COMPATIBILITY_AUDIT_2026-11-09.md "Phase 2.1.3 Application Compatibility Audit"
[6]: https://github.com/ImperioKDB/Updates/blob/3d3da285f1b076fbfebb1fdf1adbaadeb178d71f/SCHOLARS_PHASE_2_1_4_DATABASE_TYPE_GENERATION_AND_COMPATIBILITY_PLAN_2026-11-09.md "Phase 2.1.4 Database Type Generation Plan"
