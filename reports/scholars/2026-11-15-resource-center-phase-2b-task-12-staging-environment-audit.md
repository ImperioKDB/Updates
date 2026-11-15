# Scholars Resource Centre — Phase 2B Task 12 Staging Environment Audit

**Assessment date:** 2026-11-15
**Application source:** `ImperioKDB/Scholars` at `142146a67cb21eeec8d74832bc326c1fcd5dd5f4`
**Documentation source:** `ImperioKDB/Updates` at `81ecdf6edc87a9cb491d77e3ff83541019f8a370`
**Target:** existing Supabase project `scholars-staging`
**Mode:** read-only audit; no staging DDL or DML was executed.

## Verdict

**VERIFIED — PROJECT METADATA:** the intended staging project is distinct from production and from `serena`, accessible, and healthy. The mandatory isolation gate passes.

**BLOCKED:** the staging database is empty of the Scholars application baseline, and the source repository does not yet provide a defensible clean-install reconstruction path. No database changes were made.

## Project identity comparison

| Field | Production | Intended staging | Result |
|---|---|---|---|
| Name | `scholarship-platform` | `scholars-staging` | **VERIFIED — PROJECT METADATA:** distinct names |
| Reference | `cmdglabohpttgfofcmqc` | `aqhktriwaglvvrchxmtd` | **VERIFIED — PROJECT METADATA:** distinct references |
| Region | `eu-west-1` | `eu-west-1` | Same region; not evidence of shared data |
| Status | `ACTIVE_HEALTHY` | `ACTIVE_HEALTHY` | Accessible and healthy |
| PostgreSQL | 17.6.1.155 | 17.11.0.018 | Different minor releases; compatibility must be tested |
| Organization | Imperio Org (`xcygvuivzlascuarwqzl`) | Same organization | Project boundary remains separate |

`serena` is an unrelated inactive project (`nmlhcofasxsngmvjjxti`) and was not used.

## Current staging contents

| Check | Result | Classification |
|---|---:|---|
| Supabase migration history | 0 application migrations returned | **VERIFIED — LIVE STAGING DATABASE** |
| `public` base-table count | 0 | **VERIFIED — LIVE STAGING DATABASE** |
| `auth.users` row count | 0 | **VERIFIED — LIVE STAGING DATABASE** |
| `storage.buckets` row count | 0 | **VERIFIED — LIVE STAGING DATABASE** |
| Built-in storage schema | Present | **VERIFIED — LIVE STAGING DATABASE**; expected Supabase system schema |
| Public functions | 0 | **VERIFIED — LIVE STAGING DATABASE** |
| Public views | 0 | **VERIFIED — LIVE STAGING DATABASE** |
| Public RLS policies | 0 | **VERIFIED — LIVE STAGING DATABASE** |
| Public triggers | 0 | **VERIFIED — LIVE STAGING DATABASE** |
| Storage policies | 0 | **VERIFIED — LIVE STAGING DATABASE** |
| Supabase extensions | 5 installed | **VERIFIED — LIVE STAGING DATABASE**; names were not needed to establish isolation |

The table-list response contained only built-in `storage` relations; no Scholars application relation was present. No user, profile, application, scholarship, article, submission, private record, object, bucket, credential, or secret was copied or created.

## Mandatory safety gate

1. Target reference exactly matches the verified `scholars-staging` project: **PASS**.
2. Target differs from production: **PASS**.
3. Target is not `serena`: **PASS**.
4. Existing contents inventoried before changes: **PASS**.
5. No production user data will be copied: **PASS / commitment maintained**.
6. No production credentials will be placed in staging: **PASS / commitment maintained**.
7. A migration process cannot affect another project: **PASS for this audit; no migration process was invoked**.

The project contained no unexpected application data. It contained expected Supabase system schemas and an empty storage service. The task therefore did not stop for unexpected data; it stopped at the separate schema-baseline gate.

## Environment/application separation

**UNVERIFIED:** Auth redirect settings, MFA settings, email provider behavior, and API runtime behavior were not changed or tested. **UNVERIFIED:** a Vercel Preview deployment bound to this staging project does not exist as a verified separate environment. Read-only Vercel project metadata shows no custom environment, and the inspected Supabase URL, anon-key, and service-role variable entries are shared across Production and Preview targets rather than demonstrably branch-bound to `aqhktriwaglvvrchxmtd`.

No Vercel value was decrypted, printed, changed, or copied. No deployment was triggered.

## Decision

The project is safe to use as the intended isolated target, but it is not yet a representative Scholars staging environment. Proceeding to DDL would require an approved schema-only baseline or a documented source-derived reconstruction bundle. This report authorizes no migration execution.
