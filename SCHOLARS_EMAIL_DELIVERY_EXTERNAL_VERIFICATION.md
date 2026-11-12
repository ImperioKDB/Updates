# Scholars Email Delivery External Verification

**Repository:** `ImperioKDB/Scholars`  
**Audit reports:** `ImperioKDB/Updates` commit `866541a`  
**Verification date:** 12 November 2026  
**Scope:** Read-only verification only. No Supabase, Brevo, DNS, application, deployment, or credential changes were made.

## Verification result

This follow-up closed the evidence gaps that were reachable through the authorized read-only connections, but it could not verify the provider dashboards or run a controlled mailbox experiment. The connected Supabase project is active and healthy. Its unified logs show real Auth activity, including successful OTP verification, an expired-token failure, and an email-send rate-limit rejection. Those logs do not expose the configured OTP length, template bodies, SMTP host/port/security mode, sender, or provider delivery events.

Brevo operational verification was blocked at the account boundary: the available browser session redirected to the Brevo login page, and no Brevo account/API connector was available. No credits, quotas, SMTP activity, delivery events, queue, suppression list, or sender-authentication dashboard state is asserted here. No controlled signup, resend, or recovery email was sent because no designated test recipients or authenticated provider access were available.

The six-versus-eight-digit discrepancy remains unresolved at the live Supabase configuration boundary. The deployed Scholars frontend is confirmed by source and production deployment metadata to expect six digits. The current shared component renders six input boxes and six-digit copy. Supabase's current public documentation also describes `{{ .Token }}` as a six-digit OTP. The prior report's eight-digit observation remains evidence of historical drift, not proof of the current live setting.

## Supabase project and production deployment

The authorized Supabase project is `cmdglabohpttgfofcmqc`, named `scholarship-platform`, in `eu-west-1`. The project status returned `ACTIVE_HEALTHY`, with Postgres 17.6.1.155. No settings were changed.

The production Vercel deployment for the audited Scholars commit is `READY` and points to commit `137f2fa28a4f1a5b1fb6eaa55e3c6c3677bb4210`. The public production signup page loads normally. The source at that deployed commit defines `OTP_LENGTH = 6`; `AuthOtp` uses six inputs and tells users that a six-digit code was sent. The signup, login rescue, and password-recovery paths all use this shared component and Supabase `verifyOtp`.

Production Vercel environment metadata confirms that the application has server-only variables named `BREVO_API_KEY` and `REMINDER_FROM_EMAIL`, but values were not decrypted or exposed. Those variables belong to the application's separate Brevo API sender path. Their presence does not prove that Supabase Auth SMTP is configured with Brevo or that Auth messages use the same sender.

## Measured Supabase Auth evidence

The following read-only log window was queried in UTC: **2026-11-11 08:00:00 through 2026-11-12 08:00:00**. Counts are privacy-preserving aggregates; no email addresses, tokens, raw request bodies, or user identities are included in this report.

- `auth_audit_logs`: 28 confirmation-request events and 14 user-signup events.
- `auth_logs`: 28 confirmation-request events and 14 user-signup events.
- OTP verification outcomes in `auth_logs`: 13 responses with status 200, 2 responses with status 303, and 2 verification records without a parsed status value.
- One verification failure had error code `otp_expired` and HTTP status 403.
- One signup attempt had error code `over_email_send_rate_limit` and HTTP status 429.
- No matching SMTP error was returned by the aggregate query.

The audit and request streams duplicate some logical events, so the two source counts must not be added together as unique user actions. The logs prove that the Auth API is receiving requests and that at least some OTP verifications succeed. They do not prove message delivery or inbox placement. The one rate-limit rejection is direct evidence that at least one Auth email request was refused by an Auth sending limit during the window; it is not evidence of a general Brevo queue bottleneck.

The previously inspected application analytics table remains request-level instrumentation. For the preceding 30 days it contained 191 accepted confirmation/resend events and 14 failed signup events, with 58 accepted events associated with a subsequently confirmed account. That table still has no provider message ID or delivery timestamp.

## Supabase configuration verification status

The Supabase dashboard URL for the project was opened in the sandbox browser, but it redirected to Supabase's sign-in page. The available Supabase MCP connection exposes project metadata, SQL, and unified logs, not the hosted Auth configuration object. Consequently the following live values remain **unverified**:

- Email OTP length: six or eight digits.
- OTP expiry duration.
- Confirm-signup and recovery template subjects and bodies.
- SMTP host, port, TLS/security mode, and sender.
- Auth email rate-limit configuration beyond observed log outcomes.
- Whether a Send Email Hook is enabled.

No attempt was made to sign in, request credentials, change settings, or call a management endpoint with an unavailable access token.

## Brevo operational verification status

The Brevo transactional-statistics URL redirected to `login.brevo.com`. No authenticated Brevo session was available, and no Brevo MCP connector or decrypted API credential was used. Therefore these items remain unverified:

- Current sending status and account restrictions.
- Available credits and quotas.
- Recent SMTP/API activity.
- Sent, delivered, deferred, rejected, bounced, blocked, spam, or error events.
- Queued or delayed messages.
- Suppression/blocklist state.
- Sender and domain authentication state.

The repository's server-side Brevo helper confirms that application-originated non-Auth messages call Brevo's transactional API, but that code path is separate from the browser's Supabase Auth calls. No current Brevo bottleneck can be established from the available access.

