# Scholars — Targeted Supabase Auth Failure Root-Cause Report

**Project:** `scholarship-platform` (`cmdglabohpttgfofcmqc`)  
**Region:** `eu-west-1`  
**Investigation date:** 2026-11-24  
**Timezone:** Africa/Lagos (UTC+1)  
**Evidence sources:** Supabase `auth_logs`, Supabase `auth_audit_logs`, read-only application source inspection, and the application’s confirmation-email analytics table.  
**Scope:** The 8 failed `POST /signup` requests with HTTP 400 and 3 failed `POST /verify` requests with HTTP 403 identified in the daily Auth report.

## 1. Executive summary

The 8 failed signup requests have a **confirmed** cause: Supabase rejected each request because the submitted email value failed email-format validation. Every event reports `error_code: validation_failed` and the exact error `400: Unable to validate email address: invalid format`.

The 3 failed verification requests also have a **confirmed immediate cause**: Supabase rejected each submitted OTP with `error_code: otp_expired` and the exact error `token has expired or is invalid`. The logs do not establish why each token was expired or invalid. Possible explanations include a genuinely expired code, a newer resend invalidating an earlier code, delayed email access, or a code/configuration mismatch. These remain unverified without the relevant email contents and provider delivery events.

The eight signup failures occurred in a tight burst between 16:00:40 and 16:00:54 Lagos time and carried the same callback-page referer. That pattern strongly indicates repeated submission of one malformed or malformedly transformed input rather than eight independently diagnosed user accounts, although the raw submitted values are not retained in the available log fields.

The inspected frontend calls `signUp` with a normalized email and `verifyOtp({ email, token, type: "signup" })`. The shared OTP UI currently expects six digits. A prior repository investigation records direct production evidence of an eight-digit Supabase OTP setting, but the connected management tools do not expose the current Auth-provider setting. Therefore, a six-versus-eight configuration mismatch is **strongly indicated by prior evidence but not confirmed as the direct cause of these three `otp_expired` events**.

No code, Supabase setting, SMTP setting, email template, secret, or database data was changed during this investigation.

## 2. The 8 failed signup events

All eight events have the same confirmed error and classification. Request IDs are shown only by their final eight characters to preserve safe correlation without publishing complete request identifiers.

| Label | Timestamp (Lagos) | Timestamp (UTC) | Endpoint | HTTP status | Error code | Exact error | Classification | Request ID suffix |
|---|---|---|---|---:|---|---|---|---|
| Signup failure 1 | 2026-11-24 16:00:40 | 2026-11-24 15:00:40 | `POST /signup` | 400 | `validation_failed` | `400: Unable to validate email address: invalid format` | Invalid signup input — **confirmed** | `c86c99675` |
| Signup failure 2 | 2026-11-24 16:00:43 | 2026-11-24 15:00:43 | `POST /signup` | 400 | `validation_failed` | `400: Unable to validate email address: invalid format` | Invalid signup input — **confirmed** | `e164406` |
| Signup failure 3 | 2026-11-24 16:00:45 | 2026-11-24 15:00:45 | `POST /signup` | 400 | `validation_failed` | `400: Unable to validate email address: invalid format` | Invalid signup input — **confirmed** | `39c381` |
| Signup failure 4 | 2026-11-24 16:00:46 | 2026-11-24 15:00:46 | `POST /signup` | 400 | `validation_failed` | `400: Unable to validate email address: invalid format` | Invalid signup input — **confirmed** | `8c269` |
| Signup failure 5 | 2026-11-24 16:00:48 | 2026-11-24 15:00:48 | `POST /signup` | 400 | `validation_failed` | `400: Unable to validate email address: invalid format` | Invalid signup input — **confirmed** | `a7ee20` |
| Signup failure 6 | 2026-11-24 16:00:50 | 2026-11-24 15:00:50 | `POST /signup` | 400 | `validation_failed` | `400: Unable to validate email address: invalid format` | Invalid signup input — **confirmed** | `5ae9f8c` |
| Signup failure 7 | 2026-11-24 16:00:53 | 2026-11-24 15:00:53 | `POST /signup` | 400 | `validation_failed` | `400: Unable to validate email address: invalid format` | Invalid signup input — **confirmed** | `4bfe0` |
| Signup failure 8 | 2026-11-24 16:00:54 | 2026-11-24 15:00:54 | `POST /signup` | 400 | `validation_failed` | `400: Unable to validate email address: invalid format` | Invalid signup input — **confirmed** | `53e691a` |

### Signup context

- All eight requests were rejected before a signup could be accepted; none is evidence of an SMTP or email-provider failure.
- All eight carried a referer under `/auth/callback?next=%2Fdashboard`, which is unusual for a normal first visit to `/signup` and should be checked against the user journey or any retry/redirect behavior.
- The available Auth log fields do not include the submitted email value, so it is not possible to determine whether the same malformed value was retried or whether multiple malformed values were submitted.
- The eight requests occurred within 14 seconds, supporting a repeated-submit or automated/retry pattern.

