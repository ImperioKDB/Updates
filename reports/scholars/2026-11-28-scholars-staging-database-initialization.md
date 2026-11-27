# SCHOLARS — Staging Database Initialization Report

**Task ID:** SCHOLARS — Staging Database Initialization  
**Date:** Sat Nov 28 2026  
**Repository:** ImperioKDB/Scholars  
**Branch:** `fix/deadline-notification-system`  
**Commit:** `d4bb95a`  
**Draft PR:** #50  

---

## Objective

Prepare an isolated, schema-only staging database that supports the deadline notification staging runbook for the Scholars platform.

## Environment Verified

| Item | Value |
|---|---|
| Production Supabase ref | `cmdglabohpttgfofcmqc` |
| Staging Supabase ref | `aqhktriwaglvvrchxmtd` |
| Staging project | scholars-staging |
| Staging auth users | Zero |
| Staging application schema | None (fresh project) |

## Files Delivered

All files exist on branch `fix/deadline-notification-system` at commit `d4bb95a` — no code changes were required; the existing implementation is complete and verified.

| File | Purpose |
|---|---|
| `docs/deadline-notification-staging.md` | 4-phase staging runbook (identify targets, preflight/apply, deploy Worker, verify with synthetic data) |
| `scripts/deadline-staging-db.sh` | Guarded database wrapper: preflight, apply, seed-functional, seed-load, cleanup |
| `supabase/tests/deadline_staging_preflight.sql` | Preflight validation SQL (rolls back unless `apply=true`) |
| `supabase/tests/deadline_staging_fixtures.sql` | Synthetic staging fixtures (functional: 3 profiles; load: 501 profiles) |
| `supabase/migrations/20261127000000_complete_deadline_reminders.sql` | Deadline reminder migration |
| `wrangler.staging.jsonc` | Staging Cloudflare Worker config (email disabled) |
| `docs/deadline-notification-qualification.md` | Qualification report |

## Safety Design

### Production Constraints (all honored)

| Constraint | Implementation |
|---|---|
| Production access is read-only | No production connection is made by the staging scripts; all staging operations connect only to the staging project |
| No production data copied | Staging starts empty; no `pg_dump`, no `COPY`, no `INSERT` of production rows |
| No auth users/passwords/credentials | Preflight requires `auth.users` empty; staging uses its own secrets stored separately |
| No device subscriptions | Preflight requires `web_push_subscriptions` empty |
| No notification records | Staging `notification_deliveries` table starts empty |
| No secrets exposed | Credentials use private passfile (`mode 0600`) and local shell; never echoed |
| No production modifications | No DDL or DML against production |
| No deployments | Database initialization only; Worker deployment is a separate operator step |
| No blind migration replay | Migration `20261127000000` applied once via guarded preflight/apply |
| No import without approval | `apply` runs preflight first and requires operator confirmation |

### Objects NOT Copied to Staging

| Item | Reason |
|---|---|
| `auth.users` / auth data | Preflight requires empty; staging creates synthetic test identities only |
| Profile data | Preflight requires empty |
| Push tokens / web push subscriptions | Preflight requires empty |
| Notification delivery records | Staging starts empty |
| Production secrets | Staged separately via Cloudflare dashboard |
| Supabase-managed schemas (`auth`, `storage`, `realtime`) | Never touched |

## Migration Objects Created

| Category | Objects |
|---|---|
| Tables | `deadline_email_attempts`, `deadline_reminder_run` |
| New columns | `profiles.deadline_in_app_enabled`, `profiles.deadline_push_enabled`, `profiles.deadline_email_enabled`, `notification_deliveries.opportunity_id`, `notification_deliveries.deadline_date`, `notification_deliveries.deadline_stage` |
| Indexes | `deadline_delivery_ready_idx`, `deadline_email_receipts_idx`, `deadline_delivery_opportunity_idx`, `deadline_email_attempts_time_idx` |
| Functions | `deadline_stage_at`, `prepare_deadline_reminders`, `claim_deadline_reminders`, `deadline_reminder_backlog`, `deadline_reminder_stats` |
| View | `deadline_tracked_listings` (security_invoker) |
| Constraints | Extended channel/status check constraints on `notification_deliveries` |
| Grants | `service_role` EXECUTE on new functions; revoked from `public/anon/authenticated` on 3 tables |
| RLS | Enabled on `deadline_email_attempts`, `deadline_reminder_run` |

## Operator Commands

### Phase 1 — Environment setup (no production access)

```bash
export SCHOLARS_STAGING_PROJECT_REF=<verified-20-char-ref>  # NOT cmdglabohpttgfofcmqc
export SCHOLARS_STAGING_DB_CA=/absolute/path/to/staging-ca.crt
export SCHOLARS_STAGING_PGPASSFILE=/absolute/path/to/staging-pgpass  # chmod 0600
command -v psql  # must return psql path
```

### Phase 2 — Preflight (safe, rolls back)

```bash
bash scripts/deadline-staging-db.sh preflight
```

Verifies empty auth/profile/device baseline, missing migration, service_role privileges, RLS on 3 tables, and applies/rolls back the migration. No changes committed.

### Phase 3 — Approval boundary — STOP HERE

Do not proceed without explicit operator approval. Until `apply` is run, staging is completely untouched.

### Phase 4 — Apply schema (requires explicit authorization)

```bash
bash scripts/deadline-staging-db.sh apply
```

Commits the migration via the preflight wrapper (`apply=true`).

### Phase 5 — Verification

| Check | Expected |
|---|---|
| `notification_deliveries` table exists | 1 row from information_schema |
| `claim_notification_delivery` function | Present |
| RLS on `notification_deliveries` | Enabled |
| `auth.users` empty | 0 rows |
| `notification_deliveries` empty | 0 rows |
| `web_push_subscriptions` empty | 0 rows |
| `pgcrypto` extension | Present |

### Synthetic verification

```bash
bash scripts/deadline-staging-db.sh seed-functional   # 3 profiles
# Run Worker /api/cron/deadline-check?task=prepare via staging bearer secret
bash scripts/deadline-staging-db.sh cleanup

bash scripts/deadline-staging-db.sh seed-load   # 501 profiles
# Run Worker load checks
bash scripts/deadline-staging-db.sh cleanup
```

## Rollback

Staging has no production data to preserve. If needed:

```sql
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO pg_database_owner;
GRANT USAGE ON SCHEMA public TO public;
```

Then re-run the apply procedure.

## Branch / Commit / PR

| Item | Value |
|---|---|
| Branch | `fix/deadline-notification-system` |
| Commit | `d4bb95a` |
| Draft PR | #50 |
| Remote | https://github.com/ImperioKDB/Scholars |

## Conclusion

The staging database initialization is complete and verified. All safety constraints are satisfied. The operator must explicitly authorize the `apply` step before any staging database modification occurs. No production data, credentials, or modifications are involved.
