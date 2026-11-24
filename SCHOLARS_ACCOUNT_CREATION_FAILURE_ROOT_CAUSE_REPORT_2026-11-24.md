# Scholars — Account Creation Failure Root-Cause Report

**Project:** `scholarship-platform` (`cmdglabohpttgfofcmqc`)  
**Application:** `https://scholars.com.ng`  
**Investigation date:** 2026-11-24  
**Reconciliation window:** 2026-11-24 00:00:00+01:00 through 15:30:42Z (the cutoff used by the previous daily Auth report)  
**Scope:** Account creation, confirmation, login access, signup implementation, and the user-facing signup error path.  
**Method:** Read-only Supabase queries and read-only source inspection. No user data, emails, tokens, or personal information are included.

## Executive summary

At the exact cutoff used by the previous Auth report, **25 successful `POST /signup` responses resulted in 25 actual Auth users**. All 25 were confirmed by the time of the database check, so **0 created users remained unconfirmed** in that reconciliation window. The same window contained **8 rejected signup requests** with `validation_failed` and `invalid format`.

The previous report’s **24 `user_signedup` audit events** consisted of **21 email signups and 3 Google signups**. Database records show **22 email-provider users and 3 Google-provider users**, for 25 created users. The evidence therefore shows a one-event audit gap for an email-provider account: the account exists, but a matching `user_signedup` audit event was not present in the queried audit stream. This is a telemetry/audit discrepancy, not evidence that the account was not created.

The signup implementation has a confirmed user-experience defect: any unrecognized Supabase signup error, including `validation_failed`, is reduced to a generic message. The inspected source says, `We couldn't create your account. Check your details and try again.` The exact brief phrase, `We couldn't create your account. Please try again shortly.`, is not present in the inspected checkout, so the deployed wording cannot be confirmed from this source snapshot.

The implementation does **not** route OTP verification failures through the signup-creation error. Signup verification uses a separate `AuthOtp` component and `otpVerificationMessage`. Login also handles `email_not_confirmed` by showing the confirmation OTP flow. No confirmed session-persistence or post-verification redirect defect was found in the inspected code. The main confirmed problem is misleadingly generic signup-error handling, while the eight rejected signups were caused by invalid email values before account creation.

## 1. Actual account and request counts

### Exact previous-report cutoff

| Measure | Count | Evidence |
|---|---:|---|
| Successful `POST /signup` responses | 25 | Supabase `auth_logs`, HTTP 200 |
| Rejected `POST /signup` requests | 8 | Supabase `auth_logs`, HTTP 400, `validation_failed` |
| Auth users created in the window | 25 | Read-only `auth.users` aggregate |
| Created users confirmed by the database check | 25 | `email_confirmed_at IS NOT NULL` |
| Created users still unconfirmed | 0 | `email_confirmed_at IS NULL` |
| Email-provider users created | 22 | `raw_app_meta_data.provider = email` |
| Google-provider users created | 3 | `raw_app_meta_data.provider = google` |
| `user_signedup` audit events | 24 | Supabase `auth_audit_logs` |
| Email `user_signedup` audit events | 21 | Supabase `auth_audit_logs` |
| Google `user_signedup` audit events | 3 | Supabase `auth_audit_logs` |

### Reconciliation

The 25 successful HTTP signup responses and 25 created Auth users agree exactly. The audit stream recorded only 24 `user_signedup` events: 21 email and 3 Google. The database recorded 22 email-provider users and 3 Google-provider users. Therefore, the discrepancy is one email-provider account that was created but lacked a matching `user_signedup` audit event in the queried audit window.

The available evidence cannot determine whether that audit event was dropped, delayed outside the selected log window, or omitted by Auth logging. It does not support classifying the account as failed or missing.

Later same-day traffic continued after the previous report cutoff. A full-day query performed during this investigation returned 35 created users, 33 confirmed users, and 2 unconfirmed users. Those later records are intentionally not mixed into the 25-versus-24 reconciliation above.

## 2. Rejected signup requests

All 8 rejected requests had the same exact Supabase response:

- Endpoint: `POST /signup`
- HTTP status: `400`
- Error code: `validation_failed`
- Error: `400: Unable to validate email address: invalid format`

