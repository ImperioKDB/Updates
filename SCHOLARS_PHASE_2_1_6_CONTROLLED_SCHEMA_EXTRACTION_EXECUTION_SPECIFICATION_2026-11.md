# Scholars Phase 2.1.6 — Controlled Schema Extraction Execution Specification

**Status:** NO-GO — documentation-only specification; extraction is not authorized.
**Prepared:** 2026-11-10
**Documentation repository:** `ImperioKDB/Updates`
**Application repository:** `ImperioKDB/Scholars`
**Private workflow repository:** `ImperioKDB/scholars-schema-extraction`

## 1. Executive summary

The current decision is **NO-GO / BLOCKED — AUTHORIZED CAPTURE NOT AVAILABLE**. No production schema extraction, database query, staging restore, workflow run, secret operation, or deployment may begin under this specification. The existing evidence does not demonstrate a production connection that is both unable to write and unable to read application rows, does not establish exact endpoint identity and TLS verification, and does not provide actual dump or declarative artifacts for coverage review.

The future candidate approach is conditional: use a Supabase CLI pg-delta declarative tree with strict coverage as the primary human-review artifact, and compare it with an independent default schema-only SQL dump. This is not a complete backup and is not a recovered historical migration chain. Auth/Storage customizations, bucket configuration, extensions, roles, PostgREST settings, provider configuration, and other excluded or unsupported objects require separate evidence and review.

The private extraction repository already has the required HOLD notice in `README.md` at commit `40e36dbf9e0d2921433694d5a63c0a10ecdef295`. It states that `SUPABASE_DB_URL` must not be created or populated and that the workflow must not be run. No README correction is required, and the workflow YAML is intentionally unchanged.

## 2. Evidence basis and labels

This specification reconciles, without repeating, the six Phase 2.1.5 reports in the Phase 2.1.6 handoff package, the eight Phase 2.1.6 reports, and the earlier reports listed below. Evidence is classified as follows:

- **Confirmed / inherited:** directly stated in an identified prior report and carried forward without re-running the underlying investigation.
- **Current repository fact:** observed while preparing this documentation change.
- **Inference:** a reasoned implication that is not a runtime proof.
- **Unverified:** not established by the cited evidence.
- **Blocked:** must not proceed until the listed prerequisite is met.

Primary sources reconciled:

- `HANDOFFS/SCHOLARS_PHASE_2_1_6_CONTINUATION_2026-11-10/reports/` — six Phase 2.1.5 and eight Phase 2.1.6 reports.
- `SCHOLARS_A0_8_2_EXTRACTION_WORKFLOW_SECURITY_REFINEMENT_2026-11.md`.
- `SCHOLARS_A0_8_1_PRIVATE_SCHEMA_EXTRACTION_WORKFLOW_SETUP_2026-11.md`.
- `SCHOLARS_ADMIN_AUTHORIZATION_STAGING_IMPLEMENTATION_AND_VALIDATION_2026-11.md`.
- `SCHOLARS_ADMIN_AUTHORIZATION_SECURITY_REMEDIATION_SPECIFICATION_A0_6_2026-11-08.md` — the exact available A0.6 filename; the shorter filename variant in the task brief is not present.
- `SCHOLARS_RESOURCE_CENTER_PHASE_A0_5_TARGETED_BACKEND_DEPENDENCY_VERIFICATION_2026-11-08.md`.

No cited report is treated as a newly verified production observation in this task.

## 3. Environment references and current blockers

| Environment | Reference | Evidence status | Current decision |
|---|---|---|---|
| Production | `cmdglabohpttgfofcmqc` / `scholarship-platform` / `eu-west-1` / PostgreSQL 17.6.1.155 | Confirmed/inherited from Phase 2.1.5–2.1.6 reports and earlier read-only reviews | Do not connect or extract |
| Staging | `aqhktriwaglvvrchxmtd` / `scholars-staging` / `eu-west-1` / PostgreSQL 17.11.0.018 | Confirmed/inherited; empty application migration/table inventory in inspected schemas | Do not restore or use as a workaround |
| Private workflow repository | `ImperioKDB/scholars-schema-extraction`, private, `main` | Current repository metadata and README inspected; current commit `40e36dbf9e0d2921433694d5a63c0a10ecdef295` | HOLD; workflow not run |

Existing reconstruction blockers are:

1. No approved, demonstrably non-writing production database connection exists.
2. No evidence demonstrates that the extraction identity cannot read application rows directly or indirectly.
3. The workflow’s project-reference substring check is not endpoint or identity verification.
4. TLS server identity verification and the exact approved endpoint tuple are not established.
5. No actual SQL dump, declarative tree, warnings, hashes, or cross-method comparison exists.
6. Supabase-managed schemas, bucket records/configuration, extension-owned objects, roles, PostgREST settings, and project configuration are not covered by a generic schema snapshot.
7. No isolated PostgreSQL/Supabase runtime exists for restore and synthetic compatibility tests.
8. Existing staging is not authorized for reconstruction or testing.
9. The earlier source-derived staging attempt remains blocked because the Scholars migration chain lacks a proven clean-install baseline; `0001_init.sql` is explicitly superseded and the live helper/dependency state is not fully represented by source migrations.

## 4. Mandatory gate register

| Gate | Requirement | Existing evidence | Remaining work | Status |
|---|---|---|---|---|
| A — Production write prevention | The connected source must be demonstrably unable to modify production. Schema-only command semantics are not sufficient. | A0.8.2 found that the current workflow and secret do not enforce a read-only database identity. A read replica is a possible provider-enforced control but has not been selected or tested. | Select an approved provider-enforced read-only source, or independently prove effective `NOSUPERUSER`, `NOCREATEDB`, `NOCREATEROLE`, `NOBYPASSRLS`, no privileged memberships, no ownership, no `CREATE`, no write grants, and no write-capable indirect paths. Test the exact CLI/role combination outside production. | **BLOCKED** |
| B — Application-row access prevention | The extraction identity must not read application records, directly or through views, functions, foreign data, or other paths. | A0.8.2 distinguishes catalog visibility from table `SELECT`; no production role/grant audit or indirect-path review was completed. | Prove the minimum catalog/schema privileges required by CLI 2.122.1 in a disposable environment. Confirm no table-like `SELECT`, no data-bearing executable path, and no managed-schema row access. Never weaken production RLS or grant broad table access to make extraction work. | **BLOCKED** |
| C — Endpoint and identity verification | Verify the exact source before connection and require TLS server identity verification. | The current workflow checks whether the secret contains the project reference. Reports state this is not sufficient. | Validate the complete approved tuple: source mode, host, port, database, username, and intended project/replica. Use certificate/hostname verification, preferably `sslmode=verify-full` with the approved CA. Never print or log the URI or secret. | **BLOCKED** |
| D — Extraction coverage | Inspect actual output and warnings from both proposed methods. | CLI 2.122.1 help was checked only. No extraction ran. Managed schemas and bucket data are known limitations of the default dump; pg-delta coverage is unverified. | Generate private strict-coverage declarative output and independent default schema-only dump only after Gates A–C pass. Reconcile object classes, exclusions, warnings, ACLs, defaults, managed-schema customizations, extensions, publications, and storage configuration. | **BLOCKED** |
| E — Artifact confidentiality | Raw artifacts must remain private, access-controlled, short-lived, and out of public Git. | The extraction repository is private; workflow artifact retention is configured for one day; actual reader/collaborator access was not independently inventoried. | Confirm owner/trusted-reader access, retain only as long as necessary, delete after review, and publish only sanitized inventories. Do not commit raw SQL, secrets, application data, storage objects, Vault material, or unnecessarily sensitive function bodies. | **CONDITIONAL / BLOCKED** |
| F — Independent validation | Require method comparison, security review, compatibility testing, approval, and rollback/recovery planning before staging reconstruction. | No artifacts or isolated runtime exist. Phase 2.1.5–2.1.6 reports consistently deny restore approval. | Obtain independent review of actual artifacts, destination defaults, security-sensitive definitions, synthetic role tests, and rollback/recovery controls. Obtain separate explicit staging-restoration authorization. | **BLOCKED** |

## 5. Extraction-method specification

### 5.1 Supabase schema-only SQL dump

The pinned CLI evidence is Supabase CLI `2.122.1`. Its help confirms that `supabase db dump` uses schema output by default and does not have a `--schema-only` flag. Future command shape, only after authorization, is:

```bash
npx --yes supabase@2.122.1 db dump \
  --db-url "$READ_ONLY_DB_URL" \
  --schema "$APPROVED_SCHEMA_LIST" \
  --file "$PRIVATE_CAPTURE_DIR/schema.sql"
```

Expected strengths include conventional SQL definitions for included schemas, including many tables, constraints, indexes, sequences, functions, triggers, views, and policies. Actual output must be scanned; “schema-only” is not a security boundary and must not be assumed to preserve every ACL/default-privilege edge case.

Known limitations include exclusion of `auth`, `storage`, and extension-created schemas by default; exclusion of row data, storage bytes, custom role definitions, provider configuration, and Dashboard settings; and lack of a complete project backup contract. Storage bucket rows/configuration require separate authorized handling. Do not add `--data-only` or `--role-only` without a new scope and authorization.

