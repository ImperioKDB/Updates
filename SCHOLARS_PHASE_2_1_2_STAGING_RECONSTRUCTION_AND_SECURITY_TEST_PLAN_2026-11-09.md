# Scholars Phase 2.1.2 — Staging Reconstruction and Security Test Plan

**Status:** Plan only; no schema deployment, fixture creation, account creation, ACL change, or test mutation was performed.
**Target:** `scholars-staging` / `aqhktriwaglvvrchxmtd`
**Production boundary:** No production test is authorized by this plan.

## Preconditions before any reconstruction

Reconstruction remains blocked until the owner approves a staging-only setup window and confirms that the project contains no resources that must be preserved beyond the inventory already collected. Before execution, capture a metadata-only snapshot of schemas, tables, views, functions, triggers, extensions, storage buckets/policies, API settings, roles, grants, and migration history.

Create a ledger mapping every production migration to a tracked SQL file or an approved replacement. Resolve the missing opportunities creation source, historical `is_admin` restoration files, duplicate prefixes, cycle-events provenance, and the migration execution role. A clean build is not evidence of reproducibility while those gaps remain.

## Reconstruction sequence

### Phase 0 — Freeze and inventory

Record project ID, region, database version, API URL without keys, current schemas, existing tables, platform-managed objects, storage bucket names/policies, and current application environment-variable names. Store no credentials, tokens, or production row values. Establish a reset procedure that cannot target production.

### Phase 1 — Establish the reviewed schema baseline

Use a newly reconciled, ordered, schema-only migration set. Prefer the current application source only after reconciling it to the production ledger. Do not copy production data. Preserve platform-managed schemas and avoid changing them through application migrations.

Create only the application tables, types, indexes, functions, policies, views, triggers, and storage policies required for the synthetic test contract. Keep private/editorial/worker objects in non-exposed schemas where the approved design requires it. Do not deploy the production remediation itself as part of reconstruction.

### Phase 2 — Configure isolated API and auth

Use staging-only URL and publishable key values. Confirm the actual PostgREST exposed-schema list from authoritative project settings. Confirm JWT audience and role switching with fresh synthetic identities. Create no production accounts.

Provision independent test identities:

- Anonymous request context.
- Student A, non-admin.
- Student B, non-admin.
- Researcher/editor, if the approved product model includes one.
- Reviewer.
- Approver/admin.
- Service worker credential, server-side only.

Record identity labels and generated UUIDs in a private test manifest, never passwords or tokens.

### Phase 3 — Seed synthetic fixtures

Use unique marker values such as `PHASE212_PRIVATE_FIXTURE_DO_NOT_RETURN`. Seed:

- One verified public scholarship and one verified opportunity.
- One unverified scholarship and one unpublished Resource Center article.
- Public and private cycle-event fields.
- Student A and B saves, applications, notifications, WAEC rows, and profile fields.
- Discovery candidates, claims, snapshots, review events, and a publication-ready candidate.
- Worker jobs and notification-delivery rows.
- Community posts covering anonymous and consented contributor cases.
- Cohort sizes 0, 1, 4, 5, and 6 for social-proof tests.

Do not seed real names, real email addresses, real application answers, real WAEC data, or production identifiers.

### Phase 4 — Capture before snapshot

Record relation ACLs, effective privileges, column ACLs, RLS/force-RLS flags, policies, owners, sequence privileges, function signatures/security mode/EXECUTE grants, view definitions/options, triggers, default ACLs for every sanctioned creator role, exposed schemas, and storage policies.

### Phase 5 — Execute tests and capture sanitized evidence

Run the tests below with actual PostgREST requests, JWT role contexts, and Next.js route requests. Store endpoint, method, role label, status, response shape, expected result, observed result, test SHA, and cleanup status. Never store JWTs or row payloads containing private fixture values.

## Security test matrix