## 3. The 3 failed verification events

| Label | Timestamp (Lagos) | Timestamp (UTC) | Endpoint | HTTP status | Error code | Exact error | Classification | Request ID suffix |
|---|---|---|---|---:|---|---|---|---|
| Verification failure 1 | 2026-11-24 02:33:27 | 2026-11-24 01:33:27 | `POST /verify` | 403 | `otp_expired` | `token has expired or is invalid` | Expired or invalid signup OTP — **confirmed** | `d5505ec21756b` |
| Verification failure 2 | 2026-11-24 04:15:21 | 2026-11-24 03:15:21 | `POST /verify` | 403 | `otp_expired` | `token has expired or is invalid` | Expired or invalid signup OTP — **confirmed** | `14f6b75eb72b` |
| Verification failure 3 | 2026-11-24 16:30:26 | 2026-11-24 15:30:26 | `POST /verify` | 403 | `otp_expired` | `token has expired or is invalid` | Expired or invalid signup OTP — **confirmed** | `8f879c2b9` |

The logs identify these as `/verify` failures with `otp_expired`; they do not contain the submitted OTP, the email body, the email delivery timestamp, or the exact reason Supabase considered each token expired or invalid.

## 4. Correlation between signup and verification failures

No direct correlation was established.

- The signup failures occurred at approximately 16:00 Lagos time.
- Two verification failures occurred earlier, at approximately 02:33 and 04:15 Lagos time.
- The third verification failure occurred at approximately 16:30 Lagos time, about 30 minutes after the signup-failure burst.
- The failed events have different request IDs, and no matching failed-signup/failed-verification correlation key is exposed in the available records.
- The `auth_audit_logs` stream contains audit events but does not expose a direct link from these failed request records to a specific signup attempt in the fields available to this read-only investigation.

The third verification failure could be part of an earlier or separate signup flow, but the available evidence cannot prove that it corresponds to any of the eight failed signups.

## 5. Email delivery findings

The application-side table `public.auth_confirmation_email_events` recorded the following for the investigation date:

| Application event | Count |
|---|---:|
| Signup request reported as accepted by the browser/app | 34 |
| Resend request reported as accepted | 2 |
| Resend request reported as failed | 1 |

These are **application observations after the Supabase SDK call**. They do not prove that an email was accepted by an SMTP provider, delivered to a recipient mailbox, or placed in the inbox.

The connected Supabase unified-log sources for the day included `auth_logs` and `auth_audit_logs`, but no dedicated SMTP/provider-delivery stream was available through the connected log interface. The Auth logs show request acceptance or rejection, not final inbox delivery. Therefore:

- Supabase acceptance of a signup or resend: partially evidenced.
- SMTP/provider acceptance: not evidenced by the available live logs.
- Inbox delivery: not evidenced.
- Provider rejection, bounce, block, or spam placement: not determinable from the available sources.

## 6. Relevant frontend implementation findings

### Signup implementation

`app/(auth)/signup/page.tsx`:

- Normalizes the entered email with `normalizeEmail(email)` before calling `supabase.auth.signUp()`.
- Passes the normalized value as `email`.
- Sends `full_name` as user metadata.
- Uses `emailRedirectTo: {app origin}/auth/callback?next=...`.
- Handles `signUpError.code`, but only provides specific UI messages for `user_already_registered` and `over_email_send_rate_limit`.
- Maps all other signup errors, including `validation_failed`, to the generic message: `We couldn't create your account. Check your details and try again.`

The generic fallback hides the exact validation reason from the user, although Supabase records the specific reason in its Auth log.

### OTP verification implementation

`app/(auth)/signup/page.tsx` calls:

```ts
supabase.auth.verifyOtp({
  email: verificationEmail ?? cleanEmail,
  token,
  type: "signup",
});
```

This verification type is consistent with an email-confirmation signup flow. `components/AuthOtp.tsx` uses `OTP_LENGTH = 6`, six input boxes, and submits automatically once six digits are entered. `lib/auth/otp-input.ts` also truncates input to six digits.

`lib/auth/otp-error.ts` correctly maps `otp_expired` and `token_expired` to a distinct expired-code message. The UI clears the code and allows a resend after its 60-second cooldown. Verification and resend network exceptions are caught and shown as user-facing network errors.

### Callback and resend implementation

`app/auth/callback/route.ts` exchanges OAuth/legacy callback codes and safely redirects to an approved local path. New signup and recovery OTP verification occurs in the auth screens rather than through this callback route.

The signup resend implementation calls:

```ts
supabase.auth.resend({
  type: "signup",
  email: cleanEmail,
  options: { emailRedirectTo: ... },
});
```

