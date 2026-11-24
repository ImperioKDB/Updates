# SCHOLARS — LIVE AUTH CONFIGURATION & CONFIRMATION EMAIL DELIVERY AUDIT

**Date:** 24 November 2026
**Application:** https://scholars.com.ng
**Repository:** ImperioKDB/Scholars
**Supabase project:** `scholarship-platform`
**Project reference:** `cmdglabohpttgfofcmqc`
**Region:** `eu-west-1`
**Scope:** Read-only investigation of live Auth configuration, signup-confirmation email configuration, SMTP/provider evidence, and OTP timing. No production settings, templates, database records, schemas, source code, or users were changed.

## Executive conclusion

**CONFIRMED:** The Supabase project is active and healthy, and the Auth API is processing signup, resend, verification, and token requests. In the current 24 November UTC window, the Auth logs available at approximately **19:43 UTC** recorded 53 successful `POST /signup` responses and 8 rejected signup responses. The rejected signup errors were `validation_failed` with `Unable to validate email address: invalid format`.

**CONFIRMED:** The same log window recorded 43 successful `POST /verify` responses and 5 HTTP 403 responses with `otp_expired` / `token has expired or is invalid`. The application-side confirmation-email analytics table recorded 51 accepted signup requests, 2 failed signup requests, 4 accepted resend requests, and 1 failed resend request for the date. These are request-level instrumentation events, not proof of SMTP acceptance or inbox delivery.

**CONFIRMED:** As of the same read-only snapshot, 55 Auth users had been created during 24 November, 53 were confirmed, 2 were unconfirmed, all 55 had profile rows, and 52 had a session created during the day. This continues to show that the platform is not experiencing a universal Auth-user, profile, or session failure.

**UNVERIFIED:** The available authorized interfaces did not expose the live Supabase Auth settings, production signup-confirmation template, SMTP provider configuration, SMTP event stream, receiving-server acceptance, or inbox delivery. The Supabase dashboard redirected to its sign-in page in the available browser, and no authenticated dashboard session was available. The Supabase project tools provided database/log access but no management endpoint for these Auth settings.

**FINAL ANSWER:** This investigation cannot confirm that the live Auth configuration is correct, that the confirmation template is correct, or that SMTP is functioning. It can confirm that signup and verification requests are reaching Supabase and that some verification attempts are rejected as expired/invalid. Email delivery delay remains a plausible but unproven contributor to the OTP failures. The first safe corrective action is not a configuration change: obtain read-only dashboard/provider access or a provider message trace for one affected request, then compare message timestamps with the actual OTP expiry and resend behavior.

## 1. Access and evidence boundaries

### Access obtained

- Supabase project metadata: available; project status `ACTIVE_HEALTHY`.
- Read-only PostgreSQL metadata and aggregate queries: available.
- Supabase unified logs for the specified 24-hour window: available.
- Application-side `public.auth_confirmation_email_events`: available in aggregate.
- Supabase Dashboard Auth pages: navigation reached the project URL, but the page redirected to `https://supabase.com/dashboard/sign-in`; no authenticated dashboard access was available.

### Access not obtained

The following were not exposed by the available Supabase project tools and could not be safely inferred:

- Live Auth provider switches and email-confirmation setting.
- Current OTP length and expiration.
- Minimum resend interval.
- Signup and email-send rate limits.
- Auth Site URL and complete redirect allowlist.
- Signup-confirmation template body and variables.
- SMTP provider name, sender identity, SMTP status, or credentials.
- SMTP accepted/rejected/bounced/deferred/delivered events.
- Receiving mail-server acceptance or student inbox delivery.
- Provider-specific sending restrictions or account limitations.

These items are marked **UNVERIFIED** throughout this report.

## 2. Actual live Auth settings

| Setting requested | Result | Classification |
|---|---|---|
| Email authentication enabled | Not exposed by available tools; dashboard requires sign-in | **UNVERIFIED** |
| Email confirmation required | Not exposed | **UNVERIFIED** |
| Current OTP length | Not exposed; historical six-digit behavior is not treated as current configuration | **UNVERIFIED** |
| Current OTP expiration | Not exposed; historical 100-second value is not treated as current configuration | **UNVERIFIED** |
| Minimum resend interval | Not exposed | **UNVERIFIED** |
| Signup rate limits | Not exposed | **UNVERIFIED** |
| Email-send rate limits | Not exposed | **UNVERIFIED** |
| Auth Site URL | Not exposed | **UNVERIFIED** |
| Complete redirect URL allowlist | Not exposed | **UNVERIFIED** |
| `https://scholars.com.ng/auth/callback` allowed | Cannot inspect allowlist | **UNVERIFIED** |
| `https://www.scholars.com.ng/auth/callback` allowed | Cannot inspect allowlist | **UNVERIFIED** |

The Supabase project itself was reported as `ACTIVE_HEALTHY`, region `eu-west-1`, PostgreSQL 17.6.1.155. This is project/database health evidence, not proof that the Auth email configuration is correct.