### 5.2 Declarative pg-delta schema generation

Future command shape, only after authorization, is:

```bash
npx --yes supabase@2.122.1 db schema declarative generate \
  --db-url "$READ_ONLY_DB_URL" \
  --schema "$APPROVED_SCHEMA_LIST" \
  --output-dir "$PRIVATE_CAPTURE_DIR/declarative" \
  --strict-coverage --experimental
```

The declarative tree is the conditional primary human-review candidate because object-level files are easier to inspect and diff. However, pg-delta is experimental/pre-1.0 in the cited documentation. The bundled runtime version, actual warnings, managed-schema behavior, privilege fidelity, and equivalence with the SQL dump are unknown until a real authorized run.

`--strict-coverage` is necessary to fail on unsupported coverage, not proof of semantic completeness. Review functions, search paths, security mode, views, RLS, policies, grants, defaults, ownership, publications, extensions, Auth/Storage customizations, and platform-managed objects separately.

### 5.3 Required comparison

The two outputs must be compared class-by-class, not merely by file count. Record exact commands, CLI and pg-delta versions, exit codes, warnings, unsupported objects, selected/excluded schemas, generated-file inventory, manual adjustments, and SHA-256 hashes. Treat differences as unresolved until explained against a bounded catalog inventory. No method may be called complete based only on successful execution.

## 6. Exact prerequisites before extraction

All of the following must be satisfied and documented before any production connection:

1. The owner approves a revised architecture and a specific extraction source.
2. A provider-enforced read-only source is selected where possible, with replication lag and cost accepted; otherwise the effective role boundary is independently demonstrated.
3. The role is a dedicated non-owner login with no privileged membership, ownership, write capability, `BYPASSRLS`, or data-exposing indirect path.
4. Disposable non-production testing proves CLI 2.122.1 can enumerate and render the approved schema without application-table `SELECT`.
5. The exact source endpoint tuple and username are copied from the approved Dashboard connection details and validated before connection; substring matching is removed from any future design.
6. TLS certificate and hostname verification is required and tested.
7. An approved schema list is established, including separate treatment for any authorized Auth/Storage customizations, extensions, and platform-managed objects.
8. PostgREST evidence is separately obtained in sanitized form for both project refs using verified `rest:read` and `data_api_config_read` access, without secret-read scope.
9. The private repository’s reader/writer access and artifact-retention policy are confirmed.
10. A private capture directory and hash manifest are prepared; no raw artifact is written to public Git.
11. An isolated PostgreSQL/Supabase test environment is available for restore and synthetic role testing.
12. Independent security-owner approval is obtained before staging restoration.

## 7. Safe execution sequence and stop conditions

1. **Preflight:** verify owner approval, target ref/source, approved schema list, role restrictions, TLS materials, private storage, and isolated test environment. Stop on any mismatch or unknown.
2. **Non-production compatibility test:** run the pinned CLI with a synthetic schema and restricted identity. Stop if the CLI requires application-row access or any privilege broader than approved.
3. **Private production capture:** run the declarative method with strict coverage and the independent default schema-only dump. Do not run data-only, role-only, migration, restore, or SQL execution commands. Stop on any warning, unsupported object, connection identity mismatch, unexpected statement, or non-zero exit code.
4. **Artifact scan and hashing:** scan for data statements, bucket rows, credentials, Vault material, unexpected roles/ownership, platform internals, and sensitive material. Hash files privately. Stop if raw output is not safely containable.
5. **Coverage reconciliation:** compare both methods to the prior bounded catalog inventory and dependency matrix. Record omissions and unresolved semantics. Stop if critical objects or security properties cannot be explained.
6. **Independent review:** security reviewer inspects functions, views, RLS, policies, grants, ownership, defaults, managed schemas, storage configuration, and PostgREST evidence. Stop if approval is withheld.
7. **Isolated restore and compatibility:** restore only the reviewed schema into an isolated environment, apply only an approved privilege overlay, use synthetic identities/fixtures, generate types, and run role-specific tests. Stop on any cross-role access, compatibility regression, or unexplained drift.
8. **Separate staging decision:** present the reviewed baseline, test results, rollback/recovery plan, and unresolved risks for explicit approval. Do not restore existing staging automatically.

## 8. Artifact handling and retention

Raw SQL and declarative artifacts are confidential security material. Keep them only in an access-controlled private location. Restrict access to the owner and explicitly approved reviewers; do not rely on repository privacy as a substitute for access review. Use the shortest practical retention, with one day as the current workflow maximum, and delete sooner after review. Keep hashes and sanitized inventories separate from raw artifacts. Never publish connection strings, tokens, JWT values, credentials, row data, storage bytes, Vault material, or raw artifacts. Do not include sensitive function bodies in public reports unless the owner explicitly approves a minimized excerpt.

