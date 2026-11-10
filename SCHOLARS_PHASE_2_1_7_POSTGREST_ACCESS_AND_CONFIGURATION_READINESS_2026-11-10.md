# Scholars Phase 2.1.7 — PostgREST Access and Configuration Readiness

**Status:** BLOCKED — administrator authorization unavailable
**Evidence date:** 2026-11-10
**Author:** Manus AI

## Finding

No approved token or connector capability for the supported PostgREST configuration GET is available to this session. The previously inspected Supabase connector did not expose OAuth scopes or this endpoint. No Management API request was made. Production and staging configuration values are **UNKNOWN**, not unset.

The supported endpoint is `GET /v1/projects/{ref}/postgrest`. The current documentation requires OAuth scope `rest:read` and fine-grained permission `data_api_config_read`; it does not require the secret-read alternative. The example response schema includes a `jwt_secret` property, so a successful response must be filtered to an allowlist before anything is displayed or saved. Never request `data_api_config_secret_read`. [1]

## Exact evidence to collect

The administrator should perform separate reads for production `cmdglabohpttgfofcmqc` and staging `aqhktriwaglvvrchxmtd`, using a short-lived token limited to these projects and the minimum permission above. Record only project ref, timestamp, HTTP status, `db_schema`, `db_extra_search_path`, `max_rows`, `db_pool`, and the documented pool timeout/lifetime fields if returned. Omit all unapproved fields, especially `jwt_secret`; do not save or print the unfiltered response.

Use the Supabase Dashboard’s supported API configuration read or an administrator-controlled script with the token injected via a secret manager or process environment. Disable shell tracing and HTTP debug logging. Keep the raw response in memory only; emit a sanitized allowlist record and discard the raw response. A PAT must not be copied into chat, a report, a command-line argument, or a public repository.

The endpoint does not establish every requested setting. Anonymous database role and OpenAPI mode must remain **UNKNOWN** unless the administrator obtains them through a supported non-secret settings view. Do not infer them from route behavior or call broader/experimental endpoints. [1] [2]

## Administrator action

A Supabase organization/project administrator must create or use a short-lived fine-grained authorization with `rest:read` and `data_api_config_read` for both named projects, with no secret-read permission, then deliver the sanitized output through the approved private channel. The current task did not create a token or change settings.

## References

[1]: https://supabase.com/docs/reference/api/v1-get-postgrest-service-config "Supabase Management API Get PostgREST Configuration"
[2]: https://supabase.com/docs/reference/api/introduction "Supabase Management API Authentication"