## 3. Live signup-confirmation template

### Template retrieval result

**UNVERIFIED / INACCESSIBLE.** The actual production signup-confirmation template could not be retrieved because the available dashboard session was unauthenticated and the project tools do not provide a template-read endpoint.

Accordingly, the following cannot be confirmed:

- Subject.
- Sender identity.
- Sender domain.
- Whether the template uses `{{ .Token }}`.
- Whether a confirmation URL variable is present.
- Whether the template is designed for manually entered OTP verification.
- Whether the instructions contain a conflicting URL and manual-code flow.
- Whether the displayed code format matches the configured OTP length.
- Whether the message references the correct production domain.

### Redacted template copy

No redacted copy is included because no production template content was retrieved. Manufacturing or reconstructing a template from historical assumptions would not satisfy the audit objective.

Required evidence to complete this section: a read-only export or screenshot/text capture of the live **Confirm signup** Auth template, with any secrets and personal data redacted. The password-reset template must not be substituted for the signup-confirmation template.

### Specific `{{ .Token }}` check

**UNVERIFIED.** Use of `{{ .Token }}` for manually entered OTP verification could not be inspected.

## 4. SMTP provider identification

**UNVERIFIED.** The current Supabase Auth SMTP provider cannot be identified from the available project/database/log interfaces. No provider name, sender address, sender domain, SMTP operational status, or account restriction data was exposed.

The application’s Brevo/Resend integration was deliberately not treated as evidence of Supabase Auth SMTP configuration. These are separate delivery paths. A successful application email or password-reset email would not prove that signup-confirmation emails are being sent through the same provider or template.

No SMTP username, password, API key, token, or credential was accessed or printed.

## 5. Delivery evidence for 24 November 2026

### Auth API request outcomes

The following counts are from the Auth log query bounded to `2026-11-24T00:00:00Z` through `2026-11-25T00:00:00Z`; the day was still in progress when the snapshot was taken.

| Operation | Status | Count | What it proves |
|---|---:|---:|---|
| `POST /signup` | 200 | 53 | Supabase accepted the signup request |
| `POST /signup` | 400 | 8 | Supabase rejected the request; all classified as invalid email format |
| `POST /verify` | 200 | 43 | Verification request succeeded at the Auth API level |
| `POST /verify` | 403 | 5 | Verification failed with `otp_expired` / expired or invalid token |
| `POST /resend` | 200 | 4 | Resend requests were accepted by Auth |
| `POST /token` | 200 | 108 | Token operations succeeded, including refresh activity |

Additional token failures were recorded, including six `refresh_token_already_used`, three `invalid_credentials`, one `email_not_confirmed`, and one missing-email-or-phone validation error. These are not evidence of SMTP delivery status.

### Application-side confirmation-email analytics

For the same calendar-day window, `public.auth_confirmation_email_events` contained:

| Request kind | Status | Error code | Count |
|---|---|---|---:|
| signup | accepted | none recorded | 51 |
| signup | failed | `auth_error` | 2 |
| resend | accepted | none recorded | 4 |
| resend | failed | none recorded | 1 |

The associated analytics function joins these request events to `auth.users.email_confirmed_at`, but it does not expose SMTP provider events or inbox delivery. Therefore:

1. **Supabase accepted signup:** **CONFIRMED** for 53 log events.
2. **An application-side confirmation request was accepted/recorded:** **CONFIRMED** for 51 signup analytics events and 4 resend analytics events.
3. **SMTP accepted the message:** **UNVERIFIED**.
4. **The receiving mail server accepted the message:** **UNVERIFIED**.
5. **The message reached the student inbox:** **UNVERIFIED**.
6. **The student received the correct OTP before expiry:** **UNVERIFIED**.

An HTTP 200 response is not being treated as proof of delivery.

## 6. OTP expiry assessment

### Observed failures

**CONFIRMED:** Five verification requests returned HTTP 403 with `otp_expired` and `token has expired or is invalid`.

**UNVERIFIED:** The available data cannot distinguish among:

- Actual expiry before code entry.
- A newer resend superseding the earlier code.
- Reuse of an already consumed code.
- Code/account/email mismatch.
- Email transport delay or inbox filtering.
- Client-side submission or routing mismatch.

The current OTP expiry and length were not accessible. The previous reported six-digit/100-second values were historical and were not used as current settings.

### Delivery-delay comparison

**UNVERIFIED.** No SMTP accepted, delivered, deferred, bounced, or mailbox-received timestamps were available. Therefore, the audit cannot compare delivery latency with the actual current OTP expiration interval and cannot establish that messages were delayed long enough to expire.

### Resend invalidation

**UNVERIFIED.** Four accepted resend requests were observed, but they could not be linked to the five rejected verification attempts in the available privacy-preserving aggregate data. Resend invalidation is a plausible hypothesis, not a confirmed cause.

## 7. Redirect URL assessment