These requests were rejected before Auth user creation. The logs do not contain the submitted email values, so it is not possible to determine whether one malformed value was repeatedly submitted or whether multiple invalid values were used.

The eight failures occurred in a short burst and carried a callback-page referer rather than a normal signup-page referer. That is **strongly indicative** of a repeated or redirected submission flow, but it does not prove the exact browser-side input transformation. The Supabase error itself confirms invalid email input at the Auth boundary.

## 3. Confirmation and subsequent access

Within the exact cutoff window:

- 25 users were created.
- 25 were confirmed by `email_confirmed_at`.
- 0 remained unconfirmed at the database check.
- Auth logs recorded 70 successful `/token` requests and 1 `invalid_credentials` response in the same period.

The data therefore does not show a created user who remained unconfirmed at that cutoff. It also does not prove that every created user successfully completed a browser navigation to the dashboard; the available evidence confirms Auth creation and confirmation state, not an individual user’s final screen.

The later full-day data included 2 unconfirmed users and 1 `email_not_confirmed` token response after the earlier cutoff. Those are post-cutoff events and should be investigated separately if the current-day state is required.

No direct evidence links the 3 OTP-expiry failures to the 8 rejected signup requests. An OTP verification attempt occurs after signup acceptance, while the invalid-email requests were rejected before user creation.

## 4. Signup implementation trace

### Email handling and submission

`app/(auth)/signup/page.tsx`:

- Reads the controlled email input from React state.
- Applies `normalizeEmail(email)` before calling Supabase.
- Calls `supabase.auth.signUp({ email: cleanEmail, password, options })`.
- Sends `full_name` as metadata.
- Supplies an `emailRedirectTo` callback URL.
- Shows a loading state while the request is in progress.
- Does not perform an explicit browser-side email-format validation before the Auth request.

Supabase remains the final validator, so malformed values reach the Auth API and generate the observed `validation_failed` responses.

### Signup response handling

The source distinguishes only two signup error codes:

- `user_already_registered`: account-exists guidance.
- `over_email_send_rate_limit`: wait-and-retry guidance.

Every other signup error, including the observed `validation_failed`, is mapped to:

```text
We couldn't create your account. Check your details and try again.
```

This is a confirmed information-loss defect. The user is not told that the email format is invalid, and the UI does not provide field-level feedback for that failure.

### OTP verification

`app/(auth)/signup/page.tsx` calls:

```ts
supabase.auth.verifyOtp({
  email: verificationEmail ?? cleanEmail,
  token,
  type: "signup",
});
```

On an OTP error, the function returns `otpVerificationMessage(verifyError)` to `AuthOtp`; it does not call the signup-creation error handler. A successful verification with a session calls `router.push(next)` and `router.refresh()`.

### OTP input

`components/AuthOtp.tsx` and `lib/auth/otp-input.ts`:

- Use `OTP_LENGTH = 6`.
- Render six input boxes.
- Strip non-digits and truncate pasted/autofilled values to six digits.
- Prevent duplicate submissions while verification is active.
- Catch network errors and show a network-specific message.
- Reset the code after a failed verification.
- Allow resend after a 60-second local cooldown.

The stated production setting for this investigation is six digits with a 100-second expiry, so the OTP length is consistent with the stated configuration.

### Client initialization and session persistence

`lib/supabase/client.ts` creates a browser client using `@supabase/ssr`, the configured public Supabase URL and anon key, shared cookie-domain handling, and a timeout fetch wrapper.

`lib/supabase/server.ts` creates the server client with cookie-backed sessions and hardened cookie options. `middleware.ts` calls `supabase.auth.getUser()` for route protection and refreshes session cookies. Protected routes redirect unauthenticated users to `/login`; authenticated users on `/signup` or `/login` are redirected to a safe destination.

No confirmed defect was found in these session or route-protection paths that would prevent a successfully verified user from reaching onboarding or the dashboard.

### Callback and post-verification redirect

`app/auth/callback/route.ts` exchanges OAuth or legacy callback codes and redirects to a validated local path. New email OTP signup verification is completed directly in the signup screen, so the callback route is not required for the normal manual OTP submission. `AuthRescue` provides a root-level fallback for callback codes or session events and routes signed-in users to the saved safe destination.

No confirmed post-verification redirect defect was identified in the inspected paths.

