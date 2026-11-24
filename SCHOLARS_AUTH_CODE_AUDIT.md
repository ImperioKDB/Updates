# Scholars Authentication Code-Side Audit

Audit date: 2026-11-24T16:20:57.449609+00:00
Repository: ImperioKDB/Scholars
Branch: main
Commit: c209862cd7e4b8e8d2cd0bfb1e7d0f56420582e9
Mode: Read-only

## 1. Repository Integrity
- Total files: 688
- Relevant files fetched: 69
- Failed fetches: 0

## 2. Authentication Call Inventory
### signUp: 4 occurrence(s)
- `SCHOLARS_EMAIL_DELIVERY_ARCHITECTURE.md:31` — `3. The browser calls Supabase `auth.signUp()` with metadata and an allowed redirect URL.`
- `SCHOLARS_EMAIL_DELIVERY_LATENCY_AUDIT.md:31` — ``app/(auth)/signup/page.tsx` calls `supabase.auth.signUp()` from the browser. If no session is returned, the UI enters `AuthOtp`. Verification calls `supabase.auth.verifyOtp({ email, token, type: "signup" })`. Resend calls `supabase.auth.resend({ type: "signup" })`. The browser separately sends a be`
- `app/(auth)/signup/page.tsx:73` — `const { data, error: signUpError } = await supabase.auth.signUp({`
- `docs/auth-email-otp-migration.md:6` — `- Signup calls `supabase.auth.signUp()` with `full_name` metadata. The database trigger `public.handle_new_user()` creates the matching `profiles` row idempotently.`
### verifyOtp: 4 occurrence(s)
- `SCHOLARS_EMAIL_DELIVERY_LATENCY_AUDIT.md:31` — ``app/(auth)/signup/page.tsx` calls `supabase.auth.signUp()` from the browser. If no session is returned, the UI enters `AuthOtp`. Verification calls `supabase.auth.verifyOtp({ email, token, type: "signup" })`. Resend calls `supabase.auth.resend({ type: "signup" })`. The browser separately sends a be`
- `app/(auth)/login/page.tsx:182` — `const { data, error: verifyError } = await supabase.auth.verifyOtp({`
- `app/(auth)/signup/page.tsx:141` — `const { data, error: verifyError } = await supabase.auth.verifyOtp({`
- `app/reset-password/page.tsx:78` — `const { error: verifyError } = await supabase.auth.verifyOtp({`
### resend: 4 occurrence(s)
- `SCHOLARS_EMAIL_DELIVERY_ARCHITECTURE.md:40` — `An unconfirmed password login displays the same OTP component. Resend calls `auth.resend({ type: "signup" })`. The component applies a 60-second client cooldown, but Supabase remains the authoritative rate limiter. The code does not create a durable application-level idempotency key for the Auth sen`
- `SCHOLARS_EMAIL_DELIVERY_LATENCY_AUDIT.md:31` — ``app/(auth)/signup/page.tsx` calls `supabase.auth.signUp()` from the browser. If no session is returned, the UI enters `AuthOtp`. Verification calls `supabase.auth.verifyOtp({ email, token, type: "signup" })`. Resend calls `supabase.auth.resend({ type: "signup" })`. The browser separately sends a be`
- `app/(auth)/login/page.tsx:167` — `const { error: resendError } = await supabase.auth.resend({`
- `app/(auth)/signup/page.tsx:155` — `const { error: resendError } = await supabase.auth.resend({`
### signInWithPassword: 1 occurrence(s)
- `app/(auth)/login/page.tsx:117` — `const { error: signInError } = await supabase.auth.signInWithPassword({`
### signInWithOAuth: 2 occurrence(s)
- `app/(auth)/login/page.tsx:143` — `const { error: googleError } = await supabase.auth.signInWithOAuth({`
- `app/(auth)/signup/page.tsx:118` — `const { error: googleError } = await supabase.auth.signInWithOAuth({`
### exchangeCodeForSession: 1 occurrence(s)
- `app/auth/callback/route.ts:50` — `const { data, error } = await supabase.auth.exchangeCodeForSession(code);`
### getSession: 1 occurrence(s)
- `components/AuthRescue.tsx:112` — `const { data } = await supabase.auth.getSession();`
### onAuthStateChange: 3 occurrence(s)
- `app/(auth)/login/page.tsx:93` — `const { data: authListener } = supabase.auth.onAuthStateChange(`
- `app/reset-password/update/page.tsx:52` — `const { data: sub } = supabase.auth.onAuthStateChange((event) => {`
- `components/AuthRescue.tsx:99` — `const { data: sub } = supabase.auth.onAuthStateChange((event) => {`
### normalizeEmail: 6 occurrence(s)
- `app/(auth)/login/page.tsx:76` — `const cleanEmail = normalizeEmail(email);`
- `app/(auth)/signup/page.tsx:43` — `const cleanEmail = normalizeEmail(email);`
- `app/api/auth/confirmation-email-event/route.ts:15` — `function normalizeEmail(email: string): string {`
- `app/api/auth/confirmation-email-event/route.ts:29` — `const email = normalizeEmail(parsed.data.email);`
- `app/reset-password/page.tsx:50` — `const cleanEmail = normalizeEmail(email);`
- `lib/auth/email.ts:23` — `export function normalizeEmail(raw: string): string {`
### emailRegex: 2 occurrence(s)
- `docs/auth-email-otp-migration.md:5` — `- Browser auth uses `@supabase/ssr` browser cookies and `@supabase/supabase-js` `^2.45.0`.`
- `lib/supabase/server.ts:11` — `// (lib/supabase/client.ts, @supabase/ssr) needs to read the access token to`
### loadingGuard: 0 occurrence(s)
### tryCatch: 44 occurrence(s)
- `app/(auth)/login/page.tsx:40` — `try {`
- `app/(auth)/login/page.tsx:51` — `try {`
- `app/(auth)/login/page.tsx:59` — `try {`
- `app/(auth)/login/page.tsx:142` — `try {`
- `app/(auth)/signup/page.tsx:56` — `try {`
- `app/(auth)/signup/page.tsx:117` — `try {`
- `app/api/auth/password-check/route.ts:38` — `try {`
- `app/auth/callback/route.ts:41` — `try {`
- `app/auth/callback/route.ts:55` — `try {`
- `app/reset-password/page.tsx:23` — `try {`
- `app/reset-password/update/page.tsx:44` — `try {`
- `app/reset-password/update/page.tsx:80` — `try {`
- `components/AuthOtp.tsx:60` — `try {`
- `components/AuthOtp.tsx:117` — `try {`
- `components/AuthOtp.tsx:139` — `try {`
- `components/AuthRescue.tsx:31` — `try {`
- `components/AuthRescue.tsx:40` — `try {`
- `components/AuthRescue.tsx:49` — `try {`
- `components/AuthRescue.tsx:101` — `try {`
- `lib/auth/confirmation-email-analytics.ts:11` — `try {`
- `lib/auth/redirect-origin.ts:14` — `try {`
- `lib/auth/redirect-origin.ts:24` — `try {`
- `lib/auth/redirect-origin.ts:31` — `try {`
- `lib/email/digest.ts:56` — `try {`
- `lib/email/digest.ts:141` — `try {`
- `lib/email/digest.ts:152` — `try {`
- `lib/email/profileNudges.ts:103` — `try {`
- `lib/email/profileNudges.ts:154` — `try {`
- `lib/email/profileNudges.ts:207` — `try {`
- `lib/email/profileNudges.ts:228` — `try {`
- `lib/email/profileNudges.ts:230` — `try {`
- `lib/email/providers/brevo.ts:14` — `try {`
- `lib/email/providers/brevo.ts:44` — `try {`
- `lib/email/providers/resend.ts:14` — `try {`
- `lib/email/providers/resend.ts:42` — `try {`
- `lib/email/providers/types.ts:55` — `try {`
- `lib/email/providers/types.ts:92` — `try {`
- `lib/email/providers/types.ts:140` — `try {`
- `lib/email/send.test.ts:111` — `try { await sendEmail(email) } catch (error) { thrown = error }`
- `lib/email/send.ts:47` — `try {`
- `lib/email/send.ts:68` — `try {`
- `lib/supabase/server.ts:33` — `try {`
- `lib/supabase/server.ts:67` — `try {`
- `lib/supabase/server.ts:74` — `try {`
### finally: 0 occurrence(s)
### localStorage: 7 occurrence(s)
- `.agents/skills/vercel-react-best-practices/rules/js-request-idle-callback.md:96` — `- Saving state to localStorage/IndexedDB`
- `app/(auth)/login/page.tsx:21` — `// lockout stored in localStorage. UX-level only -- the real brakes are`
- `app/(auth)/login/page.tsx:41` — `const raw = localStorage.getItem(LOCK_KEY);`
- `app/(auth)/login/page.tsx:52` — `localStorage.setItem(LOCK_KEY, JSON.stringify(lock));`
- `app/(auth)/login/page.tsx:60` — `localStorage.removeItem(LOCK_KEY);`
- `app/reset-password/page.tsx:25` — `const arr = (JSON.parse(localStorage.getItem(THROTTLE_KEY) ?? "[]") as number[]).filter(`
- `app/reset-password/page.tsx:30` — `localStorage.setItem(THROTTLE_KEY, JSON.stringify(arr));`
### sessionStorage: 6 occurrence(s)
- `app/reset-password/update/page.tsx:22` — `//      recovery over via sessionStorage (RECOVERY_REDIRECT_FLAG).`
- `app/reset-password/update/page.tsx:45` — `if (sessionStorage.getItem(RECOVERY_REDIRECT_FLAG)) {`
- `app/reset-password/update/page.tsx:46` — `sessionStorage.removeItem(RECOVERY_REDIRECT_FLAG);`
- `app/reset-password/update/page.tsx:81` — `sessionStorage.removeItem(RECOVERY_REDIRECT_FLAG);`
- `components/AuthRescue.tsx:24` — `//   PASSWORD_RECOVERY -> /reset-password/update (handoff via sessionStorage)`
- `components/AuthRescue.tsx:102` — `sessionStorage.setItem(RECOVERY_REDIRECT_FLAG, "1");`