| Test | Context | Expected result | Evidence required |
|---|---|---|---|
| Anonymous verified scholarship browse | Anonymous | Approved public projection only | 200 response contains allowlisted fields and no research/internal fields |
| Anonymous internal research-note attempt | Anonymous | Denied or projection omits field; no private marker | Status/error and sanitized response keys |
| Anonymous unverified catalogue read | Anonymous | No row | 200 empty or policy denial, depending on approved API contract |
| Student A own save | Student A | Own row visible through approved route | Positive route/RPC result with synthetic ID only |
| Student A reads Student B save | Student A | Denied/empty; no inference | Negative result and no B marker |
| Student A own application | Student A | Own approved columns only | Positive result without unrelated private fields |
| Student A reads/updates Student B application | Student A | Denied; no mutation | Negative response plus before/after metadata check |
| Forged application ownership | Student A | Insert/update with B profile ID rejected | Error and no created/changed row |
| Student catalogue mutation | Student A | Denied | Status/error; no row change |
| Student discovery evidence access | Student A | Denied | No candidate/claim/snapshot fields returned |
| Anonymous/admin RPC boundary | Anonymous and Student A | Admin functions denied before data-bearing work | RPC status/error; no analytics payload |
| Worker function from browser role | Anonymous, Student A, admin JWT | Denied unless explicitly approved | RPC denial and no job state change |
| Resource Center published article | Anonymous | Approved published projection | Allowlisted fields only |
| Unpublished Resource Center article | Anonymous | Empty/denied | No unpublished marker |
| Notification read state | Student A | Own `read_at` can change; other fields/rows cannot | Column-level positive/negative checks |
| WAEC own replacement | Student A | Own replacement succeeds atomically | Returned subjects/grades are synthetic; before/after check |
| WAEC other-profile replacement | Student A targeting B | Denied and no change | Negative result and B fixture unchanged |
| Editorial publication separation | Researcher/reviewer/approver | Researcher cannot self-approve; approver can publish only approved candidate | Audit event metadata and state transition |
| Trigger-only function RPC | Anonymous/student | Not callable through ordinary RPC | Permission/unsupported result; separate trigger event still succeeds |
| Social-proof thresholds | Anonymous | Small cohorts suppressed/rounded per approved policy | Outputs for 0/1/4/5/6 fixture cohorts |
| Trending parameter bounds | Anonymous | Invalid/low/huge threshold and window rejected or bounded | Sanitized status/result shape |
| View owner/RLS semantics | Anonymous/student | Only published/allowlisted rows | Direct underlying private marker never returned |
| Default privileges | Metadata role | New objects default to owner/service only | Before/after ACL snapshot for each creator role |
| Rollback | Staging owner | App behavior returns without broad browser regrant | Migration fingerprint and test rerun |

## Acceptance criteria

The reconstruction is ready for remediation testing only when:

- The staging project ID and environment isolation are confirmed.
- The migration set is reproducible and all gaps are explicitly mapped or approved exceptions.
- Synthetic fixtures and independent role contexts exist.
- Actual exposed schemas are documented.
- Public projections contain only approved fields.
- Student A cannot access or mutate Student B's private state through any tested route or RPC.
- Anonymous and non-admin users cannot execute admin, editorial, or worker capabilities.
- Trigger behavior remains intact while unnecessary browser EXECUTE is removed in the separate remediation phase.
- Default privileges are least-privilege for every sanctioned object creator.
- Every failed or high-risk case blocks promotion.
- Metadata snapshots contain no secrets or private fixture payloads.
- A rollback has been exercised in staging without broad browser grants.

## Rollback and recovery

The plan is additive and data-preserving. If a migration or fixture step fails, stop, retain the project identity, restore only the staging schema state documented in the pre-snapshot, and remove only synthetic fixtures through the approved staging reset procedure. Do not use production as a reset source. Do not run a production down migration. Do not restore broad `anon`/`authenticated` privileges as a generic rollback.

## References

[1]: https://github.com/ImperioKDB/Scholars/commit/cf3682ce35912df7b9b9352193630fc404427c7c "Scholars application baseline"
[2]: https://github.com/ImperioKDB/Updates/commit/7f7eb680562b6e89c0172b5534848f2b576002c0 "Phase 2.1.1 audit handoff"
