# Scholars Email Delivery Repair Readiness

**Repository:** `ImperioKDB/Scholars`  
**Verification report:** `SCHOLARS_EMAIL_DELIVERY_EXTERNAL_VERIFICATION.md`  
**Date:** 12 November 2026  
**Mode:** Read-only investigation. No implementation authorization was granted or assumed.

## Readiness decision

The project is **not ready for provider migration, OTP-setting changes, or delivery-architecture implementation** because the live Supabase Auth configuration and Brevo account telemetry remain inaccessible. It is ready for a tightly scoped evidence-collection session if the required read-only access and designated test recipients are supplied.

The only confirmed current operational failure signal is one Supabase Auth signup request rejected with `over_email_send_rate_limit` (HTTP 429) in the measured 24-hour window. One OTP verification expired with HTTP 403. These are real Auth-layer signals, but they do not prove a persistent Brevo bottleneck. The project also has confirmed observability limitations: application analytics records request acceptance, not provider delivery.

The six/eight-digit issue remains a high-priority unresolved configuration risk, not a confirmed root cause. Source and deployed frontend behavior are six-digit. The live Supabase value was not retrievable.

## Confirmed root causes and contributing failures

### Confirmed: Auth request-level instrumentation stops before provider delivery

The Scholars endpoint records client-reported `accepted` or `failed` status after the Supabase SDK call. It does not store a Brevo message ID, SMTP handoff timestamp, delivered/deferred/bounce state, or inbox observation. This prevents latency attribution and makes provider bottlenecks indistinguishable from recipient filtering, stale codes, or user abandonment.

**Repair implication:** Add provider-event correlation only after confirming the actual Auth sending path. Keep the analytics call non-blocking and do not store OTPs.

### Confirmed: at least one Auth email-send rate limit was hit

The Supabase Auth log aggregate for 11 November 08:00 UTC through 12 November 08:00 UTC contains one signup request with error code `over_email_send_rate_limit` and status 429. This confirms a rate-limit rejection occurred. It does not establish whether the limit was Supabase's project quota, user/IP bucket, provider quota, or a broader account restriction.

**Repair implication:** Inspect the live Auth rate-limit settings and provider quota before changing any limit. Do not disable protection.

### Confirmed: one OTP verification expired

The same window contains one `/verify` response with `otp_expired` and status 403. This proves at least one code was used after expiry or after a newer code invalidated the earlier attempt. It does not prove the email was delayed.

**Repair implication:** Compare the live expiry and resend behavior with user-facing copy; measure request-to-arrival and code-entry timing in a controlled experiment.

### Confirmed: current deployed frontend is six-digit

The audited production commit defines `OTP_LENGTH = 6`; the shared component renders six inputs and six-digit messages. Signup, unconfirmed login rescue, and recovery all use this shared input path.

**Repair implication:** Keep source unchanged until the live setting is read. If live Auth is eight-digit, align all clients and templates in one reviewed change.

## Outstanding unknowns

The following facts are still unavailable and block a definitive provider diagnosis:

- Live Supabase Email OTP length and expiry.
- Supabase confirmation and recovery template bodies.
- Supabase Auth SMTP host, port, TLS mode, sender, and whether a Send Email Hook is enabled.
- Auth project email quota/rate-limit configuration and the precise bucket responsible for the 429.
- Brevo account sending status, credits, quotas, queue, restrictions, suppression state, and recent event timelines.
- Brevo sender/domain authentication and the exact sender used by Supabase Auth.
- Any controlled Gmail or Outlook arrival timestamps.
- Whether the current direct SMTP path preserves a custom application header or tag.

## Exact fixes justified by current evidence

### Fix 1 — Obtain read-only configuration and provider evidence

This is the only immediate action justified without changing production. Obtain a Supabase owner-provided read-only dashboard session or a management API token restricted to GET operations, and a Brevo read-only account/API credential. Retrieve values without exposing secrets in reports. Use two authorized test mailboxes.

**Why:** The current evidence proves the investigation boundary, not the provider cause.

### Fix 2 — Resolve OTP length before implementation

Read the live Supabase setting and compare it with the six-digit frontend. If live is six, record alignment. If live is eight, align the frontend, shared constant, UI copy, signup flow, login rescue, recovery flow, tests, and templates in one reviewed change. Do not change only the UI or only the provider.

**Why:** A mismatch can make delivered tokens unusable. The historical eight-digit observation is not sufficient authorization to change the live setting.

### Fix 3 — Diagnose the rate-limit signal before tuning limits

Identify whether the 429 came from project email quota, per-user cooldown, IP bucket, or provider restriction. Keep CAPTCHA/abuse controls and current protections. Adjust a limit only after measuring legitimate traffic and confirming sender capacity.

**Why:** The measured 429 is confirmed, but the responsible control is not.

### Fix 4 — Run a controlled three-purpose delivery experiment

