# Scholars Phase 2.1.7 — Execution Environment Options

**Status:** BLOCKED — no approved isolated test runner available
**Evidence date:** 2026-11-10
**Author:** Manus AI

## Current environment

The current workspace is an online Ubuntu 24.04.5 LTS amd64 Manus Sandbox. It has about 38 GB free on the filesystem containing `/tmp`, writable temporary storage, and the pinned Supabase CLI `2.122.1` verified from the prior phase. SHA-256 tooling is available. `pg_dump`, `psql`, `postgres`, `initdb`, and Docker are absent; the Docker socket is unavailable. The package cache contains no discoverable PostgreSQL 17 client package. Passwordless sudo is technically available, but this review did not use it and does not recommend privileged installation.

A PostgreSQL client could in principle be unpacked into a user-owned directory from a trusted, compatible package source without changing system files, but availability, dependency closure, and the resulting binary version have not been validated. Therefore the current workspace is **not yet qualified** for independent native `pg_dump`. Supabase CLI `db dump` runs `pg_dump` in a container, so it also needs a container runtime. [1]

The current device inventory contains only this Manus Sandbox. There is no already-authorized Cloud Computer, desktop, or alternate workspace to reuse. This is a read-only device inventory; no environment was switched, resumed, allocated, or created.

## Options and lowest-cost route

1. **Preferred zero-new-resource option:** an administrator supplies an existing approved Docker-enabled CI runner or workstation that can run Supabase CLI `2.122.1`, PostgreSQL 17 client tools, and a disposable local PostgreSQL/Supabase stack. Use synthetic fixtures only. This avoids a new Supabase project and any new paid service, if such a runner already exists.
2. **Current Sandbox:** could potentially host a user-space PostgreSQL client after package-source and dependency validation. Without Docker it cannot run the supported full local Supabase stack; plain PostgreSQL alone would not test Auth, PostgREST, Storage, or platform-managed policies. It is not a complete compatibility environment.
3. **Existing staging:** expressly excluded. It has no Scholars application baseline and must not be used as a restore target.
4. **New cloud VM, paid runner, or new Supabase project:** not permitted by this phase and not recommended as a default.

## Decision and next action

No suitable already-authorized isolated runtime was found. The administrator must identify an existing Docker-enabled runner/workstation and confirm private artifact storage and secret injection, or separately authorize a different environment. Do not install system packages, enable Docker, incur cost, create a project, or modify staging under this phase.

## References

[1]: https://supabase.com/docs/reference/cli/introduction "Supabase CLI Database Dump Behavior"
[2]: https://supabase.com/docs/guides/local-development/cli-workflows "Supabase Local Development CLI Workflows"
