# Scholars — Live Supabase OTP Configuration Check

**Project:** `scholarship-platform` (`cmdglabohpttgfofcmqc`)  
**Region:** `eu-west-1`  
**Application:** `https://scholars.com.ng`  
**Inspection date:** 2026-11-24  
**Scope:** Read-only comparison of the deployed frontend expectation with the live Supabase Auth configuration.

## Result

The connected Supabase management interface does not expose the production Auth-provider settings, email templates, or SMTP metadata. Consequently, the current production OTP length, OTP expiry, confirmation settings, confirmation template, and SMTP provider **could not be directly verified** through the available read-only tools.

The frontend expectation is verified from the inspected source: Scholars currently expects a **six-digit** signup OTP and calls `verifyOtp` with `type: "signup"`.

No configuration, database, source code, email template, deployment, or secret was changed.

## Configuration comparison

| Setting | Live production value | Frontend expectation | Compatible? |
|---|---|---|---|
| OTP length | **Not exposed by connected Supabase tools** | 6 digits (`OTP_LENGTH = 6`) | **Unknown** |
| OTP expiry | **Not exposed by connected Supabase tools** | UI says the code expires soon; no fixed expiry is hard-coded | **Unknown** |
| Email confirmation | **Not exposed by connected Supabase tools** | Signup enters an OTP confirmation flow when no session is returned | **Unknown** |
| Signup confirmation required | **Not exposed by connected Supabase tools** | `signUp` expects a verification step when `data.session` is absent | **Unknown** |
| Confirmation template | **Not retrievable through connected Supabase tools** | Manual entry of a numeric token; should use visible `{{ .Token }}` | **Unknown** |
| SMTP configuration | **Not exposed by connected Supabase tools** | No frontend SMTP dependency; delivery is handled by Supabase Auth | **Unknown** |

## Frontend verification

The inspected source files were read without modification.

### `components/AuthOtp.tsx`

- Imports `OTP_LENGTH` from `lib/auth/otp-input`.
- Renders six OTP input boxes because `OTP_LENGTH` is six.
- Uses `autoComplete="one-time-code"` on the first input.
- Automatically submits after six digits are entered.
- Allows a 60-second resend cooldown.
- Does not log, store, or display OTP values beyond the input state.

### `lib/auth/otp-input.ts`

- Defines `OTP_LENGTH = 6`.
- Strips non-digits and truncates pasted/autofilled values to six digits.
- Distributes the entered digits across the six input positions.

### Signup verification implementation

`app/(auth)/signup/page.tsx` calls:

```ts
supabase.auth.verifyOtp({
  email: verificationEmail ?? cleanEmail,
  token,
  type: "signup",
});
```

The `type: "signup"` value is consistent with confirmation of an email signup. The signup call also supplies an `emailRedirectTo` callback URL, but the current manual OTP verification happens in the signup screen rather than through the callback route.

## Live Supabase interface checks

The connected Supabase MCP interface was checked for available operations. It provides project details, database access, unified logs, functions, migrations, and related project operations, but it does not provide a read-only operation for:

- Auth Email provider settings.
- Email OTP length or expiry.
- Confirm-email/signup-confirmation toggles.
- Auth email templates.
- SMTP host/provider metadata.
- SMTP delivery-event history.

The live log source list contains Auth and application infrastructure logs, but no dedicated SMTP/provider-delivery source was available for this check. Existing Auth request logs can show signup/resend acceptance or rejection; they cannot prove inbox delivery.

## Confirmed configuration mismatches

**None can be confirmed from the current live configuration**, because the relevant Supabase settings are inaccessible through the connected read-only interface.

There is, however, an unresolved risk: the frontend expects six digits, while a previous project investigation recorded production evidence of an eight-digit OTP configuration. That older evidence must not be treated as the current live value. The setting must be read directly in the Supabase Dashboard before classifying this as a current mismatch.

## Configuration already verified as correct

- The frontend uses `verifyOtp` with `type: "signup"` for signup confirmation.
- The frontend consistently limits OTP entry and paste handling to six digits.
- The frontend has distinct handling for Supabase’s `otp_expired` error.
- No secrets or SMTP credentials were exposed during this inspection.

These findings verify frontend behavior only; they do not prove that the external Supabase settings match it.

## Inaccessible settings and missing evidence

To complete the live configuration check, a user with Supabase Dashboard access must read the following values under the project’s Auth settings:

1. Email OTP length.
2. Email OTP expiry duration.
3. Confirm email / signup confirmation requirement.
4. Current confirmation-email template, including whether it renders `{{ .Token }}` as visible text and whether it incorrectly uses `{{ .ConfirmationURL }}`.
5. SMTP provider/host and whether custom SMTP is enabled.
6. Provider-level delivery events for the relevant November 24 signup and resend attempts.

Passwords, API keys, SMTP credentials, tokens, and other secrets must not be copied into a report.

## Single smallest next action

Open **Supabase Dashboard → Authentication → Sign In / Providers → Email** for `scholarship-platform` and record the current **Email OTP length** and **OTP expiry** without changing them. Compare the OTP length to the frontend’s six-digit expectation. If they differ, align exactly one side—preferably after deciding whether six or eight digits is the intended product behavior—and then perform a controlled, consented verification test.

Until that live setting is read, changing the frontend or Supabase configuration would be guesswork.
