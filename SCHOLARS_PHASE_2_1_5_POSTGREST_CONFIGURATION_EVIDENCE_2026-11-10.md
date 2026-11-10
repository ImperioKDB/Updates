# Scholars Phase 2.1.5 — PostgREST Configuration Evidence

**Investigation date:** 2026-11-10
**Scope:** Read-only configuration evidence for production and staging. No PostgREST setting was changed.

## Verdict of this workstream

The supported Supabase Management API endpoint could not be authenticated from this execution environment. Both required configuration records therefore remain unverified. This is an access blocker, not evidence that any setting is unset.

## Scope and methodology

The project references were independently revalidated through the Supabase read-only project metadata connector:

| Environment | Project ref | Project name | Region | Status | Database |
|---|---|---|---|---|---|
| Production | `cmdglabohpttgfofcmqc` | `scholarship-platform` | `eu-west-1` | `ACTIVE_HEALTHY` | PostgreSQL 17.6.1.155 |
| Staging | `aqhktriwaglvvrchxmtd` | `scholars-staging` | `eu-west-1` | `ACTIVE_HEALTHY` | PostgreSQL 17.11.0.018 |

The documented read-only endpoint was requested without a credential:

```text
GET https://api.supabase.com/v1/projects/{ref}/postgrest
```

Both project references returned HTTP 401. No response configuration values were retained. No JWT, service-role key, database password, connection string, or other credential was retrieved or exposed. The environment did not contain a `SUPABASE_ACCESS_TOKEN`.

## Required evidence status

| Field or question | Production | Staging | Status |
|---|---|---|---|
| `db_schema` | Not obtained | Not obtained | Blocked by Management API authorization |
| `db_extra_search_path` | Not obtained | Not obtained | Blocked by Management API authorization |
| Anonymous database role / `db-anon-role` question | Unresolved | Unresolved | No supported authorized evidence |
| OpenAPI mode question | Unresolved | Unresolved | No supported authorized evidence |
| Any JWT-related field | Intentionally not requested/retained | Intentionally not requested/retained | Protected by scope rule |

The earlier SQL catalog work also did not return authoritative PostgREST service configuration values. A null or absent SQL result cannot prove that a setting is unset, so no configuration value is inferred here.

## Security implications

The application-facing API surface cannot be approved from database catalog evidence alone. The public Resource Center views and browser grants are known, but the exposed-schema and anonymous-role configuration remains a separate control plane. A candidate baseline must not be considered API-compatible until an administrator supplies sanitized Management API evidence using the required `rest:read` / fine-grained `data_api_config_read` authorization.

The broader project-configuration endpoint was not substituted. It has a wider scope and would require a separate authorization and security assessment.

## Required next action

A project administrator should retrieve the two PostgREST configuration records through the supported endpoint, remove sensitive fields, retain the retrieval timestamp and project ref, and provide only the sanitized values needed to verify exposed schemas and API roles. This action must remain read-only.

## Limitations and unresolved questions

1. No authorized Management API token was available.
2. `db_schema`, `db_extra_search_path`, anonymous role, and OpenAPI mode remain unresolved.
3. The 401 response proves an authorization failure for this request path, not a project configuration state.
4. No staging or production setting was changed.

## References

- [Supabase Management API — Get PostgREST service config](https://supabase.com/docs/reference/api/v1-get-postgrest-service-config)
- [Supabase custom schemas and API exposure](https://supabase.com/docs/guides/api/using-custom-schemas)
