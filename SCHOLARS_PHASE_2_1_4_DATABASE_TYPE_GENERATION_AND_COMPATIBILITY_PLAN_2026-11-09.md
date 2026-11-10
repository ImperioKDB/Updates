# Scholars Phase 2.1.4 — Database Type Generation and Compatibility Plan

**Investigation date:** 2026-11-10
**Scope:** Read-only design. No generated type file was overwritten and no application deployment was triggered.

## Goal

The new staging baseline must produce database types from the reviewed schema, not from guessed migration history. The generated type artifact should become a compatibility contract between the Next.js application, Supabase clients, database relations, views, functions, and enums. It must not be treated as a security proof: generated types do not encode RLS policy correctness, function `SECURITY DEFINER` safety, grants, or runtime PostgREST configuration.

Supabase documents the CLI command:

```bash
npx supabase gen types typescript --remote="$PROJECT_REF" --schema public > database.types.ts
```

The CLI can also generate from a local database. The generated definitions are then supplied as the `Database` generic to `supabase-js`. [1]

## Baseline generation plan

After the reviewed baseline exists in an isolated staging project, generate types against the staging project ref and the approved exposed application schemas. The first generated artifact should be saved under a deterministic repository path, with the CLI version, project ref, selected schemas, commit SHA, timestamp, and schema manifest recorded beside it. Do not include tokens or connection strings in the generated file.

If the application exposes a custom schema such as a Resource Center schema, include it only after the PostgREST configuration plan has confirmed that the schema is intentionally exposed and its grants are reviewed. Otherwise generate only the approved public schema. The schema list must be explicit and identical between staging validation and production release checks.

## Compatibility checks

The type-generation check should compare the generated artifact to the committed file and fail on unexpected changes. Supabase's GitHub Actions example uses a pull-request check that generates types from a local database and fails when the generated output differs from the committed artifact. [2]

The compatibility suite should include TypeScript compilation, application unit tests, route tests for every table and RPC dependency in the Phase 2.1.2 matrix, and focused checks for views and nested relationships. It should verify that the baseline contains every relation used by the application and that no relation has silently changed from table to view, nullable to non-nullable, enum to text, or one function signature to another.

The suite should also test the boundary that generated types cannot cover. Run anonymous, authenticated, and service-role-equivalent tests in an isolated environment for public catalogue reads, profile ownership, application ownership, admin-only operations, storage bucket access, Resource Center reads, and protected RPCs. Assert both allowed and denied outcomes. Never use real accounts or production data in these tests.

## CI shape

A future pull-request check should perform the following sequence:

1. Start a disposable local Postgres/Supabase stack from the reviewed migration or schema baseline.
2. Apply the migrations and generate types locally.
3. Compare generated types with the committed file using a whitespace-tolerant diff only for line-ending noise.
4. Run the TypeScript build, unit tests, and database boundary tests.
5. Emit a manifest containing migration hashes, generated-type hash, CLI version, and schema selection.

A protected staging job should then generate types remotely from staging after the approved baseline is applied, compare the remote artifact with the local artifact, and stop on drift. Production should be checked after deployment using the same command and should report drift; it should not silently commit changes back into the repository.

## Compatibility risks specific to the current repository

The application repository currently has many migration files with duplicate numeric prefixes and historical reference migrations. Replaying those files is therefore not a reliable source for generated types. The current application uses separate public, server, and service Supabase clients; the generated `Database` type must be applied consistently without widening the service boundary or moving privileged credentials into browser code. [3]

The Resource Center and security-boundary migrations are recent production changes. Their tables, views, functions, grants, and RLS policies must be included in the matrix and checked independently. A green type check cannot establish that the recent security remediation is actually present or correctly exposed.

## Decision

Generate database types only after the schema-only baseline and PostgREST configuration have been reviewed. Treat the first generated artifact as a baseline comparison, not as a reason to modify the application automatically. Any type change that alters nullability, enum values, RPC signatures, or public relations requires an application owner review and a focused compatibility test.

## References

[1]: https://supabase.com/docs/guides/api/rest/generating-types "Supabase generating TypeScript types"
[2]: https://supabase.com/docs/guides/deployment/ci/generating-types "Supabase GitHub Actions type generation"
[3]: https://github.com/ImperioKDB/Scholars/blob/cf3682ce35912df7b9b9352193630fc404427c7c/lib/supabase/server.ts "Scholars server Supabase client baseline"
