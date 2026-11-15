# Scholars Resource Centre — Phase 2B Administrator Self-Elevation Implementation Readiness

**Assessment date:** 2026-11-15
**Application repository:** `ImperioKDB/Scholars`
**Documentation repository:** `ImperioKDB/Updates`
**Source baseline inspected:** `main` at `142146a`
**Production project:** `scholarship-platform` / `cmdglabohpttgfofcmqc`
**Proposed migration timestamp:** `20261115180000_secure_profiles_admin_authorization.sql` (proposal only; not added to Scholars)

## Final verdict

# BLOCKED — MISSING REQUIREMENTS

This task produced the requested remediation design, source dependency inventory, proposed SQL, regression plan, and readiness assessment. It is **not ready for staging implementation** because the required representative Scholars database baseline has not been validated in the isolated staging project, the generic PostgREST profile upsert contract has not been tested after privilege narrowing, administrator/recovery identities and last-admin policy have not been established, and production MFA configuration remains unverified. No implementation should proceed from this report alone.

## What was reconstructed

The latest `main` branch of `ImperioKDB/Updates` already contained substantial Task 9/10 and Phase 2B work. Existing artifacts include the production verification SQL/results, supplementary function/policy/trigger/constraint analysis, privilege-regression correction, administrator authorization specification, staging establishment report, and earlier Resource Centre reports. The five exact Task 11 deliverable paths requested in the continuation brief were absent, so they were created rather than duplicating an existing valid deliverable.

The latest `main` branch of `ImperioKDB/Scholars` was inspected read-only. The source still contains the profile privilege history and current application paths relevant to the cutover. No Scholars file was modified.

## Evidence classification

- **VERIFIED — CURRENT TASK:** both authoritative repositories were cloned and inspected; current source and migration files were read; the five requested paths were absent before drafting; no Scholars source file was changed.
- **VERIFIED — SOURCE:** `app/api/profile/route.ts` uses an authenticated generic `profiles` upsert; onboarding, referral attribution, presence, community bio, and invitation-consent paths have distinct dependencies; migrations `0023`, `0028`, `0029`, `0061`, `0069`, `0070`, `0080`, `0093–0095` affect the profile write boundary.
- **VERIFIED — DATABASE (PRIOR REPORT):** published Task 9/10 reports record effective authenticated table/column write privileges, the own-row policy, the helper owner/security/search-path/ACL, and the absence of a protecting trigger or constraint. These findings were not independently rerun here.
- **VERIFIED — CURRENT TASK / PROJECT METADATA:** Supabase project listing returned `scholarship-platform` as healthy, `scholars-staging` as healthy, and `serena` as inactive. Metadata listing did not validate a representative Scholars schema or Vercel Preview mapping.
- **INFERRED:** narrowing/removing table-level profile DML can break the existing PostgREST upsert unless the exact API behavior is proven or the app path is replaced.
- **UNVERIFIED:** runtime authentication, profile mutations, PostgREST behavior, admin route behavior, AAL2 enforcement, staging schema parity, Vercel variable isolation, and all regression-test outcomes.
- **BLOCKED:** implementation readiness, because the missing prerequisites are security-critical and cannot be filled by assumptions.

## Readiness gates

| Gate | Status | Evidence |
|---|---|---|
| Authoritative source reconstruction | PASS | Updates and Scholars `main` inspected; prior Task 9/10 and staging reports located. |
| Profile dependency inventory | DESIGN COMPLETE | Source inventory published; runtime dependency behavior remains unverified. |
| Remediation design | DESIGN COMPLETE | Combined database guard, caller-bound helper, allow-listed writes, lifecycle function, audit, and AAL2 design published. |
| Proposed migration | REVIEW DRAFT | SQL is published in Updates only; no statement was executed. |
| Isolated Scholars staging project | PARTIAL / BLOCKED | `scholars-staging` exists and is healthy per current metadata; prior report found it empty and blocked at baseline reconstruction. |
| Representative schema baseline | BLOCKED | No validated schema-only manifest/snapshot tied to the source revision. |
| Safe profile upsert compatibility | NOT TESTED | Source migration explicitly warns that upsert requires table-level rights; no staging runtime test exists. |
| Admin lifecycle/recovery | BLOCKED | No roster, independent recovery operator, or approved last-admin policy was established. |
| MFA/AAL2 enforcement | UNVERIFIED | Source supports conditional checks; production configuration and high-risk call-site enforcement are not verified. |
| Security/regression tests | NOT RUN | Plan contains expected outcomes only. |
| Production implementation | NOT AUTHORIZED | No migration, grant, revoke, policy, function, trigger, config, deployment, PR, or merge performed. |

## Required actions before staging implementation

1. Approve or produce a schema-only Scholars baseline with ordered migrations and deliberate data/seed exclusions documented. It must include profile/auth provisioning, all grants/default privileges, RLS, helper/routines, triggers, views, storage, Resource Centre, scholarships, applications, matching, and community dependencies.
2. Apply and validate that baseline only in `scholars-staging`; do not use `serena` and do not create a new project as a substitute for the existing isolated project.
3. Configure and verify branch-scoped Vercel Preview variables against staging only before any branch push. Keep production secrets out of the branch and reports.
4. Create synthetic ordinary/admin/recovery identities and a safe reset path. Establish owner-approved bootstrap, two-person approval, emergency recovery, AAL2, audit retention, and last-admin rules.
5. Generate the exact live/staged dependency inventory for every policy and routine referencing `is_admin`; reconcile it with the proposed caller-bound helper cutover.
6. Prove safe ordinary profile upsert behavior. If explicit-column grants cannot support the deployed PostgREST operation, replace the generic upsert with a fixed allow-listed mutation endpoint/RPC before revoking broad DML.
7. Execute the regression plan only in staging. A passing source review is not a runtime pass.

## Safety confirmations

- **No production SQL executed:** yes, within this task.
- **No production migration, INSERT, UPDATE, DELETE, ALTER, GRANT, or REVOKE executed:** yes.
- **No Scholars application source changed:** yes; only the Updates checkout was written with the five report artifacts.
- **No administrator created, promoted, or demoted:** yes.
- **No exploit attempted:** yes; no profile write, HTTP exploit, helper invocation, or membership lookup was performed.
- **No PR, merge, deployment, or production configuration change:** yes.
- **Serena used as staging:** no.

## Deliverables

The companion files in this publication are the authoritative Task 11 package:

- Administrator self-elevation remediation design.
- Profile-write dependency inventory.
- Non-executed administrator authorization proposal SQL.
- Verification and regression plan.
- This implementation-readiness assessment.

The task stops at publication and verification. Any subsequent source modification, migration execution, privilege change, production configuration change, merge, or deployment requires separate explicit authorization.
