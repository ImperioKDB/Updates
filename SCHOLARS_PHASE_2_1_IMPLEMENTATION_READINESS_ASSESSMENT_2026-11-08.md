# Scholars Phase 2.1 — Implementation Readiness Assessment

**Assessment date:** 2026-11-08
**Reviewed application revision:** `ImperioKDB/Scholars` `main` at `cf3682ce35912df7b9b9352193630fc404427c7c`
**Supabase project:** `scholarship-platform` (`cmdglabohpttgfofcmqc`, `eu-west-1`)
**Phase 2 reference commit:** `ImperioKDB/Updates` `187209aa0bca66ef8eb373657fc7534912e02887`
**Assessment:** The Phase 2.1 **design package is ready for founder/editorial and security review; production implementation is not ready and is blocked**.
**Change status:** Documentation only; no application, database, permission, configuration, provider, or deployment change was made.

## 1. Executive decision

Do **not** begin a production migration, public-route cutover, reminder change, or private-evidence rollout yet. The technical design now defines the seven independent editorial dimensions, six central output categories, one decision envelope for every consuming surface, route acceptance/freshness rules, a retention/security policy, and an additive schema/rollout approach. It also resolves the major factual unknowns about the live `opportunities` table by reading the production migration ledger and live catalog metadata.

A critical least-privilege concern was identified in read-only metadata: `anon` and `authenticated` have broad table privileges including `TRUNCATE` on multiple catalogue, personal-history, and discovery/evidence tables, and the `supabase_admin` public-table default ACL also grants browser roles broad table privileges. RLS policy metadata is present, but RLS is not a substitute for those grants and does not row-filter `TRUNCATE`. No unauthorized REST request or destructive probe was run, so this is a confirmed privilege/configuration finding—not a demonstrated public exploit path. It must be separately assessed by the security owner before adding the new evidence system.

## 2. Readiness scorecard

| Workstream | Status | Evidence / outstanding work |
|---|---|---|
| Seven-dimension vocabulary and exact-cycle model | Ready for review | Phase 1.3.1 remains controlling; the design separates authenticity, audience, level, status, route, freshness, and editorial disposition. |
| One authoritative policy output | Specified; approval pending | Pure shared evaluator and capability envelope are defined; A-03/A-04 and reviewer/visibility decisions are not approved. |
| Worked Phase 1.3.1 examples | Reviewed | ASUU, Bode Amao, Decagon Foundation/Institute, JG Afrika, PAU/Mastercard, NDDC, PTDF, plus one explicitly synthetic positive-open-cycle fixture; the separate no-route case is only a negative route test. NDDC lifecycle and PAU route/status classification are explicitly kept separate. |
| Route acceptance evidence | Specified; A-03 pending | Exact-cycle provider-open evidence, route provenance, access observation, and acceptance proof are separate; no submission/CAPTCHA test. |
| Freshness intervals | Proposed; A-04 pending | Risk-tiered maximum ages and fail-closed stale behavior are in the route matrix. |
| Production catalogue/DML data | Not inspected or changed | Read-only metadata only; no scholarship/student rows or private notes were selected. |
| Deployed migration ledger | Partially reconciled | 177 applied entries and version range established; key opportunities history recovered; complete one-to-one source-file mapping and migration executor role remain unknown. |
| Opportunities DDL | Substantially resolved | Exact base creation SQL found in `schema_migrations.statements`; live 21-column table, enum, constraints, indexes, triggers, and policies inspected. Checked-in base DDL file remains absent. |
| Table/column grants and RLS | Critical blocker | Broad direct ACLs and `supabase_admin` default table privileges observed. Route exploitability was intentionally not tested. No permission change is authorized. |
| Generated Supabase types/typegen | Unresolved ownership | No generated `Database` type or `supabase gen types` workflow found; current types are handwritten. |
| Application integration/tests | Design specified, not executed | Route map and tests defined; no build/test, route, or user-facing behavior was run in this read-only design task. |
| Deployment | Not applicable | Only documentation in `ImperioKDB/Updates` is in scope; no Scholars app commit or Vercel deployment was performed. |