## 3. Target File Hashes
- `app/(auth)/signup/page.tsx`: `541c8ffd4de668502300135ff1b28fe0acd0347fff862e47d72d3e2256cebc87`
- `app/auth/callback/route.ts`: `81465755780b6fee74d48a3715dd5916bba2f6f3f42e3f2ca6e7cf474e5c9682`
- `lib/auth/email.ts`: `3cd8105e05e07e60cbe3b40dedace969e243697577689ef5fb190319b47bcd25`
- `lib/auth/otp-input.ts`: `0894595e2d3d4eec593427135c86f1db30711a81f92083328225904aeb8327b1`
- `components/AuthRescue.tsx`: `776db370bb310f8206fafa4c2c75312c52ec15a7b0510c40193bb0d0e2782222`
- `lib/supabase/client.ts`: `c07f8d682d50b6c1949189c6f193b83687181d630579accfa7d179afd363cac8`

## 4. Potential Security Indicators
Potential secret-related indicators were detected. Values were deliberately not printed.
- `.agents/skills/supabase/SKILL.md` — pattern: `service_role`
- `SCHOLARS_EMAIL_DELIVERY_LATENCY_AUDIT.md` — pattern: `BREVO_API_KEY`
- `docs/EMAIL_FAILOVER_SETUP.md` — pattern: `BREVO_API_KEY`
- `docs/EMAIL_FAILOVER_SETUP.md` — pattern: `RESEND_API_KEY`
- `lib/email/profileNudges.ts` — pattern: `BREVO_API_KEY`
- `lib/email/providers/brevo.ts` — pattern: `BREVO_API_KEY`
- `lib/email/providers/resend.ts` — pattern: `RESEND_API_KEY`
- `lib/email/send.test.ts` — pattern: `BREVO_API_KEY`
- `lib/email/send.test.ts` — pattern: `RESEND_API_KEY`
- `lib/email/send.ts` — pattern: `BREVO_API_KEY`
- `lib/email/send.ts` — pattern: `RESEND_API_KEY`
- `lib/supabase/config.ts` — pattern: `service_role`
- `lib/supabase/config.ts` — pattern: `SUPABASE_SERVICE_ROLE_KEY`
- `lib/supabase/service.ts` — pattern: `service_role`
- `lib/supabase/service.ts` — pattern: `SUPABASE_SERVICE_ROLE_KEY`

## 5. Fetch Errors

## 6. Audit Limitations
- This report inventories source patterns; it does not prove runtime behavior.
- It does not inspect Supabase project settings, database records, SMTP delivery, or production logs.
- Production deployment identity must be independently verified against the deployed build.
- A pattern match is not proof that a particular code path is executed.