## Controlled delivery experiment

No test email was sent. The request required designated Gmail and Outlook recipients, but none were supplied in the task and no authorized Brevo/Supabase dashboard session was available to observe provider events. Sending to real users or creating unnecessary production accounts would violate the read-only and controlled-test restrictions.

The exact missing inputs for execution are:

1. One designated Gmail address and one designated Outlook address whose owners have authorized the test.
2. Read-only access to Supabase Auth logs/configuration sufficient to capture the Auth request and SMTP handoff.
3. Read-only Brevo access sufficient to retrieve message IDs and event timelines.
4. A test operator able to record inbox and spam-folder arrival timestamps in UTC.

The experiment should create at most one disposable test account per recipient and run signup confirmation, one resend after the cooldown, and one password recovery. It should record browser request start, Supabase SDK response, Auth handoff if exposed, Brevo acceptance, Brevo delivery/defer/bounce event, and mailbox arrival. No such timestamps exist from this verification pass.

## OTP discrepancy comparison

| Surface | Verified value | Evidence |
|---|---:|---|
| Shared source constant | 6 | `lib/auth/otp-input.ts` defines `OTP_LENGTH = 6`. |
| Shared OTP component | 6 | `AuthOtp.tsx` renders six inputs, six-digit label/copy, and six-digit resend notice. |
| Signup flow | 6-input component | Signup calls the shared component and verifies `type: "signup"`. |
| Login recovery/rescue | 6-input component | Unconfirmed login reuses the shared component and signup OTP verification. |
| Password recovery | 6-input component | Recovery uses the shared component and verifies `type: "recovery"`. |
| Public Supabase documentation | 6-digit documented token | Supabase documents `{{ .Token }}` as a six-digit OTP. |
| Live Supabase setting | Unknown | Dashboard requires an unavailable login; MCP does not expose Auth config. |
| Historical production observation | 8-digit reported | The 10 November investigation recorded an eight-digit token; this is historical evidence only. |

**Explicit recommendation:** Do not change source or live settings during this read-only pass. Before implementation authorization, obtain the live Supabase OTP length. If it is six, retain the current frontend and update the evidence record to close the drift finding. If it is eight, treat the mismatch as a confirmed functional root cause and align the frontend, copy, tests, and templates in one reviewed change. Do not infer the live value from the historical screenshot or from the current source.

## Correlation architecture verification

Supabase's documented Send Email Hook receives a signed payload containing the user and `email_data`, including the OTP, token hash, redirect, and email action type. The hook replaces the normal SMTP sender when enabled. The documented default SMTP configuration does not provide an application-controlled custom-header field in the browser Auth call.

Brevo's documented transactional webhook events include a `message-id`, UTC event timestamps, event type, and—on the documented event schemas—`X-Mailin-custom` and tags. Brevo therefore exposes enough provider-side metadata to reconcile a message to later delivered, deferred, bounced, blocked, or spam events if the message is sent through a path that sets that metadata.

**Conclusion:** A non-secret correlation ID is technically feasible through a controlled Send Email Hook or custom sender integration, but it is not proven to travel through the current stock Supabase Auth → custom SMTP path because the live Auth SMTP configuration and header behavior are unavailable. The safest design is to keep OTP generation in Supabase Auth, have a signed Send Email Hook generate a server-side request ID, pass that ID as a Brevo custom header/tag, and store only the provider message ID, action type, hashed recipient identity, and timestamps. The hook must never log or persist the OTP. If the team keeps direct SMTP, use Brevo's message ID plus a secure, bounded reconciliation ledger; do not claim that an application-generated browser ID is automatically preserved through SMTP.

## Exact next evidence required

- Supabase project owner read-only dashboard access or a management API token used only to GET Auth configuration, templates, limits, and hook status.
- Brevo account read-only access or a scoped API key used only for account status, SMTP activity, event history, webhooks, suppressions, and sender/domain authentication.
- Two authorized test recipients, one Gmail and one Outlook, plus operator-recorded UTC timestamps.
- Provider message IDs and event timelines for the three test purposes.

## References

[1]: https://supabase.com/docs/guides/auth/auth-email-templates "Supabase Auth email templates and six-digit token variable"
[2]: https://supabase.com/docs/guides/auth/auth-smtp "Supabase custom SMTP configuration and delivery boundary"
[3]: https://supabase.com/docs/guides/auth/auth-hooks/send-email-hook "Supabase Send Email Hook payload and behavior"
[4]: https://supabase.com/docs/guides/auth/rate-limits "Supabase Auth rate limits"
[5]: https://supabase.com/kb/troubleshooting/not-receiving-auth-emails-from-the-supabase-project-OFSNzw "Supabase Auth email troubleshooting"
[6]: https://developers.brevo.com/docs/transactional-webhooks "Brevo transactional webhook events and message identifiers"
[7]: https://developers.brevo.com/reference/get-webhooks "Brevo webhook configuration and custom headers"
[8]: https://github.com/ImperioKDB/Scholars/tree/137f2fa28a4f1a5b1fb6eaa55e3c6c3677bb4210 "Audited Scholars production commit"
[9]: https://github.com/ImperioKDB/Updates/blob/866541a02f972a942cc5e7bdf9d6366c7c81649c/SCHOLARS_EMAIL_DELIVERY_LATENCY_AUDIT.md "Initial Scholars email delivery audit"