## 3. Technical questions T-01–T-11

| ID | Finding / answer | Readiness state |
|---|---|---|
| T-01 — Exact deployed migration history and manual applications | Live `supabase_migrations.schema_migrations` has 177 rows, first `20260821182641`, latest `20261107115403`. The applied opportunities base is version `20260907051428`, name `create_opportunities_and_saved_opportunities`. Key later applied changes include `add_training_opportunity_type` (`20260909070900`), `add_public_catalog_slugs` (`20260914080258`), and `flag_expired_opportunities` (`20261002183653`). Last two entries are `20261107115338/security_boundary_remediation` and `20261107115403/resource_center_schema`; checked-in timestamps differ. Duplicate numeric prefixes and differently named/reference-only SQL prevent a safe assumption that filename order matches production order. | **Partially resolved; blocker before migration.** Complete a 177-row ledger-to-file/statement manifest and verify every migration executor role. |
| T-02 — Actual table/column grants in addition to RLS | `pg_class.relacl` and `has_table_privilege` show `anon` and `authenticated` full table rights including TRUNCATE on multiple tables (including scholarships, rules, opportunities, cycle events, applications, saves, notifications, and discovery candidate/claim/snapshot tables). The `supabase_admin` public default ACL also grants broad browser-role table privileges. Explicit per-column catalog output included only `notifications.read_at UPDATE` for authenticated; it is not a table-wide safeguard. RLS policies exist, but they do not constrain TRUNCATE. Public PostgREST/RPC reachability was not tested. | **Critical blocker.** Security owner must assess request paths and approve any ACL/default remediation separately. No production permission changes/probes performed. |
| T-03 — Code-generated DB types and canonical schema-generation workflow | No generated `Database` TypeScript type, `supabase gen types` command, package script, or typegen CI step was found. `lib/matching/types.ts` and `lib/cycles.ts` contain handwritten types. The canonical type owner and migration workflow are not established. | **Unresolved blocker before new schema code.** Choose a reproducible type-generation and CI contract from the reconciled schema. |
| T-04 — Authoritative deployed `public.opportunities` definition/history | Exact base SQL is preserved in the production ledger statement array. The live catalog supplies the current 21 columns, five enum values, PK/FK/unique constraints, indexes, two triggers, and RLS policies. No base CREATE TABLE file is checked in. Applied updates account for `training`, `slug`, and `deadline_passed_at`; live policies have evolved from the base migration. | **Resolved as a fact; source-control gap remains.** Archive the verified baseline as non-executable history and do not replay its CREATE DDL. |
| T-05 — Cycle-aware saves, applications, discussions, notifications | Existing personal rows link to stable listing IDs rather than cycle IDs; a cycle layer cannot safely reinterpret old rows. | **Design recommendation supplied.** Keep IDs/data; nullable cycle FKs for new writes; preserve unknown old history without assigning a fabricated cycle; add cycle-bound notification keys in a separately authorized implementation. Audit all other foreign-key consumers first. |
| T-06 — Which surfaces must share the predicate | Browse, matching, detail, related items, public APIs, saves, reminders/workers, public pages, sitemap/robots, and admin review all affect visibility/actionability. Existing detail/related and reminders have weaker or different predicates. | **Resolved in design.** All must consume one decision envelope; route-level policy copies are prohibited. No consumer was modified. |
| T-07 — Candidate claims to catalogue evidence promotion | Current discovery candidates/claims are candidate-scoped; published rows do not gain a durable cycle-scoped evidence ledger. Some claim/event writes are not atomic. | **Design direction supplied; implementation mapping remains.** Promote only with explicit source/cycle links and reviewer review; preserve claim history; decision+event write must be atomic. Do not bulk-promote or publish machine verdicts. |
| T-08 — Unknown/unsupported matcher criteria | Existing generic rules can omit missing or unsupported criteria. | **Proposed rule supplied.** Explicitly represent unknown/unverifiable/materiality; unknown hard/material constraint blocks positive actionable match. Maintain a typed supported-field allowlist; preserve current engine behavior in shadow until approved. |
| T-09 — Freshness expiration and reminder suppression owner | Current deadline worker/push paths use listing-level date and do not consistently gate on cycle/opening/closure; external scheduled jobs must also be considered. | **Design direction supplied; owner/operations pending.** Shared evaluator called before queue and send; centralized review-due/lease job, cycle-bound idempotency; do not enable new messaging in this task. Confirm all GitHub/worker schedules and run-as role. |
| T-10 — Public cache/sitemap invalidation | Public pages, metadata, canonical routes, and sitemap use verified rows; exact ISR/CDN behavior and current invalidation hooks were not fully runtime-tested. | **Partial.** Require decision-version cache keys, invalidation on every material event, sitemap refresh and historical/canonical tests; implementation must inspect current Vercel/Next cache behavior before cutover. |
| T-11 — Candidate volume/review SLA | No approved reviewer capacity, per-cycle workload, or SLA was established. | **Pending product/editorial approval.** Pilot volume and review capacity before broad discovery or strict freshness promises; report stale queue age and review backlog. |