Using one fresh test address per provider where possible, measure signup confirmation, resend, and recovery. Record all timestamps in UTC and capture Brevo message IDs and final event states. Do not use real student accounts or bulk sends.

**Why:** This is the minimum evidence required to locate delay between browser, Auth, provider, recipient server, and inbox.

### Fix 5 — Validate correlation architecture before coding it

If direct SMTP cannot carry an application correlation ID, do not add a speculative header field to the browser flow. Evaluate a signed Supabase Send Email Hook or an equivalent controlled sender. The hook can create a server-side correlation record and send through a provider API that supports Brevo custom headers/tags; the hook must not persist OTPs.

**Why:** Official documentation confirms the hook payload and Brevo event fields, but the live direct-SMTP path is unverified.

## Implementation order after explicit authorization

1. Capture Supabase and Brevo configuration/event evidence.
2. Run the controlled Gmail/Outlook experiment.
3. Resolve the six/eight-digit decision and write a regression test plan.
4. Apply the smallest OTP/template alignment change, if required, with rollback evidence.
5. Add provider-event correlation using a signed hook or verified provider webhook path.
6. Add idempotent event storage, redaction, retention, and admin latency metrics.
7. Tune resend/rate-limit UX only after measured duplicate and 429 rates are known.
8. Reassess queueing or provider migration only if provider evidence shows sustained queueing, restriction, or delivery failure.

No step above is authorized by this report; it is the gated order for a later implementation task.

## Security risks

- Do not expose SMTP passwords, Brevo keys, service-role keys, hook secrets, OTPs, or full recipient addresses.
- Do not query or export raw Auth logs containing user identities when aggregates are sufficient.
- Verify Brevo webhook authentication and make event processing idempotent.
- Keep OTP generation, expiry, and verification inside Supabase Auth.
- Do not use an email address or OTP as a public correlation identifier.
- Hash or minimize recipient identity in analytics and define retention.
- Preserve account-enumeration protections and do not weaken Auth rate limits to hide 429s.
- Avoid sending test emails to real users or creating unnecessary production accounts.

## Regression risks

Changing OTP length invalidates existing tokens and can create a period where email templates and client copy disagree. Changing Auth templates can break link-based or legacy flows. Enabling a Send Email Hook can suppress the normal SMTP path or duplicate messages if configured incorrectly. Adding a webhook can create duplicate state transitions unless provider event IDs are unique. Tightening limits can block legitimate recovery; loosening them can increase abuse and provider reputation damage.

## Acceptance criteria

This investigation is ready to close when:

- The live Supabase OTP length and expiry are recorded from an authorized read-only source.
- Confirmation and recovery templates are captured without secrets or tokens.
- SMTP host class, port/security mode, sender, Auth rate limits, and hook status are recorded without credentials.
- Brevo account status, credit/quota state, recent event outcomes, queue/restriction state, suppressions, and sender authentication are recorded from authorized read-only access.
- Controlled signup, resend, and recovery tests have UTC timestamps or an explicit provider-side measurement blocker.
- Six/eight-digit alignment is decided with evidence.
- Correlation feasibility is documented for the actual configured path, not just the theoretical hook path.
- No production settings, source code, DNS, credentials, or deployments were changed during the investigation.

## Estimated costs

The evidence-collection phase has no expected software cost beyond existing Supabase and Brevo plans, but it requires an account owner with read-only access and two authorized test mailboxes. A repository-only observability implementation is a small-to-medium engineering change. A Send Email Hook may add Edge Function/provider usage and operational maintenance. A provider migration or durable queue has recurring engineering and service costs and is not justified until the controlled test demonstrates a persistent provider-side failure.

## Recommendation on the original remediation plan

The original plan remains materially correct and does not need to be rewritten. New evidence strengthens its first phase: verify the live Auth rate-limit cause before changing limits, and treat the one observed 429 as an Auth-layer signal rather than proof of Brevo congestion. The correlation design should be marked conditional on a Send Email Hook or another sender path because direct SMTP header propagation was not verified.

## References

[1]: https://github.com/ImperioKDB/Scholars/tree/137f2fa28a4f1a5b1fb6eaa55e3c6c3677bb4210 "Audited Scholars production commit"
[2]: https://github.com/ImperioKDB/Updates/blob/866541a02f972a942cc5e7bdf9d6366c7c81649c/SCHOLARS_EMAIL_DELIVERY_REMEDIATION_PLAN.md "Original email delivery remediation plan"
[3]: https://supabase.com/docs/guides/auth/auth-email-templates "Supabase Auth email templates and OTP variable"
[4]: https://supabase.com/docs/guides/auth/auth-hooks/send-email-hook "Supabase Send Email Hook"
[5]: https://supabase.com/docs/guides/auth/rate-limits "Supabase Auth rate limits"
[6]: https://developers.brevo.com/docs/transactional-webhooks "Brevo transactional webhook event fields"
[7]: https://developers.brevo.com/reference/get-webhooks "Brevo webhook configuration"