That is consistent with the signup OTP flow.

### OTP-length configuration risk

A prior repository investigation records direct production evidence of an eight-digit Supabase OTP setting, while the inspected source currently uses six digits. This is a **strongly indicated configuration risk**, not a confirmed explanation for the three current `otp_expired` events. The available Supabase management tools did not expose the current Email OTP length setting, and the current failure records do not contain the submitted token length.

If production still generates eight-digit tokens, the current six-box UI cannot submit a complete token. If production has since been changed to six digits, the current UI length is consistent.

## 7. Root-cause classification

| Failure group | Classification | Root cause / reason |
|---|---|---|
| Signup failures 1–8 | **Confirmed** | Supabase email validation rejected the submitted email value: `validation_failed`, `Unable to validate email address: invalid format`. |
| Verification failures 1–3 | **Confirmed immediate cause** | Supabase rejected the submitted token with `otp_expired`: `token has expired or is invalid`. |
| Why the verification tokens were expired/invalid | **Unknown** | Logs do not distinguish true expiry, resend invalidation, delayed email access, wrong code, or token/configuration mismatch. |
| Six-digit frontend versus possible eight-digit production setting | **Strongly indicated / current state unverified** | Prior repository evidence records an eight-digit production setting; inspected source expects six digits. Current external setting was inaccessible through the connected management tools. |
| SMTP/provider rejection | **Unknown** | No provider-level delivery or bounce stream was available. |
| Missing email template or malformed token template | **Possible but unverified** | Prior project evidence documented historical OTP-template issues, but this investigation did not retrieve the current rendered confirmation template. |
| Rate limiting as cause of these 11 events | **Not supported by the exact errors** | The failed signup and verification events report validation and OTP-expiry codes, not rate-limit errors. |
| Signup/verification event pairing | **Unknown** | No direct safe correlation key links the failed signup records to the failed verification records. |

## 8. Evidence supporting the classifications

1. The live Auth log payloads contain explicit `error` and `error_code` fields for every target event.
2. All eight signup failures have the same `validation_failed` code and invalid-email error.
3. All three verification failures have the same `otp_expired` code and expired-or-invalid-token error.
4. The signup source code passes a normalized email to Supabase but does not surface `validation_failed` specifically.
5. The verification source code uses `type: "signup"` and a six-digit OTP UI.
6. The application analytics table records SDK-level accepted/failed email-request outcomes but no provider delivery result.
7. The available live log-source list contains Auth, database, edge, storage, PostgREST, and connection-pool streams, but no dedicated SMTP/provider-delivery stream.
8. A previous project report records an eight-digit production OTP setting, but the current external setting could not be read through the connected tools.

## 9. Recommended minimal corrective actions

1. **Priority 1 — Confirm the production Email OTP length in Supabase Dashboard.** Make the dashboard setting and `OTP_LENGTH`/UI input count identical. Do not change either value until the desired product behavior is decided.
2. **Priority 1 — Improve signup validation feedback.** Map `validation_failed` to a clear email-format message and validate the normalized value before calling Supabase. Also inspect why the failing requests carried an `/auth/callback` referer.
3. **Priority 2 — Correlate accepted signup requests with confirmation outcomes.** Preserve only privacy-safe request/event correlation identifiers in the application analytics so an accepted signup, resend, verification attempt, and confirmation can be followed without storing raw OTPs or unnecessary PII.
4. **Priority 2 — Obtain provider-level delivery evidence.** For a controlled, consented test account, inspect the configured SMTP provider’s event detail for accepted, delivered, deferred, bounced, blocked, or rejected status. Do not infer inbox delivery from Supabase HTTP 200.
5. **Priority 3 — Review resend and stale-code UX.** Explain that requesting a new code may invalidate an older code, and ensure the UI always verifies the newest code for the selected email.

## 10. Evidence still needed

- Current Supabase Email OTP length and expiry settings.
- Current Supabase confirmation-email template as rendered, including whether the visible token uses `{{ .Token }}` correctly.
- SMTP/provider event records for the relevant confirmation messages.
- Safe application-side correlation between each accepted signup/resend and a later verification attempt.
- The submitted email-format values for the eight failures, if retained in a privacy-safe diagnostic system; they were not present in the live Auth log payloads inspected here.
- Whether the three expired-token attempts followed a resend or used a code from an earlier email.

## Final determination

The **confirmed causes** are:

1. The eight signup requests were rejected because Supabase received invalidly formatted email values.
2. The three verification requests were rejected because Supabase considered the submitted signup OTP expired or invalid.

The deeper cause of the OTP expiry and the availability or delivery of the corresponding emails remains unverified. The most important next action is to **confirm the live Supabase Email OTP length and align it with the deployed six-digit frontend before conducting any further user testing**.

No implementation work was started and no production configuration was changed.