## 4. Readiness classification

| Classification | Current status |
|---|---|
| **Ready for implementation after approval** | The design documents define the policy/function contract, route evidence standard, proposed additive entity model, compatibility approach, tests, and rollback gates. They are ready for founder/editorial/security review—not production execution. |
| **Blocked by unresolved technical evidence** | Critical ACL/default-privilege review; complete 177-row migration provenance manifest and migration-owner confirmation; schema/type-generation source of truth; runtime cache/scheduler inventory. |
| **Blocked by founder decisions** | A-01–A-12 are all recommendations only and remain pending. Public scope, restricted-lead visibility, actionable/open standard, freshness, roles, SEO, taxonomy/funding, history, convergence, and attribution cannot be silently chosen. |
| **Deferred to a later phase** | Provider contact, application submission, automatic cycle creation, full catalogue convergence, bulk backfill, `verified`/legacy-field deprecation, production notification cutover, and cleanup/destructive changes. |

## 5. Explicit implementation blockers

### P0 — Least-privilege/security boundary

Resolve the observed direct ACL and default-ACL scope. Determine which migration role created the affected tables, which defaults apply to future migration runs, and which exact PostgREST/RPC operations are exposed. An approved security migration must state exact before/after grants and verify anonymous/authenticated negative paths. This is separate from the present task and requires explicit permission-change authorization.

### P1 — Migration provenance and schema/type source of truth

Reconcile all 177 ledger entries against checked-in SQL, stored statements, checksums/intent, and environment migration owner. The opportunities base DDL is stored only in the live ledger at this checkout. Establish a non-executable production baseline and a reliable forward-only migration workflow. Decide whether generated `Database` types are committed and add a CI drift check. No additive migration should be applied before this work.

### P1 — Product/editorial approvals

Record explicit founder/editorial choices for A-01–A-12, especially catalogue scope, public restricted leads, open/route threshold, freshness intervals, reviewer separation, archive SEO, funding language, legacy-history handling, and public attribution. Until approved, use the restrictive defaults and do not broaden public visibility or actionability.

### P1 — Operational integration

Before cutover, identify every cache, Vercel ISR/revalidation path, matcher cache, public API, cron, notification worker, and external scheduled task. Confirm the evaluator can be called consistently and that a security-safe server data loader exists. Test decision changes under concurrent review and ensure caches/queued reminders cannot outlive a closed or superseded cycle.

### P2 — Review capacity and data readiness

Define a reviewer queue SLA, independent approval route for high-risk claims, evidence deletion owner, retention approval, and manual mapping process. Do not bulk-create cycles from stored `deadline`, `opens_at`, `last_cycle_closed_at`, or `cycle_events` predictions. The 17 Phase 1.3.1 records can be fixtures or manual editorial intake only after separate authorization.

## 6. Risk register

