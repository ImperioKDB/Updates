# Scholars Phase 2.1.2 — Decision and Blocker Register

**Investigation date:** 2026-11-09
**Overall verdict:** **BLOCKED — ADDITIONAL INVESTIGATION REQUIRED**
**Change status:** No production or staging changes were made.

## Blockers

| ID | Decision or blocker | Severity | Evidence needed | Responsible approval/owner | Blocks implementation? |
|---|---|---|---|---|---|
| B-01 | Exact deployed PostgREST exposed-schema list is unavailable from inspected database metadata. | Critical | Authoritative Supabase project-setting export or approved service-admin confirmation | Database/platform owner | Yes |
| B-02 | Production API configuration cannot be compared with staging configuration. | High | Same settings inventory for both projects | Database/platform owner | Yes |
| B-03 | Safe anonymous checks confirmed routes for catalog, Resource Center views, and selected internal no-row probes, but authenticated role behavior is untested. | High | Fresh synthetic Student A/B JWT tests in staging | Security/database owner | Yes |
| B-04 | Sensitive RPCs were not invoked in production, as required by the safety brief. | High | Staging-only role tests with synthetic fixtures | Security owner | Yes for remediation sign-off |
| B-05 | Staging is healthy but has no inspected Scholars tables and no migrations. | Critical | Approved schema-only reconstruction and pre-change resource inventory | Project/database owner | Yes |
| B-06 | Production ledger has 177 entries while the application baseline has 129 migration files. | Critical | Complete ordered ledger-to-file/content-hash mapping | Database owner and application owner | Yes |
| B-07 | Missing or differently named sources exist for opportunities creation, historical `is_admin` EXECUTE restoration, admin metrics follow-up, and cycle events. | High | Recovered source, ledger SQL, or approved replacement migration with provenance | Database owner | Yes |
| B-08 | Duplicate numeric migration prefixes make filename ordering unreliable. | High | Immutable ordered migration manifest with content hashes | Application/database owner | Yes |
| B-09 | Actual migration execution role is not established for the full production history. | High | Migration runner identity and default-privilege ownership evidence | Database/platform owner | Yes |
| B-10 | Broad `supabase_admin` default privileges remain a future-object risk, but the supported correction path is not approved. | High | Platform-supported administrative procedure and impact review | Database/platform owner | Yes for default-privilege remediation |
| B-11 | Public field policy is unresolved for research notes, cycle notes/actor IDs, competitiveness fields, contributor identity, presence, exact counts, and small cohorts. | High | Product/security field-by-field approval | Product owner and security owner | Yes |
| B-12 | Editorial researcher/reviewer/approver separation and self-approval rules are not assigned. | High | Approved role model and membership source | Product/security owner | Yes |
| B-13 | Current server routes query base tables directly and would break under a blanket browser-grant revoke. | High | Per-call-site replacement design, updated generated types, and staging regression results | Application owner | Yes |
| B-14 | Resource Center views are postgres-owned and advisor-flagged as security-definer views. | High | Staging tests for unpublished rows, field allowlists, joins, and owner/RLS semantics | Database/security owner | Yes |
| B-15 | No demonstrated HTTP route for TRUNCATE exists, but database ACL metadata confirms the privilege. | High | No production probe; isolated staging metadata and purpose-built role test only | Security/database owner | Yes for final risk classification |

## Required governance decisions

### Public data contract

Approve whether the public API may return research notes, competitiveness tiers, acceptance-rate estimates, cycle-event notes, captured-by identities, exact social-proof counts, contributor identities, and online presence. The safest interim default is to exclude internal notes, actor IDs, exact small-cohort metrics, and presence indicators.

### Role model

Approve the source of trusted researcher, reviewer, approver, auditor, and worker capabilities. Do not use editable user metadata. Decide whether self-research/self-review/self-approval is prohibited and where that rule is enforced.

### Migration ownership

Identify the supported migration executor and confirm which role creates tables, functions, sequences, schemas, and views. The default-privilege plan must cover every sanctioned creator role without modifying platform-managed memberships in an application migration.

### Staging reconstruction

Approve reconstruction of `aqhktriwaglvvrchxmtd` using synthetic fixtures only. Confirm that existing platform resources may be preserved and that no production data may be copied.

### Production verification access

Decide whether an approved administrative metadata export may be used to confirm deployed PostgREST settings. No service-role key, database password, JWT, or secret should be placed in reports or logs.

## Evidence status summary

| Finding | Status |
|---|---|
| Production and staging project IDs/statuses | Confirmed from Supabase project metadata |
| Production 177-entry migration ledger | Confirmed from Supabase migration inventory |
| Staging has no inspected application tables | Confirmed from table inventory for requested schemas |
| Staging has no migration ledger entries | Confirmed from migration inventory |
| Production 45 public tables and four public views | Confirmed from read-only catalog/table inventory |
| Broad ACLs on audited relations | Confirmed from read-only catalog metadata |
| RLS enabled/not forced and policy shapes | Confirmed from read-only catalog metadata |
| 23 browser-executable security-definer functions | Confirmed by catalog and security advisor |
| Anonymous route addressability for selected objects | Confirmed by safe 200 empty HTTP checks |
| Successful access to real private rows | Not tested and not claimed |
| Authenticated non-admin HTTP behavior | Unverified |
| Sensitive RPC execution | Not tested by design |
| TRUNCATE over HTTP | Not demonstrated |
| Exact PostgREST exposed-schema configuration | Unresolved |
| Reproducible staging baseline | Not available |

## Safely runnable next

1. Obtain authoritative production and staging PostgREST settings without exposing credentials.
2. Finish the production ledger-to-source mapping using content hashes and execution order.
3. Inventory staging resources again immediately before any approved setup.
4. Build a schema-only staging reconstruction plan from reviewed sources.
5. Create only synthetic test identities and fixtures after explicit staging approval.
6. Run role-based PostgREST and Next.js tests against staging, including negative cross-user and internal-field cases.
7. Reconcile generated database types and application call sites before any grant change.
8. Test rollback in staging without restoring broad browser privileges.

The following are not safe next steps in this phase: invoking sensitive production RPCs, reading real student rows, attempting TRUNCATE or unauthorized writes, applying migrations, modifying staging, changing PostgREST settings, or deploying application code.

## Stop/go decision

The correct current decision is **BLOCKED — ADDITIONAL INVESTIGATION REQUIRED**. Production API behavior is partially verified, but the deployed schema configuration and authenticated behavior remain unresolved. Staging is a healthy empty target rather than a ready test environment. No remediation or executable production migration should begin until B-01 through B-13 are resolved or explicitly accepted by the responsible owners.

## References

[1]: https://github.com/ImperioKDB/Scholars/commit/cf3682ce35912df7b9b9352193630fc404427c7c "Scholars application baseline"
[2]: https://github.com/ImperioKDB/Updates/commit/7f7eb680562b6e89c0172b5534848f2b576002c0 "Phase 2.1.1 audit handoff"
