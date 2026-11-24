# Scholars — Callback-Originated Signup Flow Investigation

**Project:** `scholarship-platform` (`cmdglabohpttgfofcmqc`)  
**Application:** `https://www.scholars.com.ng`  
**Investigation date:** 2026-11-24  
**Scope:** Callback, signup, AuthRescue, redirect/recovery, signup retry, and signup form-state paths only.  
**Method:** Read-only repository search/source inspection and safe aggregation of the eight historical failed signup logs. No user data, email values, tokens, or personal information are included.

## Executive conclusion

The callback route and `AuthRescue` component **cannot trigger a signup request** in the inspected source. There is exactly one executable `supabase.auth.signUp()` call site, in `app/(auth)/signup/page.tsx`.

The callback route only exchanges an OAuth/legacy code for a session, applies optional attribution updates, clears the short-lived return-path cookie, and redirects. `AuthRescue` only watches the root path for stranded auth tokens, exchanges callback codes through `/auth/callback`, listens for session events, and redirects. Neither component reads or repopulates the signup email, password, or full-name fields.

The eight failed signup requests all used the same callback referer, `https://www.scholars.com.ng/auth/callback?next=%2Fdashboard`, and occurred in a 14-second burst. They all returned the same invalid-email error. The current source contains no path that would submit signup from `/auth/callback`, and no signup form state is persisted across callback recovery. Therefore, the callback referer is **not explained by the current callback or rescue code**.

The strongest conclusion supported by the evidence is that the referer reflects the document context or deployed client state that initiated those requests, not ordinary browser history alone. Possible explanations include an older/stale deployed bundle, a callback-page or embedded script not present in this checkout, a client-side transition whose request context retained the callback URL, or an external/automated retry. The available logs do not identify which explanation occurred, and no confirmed callback bug or duplicate-submit defect can be established.

## 1. Every `auth.signUp()` call site

Repository-wide search of executable source found exactly one call:

| File | Lines | Behavior |
|---|---:|---|
| `app/(auth)/signup/page.tsx` | 73–80 | Calls `supabase.auth.signUp()` with `cleanEmail`, password, `full_name`, and an `emailRedirectTo` callback URL |

Other matches were documentation or comments. No other executable source file calls `auth.signUp()`.

The signup page calls the browser Supabase client created by `lib/supabase/client.ts`, which uses `createBrowserClient` with the configured public Supabase URL and anon key.

## 2. Callback flow

### `app/auth/callback/route.ts`

The route is a server `GET` handler for `/auth/callback?code=...&next=...`.

Its relevant behavior is:

1. Reads the OAuth/legacy `code` and the short-lived `scholars_auth_next` cookie.
2. Validates the destination through `safeNextPath`, which accepts same-origin relative paths only.
3. If a code exists, calls `supabase.auth.exchangeCodeForSession(code)`.
4. On a successful session, optionally updates referral/campaign attribution in `profiles`.
5. Clears the return-path cookie.
6. Redirects to the validated destination.
7. On failure or no code, redirects to `/login?error=...`.

There is no import of the signup page, no `signUp()` call, no form rendering, no email/password read, and no retry loop.

### Can callback recovery trigger signup?

**No, not in the inspected source.** The callback route only exchanges an already-issued code and redirects.

### Can callback failure redirect into a state that submits signup again?

**No confirmed path was found.** Callback failure redirects to `/login`, not `/signup`. The signup page can be reached later by a user selecting a signup link, but the callback route does not automatically submit it.

The callback route’s `next` value is validated and only controls a safe redirect destination. It cannot contain an arbitrary external URL or signup payload.

## 3. `AuthRescue` flow

### Location

`components/AuthRescue.tsx`, mounted in `app/layout.tsx` at the root layout.

### Behavior

`AuthRescue`:

- Runs only when the current pathname is `/`.
- Checks for an OAuth `code` query parameter or an `access_token` in the URL hash.
- On a code, redirects the browser to `/auth/callback` with the code and a safe `next` path.
- Without a code, listens for `PASSWORD_RECOVERY` and `SIGNED_IN` events.
- Calls `supabase.auth.getSession()` as a fallback.
- Routes a recovered session to the saved safe path.
- After four seconds without a session, removes the dead tokens from the root URL.

It does not call `signUp()`, `verifyOtp()`, `resend()`, or any signup form handler. It does not access the signup email, password, or full name.

The only client-side state it stores for this flow is the safe return path in the `scholars_auth_next` cookie. The signup page writes that cookie before OAuth/signup actions, but the cookie contains only the safe destination path, not form fields.

## 4. Signup form state, retries, and duplicate submissions

### Form-state persistence

The signup page stores `fullName`, `email`, and `password` in React component state only. Repository search found no localStorage, sessionStorage, URL, cookie, or IndexedDB persistence for those fields.

The only signup-related cookie is `scholars_auth_next`, which stores the validated destination path. It cannot repopulate an email or create a malformed email value.

### Automatic retry behavior

No automatic retry surrounds `supabase.auth.signUp()`. The only preceding network call is the password-breach check; that call fails open and does not retry signup.

The OTP resend path is separate and calls `supabase.auth.resend({ type: "signup" })`; it does not call `signUp()` again.

### Duplicate-submit risk

The submit button is disabled while `loading` is true, and the handler sets `loading` before the signup request. However, `handleSubmit` does not begin with an explicit `if (loading) return` guard. This leaves a **possible but unconfirmed** narrow race if multiple submit events are dispatched before React applies the disabled state. The historical eight requests were spread across 14 seconds rather than appearing as an instantaneous burst, so the logs do not confirm that this race caused them.