| Risk | Severity | Why it matters | Required control |
|---|---|---|---|
| Browser-role `TRUNCATE`/DML grants and broad `supabase_admin` defaults | Critical | RLS does not filter TRUNCATE; the database privilege surface is wider than row policies suggest. Actual API exposure is untested. | Separate approved security review, direct/default ACL inventory, and non-destructive negative tests. |
| Incomplete migration source mapping | High | A naïve migration replay could duplicate or diverge from the live schema. | Full ledger/file mapping, application-role confirmation, baseline, dry-run and rollback. |
| Legacy `verified` or date treated as current/open | High | False matches, incorrect application CTAs, public misinformation, and missed suppression. | Central exact-cycle evaluator, fail-closed gates, shadow comparisons. |
| Evidence/source excerpt leakage | High | Editorial notes, private evidence, or personal data could reach public APIs/storage. | Private-by-default evidence schema, explicit grants, allowlisted DTO, negative tests. |
| Reminder and cache drift | High | A closed/stale cycle may continue to send notifications or appear current after decision change. | Re-evaluate at send, cycle-bound idempotency, decision revision cache key, invalidation tests. |
| Inaccurate legacy-cycle assignment | High | Saves/applications can be misrepresented as relating to a different year/intake. | Preserve nullable/unassigned history; manual source-backed mapping only. |
| Unknown rule silently omitted | Medium-high | An apparent positive match can ignore a material eligibility condition. | Typed criterion support map, unknown hard-constraint gate, match invariants. |
| Reviewer backlog/freshness SLA infeasible | Medium | Stale records either accumulate or the organization overstates verification. | Pilot workload, measure review latency, adjust approved intervals before mass ingestion. |
| Overly broad catalogue/taxonomy changes | Medium | Postgraduate, international, and fee-paying routes may be presented as undergraduate scholarships. | Separate catalogue scopes, opportunity type, funding, fees, and route identities. |

## 7. Safe next sequence

1. Founder/editorial reviews the six-document package and records A-01–A-12 approval/defer states.
2. Security owner independently triages the ACL/default-privilege finding. Do not make a permission change through this documentation workflow.
3. Complete migration provenance, schema baseline, and migration-role/typegen decisions.
4. Approve the additive data model and retention schedule; design non-production fixtures from Phase 1.3.1 evidence without importing personal data.
5. Implement policy/evaluator tests and the safe server read boundary in a separate authorized app-repository task.
6. Shadow-run decisions against current catalogues and produce row-level diffs. No notification or public behavior changes during shadow mode.
7. Cut over approved surfaces incrementally behind a kill switch, with rollback and deployment checks.

## 8. Evidence and scope limitations

- Supabase work was read-only catalog/ledger/ACL metadata inspection; no scholarship, student, applicant, source-capture, or private research-note rows were selected.
- No public API exploitability test, unauthorized write, form submission, CAPTCHA attempt, or provider contact was performed.
- No application tests/build, Vercel deployment, GitHub application-repository push, schema migration, or production content correction was performed.
- The design package is not legal advice and does not assert a statutory retention period. Proposed retention needs approved privacy/security review.
- This assessment is based on the named repository revision and Supabase project at the inspection time; it does not prove later states.

## 9. Related documents

- [Governance decision refinement](SCHOLARS_PHASE_2_1_GOVERNANCE_DECISION_REFINEMENT_2026-11-08.md)
- [Authoritative publication policy and gates](SCHOLARS_PHASE_2_1_AUTHORITATIVE_PUBLICATION_POLICY_2026-11-08.md)
- [Application-route acceptance matrix and freshness standard](SCHOLARS_PHASE_2_1_ROUTE_ACCEPTANCE_AND_EVIDENCE_FRESHNESS_POLICY_2026-11-08.md)
- [Evidence retention and security policy](SCHOLARS_PHASE_2_1_EVIDENCE_RETENTION_AND_SECURITY_POLICY_2026-11-08.md)
- [Technical specification](SCHOLARS_PHASE_2_1_TECHNICAL_SPECIFICATION_AND_FINAL_ERD_2026-11-08.md)