## 9. Independent validation and staging prerequisites

Before reconstruction, the independent reviewer must approve:

- Both extraction outputs and their hashes.
- Coverage and warning reconciliation, including unsupported/excluded objects.
- Table, view, function, trigger, policy, grant, default-privilege, ownership, extension, publication, and managed-schema inventories.
- PostgREST configuration evidence and API exposure implications.
- Security-definer functions, search paths, view security options, RLS combinations, browser grants, and storage policies.
- Application compatibility against the Scholars dependency matrix, including generated types and synthetic role tests.
- Destination creator/default privileges and the proposed ACL overlay.
- Rollback/recovery strategy and owner-controlled administrator recovery procedure.

The existing staging project must not be used until this review passes and a separate authorization is granted. The earlier A0.7 finding remains controlling: the source does not provide a proven clean-install baseline, and the staging database is empty of the inspected Scholars application tables/migrations.

## 10. Risks, unresolved questions, and owner decisions

### Risks

- A schema-only command can still run with a credential that writes or reads application rows.
- A read replica prevents writes but does not prevent row reads and may lag.
- A restricted primary role may be defeated by ownership, inherited membership, missed grants, or indirect functions/views.
- SQL dump and pg-delta may differ in managed-schema treatment, ACL/default-privilege fidelity, and unsupported-object coverage.
- A successful artifact can expose privileged function logic and security design.
- Restoring under a different executor can change effective access through destination defaults.
- Existing application authorization findings, including the inherited `profiles.is_admin` self-elevation risk, must not be remediated as part of extraction.

### Unresolved questions

- Which exact provider-enforced source and endpoint will be approved?
- Can the pinned CLI complete under a no-row-access identity in a disposable environment?
- What exact schemas and managed-schema customizations are approved for capture?
- What are the current PostgREST exposed schemas, anonymous role, and related non-secret settings?
- What is the actual pg-delta runtime version and unsupported-object set?
- What are the effective destination creator/default privileges?
- Which owner and independent reviewer will approve the baseline and staging decision?

### Owner decisions required

The owner must select the source/endpoint architecture, approve the restricted identity design, approve the schema list and artifact-retention boundary, provide sanitized PostgREST evidence through an authorized channel, identify an isolated test environment, and separately authorize any staging restoration. No credentials are requested in chat.

## 11. Actions that remain unauthorized

This specification does not authorize anyone to:

- Connect to or query production or staging.
- Execute SQL against either environment.
- Create, retrieve, populate, rotate, or modify `SUPABASE_DB_URL`.
- Create roles, change privileges, modify RLS, or alter database objects.
- Run the GitHub Actions extraction workflow.
- Generate, download, or publish a production schema artifact.
- Import or restore anything into staging.
- Modify Auth, Storage, PostgREST, project settings, Vercel settings, environment variables, or application code/migrations.
- Begin administrator authorization remediation.
- Merge, deploy, or trigger a Vercel build.
- Treat this document, README HOLD notice, or any documentation approval as database-operation authorization.

## 12. Current decision and next phase

**Current decision: NO-GO / BLOCKED — AUTHORIZED CAPTURE NOT AVAILABLE.**

The next phase, only after owner approval and the gates above, is **authorized private artifact capture and isolated compatibility review**. It remains evidence-only until independent security approval is complete. Staging reconstruction, remediation, production changes, and deployment each require separate explicit authorization.

## References

- `SCHOLARS_A0_8_2_EXTRACTION_WORKFLOW_SECURITY_REFINEMENT_2026-11.md`
- `SCHOLARS_A0_8_1_PRIVATE_SCHEMA_EXTRACTION_WORKFLOW_SETUP_2026-11.md`
- `SCHOLARS_ADMIN_AUTHORIZATION_STAGING_IMPLEMENTATION_AND_VALIDATION_2026-11.md`
- `SCHOLARS_ADMIN_AUTHORIZATION_SECURITY_REMEDIATION_SPECIFICATION_A0_6_2026-11-08.md`
- `SCHOLARS_RESOURCE_CENTER_PHASE_A0_5_TARGETED_BACKEND_DEPENDENCY_VERIFICATION_2026-11-08.md`
- `HANDOFFS/SCHOLARS_PHASE_2_1_6_CONTINUATION_2026-11-10/CONTINUATION_HANDOFF.md`
- `HANDOFFS/SCHOLARS_PHASE_2_1_6_CONTINUATION_2026-11-10/reports/`
