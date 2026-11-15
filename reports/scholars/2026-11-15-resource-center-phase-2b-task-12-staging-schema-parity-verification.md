# Scholars Resource Centre — Task 12 Staging Schema Parity Verification

**Assessment date:** 2026-11-15
**Source:** `ImperioKDB/Scholars` at `142146a67cb21eeec8d74832bc326c1fcd5dd5f4`
**Target:** `scholars-staging` / `aqhktriwaglvvrchxmtd`
**Verification mode:** read-only; no migration or application request executed.

## Verdict

**BLOCKED — PARITY NOT ESTABLISHED.** The live staging project is isolated and empty of Scholars application schema. Because reconstruction was correctly stopped before DDL, the expected source schema cannot be compared as an applied baseline. “Zero staging tables” is an observation, not schema parity.

## Source-versus-staging summary

| Area | Expected from source/application | Staging observation | Result |
|---|---|---|---|
| Application migration history | 136 source SQL files requiring an approved ordered baseline | 0 applied migrations returned | **BLOCKED** |
| Profiles/Auth lifecycle | `profiles`, Auth trigger/provisioning, profile policies/grants | No public application tables; `auth.users` count 0 | **BLOCKED** |
| Scholarships/opportunities | Catalog, rules, discovery, verification and eligibility dependencies | Absent | **BLOCKED** |
| Applications/matching | Application and matching-related tables, indexes, routines | Absent | **BLOCKED** |
| Community/referrals | Community, notifications, referrals, XP and attribution relations | Absent | **BLOCKED** |
| Analytics/monitoring | Events, visitor/provider/confirmation analytics and functions | Absent | **BLOCKED** |
| Resource Centre | Five base tables, indexes, RLS, policies and four public projections | Absent | **BLOCKED** |
| Profile security | Columns, privileges, RLS, policies, triggers, constraints, admin helper | No public functions/policies/triggers | **BLOCKED** |
| Administrator dependencies | `profiles.is_admin`, helper, policy/routine references, storage policies | No application authority exists | **BLOCKED** |
| Storage | Application buckets and policies | `storage.buckets` count 0; system schema only | **BLOCKED** |
| Views | Public projections and application views | Public views count 0 | **BLOCKED** |

## Read-only staging observations

- `public` base-table count: **0**.
- `auth.users`: **0** rows.
- `storage.buckets`: **0** rows.
- Public functions: **0**.
- Public views: **0**.
- Public RLS policies: **0**.
- Public triggers: **0**.
- Storage policies: **0**.
- Supabase migration history: **empty**.
- Built-in Supabase system schemas/tables exist as expected.

These are **VERIFIED — LIVE STAGING DATABASE** observations. No profile, Auth, application, private submission, or production record was retrieved.

## Required parity checks after a future approved reconstruction

The reusable SQL companion checks, at minimum, should be run after each approved baseline build to compare:

1. Schemas, tables, columns, types, nullability, defaults and generated columns.
2. Primary keys, foreign keys, checks, unique constraints and indexes.
3. Extensions and extension versions.
4. Function names, signatures, owners, `SECURITY DEFINER`, fixed search paths and execution ACLs.
5. RLS enabled/forced status, policy roles/commands/expressions and policy counts.
6. Triggers and trigger functions.
7. Views, owners, security-barrier and security-invoker settings.
8. Storage buckets, visibility and storage policies.
9. Migration history and source-manifest coverage.
10. Explicit dependencies on `public.is_admin(uuid)` without calling that function or retrieving user records.

## Interpretation

The result is not a failed staging database migration; no migration was attempted. It is a safe parity stop caused by the missing authoritative baseline. A future report may only claim **VERIFIED — LIVE STAGING DATABASE** parity after a reviewed baseline is applied and these checks compare the resulting schema against an approved expected object manifest.
