# SCHOLARS — SUPABASE AUTHENTICATION & ACCOUNT-CREATION AUDIT

**Date:** 24 November 2026
**Application:** https://scholars.com.ng
**Repository:** ImperioKDB/Scholars
**Supabase project:** `scholarship-platform`
**Project reference:** `cmdglabohpttgfofcmqc`
**Region:** `eu-west-1`
**Audit scope:** Read-only Supabase project, database metadata, database records aggregated without identity data, Supabase logs, and Supabase advisors. No settings, schemas, records, templates, SMTP configuration, or source code were changed.

## 1. Executive summary

**CONFIRMED — Supabase was not experiencing a complete signup outage during 24 November 2026.** The project was `ACTIVE_HEALTHY`. Auth logs for the UTC day recorded 46 successful `POST /signup` responses and 8 rejected signup responses. The 8 rejected requests returned HTTP 400 with `validation_failed` and the message `Unable to validate email address: invalid format`. This is a real signup-entry failure for those requests, but it does not explain all registration failures.

**CONFIRMED — Successful Auth user creation and profile provisioning were working.** During the same UTC day, 46 non-deleted Auth users were created. Of those, 44 were confirmed and 2 remained unconfirmed at query time. All 46 had a corresponding `public.profiles` row. This rules out a general failure of the Auth user insert or the normal profile-creation trigger path for the observed population.

**CONFIRMED — OTP verification failures occurred.** Auth logs recorded 37 successful `POST /verify` responses and 5 HTTP 403 responses with `otp_expired` and `token has expired or is invalid`. The available evidence does not distinguish whether each rejected code was genuinely past expiry, superseded by a resend, already consumed, or mismatched to the account/email. The error wording alone is insufficient to claim one mechanism.

**CONFIRMED — Authenticated sessions were being established.** The database contained 43 distinct users from the 24 November creation cohort with at least one session created during that day. Auth logs also recorded successful token and OTP login events. Session creation therefore works for a substantial portion of the successful path, although the available aggregate data cannot map each individual verification attempt to a session without exposing or processing identity-level records.

**UNVERIFIED — Email delivery is not established by this audit.** The available Supabase MCP surface did not expose the live Auth email-provider switch, SMTP credentials/status, email template body, provider acceptance/bounce records, SPF/DKIM/DMARC results, or inbox delivery. The database analytics table records application-side request outcomes, not proof that a message reached a student inbox. A password-reset success would not be proof of signup-confirmation delivery.

### Direct answer

The evidence identifies two confirmed failure points in the observed registration lifecycle: (1) some signup requests were rejected before user creation because Supabase rejected the submitted email format, and (2) some verification attempts failed with `otp_expired`. The primary backend components after signup—Auth user creation, profile creation, and session establishment—were functioning for the majority of the observed cohort. The evidence is insufficient to determine whether missing or delayed confirmation emails caused some of the OTP failures, because SMTP/provider/inbox evidence and user-level event correlation were not available. Therefore, no single universal root cause is proven.

## 2. Evidence and period covered

Unless otherwise stated, the numerical reconciliation covers **2026-11-24 00:00:00 UTC through 2026-11-25 00:00:00 UTC**. The local report date is 24 November 2026; UTC is used because Supabase log and database timestamps are timezone-aware and the log query was explicitly bounded to that 24-hour window.

Sources inspected:

- Supabase project metadata and health: project `cmdglabohpttgfofcmqc`.
- Supabase Auth logs (`auth_logs`) for the bounded 24-hour period.
- Supabase audit-log stream (`auth_audit_logs`) for the same period.
- Read-only PostgreSQL metadata and aggregated records.
- `auth.users`, `auth.sessions`, `auth.one_time_tokens` metadata.
- `public.profiles`, `public.auth_confirmation_email_events`, and `public.auth_rate_limits`.
- Database triggers, functions, constraints, and RLS policies.
- Supabase security, health, and performance advisors observed on 24 November 2026.

Student email addresses, names, OTP values, passwords, tokens, IP addresses, and access credentials are intentionally omitted.

## 3. Current live Supabase configuration

The following values were directly available:

| Item | Result | Status |
|---|---|---|
| Project status | `ACTIVE_HEALTHY` | **CONFIRMED** |
| Project region | `eu-west-1` | **CONFIRMED** |
| PostgreSQL version | 17.6.1.155 | **CONFIRMED** |
| Auth user table present | `auth.users` | **CONFIRMED** |
| OTP/token storage present | `auth.one_time_tokens`, including `confirmation_token` type and `expires_at` | **CONFIRMED** |
| Auth sessions present | `auth.sessions` | **CONFIRMED** |