There is no evidence of eight same-millisecond duplicate requests, and no evidence that the callback route initiated any of them.

## 5. Email normalization and malformed state

`lib/auth/email.ts` defines `normalizeEmail(raw)` and:

- Removes zero-width characters and non-breaking spaces.
- Trims leading and trailing whitespace.
- Lowercases the result.
- Preserves internal whitespace rather than silently removing it.

The signup page calls this helper before `signUp()`.

This means the current source addresses leading/trailing invisible-character problems, but it does not perform explicit browser-side email-format validation. Internal spaces or other invalid structures reach Supabase and can produce `validation_failed`.

No callback or recovery code mutates the email string. The callback `next` path and attribution cookies are separate from the email field.

## 6. The eight historical failures

All eight records were read from the Supabase `auth_logs` stream using safe fields only.

| Event time (UTC) | Event time (Lagos) | Referer | Error code | Error |
|---|---|---|---|---|
| 15:00:40 | 16:00:40 | `/auth/callback?next=%2Fdashboard` | `validation_failed` | `400: Unable to validate email address: invalid format` |
| 15:00:43 | 16:00:43 | `/auth/callback?next=%2Fdashboard` | `validation_failed` | `400: Unable to validate email address: invalid format` |
| 15:00:45 | 16:00:45 | `/auth/callback?next=%2Fdashboard` | `validation_failed` | `400: Unable to validate email address: invalid format` |
| 15:00:46 | 16:00:46 | `/auth/callback?next=%2Fdashboard` | `validation_failed` | `400: Unable to validate email address: invalid format` |
| 15:00:48 | 16:00:48 | `/auth/callback?next=%2Fdashboard` | `validation_failed` | `400: Unable to validate email address: invalid format` |
| 15:00:50 | 16:00:50 | `/auth/callback?next=%2Fdashboard` | `validation_failed` | `400: Unable to validate email address: invalid format` |
| 15:00:53 | 16:00:53 | `/auth/callback?next=%2Fdashboard` | `validation_failed` | `400: Unable to validate email address: invalid format` |
| 15:00:54 | 16:00:54 | `/auth/callback?next=%2Fdashboard` | `validation_failed` | `400: Unable to validate email address: invalid format` |

Safe telemetry shows:

- One request at each listed timestamp.
- The same referer on all eight requests.
- The same error code and exact error on all eight requests.
- A 14-second span from the first to the last request.

The logs do not expose the submitted email value, browser document URL at the moment of the request beyond the referer, JavaScript bundle version, user agent, or a browser session identifier. They cannot prove whether the same malformed value was retried or whether multiple malformed values were submitted.

## 7. Why `/auth/callback` appears as the referer

An HTTP referer on a request generally identifies the page context that initiated the request. It is not normally just a record of arbitrary browser history. Therefore, the callback referer is meaningful evidence that the request context was associated with `/auth/callback` at the time Supabase received the request.

However, the current source cannot produce that sequence directly:

- The callback route has no signup call.
- `AuthRescue` has no signup call.
- The only signup call is in the signup page.
- The signup form is not mounted by the callback route.
- Signup fields are not restored from callback state.
- The callback failure path goes to login, not signup.

The available evidence supports these possibilities, in descending order of how directly they can be stated:

1. **Confirmed:** The eight Auth requests carried the callback referer and invalid-email error.
2. **Confirmed:** The inspected current source has no callback-originated `signUp()` path.
3. **Strongly indicated:** The eight requests came from a client/deployment context different from the normal current signup-page context, or from a callback-associated browser context that is not represented in this checkout.
4. **Possible:** A stale cached bundle, an older deployed build, a client-side transition/referrer behavior, an embedded script, or an automated retry produced the callback referer.
5. **Unknown:** Which exact browser or deployed-code mechanism generated the referer.

The referer alone is not proof that the callback route itself called signup. It is also not safe to dismiss as ordinary history without additional browser or deployment telemetry.

## 8. Confirmed defects and non-defects

### Confirmed

- The eight requests were rejected by Supabase for invalid email format.
- The current signup page does not perform explicit browser-side email-format validation.
- The signup page maps unrecognized Supabase signup errors to a generic message.
- The callback route and `AuthRescue` do not call signup.
- Only one executable `auth.signUp()` call site exists.

### Not confirmed

- No callback-triggered signup.
- No callback-induced email mutation.
- No confirmed duplicate-submit incident.
- No confirmed automatic signup retry.
- No confirmed signup form-state restoration from callback state.
- No confirmed defect in the current callback redirect or AuthRescue flow.

## 9. Smallest corrective action

The smallest safe corrective action supported by the evidence is to add an explicit `loading`/submission guard in the signup handler and add privacy-safe diagnostics that record only a flow identifier, route, and deployment/build identifier—not email values or tokens.

Separately, add explicit client-side email-format feedback before calling Supabase. This will improve the user experience for the confirmed `validation_failed` cause but will not by itself explain the callback referer.

Do not change the callback route or AuthRescue based on the current evidence. A callback change would be speculative because neither component submits signup.

## Evidence limitations

The available Auth logs do not include the browser bundle version, deployment ID, document lifecycle, user agent, client session ID, raw email value, or a reliable browser-level correlation identifier. Those fields are required to distinguish a stale deployment, browser navigation/referrer behavior, embedded script, or automated client from one another.

No test signup, email send, code change, deployment, configuration change, or database change was performed.