**UNVERIFIED.** The complete Auth redirect allowlist could not be inspected. The two requested callback URLs therefore cannot be classified as allowed or disallowed:

- `https://scholars.com.ng/auth/callback`
- `https://www.scholars.com.ng/auth/callback`

The prior logs showed requests with both production hostnames in referer fields in the broader audit context, but that does not prove that both callback URLs are on the Auth allowlist.

## 8. Account and session cross-check

The current read-only database snapshot for users created on 24 November showed:

| Measure | Count |
|---|---:|
| Auth users created | 55 |
| Confirmed | 53 |
| Unconfirmed | 2 |
| Users with a profile row | 55 |
| Users with a session created during the day | 52 |

**CONFIRMED:** User creation, profile provisioning, and session establishment are functioning for the majority of the observed cohort. This does not prove that confirmation email delivery is functioning for every student.

## 9. Findings by classification

### CONFIRMED

- The project is active and healthy.
- Signup, verification, resend, and token requests are reaching Supabase Auth.
- Eight signup requests were rejected due to invalid email format.
- Five verification requests failed with `otp_expired`.
- Application-side confirmation-email request instrumentation recorded accepted and failed requests.
- 55 users had been created in the current 24 November snapshot; 53 were confirmed.
- All 55 users in that cohort had profiles; 52 had sessions created during the day.

### UNVERIFIED

- Current live Auth email provider and confirmation settings.
- Current OTP length, expiry, resend interval, and Auth rate limits.
- Site URL and redirect allowlist.
- Both production callback URLs.
- Signup-confirmation email subject, sender, template variables, and instructions.
- Whether the template uses `{{ .Token }}`.
- SMTP provider and operational status.
- SMTP acceptance, receiving-server acceptance, delivery, bounce, deferral, throttling, and complaint events.
- Whether delivery delays explain the five OTP failures.
- Whether resend invalidation explains any OTP failures.

### RULED OUT

- A universal Supabase signup outage during the observed period.
- A universal Auth-user creation failure.
- A universal profile-creation failure.
- A universal session-establishment failure.
- Treating Brevo/Resend application email as evidence of Supabase Auth email delivery.

## 10. Configuration defects

No configuration defect can be confirmed without access to the live Auth settings and production template.

The following are therefore **UNVERIFIED**, not defects:

- OTP expiration being too short.
- Missing or incorrect confirmation-email template variable.
- Conflicting URL and manual OTP instructions.
- SMTP misconfiguration.
- Missing callback allowlist entries.
- Provider throttling or domain-authentication failure.

## 11. Safe corrective actions

### RECOMMENDATION — obtain read-only evidence first

Obtain authorized read-only Supabase Dashboard access or an official management-interface export for Auth providers, URL configuration, rate limits, and email templates. Do not change any values while collecting evidence.

### RECOMMENDATION — obtain one provider message trace

Request a provider-side trace for one affected signup using a hashed/pseudonymous identifier. Required states are: generated, accepted by SMTP, rejected, bounced, deferred, delivered, and complained/spam where available. Do not request or disclose a password, OTP, API key, or full student address in the audit report.

### RECOMMENDATION — correlate one controlled existing event

If provider evidence is available, correlate one signup, confirmation-email event, resend, verification attempt, and session by a privacy-preserving key. No test account, test email, resend, or OTP generation should be triggered as part of this audit.

### RECOMMENDATION — address confirmed invalid-email failures separately

The eight invalid-format signup requests are a confirmed failure category. The smallest safe corrective action is to inspect the rejected request inputs and validation path, without changing Supabase settings or creating accounts. This is an application-boundary follow-up, not an SMTP conclusion.

## 12. Required evidence to close the remaining gaps

To replace the **UNVERIFIED** labels, the next investigator needs:

1. Auth Providers settings screenshot/export.
2. Auth URL Configuration screenshot/export.
3. Auth Rate Limits screenshot/export.
4. Redacted production **Confirm signup** template.
5. SMTP provider configuration/status screen with credentials redacted.
6. Provider event trace for 24 November, or at least one affected message.
7. A timestamp correlation between SMTP acceptance/delivery and OTP verification.

## Final answer

1. **Is the live Auth configuration correct?** **UNVERIFIED.** It could not be inspected because the dashboard session was unauthenticated and the available project tools do not expose these management settings.
2. **Is the confirmation template correct?** **UNVERIFIED.** The live template, including `{{ .Token }}`, could not be retrieved.
3. **Is SMTP functioning?** **UNVERIFIED.** No SMTP provider or provider delivery records were available. Application-side accepted request events are not SMTP proof.
4. **Could email delivery delays explain OTP failures?** **Plausible but UNVERIFIED.** Five OTP failures are confirmed, but no delivery timestamps or current expiry value were available for comparison.
5. **What should be corrected first?** Obtain read-only Auth/template/provider evidence first, then address the confirmed invalid-email request path. Do not change OTP settings, templates, SMTP, redirects, database records, or source code until the evidence identifies a specific defect.

No production changes were made by this investigation.