The following requested live settings were **UNVERIFIED** because they were not exposed through the available read-only interfaces and were not inferred:

- Email provider enabled/disabled.
- Confirm-email setting.
- Current OTP length.
- Current OTP expiration.
- Minimum interval between OTP requests.
- Supabase signup and email-send rate limits.
- Auth Site URL.
- Additional redirect URLs.
- Signup email-template body and variables.
- SMTP provider, sender configuration, and operational status.
- SPF, DKIM, and DMARC status.

The previously supplied historical setting—six-digit OTP and 100-second expiry—was not treated as the current setting. The database schema confirms that confirmation tokens have an expiry field, but it does not reveal the live Auth configuration value. The production callback URL `https://scholars.com.ng/auth/callback`, and whether the `www` hostname is separately relevant, remain **UNVERIFIED**.

## 4. Signup and authentication log reconciliation

### 4.1 Auth API outcomes

| Endpoint/event | HTTP result | Count | Interpretation |
|---|---:|---:|---|
| `POST /signup` | 200 | 46 | Supabase accepted the signup requests |
| `POST /signup` | 400 | 8 | Rejected before successful signup completion; `validation_failed`, invalid email format |
| `POST /verify` | 200 | 37 | Verification requests succeeded at the Auth API level |
| `POST /verify` | 403 | 5 | `otp_expired`; token expired or invalid |
| `POST /resend` | 200 | 4 | Resend requests accepted |
| `POST /token` | 200 | 85 | Successful token-related requests, including refresh activity |
| `POST /token` | 400 | 2 | One `invalid_credentials`; one `email_not_confirmed` |

The Auth log query also recorded 75 token-based login events, 37 OTP login events, 9 PKCE login events, and 1 password login event. These are aggregate events and are not treated as unique users.

### 4.2 Account records and sessions

| Measure | Count |
|---|---:|
| Auth users created on 24 November | 46 |
| Confirmed by query time | 44 |
| Unconfirmed by query time | 2 |
| Created users with a `public.profiles` row | 46 |
| Created users with a session created during the day | 43 |
| Auth sessions created during the day, including repeat/refresh-related sessions | 46 distinct cohort users were checked; hourly session rows showed 46 session creations in the queried creation-day records |

The 46 users were created in the following UTC hours: 01:00 (2), 03:00 (1), 08:00 (2), 10:00 (2), 11:00 (1), 12:00 (3), 13:00 (1), 15:00 (24), and 16:00 (10). The two unconfirmed users were both in the 15:00 UTC creation group. This timing is correlation only; it does not prove that email delivery or OTP expiry caused their state.

### 4.3 Confirmation-email analytics table

The application-side table `public.auth_confirmation_email_events` contained the following aggregate outcomes for the day:

| Request kind | Status | Error code | Count |
|---|---|---|---:|
| signup | accepted | none recorded | 44 |
| signup | failed | `auth_error` | 2 |
| resend | accepted | none recorded | 4 |
| resend | failed | none recorded | 1 |

These rows show application instrumentation around confirmation-email requests. They do **not** prove SMTP acceptance, receiving-server acceptance, inbox delivery, or that the template contained the expected OTP. The count of accepted signup email events (44) differs from successful `/signup` HTTP responses (46), so these two datasets should not be treated as interchangeable without user-level correlation and knowledge of the instrumentation path.

## 5. Signup email template, SMTP, and delivery analysis

### 5.1 Template inspection

**UNVERIFIED.** The live Supabase Auth email template was not available through the read-only project/database interfaces used for this audit. Consequently, this audit cannot confirm:

- Whether the template uses the correct manually-entered OTP variable.
- Whether the message contains a six-digit code.
- Whether a confirmation URL is present.
- Whether URL instructions conflict with manual OTP instructions.
- Whether the sender identity and domain are configured as intended.

### 5.2 Delivery chain

The following distinctions are important:

1. **Supabase accepted signup:** confirmed for 46 requests with HTTP 200.
2. **Supabase/application generated or recorded a confirmation-email request:** partially evidenced by 44 accepted signup analytics events and four accepted resend events.
3. **SMTP accepted the message:** **UNVERIFIED**.
4. **Receiving mail server accepted the message:** **UNVERIFIED**.
5. **Message reached the student inbox:** **UNVERIFIED**.
6. **Student received the correct code and entered it before expiry:** **UNVERIFIED**.

No provider-specific SMTP acceptance, rejection, bounce, defer, or rate-limit records were available. Brevo/Resend application email delivery was not used as evidence for Supabase Auth confirmation delivery, because these are separate delivery paths.

