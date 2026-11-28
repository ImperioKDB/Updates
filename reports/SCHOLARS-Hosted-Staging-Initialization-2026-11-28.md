# Scholars hosted staging initialization

**Status — blocked before hosted connection.**
Date — 2026-11-28 (Africa/Lagos)
Authorized target — `aqhktriwaglvvrchxmtd`, direct PostgreSQL endpoint `db.aqhktriwaglvvrchxmtd.supabase.co:5432`

## Verified packet

The clean checkout matched the approved commit `df6df479a715a0a801b965d5f8ad608e6b147ca7`. All 15 entries in `SCHOLARS_SHARED_STAGING_BASELINE_2026-11-28/SHA256SUMS` verified. A separate check matched the foundation to the SHA-256 supplied with the approval. [Approved packet](https://github.com/ImperioKDB/Updates/tree/df6df479a715a0a801b965d5f8ad608e6b147ca7/SCHOLARS_SHARED_STAGING_BASELINE_2026-11-28)

| Approved SQL | Verified SHA-256 | Application in this run |
| --- | --- | --- |
| `00_initialization.sql` | `c2015c70af9412622ed30ffa9a37e50ffe15b6936d32e0ac5b177ab11d9f6e15` | Pending |
| `01_foundational_schema.sql` | `a47ad246308868ad1e5f6dadccc4ed5020c1c6a11f617a8cf2d40c4ed25ba3af` | Pending |
| `20261127000000_complete_deadline_reminders.sql` | `f5ef743aea40944fbdd67161891de6106d44d87749e5e03583537ac0288ca62e` | Pending |
| `20261127233336_durable_admin_broadcast.sql` | `ce46d2a70f461c95006ac57c2f9cfa1662639959fda830c08e12903590da92e4` | Pending |

## Hosted verification pending

Native `psql` was available. The execution environment had no private staging PostgreSQL passfile or staging CA binding. A direct connection with `sslmode=verify-full` could not be established, so the run stopped before `00_preflight.sql`. The earlier independent inventory is prior evidence. The current object, Auth, migration and job counts require confirmation on the verified connection before any schema write.

The staging operator needs to provide the passfile and CA privately. With those in place, use a fresh client process with inherited PostgreSQL connection overrides cleared and with the exact endpoint, database, role and TLS verification explicitly set. Preserve the approved packet and treat any unexpected endpoint, object, Auth record, migration history entry or scheduled job as a stop condition. Expected migration history before initialization contains only `20261125152047 create_better_auth_private_schema`.

Hosted initialization, catalog and ACL checks, rollback-only role and compatibility tests, zero-residue counts, and the applied-version record are pending. The hashes above are artifact evidence. This run made no connection, applied no schema version and did not start a deployment.