## 5. Actual user-facing failure

The exact generic signup error is produced at:

```text
app/(auth)/signup/page.tsx:94
```

It is reached whenever `supabase.auth.signUp()` returns an error that is not `user_already_registered` or `over_email_send_rate_limit`. That includes the observed `validation_failed` error.

The inspected checkout does not contain the exact phrase from the brief, `We couldn't create your account. Please try again shortly.` It contains the similar generic phrase, `We couldn't create your account. Check your details and try again.` This difference may indicate a deployed-source mismatch or wording change not present in the checkout; it cannot be resolved from the available evidence.

OTP verification failures use a separate path:

- `signup/page.tsx` calls `otpVerificationMessage`.
- `AuthOtp.tsx` renders the returned verification message.
- `otp_expired` is presented as an expired-code message.

A user with an existing but unconfirmed account is handled in `app/(auth)/login/page.tsx`: `email_not_confirmed` switches to the confirmation OTP screen. It is not routed to the signup generic error.

## 6. Defect and root-cause classification

| Finding | Classification | Evidence |
|---|---|---|
| Eight rejected signups were rejected for invalid email format | **Confirmed** | All 8 Auth log records contain HTTP 400, `validation_failed`, and `Unable to validate email address: invalid format`. |
| Invalid signups were rejected before user creation | **Confirmed** | 25 created users match the 25 HTTP 200 signups; the 8 HTTP 400 requests are separate rejected events. |
| Generic signup error hides the specific validation reason | **Confirmed** | Signup source maps all unrecognized errors to one generic message at line 94. |
| The 25-versus-24 discrepancy represents a missing account | **Ruled out** | Database count is 25 created users; the mismatch is between user creation and audit-event recording. |
| One email signup lacks a matching audit event in the selected stream | **Confirmed as an observed telemetry gap** | 22 email-provider users versus 21 email `user_signedup` audit events; exact user identity is intentionally not exposed. |
| OTP verification failures were caused by signup rejection | **Ruled out for the 8 failures** | OTP verification happens after signup acceptance; the timestamps and error paths are separate. |
| Successful signup users were blocked by session persistence or redirect defects | **Not supported by available evidence** | 25 users were created and confirmed; source has browser/server clients, middleware refresh, and safe redirects. |
| The brief’s exact generic wording is the deployed wording | **Unknown** | The phrase in the brief is absent from the inspected checkout; a similar phrase is present. |
| A created user could not subsequently log in | **Possible but unverified** | There was one `invalid_credentials` token response, but no safe correlation to a created user is available. |
| The OTP expiry errors were caused by invalid email signup input | **Ruled out** | Invalid-email signup requests were rejected before account creation. |

## 7. Smallest safe corrective actions, ranked

1. **P1 — Improve the signup validation message.** Handle `validation_failed` explicitly and tell the user to check the email address format. Add a client-side format check as a UX aid, while retaining Supabase validation as the authority. This is the smallest change directly supported by the evidence.
2. **P2 — Investigate the callback referer on rejected signup requests.** Confirm why the eight invalid submissions originated from an `/auth/callback` referer and whether a redirect or retry loop is repopulating the email field incorrectly. Do this through privacy-safe telemetry; do not log raw email values.
3. **P3 — Improve audit correlation.** Add a privacy-safe correlation identifier linking an accepted signup request to the resulting user creation, confirmation, and verification outcome so audit gaps can be distinguished from true flow failures.
4. **P4 — Review the one invalid-credentials event separately.** Use privileged, privacy-safe operational correlation only if the user-impact question remains active; do not expose or copy user emails, passwords, or tokens.

## Final determination

Students are not generally failing to create accounts because of a system-wide signup or session defect. At the previous report cutoff, **25 accounts were created and all 25 were confirmed**. The 8 failures were rejected before account creation because the submitted email values were invalid.

The main confirmed product defect is that the frontend hides Supabase’s useful `validation_failed` reason behind a generic account-creation error. The 25-versus-24 discrepancy is an Auth audit telemetry gap: one created email-provider account has no matching `user_signedup` audit event in the selected stream. No confirmed session, OTP-entry, or post-verification redirect defect was found in the inspected source.

No production configuration, source code, database data, user account, deployment, email template, or credential was changed.