## 6. OTP failure analysis

**CONFIRMED:** The current-day Auth logs contain five HTTP 403 verification failures with error code `otp_expired` and message `token has expired or is invalid`.

**UNVERIFIED:** The available records do not establish which of the following caused each failure:

- The configured expiry elapsed before submission.
- A resend superseded the prior code.
- The code had already been consumed.
- The code did not match the account/email.
- Email delay caused a valid code to be entered after expiry.
- A client-side or route-level mismatch sent the wrong value.

The current live OTP length, expiry, resend interval, and Auth rate limits were not exposed by the available interfaces. The `auth.one_time_tokens` table includes `confirmation_token`, `token_hash`, `relates_to`, `created_at`, `updated_at`, and `expires_at`, but inspecting token hashes or raw tokens would not establish the student's received-message timing and was not necessary for this privacy-preserving audit.

The 4 accepted resends and 1 failed resend in the application analytics table show resend activity, but they cannot be joined to the five OTP failures without identity-level correlation. Therefore, resend invalidation is a plausible contributing factor, not a confirmed root cause.

## 7. Database account creation, triggers, constraints, and RLS

### 7.1 Trigger path

**CONFIRMED:** `auth.users` has the trigger:

```sql
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION handle_new_user()
```

The live function is a `SECURITY DEFINER` function with an empty search path and inserts a profile using the new Auth user ID and a name derived from `raw_user_meta_data.full_name` or the email local part. It uses `ON CONFLICT (id) DO NOTHING` and returns the new row.

The relevant profile triggers observed are:

- `guard_community_invitation_consent` — before insert/update.
- `trg_profiles_completeness` — before insert/update.
- `trg_profiles_updated_at` — before update.
- `on_profile_referral_completion` — after insert/update.

### 7.2 Constraints and defaults

The `profiles.id` primary key is also a foreign key to `auth.users.id`. The profile table has defaults for the required boolean, integer, enum, and timestamp fields. `full_name` is nullable. The trigger's minimal insert of `(id, full_name)` is therefore structurally compatible with the live table.

**CONFIRMED for the observed period:** 46 users created on 24 November all had profiles. This is direct evidence that the trigger and profile defaults were successful for all observed created users.

### 7.3 RLS

`public.profiles` has RLS enabled and includes policies for own insert/select/update/delete plus administrative access. The automatic profile insert is performed by the `SECURITY DEFINER` trigger function, not by the student's client-side authenticated request, and the observed 46/46 profile coverage shows no general RLS block on this path.

RLS and advisor findings do warrant a separate security review, but the observed findings do not explain the registration failures:

- Six tables have RLS enabled with no policies, including `public.auth_rate_limits`; this is a security/authorization concern, not evidence of an Auth signup outage.
- Several security-definer functions are callable by anonymous or authenticated roles, including `handle_new_user` and the confirmation analytics function; this is a security-boundary concern and should be reviewed separately.
- Leaked-password protection is disabled; this does not explain invalid-email or OTP-expired errors.

## 8. Supabase advisor findings relevant to this audit

The project was healthy, but the security advisor reported:

- Six RLS-enabled tables without policies, including `public.auth_rate_limits`.
- Six security-definer views.
- Two functions with mutable search paths.
- Twenty anonymous-executable security-definer functions and 23 authenticated-executable security-definer functions.
- Leaked-password protection disabled.

These are **CONFIRMED security findings**, observed on 24 November 2026, but they are **not confirmed causes** of the observed signup, OTP, or profile-creation failures. The performance advisor reported unindexed foreign keys and auth-RLS initialization-plan warnings; these are not evidence of a registration-blocking fault at the observed scale.

## 9. Confirmed root causes and contributing factors

### Confirmed

1. **Invalid email-format requests blocked signup before account creation.** Eight `POST /signup` requests returned HTTP 400 with `validation_failed` and `Unable to validate email address: invalid format`. These requests are confirmed signup-entry failures.
2. **Invalid/expired OTP verification attempts blocked completion for five requests.** Five `POST /verify` requests returned HTTP 403 with `otp_expired`. The exact underlying mechanism for each is not confirmed.
3. **Two created accounts remained unconfirmed at query time.** This is confirmed from `auth.users`; the cause is not directly identified.

### Contributing factors that are plausible but not established

- A short OTP lifetime relative to email delivery and student response time.
- Resends superseding earlier codes.
- Template confusion between a confirmation URL and manually entered OTP.
- SMTP/provider delay, rejection, deferral, or inbox filtering.
- Client submission of malformed email addresses for the eight rejected requests.

