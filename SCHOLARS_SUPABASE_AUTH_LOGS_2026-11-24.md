# Scholars — Supabase Auth Logs Report

**Project:** `scholarship-platform`  
**Project reference:** `cmdglabohpttgfofcmqc`  
**Region:** `eu-west-1`  
**Report date:** 2026-11-24  
**Inspection window:** 2026-11-24 00:00:00+01:00 through 2026-11-24 16:30:42+01:00 (`2026-11-24T15:30:42Z`)  
**Sources inspected:** `auth_logs`, `auth_audit_logs`  

## Executive summary

The live Supabase Auth logs show normal, active authentication traffic for the production `scholarship-platform` project. The inspection returned **5,988 `auth_logs` records** and **152 `auth_audit_logs` records**, for **6,140 Auth-related records** in total.

Most traffic was successful session validation: **5,584 `GET /user` requests returned HTTP 200**. There were also **168 successful `GET /admin/users` requests**, 24 successful signups, 6 recorded login audit events, 65 token refreshes, and 28 token revocations.

The main items requiring review are **8 HTTP 400 signup requests**, **3 HTTP 403 verification requests**, and **1 HTTP 400 token request**. These could be caused by normal invalid input, duplicate registrations, expired or incorrect verification codes, or invalid token requests. The export does not show a large failed-login or brute-force pattern.

## Volume by log source

| Log source | Records |
|---|---:|
| `auth_logs` | 5,988 |
| `auth_audit_logs` | 152 |
| **Total** | **6,140** |

## Auth request activity

| Endpoint or event | Count | Result breakdown |
|---|---:|---|
| `GET /user` | 5,584 | 5,584 × HTTP 200 |
| `GET /admin/users` | 168 | 168 × HTTP 200 |
| `POST /token` | 71 | 70 × HTTP 200; 1 × HTTP 400 |
| `POST /signup` | 33 | 25 × HTTP 200; 8 × HTTP 400 |
| `POST /verify` | 24 | 21 × HTTP 200; 3 × HTTP 403 |
| OAuth authorization/callback | 8 | 4 × HTTP 302 authorization; 4 × HTTP 302 callback |
| OAuth provider redirects | 4 | External-provider redirect messages |
| `POST /recover` | 2 | 2 × HTTP 200 |
| `POST /resend` | 2 | 2 × HTTP 200 |
| `POST /logout` | 1 | 1 × HTTP 204 |
| Login request messages | 91 | Informational `Login` messages |

## Audit events

| Audit action | Count | Details |
|---|---:|---|
| `token_refreshed` | 65 | Token events |
| `token_revoked` | 28 | Token events |
| `user_confirmation_requested` | 27 | 25 email-provider events; 2 without a provider value |
| `user_signedup` | 24 | 21 email signups; 3 Google signups |
| `login` | 6 | 5 Google logins; 1 email login |
| `user_recovery_requested` | 1 | Recovery event |
| `logout` | 1 | Account event |
| **Total** | **152** | |

## Non-success responses

| Endpoint | Status | Count | Interpretation to verify |
|---|---:|---:|---|
| `POST /signup` | 400 | 8 | Possible invalid input, duplicate email, or signup validation failure |
| `POST /verify` | 403 | 3 | Possible invalid or expired verification code, or denied verification attempt |
| `POST /token` | 400 | 1 | Possible malformed, expired, or invalid token request |

These records should be correlated with the corresponding request IDs and application context before treating them as security incidents. No destructive action or configuration change was made during this inspection.

## Admin endpoint activity

The project recorded **168 successful `GET /admin/users` requests** during the inspection window. If the admin dashboard was intentionally active, this may be expected. If it was not, review the authenticated user/session associated with those requests and confirm the endpoint's authorization and RLS protections.

## Request performance

For **5,893 completed Auth requests** with a recorded duration:

| Metric | Duration |
|---|---:|
| Minimum | 0.19 ms |
| Median | 2.69 ms |
| 95th percentile | 71.44 ms |
| Maximum | 1.60 s |

Most Auth requests completed quickly, with one or more slower outliers. The maximum duration should be correlated with its request ID if latency becomes user-visible.

## Assessment

1. **No broad authentication outage is visible.** The majority of Auth requests completed successfully.
2. **No large failed-login or brute-force pattern is visible** in the summarized logs for this window.
3. **Signup and verification failures are the main error cluster** and should be checked against expected user behavior.
4. **Repeated `/user` traffic is substantial** and may reflect normal session checks, middleware, or client-side polling.
5. **Admin-user endpoint activity deserves confirmation** if the admin interface was not expected to be in use.

## Method and privacy note

This report summarizes the live Supabase unified logs using read-only queries. It intentionally excludes raw user emails, user-agent strings, IP addresses, access tokens, and request identifiers from the report to avoid unnecessarily duplicating sensitive authentication metadata. The report is an operational summary, not a definitive security incident determination.