## 10. Ruled-out or substantially discounted causes

- **General Supabase outage:** **RULED OUT** for the audited period. The project was active and healthy, and successful signup, verify, token, profile, and session events were observed.
- **Universal failure to create Auth users:** **RULED OUT.** Forty-six users were created on the audit date.
- **Universal failure of profile trigger/provisioning:** **RULED OUT for the observed cohort.** All 46 created users had profiles.
- **Universal failure to establish sessions:** **RULED OUT.** Forty-three cohort users had sessions created during the day, and successful token/OTP logins were present.
- **Brevo/Resend application email as proof of Supabase Auth email delivery:** **RULED OUT as an evidentiary shortcut.** The paths are separate and were not conflated.
- **Database profile NOT NULL/default constraints as a general blocker:** **RULED OUT for the observed cohort.** The minimal trigger insert succeeded for all 46 created users.

## 11. Unverified hypotheses

The following cannot be confirmed from the available evidence:

- Current Auth email provider and SMTP health.
- Current confirm-email setting.
- Current OTP length and expiration.
- Whether resending invalidates prior codes in the current configuration.
- Whether the callback URL is allowed and whether `www.scholars.com.ng` is correctly covered.
- Whether the signup template uses the correct OTP variable and avoids conflicting links.
- Whether the two unconfirmed users failed because of email non-delivery, delayed delivery, expired OTPs, or user abandonment.
- Whether any of the five OTP failures correspond to the two currently unconfirmed users.

## 12. Recommended corrective actions

1. Inspect and record the live Auth settings in the Supabase Dashboard or Management API: provider, confirm-email, OTP length/expiry, resend interval, signup/email rate limits, Site URL, and redirect allowlist. Do not change them as part of the audit.
2. Export the live signup-confirmation template with secrets and personal data redacted. Verify the OTP variable, code length, link instructions, sender address, and sender domain.
3. Obtain SMTP/provider event evidence for the same UTC period: accepted, rejected, bounced, deferred, throttled, and delivered/complained states. Correlate by hashed message/user identifiers rather than exposing email addresses.
4. Correlate signup, confirmation-email request, resend, verification, and session events by a privacy-preserving pseudonymous user key. This is the smallest dataset needed to determine whether the five OTP failures are primarily expiry, supersession, mismatch, or non-delivery related.
5. Validate both `scholars.com.ng` and `www.scholars.com.ng` production flows against the callback allowlist without creating a new account or triggering an OTP; use an existing controlled test identity only if separately authorized.
6. Review the security advisor findings, especially anonymous execution of security-definer functions and RLS configuration, as a separate security-hardening workstream. Do not conflate these findings with the confirmed registration blockers.
7. Review the eight invalid-email requests at the application boundary to determine whether the submitted values were malformed, transformed, or incorrectly encoded. This is a code-side/client-side follow-up and is outside this backend-only audit.

## 13. Controlled verification plan

The smallest controlled test that would establish the remaining root cause is a single authorized test registration using a controlled mailbox and a unique test address, with no production data changes beyond the normal test account. Record timestamps for: signup request, Auth user creation, confirmation-email generation, SMTP acceptance, mailbox receipt, code entry, verification response, and session creation. Repeat once with no resend and once with one resend only if the first controlled run demonstrates the normal path and the test is approved. Compare the recorded times with the live OTP expiry and resend behavior.

If test-account creation is not permitted, use a provider-side message trace for one existing affected request plus privacy-preserving Auth event correlation. Without either a controlled end-to-end trace or provider delivery evidence, the audit cannot distinguish OTP expiry/supersession from email non-delivery.

## 14. Final conclusion

Students are not being blocked by a universal inability of Supabase to create Auth users, by a universal profile trigger failure, or by a universal session-creation failure. On 24 November 2026, Supabase successfully created 46 users, confirmed 44, provisioned profiles for all 46, and established sessions for 43 cohort users.

The confirmed blockers are narrower: eight signup requests were rejected because the submitted email format was invalid, and five verification attempts were rejected with `otp_expired`. For the students who remain unable to complete registration, the most likely backend completion boundary is the confirmation/OTP stage, but the evidence does not prove whether the operative mechanism is genuinely short expiry, resend invalidation, a mismatch, or email delivery delay/non-delivery. SMTP, template, live Auth settings, redirect configuration, and inbox delivery therefore remain **UNVERIFIED**.

The correct conclusion is not to delete or recreate the Supabase project. The next step is a privacy-preserving, controlled end-to-end trace of one registration, or equivalent provider message-trace evidence, while separately correcting the invalid-email input path and reviewing the OTP/confirmation experience.
